//
//  BDSKSearch.m
//  Bibdesk
//
//  Created by Adam Maxwell on 10/13/06.
/*
 This software is Copyright (c) 2006
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

#import "BDSKSearch.h"
#import "NSImage+ToolBox.h"
#import "BDSKSearchResult.h"
#import "BDSKSearchIndex.h"

@interface BDSKSearchPrivateIvars : NSObject
{
 @private
    SKDocumentID *__ids;
    float *__scores;
    size_t __indexSize;
    
    SKDocumentRef *__docs;
    size_t __resultSize;
}

- (SKDocumentID *)documentIDBuffer;
- (float *)scoreBuffer;
- (SKDocumentRef *)documentRefBuffer;
- (BOOL)changeIndexSize:(size_t)size;
- (BOOL)changeResultSize:(size_t)size;

@end

@interface BDSKSearch (Private)

- (void)setSearchString:(NSString *)aString;
- (void)setOptions:(SKSearchOptions)opts;
- (void)updateSearchResults;
- (void)setSearch:(SKSearchRef)aSearch;
- (void)normalizeScoresWithMaximumValue:(double)maxValue;

@end

@implementation BDSKSearch

- (id)initWithIndex:(BDSKSearchIndex *)anIndex delegate:(id <BDSKSearchDelegate>)aDelegate;
{
    NSParameterAssert(nil != anIndex);
    if ((self = [super init])) {
        searchIndex = [anIndex retain];
        [anIndex setDelegate:self];
        searchResults = [[NSMutableSet alloc] initWithCapacity:128];
        
        data = [[BDSKSearchPrivateIvars alloc] init];
        [self setDelegate:aDelegate];
    }
    return self;
}

- (void)dealloc
{
    [self setSearch:NULL];
    [searchIndex setDelegate:nil];
    [searchIndex release];
    [searchResults release];
    [data release];
    [super dealloc];
}

- (void)cancel;
{
    [self setSearch:NULL];
    [searchResults removeAllObjects];
}

- (void)searchForString:(NSString *)aString withOptions:(SKSearchOptions)opts;
{
    [self setSearchString:aString];
    [self setOptions:opts];
    [self updateSearchResults];
    [[self delegate] search:self didUpdateWithResults:[searchResults allObjects]];
}

- (void)searchIndexDidUpdate:(BDSKSearchIndex *)index;
{
    if ([index isEqual:searchIndex]) {
        
        // if there's a search in progress, we'll cancel it and re-update
        // if not, we'll notify the delegate with an empty array, since the index is still working
        if (NULL != search) {
            [self cancel];
            [self updateSearchResults];
        }
        [[self delegate] search:self didUpdateWithResults:[searchResults allObjects]];
    }
}

- (void)searchIndexDidFinishInitialIndexing:(BDSKSearchIndex *)index;
{
    if ([index isEqual:searchIndex]) {
        [self searchIndexDidUpdate:index];
        [[self delegate] search:self didFinishWithResults:[searchResults allObjects]];
    }
}

- (void)setDelegate:(id <BDSKSearchDelegate>)aDelegate;
{
    NSParameterAssert(nil == aDelegate || [aDelegate conformsToProtocol:@protocol(BDSKSearchDelegate)]);
    delegate = aDelegate;
}

- (id)delegate { return delegate; }

@end


@implementation BDSKSearch (Private)

- (void)setSearch:(SKSearchRef)aSearch;
{
    if (aSearch)
        CFRetain(aSearch);
    if (search) {
        SKSearchCancel(search);
        CFRelease(search);
    }
    search = aSearch;
}

- (void)updateSearchResults;
{    
    SKIndexRef skIndex = [searchIndex index];
    NSAssert(NULL != skIndex, @"-[BDSKSearchIndex index] returned NULL");
    
    if (SKIndexFlush(skIndex) ==  FALSE) {
        NSLog(@"failed to flush index %@", searchIndex);
        return;
    }
    
    SKSearchRef skSearch = SKSearchCreate(skIndex, (CFStringRef)searchString, options);
    [self setSearch:skSearch];
    CFRelease(skSearch);
    
    // max number of documents we expect
    CFIndex maxCount = SKIndexGetDocumentCount(skIndex);
    
    NSAssert1([data changeIndexSize:maxCount], @"Unable to allocate memory for index of size %d", maxCount);

    CFIndex actualCount;
    
    float *scores = [data scoreBuffer];
    SKDocumentID *documentIDs = [data documentIDBuffer];
    
    SKSearchFindMatches(search, maxCount, documentIDs, scores, 10, &actualCount);
    
    [searchResults removeAllObjects];
    
    if (actualCount > 0) {
        
        NSAssert1([data changeResultSize:actualCount], @"Unable to allocate memory for %d results", actualCount);
        
        SKDocumentRef *skDocuments = [data documentRefBuffer];
        SKIndexCopyDocumentRefsForDocumentIDs(skIndex, actualCount, documentIDs, skDocuments);
        
        BDSKSearchResult *searchResult;
        SKDocumentRef skDocument;
        
        double maxValue = 0.0;
                
        while (actualCount--) {
            
            float score = *scores++;
            skDocument = *skDocuments++;
            
            // these scores are arbitrarily scaled, so we'll keep track of the search kit's max/min values
            maxValue = MAX(score, maxValue);
            
            searchResult = [[BDSKSearchResult alloc] initWithIndex:searchIndex documentRef:skDocument score:score];            
            [searchResults addObject:searchResult];            
            [searchResult release];
            
            CFRelease(skDocument);
        }      
        
        [self normalizeScoresWithMaximumValue:maxValue];
        
    }    
}

// we need to normalize each batch of results returned from SKSearchFindMatches separately
- (void)normalizeScoresWithMaximumValue:(double)maxValue;
{
    NSEnumerator *resultEnumerator = [searchResults objectEnumerator];
    BDSKSearchResult *result;
    
    while (result = [resultEnumerator nextObject]) {
        double score = [[result valueForKey:@"score"] doubleValue];
        score = score / maxValue * 5;
        NSNumber *normalizedScore = [[NSNumber alloc] initWithDouble:score];
        [result setValue:normalizedScore forKey:@"score"];
        [normalizedScore release];
    }
}

- (void)setSearchString:(NSString *)aString;
{
    if (searchString != aString) {
        [searchString release];
        searchString = [aString copy];
    }
}

- (void)setOptions:(SKSearchOptions)opts;
{
    options = opts;
}

@end

// wrapper around a few pointers to clean up the interface
// we don't realloc buffers to a smaller size (which might happens as fewer results are returned)

@implementation BDSKSearchPrivateIvars

- (id)init
{
    self = [super init];
    
    __indexSize = 0;
    __ids = NULL;
    __scores = NULL;
    
    __resultSize = 0;
    __docs = NULL;
    
    return self;
}

- (void)dealloc
{
    if (__ids) NSZoneFree(NSZoneFromPointer(__ids), __ids);
    if (__docs) NSZoneFree(NSZoneFromPointer(__docs), __docs);
    if (__scores) NSZoneFree(NSZoneFromPointer(__scores), __scores);
    [super dealloc];
}

- (BOOL)changeIndexSize:(size_t)size;
{
    if ((!__ids && !__scores) || __indexSize < size) {
        __ids = (SKDocumentID *)NSZoneRealloc([self zone], __ids, size * sizeof(SKDocumentID));
        __scores = (float *)NSZoneRealloc([self zone], __scores, size * sizeof(float));
        __indexSize = size;
    } 
    return NULL != __scores && NULL != __ids;
}

- (BOOL)changeResultSize:(size_t)size;
{
    if (!__docs || __resultSize < size) {
        __docs = (SKDocumentRef *)NSZoneRealloc([self zone], __docs, size * sizeof(SKDocumentRef));
        __resultSize = size;
    }
    return NULL != __docs;
}

- (SKDocumentID *)documentIDBuffer { return __ids; }
- (float *)scoreBuffer { return __scores; }
- (SKDocumentRef *)documentRefBuffer { return __docs; }

@end