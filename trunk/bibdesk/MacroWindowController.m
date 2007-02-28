//
//  MacroWindowController.m
//  BibDesk
//
//  Created by Michael McCracken on 2/21/05.
/*
 This software is Copyright (c) 2005,2007
 Michael O. McCracken. All rights reserved.

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:

 - Redistributions of source code must retain the above copyright
   notice, this list of conditions and the following disclaimer.

 - Redistributions in binary form must reproduce the above copyright
    notice, this list of conditions and the following disclaimer in
    the documentation and/or other materials provided with the
    distribution.

 - Neither the name of Michael O. McCracken nor the names of any
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

#import "MacroWindowController.h"
#import "BDSKOwnerProtocol.h"
#import "BDSKComplexString.h" // for BDSKMacroResolver protocol
#import "BibPrefController.h" // for notification name declarations
#import <OmniFoundation/NSUndoManager-OFExtensions.h> // for isUndoingOrRedoing
#import <OmniFoundation/NSString-OFExtensions.h>
#import "OmniFoundation/NSData-OFExtensions.h"
#import "MacroTextFieldWindowController.h"
#import "NSString_BDSKExtensions.h"
#import "BibTeXParser.h"
#import "BDSKComplexStringFormatter.h"
#import "BDSKGroup.h"
#import "BibItem.h"
#import "BDSKMacroResolver.h"
#import "NSWindowController_BDSKExtensions.h"
#import <OmniAppKit/OATypeAheadSelectionHelper.h>
#import "BDSKTypeSelectHelper.h"
#import "BibDocument.h"

@implementation MacroWindowController

- (id)init {
    self = [self initWithMacroResolver:nil];
    return self;
}

- (id)initWithMacroResolver:(BDSKMacroResolver *)aMacroResolver {
    if (self = [super initWithWindowNibName:@"MacroWindow"]) {
        macroResolver = [aMacroResolver retain];
        
        // a shadow array to keep the macro keys of the document.
        macros = [[NSMutableArray alloc] initWithCapacity:5];
                
		tableCellFormatter = [[BDSKComplexStringFormatter alloc] initWithDelegate:self macroResolver:aMacroResolver];
		macroTextFieldWC = nil;
        
        isEditable = (macroResolver == [BDSKMacroResolver defaultMacroResolver] || [[macroResolver owner] isDocument]);
        
        // register to listen for changes in the macros.
        // mostly used to correctly catch undo changes.
        if (aMacroResolver) {
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(handleMacroChangedNotification:)
                                                         name:BDSKMacroDefinitionChangedNotification
                                                       object:aMacroResolver];
            if (aMacroResolver != [BDSKMacroResolver defaultMacroResolver]) {
                [[NSNotificationCenter defaultCenter] addObserver:self
                                                         selector:@selector(handleMacroChangedNotification:)
                                                             name:BDSKMacroDefinitionChangedNotification
                                                           object:[BDSKMacroResolver defaultMacroResolver]];
            }
            if (isEditable == NO) {
                [[NSNotificationCenter defaultCenter] addObserver:self
                                                         selector:@selector(handleGroupWillBeRemovedNotification:)
                                                             name:BDSKDidAddRemoveGroupNotification
                                                           object:nil];
            }
        }
        
        [self refreshMacros];
    }
    return self;
}

- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [macros release];
    [tableCellFormatter release];
	[macroTextFieldWC release];
	[macroResolver release];
    [super dealloc];
}

- (void)updateButtons{
    [addButton setEnabled:isEditable];
    [removeButton setEnabled:isEditable && [tableView numberOfSelectedRows]];
}

- (void)awakeFromNib{
    NSTableColumn *tc = [tableView tableColumnWithIdentifier:@"macro"];
    [[tc dataCell] setFormatter:[[[MacroKeyFormatter alloc] init] autorelease]];
    if(isEditable)
        [tableView registerForDraggedTypes:[NSArray arrayWithObjects:NSStringPboardType, NSFilenamesPboardType, nil]];
    tc = [tableView tableColumnWithIdentifier:@"definition"];
    [[tc dataCell] setFormatter:tableCellFormatter];
    [tableView reloadData];
    [[tc dataCell] setEditable:isEditable];
    [[[tableView tableColumnWithIdentifier:@"macro"] dataCell] setEditable:isEditable];
    [self updateButtons];
}

- (NSString *)windowTitleForDocumentDisplayName:(NSString *)displayName{
    NSString *title = NSLocalizedString(@"Macros", @"title for macros window");
    if ([[macroResolver owner] isKindOfClass:[BDSKGroup class]])
        title = [NSString stringWithFormat:@"%@ - %@", title, [(BDSKGroup *)[macroResolver owner] stringValue]];
    if ([NSString isEmptyString:displayName] == NO)
        title = [NSString stringWithFormat:@"%@ - %@", title, displayName];
    return title;
}

- (NSString *)representedFilenameForWindow:(NSWindow *)aWindow {
    return [[macroResolver owner] isDocument] ? nil : @"";
}

- (BDSKMacroResolver *)macroResolver{
    return macroResolver;
}

- (void)handleGroupWillBeRemovedNotification:(NSNotification *)notif{
	NSArray *groups = [[notif userInfo] objectForKey:@"groups"];
	
	if ([groups containsObject:[macroResolver owner]])
		[self close];
}

- (void)refreshMacros{
    NSDictionary *macroDefinitions = [(BDSKMacroResolver *)macroResolver macroDefinitions];
    [macros release];
    macros = [[macroDefinitions allKeys] mutableCopy];
    [macros sortUsingSelector:@selector(compare:)];
}

- (void)handleMacroChangedNotification:(NSNotification *)notif{
    NSDictionary *info = [notif userInfo];
    BDSKMacroResolver *sender = [notif object];
    if (sender == macroResolver) {
        NSString *type = [info objectForKey:@"type"];
        if ([type isEqualToString:@"Add macro"]) {
            NSString *key = [info objectForKey:@"macroKey"];
            [macros addObject:key];
        } else if ([type isEqualToString:@"Remove macro"]) {
            NSString *key = [info objectForKey:@"macroKey"];
            if (key)
                [macros removeObject:key];
            else
                [macros removeAllObjects];
        } else if ([type isEqualToString:@"Change key"]) {
            NSString *newKey = [info objectForKey:@"newKey"];
            NSString *oldKey = [info objectForKey:@"oldKey"];
            int indexOfOldKey = [macros indexOfObject:oldKey];
            [macros replaceObjectAtIndex:indexOfOldKey withObject:newKey];
        }
    }
    [tableView reloadData];
}

- (IBAction)addMacro:(id)sender{
    NSDictionary *macroDefinitions = [(BDSKMacroResolver *)macroResolver macroDefinitions];
    // find a unique new macro key
    int i = 0;
    NSString *newKey = [NSString stringWithString:@"newMacro"];
    while([macroDefinitions objectForKey:newKey] != nil){
        newKey = [NSString stringWithFormat:@"macro%d", ++i];
    }
    
    [(BDSKMacroResolver *)macroResolver addMacroDefinition:@"definition"
                                                       forMacro:newKey];
    [[[self window] undoManager] setActionName:NSLocalizedString(@"Add Macro", @"Undo action name")];
	
    [self refreshMacros];
    [tableView reloadData];

    int row = [macros indexOfObject:newKey];
    [tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
    [tableView editColumn:0
                      row:row
                withEvent:nil
                   select:YES];
}

- (IBAction)removeSelectedMacros:(id)sender{
	NSIndexSet *rowIndexes = [tableView selectedRowIndexes];
	int row = [rowIndexes firstIndex];

    // used because we modify the macros array during the loop
    NSArray *shadowOfMacros = [[macros copy] autorelease];
    
    // in case we're editing the selected field we need to end editing.
    // we don't give it a chance to modify state.
    [[self window] endEditingFor:[tableView selectedCell]];

    while(row != NSNotFound){
        NSString *key = [shadowOfMacros objectAtIndex:row];
        [(BDSKMacroResolver *)macroResolver removeMacro:key];
		[[[self window] undoManager] setActionName:NSLocalizedString(@"Delete Macro", @"Undo action name")];
		row = [rowIndexes indexGreaterThanIndex:row];
    }
    [self refreshMacros];
    [tableView reloadData];
}

// we want to have the same undoManager as our document, so we use this 
// NSWindow delegate method to return the doc's undomanager.
- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow *)sender{
    return [macroResolver undoManager];
}

- (void)beginSheetModalForWindow:(NSWindow *)modalWindow{
    [self window]; // make sure we loaded the nib
    [tableView reloadData];
    [closeButton setKeyEquivalent:@"\E"];
    
    [NSApp beginSheet:[self window] modalForWindow:modalWindow modalDelegate:nil didEndSelector:NULL contextInfo:nil];
}

- (void)showWindow:(id)sender{
    [tableView reloadData];
    [closeButton setKeyEquivalent:@""];
    
    [super showWindow:sender];
}

- (void)windowWillClose:(NSNotification *)notification{
	if(![[self window] makeFirstResponder:[self window]])
        [[self window] endEditingFor:nil];
}

- (IBAction)closeAction:(id)sender{
	if ([[self window] isSheet]) {
		[self windowWillClose:nil];
		[[self window] orderOut:sender];
		[NSApp endSheet:[self window] returnCode:[sender tag]];
	} else {
		[[self window] performClose:sender];
	}
}

#pragma mark Macro editing

- (IBAction)editSelectedFieldAsRawBibTeX:(id)sender{
	int row = [tableView selectedRow];
	if (row == -1) 
		return;
    [self editSelectedCellAsMacro];
	if([tableView editedRow] != row)
		[tableView editColumn:1 row:row withEvent:nil select:YES];
}

- (BOOL)editSelectedCellAsMacro{
	int row = [tableView selectedRow];
	if ([macroTextFieldWC isEditing] || row == -1) 
		return NO;
	if(macroTextFieldWC == nil)
        macroTextFieldWC = [[MacroTableViewWindowController alloc] init];
    NSDictionary *macroDefinitions = [(BDSKMacroResolver *)macroResolver macroDefinitions];
    NSString *key = [macros objectAtIndex:row];
	NSString *value = [macroDefinitions objectForKey:key];
	NSText *fieldEditor = [tableView currentEditor];
	[tableCellFormatter setEditAsComplexString:YES];
	if (fieldEditor) {
		[fieldEditor setString:[tableCellFormatter editingStringForObjectValue:value]];
		[[[tableView tableColumnWithIdentifier:@"value"] dataCellForRow:row] setObjectValue:value];
		[fieldEditor selectAll:self];
	}
	return [macroTextFieldWC attachToView:tableView atRow:row column:1 withValue:value];
}

#pragma mark BDSKMacroFormatter delegate

- (BOOL)formatter:(BDSKComplexStringFormatter *)formatter shouldEditAsComplexString:(NSString *)object {
	return [self editSelectedCellAsMacro];
}

#pragma mark NSControl text delegate

- (void)controlTextDidEndEditing:(NSNotification *)aNotification {
	if ([[aNotification object] isEqual:tableView])
		[tableCellFormatter setEditAsComplexString:NO];
}

#pragma mark tableView datasource methods

- (int)numberOfRowsInTableView:(NSTableView *)tv{
    return [macros count];
}

- (id)tableView:(NSTableView *)tv objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row{
    NSDictionary *macroDefinitions = [(BDSKMacroResolver *)macroResolver macroDefinitions];
    NSString *key = [macros objectAtIndex:row];
    
    if([[tableColumn identifier] isEqualToString:@"macro"]){
         return key;
    }else{
         return [macroDefinitions objectForKey:key];
    }
    
}

- (void)tableView:(NSTableView *)tv setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(int)row{
    NSUndoManager *undoMan = [[self window] undoManager];
	if([undoMan isUndoingOrRedoing]) return;
    NSParameterAssert(row >= 0 && row < (int)[macros count]);    
    NSDictionary *macroDefinitions = [(BDSKMacroResolver *)macroResolver macroDefinitions];
    NSString *key = [macros objectAtIndex:row];
    
    if([[tableColumn identifier] isEqualToString:@"macro"]){
        // do nothing if there was no change.
        if([key isEqualToString:object]) return;
                
		if([object isEqualToString:@""]){
			[tableView reloadData];
            [tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
            [tableView editColumn:0 row:row withEvent:nil select:YES];
    		
            NSAlert *alert = [NSAlert alertWithMessageText:NSLocalizedString(@"Empty Macro", @"Message in alert dialog when entering empty macro key") 
                                             defaultButton:NSLocalizedString(@"OK", @"Button title")
                                           alternateButton:nil
                                               otherButton:nil
                                 informativeTextWithFormat:NSLocalizedString(@"The macro can not be empty.", @"Informative text in alert dialog when entering empty macro key")];
            [alert beginSheetModalForWindow:[self window] modalDelegate:nil didEndSelector:NULL contextInfo:NULL];
			return;
		}
                
		if([macroDefinitions objectForKey:object]){
			[tableView reloadData];
            [tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
            [tableView editColumn:0 row:row withEvent:nil select:YES];
    		
            NSAlert *alert = [NSAlert alertWithMessageText:NSLocalizedString(@"Duplicate Macro", @"Message in alert dialog when entering duplicate macro key") 
                                             defaultButton:NSLocalizedString(@"OK", @"Button title")
                                           alternateButton:nil
                                               otherButton:nil
                                 informativeTextWithFormat:NSLocalizedString(@"The macro key must be unique.", @"Informative text in alert dialog when entering duplicate macro key")];
            [alert beginSheetModalForWindow:[self window] modalDelegate:nil didEndSelector:NULL contextInfo:NULL];
			return;
		}
		
        NSDictionary *macroDefinitions = [(BDSKMacroResolver *)macroResolver macroDefinitions];
		if([macroResolver macroDefinition:[macroDefinitions objectForKey:key] dependsOnMacro:object]){
			[tableView reloadData];
            [tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
            [tableView editColumn:0 row:row withEvent:nil select:YES];
    		
            NSAlert *alert = [NSAlert alertWithMessageText:NSLocalizedString(@"Circular Macro", @"Message in alert dialog when entering macro with circular definition") 
                                             defaultButton:NSLocalizedString(@"OK", @"Button title")
                                           alternateButton:nil
                                               otherButton:nil
                                 informativeTextWithFormat:NSLocalizedString(@"The macro you try to define would lead to a circular definition.", @"Informative text in alert dialog")];
            [alert beginSheetModalForWindow:[self window] modalDelegate:nil didEndSelector:NULL contextInfo:NULL];
			return;
		}
		
        [(BDSKMacroResolver *)macroResolver changeMacroKey:key to:object];
		
		[undoMan setActionName:NSLocalizedString(@"Change Macro Key", @"Undo action name")];

    }else{
        // do nothing if there was no change.
        if([[macroDefinitions objectForKey:key] isEqualAsComplexString:object]) return;
		
		if([macroResolver macroDefinition:object dependsOnMacro:key]){
			[tableView reloadData];
            [tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
            [tableView editColumn:0 row:row withEvent:nil select:YES];
    		
            NSAlert *alert = [NSAlert alertWithMessageText:NSLocalizedString(@"Circular Macro", @"Message in alert dialog when entering macro with circular definition") 
                                             defaultButton:NSLocalizedString(@"OK", @"Button title")
                                           alternateButton:nil
                                               otherButton:nil
                                 informativeTextWithFormat:NSLocalizedString(@"The macro you try to define would lead to a circular definition.", @"Informative text in alert dialog")];
            [alert beginSheetModalForWindow:[self window] modalDelegate:nil didEndSelector:NULL contextInfo:NULL];
			return;
		}
        
		[(BDSKMacroResolver *)macroResolver setMacroDefinition:object forMacro:key];
		
		[undoMan setActionName:NSLocalizedString(@"Change Macro Definition", @"Undo action name")];
    }
}

#pragma mark tableview delegate methods

- (void)tableView:(NSTableView *)tv willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn row:(int)row{
	if([[tableColumn identifier] isEqualToString:@"definition"]){
        [tableCellFormatter setHighlighted:[tv isRowSelected:row]];
	}
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification{
    [self updateButtons];
}

#pragma mark || dragging operations

// this is also called from the copy: action defined in NSTableView_OAExtensions
- (BOOL)tableView:(NSTableView *)tv writeRows:(NSArray *)rows toPasteboard:(NSPasteboard *)pboard{
    NSEnumerator *e = [rows objectEnumerator];
    NSNumber *row;
    NSString *key;
    NSString *value;
    NSMutableString *pboardStr = [NSMutableString string];
    NSDictionary *macroDefinitions = [(BDSKMacroResolver *)macroResolver macroDefinitions];
    [pboard declareTypes:[NSArray arrayWithObject:NSStringPboardType] owner:nil];

    while(row = [e nextObject]){
        key = [macros objectAtIndex:[row intValue]];
        value = [[macroDefinitions objectForKey:key] stringAsBibTeXString];
        [pboardStr appendStrings:@"@string{", key, @" = ", value, @"}\n", nil];
    }
    return [pboard setString:pboardStr forType:NSStringPboardType];
    
}

- (NSDragOperation)tableView:(NSTableView*)tv validateDrop:(id <NSDraggingInfo>)info proposedRow:(int)row proposedDropOperation:(NSTableViewDropOperation)op{
    if ([info draggingSource]) {
        if([[info draggingSource] isEqual:tableView])
        {
            // can't copy onto same table
            return NSDragOperationNone;
        }
        [tv setDropRow:-1 dropOperation:NSTableViewDropOn];
        return NSDragOperationCopy;    
    }else{
        //it's not from me
        [tv setDropRow:-1 dropOperation:NSTableViewDropOn];
        return NSDragOperationEvery; // if it's not from me, copying is OK
    }
}

- (BOOL)tableView:(NSTableView *)tv acceptDrop:(id <NSDraggingInfo> )info row:(int)row dropOperation:(NSTableViewDropOperation)op{
    NSPasteboard *pboard = [info draggingPasteboard];
    NSString *type = [pboard availableTypeFromArray:[NSArray arrayWithObjects:NSStringPboardType, NSFilenamesPboardType, nil]];
    
    if([type isEqualToString:NSStringPboardType]) {
        NSString *pboardStr = [pboard stringForType:NSStringPboardType];
        return [self addMacrosFromBibTeXString:pboardStr];
    } else if ([type isEqualToString:NSFilenamesPboardType]) {
        NSArray *fileNames = [pboard propertyListForType:NSFilenamesPboardType];
        NSEnumerator *fileEnum = [fileNames objectEnumerator];
        NSString *file;
        NSFileManager *fm = [NSFileManager defaultManager];
        BOOL ok = NO;
        
        while (file = [fileEnum nextObject]) {
            NSString *extension = [file pathExtension];
            file = [file stringByStandardizingPath];
            if ([fm fileExistsAtPath:file] == NO ||
                ([extension caseInsensitiveCompare:@"bib"] != NSOrderedSame && [extension caseInsensitiveCompare:@"bst"] != NSOrderedSame))
                continue;
            NSString *fileStr = [NSString stringWithContentsOfFile:file];
            if (fileStr != nil)
                ok = ok || [self addMacrosFromBibTeXString:fileStr];
        }
        [NSString stringWithContentsOfFile:file];
        return ok;
    } else
        return NO;
}

// called from tableView paste: action defined in NSTableView_OAExtensions
- (void)tableView:(NSTableView *)tv addItemsFromPasteboard:(NSPasteboard *)pboard{
    if(![[pboard types] containsObject:NSStringPboardType])
        return;
    NSString *pboardStr = [pboard stringForType:NSStringPboardType];
    [self addMacrosFromBibTeXString:pboardStr];
}

// called from tableView delete: action defined in NSTableView_OAExtensions
- (void)tableView:(NSTableView *)tv deleteRows:(NSArray *)rows{
	[self removeSelectedMacros:nil];
}

- (BOOL)addMacrosFromBibTeXString:(NSString *)aString{
    // if this is called, we shouldn't belong to a group
	BibDocument *document = (BibDocument *)[macroResolver owner];
	
    BOOL hadCircular = NO;
    NSMutableDictionary *defs = [NSMutableDictionary dictionary];
    
    if([aString rangeOfString:@"@string" options:NSCaseInsensitiveSearch].location != NSNotFound)
        [defs addEntriesFromDictionary:[BibTeXParser macrosFromBibTeXString:aString document:document]];
            
    if([aString rangeOfString:@"MACRO" options:NSCaseInsensitiveSearch].location != NSNotFound)
        [defs addEntriesFromDictionary:[BibTeXParser macrosFromBibTeXStyle:aString document:document]]; // in case these are style defs

    if ([defs count] == 0)
        return NO;
    
    NSEnumerator *e = [defs keyEnumerator];
    NSString *macroKey;
    NSString *macroString;
    
    while(macroKey = [e nextObject]){
        macroString = [defs objectForKey:macroKey];
		if([macroResolver macroDefinition:macroString dependsOnMacro:macroKey] == NO)
            [(BDSKMacroResolver *)macroResolver setMacroDefinition:macroString forMacro:macroKey];
		else
            hadCircular = YES;
        [[[self window] undoManager] setActionName:NSLocalizedString(@"Change Macro Definition", @"Undo action name")];
    }
    [self refreshMacros];
    [tableView reloadData];
    
    if(hadCircular){
        NSAlert *alert = [NSAlert alertWithMessageText:NSLocalizedString(@"Circular Macros", @"Message in alert dialog when entering macro with circular definition") 
                                         defaultButton:NSLocalizedString(@"OK", @"Button title")
                                       alternateButton:nil
                                           otherButton:nil
                             informativeTextWithFormat:NSLocalizedString(@"Some macros you tried to add would lead to circular definitions and were ignored.", @"Informative text in alert dialog")];
        [alert beginSheetModalForWindow:[self window] modalDelegate:nil didEndSelector:NULL contextInfo:NULL];
    }
    return YES;
}

#pragma mark || Methods to support the type-ahead selector.
- (NSArray *)typeSelectHelperSelectionItems:(BDSKTypeSelectHelper *)typeSelectHelper{
    NSMutableArray *array = [NSMutableArray array];
    NSDictionary *defs = [macroResolver macroDefinitions];
    foreach(macro, macros)
        [array addObject:[defs objectForKey:macro]]; // order of items in the array must match the tableview datasource
    return array;
}
// This is where we build the list of possible items which the user can select by typing the first few letters. You should return an array of NSStrings.

- (unsigned int)typeSelectHelperCurrentlySelectedIndex:(BDSKTypeSelectHelper *)typeSelectHelper{
    if ([tableView numberOfSelectedRows] == 1){
        return [tableView selectedRow];
    }else{
        return NSNotFound;
    }
}
// Type-ahead-selection behavior can change if an item is currently selected (especially if the item was selected by type-ahead-selection). Return nil if you have no selection or a multiple selection.

- (void)typeSelectHelper:(BDSKTypeSelectHelper *)typeSelectHelper selectItemAtIndex:(unsigned int)itemIndex{
    [tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:itemIndex] byExtendingSelection:NO];
}
// We call this when a type-ahead-selection match has been made; you should select the item based on its index in the array you provided in -typeAheadSelectionItems.


@end

@implementation MacroKeyFormatter

- (NSString *)stringForObjectValue:(id)obj{
    return obj;
}

- (NSAttributedString *)attributedStringForObjectValue:(id)obj withDefaultAttributes:(NSDictionary *)attrs{
    // NSLog(@"attributed string for obj");
    return [[[NSAttributedString alloc] initWithString:[self stringForObjectValue:obj]] autorelease];
}

- (BOOL)getObjectValue:(id *)obj forString:(NSString *)string errorDescription:(NSString **)error{
    *obj = string;
    return YES;
}

- (BOOL)isPartialStringValid:(NSString **)partialStringPtr proposedSelectedRange:(NSRangePointer)proposedSelRangePtr originalString:(NSString *)origString originalSelectedRange:(NSRange)origSelRange errorDescription:(NSString **)error{
    static NSCharacterSet *invalidMacroCharSet = nil;
	
	if (!invalidMacroCharSet) {
		NSMutableCharacterSet *tmpSet = [[[NSMutableCharacterSet alloc] init] autorelease];
		[tmpSet addCharactersInRange:NSMakeRange(48,10)]; // 0-9
		[tmpSet addCharactersInRange:NSMakeRange(65,26)]; // A-Z
		[tmpSet addCharactersInRange:NSMakeRange(97,26)]; // a-z
		[tmpSet addCharactersInString:@"!$&*+-./:;<>?[]^_`|"]; // see the btparse documentation
		invalidMacroCharSet = [[[[tmpSet copy] autorelease] invertedSet] retain];
	}
    
	NSString *partialString = *partialStringPtr;
    
    if( [partialString containsCharacterInSet:invalidMacroCharSet] ||
	    ([partialString length] && 
		 [[NSCharacterSet decimalDigitCharacterSet] characterIsMember:[partialString characterAtIndex:0]]) ){
        return NO;
    }
	*partialStringPtr = [partialString lowercaseString];
    return [*partialStringPtr isEqualToString:partialString];
}


@end

@implementation MacroDragTableView

- (NSDragOperation)draggingSourceOperationMaskForLocal:(BOOL)isLocal {
    return NSDragOperationCopy;
}

- (void)awakeFromNib{
    typeSelectHelper = [[BDSKTypeSelectHelper alloc] init];
    [typeSelectHelper setDataSource:[self delegate]];
    [typeSelectHelper setCyclesSimilarResults:YES];
    [typeSelectHelper setMatchesPrefix:NO];
}

- (void)dealloc{
    [typeSelectHelper release];
    [super dealloc];
}

- (void)keyDown:(NSEvent *)event{
    if ([[event characters] length] == 0)
        return;
    unichar c = [[event characters] characterAtIndex:0];
    NSCharacterSet *alnum = [NSCharacterSet alphanumericCharacterSet];
    unsigned int flags = ([event modifierFlags] & NSDeviceIndependentModifierFlagsMask & ~NSAlphaShiftKeyMask);
    if (c == NSDeleteCharacter ||
        c == NSBackspaceCharacter) {
        [[self delegate] removeSelectedMacros:nil];
    }else if(c == NSNewlineCharacter ||
             c == NSEnterCharacter ||
             c == NSCarriageReturnCharacter){
                if([self numberOfSelectedRows] == 1)
                    [self editColumn:0 row:[self selectedRow] withEvent:nil select:YES];
    }else if ([alnum characterIsMember:c] && flags == 0) {
        [typeSelectHelper processKeyDownCharacter:c];
    }else{
        [super keyDown:event];
    }
}

// this gets called whenever an object is added/removed/changed, so it's
// a convenient place to rebuild the typeahead find cache
- (void)reloadData{
    [super reloadData];
    [typeSelectHelper rebuildTypeSelectSearchCache];
}

@end
