//
//  MacroWindowController.m
//  BibDesk
//
//  Created by Michael McCracken on 2/21/05.
/*
 This software is Copyright (c) 2005
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
#import "NSString_BDSKExtensions.h"
#import "OmniFoundation/NSData-OFExtensions.h"
#import "BibTeXParser.h"

#import <OmniAppKit/OATypeAheadSelectionHelper.h>
#import "OATypeAheadSelectionHelper_Extensions.h"

@implementation MacroWindowController
- (id) init {
    if (self = [super initWithWindowNibName:@"MacroWindow"]) {
        macroDataSource = nil;
        
        // a shadow array to keep the macro keys of the document.
        macros = [[NSMutableArray alloc] initWithCapacity:5];
                
    }
    return self;
}

- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [macros release];
    [super dealloc];
}

- (void)awakeFromNib{
    NSTableColumn *tc = [tableView tableColumnWithIdentifier:@"macro"];
    if([[self macroDataSource] respondsToSelector:@selector(displayName)])
        [[self window] setTitle:[NSString stringWithFormat:@"%@: %@", [[self window] title], [[self macroDataSource] displayName]]];
    [[tc dataCell] setFormatter:[[[MacroKeyFormatter alloc] init] autorelease]];
    [tableView registerForDraggedTypes:[NSArray arrayWithObject:NSStringPboardType]];
    [tableView reloadData];
}

- (void)setMacroDataSource:(id)newMacroDataSource{
    if (macroDataSource) {
		[[NSNotificationCenter defaultCenter]
				removeObserver:self
						  name:BDSKBibDocMacroKeyChangedNotification
						object:macroDataSource];
		[[NSNotificationCenter defaultCenter]
				removeObserver:self
						  name:BDSKBibDocMacroDefinitionChangedNotification
						object:macroDataSource];
    }
	
	macroDataSource = newMacroDataSource;
    // register to listen for changes in the macros.
    // mostly used to correctly catch undo changes.
    // there are 4 notifications, but for now our 
    // response is the same for all of them.
    if (macroDataSource) {
		[[NSNotificationCenter defaultCenter]
				addObserver:self
				   selector:@selector(handleMacroKeyChangedNotification:)
					   name:BDSKBibDocMacroKeyChangedNotification
					 object:macroDataSource];
		[[NSNotificationCenter defaultCenter]
				addObserver:self
				   selector:@selector(handleMacroChangedNotification:)
					   name:BDSKBibDocMacroDefinitionChangedNotification
					 object:macroDataSource];
    }
    
    [self refreshMacros];
}

- (id)macroDataSource{
    return macroDataSource;
}

- (void)refreshMacros{
    NSDictionary *macroDefinitions = [(id <BDSKMacroResolver>)macroDataSource macroDefinitions];
    [macros release];
    macros = [[[macroDefinitions allKeys] sortedArrayUsingSelector:@selector(compare:)] mutableCopy];
}

- (void)handleMacroChangedNotification:(NSNotification *)notif{
    NSString *type = [[notif userInfo] objectForKey:@"type"];
    NSString *key = [[notif userInfo] objectForKey:@"macroKey"];
	if ([type isEqualToString:@"Add macro"]) {
		[macros addObject:key];
	} else if ([type isEqualToString:@"Remove macro"]) {
		[macros removeObject:key];
	}
    [tableView reloadData];
}

- (void)handleMacroKeyChangedNotification:(NSNotification *)notif{
    NSDictionary *info = [notif userInfo];
    NSString *newKey = [info objectForKey:@"newKey"];
    NSString *oldKey = [info objectForKey:@"oldKey"];
    int indexOfOldKey = [macros indexOfObject:oldKey];
    [macros replaceObjectAtIndex:indexOfOldKey
                      withObject:newKey];
    [tableView reloadData];
}

- (IBAction)addMacro:(id)sender{
    NSDictionary *macroDefinitions = [(id <BDSKMacroResolver>)macroDataSource macroDefinitions];
    // find a unique new macro key
    int i = 0;
    NSString *newKey = [NSString stringWithString:@"newMacro"];
    while([macroDefinitions objectForKey:newKey] != nil){
        newKey = [NSString stringWithFormat:@"macro%d", ++i];
    }
    
    [(id <BDSKMacroResolver>)macroDataSource addMacroDefinition:@"definition"
                                                       forMacro:newKey];
    [[[self window] undoManager] setActionName:NSLocalizedString(@"Add Macro", @"add macro action name for undo")];
	
    [self refreshMacros];
    [tableView reloadData];

    int row = [macros indexOfObject:newKey];
    [tableView selectRow:row byExtendingSelection:NO];
    [tableView editColumn:0
                      row:row
                withEvent:nil
                   select:YES];
}

- (IBAction)removeSelectedMacros:(id)sender{
	NSEnumerator *rowEnum = [[[tableView selectedRowEnumerator] allObjects] objectEnumerator];
	NSNumber *row;
    NSDictionary *macroDefinitions = [(id <BDSKMacroResolver>)macroDataSource macroDefinitions];

    // used because we modify the macros array during the loop
    NSArray *shadowOfMacros = [[macros copy] autorelease];
    
    // in case we're editing the selected field we need to end editing.
    // we don't give it a chance to modify state.
    [[self window] endEditingFor:[tableView selectedCell]];

    while(row = [rowEnum nextObject]){
        NSString *key = [shadowOfMacros objectAtIndex:[row intValue]];
        [(id <BDSKMacroResolver>)macroDataSource removeMacro:key];
		[[[self window] undoManager] setActionName:NSLocalizedString(@"Delete Macro", @"delete macro action name for undo")];
    }
    [self refreshMacros];
    [tableView reloadData];
}

// we want to have the same undoManager as our document, so we use this 
// NSWindow delegate method to return the doc's undomanager.
- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow *)sender{
	return [(NSWindowController *)macroDataSource undoManager];
}

- (void)showWindow:(id)sender{
    [tableView reloadData];
    [super showWindow:sender];
}

- (void)windowWillClose:(NSNotification *)notification{
	if(![[self window] makeFirstResponder:[self window]])
        [[self window] endEditingFor:nil];
}

#pragma mark tableView datasource methods

- (int)numberOfRowsInTableView:(NSTableView *)tv{
    return [macros count];
}

- (id)tableView:(NSTableView *)tv objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row{
    NSDictionary *macroDefinitions = [(id <BDSKMacroResolver>)macroDataSource macroDefinitions];
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
    NSParameterAssert(row >= 0 && row < [macros count]);    
    NSDictionary *macroDefinitions = [(id <BDSKMacroResolver>)macroDataSource macroDefinitions];
    NSString *key = [macros objectAtIndex:row];
    
    if([[tableColumn identifier] isEqualToString:@"macro"]){
        // do nothing if there was no change.
        if([key isEqualToString:object]) return;
                
		if([object isEqualToString:@""]){
			NSRunAlertPanel(NSLocalizedString(@"Empty Macro", @"Empty Macro"),
							NSLocalizedString(@"The macro can not be empty.", @""),
							NSLocalizedString(@"OK", @"OK"), nil, nil);
			
			[tableView reloadData];
			return;
		}
                
		if([macroDefinitions objectForKey:object]){
			NSRunAlertPanel(NSLocalizedString(@"Duplicate Macro", @"Duplicate Macro"),
							NSLocalizedString(@"The macro key must be unique.", @""),
							NSLocalizedString(@"OK", @"OK"), nil, nil);
			
			[tableView reloadData];
			return;
		}
		
        [(id <BDSKMacroResolver>)macroDataSource changeMacroKey:key to:object];
		
		[undoMan setActionName:NSLocalizedString(@"Change Macro Key", @"change macro key action name for undo")];

    }else{
        // do nothing if there was no change.
        if([[macroDefinitions objectForKey:key] isEqualToString:object]) return;
        
		if(![object isStringTeXQuotingBalancedWithBraces:YES connected:NO]){
			NSRunAlertPanel(NSLocalizedString(@"Invalid Value", @"Invalid Value"),
							NSLocalizedString(@"The value you entered contains unbalanced braces and cannot be saved.", @""),
							NSLocalizedString(@"OK", @"OK"), nil, nil);
			
			[tableView reloadData];
			return;
		}
		
		[(id <BDSKMacroResolver>)macroDataSource setMacroDefinition:object forMacro:key];
		
		[undoMan setActionName:NSLocalizedString(@"Change Macro Definition", @"change macrodef action name for undo")];
    }
}

#pragma mark || dragging operations

- (BOOL)tableView:(NSTableView *)tv writeRows:(NSArray *)rows toPasteboard:(NSPasteboard *)pboard{
    NSEnumerator *e = [rows objectEnumerator];
    NSNumber *row;
    NSString *key;
    NSMutableString *pboardStr = [NSMutableString string];
    NSDictionary *macroDefinitions = [(id <BDSKMacroResolver>)macroDataSource macroDefinitions];
    [pboard declareTypes:[NSArray arrayWithObject:NSStringPboardType] owner:nil];

    while(row = [e nextObject]){
        key = [macros objectAtIndex:[row intValue]];
        [pboardStr appendFormat:@"@STRING{%@ = \"%@\"}\n", key, [macroDefinitions objectForKey:key]];
    }
    return [pboard setString:pboardStr forType:NSStringPboardType];
    
}

- (IBAction)copy:(id)sender{
    NSArray *rows = [[tableView selectedRowEnumerator] allObjects];
    NSPasteboard *pboard = [NSPasteboard generalPasteboard];
    [self tableView:tableView writeRows:rows toPasteboard:pboard];
}

- (IBAction)paste:(id)sender{
    NSPasteboard *pboard = [NSPasteboard generalPasteboard];
    if(![[pboard types] containsObject:NSStringPboardType])
        return;
    
    NSString *pboardStr = [pboard stringForType:NSStringPboardType];
    [self addMacrosFromBibTeXString:pboardStr];
}    

- (BOOL)tableView:(NSTableView *)tv acceptDrop:(id <NSDraggingInfo> )info row:(int)row dropOperation:(NSTableViewDropOperation)op{
    NSPasteboard *pboard = [info draggingPasteboard];

    if(![[pboard types] containsObject:NSStringPboardType])
        return NO;

    NSString *pboardStr = [pboard stringForType:NSStringPboardType];
    return [self addMacrosFromBibTeXString:pboardStr];
}

- (BOOL)addMacrosFromBibTeXString:(NSString *)aString{
    if([macroDataSource isKindOfClass:[NSDocument class]])
		[[BDSKErrorObjectController sharedErrorObjectController] setDocumentForErrors:(NSDocument *)macroDataSource];
	else
		[[BDSKErrorObjectController sharedErrorObjectController] setDocumentForErrors:nil];
	
    BOOL hadProblems = NO;
    NSMutableDictionary *defs = [NSMutableDictionary dictionary];
    
    if([aString rangeOfString:@"@string" options:NSCaseInsensitiveSearch].location != NSNotFound)
        [defs addEntriesFromDictionary:[BibTeXParser macrosFromBibTeXString:aString hadProblems:&hadProblems]];
            
    [defs addEntriesFromDictionary:[BibTeXParser macrosFromBibTeXStyle:aString]]; // in case these are style defs

    NSEnumerator *e = [defs keyEnumerator];
    NSString *macroKey;
    NSString *macroString;
    
    while(macroKey = [e nextObject]){
        macroString = [defs objectForKey:macroKey];
        [(id <BDSKMacroResolver>)macroDataSource setMacroDefinition:macroString forMacro:macroKey];
		[[[self window] undoManager] setActionName:NSLocalizedString(@"Change Macro Definition", @"change macrodef action name for undo")];
    }
    [self refreshMacros];
    [tableView reloadData];
    return !hadProblems;
}

- (NSDragOperation)tableView:(NSTableView*)tv validateDrop:(id <NSDraggingInfo>)info proposedRow:(int)row proposedDropOperation:(NSTableViewDropOperation)op{
    if ([info draggingSource]) {
        if([info draggingSource] == tableView)
        {
            // can't copy onto same table
            return NSDragOperationNone;
        }
        [tv setDropRow:[tv numberOfRows] dropOperation:NSDragOperationCopy];
        return NSDragOperationCopy;    
    }else{
        //it's not from me
        [tv setDropRow:[tv numberOfRows] dropOperation:NSDragOperationCopy];
        return NSDragOperationEvery; // if it's not from me, copying is OK
    }
}

#pragma mark || Methods to support the type-ahead selector.
- (NSArray *)typeAheadSelectionItems{
    NSMutableArray *array = [NSMutableArray array];
    NSDictionary *defs = [macroDataSource macroDefinitions];
    foreach(macro, macros)
        [array addObject:[defs objectForKey:macro]]; // order of items in the array must match the tableview datasource
    return array;
}
// This is where we build the list of possible items which the user can select by typing the first few letters. You should return an array of NSStrings.

- (NSString *)currentlySelectedItem{
    int n = [tableView numberOfSelectedRows];
    if (n == 1){
        return [[tableView dataSource] tableView:tableView objectValueForTableColumn:[[tableView tableColumns] lastObject] row:[tableView selectedRow]];
    }else{
        return nil;
    }
}
// Type-ahead-selection behavior can change if an item is currently selected (especially if the item was selected by type-ahead-selection). Return nil if you have no selection or a multiple selection.

- (void)typeAheadSelectItemAtIndex:(int)itemIndex{
    [tableView selectRow:itemIndex byExtendingSelection:NO];
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
    typeAheadHelper = [[OATypeAheadSelectionHelper alloc] init];
    [typeAheadHelper setDataSource:[self delegate]];
    [typeAheadHelper setCyclesSimilarResults:YES];
}

- (void)dealloc{
    [typeAheadHelper release];
    [super dealloc];
}

- (void)keyDown:(NSEvent *)event{
    unichar c = [[event characters] characterAtIndex:0];
    NSCharacterSet *alnum = [NSCharacterSet alphanumericCharacterSet];
    if (c == NSDeleteCharacter ||
        c == NSBackspaceCharacter) {
        [[self delegate] removeSelectedMacros:nil];
    }else if(c == NSNewlineCharacter ||
             c == NSEnterCharacter ||
             c == NSCarriageReturnCharacter){
                if([self numberOfSelectedRows] == 1)
                    [self editColumn:0 row:[self selectedRow] withEvent:nil select:YES];
    }else if ([alnum characterIsMember:c]) {
        [typeAheadHelper newProcessKeyDownCharacter:c];
    }else{
        [super keyDown:event];
    }
}

// this gets called whenever an object is added/removed/changed, so it's
// a convenient place to rebuild the typeahead find cache
- (void)reloadData{
    [super reloadData];
    [typeAheadHelper rebuildTypeAheadSearchCache];
}

@end
