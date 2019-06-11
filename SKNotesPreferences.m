//
//  SKNotesPreferences.m
//  Skim
//
//  Created by Christiaan Hofman on 3/14/10.
/*
 This software is Copyright (c) 2010-2019
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

#import "SKNotesPreferences.h"
#import "SKPreferenceController.h"
#import "SKStringConstants.h"
#import "SKLineWell.h"
#import "SKFontWell.h"
#import "NSGraphics_SKExtensions.h"
#import "NSImage_SKExtensions.h"
#import "NSShadow_SKExtensions.h"

#define VALUES_KEY_PATH(key) [@"values." stringByAppendingString:key]

@implementation SKNotesPreferences

@synthesize textFontWell, anchoredFontWell, textLineWell, circleLineWell, squareLineWell, lineLineWell, inkLineWell;

- (void)dealloc {
    SKDESTROY(textFontWell);
    SKDESTROY(anchoredFontWell);
    SKDESTROY(textLineWell);
    SKDESTROY(circleLineWell);
    SKDESTROY(squareLineWell);
    SKDESTROY(lineLineWell);
    SKDESTROY(inkLineWell);
    [super dealloc];
}

- (NSString *)nibName {
    return @"NotesPreferences";
}

#define BIND_LINE_WELL(lineWell, noteType, displayStyle) \
[lineWell bind:SKLineWellLineWidthKey toObject:sudc withKeyPath:VALUES_KEY_PATH(SK##noteType##NoteLineWidthKey) options:nil];\
[lineWell bind:SKLineWellStyleKey toObject:sudc withKeyPath:VALUES_KEY_PATH(SK##noteType##NoteLineStyleKey) options:nil];\
[lineWell bind:SKLineWellDashPatternKey toObject:sudc withKeyPath:VALUES_KEY_PATH(SK##noteType##NoteDashPatternKey) options:nil];\
[lineWell setDisplayStyle:displayStyle]

- (void)loadView {
    [super loadView];
    
    NSUserDefaultsController *sudc = [NSUserDefaultsController sharedUserDefaultsController];
    
    BIND_LINE_WELL(textLineWell, FreeText, SKLineWellDisplayStyleRectangle);
    BIND_LINE_WELL(circleLineWell, Circle, SKLineWellDisplayStyleOval);
    BIND_LINE_WELL(squareLineWell, Square, SKLineWellDisplayStyleRectangle);
    BIND_LINE_WELL(lineLineWell, Line, SKLineWellDisplayStyleLine);
    BIND_LINE_WELL(inkLineWell, Ink, SKLineWellDisplayStyleSimpleLine);
    
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:NSUnarchiveFromDataTransformerName, NSValueTransformerNameBindingOption, nil];
    [textFontWell setHasTextColor:YES];
    [textFontWell bind:@"textColor" toObject:sudc withKeyPath:VALUES_KEY_PATH(SKFreeTextNoteFontColorKey) options:options];
}

#pragma mark Accessors

- (NSString *)title { return NSLocalizedString(@"Notes", @"Preference pane label"); }

@end
