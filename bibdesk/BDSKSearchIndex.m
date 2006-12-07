//
//  BDSKSearchIndex.m
//  Bibdesk
//
//  Created by Adam Maxwell on 10/11/05.
/*
 This software is Copyright (c) 2005
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

@interface BDSKSearchIndex (Private)

- (void)rebuildIndex;
- (void)indexFilesForItem:(BibItem *)anItem;
void *setupThreading(void *anObject);
- (void)processNotification:(NSNotification *)note;
- (void)handleDocAddItemNotification:(NSNotification *)note;
- (void)handleDocDelItemNotification:(NSNotification *)note;
- (void)handleBibItemChangedNotification:(NSNotification *)note;
- (void)handleMachMessage:(void *)msg;

@end


@implementation BDSKSearchIndex

+ (void)initialize
{
    OBINITIALIZE;
    // ensure that the AppKit knows we're multithreaded, since we're using pthreads
    [NSThread detachNewThreadSelector:NULL toTarget:nil withObject:nil];
}

- (id)initWithDocument:(id)aDocument
{
    if(![super init])
        return nil;
    
    NSMutableData *indexData = [[NSMutableData alloc] init];
    index = SKIndexCreateWithMutableData((CFMutableDataRef)indexData, NULL, kSKIndexInverted, NULL);
    [indexData release]; // @@ doc bug: is this owned by the index now?  seems to be...
    
    indexLock = [[NSLock alloc] init];
    
    document = [aDocument retain];
    delegate = nil;
    
    flags.isIndexing = NO;
    pthread_rwlock_init(&indexStatusLock, NULL);
    flags.shouldKeepRunning = YES;
    pthread_rwlock_init(&keepRunningLock, NULL);
    
    // We need setupThreading to run in a separate thread, but +[NSThread detachNewThreadSelector...] retains self, so we end up with a retain cycle
    pthread_attr_t attr;
    pthread_attr_init(&attr);
    pthread_attr_setdetachstate(&attr, PTHREAD_CREATE_DETACHED);
    
    OSStatus err = pthread_create(&notificationThread, &attr, &setupThreading, [[self retain] autorelease]);
    pthread_attr_destroy(&attr);

    if(err != noErr){
        [self release];
        return nil;
    }
    
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [notificationPort release];
    
    [notificationQueue release];
    [document release];
    [notificationLock release];
    if(index) CFRelease(index);
    pthread_rwlock_destroy(&indexStatusLock);
    pthread_rwlock_destroy(&keepRunningLock);
    [indexLock release];
    [super dealloc];
}

- (void)cancel
{
    pthread_rwlock_wrlock(&keepRunningLock);
    flags.shouldKeepRunning = NO;
    pthread_rwlock_unlock(&keepRunningLock);
}

- (SKIndexRef)index
{
    return index;
}

- (BOOL)isIndexing
{
    volatile BOOL status;

    pthread_rwlock_rdlock(&indexStatusLock);
    status = flags.isIndexing;
    pthread_rwlock_unlock(&indexStatusLock);

    return status;
}

- (void)setDelegate:(id <BDSKSearchIndexDelegate>)anObject
{
    if(anObject)
        NSAssert1([(id)anObject conformsToProtocol:@protocol(BDSKSearchIndexDelegate)], @"%@ does not conform to BDSKSearchIndexDelegate protocol", [anObject class]);

    delegate = anObject;
}

@end

@implementation BDSKSearchIndex (Private)

- (void)rebuildIndex
{    
    pthread_rwlock_wrlock(&indexStatusLock);
    flags.isIndexing = YES;
    pthread_rwlock_unlock(&indexStatusLock);

    // copy, since the document (may) be giving us a mutable array to enumerate
    NSArray *pubs = [[document publications] copy];
    NSEnumerator *pubE = [pubs objectEnumerator];
    BibItem *aPub = nil;
    
    volatile BOOL keepGoing = YES;
    
    while((aPub = [pubE nextObject]) && keepGoing == YES){
        pthread_rwlock_rdlock(&keepRunningLock);
        keepGoing = flags.shouldKeepRunning;
        pthread_rwlock_unlock(&keepRunningLock);
                
        [self indexFilesForItem:aPub];
    }
    
    pthread_rwlock_wrlock(&indexStatusLock);
    flags.isIndexing = NO;
    pthread_rwlock_unlock(&indexStatusLock);    
    
    [pubs release];
}

- (void)indexFilesForItem:(BibItem *)anItem
{
    NSURL *url = nil;
    
    SKDocumentRef skDocument;
    volatile Boolean success;
    
    NSArray *urlFields = [[OFPreferenceWrapper sharedPreferenceWrapper] stringArrayForKey:BDSKLocalFileFieldsKey];
    unsigned int fieldCnt, maxFields = [urlFields count];
    NSString *urlFieldName = nil;
    CFDictionaryRef properties;
    
    NSAssert(maxFields, @"No local url fields are defined");
    
    for(fieldCnt = 0; fieldCnt < maxFields; fieldCnt++){
        
        urlFieldName = [urlFields objectAtIndex:fieldCnt];
        url = [anItem URLForField:urlFieldName];
        if(url == nil) continue;
        
        skDocument = SKDocumentCreateWithURL((CFURLRef)url);
        OBPOSTCONDITION(skDocument);
        if(skDocument == NULL) continue;
        
        // most documents on file will have a title, and -[BibItem title] is guaranteed to be non-nil
        properties = (CFDictionaryRef)[[NSDictionary alloc] initWithObjectsAndKeys:[anItem title], @"title", nil];
        OBASSERT(properties);
        
        [indexLock lock];
        success = SKIndexAddDocument(index, skDocument, NULL, TRUE);
        SKIndexSetDocumentProperties(index, skDocument, properties);
        [indexLock unlock];
        OBPOSTCONDITION(success);
        
        CFRelease(properties);
        CFRelease(skDocument);
    }
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
        self->notificationLock = [[NSLock alloc] init];
            
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(processNotification:) name:BDSKBibItemChangedNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(processNotification:) name:BDSKDocAddItemNotification object:self->document];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(processNotification:) name:BDSKDocDelItemNotification object:self->document];
    }
    @catch(NSException *localException){
        // exceptions here mean something is seriously wrong, and we can't do anything about it
        NSLog(@"Exception %@ raised while setting up thread support in %@; exiting.", [localException name], self);
        savedException = [localException retain];
        @throw;
    }
    
    // an exception here can probably be ignored safely
    @try{
        [self rebuildIndex];
    }
    @catch(NSException *localException){
        NSLog(@"Ignoring exception %@ raised while rebuilding index", [localException name]);
    }
        
    // run the current run loop until we get a cancel message, or else the current thread/run loop will just go away when this function returns
    volatile BOOL keepGoing;
    
    @try{
        do {
            pthread_rwlock_rdlock(&(self->keepRunningLock));
            keepGoing = self->flags.shouldKeepRunning;
            pthread_rwlock_unlock(&(self->keepRunningLock));
            
            [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
            [pool release];
            pool = [[NSAutoreleasePool alloc] init];
        } while(keepGoing);
    }
    @catch(NSException *localException){
        NSLog(@"Exception %@ raised in search index; exiting thread run loop.", [localException name]);
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
        [notificationLock lock];
        [notificationQueue addObject:note];
        [notificationLock unlock];
        [notificationPort sendBeforeDate:[NSDate date] components:nil from:nil reserved:0];
        
    } else {
        // this is a background thread that can handle these notifications
        if([[note name] isEqualToString:BDSKBibItemChangedNotification])
            [self handleBibItemChangedNotification:note];
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

    BibItem *pub = [[note userInfo] valueForKey:@"pub"];
    OBPRECONDITION(pub);
    
    [self indexFilesForItem:pub];
    
    [delegate performSelectorOnMainThread:@selector(updateSearchIfNeeded) withObject:nil waitUntilDone:NO];
}
- (void)handleDocDelItemNotification:(NSNotification *)note
{

    BibItem *anItem = [[note userInfo] valueForKey:@"pub"];
    OBPRECONDITION(anItem);
    
    NSURL *url = nil;
    
    SKDocumentRef skDocument;
    volatile Boolean success;
    
    NSArray *urlFields = [[OFPreferenceWrapper sharedPreferenceWrapper] stringArrayForKey:BDSKLocalFileFieldsKey];
    unsigned int fieldCnt, maxFields = [urlFields count];
    NSString *urlFieldName = nil;
    
    NSAssert(maxFields, @"No local url fields are defined");
    
    for(fieldCnt = 0; fieldCnt < maxFields; fieldCnt++){
        
        urlFieldName = [urlFields objectAtIndex:fieldCnt];
        url = [anItem URLForField:urlFieldName];
        if(!url) continue;
        
        skDocument = SKDocumentCreateWithURL((CFURLRef)url);
        OBPOSTCONDITION(skDocument);
        if(!skDocument) continue;
        
        [indexLock lock];
        success = SKIndexRemoveDocument(index, skDocument);
        [indexLock unlock];
        OBPOSTCONDITION(success);
        
        CFRelease(skDocument);
    }

    [delegate performSelectorOnMainThread:@selector(updateSearchIfNeeded) withObject:nil waitUntilDone:NO];
}

- (void)handleBibItemChangedNotification:(NSNotification *)note
{

    NSDictionary *userInfo = [note userInfo];
    id noteDocument = [userInfo valueForKey:@"document"];
    
    if(document != noteDocument)
        return;
    
    NSString *changedKey = [userInfo objectForKey:@"key"];
    
    if(![[[OFPreferenceWrapper sharedPreferenceWrapper] stringArrayForKey:BDSKLocalFileFieldsKey] containsObject:changedKey])
        return;
    
    // from here on we're guaranteed to have a local file field
    pthread_rwlock_wrlock(&indexStatusLock);
    flags.isIndexing = YES;
    pthread_rwlock_unlock(&indexStatusLock);
    
    // reindex all the files; unless you have many local files attached to the item, there won't be much savings vs. just adding the one that changed
    [self indexFilesForItem:[note object]];
    
    SKDocumentRef skDocument = NULL;      
    
    // remove the old document from the index
    NSString *oldValue = [userInfo valueForKey:@"oldValue"];
    if(![NSString isEmptyString:oldValue]){
        
        // try to create a valid URL from the string (which may be a path or a string representation of a URL); if it's a path, -[NSURL scheme] will return nil
        NSURL *oldURL = [NSURL URLWithString:oldValue];
        if(oldURL == nil || [oldURL scheme] == nil)
            oldURL = [NSURL fileURLWithPath:[oldValue stringByNormalizingPath]];
        
        OBPRECONDITION([oldURL isFileURL]);
        skDocument = SKDocumentCreateWithURL((CFURLRef)oldURL);
        if(oldURL != nil && skDocument != NULL){
            OBPOSTCONDITION(skDocument);
            [indexLock lock];
            SKIndexRemoveDocument(index, skDocument);            
            [indexLock unlock];
            CFRelease(skDocument);
        }
    }
    
    pthread_rwlock_wrlock(&indexStatusLock);
    flags.isIndexing = NO;
    pthread_rwlock_unlock(&indexStatusLock);

    [delegate performSelectorOnMainThread:@selector(updateSearchIfNeeded) withObject:nil waitUntilDone:NO];
}    

- (void)handleMachMessage:(void *)msg
{

    [notificationLock lock];
    while ( [notificationQueue count] ) {
        NSNotification *note = [[notificationQueue objectAtIndex:0] retain];
        [notificationQueue removeObjectAtIndex:0];
        [notificationLock unlock];
        [self processNotification:note];
        [note release];
        [notificationLock lock];
    };
    [notificationLock unlock];
}

@end
