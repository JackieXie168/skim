//
//  BDSKSearchIndex.m
//  Bibdesk
//
//  Created by Adam Maxwell on 10/11/05.
/*
 This software is Copyright (c) 2005,2006
 Adam Maxwell. All rights reserved.
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:
 
 - Redistributions of source code must retain the above copyright
 notice, this list of conditions and the following disclaimer.
 
 - Redistributions in binary form must reproduce the above copyright
 notice, this list of conditions and the following disclaimer in
 the documentation and/or other materials provided with the
 distribution.
 
 - Neither the name of Adam Maxwell nor the names of any
 contributors may be used to endorse or promote products derived
 from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "BDSKSearchIndex.h"
#import "BibDocument.h"
#import "BibItem.h"
#import <libkern/OSAtomic.h>
#import "BibTypeManager.h"

@interface BDSKSearchIndex (Private)

- (void)rebuildIndex;
- (void)indexFilesForItem:(id)anItem;
void *setupThreading(void *anObject);
- (void)processNotification:(NSNotification *)note;
- (void)handleDocAddItemNotification:(NSNotification *)note;
- (void)handleDocDelItemNotification:(NSNotification *)note;
- (void)handleSearchIndexInfoChangedNotification:(NSNotification *)note;
- (void)handleMachMessage:(void *)msg;

// use this to keep a temporary cache of objects for initial index creation, to avoid messaging the document from our worker thread
- (void)setInitialObjectsToIndex:(NSArray *)objects;

@end

/* Access to the SKIndexRef is no longer locked, since all access to it takes place on the worker pthread.  We could possibly switch to NSThread for running the worker thread now that the retain issue has been addressed, but the pthread solution works  well and has been debugged.  Setting flags.isIndexing should always succeed, since it's only changed from the worker thread; we're using the OSAtomic functions just in case (and because they're interesting). */

@implementation BDSKSearchIndex

+ (void)initialize
{
    OBINITIALIZE;
    // ensure that the AppKit knows we're multithreaded, since we're using pthreads
    [NSThread detachNewThreadSelector:NULL toTarget:nil withObject:nil];
}

- (id)initWithDocument:(id)aDocument
{
    OBASSERT([NSThread inMainThread]);

    self = [super init];
        
    if(nil != self){
    
        CFMutableDataRef indexData = CFDataCreateMutable(CFAllocatorGetDefault(), 0);
        index = SKIndexCreateWithMutableData(indexData, NULL, kSKIndexInverted, NULL);
        CFRelease(indexData); // @@ doc bug: is this owned by the index now?  seems to be...
            
        document = [aDocument retain];
        [self setInitialObjectsToIndex:[[aDocument publications] arrayByPerformingSelector:@selector(searchIndexInfo)]];
        
        flags.isIndexing = 0;
        flags.shouldKeepRunning = 1;
        
        // We need setupThreading to run in a separate thread, but +[NSThread detachNewThreadSelector...] retains self, so we end up with a retain cycle
        pthread_attr_t attr;
        pthread_attr_init(&attr);
        pthread_attr_setdetachstate(&attr, PTHREAD_CREATE_DETACHED);
        
        int err = pthread_create(&notificationThread, &attr, &setupThreading, [[self retain] autorelease]);
        pthread_attr_destroy(&attr);

        if(err){
            [self release];
            self = nil;
        }
    }
    
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [notificationPort release];
    [notificationQueue release];
    
    // the document does cleanup that should only be performed on the main thread (this was causing an assertion failure in -[BDSKFileContentSearchController cancelCurrentSearch:])
    [document performSelectorOnMainThread:@selector(release) withObject:nil waitUntilDone:NO];
    [queueLock release];
    if(index) CFRelease(index);
    [super dealloc];
}

- (void)cancel
{
    OSAtomicDecrement32((int32_t *)&flags.shouldKeepRunning);
}

- (SKIndexRef)index
{
    return index;
}

- (BOOL)isIndexing
{
    uint32_t isIndexing = flags.isIndexing;
    return isIndexing == 1;
}

@end

@implementation BDSKSearchIndex (Private)

- (void)rebuildIndex
{    
    NSAssert2(pthread_equal(notificationThread, pthread_self()), @"-[%@ %@] must be called from the worker thread!", [self class], NSStringFromSelector(_cmd));
    
    OBPRECONDITION(initialObjectsToIndex);
    NSEnumerator *enumerator = [initialObjectsToIndex objectEnumerator];
    id anObject = nil;
        
    while((anObject = [enumerator nextObject]) && flags.shouldKeepRunning == 1)
        [self indexFilesForItem:anObject];
     
    // release these, since they're only used for the initial index creation
    [self setInitialObjectsToIndex:nil];
}

- (void)indexFilesForItem:(id)anItem
{
    OBASSERT(pthread_equal(notificationThread, pthread_self()));
    NSURL *url = nil;
    
    SKDocumentRef skDocument;
    volatile Boolean success;
    
    NSEnumerator *urlEnumerator = [[anItem valueForKey:@"urls"] objectEnumerator];
    CFDictionaryRef properties;
        
    BOOL swap;
    swap = OSAtomicCompareAndSwap32Barrier(0, 1, (int32_t *)&flags.isIndexing);
    OBASSERT(swap);
    
    while(url = [urlEnumerator nextObject]){
                
        skDocument = SKDocumentCreateWithURL((CFURLRef)url);
        OBPOSTCONDITION(skDocument);
        if(skDocument == NULL) continue;
        
        // most documents on file will have a title, and the @"title" key is guaranteed to be non-nil
        properties = (CFDictionaryRef)[[NSDictionary alloc] initWithObjectsAndKeys:[anItem valueForKey:@"title"], @"title", nil];
        OBASSERT(properties);
        
        success = SKIndexAddDocument(index, skDocument, NULL, TRUE);
        SKIndexSetDocumentProperties(index, skDocument, properties);
        OBPOSTCONDITION(success);
        
        CFRelease(properties);
        CFRelease(skDocument);
    }
    swap = OSAtomicCompareAndSwap32Barrier(1, 0, (int32_t *)&flags.isIndexing);
    OBASSERT(swap);
}

void *setupThreading(void *anObject)
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    BDSKSearchIndex *self = (id)anObject;
    [self retain]; // make sure this doesn't go away until we're done with setup
    
    id savedException = nil;
 
    @try{
        self->notificationPort = [[NSMachPort alloc] init];
        [self->notificationPort setDelegate:self];
        
        [self->notificationPort scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        
        self->notificationQueue = [[NSMutableArray alloc] initWithCapacity:5];
        self->queueLock = [[NSLock alloc] init];
            
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(processNotification:) name:BDSKSearchIndexInfoChangedNotification object:self->document];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(processNotification:) name:BDSKDocAddItemNotification object:self->document];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(processNotification:) name:BDSKDocDelItemNotification object:self->document];
    }
    @catch(id localException){
        // exceptions here mean something is seriously wrong, and we can't do anything about it
        NSLog(@"Exception %@ raised while setting up thread support in %@; exiting.", localException, self);
        savedException = [localException retain];
        @throw;
    }
    
    // an exception here can probably be ignored safely
    @try{
        [self rebuildIndex];
    }
    @catch(id localException){
        NSLog(@"Ignoring exception %@ raised while rebuilding index", localException);
    }
        
    // run the current run loop until we get a cancel message, or else the current thread/run loop will just go away when this function returns
    volatile int32_t keepGoing;
    
    @try{
        do {
            keepGoing = (self->flags.shouldKeepRunning == 1);
            [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
            [pool release];
            pool = [[NSAutoreleasePool alloc] init];
        } while(keepGoing);
    }
    @catch(id localException){
        NSLog(@"Exception %@ raised in search index; exiting thread run loop.", localException);
        savedException = [localException retain];
        @throw;
    }

    @finally{
        [self release];
        [pool release];
        [savedException autorelease];
        return NULL;
    }
}

- (void)processNotification:(NSNotification *)note
{    
    if( pthread_equal(notificationThread, pthread_self()) == FALSE ){
        // Forward the notification to the correct thread
        [queueLock lock];
        [notificationQueue addObject:note];
        [queueLock unlock];
        [notificationPort sendBeforeDate:[NSDate date] components:nil from:nil reserved:0];
        
    } else {
        // this is a background thread that can handle these notifications
        if([[note name] isEqualToString:BDSKSearchIndexInfoChangedNotification])
            [self handleSearchIndexInfoChangedNotification:note];
        else if([[note name] isEqualToString:BDSKDocAddItemNotification])
            [self handleDocAddItemNotification:note];
        else if([[note name] isEqualToString:BDSKDocDelItemNotification])
            [self handleDocDelItemNotification:note];
        else
            [NSException raise:NSInvalidArgumentException format:@"notification %@ is not handled by %@", note, self];
                
    }
}

- (void)handleDocAddItemNotification:(NSNotification *)note
{
    OBASSERT(pthread_equal(notificationThread, pthread_self()));

	NSEnumerator *pubEnum = [[[note userInfo] valueForKey:@"searchIndexInfo"] objectEnumerator];
    id pub;
    OBPRECONDITION(pubEnum);
            
	while (pub = [pubEnum nextObject])
		[self indexFilesForItem:pub];
}

- (void)handleDocDelItemNotification:(NSNotification *)note
{
    OBASSERT(pthread_equal(notificationThread, pthread_self()));

	NSEnumerator *itemEnumerator = [[[note userInfo] valueForKey:@"searchIndexInfo"] objectEnumerator];
    id anItem;
    
    NSURL *url = nil;
    
    SKDocumentRef skDocument;
    volatile Boolean success;
    
    NSArray *urls = nil;
    unsigned int idx, maxIdx;
    
    // set this here because we're adding to the index apart from indexFilesForItem:
    BOOL swap;
    swap = OSAtomicCompareAndSwap32Barrier(0, 1, (int32_t *)&flags.isIndexing);
    OBASSERT(swap);

	while(anItem = [itemEnumerator nextObject]){
        urls = [anItem valueForKey:@"urls"];
        maxIdx = [urls count];
        
        // loop through the array of URLs, create a new SKDocumentRef, and try to remove it
		for(idx = 0; idx < maxIdx; idx++){
			
			url = [urls objectAtIndex:idx];
			
			skDocument = SKDocumentCreateWithURL((CFURLRef)url);
			OBPOSTCONDITION(skDocument);
			if(!skDocument) continue;
			
			success = SKIndexRemoveDocument(index, skDocument);
			OBPOSTCONDITION(success);
			
			CFRelease(skDocument);
		}
	}
    swap = OSAtomicCompareAndSwap32Barrier(1, 0, (int32_t *)&flags.isIndexing);
    OBASSERT(swap);
}

- (void)handleSearchIndexInfoChangedNotification:(NSNotification *)note
{
    OBASSERT(pthread_equal(notificationThread, pthread_self()));

    // reindex all the files; unless you have many local files attached to the item, there won't be much savings vs. just adding the one that changed
    [self indexFilesForItem:[note userInfo]];
}    

- (void)handleMachMessage:(void *)msg
{

    [queueLock lock];
    while ( [notificationQueue count] ) {
        NSNotification *note = [[notificationQueue objectAtIndex:0] retain];
        [notificationQueue removeObjectAtIndex:0];
        [queueLock unlock];
        [self processNotification:note];
        [note release];
        [queueLock lock];
    };
    [queueLock unlock];
}

- (void)setInitialObjectsToIndex:(NSArray *)objects{
    if(objects != initialObjectsToIndex){
        [initialObjectsToIndex release];
        initialObjectsToIndex = [objects copy];
    }
}

@end
