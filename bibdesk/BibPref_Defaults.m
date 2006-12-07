// BibPref_Defaults.m
// Created by Michael McCracken, 2002
/*
 This software is Copyright (c) 2002,2003,2004,2005,2006
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

#import "BibPref_Defaults.h"
#import "BDSKTypeInfoEditor.h"
#import "BibTeXParser.h"

// this corresponds with the menu item order in the nib
enum {
    BDSKStringType = 0,
    BDSKLocalFileType,
    BDSKRemoteURLType,
    BDSKBooleanType,
    BDSKTriStateType,
    BDSKRatingType
};

@implementation BibPref_Defaults

- (id)initWithTitle:(NSString *)newTitle defaultsArray:(NSArray *)newDefaultsArray controller:(OAPreferenceController *)controller{
	if(self = [super initWithTitle:newTitle defaultsArray:newDefaultsArray controller:controller]){
		customFieldsArray = [[NSMutableArray alloc] initWithCapacity:6];
		customFieldsSet = [[NSMutableSet alloc] initWithCapacity:6];
		
		// initialize the default fields from the prefs
		NSArray *defaultFields = [defaults arrayForKey:BDSKDefaultFieldsKey];
		NSEnumerator *e;
		NSString *field = nil;
		NSMutableDictionary *dict = nil;
		NSNumber *type;
		NSNumber *isDefault;
		
		// Add Local File fields
		e = [[defaults arrayForKey:BDSKLocalFileFieldsKey] objectEnumerator];
		type = [NSNumber numberWithInt:BDSKLocalFileType];
		while(field = [e nextObject]){
			isDefault = [NSNumber numberWithBool:[defaultFields containsObject:field]];
			dict = [NSMutableDictionary dictionaryWithObjectsAndKeys:field, @"field", type, @"type", isDefault, @"default", nil];
			[customFieldsArray addObject:dict];
			[customFieldsSet addObject:field];
		}
		
		// Add Remote URL fields
		e = [[defaults arrayForKey:BDSKRemoteURLFieldsKey] objectEnumerator];
		type = [NSNumber numberWithInt:BDSKRemoteURLType];
		while(field = [e nextObject]){
			isDefault = [NSNumber numberWithBool:[defaultFields containsObject:field]];
			dict = [NSMutableDictionary dictionaryWithObjectsAndKeys:field, @"field", type, @"type", isDefault, @"default", nil];
			[customFieldsArray addObject:dict];
			[customFieldsSet addObject:field];
		}
		
		// Add Boolean fields
		e = [[defaults arrayForKey:BDSKBooleanFieldsKey] objectEnumerator];
		type = [NSNumber numberWithInt:BDSKBooleanType];
		while(field = [e nextObject]){
			isDefault = [NSNumber numberWithBool:[defaultFields containsObject:field]];
			dict = [NSMutableDictionary dictionaryWithObjectsAndKeys:field, @"field", type, @"type", isDefault, @"default", nil];
			[customFieldsArray addObject:dict];
			[customFieldsSet addObject:field];
		}
        
        // Add Tri-State fields
		e = [[defaults arrayForKey:BDSKTriStateFieldsKey] objectEnumerator];
		type = [NSNumber numberWithInt:BDSKTriStateType];
		while(field = [e nextObject]){
			isDefault = [NSNumber numberWithBool:[defaultFields containsObject:field]];
			dict = [NSMutableDictionary dictionaryWithObjectsAndKeys:field, @"field", type, @"type", isDefault, @"default", nil];
			[customFieldsArray addObject:dict];
			[customFieldsSet addObject:field];
		}
        
		// Add Rating fields
		e = [[defaults arrayForKey:BDSKRatingFieldsKey] objectEnumerator];
		type = [NSNumber numberWithInt:BDSKRatingType];
		while(field = [e nextObject]){
			isDefault = [NSNumber numberWithBool:[defaultFields containsObject:field]];
			dict = [NSMutableDictionary dictionaryWithObjectsAndKeys:field, @"field", type, @"type", isDefault, @"default", nil];
			[customFieldsArray addObject:dict];
			[customFieldsSet addObject:field];
		}
		
		// Add any remaining Textual default fields at the beginning
		e = [defaultFields reverseObjectEnumerator];
		type = [NSNumber numberWithInt:BDSKStringType];
		isDefault = [NSNumber numberWithBool:YES];
		while(field = [e nextObject]){
			if([customFieldsSet containsObject:field])
				continue;
			dict = [NSMutableDictionary dictionaryWithObjectsAndKeys:field, @"field", type, @"type", isDefault, @"default", nil];
			[customFieldsArray insertObject:dict atIndex:0];
			[customFieldsSet addObject:field];
		}
	}
	return self;
}

- (void)awakeFromNib{
    [super awakeFromNib];
    BDSKFieldNameFormatter *fieldNameFormatter = [[BDSKFieldNameFormatter alloc] init];
    [RSSDescriptionFieldTextField setFormatter:fieldNameFormatter];
    [[[[defaultFieldsTableView tableColumns] objectAtIndex:0] dataCell] setFormatter:fieldNameFormatter];
    [fieldNameFormatter release];
    
}

- (void)updateButtons{
	int row = [defaultFieldsTableView selectedRow];
	if(row == -1){
		[delSelectedDefaultFieldButton setEnabled:NO];
		return;
	}
	NSString *field = [[customFieldsArray objectAtIndex:row] objectForKey:@"field"];
	if([field isEqualToString:BDSKLocalUrlString] || [field isEqualToString:BDSKUrlString] || [field isEqualToString:BDSKRatingString])
		[delSelectedDefaultFieldButton setEnabled:NO];
	else
		[delSelectedDefaultFieldButton setEnabled:YES];
}

- (void)updatePrefs{
	// we have to make sure that Local-Url and Url are the first in the list
	NSMutableArray *defaultFields = [[NSMutableArray alloc] initWithCapacity:6];
	NSMutableArray *localFileFields = [[NSMutableArray alloc] initWithObjects:BDSKLocalUrlString, nil];
	NSMutableArray *remoteURLFields = [[NSMutableArray alloc] initWithObjects:BDSKUrlString, nil];
    NSMutableArray *ratingFields = [[NSMutableArray alloc] initWithCapacity:1];
    NSMutableArray *booleanFields = [[NSMutableArray alloc] initWithCapacity:1];
    NSMutableArray *triStateFields = [[NSMutableArray alloc] initWithCapacity:1];
	
	NSEnumerator *e = [customFieldsArray objectEnumerator];
	NSDictionary *dict = nil;
	NSString *field;
	int type;
	
	while(dict = [e nextObject]){
		field = [dict objectForKey:@"field"]; 
		type = [[dict objectForKey:@"type"] intValue];
		if([[dict objectForKey:@"default"] boolValue])
			[defaultFields addObject:field];
        switch(type){
            case BDSKStringType:
                break;
            case BDSKLocalFileType:
				if(![field isEqualToString:BDSKLocalUrlString])
					[localFileFields addObject:field];
                break;
            case BDSKRemoteURLType:
				if(![field isEqualToString:BDSKUrlString])
					[remoteURLFields addObject:field];
                break;
            case BDSKBooleanType:
                [booleanFields addObject:field];
                break;
            case BDSKRatingType:
                [ratingFields addObject:field];
                break;
            case BDSKTriStateType:
                [triStateFields addObject:field];
                break;
            default:
                [NSException raise:NSInvalidArgumentException format:@"Attempt to set unrecognized type"];
        }
	}
	[defaults setObject:defaultFields forKey:BDSKDefaultFieldsKey];
	[defaults setObject:localFileFields forKey:BDSKLocalFileFieldsKey];
	[defaults setObject:remoteURLFields forKey:BDSKRemoteURLFieldsKey];
    [defaults setObject:ratingFields forKey:BDSKRatingFieldsKey];
    [defaults setObject:booleanFields forKey:BDSKBooleanFieldsKey];
    [defaults setObject:triStateFields forKey:BDSKTriStateFieldsKey];
    [defaultFields release];
    [localFileFields release];
    [remoteURLFields release];
    [ratingFields release];
    [booleanFields release];
    [triStateFields release];
    
	[defaultFieldsTableView reloadData];
	[self updateButtons];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:BDSKCustomFieldsChangedNotification
														object:self
													  userInfo:[NSDictionary dictionary]];
}

- (void)updateUI{	
	[self updateButtons];
	
    if ([[defaults objectForKey:BDSKRSSDescriptionFieldKey] isEqualToString:BDSKRssDescriptionString]) {
        [RSSDescriptionFieldMatrix selectCellWithTag:0];
        [RSSDescriptionFieldTextField setEnabled:NO];
    }else{
		[RSSDescriptionFieldTextField setStringValue:[defaults objectForKey:BDSKRSSDescriptionFieldKey]];
        [RSSDescriptionFieldMatrix selectCellWithTag:1];
        [RSSDescriptionFieldTextField setEnabled:YES];
    }
}

- (void)dealloc{
    [customFieldsArray release];
    [customFieldsSet release];
    [macroWC release];
	[fieldTypeMenu release];
    [super dealloc];
}


#pragma mark TableView DataSource methods

- (int)numberOfRowsInTableView:(NSTableView *)tableView{
	return [customFieldsArray count];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row{
	return [[customFieldsArray objectAtIndex:row] objectForKey:[tableColumn identifier]];
}

- (void)tableView:(NSTableView *)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(int)row{
	NSString *colID = [tableColumn identifier];
	NSString *field = [[customFieldsArray objectAtIndex:row] objectForKey:@"field"];
	
	if([colID isEqualToString:@"field"]){
		if([customFieldsSet containsObject:object])
			return; // don't add duplicate fields
		[customFieldsSet removeObject:field];
		if([object isEqualToString:@""]){
			[customFieldsArray removeObjectAtIndex:row];
		}else{
			[[customFieldsArray objectAtIndex:row] setObject:object forKey:colID];
			[customFieldsSet addObject:object];
		}
	}else{
		[[customFieldsArray objectAtIndex:row] setObject:object forKey:colID];
	}
	[self updatePrefs];
}

#pragma mark TableView Delegate methods

- (BOOL)tableView:(NSTableView *)tableView shouldEditTableColumn:(NSTableColumn *)tableColumn row:(int)row{
	NSString *colID = [tableColumn identifier];
	NSString *field = [[customFieldsArray objectAtIndex:row] objectForKey:@"field"];
	
	if([field isEqualToString:BDSKLocalUrlString] || [field isEqualToString:BDSKUrlString])
		return NO;
	else if([field isEqualToString:BDSKRatingString] &&
			([colID isEqualToString:@"field"] || [colID isEqualToString:@"type"]))
		return NO;
	return YES;
}

- (void)tableView:(NSTableView *)tableView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn row:(int)row{
	NSString *colID = [tableColumn identifier];
	NSString *field = [[customFieldsArray objectAtIndex:row] objectForKey:@"field"];
	
	if([field isEqualToString:BDSKLocalUrlString] || [field isEqualToString:BDSKUrlString])
		[cell setEnabled:NO];
	else if([field isEqualToString:BDSKRatingString] &&
			([colID isEqualToString:@"field"] || [colID isEqualToString:@"type"]))
		[cell setEnabled:NO];
	else
		[cell setEnabled:YES];
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification{
	int row = [defaultFieldsTableView selectedRow];
	if(row == -1){
		[delSelectedDefaultFieldButton setEnabled:NO];
		return;
	}
	NSString *field = [[customFieldsArray objectAtIndex:row] objectForKey:@"field"];
	if([field isEqualToString:BDSKLocalUrlString] || [field isEqualToString:BDSKUrlString] || [field isEqualToString:BDSKRatingString])
		[delSelectedDefaultFieldButton setEnabled:NO];
	else
		[delSelectedDefaultFieldButton setEnabled:YES];
}

#pragma mark Add and Del fields buttons

- (IBAction)delSelectedDefaultField:(id)sender{
	int row = [defaultFieldsTableView selectedRow];
    if(row != -1){
		if([defaultFieldsTableView editedRow] != -1)
			[[defaultFieldsTableView window] makeFirstResponder:nil];
        [customFieldsSet removeObject:[[customFieldsArray objectAtIndex:row] objectForKey:@"field"]];
        [customFieldsArray removeObjectAtIndex:row];
        [self updatePrefs];
    }
}

- (IBAction)addDefaultField:(id)sender{
    int row = [customFieldsArray count];
	NSMutableDictionary *newDict = [NSMutableDictionary dictionaryWithObjectsAndKeys: @"Field", @"field", [NSNumber numberWithInt:BDSKStringType], @"type", [NSNumber numberWithBool:NO], @"default", nil]; // do not localize
	[customFieldsArray addObject:newDict];
    [defaultFieldsTableView reloadData];
    [defaultFieldsTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
	[[[defaultFieldsTableView tableColumnWithIdentifier:@"field"] dataCell] setEnabled:YES]; // hack to make sure we can edit, as the delegate method is called too late
    [defaultFieldsTableView editColumn:0 row:row withEvent:nil select:YES];
	// don't update the prefs yet, as the user should first set the field name
}


- (IBAction)showTypeInfoEditor:(id)sender{
	[NSApp beginSheet:[[BDSKTypeInfoEditor sharedTypeInfoEditor] window]
       modalForWindow:[[self controlBox] window]
        modalDelegate:nil
       didEndSelector:NULL
          contextInfo:nil];
}

- (IBAction)RSSDescriptionFieldChanged:(id)sender{
    int selTag = [[sender selectedCell] tag];
    switch(selTag){
        case 0:
            // use Rss-Description
            [defaults setObject:BDSKRssDescriptionString
                         forKey:BDSKRSSDescriptionFieldKey];
			break;
        case 1:
            [defaults setObject:[[RSSDescriptionFieldTextField stringValue] capitalizedString]
                         forKey:BDSKRSSDescriptionFieldKey];
            break;
    }
    [self updateUI];
}

- (void)controlTextDidChange:(NSNotification *)aNotification{
	if ([aNotification object] == RSSDescriptionFieldTextField) {
		[defaults setObject:[[RSSDescriptionFieldTextField stringValue] capitalizedString]
					 forKey:BDSKRSSDescriptionFieldKey];
		[self updateUI];
	}
}


#pragma mark BST macro methods

// Stores global macro definitions in the preferences; useful if you keep them in a separate file.
// We handle .bib (@string) and .bst (MACRO) style definitions, via drag-and-drop or paste.

#pragma mark Macro Window Controller support

- (IBAction)showMacrosWindow:(id)sender{
	if (!macroWC){
		macroWC = [[MacroWindowController alloc] init];
		[macroWC setMacroDataSource:self];
	}
	[NSApp beginSheet:[macroWC window]
       modalForWindow:[[self controlBox] window]
        modalDelegate:nil
       didEndSelector:NULL
          contextInfo:nil];
}

- (NSString *)displayName{
    return NSLocalizedString(@"Global Macro Definitions", @"");
}

- (NSUndoManager *)undoManager{
    return [[[OAPreferenceController sharedPreferenceController] window] undoManager];
}

- (NSDictionary *)macroDefinitions{
    Boolean synced = CFPreferencesSynchronize(kCFPreferencesCurrentApplication, kCFPreferencesCurrentUser, kCFPreferencesCurrentHost);
    if(synced == FALSE)
        [NSException raise:NSInternalInconsistencyException format:@"failed to synchronize preferences"];

    CFPropertyListRef dict = CFPreferencesCopyAppValue((CFStringRef)BDSKBibStyleMacroDefinitionsKey, kCFPreferencesCurrentApplication);
    
	if(dict == NULL)
		return [NSDictionary dictionary];
    else
        return [(NSDictionary *)dict autorelease];
}

- (void)setMacroDefinitions:(NSDictionary *)newMacroDefinitions{
    CFPreferencesSetAppValue((CFStringRef)BDSKBibStyleMacroDefinitionsKey, newMacroDefinitions, kCFPreferencesCurrentApplication);
    Boolean synced = CFPreferencesSynchronize(kCFPreferencesCurrentApplication, kCFPreferencesCurrentUser, kCFPreferencesCurrentHost);
    if(synced == FALSE)
        [NSException raise:NSInternalInconsistencyException format:@"failed to synchronize preferences"];
}

- (void)addMacroDefinition:(NSString *)macroString forMacro:(NSString *)macroKey{
    [[[self undoManager] prepareWithInvocationTarget:self]
            removeMacro:macroKey];
    NSMutableDictionary *existingMacros = [[self macroDefinitions] mutableCopy];
    [existingMacros setObject:macroString forKey:macroKey];

    CFPreferencesSetAppValue((CFStringRef)BDSKBibStyleMacroDefinitionsKey, existingMacros, kCFPreferencesCurrentApplication);
    Boolean synced = CFPreferencesSynchronize(kCFPreferencesCurrentApplication, kCFPreferencesCurrentUser, kCFPreferencesCurrentHost);
    if(synced == FALSE)
        [NSException raise:NSInternalInconsistencyException format:@"failed to synchronize preferences"];
    
	[existingMacros release];
	
    NSDictionary *notifInfo = [NSDictionary dictionaryWithObjectsAndKeys:macroKey, @"macroKey", @"Add macro", @"type", nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:BDSKBibDocMacroDefinitionChangedNotification
														object:self
													  userInfo:notifInfo];
}

- (NSString *)valueOfMacro:(NSString *)macro{
    CFPropertyListRef dict = CFPreferencesCopyAppValue((CFStringRef)BDSKBibStyleMacroDefinitionsKey, kCFPreferencesCurrentApplication);
    NSString *val = [(NSDictionary *)dict objectForKey:[macro lowercaseString]];
    if(dict != NULL) CFRelease(dict);
    return val;
}

- (void)removeMacro:(NSString *)macroKey{
    NSMutableDictionary *existingMacros = [[self macroDefinitions] mutableCopy];
    NSString *currentValue = [existingMacros objectForKey:macroKey];
    
    if(!currentValue){
        return;
    }else{
        [[[self undoManager] prepareWithInvocationTarget:self]
        addMacroDefinition:currentValue
                  forMacro:macroKey];
    }
    [existingMacros removeObjectForKey:macroKey];
    
    CFPreferencesSetAppValue((CFStringRef)BDSKBibStyleMacroDefinitionsKey, existingMacros, kCFPreferencesCurrentApplication);
    Boolean synced = CFPreferencesSynchronize(kCFPreferencesCurrentApplication, kCFPreferencesCurrentUser, kCFPreferencesCurrentHost);
    if(synced == FALSE)
        [NSException raise:NSInternalInconsistencyException format:@"failed to synchronize preferences"];
	
	[existingMacros release];
	
    NSDictionary *notifInfo = [NSDictionary dictionaryWithObjectsAndKeys:macroKey, @"macroKey", @"Remove macro", @"type", nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:BDSKBibDocMacroDefinitionChangedNotification
														object:self
													  userInfo:notifInfo];    
}

- (void)changeMacroKey:(NSString *)oldKey to:(NSString *)newKey{
    NSMutableDictionary *existingMacros = [[self macroDefinitions] mutableCopy];
    NSString *oldValue = [existingMacros objectForKey:oldKey];
    if(oldValue == nil)
        [NSException raise:NSInvalidArgumentException format:@"tried to change the value of a nonexistent macro key %@", oldKey];
    [oldValue retain];

    [existingMacros removeObjectForKey:oldKey];
    [existingMacros setObject:oldValue forKey:newKey];
    [oldValue release];

    CFPreferencesSetAppValue((CFStringRef)BDSKBibStyleMacroDefinitionsKey, existingMacros, kCFPreferencesCurrentApplication);
    Boolean synced = CFPreferencesSynchronize(kCFPreferencesCurrentApplication, kCFPreferencesCurrentUser, kCFPreferencesCurrentHost);
    if(synced == FALSE)
        [NSException raise:NSInternalInconsistencyException format:@"failed to synchronize preferences"];
	
	[existingMacros release];
	
    NSDictionary *notifInfo = [NSDictionary dictionaryWithObjectsAndKeys:newKey, @"newKey", oldKey, @"oldKey", nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:BDSKBibDocMacroKeyChangedNotification
														object:self
													  userInfo:notifInfo];
}

- (void)setMacroDefinition:(NSString *)newDefinition forMacro:(NSString *)macroKey{
    if(!newDefinition)
        [NSException raise:NSInvalidArgumentException format:@"attempt to set nil macro definition for key %@", macroKey];

    NSMutableDictionary *existingMacros = [[self macroDefinitions] mutableCopy];
    NSString *currentDef = [existingMacros objectForKey:macroKey];
    [[[self undoManager] prepareWithInvocationTarget:self]
            setMacroDefinition:currentDef forMacro:macroKey];
    [existingMacros setObject:newDefinition forKey:macroKey];
    
    CFPreferencesSetAppValue((CFStringRef)BDSKBibStyleMacroDefinitionsKey, existingMacros, kCFPreferencesCurrentApplication);
    Boolean synced = CFPreferencesSynchronize(kCFPreferencesCurrentApplication, kCFPreferencesCurrentUser, kCFPreferencesCurrentHost);
    if(synced == FALSE)
        [NSException raise:NSInternalInconsistencyException format:@"failed to synchronize preferences"];
	
	[existingMacros release];
	
    NSDictionary *notifInfo = [NSDictionary dictionaryWithObjectsAndKeys:macroKey, @"macroKey", @"Change macro", @"type", nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:BDSKBibDocMacroDefinitionChangedNotification
														object:self
													  userInfo:notifInfo];
}

@end
