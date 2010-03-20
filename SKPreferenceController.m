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
#import "SKPreferencePane.h"
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

#define SKPreferenceWindowFrameAutosaveName @"SKPreferenceWindow"

#define NIBNAME_KEY @"nibName"

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
    currentPane = nil;
    SKDESTROY(resettableKeys);
    SKDESTROY(toolbarItems);
    [super dealloc];
}

- (void)windowDidLoad {
    [self setupToolbar];
    [[self window] setShowsToolbarButton:NO];
    
    [self setWindowFrameAutosaveName:SKPreferenceWindowFrameAutosaveName];
    
    SKAutoSizeLeftButtons(resetButtons);
    
    SKPreferencePane *pane;
    NSView *view;
    NSSize aSize, size = NSZeroSize;
    for (pane in preferencePanes) {
        aSize = [[pane view] frame].size;
        size.width = fmax(size.width, aSize.width);
        size.height = fmax(size.height, aSize.height);
    }
    for (pane in preferencePanes) {
        view = [pane view];
        aSize = [view frame].size;
        aSize.width = size.width;
        [view setFrameSize:aSize];
        [view setAutoresizingMask:NSViewMinYMargin];
    }
    
    currentPane = [preferencePanes objectAtIndex:0];
    view = [currentPane view];
    [[[self window] toolbar] setSelectedItemIdentifier:[currentPane nibName]];
    [[self window] setTitle:[currentPane title]];
        
    NSRect frame = [[self window] frame];
    frame.size.width = size.width;
    frame.size.height -= NSHeight([contentView frame]) - NSHeight([view frame]);
    [[self window] setFrame:frame display:NO];
    
    [view setFrameOrigin:NSZeroPoint];
    [contentView addSubview:view];
}

- (void)windowDidResignMain:(NSNotification *)notification {
    [[[self window] contentView] deactivateWellSubcontrols];
}

- (void)windowWillClose:(NSNotification *)notification {
    // make sure edits are committed
    if ([[[self window] firstResponder] isKindOfClass:[NSText class]] && [[self window] makeFirstResponder:[self window]] == NO)
        [[self window] endEditingFor:nil];
}

#pragma mark Actions

- (void)resetAllSheetDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
    if (returnCode == NSAlertDefaultReturn) {
        [[NSUserDefaultsController sharedUserDefaultsController] revertToInitialValues:nil];
        [preferencePanes makeObjectsPerformSelector:@selector(defaultsDidRevert)];
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
                     didEndSelector:@selector(resetAllSheetDidEnd:returnCode:contextInfo:)
                        contextInfo:NULL];
}

- (void)resetCurrentSheetDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
    if (returnCode == NSAlertDefaultReturn) {
        [[NSUserDefaultsController sharedUserDefaultsController] revertToInitialValuesForKeys:[resettableKeys objectForKey:[currentPane nibName]]];
        [currentPane defaultsDidRevert];
    }
}

- (IBAction)resetCurrent:(id)sender {
    if (currentPane == nil) {
        NSBeep();
        return;
    }
    NSString *label = [currentPane title];
    NSAlert *alert = [NSAlert alertWithMessageText:[NSString stringWithFormat:NSLocalizedString(@"Reset %@ preferences to their original values?", @"Message in alert dialog when pressing Reset All button"), label]
                                     defaultButton:NSLocalizedString(@"Reset", @"Button title")
                                   alternateButton:NSLocalizedString(@"Cancel", @"Button title")
                                       otherButton:nil
                         informativeTextWithFormat:NSLocalizedString(@"Choosing Reset will restore all settings in this pane to the state they were in when Skim was first installed.", @"Informative text in alert dialog when pressing Reset All button"), label];
    [alert beginSheetModalForWindow:[self window]
                      modalDelegate:self
                     didEndSelector:@selector(resetCurrentSheetDidEnd:returnCode:contextInfo:)
                        contextInfo:NULL];
}

- (IBAction)changeFont:(id)sender {
    [[[[self window] contentView] activeFontWellSubview] changeFontFromFontManager:sender];
}

- (IBAction)changeAttributes:(id)sender {
    [[[[self window] contentView] activeFontWellSubview] changeAttributesFromFontManager:sender];
}

- (IBAction)selectPane:(id)sender {
    SKPreferencePane *pane = [preferencePanes objectAtIndex:[sender tag]];
    if ([pane isEqual:currentPane] == NO) {
        
        [[[self window] toolbar] setSelectedItemIdentifier:[pane nibName]];
        [[self window] setTitle:[pane title]];
        
        NSView *oldView = [currentPane view];
        NSView *view = [pane view];
        
        currentPane = pane;
        
        // make sure edits are committed
        if ([[[self window] firstResponder] isKindOfClass:[NSText class]] && [[self window] makeFirstResponder:[self window]] == NO)
            [[self window] endEditingFor:nil];
        
        NSRect frame = [view frame];
        CGFloat dh = NSHeight([contentView frame]) - NSHeight(frame);
        
        [view setFrameOrigin:NSMakePoint(0.0, dh)];
        [contentView replaceSubview:oldView with:view];
        
        frame = [[self window] frame];
        frame.origin.y += dh;
        frame.size.height -= dh;
        [[self window] setFrame:frame display:YES animate:YES];
    }
}

#pragma mark Toolbar

- (void)setupToolbar {
    // Create a new toolbar instance, and attach it to our document window
    NSToolbar *toolbar = [[[NSToolbar alloc] initWithIdentifier:SKPreferencesToolbarIdentifier] autorelease];
    
    [toolbar setAllowsUserCustomization:NO];
    [toolbar setAutosavesConfiguration:NO];
    [toolbar setVisible:YES];
    [toolbar setDelegate:self];
    
    NSMutableDictionary *tmpDict = [NSMutableDictionary dictionary];
    NSUInteger i = 0;
    
    for (SKPreferencePane *pane in preferencePanes) {
        NSString *identifier = [pane nibName];
        NSToolbarItem *item = [[NSToolbarItem alloc] initWithItemIdentifier:identifier];
        [item setTag:i++];
        [item setLabel:[pane title]];
        [item setImage:[pane icon]];
        [item setTarget:self];
        [item setAction:@selector(selectPane:)];
        [tmpDict setObject:item forKey:identifier];
        [item release];
    }
    
    toolbarItems = [tmpDict copy];
    
    [[self window] setToolbar:toolbar];
}

- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdent willBeInsertedIntoToolbar:(BOOL)willBeInserted {
    return [toolbarItems objectForKey:itemIdent];
}

- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar *)toolbar {
    return [preferencePanes valueForKey:NIBNAME_KEY];
}

- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar *)toolbar {
    return [self toolbarDefaultItemIdentifiers:toolbar];
}

- (NSArray *)toolbarSelectableItemIdentifiers:(NSToolbar *)toolbar {
    return [self toolbarDefaultItemIdentifiers:toolbar];
}

@end
