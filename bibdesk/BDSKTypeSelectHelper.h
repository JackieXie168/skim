//  BDSKTypeSelectHelper.h
//
//  Created by Christiaan Hofman on 8/11/06.
/*
 This software is Copyright (c) 2005,2006
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

/*
 This class is mostly a copy from OATypeAheadSelectionHelper, 
 modified to accomodate substring matches, adding updates of status 
 messages, and improvement in cycling similar results.
 */

#import <Cocoa/Cocoa.h>

@class OFScheduledEvent;

@interface BDSKTypeSelectHelper : NSObject
{
    id dataSource;
    BOOL cycleResults;
    BOOL matchPrefix;
    
    NSArray *searchCache;
    NSMutableString *searchString;
    OFScheduledEvent *timeoutEvent;
}

- (id)dataSource;
- (void)setDataSource:(id)anObject;

- (BOOL)cyclesSimilarResults;
- (void)setCyclesSimilarResults:(BOOL)newValue;

- (BOOL)matchesPrefix;
- (void)setMatchesPrefix:(BOOL)newValue;

- (void)rebuildTypeSelectSearchCache;
    
- (BOOL)isProcessing;

- (void)processKeyDownCharacter:(unichar)character;

@end


@interface NSObject (BDSKTypeSelectDataSource)

- (NSArray *)typeSelectHelperSelectionItems:(BDSKTypeSelectHelper *)typeSelectHelper; // required
- (unsigned int)typeSelectHelperCurrentlySelectedIndex:(BDSKTypeSelectHelper *)typeSelectHelper; // required
- (void)typeSelectHelper:(BDSKTypeSelectHelper *)typeSelectHelper selectItemAtIndex:(unsigned int)itemIndex; // required

- (void)typeSelectHelper:(BDSKTypeSelectHelper *)typeSelectHelper updateSearchString:(NSString *)searchString; // optional

@end
