//
//  PDFDisplayView_SKExtensions.m
//  Skim
//
//  Created by Christiaan Hofman on 4/22/08.
/*
 This software is Copyright (c) 2008-2017
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
#import "NSAttributedString_SKExtensions.h"
#import "SKRuntime.h"

#define SKDisableExtendedPDFViewAccessibilityKey @"SKDisableExtendedPDFViewAccessibility"

@interface NSView (SKPDFDisplayViewPrivateDeclarations)
- (NSRange)accessibilityRangeForSelection:(id)selection;
- (id)selectionForAccessibilityRange:(NSRange)range;
- (id)pdfView;
- (id)getPDFView;
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
    if ([self respondsToSelector:@selector(getPDFView)]) {
        pdfView = [self getPDFView];
    } else if ([self respondsToSelector:@selector(pdfView)]) {
        pdfView = [self pdfView];
    } else {
        @try { pdfView = [self valueForKeyPath:@"private.pdfView"] ?: [self valueForKey:@"pdfView"]; }
        @catch (id exception) {}
    }
    return pdfView;
}

static void (*original_updateTrackingAreas)(id, SEL) = NULL;

static id (*original_accessibilityParameterizedAttributeNames)(id, SEL) = NULL;
static id (*original_accessibilityAttributeValue)(id, SEL, id) = NULL;

#pragma mark Skim support

static void replacement_updateTrackingAreas(id self, SEL _cmd) {
	original_updateTrackingAreas(self, _cmd);
    id pdfView = SKGetPDFView(self);
    if ([pdfView respondsToSelector:@selector(resetPDFToolTipRects)])
        [pdfView resetPDFToolTipRects];
}

#pragma mark Accessibility

static NSArray *replacement_accessibilityParameterizedAttributeNames(id self, SEL _cmd) {
    static NSArray *attributes = nil;
    if (attributes == nil)
        attributes = [[original_accessibilityParameterizedAttributeNames(self, _cmd) arrayByAddingObjectsFromArray:[NSArray arrayWithObjects:NSAccessibilityRangeForPositionParameterizedAttribute, NSAccessibilityRTFForRangeParameterizedAttribute, NSAccessibilityAttributedStringForRangeParameterizedAttribute, nil]] retain];
    return attributes;
}

static id replacement_accessibilityAttributeValue(id self, SEL _cmd, NSString *attribute) {
    id value = original_accessibilityAttributeValue(self, _cmd, attribute);
    if ([attribute isEqualToString:NSAccessibilityRoleAttribute] && [value isEqualToString:NSAccessibilityStaticTextRole])
        value = NSAccessibilityTextAreaRole;
    return value;
}

static NSAttributedString *attributedStringForAccessibilityRange(id pdfDisplayView, NSRange range, CGFloat scale) {
    NSAttributedString *attributedString = nil;
    // make sure the accessibility table is generated
    [pdfDisplayView accessibilityAttributeValue:NSAccessibilityVisibleCharacterRangeAttribute];
    PDFSelection *selection = [pdfDisplayView selectionForAccessibilityRange:range];
    if ([selection respondsToSelector:@selector(attributedString)]) {
        attributedString = [selection attributedString];
        if (fabs(scale - 1.0) > 0.0) {
            NSMutableAttributedString *mutableAttrString = [[attributedString mutableCopy] autorelease];
            range = NSMakeRange(0, [mutableAttrString length]);
            [mutableAttrString enumerateAttribute:NSFontAttributeName inRange:range options:0 usingBlock:^(id font, NSRange r, BOOL *stop){
                if (font) {
                    font = [[NSFontManager sharedFontManager] convertFont:font toSize:round(scale * [font pointSize])];
                    [mutableAttrString addAttribute:NSFontAttributeName value:font range:r];
                }
            }];
            [mutableAttrString fixFontAttributeInRange:range];
            attributedString = mutableAttrString;
        }
    }
    return attributedString;
}

static id fallback_accessibilityRangeForPositionAttributeForParameter(id self, SEL _cmd, id parameter) {
    id pdfView = SKGetPDFView(self);
    if (pdfView) {
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

static id fallback_accessibilityRTFForRangeAttributeForParameter(id self, SEL _cmd, id parameter) {
    PDFView *pdfView = SKGetPDFView(self);
    if (pdfView) {
        NSAttributedString *attributedString = attributedStringForAccessibilityRange(self, [parameter rangeValue], [pdfView scaleFactor]);
        return [attributedString RTFFromRange:NSMakeRange(0, [attributedString length]) documentAttributes:[NSDictionary dictionaryWithObjectsAndKeys:NSRTFTextDocumentType, NSDocumentTypeDocumentAttribute, nil]];
    }
    return nil;
}

static id fallback_accessibilityAttributedStringForRangeAttributeForParameter(id self, SEL _cmd, id parameter) {
    PDFView *pdfView = SKGetPDFView(self);
    if (pdfView) {
        return [attributedStringForAccessibilityRange(self, [parameter rangeValue], [pdfView scaleFactor]) accessibilityAttributedString];
    }
    return nil;
}

static id fallback_accessibilityStyleRangeForIndexAttributeForParameter(id self, SEL _cmd, id parameter) {
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

#pragma mark SKSwizzlePDFDisplayViewMethods

void SKSwizzlePDFDisplayViewMethods() {
    Class PDFDisplayViewClass = floor(NSAppKitVersionNumber) <= NSAppKitVersionNumber10_11 ? NSClassFromString(@"PDFDisplayView") : NSClassFromString(@"PDFDocumentView");
    if (PDFDisplayViewClass == Nil)
        return;
    
    original_updateTrackingAreas = (void (*)(id, SEL))SKReplaceInstanceMethodImplementation(PDFDisplayViewClass, @selector(updateTrackingAreas), (IMP)replacement_updateTrackingAreas);
    
    if (floor(NSAppKitVersionNumber) > NSAppKitVersionNumber10_9 ||
        [[NSUserDefaults standardUserDefaults] boolForKey:SKDisableExtendedPDFViewAccessibilityKey] ||
        [PDFDisplayViewClass instancesRespondToSelector:@selector(accessibilityRangeForSelection:)] == NO ||
        [PDFDisplayViewClass instancesRespondToSelector:@selector(selectionForAccessibilityRange:)] == NO)
        return;
    
    original_accessibilityAttributeValue = (id (*)(id, SEL, id))SKReplaceInstanceMethodImplementation(PDFDisplayViewClass, @selector(accessibilityAttributeValue:), (IMP)replacement_accessibilityAttributeValue);
    original_accessibilityParameterizedAttributeNames = (id (*)(id, SEL))SKReplaceInstanceMethodImplementation(PDFDisplayViewClass, @selector(accessibilityParameterizedAttributeNames), (IMP)replacement_accessibilityParameterizedAttributeNames);
    
    SKAddInstanceMethodImplementation(PDFDisplayViewClass, @selector(accessibilityRangeForPositionAttributeForParameter:), (IMP)fallback_accessibilityRangeForPositionAttributeForParameter, "@@:@");
    SKAddInstanceMethodImplementation(PDFDisplayViewClass, @selector(accessibilityRTFForRangeAttributeForParameter:), (IMP)fallback_accessibilityRTFForRangeAttributeForParameter, "@@:@");
    SKAddInstanceMethodImplementation(PDFDisplayViewClass, @selector(accessibilityAttributedStringForRangeAttributeForParameter:), (IMP)fallback_accessibilityAttributedStringForRangeAttributeForParameter, "@@:@");
    SKAddInstanceMethodImplementation(PDFDisplayViewClass, @selector(accessibilityStyleRangeForIndexAttributeForParameter:), (IMP)fallback_accessibilityStyleRangeForIndexAttributeForParameter, "@@:@");
}
