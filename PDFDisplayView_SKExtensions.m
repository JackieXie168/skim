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


@interface SKAccessibilityPDFDisplayViewElement : NSObject {
    id parent;
}
- (id)initWithParent:(id)aParent;
@end

#pragma mark -

@interface SKAccessibilityPDFAnnotationElement : NSObject {
    PDFAnnotation *annotation;
    SKPDFView *pdfView;
    id parent;
}
- (id)initWithAnnotation:(PDFAnnotation *)anAnnotation pdfView:(SKPDFView *)aPdfView parent:(id)aParent;
@end

#pragma mark -

static IMP originalAccessibilityAttributeNames = NULL;
static IMP originalAccessibilityAttributeValue = NULL;
static IMP originalAccessibilityHitTest = NULL;
static IMP originalAccessibilityFocusedUIElement = NULL;

@implementation PDFDisplayView (SKExtensions)

static IMP originalPasswordEntered = NULL;

- (void)replacementPasswordEntered:(id)sender {
    SKPDFDocument *document = [[[self window] windowController] document];
    originalPasswordEntered(self, _cmd, sender);
    if ([document respondsToSelector:@selector(savePasswordInKeychain:)])
        [document savePasswordInKeychain:[sender stringValue]];
}

#pragma mark Accessibility

- (SKPDFView *)skpdfView {
    id pdfView = nil;
    @try { pdfView = [self valueForKey:@"pdfView"]; }
    @catch (id exception) {}
    return [pdfView isKindOfClass:[SKPDFView class]] ? pdfView : nil;
}

- (NSArray *)replacementAccessibilityAttributeNames {
    if ([self skpdfView])
        return [originalAccessibilityAttributeNames(self, _cmd) arrayByAddingObjectsFromArray:[NSArray arrayWithObjects:NSAccessibilityChildrenAttribute, NSAccessibilityVisibleChildrenAttribute, nil]];
    else
        return originalAccessibilityAttributeNames(self, _cmd);
}

- (id)replacementAccessibilityAttributeValue:(NSString *)attribute {
    SKPDFView *pdfView = [self skpdfView];
    if (pdfView == nil) {
        return originalAccessibilityAttributeValue(self, _cmd, attribute);
    } else if ([attribute isEqualToString:NSAccessibilityRoleAttribute]) {
        return NSAccessibilityGroupRole;
    } else if ([attribute isEqualToString:NSAccessibilityRoleDescriptionAttribute]) {
        return NSAccessibilityRoleDescription(NSAccessibilityGroupRole, nil);
    } else if ([attribute isEqualToString:NSAccessibilityChildrenAttribute]) {
        NSMutableArray *children = [NSMutableArray array];
        [children addObjectsFromArray:originalAccessibilityAttributeValue(self, _cmd, attribute)];
        if (pdfView) {
            [children addObject:[[[SKAccessibilityPDFDisplayViewElement alloc] initWithParent:self] autorelease]];
            PDFDocument *pdfDoc = [pdfView document];
            unsigned int i, iMax = [pdfDoc pageCount];
            for (i = 0; i < iMax; i++) {
                PDFPage *page = [pdfDoc pageAtIndex:i];
                NSEnumerator *annotationEnum = [[page annotations] objectEnumerator];
                PDFAnnotation *annotation;
                while (annotation = [annotationEnum nextObject]) {
                    if ([[annotation type] isEqualToString:SKLinkString] || [annotation isNoteAnnotation])
                        [children addObject:[[[SKAccessibilityPDFAnnotationElement alloc] initWithAnnotation:annotation pdfView:pdfView parent:self] autorelease]];
                }
            }
        }
        return NSAccessibilityUnignoredChildren(children);
    } else if ([attribute isEqualToString:NSAccessibilityVisibleChildrenAttribute]) {
        NSMutableArray *children = [NSMutableArray array];
        [children addObjectsFromArray:originalAccessibilityAttributeValue(self, _cmd, attribute)];
        SKPDFView *pdfView = [self skpdfView];
        if (pdfView) {
            [children addObject:[[[SKAccessibilityPDFDisplayViewElement alloc] initWithParent:self] autorelease]];
            PDFDocument *pdfDoc = [pdfView document];
            NSRect visibleRect = [pdfView visibleContentRect];
            NSRange range = [pdfView visiblePageIndexRange];
            unsigned int i;
            for (i = range.location; i < NSMaxRange(range); i++) {
                PDFPage *page = [pdfDoc pageAtIndex:i];
                NSEnumerator *annotationEnum = [[page annotations] objectEnumerator];
                PDFAnnotation *annotation;
                while (annotation = [annotationEnum nextObject]) {
                    if ([[annotation type] isEqualToString:SKLinkString] || [annotation isNoteAnnotation] && 
                        NSIntersectsRect([pdfView convertRect:[annotation bounds] fromPage:[annotation page]], visibleRect))
                        [children addObject:[[[SKAccessibilityPDFAnnotationElement alloc] initWithAnnotation:annotation pdfView:pdfView parent:self] autorelease]];
                }
            }
        }
        return NSAccessibilityUnignoredChildren(children);
    } else if ([attribute isEqualToString:NSAccessibilityFocusedAttribute]) {
        NSNumber *focused = originalAccessibilityAttributeValue(self, _cmd, attribute);
        SKPDFView *pdfView = [self skpdfView];
        if (pdfView)
            return [NSNumber numberWithBool:[pdfView activeAnnotation] == nil && [focused boolValue]];
        else
            return focused;
    } else {
        return originalAccessibilityAttributeValue(self, _cmd, attribute);
    }
}

- (id)replacementAccessibilityHitTest:(NSPoint)point {
    SKPDFView *pdfView = [self skpdfView];
    if (pdfView) {
        NSPoint localPoint = [pdfView convertPoint:[[pdfView window] convertScreenToBase:point] fromView:nil];
        PDFPage *page = [pdfView pageForPoint:localPoint nearest:NO];
        if (page) {
            PDFAnnotation *annotation = [page annotationAtPoint:[pdfView convertPoint:localPoint toPage:page]];
            if ([[annotation type] isEqualToString:SKLinkString] || [annotation isNoteAnnotation]) {
                return [[[[SKAccessibilityPDFAnnotationElement alloc] initWithAnnotation:annotation pdfView:pdfView parent:self] autorelease] accessibilityHitTest:point];
            }
        }
        return [[[[SKAccessibilityPDFDisplayViewElement alloc] initWithParent:self] autorelease] accessibilityHitTest:point];
    } else {
        return originalAccessibilityHitTest(self, _cmd, point);
    }
}

- (id)replacementAccessibilityFocusedUIElement {
    SKPDFView *pdfView = [self skpdfView];
    if (pdfView) {
        PDFAnnotation *annotation = [pdfView activeAnnotation];
        if (annotation) {
            return NSAccessibilityUnignoredAncestor([[[SKAccessibilityPDFAnnotationElement alloc] initWithAnnotation:annotation pdfView:pdfView parent:self] autorelease]);
        } else {
            return NSAccessibilityUnignoredAncestor([[[SKAccessibilityPDFDisplayViewElement alloc] initWithParent:self] autorelease]);
        }
    } else {
        return originalAccessibilityFocusedUIElement(self, _cmd);
    }
}

- (BOOL)accessibilityIsIgnored {
    return NO;
}

+ (void)load {
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

- (id)initWithParent:(id)aParent {
    if (self = [super init]) {
        parent = aParent;
    }
    return self;
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
    return originalAccessibilityAttributeNames(parent, _cmd);
}

- (id)accessibilityAttributeValue:(NSString *)attribute {
    if ([attribute isEqualToString:NSAccessibilityParentAttribute]) {
        return NSAccessibilityUnignoredAncestor(parent);
    } else if ([attribute isEqualToString:NSAccessibilityWindowAttribute]) {
        // We're in the same window as our parent.
        return [NSAccessibilityUnignoredAncestor(parent) accessibilityAttributeValue:NSAccessibilityWindowAttribute];
    } else if ([attribute isEqualToString:NSAccessibilityTopLevelUIElementAttribute]) {
        // We're in the same top level element as our parent.
        return [NSAccessibilityUnignoredAncestor(parent) accessibilityAttributeValue:NSAccessibilityTopLevelUIElementAttribute];
    } else {
        return originalAccessibilityAttributeValue(parent, _cmd, attribute);
    }
}

- (BOOL)accessibilityIsAttributeSettable:(NSString *)attribute {
    return [parent respondsToSelector:_cmd] && [parent accessibilityIsAttributeSettable:attribute]; 
}

- (void)accessibilitySetValue:(id)value forAttribute:(NSString *)attribute {
    if ([parent respondsToSelector:_cmd])
        [parent accessibilitySetValue:value forAttribute:attribute];
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

#pragma mark -

@implementation SKAccessibilityPDFAnnotationElement

- (id)initWithAnnotation:(PDFAnnotation *)anAnnotation pdfView:(SKPDFView *)aPdfView parent:(id)aParent {
    if (self = [super init]) {
        annotation = anAnnotation;
        pdfView = aPdfView;
        parent = aParent;
    }
    return self;
}

- (BOOL)isEqual:(id)object {
    if ([object isKindOfClass:[SKAccessibilityPDFAnnotationElement class]]) {
        SKAccessibilityPDFAnnotationElement *other = (SKAccessibilityPDFAnnotationElement *)object;
        return annotation == other->annotation && pdfView == other->pdfView;
    } else {
        return NO;
    }
}

- (unsigned int)hash {
    return [annotation hash] + [pdfView hash];
}

- (NSArray *)accessibilityAttributeNames {
    return [annotation accessibilityAttributeNames];
}

- (id)accessibilityAttributeValue:(NSString *)attribute {
    if ([attribute isEqualToString:NSAccessibilityRoleAttribute]) {
        return [annotation accessibilityRoleAttribute];
    } else if ([attribute isEqualToString:NSAccessibilityRoleDescriptionAttribute]) {
        return [annotation accessibilityRoleDescriptionAttribute];
    } else if ([attribute isEqualToString:NSAccessibilityValueAttribute]) {
        return [annotation accessibilityValueAttribute];
    } else if ([attribute isEqualToString:NSAccessibilityTitleAttribute]) {
        return [annotation accessibilityTitleAttribute];
    } else if ([attribute isEqualToString:NSAccessibilitySelectedTextAttribute]) {
        return [annotation accessibilitySelectedTextAttribute];
    } else if ([attribute isEqualToString:NSAccessibilitySelectedTextRangeAttribute]) {
        return [annotation accessibilitySelectedTextRangeAttribute];
    } else if ([attribute isEqualToString:NSAccessibilityNumberOfCharactersAttribute]) {
        return [annotation accessibilityNumberOfCharactersAttribute];
    } else if ([attribute isEqualToString:NSAccessibilityVisibleCharacterRangeAttribute]) {
        return [annotation accessibilityVisibleCharacterRangeAttribute];
    } else if ([attribute isEqualToString:NSAccessibilityParentAttribute]) {
        return NSAccessibilityUnignoredAncestor(parent);
    } else if ([attribute isEqualToString:NSAccessibilityWindowAttribute]) {
        // We're in the same window as our parent.
        return [NSAccessibilityUnignoredAncestor(parent) accessibilityAttributeValue:NSAccessibilityWindowAttribute];
    } else if ([attribute isEqualToString:NSAccessibilityTopLevelUIElementAttribute]) {
        // We're in the same top level element as our parent.
        return [NSAccessibilityUnignoredAncestor(parent) accessibilityAttributeValue:NSAccessibilityTopLevelUIElementAttribute];
    } else if ([attribute isEqualToString:NSAccessibilityFocusedAttribute]) {
        return [NSNumber numberWithBool:[pdfView activeAnnotation] == annotation];
    } else if ([attribute isEqualToString:NSAccessibilityEnabledAttribute]) {
        return [NSNumber numberWithBool:NO];
    } else if ([attribute isEqualToString:NSAccessibilityPositionAttribute]) {
        NSRect rect = [pdfView convertRect:[annotation bounds] fromPage:[annotation page]];
        return [NSValue valueWithPoint:[[pdfView window] convertBaseToScreen:[pdfView convertPoint:rect.origin toView:nil]]];
    } else if ([attribute isEqualToString:NSAccessibilitySizeAttribute]) {
        NSRect rect = [pdfView convertRect:[annotation bounds] fromPage:[annotation page]];
        return [NSValue valueWithSize:[pdfView convertSize:rect.size toView:nil]];
    } else {
        return nil;
    }
}

- (BOOL)accessibilityIsAttributeSettable:(NSString *)attribute {
    return [attribute isEqualToString:NSAccessibilityFocusedAttribute]; 
}

- (void)accessibilitySetValue:(id)value forAttribute:(NSString *)attribute {
    if ([attribute isEqualToString:NSAccessibilityFocusedAttribute]) {
        if ([value boolValue])
            [pdfView setActiveAnnotation:annotation];
        else if ([pdfView activeAnnotation] == annotation)
            [pdfView setActiveAnnotation:nil];
    }
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
    if ([[annotation type] isEqualToString:SKLinkString] || [annotation isEditable])
        return [NSArray arrayWithObject:NSAccessibilityPressAction];
    else
        return [NSArray array];
}

- (NSString *)accessibilityActionDescription:(NSString *)anAction {
    return NSAccessibilityActionDescription(anAction);
}

- (void)accessibilityPerformAction:(NSString *)anAction {
    if ([anAction isEqualToString:NSAccessibilityPressAction]) {
        if ([pdfView activeAnnotation] != annotation)
            [pdfView setActiveAnnotation:annotation];
        [pdfView editActiveAnnotation:self];
    }
}

@end
