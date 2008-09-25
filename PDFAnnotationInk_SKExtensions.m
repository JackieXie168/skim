//
//  PDFAnnotationInk_SKExtensions.m
//  Skim
//
//  Created by Christiaan Hofman on 9/14/08.
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

#import "PDFAnnotationInk_SKExtensions.h"
#import <SkimNotes/SkimNotes.h>
#import "PDFAnnotation_SKExtensions.h"
#import "SKStringConstants.h"
#import "SKFDFParser.h"
#import "NSUserDefaults_SKExtensions.h"
#import "NSGeometry_SKExtensions.h"
#import "NSData_SKExtensions.h"
#import "NSBezierPath_BDSKExtensions.h"

NSString *SKPDFAnnotationScriptingPointListsKey = @"scriptingPointLists";

@implementation PDFAnnotationInk (SKExtensions)

- (id)initSkimNoteWithBounds:(NSRect)bounds { 	 
    if (self = [super initSkimNoteWithBounds:bounds]) { 	 
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
    NSEnumerator *pathEnum;
    NSBezierPath *path;
    
    pathEnum = [paths objectEnumerator];
    while (path = [pathEnum nextObject])
        bounds = NSUnionRect(bounds, [path nonEmptyBounds]);
    bounds = NSInsetRect(NSIntegralRect(bounds), -8.0, -8.0);
    [transform translateXBy:-NSMinX(bounds) yBy:-NSMinY(bounds)];
    
    if (self = [self initSkimNoteWithBounds:bounds]) {
        pathEnum = [paths objectEnumerator];
        while (path = [pathEnum nextObject]) {
            [path transformUsingAffineTransform:transform];
            [self addBezierPath:path];
        }
    }
    return self;
}

- (NSString *)fdfString {
    NSMutableString *fdfString = [[[super fdfString] mutableCopy] autorelease];
    NSEnumerator *pathEnum = [[self paths] objectEnumerator];
    NSBezierPath *path;
    NSPoint point;
    int i, iMax;
    NSRect bounds = [self bounds];
    [fdfString appendFDFName:SKFDFAnnotationInkListKey];
    [fdfString appendString:@"["];
    while (path = [pathEnum nextObject]) {
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
    float delta = fmaxf(4.0, 0.5 * [self lineWidth]);
    
    if ([super hitTest:point]) {
        NSEnumerator *pathEnum = [[self paths] objectEnumerator];
        NSBezierPath *path;
        NSPoint prevPoint, nextPoint = NSZeroPoint;
        int i, iMax;
        while (path = [pathEnum nextObject]) {
            iMax = [path elementCount];
            for (i = 0; i < iMax; i++) {
                prevPoint = nextPoint;
                nextPoint = [path associatedPointForElementAtIndex:i];
                if (i > 0 && SKPointNearLineFromPointToPoint(relPoint, prevPoint, nextPoint, delta))
                    return YES;
            }
        }
    }
    return NO;
}

- (NSRect)displayRectForBounds:(NSRect)bounds {
    float lineWidth = [self lineWidth];
    NSEnumerator *pathEnum = [[self paths] objectEnumerator];
    NSBezierPath *path;
    NSRect rect = NSZeroRect;
    while (path = [pathEnum nextObject])
        rect = NSUnionRect(rect, NSInsetRect([path nonEmptyBounds], -lineWidth, -lineWidth));
    rect.origin = SKAddPoints(rect.origin, bounds.origin);
    return NSUnionRect([super displayRectForBounds:bounds], NSIntegralRect(rect));
}

- (NSArray *)pointLists {
    NSMutableArray *pointLists = [NSMutableArray array];
    NSMutableArray *pointValues;
    NSEnumerator *pathEnum = [[self paths] objectEnumerator];
    NSBezierPath *path;
    NSPoint point;
    int i, iMax;
    while (path = [pathEnum nextObject]) {
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

- (FourCharCode)scriptingNoteType {
    return SKScriptingInkNote;
}

- (NSArray *)scriptingPointLists {
    NSPoint origin = [self bounds].origin;
    NSMutableArray *pointLists = [NSMutableArray array];
    NSMutableArray *pointValues;
    NSEnumerator *pathEnum = [[self paths] objectEnumerator];
    NSBezierPath *path;
    NSPoint point;
    int i, iMax;
    while (path = [pathEnum nextObject]) {
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

- (void)setScriptingPointLists:(NSArray *)lists {
    NSScriptCommand *currentCommand = [NSScriptCommand currentCommand];
    if ([currentCommand isKindOfClass:[NSCreateCommand class]] == NO)
        [currentCommand setScriptErrorNumber:NSReceiversCantHandleCommandScriptError]; 
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
    return [NSNumber numberWithUnsignedInt:[[self accessibilityValueAttribute] length]];
}

- (id)accessibilityVisibleCharacterRangeAttribute {
    return [NSValue valueWithRange:NSMakeRange(0, [[self accessibilityValueAttribute] length])];
}

@end
