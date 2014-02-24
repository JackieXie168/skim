//
//  SKNotesPreferences.m
//  Skim
//
//  Created by Christiaan Hofman on 3/14/10.
/*
 This software is Copyright (c) 2010-2014
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

#define VALUES_KEY_PATH(key) [@"values." stringByAppendingString:key]

@implementation SKNotesPreferences

@synthesize labels1, colorLabels2, colorLabels3, lineLabels2, colorWells1, colorWells2, colorWells3, fontWells, lineWells1, lineWells2;

- (void)dealloc {
    SKDESTROY(labels1);
    SKDESTROY(colorLabels2);
    SKDESTROY(colorLabels3);
    SKDESTROY(lineLabels2);
    SKDESTROY(colorWells1);
    SKDESTROY(colorWells2);
    SKDESTROY(colorWells3);
    SKDESTROY(fontWells);
    SKDESTROY(lineWells1);
    SKDESTROY(lineWells2);
    [super dealloc];
}

- (NSString *)nibName {
    return @"NotesPreferences";
}

- (void)loadView {
    [super loadView];
    
    NSMutableArray *controls = [NSMutableArray array];
    CGFloat dw, dw1, dw2;
    
    [controls addObjectsFromArray:colorWells3];
    dw = SKAutoSizeLabelFields(colorLabels3, controls, NO);
    
    [controls addObjectsFromArray:colorWells2];
    [controls addObjectsFromArray:colorLabels3];
    dw += SKAutoSizeLabelFields(colorLabels2, controls, NO);
    
    [controls addObjectsFromArray:colorWells1];
    [controls addObjectsFromArray:colorLabels2];
    [controls addObjectsFromArray:fontWells];
    [controls addObjectsFromArray:lineWells1];
    dw += dw1 = SKAutoSizeLabelFields(labels1, controls, NO);
    
    dw2 = SKAutoSizeLabelFields(lineLabels2, lineWells2, NO);
    
    SKShiftAndResizeViews(fontWells, 0.0, dw - dw1);
    
    SKShiftAndResizeViews([lineLabels2 arrayByAddingObjectsFromArray:lineWells2], dw - dw2, 0.0);
    
    SKShiftAndResizeView([self view], 0.0, dw);
    
    NSUserDefaultsController *sudc = [NSUserDefaultsController sharedUserDefaultsController];
    
    SKLineWell *lineWell = [lineWells1 objectAtIndex:0];
    [lineWell bind:SKLineWellLineWidthKey toObject:sudc withKeyPath:VALUES_KEY_PATH(SKFreeTextNoteLineWidthKey) options:nil];
    [lineWell bind:SKLineWellStyleKey toObject:sudc withKeyPath:VALUES_KEY_PATH(SKFreeTextNoteLineStyleKey) options:nil];
    [lineWell bind:SKLineWellDashPatternKey toObject:sudc withKeyPath:VALUES_KEY_PATH(SKFreeTextNoteDashPatternKey) options:nil];
    [lineWell setDisplayStyle:SKLineWellDisplayStyleRectangle];
    
    lineWell = [lineWells2 objectAtIndex:0];
    [lineWell bind:SKLineWellLineWidthKey toObject:sudc withKeyPath:VALUES_KEY_PATH(SKCircleNoteLineWidthKey) options:nil];
    [lineWell bind:SKLineWellStyleKey toObject:sudc withKeyPath:VALUES_KEY_PATH(SKCircleNoteLineStyleKey) options:nil];
    [lineWell bind:SKLineWellDashPatternKey toObject:sudc withKeyPath:VALUES_KEY_PATH(SKCircleNoteDashPatternKey) options:nil];
    [lineWell setDisplayStyle:SKLineWellDisplayStyleOval];
    
    lineWell = [lineWells2 objectAtIndex:1];
    [lineWell bind:SKLineWellLineWidthKey toObject:sudc withKeyPath:VALUES_KEY_PATH(SKSquareNoteLineWidthKey) options:nil];
    [lineWell bind:SKLineWellStyleKey toObject:sudc withKeyPath:VALUES_KEY_PATH(SKSquareNoteLineStyleKey) options:nil];
    [lineWell bind:SKLineWellDashPatternKey toObject:sudc withKeyPath:VALUES_KEY_PATH(SKSquareNoteDashPatternKey) options:nil];
    [lineWell setDisplayStyle:SKLineWellDisplayStyleRectangle];
    
    lineWell = [lineWells1 objectAtIndex:1];
    [lineWell bind:SKLineWellLineWidthKey toObject:sudc withKeyPath:VALUES_KEY_PATH(SKLineNoteLineWidthKey) options:nil];
    [lineWell bind:SKLineWellStyleKey toObject:sudc withKeyPath:VALUES_KEY_PATH(SKLineNoteLineStyleKey) options:nil];
    [lineWell bind:SKLineWellDashPatternKey toObject:sudc withKeyPath:VALUES_KEY_PATH(SKLineNoteDashPatternKey) options:nil];
    [lineWell bind:SKLineWellStartLineStyleKey toObject:sudc withKeyPath:VALUES_KEY_PATH(SKLineNoteStartLineStyleKey) options:nil];
    [lineWell bind:SKLineWellEndLineStyleKey toObject:sudc withKeyPath:VALUES_KEY_PATH(SKLineNoteEndLineStyleKey) options:nil];
    
    lineWell = [lineWells1 objectAtIndex:2];
    [lineWell bind:SKLineWellLineWidthKey toObject:sudc withKeyPath:VALUES_KEY_PATH(SKInkNoteLineWidthKey) options:nil];
    [lineWell bind:SKLineWellStyleKey toObject:sudc withKeyPath:VALUES_KEY_PATH(SKInkNoteLineStyleKey) options:nil];
    [lineWell bind:SKLineWellDashPatternKey toObject:sudc withKeyPath:VALUES_KEY_PATH(SKInkNoteDashPatternKey) options:nil];
    [lineWell setDisplayStyle:SKLineWellDisplayStyleSimpleLine];
    
    SKFontWell *fontWell = [fontWells objectAtIndex:0];
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:NSUnarchiveFromDataTransformerName, NSValueTransformerNameBindingOption, nil];
    [fontWell setHasTextColor:YES];
    [fontWell bind:@"textColor" toObject:sudc withKeyPath:VALUES_KEY_PATH(SKFreeTextNoteFontColorKey) options:options];
}

#pragma mark Accessors

- (NSString *)title { return NSLocalizedString(@"Notes", @"Preference pane label"); }

#pragma mark Actions

- (SKFontWell *)activeFontWell {
    for (SKFontWell *fontWell in fontWells)
        if ([fontWell isActive]) return fontWell;
    return nil;
}

- (IBAction)changeFont:(id)sender {
    [[self activeFontWell] changeFontFromFontManager:sender];
}

- (IBAction)changeAttributes:(id)sender {
    [[self activeFontWell] changeAttributesFromFontManager:sender];
}

@end
