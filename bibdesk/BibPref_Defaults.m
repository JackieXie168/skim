// BibPref_Defaults.m
// Created by Michael McCracken, 2002
/*
 This software is Copyright (c) 2002,2003,2004,2005
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

@implementation BibPref_Defaults

- (id)initWithTitle:(NSString *)newTitle defaultsArray:(NSArray *)newDefaultsArray{
	if(self = [super initWithTitle:newTitle defaultsArray:newDefaultsArray]){
		defaultFieldsArray = [[NSMutableArray alloc] initWithCapacity:6];
		
		// initialize the default fields from the prefs
		NSEnumerator *e = [[defaults objectForKey:BDSKDefaultFieldsKey] objectEnumerator];
		NSSet *localFileFields = [NSSet setWithArray:[defaults arrayForKey:BDSKLocalFileFieldsKey]];
		NSSet *remoteURLFields = [NSSet setWithArray:[defaults arrayForKey:BDSKRemoteURLFieldsKey]];
		NSString *field = nil;
		NSMutableDictionary *dict = nil;
		NSNumber *type;
		
		while(field = [e nextObject]){
			if([localFileFields containsObject:field])
				type = [NSNumber numberWithInt:1];
			else if([remoteURLFields containsObject:field])
				type = [NSNumber numberWithInt:2];
			else
				type = [NSNumber numberWithInt:0];
			dict = [NSMutableDictionary dictionaryWithObjectsAndKeys:field, @"field", type, @"type", nil];
			[defaultFieldsArray addObject:dict];
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

- (void)updateUI{
	// first we synchronize the prefs
	NSMutableArray *defaultFields = [[NSMutableArray alloc] initWithCapacity:6];
	NSMutableArray *localFileFields = [[NSMutableArray alloc] initWithObjects:BDSKLocalUrlString, nil];
	NSMutableArray *remoteURLFields = [[NSMutableArray alloc] initWithObjects:BDSKUrlString, nil];
	
	NSEnumerator *e = [defaultFieldsArray objectEnumerator];
	NSDictionary *dict = nil;
	NSString *field;
	int type;
	
	while(dict = [e nextObject]){
		field =[dict objectForKey:@"field"]; 
		type = [[dict objectForKey:@"type"] intValue];
		[defaultFields addObject:field];
		if(type == 1)
			[localFileFields addObject:[dict objectForKey:@"field"]];
		else if(type == 2)
			[remoteURLFields addObject:[dict objectForKey:@"field"]];
	}
	[defaults setObject:defaultFields forKey:BDSKDefaultFieldsKey];
	[defaults setObject:localFileFields forKey:BDSKLocalFileFieldsKey];
	[defaults setObject:remoteURLFields forKey:BDSKRemoteURLFieldsKey];
    [localFileFields release];
    [remoteURLFields release];
    
	[defaultFieldsTableView reloadData];
	
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
    [defaultFieldsArray release];
    [super dealloc];
}


#pragma mark TableView DataSource methods

- (int)numberOfRowsInTableView:(NSTableView *)tableView{
	return [defaultFieldsArray count];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row{
	return [[defaultFieldsArray objectAtIndex:row] objectForKey:[tableColumn identifier]];
}

- (void)tableView:(NSTableView *)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(int)row{
	NSString *colID = [tableColumn identifier];
	
	if([colID isEqualToString:@"field"] && [object isEqualToString:@""])
		[defaultFieldsArray removeObjectAtIndex:row];
	else
		[[defaultFieldsArray objectAtIndex:row] setObject:object forKey:colID];
	[self updateUI];
}

#pragma mark Add and Del fields buttons

- (IBAction)delSelectedDefaultField:(id)sender{
    if([defaultFieldsTableView numberOfSelectedRows] != 0){
		if([defaultFieldsTableView editedRow] != -1)
			[[defaultFieldsTableView window] makeFirstResponder:nil];
        [defaultFieldsArray removeObjectAtIndex:[defaultFieldsTableView selectedRow]];
        [self updateUI];
    }
}

- (IBAction)addDefaultField:(id)sender{
    int row = [defaultFieldsArray count];
	NSMutableDictionary *newDict = [NSMutableDictionary dictionaryWithObjectsAndKeys: @"Field", @"field", [NSNumber numberWithInt:0], @"type", nil]; // do not localize
	[defaultFieldsArray addObject:newDict];
    [defaultFieldsTableView reloadData];
    [defaultFieldsTableView selectRow:row byExtendingSelection:NO];
    [defaultFieldsTableView editColumn:0 row:row withEvent:nil select:YES];
}


- (IBAction)showTypeInfoEditor:(id)sender{
    [[BDSKTypeInfoEditor sharedTypeInfoEditor] showWindow:self];
}

- (IBAction)RSSDescriptionFieldChanged:(id)sender{
    int selTag = [[sender selectedCell] tag];
    switch(selTag){
        case 0:
            // use Rss-
            //BDSKRSSDescriptionFieldKey
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
        [macroWC showWindow:self];
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
