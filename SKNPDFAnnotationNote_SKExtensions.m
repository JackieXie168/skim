//
//  SKNPDFAnnotationNote_SKExtensions.m
//  Skim
//
//  Created by Christiaan Hofman on 2/6/07.
/*
 This software is Copyright (c) 2007-2017
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

#import "SKNPDFAnnotationNote_SKExtensions.h"
#import <SkimNotes/SkimNotes.h>
#import "PDFAnnotation_SKExtensions.h"
#import "SKStringConstants.h"
#import "SKFDFParser.h"
#import "NSUserDefaults_SKExtensions.h"
#import "NSGeometry_SKExtensions.h"
#import "NSString_SKExtensions.h"
#import "SKNoteText.h"
#import "PDFPage_SKExtensions.h"
#import "NSColor_SKExtensions.h"


NSString *SKPDFAnnotationRichTextKey = @"richText";

static inline void drawIconComment(CGContextRef context, NSRect bounds);
static inline void drawIconKey(CGContextRef context, NSRect bounds);
static inline void drawIconNote(CGContextRef context, NSRect bounds);
static inline void drawIconHelp(CGContextRef context, NSRect bounds);
static inline void drawIconNewParagraph(CGContextRef context, NSRect bounds);
static inline void drawIconParagraph(CGContextRef context, NSRect bounds);
static inline void drawIconInsert(CGContextRef context, NSRect bounds);

@interface PDFAnnotation (SKPrivateDeclarations)
- (void)drawWithBox:(PDFDisplayBox)box inContext:(CGContextRef)context;
@end

@implementation SKNPDFAnnotationNote (SKExtensions)

- (void)drawWithBox:(PDFDisplayBox)box inContext:(CGContextRef)context {
    if ((NSInteger)floor(NSAppKitVersionNumber) != NSAppKitVersionNumber10_12 || [self hasAppearanceStream]) {
        [super drawWithBox:box inContext:context];
    } else {
        NSRect bounds = [self bounds];
        CGContextSaveGState(context);
        [[self page] transformContext:context forBox:box];
        if (NSWidth(bounds) > 2.0 && NSHeight(bounds) > 2.0) {
            CGContextSetFillColorWithColor(context, [[self color] CGColor]);
            CGContextSetStrokeColorWithColor(context, CGColorGetConstantColor(kCGColorBlack));
            CGContextSetLineWidth(context, 1.0);
            CGContextSetLineCap(context, kCGLineCapButt);
            CGContextSetLineJoin(context, kCGLineJoinMiter);
            CGContextClipToRect(context, bounds);
            switch ([self iconType]) {
                case kPDFTextAnnotationIconComment:      drawIconComment(context, bounds);      break;
                case kPDFTextAnnotationIconKey:          drawIconKey(context, bounds);          break;
                case kPDFTextAnnotationIconNote:         drawIconNote(context, bounds);         break;
                case kPDFTextAnnotationIconHelp:         drawIconHelp(context, bounds);         break;
                case kPDFTextAnnotationIconNewParagraph: drawIconNewParagraph(context, bounds); break;
                case kPDFTextAnnotationIconParagraph:    drawIconParagraph(context, bounds);    break;
                case kPDFTextAnnotationIconInsert:       drawIconInsert(context, bounds);       break;
                default:                                 drawIconNote(context, bounds);         break;
            }
        } else {
            CGContextSetFillColorWithColor(context, CGColorGetConstantColor(kCGColorBlack));
            CGContextFillRect(context, bounds);
        }
        CGContextRestoreGState(context);
    }
}

+ (NSDictionary *)textToNoteSkimNoteProperties:(NSDictionary *)properties {
    if ([[properties objectForKey:SKNPDFAnnotationTypeKey] isEqualToString:SKNTextString]) {
        NSMutableDictionary *mutableProperties = [[properties mutableCopy] autorelease];
        NSRect bounds = NSRectFromString([properties objectForKey:SKNPDFAnnotationBoundsKey]);
        NSString *contents = [properties objectForKey:SKNPDFAnnotationContentsKey];
        [mutableProperties setObject:SKNNoteString forKey:SKNPDFAnnotationTypeKey];
        bounds.origin.y = NSMaxY(bounds) - SKNPDFAnnotationNoteSize.height;
        bounds.size = SKNPDFAnnotationNoteSize;
        [mutableProperties setObject:NSStringFromRect(bounds) forKey:SKNPDFAnnotationBoundsKey];
        if (contents) {
            NSRange r = [contents rangeOfString:@"  "];
            NSRange r1 = [contents rangeOfString:@"\n"];
            if (r1.location < r.location)
                r = r1;
            if (NSMaxRange(r) < [contents length]) {
                NSFont *font = [[NSUserDefaults standardUserDefaults] fontForNameKey:SKAnchoredNoteFontNameKey sizeKey:SKAnchoredNoteFontSizeKey];
                NSAttributedString *attrString = [[[NSAttributedString alloc] initWithString:[contents substringFromIndex:NSMaxRange(r)]
                                                    attributes:[NSDictionary dictionaryWithObjectsAndKeys:font, NSFontAttributeName, nil]] autorelease];
                [mutableProperties setObject:attrString forKey:SKNPDFAnnotationTextKey];
                [mutableProperties setObject:[contents substringToIndex:r.location] forKey:SKNPDFAnnotationContentsKey];
            }
        }
        return mutableProperties;
    }
    return properties;
}

- (id)initSkimNoteWithBounds:(NSRect)bounds {
    self = [super initSkimNoteWithBounds:bounds];
    if (self) {
        [self setColor:[[NSUserDefaults standardUserDefaults] colorForKey:SKAnchoredNoteColorKey]];
        [self setIconType:[[NSUserDefaults standardUserDefaults] integerForKey:SKAnchoredNoteIconTypeKey]];
        textStorage = [[NSTextStorage allocWithZone:[self zone]] init];
        [textStorage setDelegate:self];
        text = [[NSAttributedString alloc] init];
        texts = [[NSArray alloc] initWithObjects:[[[SKNoteText alloc] initWithNote:self] autorelease], nil];
    }
    return self;
}

- (BOOL)isNote { return YES; }

- (BOOL)isMovable { return [self isSkimNote]; }

- (BOOL)hasBorder { return NO; }

// override these Leopard methods to avoid showing the standard tool tips over our own
- (NSString *)toolTip { return @""; }

- (PDFAnnotationPopup *)popup { return nil; }

- (NSArray *)texts { return texts; }

- (NSString *)colorDefaultKey { return SKAnchoredNoteColorKey; }

- (NSSet *)keysForValuesToObserveForUndo {
    static NSSet *noteKeys = nil;
    if (noteKeys == nil) {
        NSMutableSet *mutableKeys = [[super keysForValuesToObserveForUndo] mutableCopy];
        [mutableKeys addObject:SKNPDFAnnotationTextKey];
        [mutableKeys addObject:SKNPDFAnnotationImageKey];
        noteKeys = [mutableKeys copy];
        [mutableKeys release];
    }
    return noteKeys;
}

#pragma mark Scripting support

+ (NSSet *)customScriptingKeys {
    static NSSet *customNoteScriptingKeys = nil;
    if (customNoteScriptingKeys == nil) {
        NSMutableSet *customKeys = [[super customScriptingKeys] mutableCopy];
        [customKeys addObject:SKPDFAnnotationRichTextKey];
        customNoteScriptingKeys = [customKeys copy];
        [customKeys release];
    }
    return customNoteScriptingKeys;
}

- (id)richText {
    return textStorage;
}

- (void)setRichText:(id)newText {
    if ([self isEditable] && newText != textStorage) {
        // We are willing to accept either a string or an attributed string.
        if ([newText isKindOfClass:[NSAttributedString class]])
            [textStorage replaceCharactersInRange:NSMakeRange(0, [textStorage length]) withAttributedString:newText];
        else
            [textStorage replaceCharactersInRange:NSMakeRange(0, [textStorage length]) withString:newText];
    }
}

- (id)coerceValueForRichText:(id)value {
    if ([value isKindOfClass:[NSScriptObjectSpecifier class]])
        value = [(NSScriptObjectSpecifier *)value objectsByEvaluatingSpecifier];
    // We want to just get Strings unchanged.  We will detect this and do the right thing in setRichText.  We do this because, this way, we will do more reasonable things about attributes when we are receiving plain text.
    if ([value isKindOfClass:[NSString class]])
        return value;
    else
        return [[NSScriptCoercionHandler sharedCoercionHandler] coerceValue:value toClass:[NSTextStorage class]];
}

@end

static inline void drawIconComment(CGContextRef context, NSRect bounds) {
    bounds = NSInsetRect(bounds, 0.5, 0.5);
    CGFloat x = NSMinX(bounds), y = NSMinY(bounds), w = NSWidth(bounds), h = NSHeight(bounds);
    CGFloat r = 0.1 * fmin(w, h);
    CGContextMoveToPoint(context, x + 0.3 * w, y + 0.3 * h - 0.5);
    CGContextAddArcToPoint(context, x, y + 0.3 * h - 0.5, x, y + h, r);
    CGContextAddArcToPoint(context, x, y + h, x + w, y + h, r);
    CGContextAddArcToPoint(context, x + w, y + h, x + w, y, r);
    CGContextAddArcToPoint(context, x + w, y + 0.3 * h - 0.5, x, y + 0.35 * h, r);
    CGContextAddLineToPoint(context, x + 0.5 * w, y + 0.3 * h - 0.5);
    CGContextAddLineToPoint(context, x + 0.25 * w, y);
    CGContextClosePath(context);
    CGContextDrawPath(context, kCGPathFillStroke);
    x += 0.5; y += 0.5; w -= 1.0; h -= 1.0;
    CGPoint points3[6] = {{x + 0.1 * w, y + 0.85 * h},
        {x + 0.9 * w, y + 0.85 * h},
        {x + 0.1 * w, y + 0.65 * h},
        {x + 0.9 * w, y + 0.65 * h},
        {x + 0.1 * w, y + 0.45 * h},
        {x + 0.7 * w, y + 0.45 * h}};
    CGContextSetLineWidth(context, 0.1 * h);
    CGContextStrokeLineSegments(context, points3, 6);
}

static inline void drawIconKey(CGContextRef context, NSRect bounds) {
    bounds = NSInsetRect(bounds, 0.5, 0.5);
    CGFloat x = NSMinX(bounds), y = NSMinY(bounds), w = NSWidth(bounds), h = NSHeight(bounds);
    CGFloat r = 0.1 * fmin(w, h);
    CGPoint points[9] = {{x + 0.55 * w, y + 0.65 * h},
        {x + w, y + 0.15 * h},
        {x + w, y},
        {x + 0.7 * w, y},
        {x + 0.7 * w, y + 0.15 * h},
        {x + 0.55 * w, y + 0.15 * h},
        {x + 0.55 * w, y + 0.3 * h},
        {x + 0.4 * w, y + 0.3 * h},
        {x + 0.4 * w, y + 0.45 * h}};
    CGContextAddLines(context, points, 9);
    CGContextAddArcToPoint(context, x, y + 0.45 * h, x, y + h, r);
    CGContextAddArcToPoint(context, x, y + h, x + w, y + h, 2.0 * r);
    CGContextAddArcToPoint(context, x + 0.55 * w, y + h, x + 0.55 * w, y, r);
    CGContextClosePath(context);
    CGContextAddEllipseInRect(context, CGRectMake(x + 1.0 * r, y + h - 3.0 * r, 2.0 * r, 2.0 * r));
    CGContextDrawPath(context, kCGPathEOFillStroke);
}

static inline void drawIconNote(CGContextRef context, NSRect bounds) {
    bounds = NSInsetRect(bounds, 0.08 * NSWidth(bounds) + 0.5, 0.5);
    CGFloat x = NSMinX(bounds), y = NSMinY(bounds), w = NSWidth(bounds), h = NSHeight(bounds);
    CGPoint points1[5] = {{x, y},
        {x, y + h},
        {x + w, y + h},
        {x + w, y + 0.25 * h},
        {x + 0.75 * w, y}};
    CGPoint points2[3] = {{x + 0.75 * w, y},
        {x + 0.75 * w, y + 0.25 * h},
        {x + w, y + 0.25 * h}};
    CGContextAddLines(context, points1, 5);
    CGContextClosePath(context);
    CGContextAddLines(context, points2, 3);
    CGContextDrawPath(context, kCGPathFillStroke);
    x += 0.5; y += 0.5; w -= 1.0; h -= 1.0;
    CGPoint points3[6] = {{x + 0.1 * w, y + 0.85 * h},
        {x + 0.9 * w, y + 0.85 * h},
        {x + 0.1 * w, y + 0.65 * h},
        {x + 0.9 * w, y + 0.65 * h},
        {x + 0.1 * w, y + 0.45 * h},
        {x + 0.7 * w, y + 0.45 * h}};
    CGContextSetLineWidth(context, 0.1 * h);
    CGContextStrokeLineSegments(context, points3, 6);
}

static inline void drawIconHelp(CGContextRef context, NSRect bounds) {
    if (NSWidth(bounds) < NSHeight(bounds))
        bounds = NSInsetRect(bounds, 0.0, 0.5 * (NSWidth(bounds) - NSHeight(bounds)));
    else if (NSHeight(bounds) < NSWidth(bounds))
        bounds = NSInsetRect(bounds, 0.5 * (NSHeight(bounds) - NSWidth(bounds)), 0.0);
    CGFloat x = NSMinX(bounds), y = NSMinY(bounds), w = NSWidth(bounds), h = NSHeight(bounds);
    CGContextSetLineWidth(context, 0.1 * w);
    CGContextAddArc(context, x + 0.5 * w, y + 0.65 * h, 0.15 * w, M_PI, -M_PI_4, 1);
    CGContextAddArc(context, x + 0.65 * w, y + (0.8 - 0.3 * M_SQRT2 ) * h, 0.15 * w, 3.0 * M_PI_4, M_PI, 0);
    CGContextAddLineToPoint(context, x + 0.5 * w, y + 0.35 * h);
    CGContextReplacePathWithStrokedPath(context);
    CGContextSetLineWidth(context, 1.0);
    CGContextAddEllipseInRect(context, CGRectMake(x + 0.425 * w, y + 0.125 * h, 0.15 * w, 0.15 * h));
    CGContextAddEllipseInRect(context, NSRectToCGRect(NSInsetRect(bounds, 0.5, 0.5)));
    CGContextClosePath(context);
    CGContextDrawPath(context, kCGPathEOFillStroke);
}

static inline void drawIconNewParagraph(CGContextRef context, NSRect bounds) {
    bounds = NSInsetRect(bounds, 0.08 * NSWidth(bounds), 0.5);
    CGFloat x = NSMinX(bounds), y = NSMinY(bounds), w = NSWidth(bounds), h = NSHeight(bounds);
    CGFloat r = fmin(0.3 * w, 0.1 * h);
    CGContextSetLineJoin(context, kCGLineJoinRound);
    CGPoint points1[3] = {{x + 0.1 * w, y + 0.5 * h},
        {x + 0.5 * w, y + h},
        {x + 0.9 * w, y + 0.5 * h}};
    CGContextAddLines(context, points1, 3);
    CGContextClosePath(context);
    CGContextDrawPath(context, kCGPathFillStroke);
    CGPoint points2[4] = {{x + 0.1 * w, y - 0.5},
        {x + 0.1 * w, y + 0.4 * h},
        {x + 0.4 * w, y},
        {x + 0.4 * w, y + 0.4 * h + 0.5}};
    CGContextAddLines(context, points2, 4);
    CGContextMoveToPoint(context, x + 0.6 * w, y - 0.5);
    CGContextAddLineToPoint(context, x + 0.6 * w, y + 0.4 * h);
    CGContextAddArcToPoint(context, x + 0.9 * w, y + 0.4 * h, x + 0.9 * w, y + 0.2 * h, r);
    CGContextAddArcToPoint(context, x + 0.9 * w, y + 0.2 * h, x + 0.6 * w, y + 0.2 * h, r);
    CGContextAddLineToPoint(context, x + 0.6 * w, y + 0.2 * h);
    CGContextStrokePath(context);
}

static inline void drawIconParagraph(CGContextRef context, NSRect bounds) {
    bounds = NSInsetRect(bounds, 0.08 * NSWidth(bounds), 0.5);
    CGFloat x = NSMinX(bounds), y = NSMinY(bounds), w = NSWidth(bounds), h = NSHeight(bounds);
    CGFloat r = fmin(0.4 * w, 0.25 * h);
    CGPoint points[8] = {{x + 0.9 * w, y + h},
        {x + 0.9 * w, y},
        {x + 0.76 * w, y},
        {x + 0.76 * w, y + 0.8 * h},
        {x + 0.63 * w, y + 0.8 * h},
        {x + 0.63 * w, y},
        {x + 0.5 * w, y},
        {x + 0.5 * w, y + 0.5 * h}};
    CGContextAddLines(context, points, 8);
    CGContextAddArcToPoint(context, x + 0.1 * w, y + 0.5 * h, x + 0.1 * w, y + h, r);
    CGContextAddArcToPoint(context, x + 0.1 * w, y + h, x + 0.9 * w, y + h, r);
    CGContextClosePath(context);
    CGContextDrawPath(context, kCGPathFillStroke);
}

static inline void drawIconInsert(CGContextRef context, NSRect bounds) {
    CGFloat x = NSMinX(bounds), y = NSMinY(bounds), w = NSWidth(bounds), h = NSHeight(bounds);
    CGContextSetLineJoin(context, kCGLineJoinRound);
    CGContextMoveToPoint(context, x + 0.5, y + 0.5);
    CGContextAddLineToPoint(context, x + 0.5 * w, y + h - 0.5);
    CGContextAddLineToPoint(context, x + w - 0.5, y + 0.5);
    CGContextClosePath(context);
    CGContextDrawPath(context, kCGPathFillStroke);
}
