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
    CGFloat r = 0.1 * fmin(NSWidth(bounds), NSHeight(bounds));
    CGContextMoveToPoint(context, NSMinX(bounds) + 0.3 * NSWidth(bounds), NSMinY(bounds) + 0.3 * NSHeight(bounds) - 0.5);
    CGContextAddArcToPoint(context, NSMinX(bounds), NSMinY(bounds) + 0.3 * NSHeight(bounds) - 0.5, NSMinX(bounds), NSMaxY(bounds), r);
    CGContextAddArcToPoint(context, NSMinX(bounds), NSMaxY(bounds), NSMaxX(bounds), NSMaxY(bounds), r);
    CGContextAddArcToPoint(context, NSMaxX(bounds), NSMaxY(bounds), NSMaxX(bounds), NSMinY(bounds), r);
    CGContextAddArcToPoint(context, NSMaxX(bounds), NSMinY(bounds) + 0.3 * NSHeight(bounds) - 0.5, NSMinX(bounds), NSMinY(bounds) + 0.35 * NSHeight(bounds), r);
    CGContextAddLineToPoint(context, NSMinX(bounds) + 0.5 * NSWidth(bounds), NSMinY(bounds) + 0.3 * NSHeight(bounds) - 0.5);
    CGContextAddLineToPoint(context, NSMinX(bounds) + 0.25 * NSWidth(bounds), NSMinY(bounds));
    CGContextClosePath(context);
    CGContextDrawPath(context, kCGPathFillStroke);
    bounds = NSInsetRect(bounds, 0.5, 0.5);
    CGPoint points3[6] = {{NSMinX(bounds) + 0.1 * NSWidth(bounds), NSMinY(bounds) + 0.85 * NSHeight(bounds)},
        {NSMinX(bounds) + 0.9 * NSWidth(bounds), NSMinY(bounds) + 0.85 * NSHeight(bounds)},
        {NSMinX(bounds) + 0.1 * NSWidth(bounds), NSMinY(bounds) + 0.65 * NSHeight(bounds)},
        {NSMinX(bounds) + 0.9 * NSWidth(bounds), NSMinY(bounds) + 0.65 * NSHeight(bounds)},
        {NSMinX(bounds) + 0.1 * NSWidth(bounds), NSMinY(bounds) + 0.45 * NSHeight(bounds)},
        {NSMinX(bounds) + 0.7 * NSWidth(bounds), NSMinY(bounds) + 0.45 * NSHeight(bounds)}};
    CGContextSetLineWidth(context, 0.1 * NSHeight(bounds));
    CGContextStrokeLineSegments(context, points3, 6);
}

static inline void drawIconKey(CGContextRef context, NSRect bounds) {
    bounds = NSInsetRect(bounds, 0.5, 0.5);
    CGFloat r = 0.1 * fmin(NSWidth(bounds), NSHeight(bounds));
    CGPoint points[9] = {{NSMinX(bounds) + 0.55 * NSWidth(bounds), NSMinY(bounds) + 0.65 * NSHeight(bounds)},
        {NSMaxX(bounds), NSMinY(bounds) + 0.15 * NSHeight(bounds)},
        {NSMaxX(bounds), NSMinY(bounds)},
        {NSMinX(bounds) + 0.7 * NSWidth(bounds), NSMinY(bounds)},
        {NSMinX(bounds) + 0.7 * NSWidth(bounds), NSMinY(bounds) + 0.15 * NSHeight(bounds)},
        {NSMinX(bounds) + 0.55 * NSWidth(bounds), NSMinY(bounds) + 0.15 * NSHeight(bounds)},
        {NSMinX(bounds) + 0.55 * NSWidth(bounds), NSMinY(bounds) + 0.3 * NSHeight(bounds)},
        {NSMinX(bounds) + 0.4 * NSWidth(bounds), NSMinY(bounds) + 0.3 * NSHeight(bounds)},
        {NSMinX(bounds) + 0.4 * NSWidth(bounds), NSMinY(bounds) + 0.45 * NSHeight(bounds)}};
    CGContextAddLines(context, points, 9);
    CGContextAddArcToPoint(context, NSMinX(bounds), NSMinY(bounds) + 0.45 * NSHeight(bounds), NSMinX(bounds), NSMaxY(bounds), r);
    CGContextAddArcToPoint(context, NSMinX(bounds), NSMaxY(bounds), NSMaxX(bounds), NSMaxY(bounds), 2.0 * r);
    CGContextAddArcToPoint(context, NSMinX(bounds) + 0.55 * NSWidth(bounds), NSMaxY(bounds), NSMinX(bounds) + 0.55 * NSWidth(bounds), NSMinY(bounds), r);
    CGContextClosePath(context);
    CGContextAddEllipseInRect(context, CGRectMake(NSMinX(bounds) + 1.0 * r, NSMaxY(bounds) - 3.0 * r, 2.0 * r, 2.0 * r));
    CGContextDrawPath(context, kCGPathEOFillStroke);
}

static inline void drawIconNote(CGContextRef context, NSRect bounds) {
    bounds = NSInsetRect(bounds, 0.08 * NSWidth(bounds) + 0.5, 0.5);
    CGPoint points1[5] = {{NSMinX(bounds), NSMinY(bounds)},
        {NSMinX(bounds), NSMaxY(bounds)},
        {NSMaxX(bounds), NSMaxY(bounds)},
        {NSMaxX(bounds), NSMinY(bounds) + 0.25 * NSHeight(bounds)},
        {NSMaxX(bounds) - 0.25 * NSWidth(bounds), NSMinY(bounds)}};
    CGPoint points2[3] = {{NSMaxX(bounds), NSMinY(bounds) + 0.25 * NSHeight(bounds)},
        {NSMaxX(bounds) - 0.25 * NSWidth(bounds), NSMinY(bounds) + 0.25 * NSHeight(bounds)},
        {NSMaxX(bounds) - 0.25 * NSWidth(bounds), NSMinY(bounds)}};
    CGContextAddLines(context, points1, 5);
    CGContextClosePath(context);
    CGContextAddLines(context, points2, 3);
    CGContextDrawPath(context, kCGPathFillStroke);
    bounds = NSInsetRect(bounds, 0.5, 0.5);
    CGPoint points3[6] = {{NSMinX(bounds) + 0.1 * NSWidth(bounds), NSMinY(bounds) + 0.85 * NSHeight(bounds)},
        {NSMinX(bounds) + 0.9 * NSWidth(bounds), NSMinY(bounds) + 0.85 * NSHeight(bounds)},
        {NSMinX(bounds) + 0.1 * NSWidth(bounds), NSMinY(bounds) + 0.65 * NSHeight(bounds)},
        {NSMinX(bounds) + 0.9 * NSWidth(bounds), NSMinY(bounds) + 0.65 * NSHeight(bounds)},
        {NSMinX(bounds) + 0.1 * NSWidth(bounds), NSMinY(bounds) + 0.45 * NSHeight(bounds)},
        {NSMinX(bounds) + 0.7 * NSWidth(bounds), NSMinY(bounds) + 0.45 * NSHeight(bounds)}};
    CGContextSetLineWidth(context, 0.1 * NSHeight(bounds));
    CGContextStrokeLineSegments(context, points3, 6);
}

static inline void drawIconHelp(CGContextRef context, NSRect bounds) {
    if (NSWidth(bounds) < NSHeight(bounds))
        bounds = NSInsetRect(bounds, 0.0, 0.5 * (NSHeight(bounds) - NSWidth(bounds)));
    else if (NSHeight(bounds) < NSWidth(bounds))
        bounds = NSInsetRect(bounds, 0.5 * (NSWidth(bounds) - NSHeight(bounds)), 0.0);
    CGContextSetLineWidth(context, 0.1 * NSWidth(bounds));
    CGContextAddArc(context, NSMidX(bounds), NSMinY(bounds) + 0.65 * NSHeight(bounds), 0.15 * NSWidth(bounds), M_PI, -M_PI_4, 1);
    CGContextAddArc(context, NSMinX(bounds) + 0.65 * NSWidth(bounds), NSMinY(bounds) + (0.8 - 0.3 * M_SQRT2 ) * NSHeight(bounds), 0.15 * NSWidth(bounds), 3.0 * M_PI_4, M_PI, 0);
    CGContextAddLineToPoint(context, NSMidX(bounds), NSMinY(bounds) + 0.35 * NSHeight(bounds));
    CGContextReplacePathWithStrokedPath(context);
    CGContextSetLineWidth(context, 1.0);
    CGContextAddEllipseInRect(context, CGRectMake(NSMinX(bounds) + 0.425 * NSWidth(bounds), NSMinY(bounds) + 0.125 * NSHeight(bounds), 0.15 * NSWidth(bounds), 0.15 * NSHeight(bounds)));
    CGContextAddEllipseInRect(context, NSRectToCGRect(NSInsetRect(bounds, 0.5, 0.5)));
    CGContextClosePath(context);
    CGContextDrawPath(context, kCGPathEOFillStroke);
}

static inline void drawIconNewParagraph(CGContextRef context, NSRect bounds) {
    bounds = NSInsetRect(bounds, 0.08 * NSWidth(bounds), 0.5);
    CGFloat r = fmin(0.3 * NSWidth(bounds), 0.1 * NSHeight(bounds));
    CGContextSetLineJoin(context, kCGLineJoinRound);
    CGPoint points1[3] = {{NSMinX(bounds) + 0.1 * NSWidth(bounds), NSMinY(bounds) + 0.5 * NSHeight(bounds)},
        {NSMidX(bounds), NSMaxY(bounds)},
        {NSMaxX(bounds) - 0.1 * NSWidth(bounds), NSMinY(bounds) + 0.5 * NSHeight(bounds)}};
    CGContextAddLines(context, points1, 3);
    CGContextClosePath(context);
    CGContextDrawPath(context, kCGPathFillStroke);
    CGPoint points2[4] = {{NSMinX(bounds) + 0.1 * NSWidth(bounds), NSMinY(bounds) - 0.5},
        {NSMinX(bounds) + 0.1 * NSWidth(bounds), NSMinY(bounds) + 0.4 * NSHeight(bounds)},
        {NSMinX(bounds) + 0.4 * NSWidth(bounds), NSMinY(bounds)},
        {NSMinX(bounds) + 0.4 * NSWidth(bounds), NSMinY(bounds) + 0.4 * NSHeight(bounds) + 0.5}};
    CGContextAddLines(context, points2, 4);
    CGContextMoveToPoint(context, NSMinX(bounds) + 0.6 * NSWidth(bounds), NSMinY(bounds) - 0.5);
    CGContextAddLineToPoint(context, NSMinX(bounds) + 0.6 * NSWidth(bounds), NSMinY(bounds) + 0.4 * NSHeight(bounds));
    CGContextAddArcToPoint(context, NSMinX(bounds) + 0.9 * NSWidth(bounds), NSMinY(bounds) + 0.4 * NSHeight(bounds), NSMinX(bounds) + 0.9 * NSWidth(bounds), NSMinY(bounds) + 0.2 * NSHeight(bounds), r);
    CGContextAddArcToPoint(context, NSMinX(bounds) + 0.9 * NSWidth(bounds), NSMinY(bounds) + 0.2 * NSHeight(bounds), NSMinX(bounds) + 0.6 * NSWidth(bounds), NSMinY(bounds) + 0.2 * NSHeight(bounds), r);
    CGContextAddLineToPoint(context, NSMinX(bounds) + 0.6 * NSWidth(bounds), NSMinY(bounds) + 0.2 * NSHeight(bounds));
    CGContextStrokePath(context);
}

static inline void drawIconParagraph(CGContextRef context, NSRect bounds) {
    bounds = NSInsetRect(bounds, 0.08 * NSWidth(bounds), 0.5);
    CGFloat r = fmin(0.4 * NSWidth(bounds), 0.25 * NSHeight(bounds));
    CGPoint points[8] = {{NSMinX(bounds) + 0.9 * NSWidth(bounds), NSMaxY(bounds)},
        {NSMinX(bounds) + 0.9 * NSWidth(bounds), NSMinY(bounds)},
        {NSMinX(bounds) + 0.76 * NSWidth(bounds), NSMinY(bounds)},
        {NSMinX(bounds) + 0.76 * NSWidth(bounds), NSMinY(bounds) + 0.8 * NSHeight(bounds)},
        {NSMinX(bounds) + 0.63 * NSWidth(bounds), NSMinY(bounds) + 0.8 * NSHeight(bounds)},
        {NSMinX(bounds) + 0.63 * NSWidth(bounds), NSMinY(bounds)},
        {NSMinX(bounds) + 0.5 * NSWidth(bounds), NSMinY(bounds)},
        {NSMinX(bounds) + 0.5 * NSWidth(bounds), NSMinY(bounds) + 0.5 * NSHeight(bounds)}};
    CGContextAddLines(context, points, 8);
    CGContextAddArcToPoint(context, NSMinX(bounds) + 0.1 * NSWidth(bounds), NSMinY(bounds) + 0.5 * NSHeight(bounds), NSMinX(bounds) + 0.1 * NSWidth(bounds), NSMaxY(bounds), r);
    CGContextAddArcToPoint(context, NSMinX(bounds) + 0.1 * NSWidth(bounds), NSMaxY(bounds), NSMinX(bounds) + 0.9 * NSWidth(bounds), NSMaxY(bounds), r);
    CGContextClosePath(context);
    CGContextDrawPath(context, kCGPathFillStroke);
}

static inline void drawIconInsert(CGContextRef context, NSRect bounds) {
    CGContextSetLineJoin(context, kCGLineJoinRound);
    CGContextMoveToPoint(context, NSMinX(bounds) + 0.5, NSMinY(bounds) + 0.5);
    CGContextAddLineToPoint(context, NSMidX(bounds), NSMaxY(bounds) - 0.5);
    CGContextAddLineToPoint(context, NSMaxX(bounds) - 0.5, NSMinY(bounds) + 0.5);
    CGContextClosePath(context);
    CGContextDrawPath(context, kCGPathFillStroke);
}
