//
//  SKLineWell.h
//  Skim
//
//  Created by Christiaan Hofman on 6/22/07.
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

extern NSString *SKPasteboardTypeLineStyle;
// these keys are used in the userInfo dictionary of this pboard type
extern NSString *SKLineWellLineWidthKey;
extern NSString *SKLineWellStyleKey;
extern NSString *SKLineWellDashPatternKey;
extern NSString *SKLineWellStartLineStyleKey;
extern NSString *SKLineWellEndLineStyleKey;

enum {
    SKLineWellDisplayStyleLine,
    SKLineWellDisplayStyleSimpleLine,
    SKLineWellDisplayStyleRectangle,
    SKLineWellDisplayStyleOval
};
typedef NSInteger SKLineWellDisplayStyle;

@interface SKLineWell : NSControl {
    CGFloat lineWidth;
    PDFBorderStyle style;
    NSArray *dashPattern;
    PDFLineStyle startLineStyle;
    PDFLineStyle endLineStyle;
    
    struct _lwFlags {
        unsigned int displayStyle:2;
        unsigned int active:1;
        unsigned int canActivate:1;
        unsigned int highlighted:1;
        unsigned int existsActiveLineWell:1;
    } lwFlags;
    
    id target;
    SEL action;
}

@property (nonatomic) SEL action;
@property (nonatomic, assign) id target;
@property (nonatomic, readonly) BOOL isActive;
@property (nonatomic) BOOL canActivate;
@property (nonatomic, getter=isHighlighted) BOOL highlighted;
@property (nonatomic) SKLineWellDisplayStyle displayStyle;
@property (nonatomic) CGFloat lineWidth;
@property (nonatomic) PDFBorderStyle style;
@property (nonatomic, copy) NSArray *dashPattern;
@property (nonatomic) PDFLineStyle startLineStyle, endLineStyle;

- (void)activate:(BOOL)exclusive;
- (void)deactivate;

- (void)lineInspectorLineAttributeChanged:(NSNotification *)notification;

@end
