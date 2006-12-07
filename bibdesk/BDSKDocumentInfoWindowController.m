//
//  BDSKDocumentInfoWindowController.m
//  Bibdesk
//
//  Created by Christiaan Hofman on 5/31/06.
/*
 This software is Copyright (c) 2006
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

#import "BDSKDocumentInfoWindowController.h"
#import "BibDocument.h"
#import "NSDictionary_BDSKExtensions.h"


@implementation BDSKDocumentInfoWindowController

- (id)init {
    self = [self initWithDocument:nil];
    return self;
}

// designated initializer
- (id)initWithDocument:(BibDocument *)aDocument {
    if (self = [super initWithWindowNibName:@"DocumentInfoWindow"]) {
        document = aDocument;
        info = nil;
        keys = nil;
        ignoreEdit = NO;
    }
    return self;
}

- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [info release];
    [keys release];
    [super dealloc];
}

#pragma mark Resetting

- (void)refreshKeys{
    if (keys == nil)
        keys = [[NSMutableArray alloc] init];
    [keys setArray:[info allKeys]];
    [keys sortUsingSelector:@selector(compare:)];
}

- (void)resetInfo{
    if (info == nil)
        info = [[NSMutableDictionary alloc] initForCaseInsensitiveKeys];
    [info setDictionary:[document documentInfo]];
    [self refreshKeys];
}

- (void)updateButtons{
	[removeButton setEnabled:[tableView numberOfSelectedRows] > 0];
}

- (void)awakeFromNib{
    [self resetInfo];
    [self updateButtons];
}

- (void)finalizeChangesIgnoringEdit:(BOOL)flag {
	ignoreEdit = flag;
	if ([[self window] makeFirstResponder:nil] == NO)
        [[self window] endEditingFor:nil];
	ignoreEdit = NO;
}

- (void)windowWillClose:(NSNotification *)notification{
    [self finalizeChangesIgnoringEdit:YES];
}

#pragma mark Showing the window

- (void)prepare{
    [self window]; // make sure the nib is loaded
    [self resetInfo];
    [tableView reloadData];
}

#pragma mark Button actions

- (IBAction)dismiss:(id)sender{
    [self finalizeChangesIgnoringEdit:[sender tag] == NSCancelButton]; // commit edit before reloading
    
    if ([sender tag] == NSOKButton) {
        if ([tableView editedRow] != -1) {
            NSBeep();
            return;
        }
        [document setDocumentInfo:info];
		[[document undoManager] setActionName:NSLocalizedString(@"Change Document Info", @"Undo action name")];
    }
    
    [super dismiss:sender];
}

- (IBAction)addKey:(id)sender{
    // find a unique new key
    int i = 0;
    NSString *newKey = @"key";
    while([info objectForKey:newKey] != nil)
        newKey = [NSString stringWithFormat:@"key%i", ++i];
    
    [info setObject:@"" forKey:newKey];
    [self refreshKeys];
    [tableView reloadData];
    
    int row = [keys indexOfObject:newKey];
    [tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
    [tableView editColumn:0 row:row withEvent:nil select:YES];
}

- (IBAction)removeSelectedKeys:(id)sender{
    // in case we're editing the selected field we need to end editing.
    // we don't give it a chance to modify state.
    [[self window] endEditingFor:[tableView selectedCell]];

    [info removeObjectsForKeys:[keys objectsAtIndexes:[tableView selectedRowIndexes]]];
    [self refreshKeys];
    [tableView reloadData];
}

#pragma mark TableView DataSource methods

- (int)numberOfRowsInTableView:(NSTableView *)tv{
    return [keys count];
}

- (id)tableView:(NSTableView *)tv objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row{
    NSString *key = [keys objectAtIndex:row];
    
    if([[tableColumn identifier] isEqualToString:@"key"]){
         return key;
    }else{
         return [info objectForKey:key];
    }
    
}

- (void)tableView:(NSTableView *)tv setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(int)row{
    if (ignoreEdit) return;
    
    NSString *key = [keys objectAtIndex:row];
    NSString *value = [[[info objectForKey:key] retain] autorelease];
    
    if([[tableColumn identifier] isEqualToString:@"key"]){
		
		if([object isEqualToString:@""]){
			[tv reloadData];
            [tv selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
            [tableView editColumn:0 row:row withEvent:nil select:YES];
    		
            NSAlert *alert = [NSAlert alertWithMessageText:NSLocalizedString(@"Empty Key", @"Message in alert dialog when trying to set an empty string for a key")
                                             defaultButton:NSLocalizedString(@"OK", @"Button title")
                                           alternateButton:nil
                                               otherButton:nil
                                 informativeTextWithFormat:NSLocalizedString(@"The key can not be empty.", @"Informative text in alert dialog when trying to set an empty string for a key")];
            [alert beginSheetModalForWindow:[self window] modalDelegate:nil didEndSelector:NULL contextInfo:NULL];
			return;
		}
        
        if([info objectForKey:object]){
            if([key caseInsensitiveCompare:object] != NSOrderedSame){			
                [tv reloadData];
                [tv selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
                [tableView editColumn:0 row:row withEvent:nil select:YES];
                
                NSAlert *alert = [NSAlert alertWithMessageText:NSLocalizedString(@"Duplicate Key", @"Message in alert dialog when trying to add a duplicate key")
                                                 defaultButton:NSLocalizedString(@"OK", @"Button title")
                                               alternateButton:nil
                                                   otherButton:nil
                                     informativeTextWithFormat:NSLocalizedString(@"The key must be unique.", @"Informative text in alert dialog when trying to add a duplicate key")];
                [alert beginSheetModalForWindow:[self window] modalDelegate:nil didEndSelector:NULL contextInfo:NULL];
			}
            return;
		}
        
        [info removeObjectForKey:key];
        [info setObject:value forKey:object];
        [self refreshKeys];
        
    }else{
        
        if([value isEqualToString:object]) return;
        
        if([value isStringTeXQuotingBalancedWithBraces:YES connected:NO] == NO){
            NSAlert *alert = [NSAlert alertWithMessageText:NSLocalizedString(@"Unbalanced Braces", @"Message in alert dialog when trying to set a value with unbalanced braces")
                                             defaultButton:NSLocalizedString(@"OK", @"Button title")
                                           alternateButton:nil
                                               otherButton:nil
                                 informativeTextWithFormat:NSLocalizedString(@"Braces must be balanced within the value.", @"Informative text in alert dialog")];
            [alert beginSheetModalForWindow:[self window] modalDelegate:nil didEndSelector:NULL contextInfo:NULL];
            
            [tv reloadData];
            [tv selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
            [tableView editColumn:0 row:row withEvent:nil select:YES];
            return;
		}
        
        [info setObject:object forKey:key];
    }
}

#pragma mark TableView Delegate methods

- (void)tableViewSelectionDidChange:(NSNotification *)notification{
    [self updateButtons];
}

@end
