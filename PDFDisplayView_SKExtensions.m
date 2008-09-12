//
//  PDFDisplayView_SKExtensions.m
//  Skim
//
//  Created by Christiaan Hofman on 4/22/08.
/*
 This software is Copyright (c) 2008
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
#import "SKPDFDocument.h"
#import "SKRuntime.h"
#import "SKAccessibilityFauxUIElement.h"

@interface NSView (SKPDFDisplayViewPrivateDeclarations)
- (void)passwordEntered:(id)sender;

- (NSRange)accessibilityRangeForSelection:(id)selection;
- (id)selectionForAccessibilityRange:(NSRange)range;
- (void)generateAccessibilityTable;

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

static void (*originalResetCursorRects)(id, SEL) = NULL;
static void (*originalPasswordEntered)(id, SEL, id) = NULL;

static id (*originalAccessibilityAttributeNames)(id, SEL) = NULL;
static id (*originalAccessibilityParameterizedAttributeNames)(id, SEL) = NULL;
static id (*originalAccessibilityAttributeValue)(id, SEL, id) = NULL;
static id (*originalAccessibilityHitTest)(id, SEL, NSPoint) = NULL;
static id (*originalAccessibilityFocusedUIElement)(id, SEL) = NULL;

#pragma mark Skim support

static void replacementResetCursorRects(id self, SEL _cmd) {
	originalResetCursorRects(self, _cmd);
    id pdfView = SKGetPDFView(self);
    if ([pdfView respondsToSelector:@selector(resetPDFToolTipRects)])
        [pdfView resetPDFToolTipRects];
}

static void replacementPasswordEntered(id self, SEL _cmd, id sender) {
    SKPDFDocument *document = [[[self window] windowController] document];
    originalPasswordEntered(self, _cmd, sender);
    if ([document respondsToSelector:@selector(savePasswordInKeychain:)])
        [document savePasswordInKeychain:[sender stringValue]];
}

#pragma mark Accessibility

static NSArray *replacementAccessibilityAttributeNames(id self, SEL _cmd) {
    if ([SKGetPDFView(self) respondsToSelector:@selector(accessibilityChildren)]) {
        static NSArray *attributes = nil;
        if (attributes == nil)
            attributes = [[originalAccessibilityAttributeNames(self, _cmd) arrayByAddingObject:NSAccessibilityChildrenAttribute] retain];
        return attributes;
    } else {
        return originalAccessibilityAttributeNames(self, _cmd);
    }
}

static NSArray *replacementAccessibilityParameterizedAttributeNames(id self, SEL _cmd) {
    static NSArray *attributes = nil;
    if (attributes == nil)
        attributes = [[originalAccessibilityParameterizedAttributeNames(self, _cmd) arrayByAddingObjectsFromArray:[NSArray arrayWithObjects:NSAccessibilityRangeForPositionParameterizedAttribute, NSAccessibilityRTFForRangeParameterizedAttribute, NSAccessibilityAttributedStringForRangeParameterizedAttribute, nil]] retain];
    return attributes;
}

static id replacementAccessibilityAttributeValue(id self, SEL _cmd, NSString *attribute) {
    if ([attribute isEqualToString:NSAccessibilityRoleAttribute]) {
        return NSAccessibilityTextAreaRole;
    } else if ([attribute isEqualToString:NSAccessibilityChildrenAttribute]) {
        id pdfView = SKGetPDFView(self);
        return [pdfView respondsToSelector:@selector(accessibilityChildren)] ? NSAccessibilityUnignoredChildren([pdfView accessibilityChildren]) : originalAccessibilityAttributeValue(self, _cmd, attribute);
    } else {
        return originalAccessibilityAttributeValue(self, _cmd, attribute);
    }
}

static void generateAccessibilityTableIfNeeded(id pdfDisplayView) {
    @try {
        if ([[pdfDisplayView valueForKey:@"numAccessibilityLines"] unsignedIntValue] == 0 &&
            [pdfDisplayView respondsToSelector:@selector(generateAccessibilityTable)])
            [pdfDisplayView generateAccessibilityTable];
    }
    @catch (id exception) {}
}

static NSAttributedString *attributedStringForAccessibilityRange(id pdfDisplayView, NSRange range) {
    NSAttributedString *attributedString = nil;
    if ([pdfDisplayView respondsToSelector:@selector(selectionForAccessibilityRange:)]) {
        PDFSelection *selection = [pdfDisplayView selectionForAccessibilityRange:range];
        if ([selection respondsToSelector:@selector(attributedString)])
            attributedString = [selection attributedString];
    }
    return attributedString;
}

static id replacementAccessibilityRangeForPositionAttributeForParameter(id self, SEL _cmd, id parameter) {
    id pdfView = SKGetPDFView(self);
    if (pdfView && [self respondsToSelector:@selector(accessibilityRangeForSelection:)]) {
        NSPoint point = [pdfView convertPoint:[[pdfView window] convertScreenToBase:[parameter pointValue]] fromView:nil];
        PDFPage *page = [pdfView pageForPoint:point nearest:NO];
        if (page) {
            int i = [page characterIndexAtPoint:[pdfView convertPoint:point toPage:page]];
            if (i != -1) {
                generateAccessibilityTableIfNeeded(self);
                return [NSValue valueWithRange:[self accessibilityRangeForSelection:[page selectionForRange:NSMakeRange(i, 1)]]];
            }
        }
    }
    return nil;
}

static id replacementAccessibilityRTFForRangeAttributeForParameter(id self, SEL _cmd, id parameter) {
    id pdfView = SKGetPDFView(self);
    if (pdfView) {
        generateAccessibilityTableIfNeeded(self);
        NSAttributedString *attributedString = attributedStringForAccessibilityRange(self, [parameter rangeValue]);
        return [attributedString RTFFromRange:NSMakeRange(0, [attributedString length]) documentAttributes:NULL];
    }
    return nil;
}

static id replacementAccessibilityAttributedStringForRangeAttributeForParameter(id self, SEL _cmd, id parameter) {
    id pdfView = SKGetPDFView(self);
    if (pdfView) {
        generateAccessibilityTableIfNeeded(self);
        return [attributedStringForAccessibilityRange(self, [parameter rangeValue]) accessibilityAttributedString];
    }
    return nil;
}

static id replacementAccessibilityStyleRangeForIndexAttributeForParameter(id self, SEL _cmd, id parameter) {
    id pdfView = SKGetPDFView(self);
    if (pdfView) {
        generateAccessibilityTableIfNeeded(self);
        int i = [parameter unsignedIntValue];
        int n = [[self accessibilityAttributeValue:NSAccessibilityNumberOfCharactersAttribute] intValue];
        int start = MAX(0, i - 25), end = MIN(n, i + 25);
        NSRange range = NSMakeRange(i, 1);
        NSRange r = NSMakeRange(start, end - start);
        BOOL foundRange = NO;
        while (foundRange == NO) {
            [attributedStringForAccessibilityRange(self, r) attributesAtIndex:i - r.location longestEffectiveRange:&range inRange:NSMakeRange(0, r.length)];
            foundRange = YES;
            if (range.location == r.location && r.location > 0) {
                start = MAX(0, (int)r.location - 25);
                foundRange = NO;
            }
            if (NSMaxRange(range) == NSMaxRange(r) && (int)NSMaxRange(range) < n) {
                end = MIN(n, (int)NSMaxRange(r) + 25);
                foundRange = NO;
            }
            r = NSMakeRange(start, end - start);
        }
        return [NSValue valueWithRange:range];
    }
    return nil;
}

static id replacementAccessibilityHitTest(id self, SEL _cmd, NSPoint point) {
    id pdfView = SKGetPDFView(self);
    id element = nil;
    if ([pdfView respondsToSelector:@selector(accessibilityChildAtPoint:)])
        element = [pdfView accessibilityChildAtPoint:point];
    return element ?: originalAccessibilityHitTest(self, _cmd, point);
}

static id replacementAccessibilityFocusedUIElement(id self, SEL _cmd) {
    id pdfView = SKGetPDFView(self);
    id element = nil;
    if ([pdfView respondsToSelector:@selector(accessibilityFocusedChild)])
        element = [pdfView accessibilityFocusedChild];
    return element ?: originalAccessibilityFocusedUIElement(self, _cmd);
}

#pragma mark SKSwizzlePDFDisplayViewMethods

void SKSwizzlePDFDisplayViewMethods() {
    Class PDFDisplayViewClass = NSClassFromString(@"PDFDisplayView");
    if (PDFDisplayViewClass) {
        originalResetCursorRects = (void (*)(id, SEL))SKReplaceInstanceMethodImplementation(PDFDisplayViewClass, @selector(resetCursorRects), (IMP)replacementResetCursorRects);
        originalPasswordEntered = (void (*)(id, SEL, id))SKReplaceInstanceMethodImplementation(PDFDisplayViewClass, @selector(passwordEntered:), (IMP)replacementPasswordEntered);
        
        if ([[NSUserDefaults standardUserDefaults] boolForKey:@"SKDisableExtendedPDFViewAccessibility"]) return;
        
        originalAccessibilityAttributeNames = (id (*)(id, SEL))SKReplaceInstanceMethodImplementation(PDFDisplayViewClass, @selector(accessibilityAttributeNames), (IMP)replacementAccessibilityAttributeNames);
        originalAccessibilityParameterizedAttributeNames = (id (*)(id, SEL))SKReplaceInstanceMethodImplementation(PDFDisplayViewClass, @selector(accessibilityParameterizedAttributeNames), (IMP)replacementAccessibilityParameterizedAttributeNames);
        originalAccessibilityAttributeValue = (id (*)(id, SEL, id))SKReplaceInstanceMethodImplementation(PDFDisplayViewClass, @selector(accessibilityAttributeValue:), (IMP)replacementAccessibilityAttributeValue);
        originalAccessibilityHitTest = (id (*)(id, SEL, NSPoint))SKReplaceInstanceMethodImplementation(PDFDisplayViewClass, @selector(accessibilityHitTest:), (IMP)replacementAccessibilityHitTest);
        originalAccessibilityFocusedUIElement = (id (*)(id, SEL))SKReplaceInstanceMethodImplementation(PDFDisplayViewClass, @selector(accessibilityFocusedUIElement), (IMP)replacementAccessibilityFocusedUIElement);
            
        SKAddInstanceMethodImplementation(PDFDisplayViewClass, @selector(accessibilityRangeForPositionAttributeForParameter:), (IMP)replacementAccessibilityRangeForPositionAttributeForParameter, "@@:@");
        SKAddInstanceMethodImplementation(PDFDisplayViewClass, @selector(accessibilityRTFForRangeAttributeForParameter:), (IMP)replacementAccessibilityRTFForRangeAttributeForParameter, "@@:@");
        SKAddInstanceMethodImplementation(PDFDisplayViewClass, @selector(accessibilityAttributedStringForRangeAttributeForParameter:), (IMP)replacementAccessibilityAttributedStringForRangeAttributeForParameter, "@@:@");
        SKAddInstanceMethodImplementation(PDFDisplayViewClass, @selector(accessibilityStyleRangeForIndexAttributeForParameter:), (IMP)replacementAccessibilityStyleRangeForIndexAttributeForParameter, "@@:@");
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
    return [SKGetPDFView(self) activeAnnotation] == [element representedObject];
}

- (void)fauxUIlement:(SKAccessibilityFauxUIElement *)element setFocused:(BOOL)focused {
    SKPDFView *pdfView = SKGetPDFView(self);
    if (pdfView) {
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
    if (pdfView) {
        PDFAnnotation *annotation = [element representedObject];
        if ([annotation isKindOfClass:[PDFAnnotation class]]) {
            if ([pdfView activeAnnotation] != annotation)
                [pdfView setActiveAnnotation:annotation];
            [pdfView editActiveAnnotation:self];
        }
    }
}

@end
