//
//  SKPreferenceController.m
//  Skim
//
//  Created by Christiaan Hofman on 2/10/07.
/*
 This software is Copyright (c) 2007-2010
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

#import "SKPreferenceController.h"
#import "SKViewController.h"
#import "SKGeneralPreferences.h"
#import "SKDisplayPreferences.h"
#import "SKNotesPreferences.h"
#import "SKSyncPreferences.h"
#import "NSUserDefaultsController_SKExtensions.h"
#import "SKFontWell.h"
#import "NSView_SKExtensions.h"
#import "NSGeometry_SKExtensions.h"

#define INITIALUSERDEFAULTS_KEY @"InitialUserDefaults"
#define RESETTABLEKEYS_KEY @"ResettableKeys"

#define SKPreferencesToolbarIdentifier @"SKPreferencesToolbarIdentifier"

#define SKGeneralPreferencesIdentifier @"SKGeneralPreferencesIdentifier"
#define SKDisplayPreferencesIdentifier @"SKDisplayPreferencesIdentifier"
#define SKNotesPreferencesIdentifier   @"SKNotesPreferencesIdentifier"
#define SKSyncPreferencesIdentifier    @"SKSyncPreferencesIdentifier"

#define SKPreferenceWindowFrameAutosaveName @"SKPreferenceWindow"

@implementation SKPreferenceController

+ (id)sharedPrefenceController {
    static SKPreferenceController *sharedPrefenceController = nil;
    if (sharedPrefenceController == nil)
        sharedPrefenceController = [[self alloc] init];
    return sharedPrefenceController;
}

- (id)init {
    if (self = [super initWithWindowNibName:@"PreferenceWindow"]) {
        NSString *initialUserDefaultsPath = [[NSBundle mainBundle] pathForResource:INITIALUSERDEFAULTS_KEY ofType:@"plist"];
        resettableKeys = [[[NSDictionary dictionaryWithContentsOfFile:initialUserDefaultsPath] valueForKey:RESETTABLEKEYS_KEY] retain];
    }
    return self;
}

- (void)dealloc {
    SKDESTROY(resettableKeys);
    SKDESTROY(panes);
    SKDESTROY(toolbarItems);
    SKDESTROY(currentPaneID);
    [super dealloc];
}

- (void)windowDidLoad {
    [self setupToolbar];
    [[self window] setShowsToolbarButton:NO];
    
    [self setWindowFrameAutosaveName:SKPreferenceWindowFrameAutosaveName];
    
    SKAutoSizeLeftButtons(resetButtons);
    
    SKGeneralPreferences *generalPane = [[[SKGeneralPreferences alloc] init] autorelease];
    SKDisplayPreferences *displayPane = [[[SKDisplayPreferences alloc] init] autorelease];
    SKNotesPreferences *notesPane = [[[SKNotesPreferences alloc] init] autorelease];
    SKSyncPreferences *syncPane = [[[SKSyncPreferences alloc] init] autorelease];
    NSArray *allPanes = [NSArray arrayWithObjects:generalPane, displayPane, notesPane, syncPane, nil];
    NSArray *paneIDs = [NSArray arrayWithObjects:SKGeneralPreferencesIdentifier, SKDisplayPreferencesIdentifier, SKNotesPreferencesIdentifier, SKSyncPreferencesIdentifier, nil];
    panes = [[NSDictionary alloc] initWithObjects:allPanes forKeys:paneIDs];
    
    NSSize size = NSZeroSize;
    for (NSViewController *pane in allPanes) {
        NSSize aSize = [[pane view] frame].size;
        size.width = fmax(size.width, aSize.width);
        size.height = fmax(size.height, aSize.height);
    }
    for (NSViewController *pane in allPanes) {
        NSView *view = [pane view];
        NSSize aSize = [view frame].size;
        aSize.width = size.width;
        [view setFrameSize:aSize];
        [view setAutoresizingMask:NSViewMinYMargin];
    }
    NSRect frame = [[self window] frame];
    frame.size.width = size.width;
    [[self window] setFrame:frame display:NO];
    
    [self selectPaneWithIdentifier:SKGeneralPreferencesIdentifier];
}

- (void)windowDidResignMain:(NSNotification *)notification {
    [[[self window] contentView] deactivateWellSubcontrols];
}

- (void)windowWillClose:(NSNotification *)notification {
    // make sure edits are committed
    if ([[[self window] firstResponder] isKindOfClass:[NSText class]] && [[self window] makeFirstResponder:[self window]] == NO)
        [[self window] endEditingFor:nil];
}

- (void)selectPaneWithIdentifier:(NSString *)paneID {
    if ([paneID isEqualToString:currentPaneID] == NO) {
        BOOL hasPane = currentPaneID != nil;
        SKViewController *oldPane = hasPane ? [panes objectForKey:currentPaneID] : nil;
        SKViewController *newPane = [panes objectForKey:paneID];
        
        [[[self window] toolbar] setSelectedItemIdentifier:paneID];
        [[self window] setTitle:[[toolbarItems objectForKey:paneID] label]];
        
        [currentPaneID release];
        currentPaneID = [paneID retain];
        
        // make sure edits are committed
        if (hasPane && [[[self window] firstResponder] isKindOfClass:[NSText class]] && [[self window] makeFirstResponder:[self window]] == NO)
            [[self window] endEditingFor:nil];
        
        NSView *view = [newPane view];
        NSRect frame = [view frame];
        CGFloat dh = NSHeight([contentView frame]) - NSHeight(frame);
        
        [view setFrameOrigin:NSMakePoint(0.0, dh)];
        if (hasPane)
            [contentView replaceSubview:[oldPane view] with:view];
        else
            [contentView addSubview:view];
        
        frame = [[self window] frame];
        frame.origin.y += dh;
        frame.size.height -= dh;
        [[self window] setFrame:frame display:hasPane animate:hasPane];
    }
}

#pragma mark Actions

- (void)resetSheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
    if (returnCode == NSAlertDefaultReturn) {
        NSString *paneID = (NSString *)contextInfo;
        if (paneID)
            [[NSUserDefaultsController sharedUserDefaultsController] revertToInitialValuesForKeys:[resettableKeys objectForKey:paneID]];
        else
            [[NSUserDefaultsController sharedUserDefaultsController] revertToInitialValues:nil];
        if (paneID == nil || [paneID isEqualToString:SKGeneralPreferencesIdentifier])
            [(SKGeneralPreferences *)[panes objectForKey:SKGeneralPreferencesIdentifier] resetSparkleDefaults];
    }
}

- (IBAction)resetAll:(id)sender {
    NSAlert *alert = [NSAlert alertWithMessageText:NSLocalizedString(@"Reset all preferences to their original values?", @"Message in alert dialog when pressing Reset All button") 
                                     defaultButton:NSLocalizedString(@"Reset", @"Button title")
                                   alternateButton:NSLocalizedString(@"Cancel", @"Button title")
                                       otherButton:nil
                         informativeTextWithFormat:NSLocalizedString(@"Choosing Reset will restore all settings to the state they were in when Skim was first installed.", @"Informative text in alert dialog when pressing Reset All button")];
    [alert beginSheetModalForWindow:[self window]
                      modalDelegate:self
                     didEndSelector:@selector(resetSheetDidEnd:returnCode:contextInfo:)
                        contextInfo:NULL];
}

- (IBAction)resetCurrent:(id)sender {
    if (currentPaneID == nil) {
        NSBeep();
        return;
    }
    NSString *label = [[toolbarItems objectForKey:currentPaneID] label];
    NSAlert *alert = [NSAlert alertWithMessageText:[NSString stringWithFormat:NSLocalizedString(@"Reset %@ preferences to their original values?", @"Message in alert dialog when pressing Reset All button"), label]
                                     defaultButton:NSLocalizedString(@"Reset", @"Button title")
                                   alternateButton:NSLocalizedString(@"Cancel", @"Button title")
                                       otherButton:nil
                         informativeTextWithFormat:NSLocalizedString(@"Choosing Reset will restore all settings in this pane to the state they were in when Skim was first installed.", @"Informative text in alert dialog when pressing Reset All button"), label];
    [alert beginSheetModalForWindow:[self window]
                      modalDelegate:self
                     didEndSelector:@selector(resetSheetDidEnd:returnCode:contextInfo:)
                        contextInfo:currentPaneID];
}

- (IBAction)changeFont:(id)sender {
    [[[[self window] contentView] activeFontWellSubview] changeFontFromFontManager:sender];
}

- (IBAction)changeAttributes:(id)sender {
    [[[[self window] contentView] activeFontWellSubview] changeAttributesFromFontManager:sender];
}

- (IBAction)selectPane:(id)sender {
    [self selectPaneWithIdentifier:[sender itemIdentifier]];
}

#pragma mark Toolbar

- (void)setupToolbar {
    // Create a new toolbar instance, and attach it to our document window
    NSToolbar *toolbar = [[[NSToolbar alloc] initWithIdentifier:SKPreferencesToolbarIdentifier] autorelease];
    NSToolbarItem *item;
    
    NSMutableDictionary *tmpDict = [NSMutableDictionary dictionary];
    
    [toolbar setAllowsUserCustomization:NO];
    [toolbar setAutosavesConfiguration:NO];
    [toolbar setVisible:YES];
    [toolbar setDelegate:self];
    
    item = [[NSToolbarItem alloc] initWithItemIdentifier:SKGeneralPreferencesIdentifier];
    [item setLabel:NSLocalizedString(@"General", @"Toolbar item label")];
    [item setImage:[NSImage imageNamed:@"GeneralPreferences"]];
    [item setTarget:self];
    [item setAction:@selector(selectPane:)];
    [tmpDict setObject:item forKey:SKGeneralPreferencesIdentifier];
    [item release];
    
    item = [[NSToolbarItem alloc] initWithItemIdentifier:SKDisplayPreferencesIdentifier];
    [item setLabel:NSLocalizedString(@"Display", @"Toolbar item label")];
    [item setImage:[NSImage imageNamed:@"DisplayPreferences"]];
    [item setTarget:self];
    [item setAction:@selector(selectPane:)];
    [tmpDict setObject:item forKey:SKDisplayPreferencesIdentifier];
    [item release];
    
    item = [[NSToolbarItem alloc] initWithItemIdentifier:SKNotesPreferencesIdentifier];
    [item setLabel:NSLocalizedString(@"Notes", @"Toolbar item label")];
    [item setImage:[NSImage imageNamed:@"NotesPreferences"]];
    [item setTarget:self];
    [item setAction:@selector(selectPane:)];
    [tmpDict setObject:item forKey:SKNotesPreferencesIdentifier];
    [item release];
    
    item = [[NSToolbarItem alloc] initWithItemIdentifier:SKSyncPreferencesIdentifier];
    [item setLabel:NSLocalizedString(@"Sync", @"Toolbar item label")];
    [item setImage:[NSImage imageNamed:@"SyncPreferences"]];
    [item setTarget:self];
    [item setAction:@selector(selectPane:)];
    [tmpDict setObject:item forKey:SKSyncPreferencesIdentifier];
    [item release];
    
    toolbarItems = [tmpDict copy];
    
    [[self window] setToolbar:toolbar];
}

- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdent willBeInsertedIntoToolbar:(BOOL)willBeInserted {
    return [toolbarItems objectForKey:itemIdent];
}

- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar *)toolbar {
    return [NSArray arrayWithObjects:SKGeneralPreferencesIdentifier, SKDisplayPreferencesIdentifier, SKNotesPreferencesIdentifier, SKSyncPreferencesIdentifier, nil];
}

- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar *)toolbar {
    return [self toolbarDefaultItemIdentifiers:toolbar];
}

- (NSArray *)toolbarSelectableItemIdentifiers:(NSToolbar *)toolbar {
    return [self toolbarDefaultItemIdentifiers:toolbar];
}

@end
