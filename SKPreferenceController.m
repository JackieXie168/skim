//
//  SKPreferenceController.m
//  Skim
//
//  Created by Christiaan Hofman on 2/10/07.
/*
 This software is Copyright (c) 2007-2008
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
#import "SKStringConstants.h"
#import "NSUserDefaultsController_SKExtensions.h"
#import "SKApplicationController.h"
#import "SKLineWell.h"
#import "SKFontWell.h"
#import "NSView_SKExtensions.h"
#import <Sparkle/Sparkle.h>

static NSString *SKPreferenceInitialUserDefaultsFileName = @"InitialUserDefaults";
static NSString *SKPreferenceResettableKeysKey = @"ResettableKeys";

static float SKDefaultFontSizes[] = {8.0, 9.0, 10.0, 11.0, 12.0, 13.0, 14.0, 16.0, 18.0, 20.0, 24.0, 28.0, 32.0, 48.0, 64.0};
static NSString *SKTeXEditors[] = {@"TextMate", @"BBEdit", @"TextWrangler", @"Emacs", @"Aquamacs Emacs", @"LyX", @"AquaX"};
static NSString *SKTeXEditorCommands[] = {@"mate", @"bbedit", @"edit", @"emacsclient", @"emacsclient", @"lyxeditor", @"aquac"};
static NSString *SKTeXEditorArguments[] = {@"-l %line \"%file\"", @"+%line \"%file\"", @"+%line \"%file\"", @"--no-wait +%line \"%file\"", @"--no-wait +%line \"%file\"", @"\"%file\" %line", @"+%line \"%file\""};

static NSString *SKPreferenceWindowFrameAutosaveName = @"SKPreferenceWindow";

static void *SKPreferenceWindowDefaultsObservationContext = (void *)@"SKPreferenceWindowDefaultsObservationContext";

@implementation SKPreferenceController

static SKPreferenceController *sharedPrefenceController = nil;

+ (id)sharedPrefenceController {
    return sharedPrefenceController ? sharedPrefenceController : [[self alloc] init];
}

+ (id)allocWithZone:(NSZone *)zone {
    return sharedPrefenceController ? sharedPrefenceController : [super allocWithZone:zone];
}

- (id)init {
    if (sharedPrefenceController == nil && (sharedPrefenceController = self = [super init])) {
        NSString *initialUserDefaultsPath = [[NSBundle mainBundle] pathForResource:SKPreferenceInitialUserDefaultsFileName ofType:@"plist"];
        resettableKeys = [[[NSDictionary dictionaryWithContentsOfFile:initialUserDefaultsPath] valueForKey:SKPreferenceResettableKeysKey] retain];
        
        sud = [NSUserDefaults standardUserDefaults];
        sudc = [NSUserDefaultsController sharedUserDefaultsController];
        [sudc addObserver:self forKeys:[NSArray arrayWithObjects:SKDefaultPDFDisplaySettingsKey, SKDefaultFullScreenPDFDisplaySettingsKey, nil] context:SKPreferenceWindowDefaultsObservationContext];
    }
    return sharedPrefenceController;
}

- (void)dealloc {
    [sudc removeObserver:self forKeys:[NSArray arrayWithObjects:SKDefaultPDFDisplaySettingsKey, SKDefaultFullScreenPDFDisplaySettingsKey, nil]];
    [resettableKeys release];
    [super dealloc];
}

- (id)retain { return self; }

- (id)autorelease { return self; }

- (void)release {}

- (unsigned)retainCount { return UINT_MAX; }

- (NSString *)windowNibName {
    return @"PreferenceWindow";
}

- (void)updateRevertButtons {
    NSDictionary *initialValues = [sudc initialValues];
    [revertPDFSettingsButton setEnabled:[[initialValues objectForKey:SKDefaultPDFDisplaySettingsKey] isEqual:[sud dictionaryForKey:SKDefaultPDFDisplaySettingsKey]] == NO];
    [revertFullScreenPDFSettingsButton setEnabled:[[initialValues objectForKey:SKDefaultFullScreenPDFDisplaySettingsKey] isEqual:[sud dictionaryForKey:SKDefaultFullScreenPDFDisplaySettingsKey]] == NO];
}

#define VALUES_KEY_PATH(key) [@"values." stringByAppendingString:key]

- (void)windowDidLoad {
    [self setWindowFrameAutosaveName:SKPreferenceWindowFrameAutosaveName];
    
    NSString *editorPreset = [sud stringForKey:SKTeXEditorPresetKey];
    int i = sizeof(SKTeXEditors) / sizeof(NSString *);
    int idx = -1;
    
    while (i--) {
        [texEditorPopUpButton insertItemWithTitle:SKTeXEditors[i] atIndex:0];
        if ([SKTeXEditors[i] isEqualToString:editorPreset])
            idx = i;
    }
    
    [self setCustomTeXEditor:idx == -1];
    
    if (isCustomTeXEditor)
        [texEditorPopUpButton selectItem:[texEditorPopUpButton lastItem]];
    else
        [texEditorPopUpButton selectItemAtIndex:idx];
    
    [self updateRevertButtons];
    
    [textLineWell bind:SKLineWellLineWidthKey toObject:sudc withKeyPath:VALUES_KEY_PATH(SKFreeTextNoteLineWidthKey) options:nil];
    [textLineWell bind:SKLineWellStyleKey toObject:sudc withKeyPath:VALUES_KEY_PATH(SKFreeTextNoteLineStyleKey) options:nil];
    [textLineWell bind:SKLineWellDashPatternKey toObject:sudc withKeyPath:VALUES_KEY_PATH(SKFreeTextNoteDashPatternKey) options:nil];
    [textLineWell setDisplayStyle:SKLineWellDisplayStyleRectangle];
    
    [circleLineWell bind:SKLineWellLineWidthKey toObject:sudc withKeyPath:VALUES_KEY_PATH(SKCircleNoteLineWidthKey) options:nil];
    [circleLineWell bind:SKLineWellStyleKey toObject:sudc withKeyPath:VALUES_KEY_PATH(SKCircleNoteLineStyleKey) options:nil];
    [circleLineWell bind:SKLineWellDashPatternKey toObject:sudc withKeyPath:VALUES_KEY_PATH(SKCircleNoteDashPatternKey) options:nil];
    [circleLineWell setDisplayStyle:SKLineWellDisplayStyleOval];
    
    [boxLineWell bind:SKLineWellLineWidthKey toObject:sudc withKeyPath:VALUES_KEY_PATH(SKSquareNoteLineWidthKey) options:nil];
    [boxLineWell bind:SKLineWellStyleKey toObject:sudc withKeyPath:VALUES_KEY_PATH(SKSquareNoteLineStyleKey) options:nil];
    [boxLineWell bind:SKLineWellDashPatternKey toObject:sudc withKeyPath:VALUES_KEY_PATH(SKSquareNoteDashPatternKey) options:nil];
    [boxLineWell setDisplayStyle:SKLineWellDisplayStyleRectangle];
    
    [lineLineWell bind:SKLineWellLineWidthKey toObject:sudc withKeyPath:VALUES_KEY_PATH(SKLineNoteLineWidthKey) options:nil];
    [lineLineWell bind:SKLineWellStyleKey toObject:sudc withKeyPath:VALUES_KEY_PATH(SKLineNoteLineStyleKey) options:nil];
    [lineLineWell bind:SKLineWellDashPatternKey toObject:sudc withKeyPath:VALUES_KEY_PATH(SKLineNoteDashPatternKey) options:nil];
    [lineLineWell bind:SKLineWellStartLineStyleKey toObject:sudc withKeyPath:VALUES_KEY_PATH(SKLineNoteStartLineStyleKey) options:nil];
    [lineLineWell bind:SKLineWellEndLineStyleKey toObject:sudc withKeyPath:VALUES_KEY_PATH(SKLineNoteEndLineStyleKey) options:nil];
}

- (void)windowDidResignMain:(NSNotification *)notification {
    [[[self window] contentView] deactivateWellSubcontrols];
}

- (void)windowWillClose:(NSNotification *)notification {
    // make sure edits are committed
    if ([[[self window] firstResponder] isKindOfClass:[NSText class]] && [[self window] makeFirstResponder:[self window]] == NO)
        [[self window] endEditingFor:nil];
}

- (void)tabView:(NSTabView *)tabView willSelectTabViewItem:(NSTabViewItem *)tabViewItem {
    // make sure edits are committed
    if ([[[self window] firstResponder] isKindOfClass:[NSText class]] && [[self window] makeFirstResponder:[self window]] == NO)
        [[self window] endEditingFor:nil];
}

- (unsigned)countOfSizes {
    return sizeof(SKDefaultFontSizes) / sizeof(float);
}

- (id)objectInSizesAtIndex:(unsigned)anIndex {
    return [NSNumber numberWithFloat:SKDefaultFontSizes[anIndex]];
}

- (BOOL)isCustomTeXEditor {
    return isCustomTeXEditor;
}

- (void)setCustomTeXEditor:(BOOL)flag {
    isCustomTeXEditor = flag;
}

- (IBAction)changeDiscreteThumbnailSizes:(id)sender {
    if ([sender state] == NSOnState) {
        [thumbnailSizeSlider setNumberOfTickMarks:8];
        [snapshotSizeSlider setNumberOfTickMarks:8];
        [thumbnailSizeSlider setAllowsTickMarkValuesOnly:YES];
        [snapshotSizeSlider setAllowsTickMarkValuesOnly:YES];
    } else {
        [[thumbnailSizeSlider superview] setNeedsDisplayInRect:[thumbnailSizeSlider frame]];
        [[snapshotSizeSlider superview] setNeedsDisplayInRect:[snapshotSizeSlider frame]];
        [thumbnailSizeSlider setNumberOfTickMarks:0];
        [snapshotSizeSlider setNumberOfTickMarks:0];
        [thumbnailSizeSlider setAllowsTickMarkValuesOnly:NO];
        [snapshotSizeSlider setAllowsTickMarkValuesOnly:NO];
    }
    [thumbnailSizeSlider sizeToFit];
    [snapshotSizeSlider sizeToFit];
}

- (IBAction)changeUpdateInterval:(id)sender {
    int checkInterval = [[sender selectedItem] tag];
    if (checkInterval)
       [[SUUpdater sharedUpdater] scheduleCheckWithInterval:checkInterval];
}

- (IBAction)changeTeXEditorPreset:(id)sender {
    int idx = [sender indexOfSelectedItem];
    if (idx < [sender numberOfItems] - 1) {
        [[sudc values] setValue:[sender titleOfSelectedItem] forKey:SKTeXEditorPresetKey];
        [[sudc values] setValue:SKTeXEditorCommands[idx] forKey:SKTeXEditorCommandKey];
        [[sudc values] setValue:SKTeXEditorArguments[idx] forKey:SKTeXEditorArgumentsKey];
        [self setCustomTeXEditor:NO];
    } else {
        [[sudc values] setValue:@"" forKey:SKTeXEditorPresetKey];
        [self setCustomTeXEditor:YES];
    }
}

- (IBAction)revertPDFViewSettings:(id)sender {
    [sudc revertToInitialValueForKey:SKDefaultPDFDisplaySettingsKey];
}

- (IBAction)revertFullScreenPDFViewSettings:(id)sender {
    [sudc revertToInitialValueForKey:SKDefaultFullScreenPDFDisplaySettingsKey];
}

- (void)resetSheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo {
    if (returnCode == NSAlertDefaultReturn) {
        NSString *tabID = (NSString *)contextInfo;
        NSArray *keys = tabID ? [resettableKeys objectForKey:tabID] : nil;
        if (tabID)
            [sudc revertToInitialValuesForKeys:keys];
        else
            [sudc revertToInitialValues:nil];
        if (tabID == nil || [keys containsObject:SUScheduledCheckIntervalKey]) {
            int checkInterval = [sud integerForKey:SUScheduledCheckIntervalKey];
            if (checkInterval)
               [[SUUpdater sharedUpdater] scheduleCheckWithInterval:checkInterval];
        }
    }
}

- (IBAction)changeFont:(id)sender {
    [[[[self window] contentView] activeFontWellSubview] changeFontFromFontManager];
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
    NSString *label = [[tabView selectedTabViewItem] label];
    NSAlert *alert = [NSAlert alertWithMessageText:[NSString stringWithFormat:NSLocalizedString(@"Reset %@ preferences to their original values?", @"Message in alert dialog when pressing Reset All button"), label]
                                     defaultButton:NSLocalizedString(@"Reset", @"Button title")
                                   alternateButton:NSLocalizedString(@"Cancel", @"Button title")
                                       otherButton:nil
                         informativeTextWithFormat:NSLocalizedString(@"Choosing Reset will restore all settings in this pane to the state they were in when Skim was first installed.", @"Informative text in alert dialog when pressing Reset All button"), label];
    [alert beginSheetModalForWindow:[self window]
                      modalDelegate:self
                     didEndSelector:@selector(resetSheetDidEnd:returnCode:contextInfo:)
                        contextInfo:[[tabView selectedTabViewItem] identifier]];
}

#pragma mark KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (context == SKPreferenceWindowDefaultsObservationContext) {
        NSString *key = [keyPath substringFromIndex:7];
        if ([key isEqualToString:SKDefaultPDFDisplaySettingsKey] || [key isEqualToString:SKDefaultFullScreenPDFDisplaySettingsKey]) {
            [self updateRevertButtons];
        }
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

@end
