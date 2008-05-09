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
#import "SKUtilities.h"

@interface PDFDisplayView : NSView
- (void)passwordEntered:(id)sender;
- (NSRange)accessibilityRangeForSelection:(id)selection;
- (id)selectionForAccessibilityRange:(NSRange)range;
- (void)generateAccessibilityTable;
@end


@interface PDFDisplayView (SKExtensions)
@end


@interface NSAttributedString (SKExtensions)
- (NSAttributedString *)accessibilityAttributedString;
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
    if ([[self skPdfView] respondsToSelector:@selector(accessibilityChildren)]) {
        static NSArray *attributes = nil;
        if (attributes == nil)
            attributes = [[originalAccessibilityAttributeNames(self, _cmd) arrayByAddingObject:NSAccessibilityChildrenAttribute] retain];
        return attributes;
    } else {
        return originalAccessibilityAttributeNames(self, _cmd);
    }
}

- (NSArray *)replacementAccessibilityParameterizedAttributeNames {
    static NSArray *attributes = nil;
    if (attributes == nil)
        attributes = [[originalAccessibilityParameterizedAttributeNames(self, _cmd) arrayByAddingObjectsFromArray:[NSArray arrayWithObjects:NSAccessibilityRangeForPositionParameterizedAttribute, NSAccessibilityRTFForRangeParameterizedAttribute, NSAccessibilityAttributedStringForRangeParameterizedAttribute, nil]] retain];
    return attributes;
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

- (id)replacementAccessibilityAttributedStringForRangeAttributeForParameter:(id)parameter {
    id pdfView = [self skPdfView];
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

- (id)replacementAccessibilityStyleRangeForIndexAttributeForParameter:(id)parameter {
    id pdfView = [self skPdfView];
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
    originalResetCursorRects = SKReplaceMethodImplementationWithSelector(self, @selector(resetCursorRects), @selector(replacementResetCursorRects));
    if ([self instancesRespondToSelector:@selector(passwordEntered:)])
        originalPasswordEntered = SKReplaceMethodImplementationWithSelector(self, @selector(passwordEntered:), @selector(replacementPasswordEntered:));
    if ([self instancesRespondToSelector:@selector(accessibilityAttributeNames)])
        originalAccessibilityAttributeNames = SKReplaceMethodImplementationWithSelector(self, @selector(accessibilityAttributeNames), @selector(replacementAccessibilityAttributeNames));
    if ([self instancesRespondToSelector:@selector(accessibilityParameterizedAttributeNames)])
        originalAccessibilityParameterizedAttributeNames = SKReplaceMethodImplementationWithSelector(self, @selector(accessibilityParameterizedAttributeNames), @selector(replacementAccessibilityParameterizedAttributeNames));
    if ([self instancesRespondToSelector:@selector(accessibilityAttributeValue:)])
        originalAccessibilityAttributeValue = SKReplaceMethodImplementationWithSelector(self, @selector(accessibilityAttributeValue:), @selector(replacementAccessibilityAttributeValue:));
    if ([self instancesRespondToSelector:@selector(accessibilityHitTest:)])
        originalAccessibilityHitTest = SKReplaceMethodImplementationWithSelector(self, @selector(accessibilityHitTest:), @selector(replacementAccessibilityHitTest:));
    if ([self instancesRespondToSelector:@selector(accessibilityFocusedUIElement)])
        originalAccessibilityFocusedUIElement = SKReplaceMethodImplementationWithSelector(self, @selector(accessibilityFocusedUIElement), @selector(replacementAccessibilityFocusedUIElement));
    if ([self instancesRespondToSelector:@selector(accessibilityRangeForPositionAttributeForParameter:)] == NO)
        SKRegisterMethodImplementationWithSelector(self, @selector(accessibilityRangeForPositionAttributeForParameter:), @selector(replacementAccessibilityRangeForPositionAttributeForParameter:));
    if ([self instancesRespondToSelector:@selector(accessibilityRTFForRangeAttributeForParameter:)] == NO)
        SKRegisterMethodImplementationWithSelector(self, @selector(accessibilityRTFForRangeAttributeForParameter:), @selector(replacementAccessibilityRTFForRangeAttributeForParameter:));
    if ([self instancesRespondToSelector:@selector(accessibilityAttributedStringForRangeAttributeForParameter:)] == NO)
        SKRegisterMethodImplementationWithSelector(self, @selector(accessibilityAttributedStringForRangeAttributeForParameter:), @selector(replacementAccessibilityAttributedStringForRangeAttributeForParameter:));
    if ([self instancesRespondToSelector:@selector(accessibilityStyleRangeForIndexAttributeForParameter:)] == NO)
        SKRegisterMethodImplementationWithSelector(self, @selector(accessibilityStyleRangeForIndexAttributeForParameter:), @selector(replacementAccessibilityStyleRangeForIndexAttributeForParameter:));
}

@end


@implementation NSAttributedString (SKExtensions)

- (NSAttributedString *)accessibilityAttributedString {
    NSTextFieldCell *cell = nil;
    if (cell == nil)
        cell = [[NSTextFieldCell alloc] init];
    [cell setAttributedStringValue:self];
    return [cell accessibilityAttributeValue:NSAccessibilityAttributedStringForRangeParameterizedAttribute forParameter:[NSValue valueWithRange:NSMakeRange(0, [self length])]];
}

@end
