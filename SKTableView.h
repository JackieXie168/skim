//
//  SKTableView.h
//  Skim
//
//  Created by Christiaan Hofman on 8/20/07.
/*
 This software is Copyright (c) 2007-2014
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

#import <Cocoa/Cocoa.h>
#import "SKTypeSelectHelper.h"
#import "SKImageToolTipContext.h"

@protocol SKTableViewDelegate;

@interface SKTableView : NSTableView <SKTypeSelectDelegate> {
    NSMutableSet *trackingAreas;
    SKTypeSelectHelper *typeSelectHelper;
    BOOL supportsQuickLook;
}

@property (nonatomic, readonly) BOOL canDelete, canCopy, canPaste;
@property (nonatomic) BOOL hasImageToolTips, supportsQuickLook;
@property (nonatomic, retain) SKTypeSelectHelper *typeSelectHelper;

- (void)delete:(id)sender;
- (void)copy:(id)sender;
- (void)paste:(id)sender;

- (void)scrollToBeginningOfDocument:(id)sender;
- (void)scrollToEndOfDocument:(id)sender;

- (id <SKTableViewDelegate>)delegate;
- (void)setDelegate:(id <SKTableViewDelegate>)newDelegate;

@end


@protocol SKTableViewDelegate <NSTableViewDelegate>
@optional

- (void)tableView:(NSTableView *)aTableView deleteRowsWithIndexes:(NSIndexSet *)rowIndexes;
- (BOOL)tableView:(NSTableView *)aTableView canDeleteRowsWithIndexes:(NSIndexSet *)rowIndexes;

- (void)tableView:(NSTableView *)aTableView copyRowsWithIndexes:(NSIndexSet *)rowIndexes;
- (BOOL)tableView:(NSTableView *)aTableView canCopyRowsWithIndexes:(NSIndexSet *)rowIndexes;

- (void)tableView:(NSTableView *)aTableView pasteFromPasteboard:(NSPasteboard *)pboard;
- (BOOL)tableView:(NSTableView *)aTableView canPasteFromPasteboard:(NSPasteboard *)pboard;

- (id <SKImageToolTipContext>)tableView:(NSTableView *)aTableView imageContextForRow:(NSInteger)rowIndex;

- (NSArray *)tableView:(NSTableView *)aTableView typeSelectHelperSelectionStrings:(SKTypeSelectHelper *)aTypeSelectHelper;
- (void)tableView:(NSTableView *)aTableView typeSelectHelper:(SKTypeSelectHelper *)aTypeSelectHelper didFailToFindMatchForSearchString:(NSString *)searchString;
- (void)tableView:(NSTableView *)aTableView typeSelectHelper:(SKTypeSelectHelper *)aTypeSelectHelper updateSearchString:(NSString *)searchString;

@end
