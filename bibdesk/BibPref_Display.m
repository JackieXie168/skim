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
    
    NSMutableArray *availableFontFamilies = [[[NSFontManager sharedFontManager] availableFontFamilies] mutableCopy];
    
    [previewFontPopup removeAllItems];
    [previewFontPopup addItemsWithTitles:[availableFontFamilies sortedArrayUsingSelector:@selector(compare:)]];
    [previewFontPopup selectItemWithTitle:[defaults objectForKey:BDSKPreviewPaneFontFamilyKey]];
    [availableFontFamilies release];
    
    NSMutableArray *availableFonts = [[[NSFontManager sharedFontManager] availableFonts] mutableCopy];
    
    [tableViewFontPopup removeAllItems];
    [tableViewFontPopup addItemsWithTitles:[availableFonts sortedArrayUsingSelector:@selector(compare:)]];
    [tableViewFontPopup selectItemWithTitle:[defaults objectForKey:BDSKTableViewFontKey]];
    [availableFonts release];
    
    [previewMaxNumberComboBox addItemsWithObjectValues:[NSArray arrayWithObjects:NSLocalizedString(@"All", @"All"), @"1", @"5", @"10", @"20", nil]];
    [self updateUI];
}

- (IBAction)selectPreviewFont:(id)sender{
    if([sender isKindOfClass:[NSPopUpButton class]])
        [defaults setObject:[sender titleOfSelectedItem] forKey:BDSKPreviewPaneFontFamilyKey];
    else if([sender isKindOfClass:[NSTextField class]])
        [defaults setFloat:[previewFontSizeField floatValue] forKey:BDSKPreviewBaseFontSizeKey];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:BDSKPreviewPaneFontChangedNotification object:nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:BDSKPreviewDisplayChangedNotification object:nil];
}

- (void)updateUI{
    [tableViewFontSizeField setFloatValue:[defaults floatForKey:BDSKTableViewFontSizeKey]];
    [previewFontSizeField setFloatValue:[defaults floatForKey:BDSKPreviewBaseFontSizeKey]];
    
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

- (IBAction)chooseFont:(id)sender{
    if([sender isKindOfClass:[NSPopUpButton class]])
        [defaults setObject:[sender titleOfSelectedItem] forKey:BDSKTableViewFontKey];
    else if([sender isKindOfClass:[NSTextField class]])
        [defaults setFloat:[sender floatValue] forKey:BDSKTableViewFontSizeKey];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:BDSKTableViewFontChangedNotification
                                                        object:nil];
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

@end
