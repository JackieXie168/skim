//
//  PDFDocumentView_SKExtensions.m
//  Skim
//
//  Created by Christiaan Hofman on 4/22/08.
/*
 This software is Copyright (c) 2008-2020
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

#import "PDFDocumentView_SKExtensions.h"
#import <Quartz/Quartz.h>
#import "SKPDFView.h"
#import "NSAttributedString_SKExtensions.h"
#import "SKRuntime.h"
#import "NSView_SKExtensions.h"
#import <objc/objc-runtime.h>

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

static NSString *pdfViewIvarKeyPath = @"private.pdfView";

static id fallback_ivar_getPDFView(id self, SEL _cmd) {
    id pdfView = nil;
    @try { pdfView = [self valueForKeyPath:pdfViewIvarKeyPath]; }
    @catch (id exception) {}
    return pdfView;
}

static id fallback_getPDFView(id self, SEL _cmd) {
    id pdfView = [[self enclosingScrollView] superview];
    return [pdfView isKindOfClass:[PDFView class]] ? pdfView : nil;
}

static id (*original_menuForEvent)(id, SEL, id) = NULL;

static void (*original_updateTrackingAreas)(id, SEL) = NULL;

#pragma mark PDFPageView fix

// On Sierra and later menuForEvent: is forwarded to the PDFView of the PDFPage rather than the actual PDFView,
static NSMenu *replacement_menuForEvent(id self, SEL _cmd, NSEvent *event) {
    id view = [[self enclosingScrollView] superview];
    while ((view = [view superview]))
        if ([view isKindOfClass:[PDFView class]])
            break;
    return [view menuForEvent:event];
}

#pragma mark Skim support

static void replacement_updateTrackingAreas(id self, SEL _cmd) {
	original_updateTrackingAreas(self, _cmd);
    id pdfView = [self getPDFView];
    if ([pdfView respondsToSelector:@selector(resetPDFToolTipRects)])
        [pdfView resetPDFToolTipRects];
}

#pragma mark SKSwizzlePDFDocumentViewMethods

void SKSwizzlePDFDocumentViewMethods() {
    Class PDFPageViewClass = NSClassFromString(@"PDFPageView");
    if (PDFPageViewClass)
        original_menuForEvent = (id (*)(id, SEL, id))SKReplaceInstanceMethodImplementation(PDFPageViewClass, @selector(menuForEvent:), (IMP)replacement_menuForEvent);
    
    Class PDFDocumentViewClass = RUNNING_BEFORE(10_12) ? NSClassFromString(@"PDFDisplayView") : NSClassFromString(@"PDFDocumentView");
    if (PDFDocumentViewClass == Nil)
        return;

    if ([PDFDocumentViewClass instancesRespondToSelector:@selector(getPDFView)] == NO) {
        if ([PDFDocumentViewClass instancesRespondToSelector:@selector(pdfView)]) {
            SKAddInstanceMethodImplementationFromSelector(PDFDocumentViewClass, @selector(getPDFView), @selector(pdfView));
        } else if (class_getInstanceVariable(PDFDocumentViewClass, "_pdfView")) {
            pdfViewIvarKeyPath = @"pdfView";
            SKAddInstanceMethodImplementation(PDFDocumentViewClass, @selector(getPDFView), (IMP)fallback_ivar_getPDFView, "@@:");
        } else if (class_getInstanceVariable(PDFDocumentViewClass, "_private")) {
            SKAddInstanceMethodImplementation(PDFDocumentViewClass, @selector(getPDFView), (IMP)fallback_ivar_getPDFView, "@@:");
        } else {
            SKAddInstanceMethodImplementation(PDFDocumentViewClass, @selector(getPDFView), (IMP)fallback_getPDFView, "@@:");
        }
    }
    
    original_updateTrackingAreas = (void (*)(id, SEL))SKReplaceInstanceMethodImplementation(PDFDocumentViewClass, @selector(updateTrackingAreas), (IMP)replacement_updateTrackingAreas);
    
}
