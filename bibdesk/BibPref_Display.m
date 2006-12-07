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
#import "BDSKTemplate.h"
#import "BibAuthor.h"


@implementation BibPref_Display

- (void)awakeFromNib{
    [super awakeFromNib];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handlePreviewDisplayChangedNotification:)
                                                 name:BDSKPreviewDisplayChangedNotification
                                               object:nil];
    [OFPreference addObserver:self 
                     selector:@selector(handleTemplatePrefsChangedNotification:) 
                forPreference:[OFPreference preferenceForKey:BDSKExportTemplateTree]];
    
    [self handleTemplatePrefsChangedNotification:nil];
    
    [previewMaxNumberComboBox addItemsWithObjectValues:[NSArray arrayWithObjects:NSLocalizedString(@"All", @"Display all items in preview"), @"1", @"5", @"10", @"20", nil]];
    [self updateUI];
}

- (void)updateUI{
    [displayPrefRadioMatrix selectCellWithTag:[defaults integerForKey:BDSKPreviewDisplayKey]];
	
    int maxNumber = [defaults integerForKey:BDSKPreviewMaxNumberKey];
	if (maxNumber == 0)
		[previewMaxNumberComboBox setStringValue:NSLocalizedString(@"All",@"Display all items in preview")];
	else 
		[previewMaxNumberComboBox setIntValue:maxNumber];
    
    [previewTemplatePopup setEnabled:[defaults integerForKey:BDSKPreviewDisplayKey] == 3];
    
    int tag, tagMax = 2;
    int mask = [defaults integerForKey:BDSKAuthorNameDisplayKey];
    OBPRECONDITION([authorNameMatrix numberOfColumns] == 1);
    OBPRECONDITION([authorNameMatrix numberOfRows] == tagMax + 1);
    for(tag = 0; tag <= tagMax; tag++){
        NSButtonCell *cell = [authorNameMatrix cellWithTag:tag];
        OBPOSTCONDITION(cell);
        [cell setState:(mask & (1 << tag) ? NSOnState : NSOffState)];
        if(1 << tag != BDSKAuthorDisplayFirstNameMask)
            [cell setEnabled:mask & BDSKAuthorDisplayFirstNameMask];
    }
}    

- (void)handleTemplatePrefsChangedNotification:(NSNotification *)notification{
    NSString *currentStyle = [defaults stringForKey:BDSKPreviewTemplateStyleKey];
    NSMutableArray *styles = [NSMutableArray arrayWithArray:[BDSKTemplate allStyleNamesForFileType:@"rtf"]];
    [styles addObjectsFromArray:[BDSKTemplate allStyleNamesForFileType:@"rtfd"]];
    [styles addObjectsFromArray:[BDSKTemplate allStyleNamesForFileType:@"doc"]];
    [styles addObjectsFromArray:[BDSKTemplate allStyleNamesForFileType:@"html"]];
    [previewTemplatePopup removeAllItems];
    [previewTemplatePopup addItemsWithTitles:styles];
    if ([styles containsObject:currentStyle]) {
        [previewTemplatePopup selectItemWithTitle:currentStyle];
    } else if ([styles count]) {
        [previewTemplatePopup selectItemAtIndex:0];
        [defaults setObject:[styles objectAtIndex:0] forKey:BDSKPreviewTemplateStyleKey];
        [defaults autoSynchronize];
        if ([defaults integerForKey:BDSKPreviewDisplayKey] == 3)
            [[NSNotificationCenter defaultCenter] postNotificationName:BDSKPreviewDisplayChangedNotification object:nil];
    }
}

- (void)handlePreviewDisplayChangedNotification:(NSNotification *)notification{
    [self updateUI];
}

- (IBAction)changePreviewDisplay:(id)sender{
    int tag = [[sender selectedCell] tag];
    if(tag != [defaults integerForKey:BDSKPreviewDisplayKey]){
        [defaults setInteger:tag forKey:BDSKPreviewDisplayKey];
        [defaults autoSynchronize];
        [[NSNotificationCenter defaultCenter] postNotificationName:BDSKPreviewDisplayChangedNotification object:nil];
    }
}

- (IBAction)changePreviewMaxNumber:(id)sender{
    int maxNumber = [[[sender cell] objectValueOfSelectedItem] intValue]; // returns 0 if not a number (as in @"All")
    if(maxNumber != [defaults integerForKey:BDSKPreviewMaxNumberKey]){
		[defaults setInteger:maxNumber forKey:BDSKPreviewMaxNumberKey];
        [defaults autoSynchronize];
		[[NSNotificationCenter defaultCenter] postNotificationName:BDSKPreviewDisplayChangedNotification object:nil];
	} else 
        [self updateUI];
}

- (IBAction)changePreviewTemplate:(id)sender{
    NSString *style = [sender title];
    if ([style isEqualToString:[defaults stringForKey:BDSKPreviewTemplateStyleKey]] == NO) {
        [defaults setObject:style forKey:BDSKPreviewTemplateStyleKey];
        [defaults autoSynchronize];
        [[NSNotificationCenter defaultCenter] postNotificationName:BDSKPreviewDisplayChangedNotification object:nil];
    }
}

//
// sorting prefs code
//

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
    return [[defaults arrayForKey:BDSKIgnoredSortTermsKey] objectAtIndex:rowIndex];
}

- (int)numberOfRowsInTableView:(NSTableView *)aTableView
{
    return [[defaults arrayForKey:BDSKIgnoredSortTermsKey] count];
}

- (void)tableView:(NSTableView *)aTableView setObjectValue:(id)anObject forTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
    NSMutableArray *mutableArray = [[defaults arrayForKey:BDSKIgnoredSortTermsKey] mutableCopy];
    [mutableArray replaceObjectAtIndex:rowIndex withObject:anObject];
    [defaults setObject:mutableArray forKey:BDSKIgnoredSortTermsKey];
    [mutableArray release];
    [defaults autoSynchronize];
}

- (IBAction)addTerm:(id)sender
{
    NSMutableArray *mutableArray = [[defaults arrayForKey:BDSKIgnoredSortTermsKey] mutableCopy];
    if(!mutableArray)
        mutableArray = [[NSMutableArray alloc] initWithCapacity:1];
    [mutableArray addObject:NSLocalizedString(@"Edit or delete this text", @"")];
    [defaults setObject:mutableArray forKey:BDSKIgnoredSortTermsKey];
    [tableView reloadData];
    [tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:[mutableArray count] - 1] byExtendingSelection:NO];
    [tableView editColumn:0 row:[tableView selectedRow] withEvent:nil select:YES];
    [mutableArray release];
    [defaults autoSynchronize];
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
    [removeButton setEnabled:([tableView numberOfSelectedRows] > 0)];
}

- (IBAction)removeSelectedTerm:(id)sender
{
    [[[BDSKPreferenceController sharedPreferenceController] window] makeFirstResponder:tableView];  // end editing 
    NSMutableArray *mutableArray = [[defaults arrayForKey:BDSKIgnoredSortTermsKey] mutableCopy];
    
    int selRow = [tableView selectedRow];
    NSAssert(selRow >= 0, @"row must be selected in order to delete");
    
    [mutableArray removeObjectAtIndex:selRow];
    [defaults setObject:mutableArray forKey:BDSKIgnoredSortTermsKey];
    [mutableArray release];
    [tableView reloadData];
    [defaults autoSynchronize];
}

- (IBAction)changeAuthorDisplay:(id)sender;
{
    OBPRECONDITION(sender == authorNameMatrix);
    NSButtonCell *clickedCell = [sender selectedCell];
    int cellMask = 1 << [clickedCell tag];
    int prefMask = [defaults integerForKey:BDSKAuthorNameDisplayKey];
    if([clickedCell state] == NSOnState)
        prefMask |= cellMask;
    else
        prefMask &= ~cellMask;
    [defaults setInteger:prefMask forKey:BDSKAuthorNameDisplayKey];
    [self valuesHaveChanged];
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
            // set the family last as that is observed
            [defaults setFloat:[font pointSize] forKey:BDSKPreviewBaseFontSizeKey];
            [defaults setObject:[font familyName] forKey:BDSKPreviewPaneFontFamilyKey];
            [[NSNotificationCenter defaultCenter] postNotificationName:BDSKPreviewDisplayChangedNotification object:nil];
            [defaults autoSynchronize];
            return;
        case 4:
            fontNameKey = BDSKEditorFontNameKey;
            fontSizeKey = BDSKEditorFontSizeKey;
            break;
        default:
            return;
    }
    // set the name last, as that is observed for changes
    [defaults setFloat:[font pointSize] forKey:fontSizeKey];
    [defaults setObject:[font fontName] forKey:fontNameKey];
    [defaults autoSynchronize];
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

