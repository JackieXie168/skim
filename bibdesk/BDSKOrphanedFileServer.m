//
//  BDSKOrphanedFileServer.m
//  Bibdesk
//
//  Created by Adam Maxwell on 08/13/06.
/*
 This software is Copyright (c) 2006,2007
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

#import "BDSKOrphanedFileServer.h"
#import "UKDirectoryEnumerator.h"
#import "NSURL_BDSKExtensions.h"
#import "BDSKFile.h"

@interface BDSKOrphanedFileServer (PrivateServerThread)

// these messages should only be sent on the server thread
- (void)checkAllFilesInDirectoryRootedAtURL:(NSURL *)theURL;
- (void)setBaseURL:(NSURL *)theURL;
- (void)setKnownFiles:(NSSet *)theFiles;
- (void)flushFoundFiles;
- (void)clearFoundFiles;

@end

#pragma mark -

@implementation BDSKOrphanedFileServer

- (id)init;
{
    self = [super init];
    if(self){
        foundFiles = [[NSMutableArray alloc] initWithCapacity:32];
        knownFiles = nil;
        baseURL = nil;
        keepEnumerating = 0;
        allFilesEnumerated = 0;
        delegate = nil;
    }
    return self;
}

- (void)dealloc
{
    [foundFiles release];
    [knownFiles release];
    [baseURL release];
    [super dealloc];
}

// superclass overrides

- (Protocol *)protocolForServerThread { return @protocol(BDSKOrphanedFileServerThread); }

- (Protocol *)protocolForMainThread { return @protocol(BDSKOrphanedFileServerMainThread); }

#pragma mark API

- (id)delegate { return delegate; }

- (void)setDelegate:(id)newDelegate { delegate = newDelegate; }

- (BOOL)allFilesEnumerated { return (BOOL)(1 == allFilesEnumerated); }

- (void)stopEnumerating { OSAtomicCompareAndSwap32Barrier(1, 0, &keepEnumerating); }

#pragma mark Server thread protocol

- (oneway void)checkForOrphansWithKnownFiles:(bycopy NSSet *)theFiles baseURL:(bycopy NSURL *)theURL;
{
    // set the stop flag so enumeration ceases
    // CMH: is this necessary, shouldn't we already be done as we're on the same thread?
    OSAtomicCompareAndSwap32Barrier(1, 0, &keepEnumerating);
    
    // reset our local variables
    [self setKnownFiles:theFiles];
    [self setBaseURL:theURL];
    [self clearFoundFiles];
    
    OSAtomicCompareAndSwap32Barrier(0, 1, &keepEnumerating);
    OSAtomicCompareAndSwap32Barrier(1, 0, &allFilesEnumerated);
    
    // increase file limit for enumerating a home directory http://developer.apple.com/qa/qa2001/qa1292.html
    struct rlimit limit;
    int err;
    
    err = getrlimit(RLIMIT_NOFILE, &limit);
    if (err == 0) {
        limit.rlim_cur = RLIM_INFINITY;
        (void) setrlimit(RLIMIT_NOFILE, &limit);
    }
        
    // run directory enumerator; if knownFiles doesn't contain object, add to foundFiles
    [self checkAllFilesInDirectoryRootedAtURL:baseURL];
    
    // see if we have some left in the cache
    [self flushFoundFiles];
    
    // keepEnumerating is 0 when enumeration was stopped
    if (keepEnumerating == 1)
        OSAtomicCompareAndSwap32Barrier(0, 1, &allFilesEnumerated);
    
    // notify the delegate that we're done
    [[self serverOnMainThread] serverDidFinish];
}

#pragma mark Main thread protocol

- (oneway void)serverFoundFiles:(bycopy NSArray *)newFiles;
{
    if ([delegate respondsToSelector:@selector(orphanedFileServer:foundFiles:)])
        [delegate orphanedFileServer:self foundFiles:newFiles];
}

- (oneway void)serverDidFinish;
{
    if ([delegate respondsToSelector:@selector(orphanedFileServerDidFinish:)])
        [delegate orphanedFileServerDidFinish:self];
}

@end

#pragma mark -

@implementation BDSKOrphanedFileServer (PrivateServerThread)

// must not be oneway; we need to wait for this method to return and set a flag when enumeration is complete (or been stopped)
- (void)checkAllFilesInDirectoryRootedAtURL:(NSURL *)theURL
{
    UKDirectoryEnumerator *enumerator = [UKDirectoryEnumerator enumeratorWithURL:theURL];

    // default is 16, which is a bit small (don't set it too large, though, since we use -cacheExhausted to signal that it's time to flush the found files)
    [enumerator setCacheSize:32];
    
    // get visibility and directory flags
    [enumerator setDesiredInfo:(kFSCatInfoFinderInfo | kFSCatInfoNodeFlags)];
    
    BOOL isDir, isHidden;
    BDSKFile *aFile;
    
    while ( (1 == keepEnumerating) && (aFile = [enumerator nextObjectFile]) ){
        
        // periodically flush the cache        
        if([enumerator cacheExhausted] && [foundFiles count] >= 16){
            [self flushFoundFiles];
        }
        
        isDir = [enumerator isDirectory];
        isHidden = [enumerator isInvisible] || CFStringHasPrefix((CFStringRef)[aFile fileName], CFSTR("."));
        
        // ignore hidden files
        if (isHidden)
            continue;
        
        if (isDir){
            
            // resolve aliases in parent directories, since that's what BibItem does
            NSURL *resolvedURL = (NSURL *)BDCopyFileURLResolvingAliases((CFURLRef)[aFile fileURL]);
            if(resolvedURL){
                // recurse
                [self checkAllFilesInDirectoryRootedAtURL:resolvedURL];
                CFRelease(resolvedURL);
            }
            
        } else if([knownFiles containsObject:aFile] == NO){
            
            [foundFiles addObject:[aFile fileURL]];
            
        }
        
    }
    
}

- (void)setBaseURL:(NSURL *)theURL;
{
    NSParameterAssert([theURL isFileURL]);
    [baseURL autorelease];
    baseURL = [theURL copy];
}

- (void)setKnownFiles:(NSSet *)theFiles;
{
    [knownFiles autorelease];
    knownFiles = [theFiles copy];
}

- (void)flushFoundFiles;
{
    if([foundFiles count]){
        [[self serverOnMainThread] serverFoundFiles:[[foundFiles copy] autorelease]];
        [self clearFoundFiles];
    }
}

- (void)clearFoundFiles;
{
    [foundFiles removeAllObjects];
}

@end

#pragma mark -
#pragma mark fixes for encoding NSURL

@interface NSURL (BDSK_PortCoderFix) @end

@implementation NSURL (BDSK_PortCoderFix)

- (id)replacementObjectForPortCoder:(NSPortCoder *)encoder
{
    return [encoder isByref] ? (id)[NSDistantObject proxyWithLocal:self connection:[encoder connection]] : self;
}

- (NSComparisonResult)localizedCaseInsensitiveCompare:(NSURL *)other;
{
    return [[self path] localizedCaseInsensitiveCompare:[other path]];
}

@end

