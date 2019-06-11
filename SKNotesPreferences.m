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

- (void)loadView {
    [super loadView];
    
    [[self view] setFrameSize:[[self view] fittingSize]];
    
    NSUserDefaultsController *sudc = [NSUserDefaultsController sharedUserDefaultsController];
    
    [textLineWell bind:SKLineWellLineWidthKey toObject:sudc withKeyPath:VALUES_KEY_PATH(SKFreeTextNoteLineWidthKey) options:nil];
    [textLineWell bind:SKLineWellStyleKey toObject:sudc withKeyPath:VALUES_KEY_PATH(SKFreeTextNoteLineStyleKey) options:nil];
    [textLineWell bind:SKLineWellDashPatternKey toObject:sudc withKeyPath:VALUES_KEY_PATH(SKFreeTextNoteDashPatternKey) options:nil];
    [textLineWell setDisplayStyle:SKLineWellDisplayStyleRectangle];
    
    [circleLineWell bind:SKLineWellLineWidthKey toObject:sudc withKeyPath:VALUES_KEY_PATH(SKCircleNoteLineWidthKey) options:nil];
    [circleLineWell bind:SKLineWellStyleKey toObject:sudc withKeyPath:VALUES_KEY_PATH(SKCircleNoteLineStyleKey) options:nil];
    [circleLineWell bind:SKLineWellDashPatternKey toObject:sudc withKeyPath:VALUES_KEY_PATH(SKCircleNoteDashPatternKey) options:nil];
    [circleLineWell setDisplayStyle:SKLineWellDisplayStyleOval];
    
    [squareLineWell bind:SKLineWellLineWidthKey toObject:sudc withKeyPath:VALUES_KEY_PATH(SKSquareNoteLineWidthKey) options:nil];
    [squareLineWell bind:SKLineWellStyleKey toObject:sudc withKeyPath:VALUES_KEY_PATH(SKSquareNoteLineStyleKey) options:nil];
    [squareLineWell bind:SKLineWellDashPatternKey toObject:sudc withKeyPath:VALUES_KEY_PATH(SKSquareNoteDashPatternKey) options:nil];
    [squareLineWell setDisplayStyle:SKLineWellDisplayStyleRectangle];
    
    [lineLineWell bind:SKLineWellLineWidthKey toObject:sudc withKeyPath:VALUES_KEY_PATH(SKLineNoteLineWidthKey) options:nil];
    [lineLineWell bind:SKLineWellStyleKey toObject:sudc withKeyPath:VALUES_KEY_PATH(SKLineNoteLineStyleKey) options:nil];
    [lineLineWell bind:SKLineWellDashPatternKey toObject:sudc withKeyPath:VALUES_KEY_PATH(SKLineNoteDashPatternKey) options:nil];
    [lineLineWell bind:SKLineWellStartLineStyleKey toObject:sudc withKeyPath:VALUES_KEY_PATH(SKLineNoteStartLineStyleKey) options:nil];
    [lineLineWell bind:SKLineWellEndLineStyleKey toObject:sudc withKeyPath:VALUES_KEY_PATH(SKLineNoteEndLineStyleKey) options:nil];
    
    [inkLineWell bind:SKLineWellLineWidthKey toObject:sudc withKeyPath:VALUES_KEY_PATH(SKInkNoteLineWidthKey) options:nil];
    [inkLineWell bind:SKLineWellStyleKey toObject:sudc withKeyPath:VALUES_KEY_PATH(SKInkNoteLineStyleKey) options:nil];
    [inkLineWell bind:SKLineWellDashPatternKey toObject:sudc withKeyPath:VALUES_KEY_PATH(SKInkNoteDashPatternKey) options:nil];
    [inkLineWell setDisplayStyle:SKLineWellDisplayStyleSimpleLine];
    
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:NSUnarchiveFromDataTransformerName, NSValueTransformerNameBindingOption, nil];
    [textFontWell setHasTextColor:YES];
    [textFontWell bind:@"textColor" toObject:sudc withKeyPath:VALUES_KEY_PATH(SKFreeTextNoteFontColorKey) options:options];
}

#pragma mark Accessors

- (NSString *)title { return NSLocalizedString(@"Notes", @"Preference pane label"); }

@end
