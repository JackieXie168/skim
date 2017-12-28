//
//  SKExportAccessoryController.m
//  Skim
//
//  Created by Christiaan on 9/27/12.
/*
 This software is Copyright (c) 2012-2017
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

#import "SKExportAccessoryController.h"
#import "NSGraphics_SKExtensions.h"

#define MARGIN_X 16.0
#define MARGIN_Y 16.0
#define POPUP_MATRIX_OFFSET 3.0

@implementation SKExportAccessoryController

@synthesize matrix, labelField;

- (void)dealloc {
    SKDESTROY(matrix);
    SKDESTROY(labelField);
    [super dealloc];
}

- (NSString *)nibName {
    return @"ExportAccessoryView";
}

- (void)loadView {
    [super loadView];
    [matrix sizeToFit];
    SKAutoSizeLabelField(labelField, matrix, NO);
}

- (void)addFormatPopUpButton:(NSPopUpButton *)popupButton {
    // find the largest item and size popup to fit
    CGFloat width = 0.0, maxWidth = 0.0;
    NSSize size = NSMakeSize(1000.0, 1000.0);
    NSDictionary *attrs = [NSDictionary dictionaryWithObjectsAndKeys:[popupButton font], NSFontAttributeName, nil];
    NSUInteger i, iNum = [popupButton numberOfItems], iMax = 0;
    for (i = 0; i < iNum; i++) {
        width = NSWidth([[popupButton itemTitleAtIndex:i] boundingRectWithSize:size options:0 attributes:attrs]);
        if (width > maxWidth) {
            maxWidth = width;
            iMax = i;
        }
    }
    i = [popupButton indexOfSelectedItem];
    [popupButton selectItemAtIndex:iMax];
    [popupButton sizeToFit];
    [popupButton selectItemAtIndex:i];

    NSView *view = [self view];
    NSRect frame = [view frame];
    NSRect matrixFrame = [matrix frame];
    NSRect popupFrame = [popupButton frame];
    
    popupFrame.origin.x = NSMinX(matrixFrame) - POPUP_MATRIX_OFFSET;
    popupFrame.origin.y = NSMaxY(matrixFrame) + MARGIN_Y;
    popupFrame.size.width = fmax(NSWidth(popupFrame), NSWidth(matrixFrame) + 2.0 * POPUP_MATRIX_OFFSET);
    frame.size.width = fmax(NSMaxX(popupFrame) + MARGIN_X - POPUP_MATRIX_OFFSET, NSMaxX(matrixFrame) + MARGIN_X);
    
    if (RUNNING_AFTER(10_7))
        [popupButton setValue:[NSNumber numberWithBool:NO] forKeyPath:@"constraints.active"];
    [popupButton setAutoresizingMask:NSViewWidthSizable | NSViewMinYMargin];
    [popupButton setFrame:popupFrame];
    [view setFrame:frame];
    [view addSubview:popupButton];
}

@end
