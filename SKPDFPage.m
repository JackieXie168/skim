//
//  SKPDFPage.m
//  Skim
//
//  Created by Christiaan Hofman on 9/4/09.
/*
 This software is Copyright (c) 2009-2017
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

#import "SKPDFPage.h"
#import "NSBitmapImageRep_SKExtensions.h"
#import "NSData_SKExtensions.h"
#import "NSGeometry_SKExtensions.h"
#import "PDFPage_SKExtensions.h"
#import "SKPDFView.h"


@interface PDFPage (SKPrivateDeclarations)
- (void)setView:(PDFView *)view;
@end

@implementation SKPDFPage

// On Sierra the PDFView is set on the PDFPage, but we don't want the secondary or snapshot PDFView to steal us away
- (void)setView:(PDFView *)view {
    if ([PDFPage instancesRespondToSelector:_cmd] && (view == nil || [view isKindOfClass:[SKPDFView class]]))
        [super setView:view];
}

- (BOOL)isEditable { return YES; }

// cache the value calculated in the superclass
- (NSRect)foregroundBox {
    if (NSEqualRects(NSZeroRect, foregroundBox))
        foregroundBox = [super foregroundBox];
    return foregroundBox;
}

- (void)setBounds:(NSRect)bounds forBox:(PDFDisplayBox)box {
    if (box == kPDFDisplayBoxCropBox)
        foregroundBox = NSZeroRect;
    [super setBounds:bounds forBox:box];
}

- (void)addAnnotation:(PDFAnnotation *)annotation {
    if (NSContainsRect(foregroundBox, [annotation bounds]) == NO)
        foregroundBox = NSZeroRect;
    [super addAnnotation:annotation];
}

- (void)removeAnnotation:(PDFAnnotation *)annotation {
    if (NSContainsRect(foregroundBox, [annotation bounds]) == NO)
        foregroundBox = NSZeroRect;
    [super removeAnnotation:annotation];
}

- (NSInteger)intrinsicRotation {
    if (intrinsicRotation == 0)
        intrinsicRotation = [super intrinsicRotation] + 360;
    return intrinsicRotation - 360;
}

- (NSAttributedString *)attributedString {
    // on 10.6 the attributedstring is over-released by one
    if ((NSInteger)floor(NSAppKitVersionNumber) == (NSInteger)NSAppKitVersionNumber10_6)
        return [[super attributedString] retain];
    return [super attributedString];
}

@end
