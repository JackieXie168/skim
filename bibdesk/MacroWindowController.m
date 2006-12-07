//
//  MacroWindowController.m
//  Bibdesk
//
//  Created by Michael McCracken on 2/21/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "MacroWindowController.h"
#import "NSString_BDSKExtensions.h"
#import "OmniFoundation/NSData-OFExtensions.h"
#import "BibTeXParser.h"

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
    
    [tableView reloadData];

    int row = [macros indexOfObject:newKey];
    [tableView selectRow:row byExtendingSelection:NO];
    [tableView editColumn:0
                      row:row
                withEvent:nil
                   select:YES];
}

- (IBAction)removeSelectedMacros:(id)sender{
	NSEnumerator *rowEnum = [tableView selectedRowEnumerator];
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
    }
    
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
    if([[[self window] undoManager] isUndoingOrRedoing]) return;
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
		
        [(id <BDSKMacroResolver>)macroDataSource changeMacroKey:key to:object];

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
    BOOL hadProblems = NO;
    NSArray *defs = [BibTeXParser macrosFromBibTeXString:aString hadProblems:&hadProblems];
    NSEnumerator *e = [defs objectEnumerator];
    NSDictionary *dict = nil;
    NSString *macroKey;
    NSString *macroString;
    
    while(dict = [e nextObject]){
        macroKey = [dict objectForKey:@"mkey"];
        macroString = [dict objectForKey:@"mstring"];
        [(id <BDSKMacroResolver>)macroDataSource setMacroDefinition:macroString forMacro:macroKey];
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
    return YES;
}


@end

@implementation MacroDragTableView

- (NSDragOperation)draggingSourceOperationMaskForLocal:(BOOL)isLocal {
    return NSDragOperationCopy;
}

@end
