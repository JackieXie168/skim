//
//  PDFPage_SKExtensions.m
//  Skim
//
//  Created by Christiaan Hofman on 2/16/07.
/*
 This software is Copyright (c) 2007
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

#import "PDFPage_SKExtensions.h"
#import "SKPDFAnnotationNote.h"
#import "SKDocument.h"
#import "SKPDFView.h"


@interface PDFSelection (PDFSelectionPrivateDeclarations)
- (int)numberOfRangesOnPage:(PDFPage *)page;
- (NSRange)rangeAtIndex:(int)index onPage:(PDFPage *)page;
@end

@implementation PDFPage (SKExtensions) 

- (NSImage *)image {
    NSRect bounds = [self boundsForBox:kPDFDisplayBoxCropBox];
    NSImage *image = [[NSImage alloc] initWithSize:bounds.size];
    
    [image lockFocus];
    [NSGraphicsContext saveGraphicsState];
    [[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationHigh];
    if ([self rotation]) {
        NSAffineTransform *transform = [NSAffineTransform transform];
        [transform rotateByDegrees:[self rotation]];
        switch ([self rotation]) {
            case 90:
                [transform translateXBy:0.0 yBy:-NSWidth(bounds)];
                break;
            case 180:
                [transform translateXBy:-NSWidth(bounds) yBy:-NSHeight(bounds)];
                break;
            case 270:
                [transform translateXBy:-NSHeight(bounds) yBy:0.0];
                break;
        }
        [transform concat];
    }
    [[NSColor whiteColor] set];
    bounds.origin = NSZeroPoint;
    NSRectFill(bounds);
    [self drawWithBox:kPDFDisplayBoxCropBox]; 
    [NSGraphicsContext restoreGraphicsState];
    [image unlockFocus];
    
    return [image autorelease];
}

- (NSImage *)thumbnailWithSize:(float)size shadowBlurRadius:(float)shadowBlurRadius shadowOffset:(NSSize)shadowOffset {
    NSRect bounds = [self boundsForBox:kPDFDisplayBoxCropBox];
    BOOL isScaled = size > 0.0;
    BOOL hasShadow = shadowBlurRadius > 0.0;
    float scaleX, scaleY;
    NSSize thumbnailSize;
    NSImage *image;
    
    if ([self rotation] % 180 == 90)
        bounds = NSMakeRect(NSMinX(bounds), NSMinY(bounds), NSHeight(bounds), NSWidth(bounds));
    
    if (isScaled) {
        if (NSHeight(bounds) > NSWidth(bounds))
            thumbnailSize = NSMakeSize(roundf((size - 2.0 * shadowBlurRadius) * NSWidth(bounds) / NSHeight(bounds) + 2.0 * shadowBlurRadius), size);
        else
            thumbnailSize = NSMakeSize(size, roundf((size - 2.0 * shadowBlurRadius) * NSHeight(bounds) / NSWidth(bounds) + 2.0 * shadowBlurRadius));
        scaleX = (thumbnailSize.width - 2.0 * shadowBlurRadius) / NSWidth(bounds);
        scaleY = (thumbnailSize.height - 2.0 * shadowBlurRadius) / NSHeight(bounds);
    } else {
        thumbnailSize = NSMakeSize(NSWidth(bounds) + 2.0 * shadowBlurRadius, NSHeight(bounds) + 2.0 * shadowBlurRadius);
        scaleX = scaleY = 1.0;
    }
    
    image = [[NSImage alloc] initWithSize:thumbnailSize];
    [image lockFocus];
    [NSGraphicsContext saveGraphicsState];
    [[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationHigh];
    if (isScaled || hasShadow) {
        NSAffineTransform *transform = [NSAffineTransform transform];
        if (isScaled)
            [transform scaleXBy:scaleX yBy:scaleY];
        [transform translateXBy:(shadowBlurRadius - shadowOffset.width) / scaleX yBy:(shadowBlurRadius - shadowOffset.height) / scaleY];
        [transform concat];
    }
    [NSGraphicsContext saveGraphicsState];
    [[NSColor whiteColor] set];
    if (hasShadow) {
        NSShadow *shadow = [[NSShadow alloc] init];
        [shadow setShadowColor:[NSColor colorWithDeviceWhite:0.0 alpha:0.5]];
        [shadow setShadowBlurRadius:shadowBlurRadius];
        [shadow setShadowOffset:shadowOffset];
        [shadow set];
        [shadow release];
    }
    bounds.origin = NSZeroPoint;
    NSRectFill(bounds);
    [NSGraphicsContext restoreGraphicsState];
    [self drawWithBox:kPDFDisplayBoxCropBox]; 
    [NSGraphicsContext restoreGraphicsState];
    [image unlockFocus];
    
    return [image autorelease];
}

- (NSArray *)lineBounds {
    if ([PDFSelection instancesRespondToSelector:@selector(numberOfRangesOnPage:)] == NO || [PDFSelection instancesRespondToSelector:@selector(rangeAtIndex:onPage:)] == NO)
        return [NSArray array];
    
    static NSCharacterSet *nonWhitespaceAndNewlineCharacterSet = nil;
    if (nonWhitespaceAndNewlineCharacterSet == nil)
        nonWhitespaceAndNewlineCharacterSet = [[[NSCharacterSet whitespaceAndNewlineCharacterSet] invertedSet] copy];
    
    NSMutableArray *lines = [NSMutableArray array];
    PDFSelection *sel = [self selectionForRect:[self boundsForBox:kPDFDisplayBoxCropBox]];
    unsigned i, iMax = [sel numberOfRangesOnPage:self];
    NSMutableIndexSet *indexes = [NSMutableIndexSet indexSet];
    NSString *string = [self string];
    NSRange stringRange = NSMakeRange(0, [string length]);
    
    for (i = 0; i < iMax; i++) {
        NSRange range = [sel rangeAtIndex:i onPage:self];
        unsigned j;
        
        for (j = range.location; j < NSMaxRange(range); j++) {
            if ([indexes containsIndex:j])
                continue;
            
            NSRect r = [self characterBoundsAtIndex:j];
            PDFSelection *s = [self selectionForLineAtPoint:NSMakePoint(NSMidX(r), NSMidY(r))];
            unsigned k, kMax = [s numberOfRangesOnPage:self];
            BOOL notEmpty = NO;
            
            for (k = 0; k < kMax; k++) {
                NSRange selRange = [s rangeAtIndex:k onPage:self];
                [indexes addIndexesInRange:selRange];
                // due to a bug in PDFKit, the range of the selection can sometimes lie partly outside the range of the string
                if ([string rangeOfCharacterFromSet:nonWhitespaceAndNewlineCharacterSet options:0 range:NSIntersectionRange(selRange, stringRange)].length)
                    notEmpty = YES;
            }
            if (notEmpty)
                [lines addObject:[NSValue valueWithRect:[s boundsForPage:self]]];
        }
    }
    
    [lines sortUsingSelector:@selector(boundsCompare:)];
    
    iMax = [lines count];
    NSMutableArray *fullLines = [NSMutableArray array];
    NSRect r1 = NSZeroRect;
    
    for (i = 0; i < iMax; i++) {
        NSRect r2 = [[lines objectAtIndex:i] rectValue];
        if (NSEqualRects(r1, NSZeroRect)) {
            r1 = r2;
        } else if ((NSMinY(r1) < NSMidY(r2) && NSMidY(r1) > NSMinY(r2)) || (NSMidY(r1) < NSMaxY(r2) && NSMaxY(r1) > NSMidY(r2))) {
            r1 = NSUnionRect(r1, r2);
        } else if (NSEqualRects(r1, NSZeroRect) == NO) {
            [fullLines addObject:[NSValue valueWithRect:r1]];
            r1 = r2;
        }
    }
    if (NSEqualRects(r1, NSZeroRect) == NO)
        [fullLines addObject:[NSValue valueWithRect:r1]];
    
    return fullLines;
}

#pragma mark Scripting support

- (NSScriptObjectSpecifier *)objectSpecifier {
    SKDocument *document = [self containingDocument];
	unsigned index = [[self document] indexForPage:self];
    
    if (document && index != NSNotFound) {
        NSScriptObjectSpecifier *containerRef = [document objectSpecifier];
        return [[[NSIndexSpecifier allocWithZone:[self zone]] initWithContainerClassDescription:[containerRef keyClassDescription] containerSpecifier:containerRef key:@"pages" index:index] autorelease];
    } else {
        return nil;
    }
}

- (SKDocument *)containingDocument {
    NSEnumerator *docEnum = [[[NSDocumentController sharedDocumentController] documents] objectEnumerator];
    SKDocument *document;
    
    while (document = [docEnum nextObject]) {
        if ([[self document] isEqual:[document pdfDocument]])
            break;
    }
    
    return document;
}

- (NSData *)boundsAsQDRect {
    Rect qdBounds = RectFromNSRect([self boundsForBox:kPDFDisplayBoxCropBox]);
    return [NSData dataWithBytes:&qdBounds length:sizeof(Rect)];
}

- (id)richText {
    NSAttributedString *attrString = [self attributedString];
    return attrString ? [[[NSTextStorage alloc] initWithAttributedString:attrString] autorelease] : [NSNull null];
}

- (NSArray *)notes {
    NSEnumerator *annEnum = [[self annotations] objectEnumerator];
    PDFAnnotation *annotation;
    NSMutableArray *notes = [NSMutableArray array];
    
    while (annotation = [annEnum nextObject]) {
        if ([annotation isNoteAnnotation])
            [notes addObject:annotation];
    }
    return notes;
}

- (void)insertInNotes:(id)newNote {
    SKDocument *document = [self containingDocument];
    
    [[document pdfView] addAnnotation:newNote toPage:self];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:SKPDFViewDidAddAnnotationNotification object:[document pdfView] 
        userInfo:[NSDictionary dictionaryWithObjectsAndKeys:newNote, @"annotation", self, @"page", nil]];
}

- (void)removeFromNotesAtIndex:(unsigned int)index {
    PDFAnnotation *note = [[self notes] objectAtIndex:index];
    
    [[[self containingDocument] pdfView] removeAnnotation:note];
}


- (id)handleGoToScriptCommand:(NSScriptCommand *)command {
    [[[self containingDocument] pdfView] goToPage:self];
    return nil;
}

@end

#pragma mark -

@implementation NSValue (SKExtensions)

- (NSComparisonResult)boundsCompare:(NSValue *)aValue {
    NSRect rect1 = [self rectValue];
    NSRect rect2 = [aValue rectValue];
    float y1 = NSMaxY(rect1);
    float y2 = NSMaxY(rect2);
    
    if (y1 > y2)
        return NSOrderedAscending;
    else if (y1 < y2)
        return NSOrderedDescending;
    
    float x1 = NSMinX(rect1);
    float x2 = NSMinX(rect2);
    
    if (x1 < x2)
        return NSOrderedAscending;
    else if (x1 > x2)
        return NSOrderedDescending;
    else
        return NSOrderedSame;
}

@end
