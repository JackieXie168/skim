//
//  SKGroupedSearchResult.m
//  Skim
//
//  Created by Christiaan Hofman on 4/29/08.
/*
 This software is Copyright (c) 2008-2014
 Christiaan Hofman. All rights reserved.

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:

 - Redistributions of source code must retain the above copyright
   notice, this list of conditions and the following disclaimer.

 - Redistributions in binary form must reproduce the above copyright
    notice, this list of conditions and the following disclaimer in
    the documentation and/or other materials provided with the
    distribution.

 - Neither the name of Christiaan Hofman nor the names of any
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

#import "SKGroupedSearchResult.h"
#import "PDFPage_SKExtensions.h"
#import "NSGeometry_SKExtensions.h"

NSString *SKGroupedSearchResultCountKey = @"count";

@implementation SKGroupedSearchResult

@synthesize page, maxCount, matches;
@dynamic pageIndex, count;

+ (id)groupedSearchResultWithPage:(PDFPage *)aPage maxCount:(NSUInteger)aMaxCount {
    return [[[self alloc] initWithPage:aPage maxCount:aMaxCount] autorelease];
}

- (id)initWithPage:(PDFPage *)aPage maxCount:(NSUInteger)aMaxCount {
    self = [super init];
    if (self) {
        page = [aPage retain];
        maxCount = aMaxCount;
        matches = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)dealloc {
    SKDESTROY(page);
    SKDESTROY(matches);
    [super dealloc];
}

- (NSUInteger)pageIndex {
    return [page pageIndex];
}

- (NSUInteger)count {
    return [matches count];
}

- (void)addMatch:(PDFSelection *)match {
    [self willChangeValueForKey:SKGroupedSearchResultCountKey];
    NSRect bounds = [match boundsForPage:page];
    NSInteger i = [matches count];
    while (i-- > 0) {
        PDFSelection *prevResult = [matches objectAtIndex:i];
        if (SKCompareRects(bounds, [prevResult boundsForPage:page]) != NSOrderedAscending)
            break;
    }
    [matches insertObject:match atIndex:i + 1];
    [self didChangeValueForKey:SKGroupedSearchResultCountKey];
}

@end
