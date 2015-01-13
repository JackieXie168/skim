//
//  SKNotesPreferences.m
//  Skim
//
//  Created by Christiaan Hofman on 3/14/10.
/*
 This software is Copyright (c) 2010-2015
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

- (SKFontWell *)activeFontWell {
    for (SKFontWell *fontWell in fontWells)
        if ([fontWell isActive]) return fontWell;
    return nil;
}

#pragma mark Accessors

- (NSString *)title { return NSLocalizedString(@"Notes", @"Preference pane label"); }

- (NSImage *)icon {
    static NSImage *image = nil;
    if (image == nil) {
        image = [[NSImage bitmapImageWithSize:NSMakeSize(32.0, 32.0) drawingHandler:^(NSRect rect, CGFloat bScale){
            CGFloat lineWidth = 1.0 / bScale;
            NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:NSMakeRect(5.0, 3.0, 21.0, 27.0) xRadius:3.0 yRadius:3.0];
            [NSGraphicsContext saveGraphicsState];
            [NSShadow setShadowWithColor:[NSColor colorWithCalibratedWhite:0.0 alpha:0.7] blurRadius:2.0 * bScale yOffset:-bScale];
            [[NSColor colorWithCalibratedRed:1.0 green:0.935 blue:0.422 alpha:1.0] set];
            [path fill];
            [NSGraphicsContext restoreGraphicsState];
            [NSGraphicsContext saveGraphicsState];
            [path addClip];
            NSGradient *gradient = [[[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedRed:1.0 green:0.935 blue:0.422 alpha:1.0] endingColor:[NSColor colorWithCalibratedRed:1.0 green:0.975 blue:0.768 alpha:1.0]] autorelease];
            [gradient drawInBezierPath:path angle:90.0];
            path = [NSBezierPath bezierPathWithRect:NSMakeRect(5.0, 6.0, 21.0, lineWidth)];
            [path appendBezierPathWithRect:NSMakeRect(5.0, 10.0, 21.0, lineWidth)];
            [path appendBezierPathWithRect:NSMakeRect(5.0, 14.0, 21.0, lineWidth)];
            [path appendBezierPathWithRect:NSMakeRect(5.0, 18.0, 21.0, lineWidth)];
            [path appendBezierPathWithRect:NSMakeRect(5.0, 22.0, 21.0, lineWidth)];
            [[NSColor colorWithCalibratedRed:0.15 green:0.5 blue:0.9 alpha:0.1] set];
            [path fill];
            path = [NSBezierPath bezierPathWithRect:NSMakeRect(7.0, 3.0, lineWidth, 23.0)];
            [path appendBezierPathWithRect:NSMakeRect(9.0, 3.0, lineWidth, 23.0)];
            [[NSColor colorWithCalibratedRed:0.685 green:0.335 blue:0.185 alpha:0.3] set];
            [path fill];
            [NSGraphicsContext saveGraphicsState];
            path = [NSBezierPath bezierPathWithRoundedRect:NSMakeRect(5.0, 3.0, 21.0, 27.0) xRadius:3.0 yRadius:3.0];
            [[NSColor colorWithCalibratedWhite:0.0 alpha:0.5] set];
            CGContextSetBlendMode([[NSGraphicsContext currentContext] graphicsPort], kCGBlendModeSoftLight);
            [path setLineWidth:2.0 * lineWidth];
            [path stroke];
            [NSGraphicsContext restoreGraphicsState];
            path = [NSBezierPath bezierPath];
            [path moveToPoint:NSMakePoint(5.0, 26.0)];
            [path appendBezierPathWithArcFromPoint:NSMakePoint(5.0, 30.0) toPoint:NSMakePoint(26.0, 30.0) radius:3.0];
            [path appendBezierPathWithArcFromPoint:NSMakePoint(26.0, 30.0) toPoint:NSMakePoint(26.0, 26.0) radius:3.0];
            [path lineToPoint:NSMakePoint(26.0, 26.0)];
            [path closePath];
            [[NSColor colorWithCalibratedWhite:0.5 alpha:1.0] set];
            [NSShadow setShadowWithColor:[NSColor colorWithCalibratedWhite:0.0 alpha:0.3] blurRadius:0.0 yOffset:-1.0];
            [path fill];
            [NSGraphicsContext restoreGraphicsState];
            [NSGraphicsContext saveGraphicsState];
            [path addClip];
            gradient = [[[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedWhite:0.3 alpha:1.0] endingColor:[NSColor colorWithCalibratedWhite:0.5 alpha:1.0]] autorelease];
            [gradient drawInRect:NSMakeRect(5.0, 26.0, 21.0, 4.0) angle:90.0];
            [path appendBezierPathWithRect:rect];
            [path setWindingRule:NSEvenOddWindingRule];
            [[NSColor colorWithCalibratedWhite:0.0 alpha:0.8] set];
            [NSShadow setShadowWithColor:[NSColor colorWithCalibratedWhite:0.0 alpha:1.0] blurRadius:2.0 * bScale yOffset:0.0 * bScale];
            [path fill];
            [NSGraphicsContext restoreGraphicsState];
        }] retain];
    }
    return image;
}

@end
