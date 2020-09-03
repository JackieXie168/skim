//
//  NSView_SKExtensions.h
//  Skim
//
//  Created by Christiaan Hofman on 9/17/07.
/*
 This software is Copyright (c) 2007-2020
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

@class SKFontWell;

typedef NS_ENUM(NSInteger, SKVisualEffectMaterial) {
    SKVisualEffectMaterialAppearanceBased = 0,
    SKVisualEffectMaterialLight = 1,
    SKVisualEffectMaterialDark = 2,
    SKVisualEffectMaterialTitlebar = 3,
    SKVisualEffectMaterialSelection = 4,
    SKVisualEffectMaterialMediumLight = 8,
    SKVisualEffectMaterialUltraDark = 9,
    // 10.11
    SKVisualEffectMaterialMenu = 5,
    SKVisualEffectMaterialPopover = 6,
    SKVisualEffectMaterialSidebar = 7,
    // 10.14
    SKVisualEffectMaterialHeaderView = 10,
    SKVisualEffectMaterialSheet = 11,
    SKVisualEffectMaterialWindowBackground = 12,
    SKVisualEffectMaterialHUDWindow = 13,
    SKVisualEffectMaterialFullScreenUI = 15,
    SKVisualEffectMaterialToolTip = 17,
    SKVisualEffectMaterialContentBackground = 18,
    SKVisualEffectMaterialUnderWindowBackground = 21,
    SKVisualEffectMaterialUnderPageBackground = 22
};

@interface NSView (SKExtensions)

- (id)subviewOfClass:(Class)aClass;

- (void)deactivateWellSubcontrols;
- (void)deactivateColorWellSubcontrols;

- (SKFontWell *)activeFontWell;

- (CGFloat)backingScale;

- (NSRect)convertRectToScreen:(NSRect)rect;
- (NSRect)convertRectFromScreen:(NSRect)rect;
- (NSPoint)convertPointToScreen:(NSPoint)point;
- (NSPoint)convertPointFromScreen:(NSPoint)point;

- (NSBitmapImageRep *)bitmapImageRepCachingDisplayInRect:(NSRect)rect;

+ (NSView *)visualEffectViewWithMaterial:(SKVisualEffectMaterial)material active:(BOOL)active blendInWindow:(BOOL)blendInWindow;
- (void)applyMaskImageWithDrawingHandler:(void (^)(NSRect dstRect))drawingHandler;
- (void)applyVisualEffectMaterial:(SKVisualEffectMaterial)material;

@end
