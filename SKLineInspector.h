
//
//  SKLineInspector.h
//  Skim
//
//  Created by Christiaan Hofman on 6/20/07.
/*
 This software is Copyright (c) 2007
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

extern NSString *SKLineInspectorLineWidthDidChangeNotification;
extern NSString *SKLineInspectorLineStyleDidChangeNotification;
extern NSString *SKLineInspectorDashPatternDidChangeNotification;
extern NSString *SKLineInspectorStartLineStyleDidChangeNotification;
extern NSString *SKLineInspectorEndLineStyleDidChangeNotification;

@interface SKLineInspector : NSWindowController {
    IBOutlet NSSlider *lineWidthSlider;
    IBOutlet NSTextField *lineWidthField;
    IBOutlet NSSegmentedControl *styleButton;
    IBOutlet NSTextField *dashPatternField;
    IBOutlet NSSegmentedControl *startLineStyleButton;
    IBOutlet NSSegmentedControl *endLineStyleButton;
    PDFBorder *border;
    PDFLineStyle startLineStyle;
    PDFLineStyle endLineStyle;
}

+ (id)sharedLineInspector;

- (float)lineWidth;
- (void)setLineWidth:(float)width;
- (PDFBorderStyle)style;
- (void)setStyle:(PDFBorderStyle)newStyle;
- (NSArray *)dashPattern;
- (void)setDashPattern:(NSArray *)pattern;

- (PDFLineStyle)startLineStyle;
- (void)setStartLineStyle:(PDFLineStyle)newStyle;
- (PDFLineStyle)endLineStyle;
- (void)setEndLineStyle:(PDFLineStyle)newStyle;

- (void)setBorder:(PDFBorder *)newBorder;
- (void)setAnnotationStyle:(PDFAnnotation *)annotation;

@end


@interface NSObject (SKLineInspectorDelegate)

- (void)changeLineWidth:(id)sender;
- (void)changeLineStyle:(id)sender;
- (void)changeDashPattern:(id)sender;
- (void)changeStartLineStyle:(id)sender;
- (void)changeEndLineStyle:(id)sender;

@end


@interface SKNumberArrayFormatter : NSFormatter
    NSNumberFormatter *numberFormatter;
@end
