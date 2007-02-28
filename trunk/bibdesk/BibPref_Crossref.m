//
//  BibPref_Crossref.m
//  
//
//  Created by Christiaan Hofman on 28/5/05.
/*
 This software is Copyright (c) 2005,2007
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

#import "BibPref_Crossref.h"
#import "BDSKTypeNameFormatter.h"

@implementation BibPref_Crossref

- (void)awakeFromNib{
    [super awakeFromNib];
	
    typesArray = [[NSMutableArray alloc] initWithCapacity:4];
	[typesArray setArray:[defaults arrayForKey:BDSKTypesForDuplicateBooktitleKey]];
    BDSKTypeNameFormatter *typeNameFormatter = [[BDSKTypeNameFormatter alloc] init];
    [[[[tableView tableColumns] objectAtIndex:0] dataCell] setFormatter:typeNameFormatter];
    [typeNameFormatter release];
    
    [OFPreference addObserver:self selector:@selector(handleEditInheritedChanged:) forPreference:[OFPreference preferenceForKey:BDSKWarnOnEditInheritedKey]];
}

- (void)dealloc{
    [OFPreference removeObserver:self forPreference:nil];
    [typesArray release];
    [super dealloc];
}

- (void)updateUI{
	BOOL duplicate = [defaults boolForKey:BDSKDuplicateBooktitleKey];
	[tableView reloadData];
    [defaults setObject:typesArray forKey:BDSKTypesForDuplicateBooktitleKey];
    [duplicateBooktitleCheckButton setState:duplicate ? NSOnState : NSOffState];
    [forceDuplicateBooktitleCheckButton setState:[defaults boolForKey:BDSKForceDuplicateBooktitleKey] ? NSOnState : NSOffState];
    [forceDuplicateBooktitleCheckButton setEnabled:duplicate];
	[tableView setEnabled:duplicate];
	[addTypeButton setEnabled:duplicate];
	[deleteTypeButton setEnabled:duplicate];
    [warnOnEditInheritedCheckButton setState:[defaults boolForKey:BDSKWarnOnEditInheritedKey] ? NSOnState : NSOffState];
    [autoSortCheckButton setState:[defaults boolForKey:BDSKAutoSortForCrossrefsKey] ? NSOnState : NSOffState];
}

- (void)handleEditInheritedChanged:(NSNotification *)notification {
    [warnOnEditInheritedCheckButton setState:[defaults boolForKey:BDSKWarnOnEditInheritedKey] ? NSOnState : NSOffState];
}

- (IBAction)changeAutoSort:(id)sender{
    [defaults setBool:([sender state] == NSOnState) forKey:BDSKAutoSortForCrossrefsKey];
	[self valuesHaveChanged];
}

- (IBAction)changeWarnOnEditInherited:(id)sender{
    [defaults setBool:([sender state] == NSOnState) forKey:BDSKWarnOnEditInheritedKey];
	[self valuesHaveChanged];
}

- (IBAction)changeDuplicateBooktitle:(id)sender{
    [defaults setBool:([sender state] == NSOnState) forKey:BDSKDuplicateBooktitleKey];
	[self valuesHaveChanged];
}

- (IBAction)changeForceDuplicateBooktitle:(id)sender{
    [defaults setBool:([sender state] == NSOnState) forKey:BDSKForceDuplicateBooktitleKey];
	[self valuesHaveChanged];
}

- (IBAction)deleteType:(id)sender{
    if([tableView selectedRow] != -1){
        [typesArray removeObjectAtIndex:[tableView selectedRow]];
        [self valuesHaveChanged];
    }
}

- (IBAction)addType:(id)sender{
    NSString *newType = @"type"; // do not localize
    [typesArray addObject:newType];
    int row = [typesArray count] - 1;
    [tableView reloadData];
    [tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
    [tableView editColumn:0 row:row withEvent:nil select:YES];
}

#pragma mark TableView datasource methods

- (int)numberOfRowsInTableView:(NSTableView *)tv{
    return [typesArray count];
}

- (id)tableView:(NSTableView *)tv objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row{
    return [typesArray objectAtIndex:row];
}

- (void)tableView:(NSTableView *)tv setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(int)row{
    if([object isEqualToString:@""])
        [typesArray removeObjectAtIndex:row];
    else
        [typesArray replaceObjectAtIndex:row withObject:[(NSString *)object entryType]];
    [self updateUI];
}

- (BOOL)tableView:(NSTableView *)tv shouldEditTableColumn:(NSTableColumn *)tableColumn row:(int)row{
	return [tv isEnabled];
}

- (BOOL)tableView:(NSTableView *)tv shouldSelectRow:(int)row{
	return [tv isEnabled];
}

@end

@implementation NSTableView (BDSKDisablingTableView)

- (void)setEnabled:(BOOL)flag{
	[super setEnabled:flag];
	if (!flag) [self deselectAll:nil];
}

- (BOOL)acceptsFirstResponder{
	return [self isEnabled];
}

@end
