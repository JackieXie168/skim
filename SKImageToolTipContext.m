//
//  SKImageToolTipContext.m
//  Skim
//
//  Created by Christiaan Hofman on 2/6/10.
/*
 This software is Copyright (c) 2010-2020
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

#import "SKImageToolTipContext.h"
#import "PDFPage_SKExtensions.h"
#import <SkimNotes/SkimNotes.h>
#import "PDFAnnotation_SKExtensions.h"
#import "NSParagraphStyle_SKExtensions.h"
#import "NSGeometry_SKExtensions.h"
#import "NSGraphics_SKExtensions.h"
#import "PDFSelection_SKExtensions.h"
#import "NSCharacterSet_SKExtensions.h"
#import "NSColor_SKExtensions.h"
#import "NSAttributedString_SKExtensions.h"

#define TEXT_MARGIN_X 2.0
#define TEXT_MARGIN_Y 2.0

#define SKToolTipWidthKey  @"SKToolTipWidth"
#define SKToolTipHeightKey @"SKToolTipHeight"


static NSAttributedString *toolTipAttributedString(NSString *string) {
    static NSDictionary *attributes = nil;
    if (attributes == nil)
        attributes = [[NSDictionary alloc] initWithObjectsAndKeys:[NSFont toolTipsFontOfSize:11.0], NSFontAttributeName, [NSParagraphStyle defaultClippingParagraphStyle], NSParagraphStyleAttributeName, nil];
    return [[[NSAttributedString alloc] initWithString:string attributes:attributes] autorelease];
}


@implementation NSAttributedString (SKImageToolTipContext)

- (NSImage *)toolTipImage {
    NSAttributedString *attrString = [self attributedStringByAddingControlTextColorAttribute];
    CGFloat width = [[NSUserDefaults standardUserDefaults] doubleForKey:SKToolTipWidthKey] - 2.0 * TEXT_MARGIN_X;
    CGFloat height = [[NSUserDefaults standardUserDefaults] doubleForKey:SKToolTipHeightKey] - 2.0 * TEXT_MARGIN_Y;
    NSRect textRect = [self boundingRectWithSize:NSMakeSize(width, height) options:NSStringDrawingUsesLineFragmentOrigin];
    NSSize size;
    
    textRect.origin = NSMakePoint(TEXT_MARGIN_X, TEXT_MARGIN_Y);
    textRect.size.height = fmin(NSHeight(textRect), height);
    size = NSInsetRect(NSIntegralRect(textRect), -TEXT_MARGIN_X, -TEXT_MARGIN_Y).size;
    
    NSImage *image = [[[NSImage alloc] initWithSize:size] autorelease];
    [image lockFocus];
    SKRunWithAppearance(NSApp, ^{
        [attrString drawWithRect:textRect options:NSStringDrawingUsesLineFragmentOrigin];
    });
    [image unlockFocus];
    
    [[[image representations] firstObject] setOpaque:NO];
    return image;
}

@end


@interface PDFDestination (SKImageToolTipContextExtension)
- (NSImage *)toolTipImageWithOffset:(NSPoint)offset selections:(NSArray *)selections;
@end

@implementation PDFDestination (SKImageToolTipContext)

- (NSImage *)toolTipImageWithOffset:(NSPoint)offset selections:(NSArray *)selections {
    static NSDictionary *labelAttributes = nil;
    static NSColor *labelColor = nil;
    if (labelAttributes == nil)
        labelAttributes = [[NSDictionary alloc] initWithObjectsAndKeys:[NSFont boldSystemFontOfSize:11.0], NSFontAttributeName, [NSColor whiteColor], NSForegroundColorAttributeName, [NSParagraphStyle defaultClippingParagraphStyle], NSParagraphStyleAttributeName, nil];
    if (labelColor == nil)
        labelColor = [[NSColor colorWithCalibratedWhite:0.5 alpha:0.8] retain];
    
    PDFPage *page = [self page];
    NSImage *pageImage = [page thumbnailWithSize:0.0 forBox:kPDFDisplayBoxCropBox shadowBlurRadius:0.0 highlights:selections];
    NSRect pageImageRect = {NSZeroPoint, [pageImage size]};
    NSRect bounds = [page boundsForBox:kPDFDisplayBoxCropBox];
    NSRect sourceRect = NSZeroRect;
    PDFSelection *pageSelection = [page selectionForRect:bounds];
    NSAffineTransform *transform = [page affineTransformForBox:kPDFDisplayBoxCropBox];
    
    sourceRect.size.width = [[NSUserDefaults standardUserDefaults] doubleForKey:SKToolTipWidthKey];
    sourceRect.size.height = [[NSUserDefaults standardUserDefaults] doubleForKey:SKToolTipHeightKey];
    sourceRect.origin = SKAddPoints([transform transformPoint:[self point]], offset);
    sourceRect.origin.y -= NSHeight(sourceRect);
    
    
    if ([pageSelection hasCharacters]) {
        NSRect selBounds = [pageSelection boundsForPage:page];
        selBounds = SKRectFromPoints([transform transformPoint:SKBottomLeftPoint(selBounds)], [transform transformPoint:SKTopRightPoint(selBounds)]);
        CGFloat top = ceil(fmax(NSMaxY(selBounds), NSMinY(selBounds) + NSHeight(sourceRect)));
        CGFloat left = floor(fmin(NSMinX(selBounds), NSMaxX(selBounds) - NSWidth(sourceRect)));
        if (top < NSMaxY(sourceRect))
            sourceRect.origin.y = top - NSHeight(sourceRect);
        if (left > NSMinX(sourceRect))
            sourceRect.origin.x = left;
    }
    
    sourceRect = SKConstrainRect(sourceRect, pageImageRect);
    
    NSRect targetRect = sourceRect;
    targetRect.origin = NSZeroPoint;
    
    NSAttributedString *labelString = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:NSLocalizedString(@"Page %@", @"Tool tip label format"), [page displayLabel]] attributes:labelAttributes];
    NSRect labelRect = [labelString boundingRectWithSize:NSZeroSize options:NSStringDrawingUsesLineFragmentOrigin];
    
    labelRect.size.width = floor(NSWidth(labelRect));
    labelRect.size.height = 2.0 * floor(0.5 * NSHeight(labelRect)); // make sure the cap radius is integral
    labelRect.origin.x = NSWidth(sourceRect) - NSWidth(labelRect) - 0.5 * NSHeight(labelRect) - TEXT_MARGIN_X;
    labelRect.origin.y = TEXT_MARGIN_Y;
    labelRect = NSIntegralRect(labelRect);
    
    NSImage *image = [[[NSImage alloc] initWithSize:sourceRect.size] autorelease];
    
    [image lockFocus];
    
    [pageImage drawInRect:targetRect fromRect:sourceRect operation:NSCompositeCopy fraction:1.0];
    
    CGFloat radius = 0.5 * NSHeight(labelRect);
    NSBezierPath *path = [NSBezierPath bezierPath];
    
    [path moveToPoint:SKTopLeftPoint(labelRect)];
    [path appendBezierPathWithArcWithCenter:NSMakePoint(NSMinX(labelRect), NSMidY(labelRect)) radius:radius startAngle:90.0 endAngle:270.0];
    [path appendBezierPathWithArcWithCenter:NSMakePoint(NSMaxX(labelRect), NSMidY(labelRect)) radius:radius startAngle:-90.0 endAngle:90.0];
    [path closePath];
    
    [labelColor setFill];
    [path fill];
    
    [labelString drawWithRect:labelRect options:NSStringDrawingUsesLineFragmentOrigin];
    
    [image unlockFocus];
    
    [labelString release];
    
    return image;
}

- (NSImage *)toolTipImage {
    NSImage *image = [self toolTipImageWithOffset:NSMakePoint(-50.0, 20.0) selections:nil];
    [[[image representations] firstObject] setOpaque:YES];
    return image;
}

@end


@implementation PDFSelection (SKImageToolTipContext)

- (NSImage *)toolTipImage {
    PDFSelection *sel = [self copy];
    [sel setColor:[NSColor searchHighlightColor]];
    NSArray *selections = [NSArray arrayWithObject:sel];
    [sel release];
    return [[self destination] toolTipImageWithOffset:NSMakePoint(-50.0, 20.0) selections:selections];
}

@end


@implementation SKGroupedSearchResult (SKImageToolTipContext)

- (NSImage *)toolTipImage {
    NSArray *selections = [[[NSArray alloc] initWithArray:[self matches] copyItems:YES] autorelease];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wpartial-availability"
    [selections setValue:[NSColor findHighlightColor] forKey:@"color"];
#pragma clang diagnostic pop
    return [[[selections firstObject] destination] toolTipImageWithOffset:NSMakePoint(-50.0, 20.0) selections:selections];
}

@end


@implementation PDFAnnotation (SKImageToolTipContext)

- (NSImage *)toolTipImage {
    
    if ([self isLink]) {
        NSImage *image = [[self linkDestination] toolTipImageWithOffset:NSZeroPoint selections:nil];
        if (image == nil) {
            NSURL *url = [self linkURL];
            if (url) {
                NSAttributedString *attrString = toolTipAttributedString([url absoluteString]);
                if ([attrString length])
                    image = [attrString toolTipImage];
            }
        }
        if (image) {
            [[[image representations] firstObject] setOpaque:YES];
            return image;
        }
    }
    
    NSAttributedString *attrString = [self text];
    NSString *string = [attrString string];
    NSUInteger i, l = [string length];
    
    if (l == 0 || [string rangeOfCharacterFromSet:[NSCharacterSet nonWhitespaceAndNewlineCharacterSet]].location == NSNotFound) {
        string = [self string];
        l = [string length];
        attrString = l > 0 ? toolTipAttributedString(string) : nil;
    }
    
    if (l > 0) {
        NSRange r = NSMakeRange(0, l);
        while (NSNotFound != (i = NSMaxRange([string rangeOfCharacterFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet] options:NSAnchoredSearch range:r])))
            r = NSMakeRange(i, l - i);
        while (NSNotFound != (i = [string rangeOfCharacterFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet] options:NSBackwardsSearch | NSAnchoredSearch range:r].location))
            r.length = i - r.location;
        if (r.length == 0)
            attrString = nil;
        else if (NSMaxRange(r) < l)
            attrString = [attrString attributedSubstringFromRange:r];
    }
    
    return [attrString length] ? [attrString toolTipImage] : nil;
}

@end


@implementation PDFPage (SKImageToolTipContext)

- (NSImage *)toolTipImage {
    NSImage *image = [self thumbnailWithSize:256.0 forBox:kPDFDisplayBoxCropBox shadowBlurRadius:0.0 highlights:nil];
    [[[image representations] firstObject] setOpaque:YES];
    return image;
}

@end
