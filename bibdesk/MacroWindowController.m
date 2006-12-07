//
//  MacroWindowController.m
//  Bibdesk
//
//  Created by Michael McCracken on 2/21/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "MacroWindowController.h"


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
    [macros release];
    [super dealloc];
}

- (void)awakeFromNib{
    NSTableColumn *tc = [tableView tableColumnWithIdentifier:@"macro"];
  //  [[tc dataCell] setFormatter:[[[MacroKeyFormatter alloc] init] autorelease]];
    [tableView reloadData];
}

- (void)setMacroDataSource:(id)newMacroDataSource{
    macroDataSource = newMacroDataSource;
    // register to listen for changes in the macros.
    // mostly used to correctly catch undo changes.
    // there are 4 notifications, but for now our 
    // response is the same for all of them.
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
    NSIndexSet *indexes = [NSIndexSet indexSetWithIndex:row];
    [tableView selectRowIndexes:indexes byExtendingSelection:NO];
    [tableView editColumn:0
                      row:row
                withEvent:nil
                   select:YES];
}

- (IBAction)removeSelectedMacros:(id)sender{
    NSIndexSet *indexes = [tableView selectedRowIndexes];
    unsigned int i = [indexes firstIndex];
    NSDictionary *macroDefinitions = [(id <BDSKMacroResolver>)macroDataSource macroDefinitions];
    int numberOfIndexes = [indexes count];

    // used because we modify the macros array during the loop
    NSArray *shadowOfMacros = [[macros copy] autorelease];
    
    // in case we're editing the selected field we need to end editing.
    // we don't give it a chance to modify state.
    [[self window] endEditingFor:[tableView selectedCell]];

    while(i != NSNotFound){
        NSString *key = [shadowOfMacros objectAtIndex:i];
        [(id <BDSKMacroResolver>)macroDataSource removeMacro:key];
        i = [indexes indexGreaterThanIndex:i];
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

- (int)numberOfRowsInTableView:(NSTableView *)tableView{
    return [macros count];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row{
    NSDictionary *macroDefinitions = [(id <BDSKMacroResolver>)macroDataSource macroDefinitions];
    NSString *key = [macros objectAtIndex:row];
    
    if([[tableColumn identifier] isEqualToString:@"macro"]){
         return key;
    }else{
         return [macroDefinitions objectForKey:key];
    }
    
}

- (void)tableView:(NSTableView *)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(int)row{
    if([[[self window] undoManager] isUndoingOrRedoing]) return;
    NSParameterAssert(row >= 0 && row < [macros count]);    
    NSDictionary *macroDefinitions = [(id <BDSKMacroResolver>)macroDataSource macroDefinitions];
    NSString *key = [macros objectAtIndex:row];
    
    if([[tableColumn identifier] isEqualToString:@"macro"]){
        // do nothing if there was no change.
        if([key isEqualToString:object]) return;
                
        [(id <BDSKMacroResolver>)macroDataSource changeMacroKey:key to:object];

    }else{
        // do nothing if there was no change.
        if([[macroDefinitions objectForKey:key] isEqualToString:object]) return;
        
        [(id <BDSKMacroResolver>)macroDataSource setMacroDefinition:object forMacro:key];
    }
}

@end

@implementation MacroKeyFormatter

- (NSString *)stringForObjectValue:(id)obj{
    return obj;
}

- (NSAttributedString *)attributedStringForObjectValue:(id)obj withDefaultAttributes:(NSDictionary *)attrs{
    NSLog(@"attributed string for obj");
    return [[[NSAttributedString alloc] initWithString:[self stringForObjectValue:obj]] autorelease];
}

- (BOOL)getObjectValue:(id *)obj forString:(NSString *)string errorDescription:(NSString **)error{
    *obj = string;
    return YES;
}

- (BOOL)isPartialStringValid:(NSString **)partialStringPtr proposedSelectedRange:(NSRangePointer)proposedSelRangePtr originalString:(NSString *)origString originalSelectedRange:(NSRange)origSelRange errorDescription:(NSString **)error{
    
    NSString *partialString = *partialStringPtr;
    
    if([partialString containsCharacterInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]){
        return NO;
    }else{
        return YES;
    }
    
}


@end