//
//  SKSyncPreferences.m
//  Skim
//
//  Created by Christiaan Hofman on 3/14/10.
/*
 This software is Copyright (c) 2010-2013
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

#import "SKSyncPreferences.h"
#import "SKPreferenceController.h"
#import "SKStringConstants.h"
#import "NSGraphics_SKExtensions.h"

static SKTeXEditor SKTeXEditors[] = {{@"TextMate",       @"mate",        @"-l %line \"%file\""}, 
                                     {@"BBEdit",         @"bbedit",      @"+%line \"%file\""}, 
                                     {@"TextWrangler",   @"edit",        @"+%line \"%file\""}, 
                                     {@"Emacs",          @"emacsclient", @"--no-wait +%line \"%file\""}, 
                                     {@"Aquamacs Emacs", @"emacsclient", @"--no-wait +%line \"%file\""}, 
                                     {@"Aquamacs",       @"emacsclient", @"--no-wait +%line \"%file\""}, 
                                     {@"LyX",            @"lyxeditor",   @"\"%file\" %line"}, 
                                     {@"TeXMaker",       @"texmaker",    @"\"%file\" -line %line"}, 
                                     {@"AlphaX",         @"alphac",      @"+%line \"%file\""}, 
                                     {@"MacVim",         @"mvim",        @"--remote-silent +\":%line\" \"%file\""}, 
                                     {@"Sublime Text 2", @"subl",        @"\"%file\":%line"}};
#define SKTeXEditorCount (sizeof(SKTeXEditors) / sizeof(SKTeXEditor))
#define SKNullTeXEditor ((SKTeXEditor){nil, nil, nil})

@implementation SKSyncPreferences

@synthesize texEditorLabels, texEditorControls, customTeXEditor;

- (void)dealloc {
    SKDESTROY(texEditorLabels);
    SKDESTROY(texEditorControls);
    [super dealloc];
}

- (NSString *)nibName {
    return @"SyncPreferences";
}

- (void)loadView {
    [super loadView];
    
    SKAutoSizeLabelFields(texEditorLabels, texEditorControls, YES);
    
    NSString *editorPreset = [[NSUserDefaults standardUserDefaults] stringForKey:SKTeXEditorPresetKey];
    NSInteger i = SKTeXEditorCount;
    NSInteger idx = -1;
    NSPopUpButton *texEditorPopUpButton = [texEditorControls objectAtIndex:0];
    
    while (i--) {
        NSString *name = SKTeXEditors[i].name;
        [texEditorPopUpButton insertItemWithTitle:name atIndex:0];
        if ([name isEqualToString:editorPreset])
            idx = i;
    }
    
    [self setCustomTeXEditor:idx == -1];
    
    if (idx == -1)
        [texEditorPopUpButton selectItem:[texEditorPopUpButton lastItem]];
    else
        [texEditorPopUpButton selectItemAtIndex:idx];
}

#pragma mark Accessors

- (NSString *)title { return NSLocalizedString(@"Sync", @"Preference pane label"); }

+ (SKTeXEditor)TeXEditorForPreset:(NSString *)name {
    NSInteger i = SKTeXEditorCount;
    while (i--) {
        SKTeXEditor editor = SKTeXEditors[i];
        if ([editor.name isEqualToString:name])
            return editor;
    }
    return SKNullTeXEditor;
}

#pragma mark Actions

- (IBAction)changeTeXEditorPreset:(id)sender {
    NSUserDefaultsController *sudc = [NSUserDefaultsController sharedUserDefaultsController];
    NSInteger idx = [sender indexOfSelectedItem];
    if (idx < [sender numberOfItems] - 1) {
        [[sudc values] setValue:[sender titleOfSelectedItem] forKey:SKTeXEditorPresetKey];
        [[sudc values] setValue:SKTeXEditors[idx].command forKey:SKTeXEditorCommandKey];
        [[sudc values] setValue:SKTeXEditors[idx].arguments forKey:SKTeXEditorArgumentsKey];
        [self setCustomTeXEditor:NO];
    } else {
        [[sudc values] setValue:@"" forKey:SKTeXEditorPresetKey];
        [self setCustomTeXEditor:YES];
    }
}

#pragma mark Hooks

- (void)defaultsDidRevert {
    NSString *editorPreset = [[NSUserDefaults standardUserDefaults] stringForKey:SKTeXEditorPresetKey];
    NSPopUpButton *texEditorPopUpButton = [texEditorControls objectAtIndex:0];
    if ([editorPreset length] == 0) {
        [texEditorPopUpButton selectItem:[texEditorPopUpButton lastItem]];
        [self setCustomTeXEditor:YES];
    } else {
        [texEditorPopUpButton selectItemWithTitle:editorPreset];
        [self setCustomTeXEditor:NO];
    }
}

@end
