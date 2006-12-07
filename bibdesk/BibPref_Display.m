//
//  BibPref_Display.m
//  Bibdesk
//
//  Created by Adam Maxwell on 07/25/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

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

@end
