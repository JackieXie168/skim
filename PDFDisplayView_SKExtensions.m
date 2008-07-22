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
#import "NSObject_SKExtensions.h"
#import "SKAccessibilityProxyElement.h"

@interface NSView (SKPDFDisplayViewprivateDeclarations)
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

static IMP originalResetCursorRects = NULL;
static IMP originalPasswordEntered = NULL;

static IMP originalAccessibilityAttributeNames = NULL;
static IMP originalAccessibilityParameterizedAttributeNames = NULL;
static IMP originalAccessibilityAttributeValue = NULL;
static IMP originalAccessibilityHitTest = NULL;
static IMP originalAccessibilityFocusedUIElement = NULL;

#pragma mark Skim support

static void replacementResetCursorRects(id self, SEL _cmd) {
	originalResetCursorRects(self, _cmd);
    id pdfView = SKGetPDFView(self);
    if ([pdfView respondsToSelector:@selector(resetHoverRects)])
        [pdfView resetHoverRects];
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

static id replacementAccessibilityRangeForPositionAttributeForParameter(id self, SEL _cmd, id parameter) {
    id pdfView = SKGetPDFView(self);
    if (pdfView && [self respondsToSelector:@selector(accessibilityRangeForSelection:)]) {
        NSPoint point = [pdfView convertPoint:[[pdfView window] convertScreenToBase:[parameter pointValue]] fromView:nil];
        PDFPage *page = [pdfView pageForPoint:point nearest:NO];
        if (page) {
            int i = [page characterIndexAtPoint:[pdfView convertPoint:point toPage:page]];
            if (i != -1) {
                @try {
                    if ([[self valueForKey:@"numAccessibilityLines"] unsignedIntValue] == 0 && [self respondsToSelector:@selector(generateAccessibilityTable)])
                        [self generateAccessibilityTable];
                }
                @catch (id exception) {}
                return [NSValue valueWithRange:[self accessibilityRangeForSelection:[page selectionForRange:NSMakeRange(i, 1)]]];
            }
        }
    }
    return nil;
}

static id replacementAccessibilityRTFForRangeAttributeForParameter(id self, SEL _cmd, id parameter) {
    id pdfView = SKGetPDFView(self);
    if (pdfView && [self respondsToSelector:@selector(selectionForAccessibilityRange:)]) {
        @try {
            if ([[self valueForKey:@"numAccessibilityLines"] unsignedIntValue] == 0 && [self respondsToSelector:@selector(generateAccessibilityTable)])
                [self generateAccessibilityTable];
        }
        @catch (id exception) {}
        NSAttributedString *attributedString = [[self selectionForAccessibilityRange:[parameter rangeValue]] attributedString];
        return [attributedString RTFFromRange:NSMakeRange(0, [attributedString length]) documentAttributes:NULL];
    }
    return nil;
}

static id replacementAccessibilityAttributedStringForRangeAttributeForParameter(id self, SEL _cmd, id parameter) {
    id pdfView = SKGetPDFView(self);
    if (pdfView && [self respondsToSelector:@selector(selectionForAccessibilityRange:)]) {
        @try {
            if ([[self valueForKey:@"numAccessibilityLines"] unsignedIntValue] == 0 && [self respondsToSelector:@selector(generateAccessibilityTable)])
                [self generateAccessibilityTable];
        }
        @catch (id exception) {}
        NSAttributedString *attributedString = [[self selectionForAccessibilityRange:[parameter rangeValue]] attributedString];
        return [attributedString accessibilityAttributedString];
    }
    return nil;
}

static id replacementAccessibilityStyleRangeForIndexAttributeForParameter(id self, SEL _cmd, id parameter) {
    id pdfView = SKGetPDFView(self);
    if (pdfView && [self respondsToSelector:@selector(selectionForAccessibilityRange:)]) {
        @try {
            if ([[self valueForKey:@"numAccessibilityLines"] unsignedIntValue] == 0 && [self respondsToSelector:@selector(generateAccessibilityTable)])
                [self generateAccessibilityTable];
        }
        @catch (id exception) {}
        int i = [parameter unsignedIntValue];
        int n = [[self accessibilityAttributeValue:NSAccessibilityNumberOfCharactersAttribute] intValue];
        int start = MAX(0, i - 25), end = MIN(n, i + 25);
        NSRange range = NSMakeRange(i, 1);
        NSRange r = NSMakeRange(start, end - start);
        BOOL foundRange = NO;
        while (foundRange == NO) {
            [[[self selectionForAccessibilityRange:r] attributedString] attributesAtIndex:i - r.location longestEffectiveRange:&range inRange:NSMakeRange(0, r.length)];
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
    return element ? element : originalAccessibilityHitTest(self, _cmd, point);
}

static id replacementAccessibilityFocusedUIElement(id self, SEL _cmd) {
    id pdfView = SKGetPDFView(self);
    id element = nil;
    if ([pdfView respondsToSelector:@selector(accessibilityFocusedChild)])
        element = [pdfView accessibilityFocusedChild];
    return element ? element : originalAccessibilityFocusedUIElement(self, _cmd);
}

#pragma mark SKSwizzlePDFDisplayViewMethods

void SKSwizzlePDFDisplayViewMethods() {
    Class PDFDisplayViewClass = NSClassFromString(@"PDFDisplayView");
    if (PDFDisplayViewClass) {
        if ([PDFDisplayViewClass instancesRespondToSelector:@selector(resetCursorRects)])
            originalResetCursorRects = [PDFDisplayViewClass setInstanceMethod:(IMP)replacementResetCursorRects typeEncoding:"v@:" forSelector:@selector(resetCursorRects)];
        if ([PDFDisplayViewClass instancesRespondToSelector:@selector(passwordEntered:)])
            originalPasswordEntered = [PDFDisplayViewClass setInstanceMethod:(IMP)replacementPasswordEntered typeEncoding:"v@:@" forSelector:@selector(passwordEntered:)];
        
        if ([[NSUserDefaults standardUserDefaults] boolForKey:@"SKDisableExtendedPDFViewAccessibility"]) return;
        
        if ([PDFDisplayViewClass instancesRespondToSelector:@selector(accessibilityAttributeNames)])
            originalAccessibilityAttributeNames = [PDFDisplayViewClass setInstanceMethod:(IMP)replacementAccessibilityAttributeNames typeEncoding:"@@:" forSelector:@selector(accessibilityAttributeNames)];
        if ([PDFDisplayViewClass instancesRespondToSelector:@selector(accessibilityParameterizedAttributeNames)])
            originalAccessibilityParameterizedAttributeNames = [PDFDisplayViewClass setInstanceMethod:(IMP)replacementAccessibilityParameterizedAttributeNames typeEncoding:"@@:" forSelector:@selector(accessibilityParameterizedAttributeNames)];
        if ([PDFDisplayViewClass instancesRespondToSelector:@selector(accessibilityAttributeValue:)])
            originalAccessibilityAttributeValue = [PDFDisplayViewClass setInstanceMethod:(IMP)replacementAccessibilityAttributeValue typeEncoding:"@@:@" forSelector:@selector(accessibilityAttributeValue:)];
        if ([PDFDisplayViewClass instancesRespondToSelector:@selector(accessibilityHitTest:)])
            originalAccessibilityHitTest = [PDFDisplayViewClass setInstanceMethod:(IMP)replacementAccessibilityHitTest typeEncoding:"@@:{_NSPoint=ff}" forSelector:@selector(accessibilityHitTest:)];
        if ([PDFDisplayViewClass instancesRespondToSelector:@selector(accessibilityFocusedUIElement)])
            originalAccessibilityFocusedUIElement = [PDFDisplayViewClass setInstanceMethod:(IMP)replacementAccessibilityFocusedUIElement typeEncoding:"@@:" forSelector:@selector(accessibilityFocusedUIElement)];
            
        if ([PDFDisplayViewClass instancesRespondToSelector:@selector(accessibilityRangeForPositionAttributeForParameter:)] == NO)
            [PDFDisplayViewClass setInstanceMethod:(IMP)replacementAccessibilityRangeForPositionAttributeForParameter typeEncoding:"@@:@" forSelector:@selector(accessibilityRangeForPositionAttributeForParameter:)];
        if ([PDFDisplayViewClass instancesRespondToSelector:@selector(accessibilityRTFForRangeAttributeForParameter:)] == NO)
            [PDFDisplayViewClass setInstanceMethod:(IMP)replacementAccessibilityRTFForRangeAttributeForParameter typeEncoding:"@@:@" forSelector:@selector(accessibilityRTFForRangeAttributeForParameter:)];
        if ([PDFDisplayViewClass instancesRespondToSelector:@selector(accessibilityAttributedStringForRangeAttributeForParameter:)] == NO)
            [PDFDisplayViewClass setInstanceMethod:(IMP)replacementAccessibilityAttributedStringForRangeAttributeForParameter typeEncoding:"@@:@" forSelector:@selector(accessibilityAttributedStringForRangeAttributeForParameter:)];
        if ([PDFDisplayViewClass instancesRespondToSelector:@selector(accessibilityStyleRangeForIndexAttributeForParameter:)] == NO)
            [PDFDisplayViewClass setInstanceMethod:(IMP)replacementAccessibilityStyleRangeForIndexAttributeForParameter typeEncoding:"@@:@" forSelector:@selector(accessibilityStyleRangeForIndexAttributeForParameter:)];
    }
}

#pragma mark SKAccessibilityProxyElementParent

@implementation NSView (SKPDFDisplayViewExtensions)

- (NSRect)element:(SKAccessibilityProxyElement *)element screenRectForRepresentedObject:(id)annotation {
    NSRect rect = NSZeroRect;
    SKPDFView *pdfView = SKGetPDFView(self);
    if (pdfView) {
        rect = [pdfView convertRect:[pdfView convertRect:[annotation bounds] fromPage:[annotation page]] toView:nil];
        rect.origin = [[pdfView window] convertBaseToScreen:rect.origin];
    }
    return rect;
}

- (BOOL)element:(SKAccessibilityProxyElement *)element isRepresentedObjectFocused:(id)annotation {
    return [SKGetPDFView(self) activeAnnotation] == annotation;
}

- (void)element:(SKAccessibilityProxyElement *)element setFocused:(BOOL)focused forRepresentedObject:(id)annotation {
    SKPDFView *pdfView = SKGetPDFView(self);
    if (pdfView) {
        if (focused)
            [pdfView setActiveAnnotation:annotation];
        else if ([pdfView activeAnnotation] == annotation)
            [pdfView setActiveAnnotation:nil];
    }
}

- (void)element:(SKAccessibilityProxyElement *)element pressRepresentedObject:(id)annotation {
    SKPDFView *pdfView = SKGetPDFView(self);
    if (pdfView) {
        if ([pdfView activeAnnotation] != annotation)
            [pdfView setActiveAnnotation:annotation];
        [pdfView editActiveAnnotation:self];
    }
}

@end
