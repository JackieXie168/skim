//
//  SKLineInspector.h
//  Skim
//
//  Created by Christiaan Hofman on 6/20/07.
/*
 This software is Copyright (c) 2007-2014
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
    NSSlider *lineWidthSlider;
    NSTextField *lineWidthField;
    NSSegmentedControl *styleButton;
    NSTextField *dashPatternField;
    NSSegmentedControl *startLineStyleButton;
    NSSegmentedControl *endLineStyleButton;
    SKLineWell *lineWell;
    NSTextField *lineWidthLabelField;
    NSTextField *styleLabelField;
    NSTextField *dashPatternLabelField;
    NSTextField *startLineStyleLabelField;
    NSTextField *endLineStyleLabelField;
    NSArray *labelFields;
    CGFloat lineWidth;
    PDFBorderStyle style;
    NSArray *dashPattern;
    PDFLineStyle startLineStyle;
    PDFLineStyle endLineStyle;
    SKLineChangeAction currentLineChangeAction;
}

@property (nonatomic, retain) IBOutlet NSSlider *lineWidthSlider;
@property (nonatomic, retain) IBOutlet NSTextField *lineWidthField, *dashPatternField;
@property (nonatomic, retain) IBOutlet NSSegmentedControl *styleButton, *startLineStyleButton, *endLineStyleButton;
@property (nonatomic, retain) IBOutlet SKLineWell *lineWell;
@property (nonatomic, retain) IBOutlet NSTextField *lineWidthLabelField, *styleLabelField, *dashPatternLabelField, *startLineStyleLabelField, *endLineStyleLabelField;
@property (nonatomic, retain) IBOutlet NSArray *labelFields;
@property (nonatomic) CGFloat lineWidth;
@property (nonatomic) PDFBorderStyle style;
@property (nonatomic, copy) NSArray *dashPattern;
@property (nonatomic) PDFLineStyle startLineStyle, endLineStyle;
@property (nonatomic, readonly) SKLineChangeAction currentLineChangeAction;

+ (id)sharedLineInspector;
+ (BOOL)sharedLineInspectorExists;

- (void)setAnnotationStyle:(PDFAnnotation *)annotation;

@end


@interface NSObject (SKLineInspectorDelegate)
- (void)changeLineAttribute:(id)sender;
@end
