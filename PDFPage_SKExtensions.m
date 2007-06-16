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
#import "PDFSelection_SKExtensions.h"
#import "OBUtilities.h"
#import "NSBitmapImageRep_SKExtensions.h"
#import "SKStringConstants.h"

NSString *SKPDFDocumentPageBoundsDidChangeNotification = @"SKPDFDocumentPageBoundsDidChangeNotification";

@interface PDFPage (SKReplacementMethods)
- (void)replacementDealloc;
@end

@implementation PDFPage (SKExtensions) 

#define FOREGROUND_BOX_MARGIN 10.0

// A subclass with ivars would be nicer in some respects, but that would require subclassing PDFDocument and returning instances of the subclass for each page.
static CFMutableDictionaryRef bboxCache = NULL;
static IMP originalDealloc = NULL;

+ (void)load {
    originalDealloc = OBReplaceMethodImplementationWithSelector(self, @selector(dealloc), @selector(replacementDealloc));
    bboxCache = CFDictionaryCreateMutable(NULL, 0, NULL, &kCFTypeDictionaryValueCallBacks);
}

- (void)replacementDealloc {
    CFDictionaryRemoveValue(bboxCache, self);
    originalDealloc(self, _cmd);
}

// mainly useful for drawing the box in a PDFView while debugging
- (NSRect)foregroundBox {
    
    NSValue *rectValue = nil;
    if (FALSE == CFDictionaryGetValueIfPresent(bboxCache, (void *)self, (const void **)&rectValue)) {
        float marginWidth = [[NSUserDefaults standardUserDefaults] floatForKey:@"SKAutoCropBoxMarginWidth"];
        float marginHeight = [[NSUserDefaults standardUserDefaults] floatForKey:@"SKAutoCropBoxMarginHeight"];
        NSBitmapImageRep *imageRep = [[NSBitmapImageRep alloc] initWithPDFPage:self forBox:kPDFDisplayBoxMediaBox];
        NSRect r = imageRep ? [imageRep foregroundRect] : NSZeroRect;
        NSRect b = [self boundsForBox:kPDFDisplayBoxMediaBox];
        if (imageRep == nil) {
            r = b;
        } else if (NSEqualRects(NSZeroRect, r)) {
            r = NSMakeRect(NSMidX(b), NSMidY(b), 0.0, 0.0);
        } else {
            r.origin.x += NSMinX(b);
            r.origin.y += NSMinY(b);
        }
        [imageRep release];
        r = NSIntersectionRect(NSInsetRect(r, -marginWidth, -marginHeight), b);
        rectValue = [NSValue valueWithRect:r];
        CFDictionarySetValue(bboxCache, (void *)self, (void *)rectValue);
    }
    return [rectValue rectValue];
}
    
- (NSImage *)image {
    return [self imageForBox:kPDFDisplayBoxCropBox];
}

- (NSImage *)imageForBox:(PDFDisplayBox)box {
    NSRect bounds = [self boundsForBox:box];
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
    [self drawWithBox:box]; 
    [NSGraphicsContext restoreGraphicsState];
    [image unlockFocus];
    
    return [image autorelease];
}

- (NSImage *)thumbnailWithSize:(float)size forBox:(PDFDisplayBox)box {
    return  [self thumbnailWithSize:size forBox:box readingBarRect:NSZeroRect];
}

- (NSImage *)thumbnailWithSize:(float)size forBox:(PDFDisplayBox)box readingBarRect:(NSRect)readingBarRect {
    float shadowBlurRadius = roundf(size / 32.0);
    float shadowOffset = - ceilf(shadowBlurRadius * 0.75);
    return  [self thumbnailWithSize:size forBox:box shadowBlurRadius:shadowBlurRadius shadowOffset:NSMakeSize(0.0, shadowOffset) readingBarRect:readingBarRect];
}

- (NSImage *)thumbnailWithSize:(float)size forBox:(PDFDisplayBox)box shadowBlurRadius:(float)shadowBlurRadius shadowOffset:(NSSize)shadowOffset readingBarRect:(NSRect)readingBarRect {
    NSRect bounds = [self boundsForBox:box];
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
    
    readingBarRect.origin.x -= NSMinX(bounds);
    readingBarRect.origin.y -= NSMinY(bounds);
    
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
    [self drawWithBox:box]; 
    if (NSIsEmptyRect(readingBarRect) == NO) {
        [[NSUnarchiver unarchiveObjectWithData:[[NSUserDefaults standardUserDefaults] objectForKey:SKReadingBarColorKey]] setFill];
        if ([[NSUserDefaults standardUserDefaults] boolForKey:SKReadingBarInvertKey]) {
            NSRect outRect, ignored;
            NSDivideRect(bounds, &outRect, &ignored, NSMaxY(bounds) - NSMaxY(readingBarRect), NSMaxYEdge);
            [NSBezierPath fillRect:outRect];
            NSDivideRect(bounds, &outRect, &ignored, NSMinY(readingBarRect) - NSMinY(bounds), NSMinYEdge);
            [NSBezierPath fillRect:outRect];
        } else {
            CGContextSetBlendMode([[NSGraphicsContext currentContext] graphicsPort], kCGBlendModeMultiply);
            [NSBezierPath fillRect:readingBarRect];
        }
    }
    [NSGraphicsContext restoreGraphicsState];
    [image unlockFocus];
    
    return [image autorelease];
}

- (NSArray *)lineBounds {
    static NSCharacterSet *nonWhitespaceAndNewlineCharacterSet = nil;
    if (nonWhitespaceAndNewlineCharacterSet == nil)
        nonWhitespaceAndNewlineCharacterSet = [[[NSCharacterSet whitespaceAndNewlineCharacterSet] invertedSet] copy];
    
    NSMutableArray *lines = [NSMutableArray array];
    PDFSelection *sel = [self selectionForRect:[self boundsForBox:kPDFDisplayBoxCropBox]];
    unsigned i, iMax = [sel safeNumberOfRangesOnPage:self];
    NSMutableIndexSet *indexes = [NSMutableIndexSet indexSet];
    NSString *string = [self string];
    NSRange stringRange = NSMakeRange(0, [string length]);
    
    for (i = 0; i < iMax; i++) {
        NSRange range = [sel safeRangeAtIndex:i onPage:self];
        unsigned j;
        
        for (j = range.location; j < NSMaxRange(range); j++) {
            if ([indexes containsIndex:j])
                continue;
            
            NSRect r = [self characterBoundsAtIndex:j];
            PDFSelection *s = [self selectionForLineAtPoint:NSMakePoint(NSMidX(r), NSMidY(r))];
            unsigned k, kMax = [s safeNumberOfRangesOnPage:self];
            BOOL notEmpty = NO;
            
            for (k = 0; k < kMax; k++) {
                NSRange selRange = [s safeRangeAtIndex:k onPage:self];
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

- (unsigned int)index {
    return [[self document] indexForPage:self] + 1;
}

- (int)rotationAngle {
    return [self rotation];
}

- (void)setRotationAngle:(int)angle {
    if (angle != [self rotation]) {
        NSUndoManager *undoManager = [[self containingDocument] undoManager];
        [[undoManager prepareWithInvocationTarget:self] setRotationAngle:[self rotation]];
        [undoManager setActionName:NSLocalizedString(@"Rotate Page", @"Undo action name")];
        // this will dirty the document, even though no saveable change has been made
        // but we cannot undo the document change count because there may be real changes to the document in the script
        
        [self setRotation:angle];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:SKPDFDocumentPageBoundsDidChangeNotification 
                object:[self document] userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"rotate", @"action", self, @"page", nil]];
    }
}

- (NSData *)boundsAsQDRect {
    Rect qdBounds = RectFromNSRect([self boundsForBox:kPDFDisplayBoxCropBox]);
    return [NSData dataWithBytes:&qdBounds length:sizeof(Rect)];
}

- (void)setBoundsAsQDRect:(NSData *)inQDBoundsAsData {
    if ([inQDBoundsAsData length] == sizeof(Rect)) {
        NSUndoManager *undoManager = [[self containingDocument] undoManager];
        [[undoManager prepareWithInvocationTarget:self] setBoundsAsQDRect:[self boundsAsQDRect]];
        [undoManager setActionName:NSLocalizedString(@"Crop Page", @"Undo action name")];
        // this will dirty the document, even though no saveable change has been made
        // but we cannot undo the document change count because there may be real changes to the document in the script
        
        const Rect *qdBounds = (const Rect *)[inQDBoundsAsData bytes];
        NSRect newBounds = NSRectFromRect(*qdBounds);
        [self setBounds:newBounds forBox:kPDFDisplayBoxCropBox];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:SKPDFDocumentPageBoundsDidChangeNotification 
                object:[self document] userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"crop", @"action", self, @"page", nil]];
    }
}

- (NSData *)mediaBoundsAsQDRect {
    Rect qdBounds = RectFromNSRect([self boundsForBox:kPDFDisplayBoxMediaBox]);
    return [NSData dataWithBytes:&qdBounds length:sizeof(Rect)];
}

- (NSData *)contentBoundsAsQDRect {
    Rect qdBounds = RectFromNSRect([self foregroundBox]);
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
    SKPDFView *pdfView = [[self containingDocument] pdfView];
    
    [pdfView addAnnotation:newNote toPage:self];
    [[pdfView undoManager] setActionName:NSLocalizedString(@"Add Note", @"Undo action name")];
}

- (void)insertInNotes:(id)newNote atIndex:(unsigned int)index {
    [self insertInNotes:newNote];
}

- (void)removeFromNotesAtIndex:(unsigned int)index {
    PDFAnnotation *note = [[self notes] objectAtIndex:index];
    SKPDFView *pdfView = [[self containingDocument] pdfView];
    
    [pdfView removeAnnotation:note];
    [[pdfView undoManager] setActionName:NSLocalizedString(@"Remove Note", @"Undo action name")];
}

@end
