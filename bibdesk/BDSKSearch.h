//
//  BDSKSearch.h
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

#import <Cocoa/Cocoa.h>
#import "BDSKSearchIndex.h"

@class BDSKSearchIndex, BDSKSearch, BDSKSearchPrivateIvars;

@protocol BDSKSearchDelegate <NSObject>
- (void)search:(BDSKSearch *)aSearch didUpdateWithResults:(NSArray *)anArray;
- (void)search:(BDSKSearch *)aSearch didFinishWithResults:(NSArray *)anArray;
@end

@interface BDSKSearch : NSObject <BDSKSearchIndexDelegate>
{
    @private
    SKSearchRef search;
    BDSKSearchIndex *searchIndex;
    NSMutableSet *searchResults;
    
    NSString *searchString;
    SKSearchOptions options;
   
    BDSKSearchPrivateIvars *data;
    id delegate;
}

- (id)initWithIndex:(BDSKSearchIndex *)anIndex delegate:(id <BDSKSearchDelegate>)aDelegate;
- (void)searchForString:(NSString *)aString withOptions:(SKSearchOptions)opts;

- (void)setDelegate:(id <BDSKSearchDelegate>)aDelegate;
- (id)delegate;
- (void)cancel;

@end

