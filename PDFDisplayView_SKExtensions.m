//
//  PDFDisplayView_SKExtensions.m
//  Skim
//
//  Created by Christiaan Hofman on 4/22/08.
/*
 This software is Copyright (c) 2008-2014
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

#import "PDFDisplayView_SKExtensions.h"
#import <Quartz/Quartz.h>
#import "SKPDFView.h"
#import "PDFAnnotation_SKExtensions.h"
#import "NSAttributedString_SKExtensions.h"
#import "SKMainDocument.h"
#import "SKRuntime.h"
#import "SKAccessibilityFauxUIElement.h"

#define SKDisableExtendedPDFViewAccessibilityKey @"SKDisableExtendedPDFViewAccessibility"

@interface NSView (SKPDFDisplayViewPrivateDeclarations)
- (NSRange)accessibilityRangeForSelection:(id)selection;
- (id)selectionForAccessibilityRange:(NSRange)range;
@end

@interface NSView (SKPDFDisplayViewAdditionalAccessibility)
- (id)accessibilityRangeForPositionAttributeForParameter:(id)parameter;
- (id)accessibilityRTFForRangeAttributeForParameter:(id)parameter;
- (id)accessibilityAttributedStringForRangeAttributeForParameter:(id)parameter;
- (id)accessibilityStyleRangeForIndexAttributeForParameter:(id)parameter;
@end

#pragma mark -

static id SKGetPDFView(id self) {
    id pdfView = nil;
    @try { pdfView = [self valueForKey:@"pdfView"]; }
    @catch (id exception) {}
    return pdfView;
}

static void (*original_updateTrackingAreas)(id, SEL) = NULL;

static id (*original_accessibilityAttributeNames)(id, SEL) = NULL;
static id (*original_accessibilityParameterizedAttributeNames)(id, SEL) = NULL;
static id (*original_accessibilityAttributeValue)(id, SEL, id) = NULL;
static id (*original_accessibilityHitTest)(id, SEL, NSPoint) = NULL;
static id (*original_accessibilityFocusedUIElement)(id, SEL) = NULL;

#pragma mark Skim support

static void replacement_updateTrackingAreas(id self, SEL _cmd) {
	original_updateTrackingAreas(self, _cmd);
    id pdfView = SKGetPDFView(self);
    if ([pdfView respondsToSelector:@selector(resetPDFToolTipRects)])
        [pdfView resetPDFToolTipRects];
}

#pragma mark Accessibility

static NSArray *replacement_accessibilityAttributeNames(id self, SEL _cmd) {
    if ([SKGetPDFView(self) respondsToSelector:@selector(accessibilityChildren)]) {
        static NSArray *attributes = nil;
        if (attributes == nil)
            attributes = [[original_accessibilityAttributeNames(self, _cmd) arrayByAddingObject:NSAccessibilityChildrenAttribute] retain];
        return attributes;
    } else {
        return original_accessibilityAttributeNames(self, _cmd);
    }
}

static NSArray *replacement_accessibilityParameterizedAttributeNames(id self, SEL _cmd) {
    static NSArray *attributes = nil;
    if (attributes == nil)
        attributes = [[original_accessibilityParameterizedAttributeNames(self, _cmd) arrayByAddingObjectsFromArray:[NSArray arrayWithObjects:NSAccessibilityRangeForPositionParameterizedAttribute, NSAccessibilityRTFForRangeParameterizedAttribute, NSAccessibilityAttributedStringForRangeParameterizedAttribute, nil]] retain];
    return attributes;
}

static id replacement_accessibilityAttributeValue(id self, SEL _cmd, NSString *attribute) {
    if ([attribute isEqualToString:NSAccessibilityRoleAttribute]) {
        return NSAccessibilityTextAreaRole;
    } else if ([attribute isEqualToString:NSAccessibilityChildrenAttribute]) {
        id pdfView = SKGetPDFView(self);
        return [pdfView respondsToSelector:@selector(accessibilityChildren)] ? NSAccessibilityUnignoredChildren([pdfView accessibilityChildren]) : original_accessibilityAttributeValue(self, _cmd, attribute);
    } else {
        return original_accessibilityAttributeValue(self, _cmd, attribute);
    }
}

static NSAttributedString *attributedStringForAccessibilityRange(id pdfDisplayView, NSRange range, CGFloat scale) {
    NSAttributedString *attributedString = nil;
    if ([pdfDisplayView respondsToSelector:@selector(selectionForAccessibilityRange:)]) {
        // make sure the accessibility table is generated
        [pdfDisplayView accessibilityAttributeValue:NSAccessibilityVisibleCharacterRangeAttribute];
        PDFSelection *selection = [pdfDisplayView selectionForAccessibilityRange:range];
        if ([selection respondsToSelector:@selector(attributedString)]) {
            attributedString = [selection attributedString];
            if (fabs(scale - 1.0) > 0.0) {
                NSMutableAttributedString *mutableAttrString = [[attributedString mutableCopy] autorelease];
                NSUInteger i = 0, l = [mutableAttrString length];
                NSRange r;
                while (i < l) {
                    NSFont *font = [mutableAttrString attribute:NSFontAttributeName atIndex:i effectiveRange:&r];
                    if (font) {
                        font = [[NSFontManager sharedFontManager] convertFont:font toSize:round(scale * [font pointSize])];
                        [mutableAttrString addAttribute:NSFontAttributeName value:font range:r];
                    }
                    i = NSMaxRange(r);
                }
                [mutableAttrString fixFontAttributeInRange:NSMakeRange(0, l)];
                attributedString = mutableAttrString;
            }
        }
    }
    return attributedString;
}

static id replacement_accessibilityRangeForPositionAttributeForParameter(id self, SEL _cmd, id parameter) {
    id pdfView = SKGetPDFView(self);
    if (pdfView && [self respondsToSelector:@selector(accessibilityRangeForSelection:)]) {
        NSPoint point = [pdfView convertPoint:[[pdfView window] convertScreenToBase:[parameter pointValue]] fromView:nil];
        PDFPage *page = [pdfView pageForPoint:point nearest:NO];
        if (page) {
            NSInteger i = [page characterIndexAtPoint:[pdfView convertPoint:point toPage:page]];
            if (i != -1) {
                // make sure the accessibility table is generated
                [self accessibilityAttributeValue:NSAccessibilityVisibleCharacterRangeAttribute];
                return [NSValue valueWithRange:[self accessibilityRangeForSelection:[page selectionForRange:NSMakeRange(i, 1)]]];
            }
        }
    }
    return nil;
}

static id replacement_accessibilityRTFForRangeAttributeForParameter(id self, SEL _cmd, id parameter) {
    PDFView *pdfView = SKGetPDFView(self);
    if (pdfView) {
        NSAttributedString *attributedString = attributedStringForAccessibilityRange(self, [parameter rangeValue], [pdfView scaleFactor]);
        return [attributedString RTFFromRange:NSMakeRange(0, [attributedString length]) documentAttributes:NULL];
    }
    return nil;
}

static id replacement_accessibilityAttributedStringForRangeAttributeForParameter(id self, SEL _cmd, id parameter) {
    PDFView *pdfView = SKGetPDFView(self);
    if (pdfView) {
        return [attributedStringForAccessibilityRange(self, [parameter rangeValue], [pdfView scaleFactor]) accessibilityAttributedString];
    }
    return nil;
}

static id replacement_accessibilityStyleRangeForIndexAttributeForParameter(id self, SEL _cmd, id parameter) {
    PDFView *pdfView = SKGetPDFView(self);
    if (pdfView) {
        // make sure the accessibility table is generated
        [self accessibilityAttributeValue:NSAccessibilityVisibleCharacterRangeAttribute];
        NSInteger i = [parameter unsignedIntegerValue];
        NSInteger n = [[self accessibilityAttributeValue:NSAccessibilityNumberOfCharactersAttribute] integerValue];
        NSInteger start = MAX(0, i - 25), end = MIN(n, i + 25);
        NSRange range = NSMakeRange(i, 1);
        NSRange r = NSMakeRange(start, end - start);
        BOOL foundRange = NO;
        while (foundRange == NO) {
            [attributedStringForAccessibilityRange(self, r, [pdfView scaleFactor]) attributesAtIndex:i - r.location longestEffectiveRange:&range inRange:NSMakeRange(0, r.length)];
            foundRange = YES;
            if (range.location == r.location && r.location > 0) {
                start = MAX(0, (NSInteger)r.location - 25);
                foundRange = NO;
            }
            if (NSMaxRange(range) == NSMaxRange(r) && (NSInteger)NSMaxRange(range) < n) {
                end = MIN(n, (NSInteger)NSMaxRange(r) + 25);
                foundRange = NO;
            }
            r = NSMakeRange(start, end - start);
        }
        return [NSValue valueWithRange:range];
    }
    return nil;
}

static id replacement_accessibilityHitTest(id self, SEL _cmd, NSPoint point) {
    id pdfView = SKGetPDFView(self);
    id element = nil;
    if ([pdfView respondsToSelector:@selector(accessibilityChildAtPoint:)])
        element = [pdfView accessibilityChildAtPoint:point];
    return element ?: original_accessibilityHitTest(self, _cmd, point);
}

static id replacement_accessibilityFocusedUIElement(id self, SEL _cmd) {
    id pdfView = SKGetPDFView(self);
    id element = nil;
    if ([pdfView respondsToSelector:@selector(accessibilityFocusedChild)])
        element = [pdfView accessibilityFocusedChild];
    return element ?: original_accessibilityFocusedUIElement(self, _cmd);
}

#pragma mark SKSwizzlePDFDisplayViewMethods

void SKSwizzlePDFDisplayViewMethods() {
    Class PDFDisplayViewClass = NSClassFromString(@"PDFDisplayView");
    if (PDFDisplayViewClass) {
        original_updateTrackingAreas = (void (*)(id, SEL))SKReplaceInstanceMethodImplementation(PDFDisplayViewClass, @selector(updateTrackingAreas), (IMP)replacement_updateTrackingAreas);
        
        if ([[NSUserDefaults standardUserDefaults] boolForKey:SKDisableExtendedPDFViewAccessibilityKey]) return;
        
        original_accessibilityAttributeNames = (id (*)(id, SEL))SKReplaceInstanceMethodImplementation(PDFDisplayViewClass, @selector(accessibilityAttributeNames), (IMP)replacement_accessibilityAttributeNames);
        original_accessibilityAttributeValue = (id (*)(id, SEL, id))SKReplaceInstanceMethodImplementation(PDFDisplayViewClass, @selector(accessibilityAttributeValue:), (IMP)replacement_accessibilityAttributeValue);
        original_accessibilityHitTest = (id (*)(id, SEL, NSPoint))SKReplaceInstanceMethodImplementation(PDFDisplayViewClass, @selector(accessibilityHitTest:), (IMP)replacement_accessibilityHitTest);
        original_accessibilityFocusedUIElement = (id (*)(id, SEL))SKReplaceInstanceMethodImplementation(PDFDisplayViewClass, @selector(accessibilityFocusedUIElement), (IMP)replacement_accessibilityFocusedUIElement);
        original_accessibilityParameterizedAttributeNames = (id (*)(id, SEL))SKReplaceInstanceMethodImplementation(PDFDisplayViewClass, @selector(accessibilityParameterizedAttributeNames), (IMP)replacement_accessibilityParameterizedAttributeNames);
        
        SKAddInstanceMethodImplementation(PDFDisplayViewClass, @selector(accessibilityRangeForPositionAttributeForParameter:), (IMP)replacement_accessibilityRangeForPositionAttributeForParameter, "@@:@");
        SKAddInstanceMethodImplementation(PDFDisplayViewClass, @selector(accessibilityRTFForRangeAttributeForParameter:), (IMP)replacement_accessibilityRTFForRangeAttributeForParameter, "@@:@");
        SKAddInstanceMethodImplementation(PDFDisplayViewClass, @selector(accessibilityAttributedStringForRangeAttributeForParameter:), (IMP)replacement_accessibilityAttributedStringForRangeAttributeForParameter, "@@:@");
        SKAddInstanceMethodImplementation(PDFDisplayViewClass, @selector(accessibilityStyleRangeForIndexAttributeForParameter:), (IMP)replacement_accessibilityStyleRangeForIndexAttributeForParameter, "@@:@");
    }
}

#pragma mark SKAccessibilityProxyElementParent

@implementation NSView (SKPDFDisplayViewExtensions)

- (NSRect)screenRectForFauxUIElement:(SKAccessibilityFauxUIElement *)element {
    NSRect rect = NSZeroRect;
    SKPDFView *pdfView = SKGetPDFView(self);
    if (pdfView) {
        PDFAnnotation *annotation = [element representedObject];
        if ([annotation respondsToSelector:@selector(bounds)] && [annotation respondsToSelector:@selector(page)]) {
            rect = [pdfView convertRect:[pdfView convertRect:[annotation bounds] fromPage:[annotation page]] toView:nil];
            rect.origin = [[pdfView window] convertBaseToScreen:rect.origin];
        }
    }
    return rect;
}

- (BOOL)isFauxUIElementFocused:(SKAccessibilityFauxUIElement *)element {
    SKPDFView *pdfView = SKGetPDFView(self);
    if ([pdfView respondsToSelector:@selector(activeAnnotation)])
        return [pdfView activeAnnotation] == [element representedObject];
    else
        return NO;
}

- (void)fauxUIlement:(SKAccessibilityFauxUIElement *)element setFocused:(BOOL)focused {
    SKPDFView *pdfView = SKGetPDFView(self);
    if ([pdfView respondsToSelector:@selector(setActiveAnnotation:)]) {
        PDFAnnotation *annotation = [element representedObject];
        if ([annotation isKindOfClass:[PDFAnnotation class]]) {
            if (focused)
                [pdfView setActiveAnnotation:annotation];
            else if ([pdfView activeAnnotation] == annotation)
                [pdfView setActiveAnnotation:nil];
        }
    }
}

- (void)pressFauxUIElement:(SKAccessibilityFauxUIElement *)element {
    SKPDFView *pdfView = SKGetPDFView(self);
    if ([pdfView respondsToSelector:@selector(activeAnnotation)] && [pdfView respondsToSelector:@selector(setActiveAnnotation:)] && [pdfView respondsToSelector:@selector(editActiveAnnotation:)]) {
        PDFAnnotation *annotation = [element representedObject];
        if ([annotation isKindOfClass:[PDFAnnotation class]]) {
            if ([pdfView activeAnnotation] != annotation)
                [pdfView setActiveAnnotation:annotation];
            [pdfView editActiveAnnotation:self];
        }
    }
}

@end
