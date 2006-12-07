//
//  BibPref_Display.m
//  Bibdesk
//
//  Created by Adam Maxwell on 07/25/05.
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

#import "BibPref_Display.h"


@implementation BibPref_Display

- (void)awakeFromNib{
    [super awakeFromNib];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handlePreviewDisplayChangedNotification:)
                                                 name:BDSKPreviewDisplayChangedNotification
                                               object:nil];
    
    [previewMaxNumberComboBox addItemsWithObjectValues:[NSArray arrayWithObjects:NSLocalizedString(@"All", @"All"), @"1", @"5", @"10", @"20", nil]];
    [self updateUI];
}

- (void)updateUI{
    [displayPrefRadioMatrix selectCellWithTag:[defaults integerForKey:BDSKPreviewDisplayKey]];
	
    int maxNumber = [defaults integerForKey:BDSKPreviewMaxNumberKey];
	if (maxNumber == 0)
		[previewMaxNumberComboBox setStringValue:NSLocalizedString(@"All",@"All")];
	else 
		[previewMaxNumberComboBox setIntValue:maxNumber];
    
    int tag, tagMax = 2;
    OBPRECONDITION([authorNameMatrix numberOfColumns] == 1);
    OBPRECONDITION([authorNameMatrix numberOfRows] == tagMax + 1);
    for(tag = 0; tag <= tagMax; tag++){
        NSButtonCell *cell = [authorNameMatrix cellWithTag:tag];
        OBPOSTCONDITION(cell);
        NSString *prefKey = nil;
        switch(tag){
            case 0:
                prefKey = BDSKShouldDisplayFirstNamesKey;
                break;
            case 1:
                prefKey = BDSKShouldAbbreviateFirstNamesKey;
                break;
            case 2:
                prefKey = BDSKShouldDisplayLastNameFirstKey;
                break;
            default:
                [NSException raise:NSInvalidArgumentException format:@"Unrecognized cell %@ with tag %d", cell, [cell tag]];
        }
        OBPOSTCONDITION(prefKey);
        [cell setState:([defaults boolForKey:prefKey] ? NSOnState : NSOffState)];
    }
    
}    

- (void)handlePreviewDisplayChangedNotification:(NSNotification *)notification{
    [self updateUI];
}

- (IBAction)changePreviewDisplay:(id)sender{
    int tag = [[sender selectedCell] tag];
    if(tag != [defaults integerForKey:BDSKPreviewDisplayKey]){
        [defaults setInteger:tag forKey:BDSKPreviewDisplayKey];
        [[NSNotificationCenter defaultCenter] postNotificationName:BDSKPreviewDisplayChangedNotification object:nil];
    }
}

- (IBAction)changePreviewMaxNumber:(id)sender{
    int maxNumber = [[[sender cell] objectValueOfSelectedItem] intValue]; // returns 0 if not a number (as in @"All")
    if(maxNumber != [defaults integerForKey:BDSKPreviewMaxNumberKey]){
		[defaults setInteger:maxNumber forKey:BDSKPreviewMaxNumberKey];
		[[NSNotificationCenter defaultCenter] postNotificationName:BDSKPreviewDisplayChangedNotification object:nil];
	}
	[self updateUI];
}

//
// sorting prefs code
//

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
    return [[[OFPreferenceWrapper sharedPreferenceWrapper] arrayForKey:BDSKIgnoredSortTermsKey] objectAtIndex:rowIndex];
}

- (int)numberOfRowsInTableView:(NSTableView *)aTableView
{
    return [[[OFPreferenceWrapper sharedPreferenceWrapper] arrayForKey:BDSKIgnoredSortTermsKey] count];
}

- (void)tableView:(NSTableView *)aTableView setObjectValue:(id)anObject forTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
    NSMutableArray *mutableArray = [[[OFPreferenceWrapper sharedPreferenceWrapper] arrayForKey:BDSKIgnoredSortTermsKey] mutableCopy];
    [mutableArray replaceObjectAtIndex:rowIndex withObject:anObject];
    [[OFPreferenceWrapper sharedPreferenceWrapper] setObject:mutableArray forKey:BDSKIgnoredSortTermsKey];
    [mutableArray release];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:BDSKResortDocumentNotification object:nil];
}

- (IBAction)addTerm:(id)sender
{
    NSMutableArray *mutableArray = [[[OFPreferenceWrapper sharedPreferenceWrapper] arrayForKey:BDSKIgnoredSortTermsKey] mutableCopy];
    if(!mutableArray)
        mutableArray = [[NSMutableArray alloc] initWithCapacity:1];
    [mutableArray addObject:NSLocalizedString(@"Edit or delete this text", @"")];
    [[OFPreferenceWrapper sharedPreferenceWrapper] setObject:mutableArray forKey:BDSKIgnoredSortTermsKey];
    [tableView reloadData];
    [tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:[mutableArray count] - 1] byExtendingSelection:NO];
    [tableView editColumn:0 row:[tableView selectedRow] withEvent:nil select:YES];
    [mutableArray release];
    [[NSNotificationCenter defaultCenter] postNotificationName:BDSKStopWordsChangedNotification object:nil];
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
    [removeButton setEnabled:([tableView numberOfSelectedRows] > 0)];
}

- (IBAction)removeSelectedTerm:(id)sender
{
    [[[OAPreferenceController sharedPreferenceController] window] makeFirstResponder:tableView];  // end editing 
    NSMutableArray *mutableArray = [[[OFPreferenceWrapper sharedPreferenceWrapper] arrayForKey:BDSKIgnoredSortTermsKey] mutableCopy];
    
    int selRow = [tableView selectedRow];
    NSAssert(selRow >= 0, @"row must be selected in order to delete");
    
    [mutableArray removeObjectAtIndex:selRow];
    [[OFPreferenceWrapper sharedPreferenceWrapper] setObject:mutableArray forKey:BDSKIgnoredSortTermsKey];
    [mutableArray release];
    [tableView reloadData];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:BDSKResortDocumentNotification object:nil];
}

- (IBAction)changeAuthorDisplay:(id)sender;
{
    OBPRECONDITION(sender == authorNameMatrix);
    NSButtonCell *clickedCell = [sender selectedCell];
    NSString *prefKey = nil;
    switch([clickedCell tag]){
        case 0:
            prefKey = BDSKShouldDisplayFirstNamesKey;
            break;
        case 1:
            prefKey = BDSKShouldAbbreviateFirstNamesKey;
            break;
        case 2:
            prefKey = BDSKShouldDisplayLastNameFirstKey;
            break;
        default:
            [NSException raise:NSInvalidArgumentException format:@"Unrecognized cell %@ with tag %d", clickedCell, [clickedCell tag]];
    }
    OBPOSTCONDITION(prefKey);
    [defaults setBool:([clickedCell state] == NSOnState) forKey:prefKey];
    [self updateUI];
    [[NSNotificationCenter defaultCenter] postNotificationName:BDSKPreviewDisplayChangedNotification object:nil];
    // all we really want to do is force a -[NSTableView reloadData] here
    [[NSNotificationCenter defaultCenter] postNotificationName:BDSKResortDocumentNotification object:nil];
}


- (NSFont *)currentFont{
    NSString *fontNameKey = nil;
    NSString *fontSizeKey = nil;
    switch ([fontElementPopup indexOfSelectedItem]) {
        case 0:
            fontNameKey = BDSKMainTableViewFontNameKey;
            fontSizeKey = BDSKMainTableViewFontSizeKey;
            break;
        case 1:
            fontNameKey = BDSKGroupTableViewFontNameKey;
            fontSizeKey = BDSKGroupTableViewFontSizeKey;
            break;
        case 2:
            fontNameKey = BDSKPersonTableViewFontNameKey;
            fontSizeKey = BDSKPersonTableViewFontSizeKey;
            break;
        case 3:
            fontNameKey = BDSKPreviewPaneFontFamilyKey;
            fontSizeKey = BDSKPreviewBaseFontSizeKey;
            break;
        case 4:
            fontNameKey = BDSKEditorFontNameKey;
            fontSizeKey = BDSKEditorFontSizeKey;
            break;
        default:
            return nil;
    }
    return [NSFont fontWithName:[defaults objectForKey:fontNameKey] size:[defaults floatForKey:fontSizeKey]];
}

- (void)setCurrentFont:(NSFont *)font{
    NSString *fontNameKey = nil;
    NSString *fontSizeKey = nil;
    NSString *notificationName = nil;
    switch ([fontElementPopup indexOfSelectedItem]) {
        case 0:
            fontNameKey = BDSKMainTableViewFontNameKey;
            fontSizeKey = BDSKMainTableViewFontSizeKey;
            notificationName = BDSKMainTableViewFontChangedNotification;
            break;
        case 1:
            fontNameKey = BDSKGroupTableViewFontNameKey;
            fontSizeKey = BDSKGroupTableViewFontSizeKey;
            notificationName = BDSKGroupTableViewFontChangedNotification;
            break;
        case 2:
            fontNameKey = BDSKPersonTableViewFontNameKey;
            fontSizeKey = BDSKPersonTableViewFontSizeKey;
            notificationName = BDSKPersonTableViewFontChangedNotification;
            break;
        case 3:
            [defaults setObject:[font familyName] forKey:BDSKPreviewPaneFontFamilyKey];
            [defaults setFloat:[font pointSize] forKey:BDSKPreviewBaseFontSizeKey];
            [[NSNotificationCenter defaultCenter] postNotificationName:BDSKPreviewPaneFontChangedNotification object:nil];
            [[NSNotificationCenter defaultCenter] postNotificationName:BDSKPreviewDisplayChangedNotification object:nil];
            return;
        case 4:
            fontNameKey = BDSKEditorFontNameKey;
            fontSizeKey = BDSKEditorFontSizeKey;
            notificationName = BDSKEditorTextViewFontChangedNotification;
            break;
        default:
            return;
    }
    [defaults setObject:[font fontName] forKey:fontNameKey];
    [defaults setFloat:[font pointSize] forKey:fontSizeKey];
    [[NSNotificationCenter defaultCenter] postNotificationName:notificationName object:nil];
}

- (void)changeFont:(id)sender{
	NSFontManager *fontManager = [NSFontManager sharedFontManager];
	NSFont *font = [self currentFont];
	
    if (font == nil)
		font = [NSFont systemFontOfSize:[NSFont systemFontSize]];
    font = [fontManager convertFont:font];
    
    [self setCurrentFont:font];
}

- (IBAction)changeFontElement:(id)sender{
    [self updateFontPanel:nil];
    [[NSFontManager sharedFontManager] orderFrontFontPanel:sender];
}

- (void)updateFontPanel:(NSNotification *)notification{
	NSFont *font = [self currentFont];
    if (font == nil)
		font = [NSFont systemFontOfSize:[NSFont systemFontSize]];
	[[NSFontManager sharedFontManager] setSelectedFont:font isMultiple:NO];
	[[NSFontManager sharedFontManager] setAction:@selector(localChangeFont:)];
}

- (void)resetFontPanel:(NSNotification *)notification{
	[[NSFontManager sharedFontManager] setAction:@selector(changeFont:)];
}

- (void)didBecomeCurrentPreferenceClient{
    [self updateFontPanel:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateFontPanel:)
                                                 name:NSWindowDidBecomeMainNotification
                                               object:[[self controlBox] window]];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(resetFontPanel:)
                                                 name:NSWindowDidResignMainNotification
                                               object:[[self controlBox] window]];
}

- (void)resignCurrentPreferenceClient{
    [self resetFontPanel:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:NSWindowDidBecomeMainNotification
                                                  object:[[self controlBox] window]];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:NSWindowDidResignMainNotification
                                                  object:[[self controlBox] window]];
    
}

@end


@implementation OAPreferenceController (BDSKFontExtension)

- (void)localChangeFont:(id)sender{
    if ([nonretained_currentClient respondsToSelector:@selector(changeFont:)])
        [nonretained_currentClient performSelector:@selector(changeFont:) withObject:sender];
}

@end

