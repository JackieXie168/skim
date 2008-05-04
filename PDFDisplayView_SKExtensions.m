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
#import "SKPDFView.h"
#import "PDFAnnotation_SKExtensions.h"
#import "SKPDFDocument.h"
#import "SKStringConstants.h"
#import "OBUtilities.h"

@interface PDFDisplayView : NSView
- (void)passwordEntered:(id)sender;
- (NSRange)accessibilityRangeForSelection:(id)selection;
- (id)selectionForAccessibilityRange:(NSRange)range;
- (void)generateAccessibilityTable;
@end

@interface PDFDisplayView (SKExtensions)
@end

@implementation PDFDisplayView (SKExtensions)

static IMP originalResetCursorRects = NULL;
static IMP originalPasswordEntered = NULL;

static IMP originalAccessibilityAttributeNames = NULL;
static IMP originalAccessibilityParameterizedAttributeNames = NULL;
static IMP originalAccessibilityAttributeValue = NULL;
static IMP originalAccessibilityHitTest = NULL;
static IMP originalAccessibilityFocusedUIElement = NULL;

- (id)skPdfView {
    id pdfView = nil;
    @try { pdfView = [self valueForKey:@"pdfView"]; }
    @catch (id exception) {}
    return pdfView;
}

- (void)replacementResetCursorRects {
	originalResetCursorRects(self, _cmd);
    id pdfView = [self skPdfView];
    if ([pdfView respondsToSelector:@selector(resetHoverRects)])
        [pdfView resetHoverRects];
}

- (void)replacementPasswordEntered:(id)sender {
    SKPDFDocument *document = [[[self window] windowController] document];
    originalPasswordEntered(self, _cmd, sender);
    if ([document respondsToSelector:@selector(savePasswordInKeychain:)])
        [document savePasswordInKeychain:[sender stringValue]];
}

#pragma mark Accessibility

- (NSArray *)replacementAccessibilityAttributeNames {
    static NSArray *attributes = nil;
    if (attributes == nil)
        attributes = [[originalAccessibilityAttributeNames(self, _cmd) arrayByAddingObject:NSAccessibilityChildrenAttribute] retain];
    return attributes;
}

- (NSArray *)replacementAccessibilityParameterizedAttributeNames {
    if ([[self skPdfView] respondsToSelector:@selector(accessibilityChildren)]) {
        static NSArray *attributes = nil;
        if (attributes == nil)
            attributes = [[originalAccessibilityParameterizedAttributeNames(self, _cmd) arrayByAddingObjectsFromArray:[NSArray arrayWithObjects:NSAccessibilityRangeForPositionParameterizedAttribute, NSAccessibilityRTFForRangeParameterizedAttribute, nil]] retain];
        return attributes;
    } else {
        return originalAccessibilityAttributeNames(self, _cmd);
    }
}

- (id)replacementAccessibilityAttributeValue:(NSString *)attribute {
    if ([attribute isEqualToString:NSAccessibilityRoleAttribute]) {
        return NSAccessibilityTextAreaRole;
    } else if ([attribute isEqualToString:NSAccessibilityChildrenAttribute]) {
        id pdfView = [self skPdfView];
        return [pdfView respondsToSelector:@selector(accessibilityChildren)] ? NSAccessibilityUnignoredChildren([pdfView accessibilityChildren]) : originalAccessibilityAttributeValue(self, _cmd, attribute);
    } else {
        return originalAccessibilityAttributeValue(self, _cmd, attribute);
    }
}

- (id)replacementAccessibilityRangeForPositionAttributeForParameter:(id)parameter {
    id pdfView = [self skPdfView];
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

- (id)replacementAccessibilityRTFForRangeAttributeForParameter:(id)parameter {
    id pdfView = [self skPdfView];
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

- (id)replacementAccessibilityHitTest:(NSPoint)point {
    id pdfView = [self skPdfView];
    id element = nil;
    if ([pdfView respondsToSelector:@selector(accessibilityChildAtPoint:)])
        element = [pdfView accessibilityChildAtPoint:point];
    return element ? element : originalAccessibilityHitTest(self, _cmd, point);
}

- (id)replacementAccessibilityFocusedUIElement {
    id pdfView = [self skPdfView];
    id element = nil;
    if ([pdfView respondsToSelector:@selector(accessibilityFocusedChild)])
        element = [pdfView accessibilityFocusedChild];
    return element ? element : originalAccessibilityFocusedUIElement(self, _cmd);
}

- (NSRect)screenRectForRepresentedObject:(id)annotation {
    NSRect rect = NSZeroRect;
    SKPDFView *pdfView = [self skPdfView];
    if (pdfView) {
        rect = [pdfView convertRect:[pdfView convertRect:[annotation bounds] fromPage:[annotation page]] toView:nil];
        rect.origin = [[pdfView window] convertBaseToScreen:rect.origin];
    }
    return rect;
}

- (BOOL)isRepresentedObjectFocused:(id)annotation {
    return [[self skPdfView] activeAnnotation] == annotation;
}

- (void)setFocused:(BOOL)focused forRepresentedObject:(id)annotation {
    SKPDFView *pdfView = [self skPdfView];
    if (pdfView) {
        if (focused)
            [pdfView setActiveAnnotation:annotation];
        else if ([pdfView activeAnnotation] == annotation)
            [pdfView setActiveAnnotation:nil];
    }
}

- (void)pressRepresentedObject:(id)annotation {
    SKPDFView *pdfView = [self skPdfView];
    if (pdfView) {
        if ([pdfView activeAnnotation] != annotation)
            [pdfView setActiveAnnotation:annotation];
        [pdfView editActiveAnnotation:self];
    }
}

+ (void)load {
    originalResetCursorRects = OBReplaceMethodImplementationWithSelector(self, @selector(resetCursorRects), @selector(replacementResetCursorRects));
    if ([self instancesRespondToSelector:@selector(passwordEntered:)])
        originalPasswordEntered = OBReplaceMethodImplementationWithSelector(self, @selector(passwordEntered:), @selector(replacementPasswordEntered:));
    if ([self instancesRespondToSelector:@selector(accessibilityAttributeNames)])
        originalAccessibilityAttributeNames = OBReplaceMethodImplementationWithSelector(self, @selector(accessibilityAttributeNames), @selector(replacementAccessibilityAttributeNames));
    if ([self instancesRespondToSelector:@selector(accessibilityParameterizedAttributeNames)])
        originalAccessibilityParameterizedAttributeNames = OBReplaceMethodImplementationWithSelector(self, @selector(accessibilityParameterizedAttributeNames), @selector(replacementAccessibilityParameterizedAttributeNames));
    if ([self instancesRespondToSelector:@selector(accessibilityAttributeValue:)])
        originalAccessibilityAttributeValue = OBReplaceMethodImplementationWithSelector(self, @selector(accessibilityAttributeValue:), @selector(replacementAccessibilityAttributeValue:));
    if ([self instancesRespondToSelector:@selector(accessibilityHitTest:)])
        originalAccessibilityHitTest = OBReplaceMethodImplementationWithSelector(self, @selector(accessibilityHitTest:), @selector(replacementAccessibilityHitTest:));
    if ([self instancesRespondToSelector:@selector(accessibilityFocusedUIElement)])
        originalAccessibilityFocusedUIElement = OBReplaceMethodImplementationWithSelector(self, @selector(accessibilityFocusedUIElement), @selector(replacementAccessibilityFocusedUIElement));
    if ([self instancesRespondToSelector:@selector(accessibilityRangeForPositionAttributeForParameter:)] == NO)
        OBAddMethodImplementationWithSelector(self, @selector(accessibilityRangeForPositionAttributeForParameter:), @selector(replacementAccessibilityRangeForPositionAttributeForParameter:));
    if ([self instancesRespondToSelector:@selector(accessibilityRTFForRangeAttributeForParameter:)] == NO)
        OBAddMethodImplementationWithSelector(self, @selector(accessibilityRTFForRangeAttributeForParameter:), @selector(replacementAccessibilityRTFForRangeAttributeForParameter:));
}

@end
