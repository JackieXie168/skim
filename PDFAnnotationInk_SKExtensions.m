//
//  PDFAnnotationInk_SKExtensions.m
//  Skim
//
//  Created by Christiaan Hofman on 9/14/08.
/*
 This software is Copyright (c) 2008-2011
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

#import "PDFAnnotationInk_SKExtensions.h"
#import <SkimNotes/SkimNotes.h>
#import "PDFAnnotation_SKExtensions.h"
#import "SKStringConstants.h"
#import "SKFDFParser.h"
#import "NSUserDefaults_SKExtensions.h"
#import "NSGeometry_SKExtensions.h"
#import "NSData_SKExtensions.h"
#import "NSBezierPath_SKExtensions.h"
#import "SKRuntime.h"

NSString *SKPDFAnnotationScriptingPointListsKey = @"scriptingPointLists";

@implementation PDFAnnotationInk (SKExtensions)

static void (*original_drawWithBox)(id, SEL, PDFDisplayBox) = NULL;

- (void)replacement_drawWithBox:(PDFDisplayBox)box {
    if ([PDFAnnotation currentActiveAnnotation] == self) {
        [NSGraphicsContext saveGraphicsState];
        NSShadow *shade = [[[NSShadow alloc] init] autorelease];
        [shade setShadowBlurRadius:2.0];
        [shade setShadowOffset:NSMakeSize(0.0, -2.0)];
        [shade set];
        original_drawWithBox(self, _cmd, box);
        [NSGraphicsContext restoreGraphicsState];
    } else {
        original_drawWithBox(self, _cmd, box);
    }
}

+ (void)load {
    original_drawWithBox = (void (*)(id, SEL, PDFDisplayBox))SKReplaceInstanceMethodImplementationFromSelector(self, @selector(drawWithBox:), @selector(replacement_drawWithBox:));
}

- (id)initSkimNoteWithBounds:(NSRect)bounds { 	 
    self = [super initSkimNoteWithBounds:bounds];
    if (self) { 	 
        // PDFAnnotationInk over-retains the initial PDFBorder ivar on 10.6.x
        if ((NSInteger)floor(NSAppKitVersionNumber) == NSAppKitVersionNumber10_6)
            [[self border] release];
        [self setColor:[[NSUserDefaults standardUserDefaults] colorForKey:SKInkNoteColorKey]]; 	 
        PDFBorder *border = [[PDFBorder allocWithZone:[self zone]] init]; 	 
        [border setLineWidth:[[NSUserDefaults standardUserDefaults] floatForKey:SKInkNoteLineWidthKey]]; 	 
        [border setDashPattern:[[NSUserDefaults standardUserDefaults] arrayForKey:SKInkNoteDashPatternKey]]; 	 
        [border setStyle:[[NSUserDefaults standardUserDefaults] floatForKey:SKInkNoteLineStyleKey]]; 	 
        [self setBorder:[border lineWidth] > 0.0 ? border : nil]; 	 
        [border release]; 	 
    } 	 
    return self; 	 
} 	 

- (id)initSkimNoteWithPaths:(NSArray *)paths {
    NSRect bounds = NSZeroRect;
    NSAffineTransform *transform = [NSAffineTransform transform];
    NSBezierPath *path;
    
    for (path in paths)
        bounds = NSUnionRect(bounds, [path nonEmptyBounds]);
    bounds = NSInsetRect(NSIntegralRect(bounds), -8.0, -8.0);
    [transform translateXBy:-NSMinX(bounds) yBy:-NSMinY(bounds)];
    
    self = [self initSkimNoteWithBounds:bounds];
    if (self) {
        for (path in paths) {
            [path transformUsingAffineTransform:transform];
            [self addBezierPath:path];
        }
    }
    return self;
}

- (NSArray *)pagePaths {
    NSMutableArray *paths = [[[NSMutableArray alloc] initWithArray:[self paths] copyItems:YES] autorelease];
    NSRect bounds = [self bounds];
    NSAffineTransform *transform = [NSAffineTransform transform];
    [transform translateXBy:NSMinX(bounds) yBy:NSMinY(bounds)];
    [paths makeObjectsPerformSelector:@selector(transformUsingAffineTransform:) withObject:transform];
    return paths;
}

- (NSString *)fdfString {
    NSMutableString *fdfString = [[[super fdfString] mutableCopy] autorelease];
    NSPoint point;
    NSInteger i, iMax;
    NSRect bounds = [self bounds];
    [fdfString appendFDFName:SKFDFAnnotationInkListKey];
    [fdfString appendString:@"["];
    for (NSBezierPath *path in [self paths]) {
        iMax = [path elementCount];
        [fdfString appendString:@"["];
        for (i = 0; i < iMax; i++) {
            point = [path associatedPointForElementAtIndex:i];
            [fdfString appendFormat:@"%f %f ", point.x + NSMinX(bounds), point.y + NSMinY(bounds)];
        }
        [fdfString appendString:@"]"];
    }
    [fdfString appendString:@"]"];
    return fdfString;
}

- (BOOL)isResizable { return NO; }

- (BOOL)isMovable { return [self isSkimNote]; }

- (BOOL)isConvertibleAnnotation { return YES; }

- (BOOL)hitTest:(NSPoint)point {
    NSPoint relPoint = SKSubstractPoints(point, [self bounds].origin);
    CGFloat delta = fmax(4.0, 0.5 * [self lineWidth]);
    
    if ([super hitTest:point]) {
        NSPoint prevPoint, nextPoint = NSZeroPoint;
        NSInteger i, iMax;
        for (NSBezierPath *path in [self paths]) {
            iMax = [path elementCount];
            for (i = 0; i < iMax; i++) {
                prevPoint = nextPoint;
                nextPoint = [path associatedPointForElementAtIndex:i];
                if (i > 0 && SKPointNearLineFromPointToPoint(relPoint, prevPoint, nextPoint, delta, delta))
                    return YES;
            }
        }
    }
    return NO;
}

- (NSRect)displayRectForBounds:(NSRect)bounds {
    CGFloat lineWidth = [self lineWidth];
    NSRect rect = NSZeroRect;
    for (NSBezierPath *path in [self paths])
        rect = NSUnionRect(rect, NSInsetRect([path nonEmptyBounds], -lineWidth, -lineWidth));
    rect.origin = SKAddPoints(rect.origin, bounds.origin);
    return NSUnionRect([super displayRectForBounds:bounds], NSIntegralRect(rect));
}

- (NSArray *)pointLists {
    NSMutableArray *pointLists = [NSMutableArray array];
    NSMutableArray *pointValues;
    NSPoint point;
    NSInteger i, iMax;
    for (NSBezierPath *path in [self paths]) {
        iMax = [path elementCount];
        pointValues = [[NSMutableArray alloc] initWithCapacity:iMax];
        for (i = 0; i < iMax; i++) {
            point = [path associatedPointForElementAtIndex:i];
            [pointValues addObject:[NSValue valueWithPoint:point]];
        }
        [pointLists addObject:pointValues];
        [pointValues release];
    }
    return pointLists;
}

#pragma mark Scripting support

+ (NSSet *)customScriptingKeys {
    static NSSet *customInkScriptingKeys = nil;
    if (customInkScriptingKeys == nil) {
        NSMutableSet *customKeys = [[super customScriptingKeys] mutableCopy];
        [customKeys addObject:SKPDFAnnotationScriptingPointListsKey];
        customInkScriptingKeys = [customKeys copy];
        [customKeys release];
    }
    return customInkScriptingKeys;
}

- (NSArray *)scriptingPointLists {
    NSPoint origin = [self bounds].origin;
    NSMutableArray *pointLists = [NSMutableArray array];
    NSMutableArray *pointValues;
    NSPoint point;
    NSInteger i, iMax;
    for (NSBezierPath *path in [self paths]) {
        iMax = [path elementCount];
        pointValues = [[NSMutableArray alloc] initWithCapacity:iMax];
        for (i = 0; i < iMax; i++) {
            point = [path associatedPointForElementAtIndex:i];
            [pointValues addObject:[NSData dataWithPointAsQDPoint:SKAddPoints(point, origin)]];
        }
        [pointLists addObject:pointValues];
        [pointValues release];
    }
    return pointLists;
}

#pragma mark Accessibility

- (NSArray *)accessibilityAttributeNames {
    static NSArray *attributes = nil;
    if (attributes == nil) {
        attributes = [[[super accessibilityAttributeNames] arrayByAddingObjectsFromArray:[NSArray arrayWithObjects:
            NSAccessibilitySelectedTextAttribute,
            NSAccessibilitySelectedTextRangeAttribute,
            NSAccessibilityNumberOfCharactersAttribute,
            NSAccessibilityVisibleCharacterRangeAttribute,
            nil]] retain];
    }
    return attributes;
}

- (id)accessibilityRoleAttribute {
    return NSAccessibilityStaticTextRole;
}

- (id)accessibilitySelectedTextAttribute {
    return @"";
}

- (id)accessibilitySelectedTextRangeAttribute {
    return [NSValue valueWithRange:NSMakeRange(0, 0)];
}

- (id)accessibilityNumberOfCharactersAttribute {
    return [NSNumber numberWithUnsignedInteger:[[self accessibilityValueAttribute] length]];
}

- (id)accessibilityVisibleCharacterRangeAttribute {
    return [NSValue valueWithRange:NSMakeRange(0, [[self accessibilityValueAttribute] length])];
}

@end
