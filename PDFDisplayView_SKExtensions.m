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

static IMP originalAccessibilityAttributeNames = NULL;
static IMP originalAccessibilityAttributeValue = NULL;
static IMP originalAccessibilityHitTest = NULL;
static IMP originalAccessibilityFocusedUIElement = NULL;

@implementation PDFDisplayView (SKExtensions)

static IMP originalResetCursorRects = NULL;
static IMP originalPasswordEntered = NULL;

- (SKPDFView *)skpdfView {
    id pdfView = nil;
    @try { pdfView = [self valueForKey:@"pdfView"]; }
    @catch (id exception) {}
    return [pdfView isKindOfClass:[SKPDFView class]] ? pdfView : nil;
}

- (void)replacementResetCursorRects {
	originalResetCursorRects(self, _cmd);
    [[self skpdfView] resetHoverRects];
}

- (void)replacementPasswordEntered:(id)sender {
    SKPDFDocument *document = [[[self window] windowController] document];
    originalPasswordEntered(self, _cmd, sender);
    if ([document respondsToSelector:@selector(savePasswordInKeychain:)])
        [document savePasswordInKeychain:[sender stringValue]];
}

#pragma mark Accessibility

- (NSArray *)replacementAccessibilityAttributeNames {
    if ([self skpdfView]) {
        static NSArray *attributes = nil;
        if (attributes == nil)
            attributes = [[originalAccessibilityAttributeNames(self, _cmd) arrayByAddingObject:NSAccessibilityChildrenAttribute] retain];
        return attributes;
    } else {
        return originalAccessibilityAttributeNames(self, _cmd);
    }
}

- (id)replacementAccessibilityAttributeValue:(NSString *)attribute {
    SKPDFView *pdfView = [self skpdfView];
    if (pdfView) {
        if ([attribute isEqualToString:NSAccessibilityRoleAttribute])
            return NSAccessibilityGroupRole;
        else if ([attribute isEqualToString:NSAccessibilityRoleDescriptionAttribute])
            return NSAccessibilityRoleDescription(NSAccessibilityGroupRole, nil);
        else if ([attribute isEqualToString:NSAccessibilityChildrenAttribute])
            return NSAccessibilityUnignoredChildren([pdfView accessibilityChildren]);
    }
    return originalAccessibilityAttributeValue(self, _cmd, attribute);
}

- (id)replacementAccessibilityHitTest:(NSPoint)point {
    SKPDFView *pdfView = [self skpdfView];
    if (pdfView)
        return [pdfView accessibilityChildAtPoint:point];
    else
        return originalAccessibilityHitTest(self, _cmd, point);
}

- (id)replacementAccessibilityFocusedUIElement {
    SKPDFView *pdfView = [self skpdfView];
    if (pdfView)
        return [pdfView accessibilityFocusedChild];
    else
        return originalAccessibilityFocusedUIElement(self, _cmd);
}

- (NSRect)screenRectForRepresentedObject:(id)annotation {
    NSRect rect = NSZeroRect;
    SKPDFView *pdfView = [self skpdfView];
    if (pdfView) {
        rect = [pdfView convertRect:[pdfView convertRect:[annotation bounds] fromPage:[annotation page]] toView:nil];
        rect.origin = [[pdfView window] convertBaseToScreen:rect.origin];
    }
    return rect;
}

- (BOOL)isRepresentedObjectFocused:(id)annotation {
    return [[self skpdfView] activeAnnotation] == annotation;
}

- (void)setFocused:(BOOL)focused forRepresentedObject:(id)annotation {
    SKPDFView *pdfView = [self skpdfView];
    if (pdfView) {
        if (focused)
            [pdfView setActiveAnnotation:annotation];
        else if ([pdfView activeAnnotation] == annotation)
            [pdfView setActiveAnnotation:nil];
    }
}

- (void)pressRepresentedObject:(id)annotation {
    SKPDFView *pdfView = [self skpdfView];
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
    if ([self instancesRespondToSelector:@selector(accessibilityAttributeValue:)])
        originalAccessibilityAttributeValue = OBReplaceMethodImplementationWithSelector(self, @selector(accessibilityAttributeValue:), @selector(replacementAccessibilityAttributeValue:));
    if ([self instancesRespondToSelector:@selector(accessibilityHitTest:)])
        originalAccessibilityHitTest = OBReplaceMethodImplementationWithSelector(self, @selector(accessibilityHitTest:), @selector(replacementAccessibilityHitTest:));
    if ([self instancesRespondToSelector:@selector(accessibilityFocusedUIElement)])
        originalAccessibilityFocusedUIElement = OBReplaceMethodImplementationWithSelector(self, @selector(accessibilityFocusedUIElement), @selector(replacementAccessibilityFocusedUIElement));
}

@end

#pragma mark -

@implementation SKAccessibilityPDFDisplayViewElement

+ (id)elementWithParent:(id)aParent {
    return [[[self alloc] initWithParent:aParent] autorelease];
}

- (id)initWithParent:(id)aParent {
    if (self = [super init]) {
        parent = [aParent retain];
    }
    return self;
}

- (void)dealloc {
    [parent release];
    [super dealloc];
}

- (BOOL)isEqual:(id)object {
    if ([object isKindOfClass:[SKAccessibilityPDFDisplayViewElement class]]) {
        SKAccessibilityPDFDisplayViewElement *other = (SKAccessibilityPDFDisplayViewElement *)object;
        return parent == other->parent;
    } else {
        return NO;
    }
}

- (unsigned int)hash {
    return [parent hash];
}

- (NSArray *)accessibilityAttributeNames {
    if (originalAccessibilityAttributeNames != NULL)
        return originalAccessibilityAttributeNames(parent, _cmd);
    else if ([parent respondsToSelector:_cmd])
        return [parent accessibilityAttributeNames];
    else
        return [NSArray array];
}

- (id)accessibilityAttributeValue:(NSString *)attribute {
    if ([attribute isEqualToString:NSAccessibilityParentAttribute])
        return NSAccessibilityUnignoredAncestor(parent);
    else if (originalAccessibilityAttributeValue != NULL)
        return originalAccessibilityAttributeValue(parent, _cmd, attribute);
    else if ([parent respondsToSelector:_cmd])
        return [parent accessibilityAttributeValue:attribute];
    else
        return nil;
}

- (BOOL)accessibilityIsAttributeSettable:(NSString *)attribute {
    return [parent respondsToSelector:_cmd] && [parent accessibilityIsAttributeSettable:attribute]; 
}

- (void)accessibilitySetValue:(id)value forAttribute:(NSString *)attribute {
    if ([parent respondsToSelector:_cmd])
        [parent accessibilitySetValue:value forAttribute:attribute];
    if ([attribute isEqualToString:NSAccessibilityFocusedAttribute] && [value boolValue] && [[parent skpdfView] activeAnnotation])
        [[parent skpdfView] setActiveAnnotation:nil];
}

- (NSArray *)accessibilityParameterizedAttributeNames {
    return [parent respondsToSelector:_cmd] ? [parent accessibilityParameterizedAttributeNames] : [NSArray array];
}

- (id)accessibilityAttributeValue:(NSString *)attribute forParameter:(id)parameter {
    return [parent respondsToSelector:_cmd] ? [parent accessibilityAttributeValue:attribute forParameter:parameter] : nil;
}

- (BOOL)accessibilityIsIgnored {
    return NO;
}

- (id)accessibilityHitTest:(NSPoint)point {
    return NSAccessibilityUnignoredAncestor(self);
}

- (id)accessibilityFocusedUIElement {
    return NSAccessibilityUnignoredAncestor(self);
}

- (NSArray *)accessibilityActionNames {
    return [parent respondsToSelector:_cmd] ? [parent accessibilityActionNames] : [NSArray array];
}

- (NSString *)accessibilityActionDescription:(NSString *)anAction {
    return [parent respondsToSelector:_cmd] ? [parent accessibilityActionDescription:anAction] : NSAccessibilityActionDescription(anAction);
}

- (void)accessibilityPerformAction:(NSString *)anAction {
    if ([parent respondsToSelector:_cmd])
        [parent accessibilityPerformAction:anAction];
}

@end
