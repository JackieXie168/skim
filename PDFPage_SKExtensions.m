//
//  PDFPage_SKExtensions.m
//  Skim
//
//  Created by Christiaan Hofman on 2/16/07.
/*
 This software is Copyright (c) 2007-2009
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
#import <SkimNotes/SkimNotes.h>
#import "SKPDFAnnotationTemporary.h"
#import "SKPDFDocument.h"
#import "SKPDFView.h"
#import "PDFSelection_SKExtensions.h"
#import "SKRuntime.h"
#import "NSBitmapImageRep_SKExtensions.h"
#import "SKStringConstants.h"
#import "NSCharacterSet_SKExtensions.h"
#import "NSGeometry_SKExtensions.h"
#import "NSData_SKExtensions.h"
#import "SKCFCallBacks.h"
#import "NSUserDefaults_SKExtensions.h"
#import "SKMainWindowController.h"
#import "NSAffineTransform_SKExtensions.h"

NSString *SKPDFPageBoundsDidChangeNotification = @"SKPDFPageBoundsDidChangeNotification";

NSString *SKPDFPagePageKey = @"page";
NSString *SKPDFPageActionKey = @"action";
NSString *SKPDFPageActionCrop = @"crop";
NSString *SKPDFPageActionRotate = @"rotate";

#define SKAutoCropBoxMarginWidthKey @"SKAutoCropBoxMarginWidth"
#define SKAutoCropBoxMarginHeightKey @"SKAutoCropBoxMarginHeight"

@implementation PDFPage (SKExtensions) 

#define FOREGROUND_BOX_MARGIN 10.0

// A subclass with ivars would be nicer in some respects, but that would require subclassing PDFDocument and returning instances of the subclass for each page.
static CFMutableDictionaryRef bboxCache = NULL;
static void (*original_dealloc)(id, SEL) = NULL;

- (void)replacement_dealloc {
    CFDictionaryRemoveValue(bboxCache, self);
    original_dealloc(self, _cmd);
}

+ (void)load {
    original_dealloc = (void (*)(id, SEL))SKReplaceInstanceMethodImplementationFromSelector(self, @selector(dealloc), @selector(replacement_dealloc));
    bboxCache = CFDictionaryCreateMutable(NULL, 0, NULL, &kSKNSRectDictionaryValueCallBacks);
}

static BOOL usesSequentialPageNumbering = NO;

+ (BOOL)usesSequentialPageNumbering {
    return usesSequentialPageNumbering;
}

+ (void)setUsesSequentialPageNumbering:(BOOL)flag {
    usesSequentialPageNumbering = flag;
}

- (NSBitmapImageRep *)newBitmapImageRepForBox:(PDFDisplayBox)box {
    NSRect bounds = [self boundsForBox:box];
    NSBitmapImageRep *imageRep;
    imageRep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:NULL
                                                       pixelsWide:NSWidth(bounds) 
                                                       pixelsHigh:NSHeight(bounds) 
                                                    bitsPerSample:8 
                                                  samplesPerPixel:4
                                                         hasAlpha:YES 
                                                         isPlanar:NO 
                                                   colorSpaceName:NSCalibratedRGBColorSpace 
                                                     bitmapFormat:0 
                                                      bytesPerRow:0 
                                                     bitsPerPixel:32];
    if (imageRep) {
        [NSGraphicsContext saveGraphicsState];
        [NSGraphicsContext setCurrentContext:[NSGraphicsContext graphicsContextWithBitmapImageRep:imageRep]];
        [[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationNone];
        [[NSGraphicsContext currentContext] setShouldAntialias:NO];
        if ([self rotation]) {
            NSAffineTransform *transform = [NSAffineTransform transform];
            switch ([self rotation]) {
                case 90:  [transform translateXBy:NSWidth(bounds) yBy:0.0]; break;
                case 180: [transform translateXBy:NSHeight(bounds) yBy:NSWidth(bounds)]; break;
                case 270: [transform translateXBy:0.0 yBy:NSHeight(bounds)]; break;
            }
            [transform rotateByDegrees:[self rotation]];
            [transform concat];
        }
        [[self annotations] makeObjectsPerformSelector:@selector(hideIfTemporary)];
        [self drawWithBox:box]; 
        [[self annotations] makeObjectsPerformSelector:@selector(displayIfTemporary)];
        [NSGraphicsContext restoreGraphicsState];
    }
    return imageRep;
}

- (NSRect)foregroundBox {
    NSRect *rectPtr = NULL;
    if (FALSE == CFDictionaryGetValueIfPresent(bboxCache, (void *)self, (const void **)&rectPtr)) {
        CGFloat marginWidth = [[NSUserDefaults standardUserDefaults] floatForKey:SKAutoCropBoxMarginWidthKey];
        CGFloat marginHeight = [[NSUserDefaults standardUserDefaults] floatForKey:SKAutoCropBoxMarginHeightKey];
        NSBitmapImageRep *imageRep = [self newBitmapImageRepForBox:kPDFDisplayBoxMediaBox];
        NSRect bounds = [self boundsForBox:kPDFDisplayBoxMediaBox];
        NSRect rect = [imageRep foregroundRect];
        if (imageRep == nil) {
            rect = bounds;
        } else if (NSEqualRects(NSZeroRect, rect)) {
            rect.origin.x = SKFloor(NSMidX(bounds));
            rect.origin.x = ceilf(NSMidY(bounds));
        } else {
            rect.origin.x += NSMinX(bounds);
            rect.origin.y += NSMinY(bounds);
        }
        [imageRep release];
        rect = NSIntersectionRect(NSInsetRect(rect, -marginWidth, -marginHeight), bounds);
        rectPtr = &rect;
        CFDictionarySetValue(bboxCache, (void *)self, (void *)rectPtr);
    }
    // dereferencing here should always be safe (if not in the dictionary, it was initialized)
    return *rectPtr;
}

- (NSImage *)image {
    return [self thumbnailWithSize:0.0 forBox:kPDFDisplayBoxCropBox shadowBlurRadius:0.0 shadowOffset:NSZeroSize readingBarRect:NSZeroRect];
}

- (NSImage *)thumbnailWithSize:(CGFloat)size forBox:(PDFDisplayBox)box {
    return  [self thumbnailWithSize:size forBox:box readingBarRect:NSZeroRect];
}

- (NSImage *)thumbnailWithSize:(CGFloat)size forBox:(PDFDisplayBox)box readingBarRect:(NSRect)readingBarRect {
    CGFloat shadowBlurRadius = SKRound(size / 32.0);
    CGFloat shadowOffset = - ceilf(shadowBlurRadius * 0.75);
    return  [self thumbnailWithSize:size forBox:box shadowBlurRadius:shadowBlurRadius shadowOffset:NSMakeSize(0.0, shadowOffset) readingBarRect:readingBarRect];
}

- (NSImage *)thumbnailWithSize:(CGFloat)size forBox:(PDFDisplayBox)box shadowBlurRadius:(CGFloat)shadowBlurRadius shadowOffset:(NSSize)shadowOffset readingBarRect:(NSRect)readingBarRect {
    NSRect bounds = [self boundsForBox:box];
    BOOL isScaled = size > 0.0;
    BOOL hasShadow = shadowBlurRadius > 0.0;
    CGFloat scale = 1.0;
    NSSize thumbnailSize;
    NSRect pageRect = NSZeroRect;
    NSImage *image;
    
    if ([self rotation] % 180 == 90)
        bounds = NSMakeRect(NSMinX(bounds), NSMinY(bounds), NSHeight(bounds), NSWidth(bounds));
    
    if (isScaled) {
        if (NSHeight(bounds) > NSWidth(bounds))
            thumbnailSize = NSMakeSize(SKRound((size - 2.0 * shadowBlurRadius) * NSWidth(bounds) / NSHeight(bounds) + 2.0 * shadowBlurRadius), size);
        else
            thumbnailSize = NSMakeSize(size, SKRound((size - 2.0 * shadowBlurRadius) * NSHeight(bounds) / NSWidth(bounds) + 2.0 * shadowBlurRadius));
        scale = SKMin((thumbnailSize.width - 2.0 * shadowBlurRadius) / NSWidth(bounds), (thumbnailSize.height - 2.0 * shadowBlurRadius) / NSHeight(bounds));
    } else {
        thumbnailSize = NSMakeSize(NSWidth(bounds) + 2.0 * shadowBlurRadius, NSHeight(bounds) + 2.0 * shadowBlurRadius);
    }
    
    readingBarRect.origin = SKSubstractPoints(readingBarRect.origin, bounds.origin);

    image = [[NSImage alloc] initWithSize:thumbnailSize];
    [image lockFocus];
    [[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationHigh];
    [NSGraphicsContext saveGraphicsState];
    [[NSColor whiteColor] set];
    if (hasShadow) {
        NSShadow *aShadow = [[NSShadow alloc] init];
        [aShadow setShadowColor:[NSColor colorWithCalibratedWhite:0.0 alpha:0.5]];
        [aShadow setShadowBlurRadius:shadowBlurRadius];
        [aShadow setShadowOffset:shadowOffset];
        [aShadow set];
        [aShadow release];
    }
    pageRect.size = thumbnailSize;
    pageRect = NSInsetRect(pageRect, shadowBlurRadius, shadowBlurRadius);
    pageRect.origin.x -= shadowOffset.width;
    pageRect.origin.y -= shadowOffset.height;
    NSRectFill(pageRect);
    [NSGraphicsContext restoreGraphicsState];
    if (isScaled || hasShadow) {
        NSAffineTransform *transform = [NSAffineTransform transform];
        if (isScaled)
            [transform scaleBy:scale];
        [transform translateXBy:(shadowBlurRadius - shadowOffset.width) / scale yBy:(shadowBlurRadius - shadowOffset.height) / scale];
        [transform concat];
    }
    
    [[self annotations] makeObjectsPerformSelector:@selector(hideIfTemporary)];
    [self drawWithBox:box]; 
    [[self annotations] makeObjectsPerformSelector:@selector(displayIfTemporary)];
    
    if (NSIsEmptyRect(readingBarRect) == NO) {
        [[[NSUserDefaults standardUserDefaults] colorForKey:SKReadingBarColorKey] setFill];
        if ([[NSUserDefaults standardUserDefaults] boolForKey:SKReadingBarInvertKey]) {
            NSRect outRect, ignored;
            bounds.origin = NSZeroPoint;
            NSDivideRect(bounds, &outRect, &ignored, NSMaxY(bounds) - NSMaxY(readingBarRect), NSMaxYEdge);
            [NSBezierPath fillRect:outRect];
            NSDivideRect(bounds, &outRect, &ignored, NSMinY(readingBarRect) - NSMinY(bounds), NSMinYEdge);
            [NSBezierPath fillRect:outRect];
        } else {
            CGContextSetBlendMode([[NSGraphicsContext currentContext] graphicsPort], kCGBlendModeMultiply);
            [NSBezierPath fillRect:readingBarRect];
        }
    }
    [image unlockFocus];
    
    return [image autorelease];
}

- (NSAttributedString *)thumbnailAttachmentWithSize:(CGFloat)size {
    NSImage *image = [self thumbnailWithSize:size forBox:kPDFDisplayBoxCropBox];
    
    NSFileWrapper *wrapper = [[NSFileWrapper alloc] initRegularFileWithContents:[image TIFFRepresentation]];
    NSString *filename = [NSString stringWithFormat:@"page_%u.tiff", [self pageIndex] + 1];
    [wrapper setFilename:filename];
    [wrapper setPreferredFilename:filename];

    NSTextAttachment *attachment = [[NSTextAttachment alloc] initWithFileWrapper:wrapper];
    [wrapper release];
    NSAttributedString *attrString = [NSAttributedString attributedStringWithAttachment:attachment];
    [attachment release];
    
    return attrString;
}

- (NSAttributedString *)thumbnailAttachment { return [self thumbnailAttachmentWithSize:0.0]; }

- (NSAttributedString *)thumbnail512Attachment { return [self thumbnailAttachmentWithSize:512.0]; }

- (NSAttributedString *)thumbnail256Attachment { return [self thumbnailAttachmentWithSize:256.0]; }

- (NSAttributedString *)thumbnail128Attachment { return [self thumbnailAttachmentWithSize:128.0]; }

- (NSAttributedString *)thumbnail64Attachment { return [self thumbnailAttachmentWithSize:64.0]; }

- (NSAttributedString *)thumbnail32Attachment { return [self thumbnailAttachmentWithSize:32.0]; }

- (NSData *)PDFDataForRect:(NSRect)rect {
    NSData *data = [self dataRepresentation];
    
    if (NSEqualRects(rect, NSZeroRect))
        return data;
    if (NSIsEmptyRect(rect))
        return nil;
    
    if ([self rotation]) {
        NSAffineTransform *transform = [NSAffineTransform transform];
        NSRect bounds = [self boundsForBox:kPDFDisplayBoxMediaBox];
        switch ([self rotation]) {
            case 90:  [transform translateXBy:0.0 yBy:NSWidth(bounds)]; break;
            case 180: [transform translateXBy:NSWidth(bounds) yBy:NSHeight(bounds)]; break;
            case 270: [transform translateXBy:NSHeight(bounds) yBy:0.0]; break;
        }
        [transform rotateByDegrees:-[self rotation]];
        rect = [transform transformRect:rect];
    }
    
    PDFDocument *pdfDoc = [[PDFDocument alloc] initWithData:data];
    PDFPage *page = [pdfDoc pageAtIndex:0];
    
    if (floor(NSAppKitVersionNumber) > NSAppKitVersionNumber10_4) {
        [page setBounds:rect forBox:kPDFDisplayBoxMediaBox];
        [page setBounds:NSZeroRect forBox:kPDFDisplayBoxCropBox];
    } else {
        // setting the media box is buggy on Tiger, see bug # 1928384
        [page setBounds:rect forBox:kPDFDisplayBoxCropBox];
    }
    [page setBounds:NSZeroRect forBox:kPDFDisplayBoxBleedBox];
    [page setBounds:NSZeroRect forBox:kPDFDisplayBoxTrimBox];
    [page setBounds:NSZeroRect forBox:kPDFDisplayBoxArtBox];
    data = [page dataRepresentation];
    [pdfDoc release];
    
    return data;
}

- (NSData *)TIFFDataForRect:(NSRect)rect {
    PDFDisplayBox box = NSEqualRects(rect, [self boundsForBox:kPDFDisplayBoxCropBox]) ? kPDFDisplayBoxCropBox : kPDFDisplayBoxMediaBox;
    NSImage *pageImage = [self thumbnailWithSize:0.0 forBox:box shadowBlurRadius:0.0 shadowOffset:NSZeroSize readingBarRect:NSZeroRect];
    NSRect bounds = [self boundsForBox:box];
    
    if (NSEqualRects(rect, NSZeroRect) || NSEqualRects(rect, bounds))
        return [pageImage TIFFRepresentation];
    if (NSIsEmptyRect(rect))
        return nil;
    
    NSAffineTransform *transform = [NSAffineTransform transform];
    switch ([self rotation]) {
        case 0:   [transform translateXBy:-NSMinX(bounds) yBy:-NSMinY(bounds)]; break;
        case 90:  [transform translateXBy:-NSMinY(bounds) yBy:NSMaxX(bounds)]; break;
        case 180: [transform translateXBy:NSMaxX(bounds) yBy:NSMaxY(bounds)]; break;
        case 270: [transform translateXBy:NSMaxY(bounds) yBy:-NSMinX(bounds)]; break;
    }
    [transform rotateByDegrees:-[self rotation]];
    
    NSRect sourceRect = [transform transformRect:rect];
    NSRect targetRect = {NSZeroPoint, sourceRect.size};
    
    NSImage *image = [[NSImage alloc] initWithSize:targetRect.size];
    [image lockFocus];
    [pageImage drawInRect:targetRect fromRect:sourceRect operation:NSCompositeCopy fraction:1.0];
    [image unlockFocus];
    
    NSData *data = [image TIFFRepresentation];
    [image release];
    
    return data;
}

- (NSArray *)lineRects {
    NSMutableArray *lines = [NSMutableArray array];
    PDFSelection *sel = [self selectionForRect:[self boundsForBox:kPDFDisplayBoxCropBox]];
    NSUInteger i, iMax = [sel safeNumberOfRangesOnPage:self];
    NSMutableIndexSet *indexes = [NSMutableIndexSet indexSet];
    NSString *string = [self string];
    NSRange stringRange = NSMakeRange(0, [string length]);
    
    for (i = 0; i < iMax; i++) {
        NSRange range = [sel safeRangeAtIndex:i onPage:self];
        NSUInteger j, jMax = NSMaxRange(range);
        
        for (j = range.location; j < jMax; j++) {
            if ([indexes containsIndex:j])
                continue;
            
            NSRect r = [self characterBoundsAtIndex:j];
            PDFSelection *s = [self selectionForLineAtPoint:SKCenterPoint(r)];
            NSUInteger k, kMax = [s safeNumberOfRangesOnPage:self];
            BOOL notEmpty = NO;
            
            for (k = 0; k < kMax; k++) {
                NSRange selRange = [s safeRangeAtIndex:k onPage:self];
                if (selRange.location != NSNotFound) {
                    [indexes addIndexesInRange:selRange];
                    // due to a bug in PDFKit, the range of the selection can sometimes lie partly outside the range of the string
                    if ([string rangeOfCharacterFromSet:[NSCharacterSet nonWhitespaceAndNewlineCharacterSet] options:0 range:NSIntersectionRange(selRange, stringRange)].length)
                        notEmpty = YES;
                }
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

- (NSUInteger)pageIndex {
    return [[self document] indexForPage:self];
}

- (NSString *)sequentialLabel {
    return [NSString stringWithFormat:@"%u", [self pageIndex] + 1];
}

- (NSString *)displayLabel {
    NSString *label = nil;
    if ([[self class] usesSequentialPageNumbering] == NO)
        label = [self label];
    return label ?: [self sequentialLabel];
}

#pragma mark Scripting support

- (NSScriptObjectSpecifier *)objectSpecifier {
    SKPDFDocument *document = [self containingDocument];
	NSUInteger idx = [self pageIndex];
    
    if (document && idx != NSNotFound) {
        NSScriptObjectSpecifier *containerRef = [document objectSpecifier];
        return [[[NSIndexSpecifier allocWithZone:[self zone]] initWithContainerClassDescription:[containerRef keyClassDescription] containerSpecifier:containerRef key:@"pages" index:idx] autorelease];
    } else {
        return nil;
    }
}

- (SKPDFDocument *)containingDocument {
    NSEnumerator *docEnum = [[[NSDocumentController sharedDocumentController] documents] objectEnumerator];
    SKPDFDocument *document;
    
    while (document = [docEnum nextObject]) {
        if ([document respondsToSelector:@selector(pdfDocument)] && [[self document] isEqual:[document pdfDocument]])
            break;
    }
    
    return document;
}

- (NSUInteger)index {
    return [self pageIndex] + 1;
}

- (NSInteger)rotationAngle {
    return [self rotation];
}

- (void)setRotationAngle:(NSInteger)angle {
    if (angle != [self rotation]) {
        NSUndoManager *undoManager = [[self containingDocument] undoManager];
        [[undoManager prepareWithInvocationTarget:self] setRotationAngle:[self rotation]];
        [undoManager setActionName:NSLocalizedString(@"Rotate Page", @"Undo action name")];
        // this will dirty the document, even though no saveable change has been made
        // but we cannot undo the document change count because there may be real changes to the document in the script
        
        [self setRotation:angle];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:SKPDFPageBoundsDidChangeNotification 
                object:[self document] userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"rotate", @"action", self, @"page", nil]];
    }
}

- (NSData *)boundsAsQDRect {
    return [NSData dataWithRectAsQDRect:[self boundsForBox:kPDFDisplayBoxCropBox]];
}

- (void)setBoundsAsQDRect:(NSData *)inQDBoundsAsData {
    if (inQDBoundsAsData && [inQDBoundsAsData isEqual:[NSNull null]] == NO) {
        NSUndoManager *undoManager = [[self containingDocument] undoManager];
        [[undoManager prepareWithInvocationTarget:self] setBoundsAsQDRect:[self boundsAsQDRect]];
        [undoManager setActionName:NSLocalizedString(@"Crop Page", @"Undo action name")];
        // this will dirty the document, even though no saveable change has been made
        // but we cannot undo the document change count because there may be real changes to the document in the script
        
        NSRect newBounds = [inQDBoundsAsData rectValueAsQDRect];
        if (NSWidth(newBounds) < 0.0)
            newBounds.size.width = 0.0;
        if (NSHeight(newBounds) < 0.0)
            newBounds.size.height = 0.0;
        [self setBounds:newBounds forBox:kPDFDisplayBoxCropBox];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:SKPDFPageBoundsDidChangeNotification 
                object:[self document] userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"crop", @"action", self, @"page", nil]];
    }
}

- (NSData *)mediaBoundsAsQDRect {
    return [NSData dataWithRectAsQDRect:[self boundsForBox:kPDFDisplayBoxMediaBox]];
}

- (void)setMediaBoundsAsQDRect:(NSData *)inQDBoundsAsData {
    if (inQDBoundsAsData && [inQDBoundsAsData isEqual:[NSNull null]] == NO) {
        NSUndoManager *undoManager = [[self containingDocument] undoManager];
        [[undoManager prepareWithInvocationTarget:self] setMediaBoundsAsQDRect:[self mediaBoundsAsQDRect]];
        [undoManager setActionName:NSLocalizedString(@"Crop Page", @"Undo action name")];
        // this will dirty the document, even though no saveable change has been made
        // but we cannot undo the document change count because there may be real changes to the document in the script
        
        NSRect newBounds = [inQDBoundsAsData rectValueAsQDRect];
        if (NSWidth(newBounds) < 0.0)
            newBounds.size.width = 0.0;
        if (NSHeight(newBounds) < 0.0)
            newBounds.size.height = 0.0;
        [self setBounds:newBounds forBox:kPDFDisplayBoxMediaBox];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:SKPDFPageBoundsDidChangeNotification 
                object:[self document] userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"crop", @"action", self, @"page", nil]];
    }
}

- (NSData *)contentBoundsAsQDRect {
    return [NSData dataWithRectAsQDRect:[self foregroundBox]];
}

- (NSTextStorage *)richText {
    NSAttributedString *attrString = [self attributedString];
    return attrString ? [[[NSTextStorage alloc] initWithAttributedString:attrString] autorelease] : [[[NSTextStorage alloc] init] autorelease];
}

- (NSArray *)notes {
    NSEnumerator *annEnum = [[self annotations] objectEnumerator];
    PDFAnnotation *annotation;
    NSMutableArray *notes = [NSMutableArray array];
    
    while (annotation = [annEnum nextObject]) {
        if ([annotation isSkimNote])
            [notes addObject:annotation];
    }
    return notes;
}

- (void)insertInNotes:(id)newNote {
    SKPDFView *pdfView = [[self containingDocument] pdfView];
    
    [pdfView addAnnotation:newNote toPage:self];
    [[pdfView undoManager] setActionName:NSLocalizedString(@"Add Note", @"Undo action name")];
}

- (void)insertInNotes:(id)newNote atIndex:(NSUInteger)anIndex {
    [self insertInNotes:newNote];
}

- (void)removeFromNotesAtIndex:(NSUInteger)anIndex {
    PDFAnnotation *note = [[self notes] objectAtIndex:anIndex];
    SKPDFView *pdfView = [[self containingDocument] pdfView];
    
    [pdfView removeAnnotation:note];
    [[pdfView undoManager] setActionName:NSLocalizedString(@"Remove Note", @"Undo action name")];
}

- (id)handleGrabScriptCommand:(NSScriptCommand *)command {
	NSDictionary *args = [command evaluatedArguments];
    NSData *boundsData = [args objectForKey:@"Bounds"];
    id asTIFFNumber = [args objectForKey:@"AsTIFF"];
    id asTypeNumber = [args objectForKey:@"Type"];
    NSRect bounds = [boundsData respondsToSelector:@selector(rectValueAsQDRect)] ? [boundsData rectValueAsQDRect] : NSZeroRect;
    FourCharCode asType = [asTypeNumber respondsToSelector:@selector(unsignedLongValue)] ? [asTypeNumber unsignedLongValue] : 0; 
    BOOL asTIFF = [asTIFFNumber respondsToSelector:@selector(boolValue)] ? [asTIFFNumber boolValue] : NO; 
    
    NSData *data = nil;
    DescType type = 0;
    
    if (asTIFF || asType == 'TIFF') {
        data = [self TIFFDataForRect:bounds];
        type = 'TIFF';
    } else {
        data = [self PDFDataForRect:bounds];
        type = 'PDF ';
    }
    
    return data ? [NSAppleEventDescriptor descriptorWithDescriptorType:type data:data] : nil;
}

@end
