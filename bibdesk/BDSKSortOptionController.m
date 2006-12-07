//
//  BDSKSortOptionController.m
//  Bibdesk
//
//  Created by Adam Maxwell on 07/20/05.
//
/*
 This software is Copyright (c) 2005
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

#import "BDSKSortOptionController.h"
#import "BibPrefController.h"

@implementation BDSKSortOptionController

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
}

- (IBAction)addTerm:(id)sender
{
    NSMutableArray *mutableArray = [[[OFPreferenceWrapper sharedPreferenceWrapper] arrayForKey:BDSKIgnoredSortTermsKey] mutableCopy];
    if(!mutableArray)
        mutableArray = [[NSMutableArray alloc] initWithCapacity:1];
    [mutableArray addObject:NSLocalizedString(@"Edit or delete this text", @"")];
    [[OFPreferenceWrapper sharedPreferenceWrapper] setObject:mutableArray forKey:BDSKIgnoredSortTermsKey];
    [tableView reloadData];
    [tableView selectRow:([mutableArray count] - 1) byExtendingSelection:NO];
    [tableView editColumn:0 row:[tableView selectedRow] withEvent:nil select:YES];
    [mutableArray release];
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
    [removeButton setEnabled:([tableView numberOfSelectedRows] > 0)];
}

- (IBAction)removeSelectedTerm:(id)sender
{
    [[self window] makeFirstResponder:tableView];  // end editing 
    NSMutableArray *mutableArray = [[[OFPreferenceWrapper sharedPreferenceWrapper] arrayForKey:BDSKIgnoredSortTermsKey] mutableCopy];
    
    int selRow = [tableView selectedRow];
    NSAssert(selRow >= 0, @"row must be selected in order to delete");
    
    [mutableArray removeObjectAtIndex:selRow];
    [[OFPreferenceWrapper sharedPreferenceWrapper] setObject:mutableArray forKey:BDSKIgnoredSortTermsKey];
    [mutableArray release];
    [tableView reloadData];
}

- (IBAction)endEditingSheet:(id)sender
{
    [[self window] orderOut:sender];
    [NSApp endSheet:[self window] returnCode:[sender tag]];
}
    
- (void)beginEditSortSheetModalForWindow:(NSWindow *)docWindow modalDelegate:(id)modalDelegate didEndSelector:(SEL)didEndSelector contextInfo:(void *)contextInfo;
{
    if (![NSBundle loadNibNamed:[self windowNibName] owner:self]) return NSBeep(); // make sure we loaded the nib

    [NSApp beginSheet:[self window]
       modalForWindow:docWindow
        modalDelegate:modalDelegate
       didEndSelector:didEndSelector
          contextInfo:contextInfo];
}

@end
