//
//  SKRecentDocumentInfo.m
//  Skim
//
//  Created by Christiaan Hofman on 23/11/2020.
/*
This software is Copyright (c) 2020
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

#import "SKRecentDocumentInfo.h"
#import "SKAlias.h"

#define PAGEINDEX_KEY @"pageIndex"
#define ALIASDATA_KEY @"_BDAlias"
#define BOOKMARK_KEY  @"bookmark"
#define SNAPSHOTS_KEY @"snapshots"

@implementation SKRecentDocumentInfo

@synthesize pageIndex, snapshots;
@dynamic fileURL, properties;

- (id)initWithProperties:(NSDictionary *)properties {
    self = [super init];
    if (self) {
        NSNumber *pageNumber = [properties objectForKey:PAGEINDEX_KEY];
        pageIndex = pageNumber ? [pageNumber unsignedIntegerValue] : NSNotFound;
        snapshots = [[properties objectForKey:SNAPSHOTS_KEY] copy];
        NSData *data;
        if ((data = [properties objectForKey:ALIASDATA_KEY]))
            alias = [[SKAlias alloc] initWithAliasData:data];
        else if ((data = [properties objectForKey:BOOKMARK_KEY]))
            alias = [[SKAlias alloc] initWithBookmarkData:data];
    }
    return self;
}

- (id)initWithURL:(NSURL *)fileURL pageIndex:(NSUInteger)aPageIndex snapshots:(NSArray *)aSnapshots {
    self = [super init];
    if (self) {
        alias = [[SKAlias alloc] initWithURL:fileURL];
        if (alias) {
            pageIndex = aPageIndex;
            snapshots = [aSnapshots count] ? [aSnapshots copy] : nil;
        } else {
            [self release];
            self = nil;
        }
    }
    return self;
}

- (void)dealloc {
    SKDESTROY(alias);
    SKDESTROY(snapshots);
    [super dealloc];
}

- (NSURL *)fileURL {
    return [alias fileURLNoUI];
}

- (NSDictionary *)properties {
    NSData *data = [alias data];
    NSString *dataKey = [alias isBookmark] ? BOOKMARK_KEY : ALIASDATA_KEY;
    return [NSDictionary dictionaryWithObjectsAndKeys:
            [NSNumber numberWithUnsignedInteger:pageIndex], PAGEINDEX_KEY,
            data, dataKey,
            snapshots, SNAPSHOTS_KEY,
            nil];
}

@end
