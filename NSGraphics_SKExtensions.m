//
//  NSGraphics_SKExtensions.m
//  Skim
//
//  Created by Christiaan Hofman on 10/20/11.
/*
 This software is Copyright (c) 2011-2020
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

#import "NSGraphics_SKExtensions.h"
#import "NSGeometry_SKExtensions.h"
#import "NSColor_SKExtensions.h"


#if SDK_BEFORE(10_14)

@interface NSAppearance (SKMojaveExtensions)
- (NSString *)bestMatchFromAppearancesWithNames:(NSArray *)names;
@end

@interface NSApplication (SKMojaveExtensions) <NSAppearanceCustomization>
@end

#endif

BOOL SKHasDarkAppearance(id object) {
    if (RUNNING_AFTER(10_13)) {
        id appearance = nil;
        if (object == nil)
            appearance = [NSAppearance currentAppearance];
        else if ([object respondsToSelector:@selector(effectiveAppearance)])
            appearance = [(id<NSAppearanceCustomization>)object effectiveAppearance];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wpartial-availability"
        return [[appearance bestMatchFromAppearancesWithNames:[NSArray arrayWithObjects:@"NSAppearanceNameAqua", @"NSAppearanceNameDarkAqua", nil]] isEqualToString:@"NSAppearanceNameDarkAqua"];
#pragma clang diagnostic pop
    }
    return NO;
}

void SKSetHasDarkAppearance(id object) {
    if (RUNNING_AFTER(10_13) && [object respondsToSelector:@selector(setAppearance:)])
        [(id<NSAppearanceCustomization>)object setAppearance:[NSAppearance appearanceNamed:@"NSAppearanceNameDarkAqua"]];
}

void SKSetHasLightAppearance(id object) {
    if (RUNNING_AFTER(10_13) && [object respondsToSelector:@selector(setAppearance:)])
        [(id<NSAppearanceCustomization>)object setAppearance:[NSAppearance appearanceNamed:@"NSAppearanceNameAqua"]];
}

void SKSetHasDefaultAppearance(id object) {
    if (RUNNING_AFTER(10_13) && [object respondsToSelector:@selector(setAppearance:)])
        [(id<NSAppearanceCustomization>)object setAppearance:nil];
}

void SKRunWithAppearance(id object, void (^code)(void)) {
    NSAppearance *appearance = nil;
    if ([object respondsToSelector:@selector(effectiveAppearance)]) {
        appearance = [[[NSAppearance currentAppearance] retain] autorelease];
        [NSAppearance setCurrentAppearance:[(id<NSAppearanceCustomization>)object effectiveAppearance]];
    }
    code();
    if ([object respondsToSelector:@selector(effectiveAppearance)])
        [NSAppearance setCurrentAppearance:appearance];
}

void SKRunWithLightAppearance(void (^code)(void)) {
    NSAppearance *appearance = [[[NSAppearance currentAppearance] retain] autorelease];
    [NSAppearance setCurrentAppearance:[NSAppearance appearanceNamed:NSAppearanceNameAqua]];
    code();
    [NSAppearance setCurrentAppearance:appearance];
}

#pragma mark -

void SKSetColorsForResizeHandle(CGContextRef context, BOOL active)
{
    NSColor *color = [NSColor selectionHighlightInteriorColor:active];
    CGContextSetFillColorWithColor(context, [color CGColor]);
    color = [NSColor selectionHighlightColor:active];
    CGContextSetStrokeColorWithColor(context, [color CGColor]);
}

void SKFillStrokeResizeHandle(CGContextRef context, NSPoint point, CGFloat radius)
{
    CGRect rect = CGRectMake(point.x - 0.875 * radius, point.y - 0.875 * radius, 1.75 * radius, 1.75 * radius);
    CGContextSetLineWidth(context, 0.25 * radius);
    CGContextFillEllipseInRect(context, rect);
    CGContextStrokeEllipseInRect(context, rect);
}

void SKDrawResizeHandle(CGContextRef context, NSPoint point, CGFloat radius, BOOL active)
{
    SKSetColorsForResizeHandle(context, active);
    SKFillStrokeResizeHandle(context, point, radius);
}

void SKDrawResizeHandles(CGContextRef context, NSRect rect, CGFloat radius, BOOL active)
{
    SKSetColorsForResizeHandle(context, active);
    SKFillStrokeResizeHandle(context, NSMakePoint(NSMinX(rect), NSMidY(rect)), radius);
    SKFillStrokeResizeHandle(context, NSMakePoint(NSMidX(rect), NSMaxY(rect)), radius);
    SKFillStrokeResizeHandle(context, NSMakePoint(NSMidX(rect), NSMinY(rect)), radius);
    SKFillStrokeResizeHandle(context, NSMakePoint(NSMaxX(rect), NSMidY(rect)), radius);
    SKFillStrokeResizeHandle(context, NSMakePoint(NSMinX(rect), NSMaxY(rect)), radius);
    SKFillStrokeResizeHandle(context, NSMakePoint(NSMinX(rect), NSMinY(rect)), radius);
    SKFillStrokeResizeHandle(context, NSMakePoint(NSMaxX(rect), NSMaxY(rect)), radius);
    SKFillStrokeResizeHandle(context, NSMakePoint(NSMaxX(rect), NSMinY(rect)), radius);
}

#pragma mark -

void SKDrawTextFieldBezel(NSRect rect, NSView *controlView) {
    static NSTextFieldCell *cell = nil;
    if (cell == nil) {
        cell = [[NSTextFieldCell alloc] initTextCell:@""];
        [cell setBezeled:YES];
    }
    [cell drawWithFrame:rect inView:controlView];
    [cell setControlView:nil];
}
