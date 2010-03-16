//
//  SKNotesPreferences.m
//  Skim
//
//  Created by Christiaan on 3/14/10.
/*
 This software is Copyright (c) 2010
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
#import "NSGeometry_SKExtensions.h"

#define VALUES_KEY_PATH(key) [@"values." stringByAppendingString:key]

@implementation SKNotesPreferences

- (NSString *)nibName {
    return @"NotesPreferences";
}

- (void)loadView {
    [super loadView];
    
    NSArray *labels1 = [NSArray arrayWithObjects:textColorLabelField, anchoredColorLabelField, lineColorLabelField, freehandColorLabelField, 
                                                 textFontLabelField, anchoredFontLabelField, 
                                                 textLineLabelField, lineLineLabelField, freehandLineLabelField, nil];
    NSArray *colorLabels2 = [NSArray arrayWithObjects:circleColorLabelField, circleInteriorColorLabelField, boxColorLabelField, boxInteriorColorLabelField, nil];
    NSArray *colorLabels3 = [NSArray arrayWithObjects:highlightColorLabelField, underlineColorLabelField, strikeOutColorLabelField, nil];
    NSArray *lineLabels2 = [NSArray arrayWithObjects:circleLineLabelField, boxLineLabelField, nil];
    NSArray *colorWells1 = [NSArray arrayWithObjects:textColorWell, anchoredColorWell, lineColorWell, freehandColorWell, nil];
    NSArray *colorWells2 = [NSArray arrayWithObjects:circleColorWell, circleInteriorColorWell, boxColorWell, boxInteriorColorWell, nil];
    NSArray *colorWells3 = [NSArray arrayWithObjects:highlightColorWell, underlineColorWell, strikeOutColorWell, nil];
    NSArray *fontWells1 = [NSArray arrayWithObjects:textNoteFontWell, anchoredNoteFontWell, nil];
    NSArray *lineWells1 = [NSArray arrayWithObjects:textLineWell, lineLineWell, freehandLineWell, nil];
    NSArray *lineWells2 = [NSArray arrayWithObjects:circleLineWell, boxLineWell, nil];
    NSMutableArray *controls = [NSMutableArray array];
    CGFloat dw, dw1, dw2;
    
    [controls addObjectsFromArray:colorWells3];
    dw = SKAutoSizeLabelFields(colorLabels3, controls, NO);
    
    [controls addObjectsFromArray:colorWells2];
    [controls addObjectsFromArray:colorLabels3];
    dw += SKAutoSizeLabelFields(colorLabels2, controls, NO);
    
    [controls addObjectsFromArray:colorWells1];
    [controls addObjectsFromArray:colorLabels2];
    [controls addObjectsFromArray:fontWells1];
    [controls addObjectsFromArray:lineWells1];
    dw += dw1 = SKAutoSizeLabelFields(labels1, controls, NO);
    
    dw2 = SKAutoSizeLabelFields(lineLabels2, lineWells2, NO);
    
    SKShiftAndResizeViews(fontWells1, 0.0, dw - dw1);
    
    SKShiftAndResizeViews([lineLabels2 arrayByAddingObjectsFromArray:lineWells2], dw - dw2, 0.0);
    
    SKShiftAndResizeViews([NSArray arrayWithObjects:[self view], nil], 0.0, dw);
    
    NSUserDefaultsController *sudc = [NSUserDefaultsController sharedUserDefaultsController];
    
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
    
    [freehandLineWell bind:SKLineWellLineWidthKey toObject:sudc withKeyPath:VALUES_KEY_PATH(SKInkNoteLineWidthKey) options:nil];
    [freehandLineWell bind:SKLineWellStyleKey toObject:sudc withKeyPath:VALUES_KEY_PATH(SKInkNoteLineStyleKey) options:nil];
    [freehandLineWell bind:SKLineWellDashPatternKey toObject:sudc withKeyPath:VALUES_KEY_PATH(SKInkNoteDashPatternKey) options:nil];
    [freehandLineWell setDisplayStyle:SKLineWellDisplayStyleSimpleLine];
    
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:NSUnarchiveFromDataTransformerName, NSValueTransformerNameBindingOption, nil];
    [textNoteFontWell setHasTextColor:YES];
    [textNoteFontWell bind:@"textColor" toObject:sudc withKeyPath:VALUES_KEY_PATH(SKFreeTextNoteFontColorKey) options:options];
}

@end
