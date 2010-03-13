//
//  SKLineInspector.h
//  Skim
//
//  Created by Christiaan Hofman on 6/20/07.
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

#import <Cocoa/Cocoa.h>
#import <Quartz/Quartz.h>
#import "SKWindowController.h"

extern NSString *SKLineInspectorLineAttributeDidChangeNotification;

enum {
    SKNoLineChangeAction,
    SKLineWidthLineChangeAction,
    SKStyleLineChangeAction,
    SKDashPatternLineChangeAction,
    SKStartLineStyleLineChangeAction,
    SKEndLineStyleLineChangeAction
};
typedef NSUInteger SKLineChangeAction;

@class SKLineWell;

@interface SKLineInspector : SKWindowController {
    IBOutlet NSSlider *lineWidthSlider;
    IBOutlet NSTextField *lineWidthField;
    IBOutlet NSSegmentedControl *styleButton;
    IBOutlet NSTextField *dashPatternField;
    IBOutlet NSSegmentedControl *startLineStyleButton;
    IBOutlet NSSegmentedControl *endLineStyleButton;
    IBOutlet SKLineWell *lineWell;
    IBOutlet NSTextField *borderStyleHeaderField;
    IBOutlet NSTextField *lineEndingStyleHeaderField;
    IBOutlet NSTextField *lineWidthLabelField;
    IBOutlet NSTextField *styleLabelField;
    IBOutlet NSTextField *dashPatternLabelField;
    IBOutlet NSTextField *startLineStyleLabelField;
    IBOutlet NSTextField *endLineStyleLabelField;
    CGFloat lineWidth;
    PDFBorderStyle style;
    NSArray *dashPattern;
    PDFLineStyle startLineStyle;
    PDFLineStyle endLineStyle;
    SKLineChangeAction currentLineChangeAction;
}

+ (id)sharedLineInspector;
+ (BOOL)sharedLineInspectorExists;

- (CGFloat)lineWidth;
- (void)setLineWidth:(CGFloat)width;
- (PDFBorderStyle)style;
- (void)setStyle:(PDFBorderStyle)newStyle;
- (NSArray *)dashPattern;
- (void)setDashPattern:(NSArray *)pattern;

- (PDFLineStyle)startLineStyle;
- (void)setStartLineStyle:(PDFLineStyle)newStyle;
- (PDFLineStyle)endLineStyle;
- (void)setEndLineStyle:(PDFLineStyle)newStyle;

- (void)setAnnotationStyle:(PDFAnnotation *)annotation;

- (SKLineChangeAction)currentLineChangeAction;

@end


@interface NSObject (SKLineInspectorDelegate)
- (void)changeLineAttribute:(id)sender;
@end
