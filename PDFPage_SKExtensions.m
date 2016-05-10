//
//  PDFPage_SKExtensions.m
//  Skim
//
//  Created by Christiaan Hofman on 2/16/07.
/*
 This software is Copyright (c) 2007-2016
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
#import "SKMainDocument.h"
#import "SKPDFView.h"
#import "SKReadingBar.h"
#import "PDFSelection_SKExtensions.h"
#import "SKRuntime.h"
#import "NSBitmapImageRep_SKExtensions.h"
#import "SKStringConstants.h"
#import "NSCharacterSet_SKExtensions.h"
#import "NSGeometry_SKExtensions.h"
#import "NSData_SKExtensions.h"
#import "NSUserDefaults_SKExtensions.h"
#import "SKMainWindowController.h"
#import "PDFAnnotation_SKExtensions.h"
#import "PDFAnnotationMarkup_SKExtensions.h"
#import "PDFAnnotationInk_SKExtensions.h"
#import "NSPointerArray_SKExtensions.h"
#import "NSDocument_SKExtensions.h"
#import "PDFDocument_SKExtensions.h"
#import "NSImage_SKExtensions.h"
#import "NSShadow_SKExtensions.h"

NSString *SKPDFPageBoundsDidChangeNotification = @"SKPDFPageBoundsDidChangeNotification";

NSString *SKPDFPagePageKey = @"page";
NSString *SKPDFPageActionKey = @"action";
NSString *SKPDFPageActionCrop = @"crop";
NSString *SKPDFPageActionResize = @"resize";
NSString *SKPDFPageActionRotate = @"rotate";

#define SKAutoCropBoxMarginWidthKey @"SKAutoCropBoxMarginWidth"
#define SKAutoCropBoxMarginHeightKey @"SKAutoCropBoxMarginHeight"

@implementation PDFPage (SKExtensions) 

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
        [self drawWithBox:box]; 
        [[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationDefault];
        [NSGraphicsContext restoreGraphicsState];
    }
    return imageRep;
}

// this will be cached in our custom subclass
- (NSRect)foregroundBox {
    CGFloat marginWidth = [[NSUserDefaults standardUserDefaults] floatForKey:SKAutoCropBoxMarginWidthKey];
    CGFloat marginHeight = [[NSUserDefaults standardUserDefaults] floatForKey:SKAutoCropBoxMarginHeightKey];
    NSBitmapImageRep *imageRep = [self newBitmapImageRepForBox:kPDFDisplayBoxMediaBox];
    NSRect bounds = [self boundsForBox:kPDFDisplayBoxMediaBox];
    NSRect foregroundBox = [imageRep foregroundRect];
    if (imageRep == nil) {
        foregroundBox = bounds;
    } else if (NSIsEmptyRect(foregroundBox)) {
        foregroundBox.origin = SKIntegralPoint(SKCenterPoint(bounds));
        foregroundBox.size = NSZeroSize;
    } else {
        foregroundBox.origin = SKAddPoints(foregroundBox.origin, bounds.origin);
    }
    [imageRep release];
    return NSIntersectionRect(NSInsetRect(foregroundBox, -marginWidth, -marginHeight), bounds);
}

- (NSImage *)pageImage {
    return [self thumbnailWithSize:0.0 forBox:kPDFDisplayBoxCropBox shadowBlurRadius:0.0 readingBar:nil];
}

- (NSImage *)thumbnailWithSize:(CGFloat)aSize forBox:(PDFDisplayBox)box {
    return  [self thumbnailWithSize:aSize forBox:box readingBar:nil];
}

- (NSImage *)thumbnailWithSize:(CGFloat)aSize forBox:(PDFDisplayBox)box readingBar:(SKReadingBar *)readingBar {
    CGFloat shadowBlurRadius = round(aSize / 32.0);
    return  [self thumbnailWithSize:aSize forBox:box shadowBlurRadius:shadowBlurRadius readingBar:readingBar];
}

- (NSImage *)thumbnailWithSize:(CGFloat)aSize forBox:(PDFDisplayBox)box shadowBlurRadius:(CGFloat)shadowBlurRadius readingBar:(SKReadingBar *)readingBar {
    NSRect bounds = [self boundsForBox:box];
    NSSize pageSize = bounds.size;
    CGFloat scale = 1.0;
    NSSize thumbnailSize;
    CGFloat shadowOffset = shadowBlurRadius > 0.0 ? - ceil(shadowBlurRadius * 0.75) : 0.0;
    NSRect pageRect = NSZeroRect;
    NSImage *image;
    
    if ([self rotation] % 180 == 90)
        pageSize = NSMakeSize(pageSize.height, pageSize.width);
    
    if (aSize > 0.0) {
        if (pageSize.height > pageSize.width)
            thumbnailSize = NSMakeSize(round((aSize - 2.0 * shadowBlurRadius) * pageSize.width / pageSize.height + 2.0 * shadowBlurRadius), aSize);
        else
            thumbnailSize = NSMakeSize(aSize, round((aSize - 2.0 * shadowBlurRadius) * pageSize.height / pageSize.width + 2.0 * shadowBlurRadius));
        scale = fmax((thumbnailSize.width - 2.0 * shadowBlurRadius) / pageSize.width, (thumbnailSize.height - 2.0 * shadowBlurRadius) / pageSize.height);
    } else {
        thumbnailSize = NSMakeSize(pageSize.width + 2.0 * shadowBlurRadius, pageSize.height + 2.0 * shadowBlurRadius);
    }
    
    pageRect.size = thumbnailSize;
    
    if (shadowBlurRadius > 0.0) {
        pageRect = NSInsetRect(pageRect, shadowBlurRadius, shadowBlurRadius);
        pageRect.origin.y -= shadowOffset;
    }
    
    image = [NSImage bitmapImageWithSize:thumbnailSize drawingHandler:^(NSRect rect){
        
        [[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationHigh];
        
        [NSGraphicsContext saveGraphicsState];
        [[NSColor whiteColor] setFill];
        if (shadowBlurRadius > 0.0)
            [NSShadow setShadowWithColor:[NSColor colorWithCalibratedWhite:0.0 alpha:0.5] blurRadius:shadowBlurRadius yOffset:shadowOffset];
        NSRectFill(pageRect);
        [NSGraphicsContext restoreGraphicsState];
        
        if (fabs(scale - 1.0) > 0.0 || shadowBlurRadius > 0.0) {
            NSAffineTransform *transform = [NSAffineTransform transform];
            if (shadowBlurRadius > 0.0)
                [transform translateXBy:NSMinX(pageRect) yBy:NSMinY(pageRect)];
            [transform scaleBy:scale];
            [transform concat];
        }
        
        [self drawWithBox:box]; 
        
        if (readingBar) {
            [self transformContextForBox:box];
            [readingBar drawForPage:self withBox:box];
        }
        
        [[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationDefault];
        
    }];
    
    return image;
}

- (NSAttributedString *)thumbnailAttachmentWithSize:(CGFloat)aSize {
    NSImage *image = [self thumbnailWithSize:aSize forBox:kPDFDisplayBoxCropBox];
    
    NSFileWrapper *wrapper = [[NSFileWrapper alloc] initRegularFileWithContents:[image TIFFRepresentation]];
    NSString *filename = [NSString stringWithFormat:@"page_%lu.tiff", (unsigned long)([self pageIndex] + 1)];
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
    if (NSEqualRects(rect, NSZeroRect))
        return [self dataRepresentation];
    if (NSIsEmptyRect(rect))
        return nil;
    
    NSData *data = nil;
    PDFPage *page = [self copy];
    
    if (floor(NSAppKitVersionNumber) > NSAppKitVersionNumber10_10_Max) {
        // on 10.11 the media box is shifted back to the origin without the contents being shifted
        [page setBounds:rect forBox:kPDFDisplayBoxCropBox];
    } else {
        [page setBounds:rect forBox:kPDFDisplayBoxMediaBox];
        [page setBounds:NSZeroRect forBox:kPDFDisplayBoxCropBox];
    }
    [page setBounds:NSZeroRect forBox:kPDFDisplayBoxBleedBox];
    [page setBounds:NSZeroRect forBox:kPDFDisplayBoxTrimBox];
    [page setBounds:NSZeroRect forBox:kPDFDisplayBoxArtBox];
    data = [page dataRepresentation];
    [page release];
    
    return data;
}

- (NSData *)TIFFDataForRect:(NSRect)rect {
    PDFDisplayBox box = NSEqualRects(rect, [self boundsForBox:kPDFDisplayBoxCropBox]) ? kPDFDisplayBoxCropBox : kPDFDisplayBoxMediaBox;
    NSImage *pageImage = [self thumbnailWithSize:0.0 forBox:box shadowBlurRadius:0.0 readingBar:nil];
    NSRect bounds = [self boundsForBox:box];
    
    if (NSEqualRects(rect, NSZeroRect) || NSEqualRects(rect, bounds))
        return [pageImage TIFFRepresentation];
    if (NSIsEmptyRect(rect))
        return nil;
    
    NSAffineTransform *transform = [self affineTransformForBox:box];
    NSRect sourceRect = SKRectFromPoints([transform transformPoint:SKBottomLeftPoint(rect)], [transform transformPoint:SKTopRightPoint(rect)]);
    
    NSImage *image = [NSImage bitmapImageWithSize:sourceRect.size drawingHandler:^(NSRect destRect){
        [pageImage drawInRect:destRect fromRect:sourceRect operation:NSCompositeCopy fraction:1.0];
    }];
    
    return [image TIFFRepresentation];
}

static inline BOOL lineRectsOverlap(NSRect r1, NSRect r2, BOOL rotated) {
    if (rotated)
        return (NSMaxX(r1) > NSMidX(r2) && NSMidX(r1) < NSMaxX(r2)) || (NSMidX(r1) > NSMinX(r2) && NSMinX(r1) < NSMidX(r2));
    else
        return (NSMinY(r1) < NSMidY(r2) && NSMidY(r1) > NSMinY(r2)) || (NSMidY(r1) < NSMaxY(r2) && NSMaxY(r1) > NSMidY(r2));
}

- (NSPointerArray *)lineRects {
    NSPointerArray *lines = [NSPointerArray rectPointerArray];
    PDFSelection *sel = [self selectionForRect:[self boundsForBox:kPDFDisplayBoxCropBox]];
    CGFloat lastOrder = -CGFLOAT_MAX;
    NSUInteger i;
    NSRect rect;
    
    for (PDFSelection *s in [sel selectionsByLine]) {
        rect = [s boundsForPage:self];
        if (NSIsEmptyRect(rect) == NO && [[s string] rangeOfCharacterFromSet:[NSCharacterSet nonWhitespaceAndNewlineCharacterSet]].length) {
            CGFloat order = [self sortOrderForBounds:rect];
            if (lastOrder <= order) {
                [lines addPointer:&rect];
                lastOrder = order;
            } else {
                for (i = [lines count] - 1; i > 0; i--) {
                    if ([self sortOrderForBounds:[lines rectAtIndex:i - 1]] <= order)
                        break;
                }
                [lines insertPointer:&rect atIndex:i];
            }
        }
    }
    
    NSRect prevRect = NSZeroRect;
    BOOL rotated = ([self intrinsicRotation] % 180) != 0;
    
    for (i = 0; i < [lines count]; i++) {
        rect = [lines rectAtIndex:i];
        if (i > 0 && lineRectsOverlap(prevRect, rect, rotated)) {
            rect = NSUnionRect(prevRect, rect);
            [lines removePointerAtIndex:i--];
            [lines replacePointerAtIndex:i withPointer:&rect];
        }
        prevRect = rect;
    }
    
    return lines;
}

- (NSUInteger)pageIndex {
    return [[self document] indexForPage:self];
}

- (NSString *)sequentialLabel {
    return [NSString stringWithFormat:@"%lu", (unsigned long)([self pageIndex] + 1)];
}

- (NSString *)displayLabel {
    NSString *label = nil;
    if ([[self class] usesSequentialPageNumbering] == NO)
        label = [self label];
    return label ?: [self sequentialLabel];
}

- (NSInteger)intrinsicRotation {
    return CGPDFPageGetRotationAngle([self pageRef]);
}

- (BOOL)isEditable {
    return NO;
}

- (NSAffineTransform *)affineTransformForBox:(PDFDisplayBox)box {
    NSRect bounds = [self boundsForBox:box];
    NSAffineTransform *transform = [NSAffineTransform transform];
    [transform rotateByDegrees:-[self rotation]];
    switch ([self rotation]) {
        case 0:   [transform translateXBy:-NSMinX(bounds) yBy:-NSMinY(bounds)]; break;
        case 90:  [transform translateXBy:-NSMaxX(bounds) yBy:-NSMinY(bounds)]; break;
        case 180: [transform translateXBy:-NSMaxX(bounds) yBy:-NSMaxY(bounds)]; break;
        case 270: [transform translateXBy:-NSMinX(bounds) yBy:-NSMaxY(bounds)]; break;
    }
    return transform;
}

- (CGFloat)sortOrderForBounds:(NSRect)bounds {
    NSRect pageBounds = [self boundsForBox:kPDFDisplayBoxMediaBox];
    // count pixels from top of page in reading direction until the corner of the bounds, in intrinsically rotated page
    if ([[self document] hasRightToLeftLanguage]) {
        switch ([self intrinsicRotation]) {
            case 0:   return NSWidth(pageBounds) * (NSMaxY(pageBounds) - ceil(NSMaxY(bounds))) + NSMaxX(pageBounds) - NSMaxX(bounds);
            case 90:  return NSHeight(pageBounds) * floor(NSMinX(bounds)) + NSMaxY(pageBounds) - NSMaxY(bounds);
            case 180: return NSWidth(pageBounds) * floor(NSMinY(bounds)) + NSMinX(bounds);
            case 270: return NSHeight(pageBounds) * (NSMaxX(pageBounds) - ceil(NSMaxX(bounds))) + NSMinY(bounds);
            default:  return NSWidth(pageBounds) * (NSMaxY(pageBounds) - ceil(NSMaxY(bounds))) + NSMaxX(pageBounds) - NSMaxX(bounds);
        }
    } else {
        switch ([self intrinsicRotation]) {
            case 0:   return NSWidth(pageBounds) * (NSMaxY(pageBounds) - ceil(NSMaxY(bounds))) + NSMinX(bounds);
            case 90:  return NSHeight(pageBounds) * floor(NSMinX(bounds)) + NSMinY(bounds);
            case 180: return NSWidth(pageBounds) * floor(NSMinY(bounds)) + NSMaxX(pageBounds) - NSMaxX(bounds);
            case 270: return NSHeight(pageBounds) * (NSMaxX(pageBounds) - ceil(NSMaxX(bounds))) + NSMaxY(pageBounds) - NSMaxY(bounds);
            default:  return NSWidth(pageBounds) * (NSMaxY(pageBounds) - ceil(NSMaxY(bounds))) + NSMinX(bounds);
        }
    }
}

#pragma mark Scripting support

- (NSScriptObjectSpecifier *)objectSpecifier {
    NSDocument *document = [self containingDocument];
	NSUInteger idx = [self pageIndex];
    
    if (document && idx != NSNotFound) {
        NSScriptObjectSpecifier *containerRef = [document objectSpecifier];
        return [[[NSIndexSpecifier allocWithZone:[self zone]] initWithContainerClassDescription:[containerRef keyClassDescription] containerSpecifier:containerRef key:@"pages" index:idx] autorelease];
    } else {
        return nil;
    }
}

- (NSDocument *)containingDocument {
    NSDocument *document = nil;
    
    for (document in [[NSDocumentController sharedDocumentController] documents]) {
        if ([[self document] isEqual:[document pdfDocument]])
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
    if ([self isEditable] && angle != [self rotation]) {
        NSUndoManager *undoManager = [[self containingDocument] undoManager];
        [(PDFPage *)[undoManager prepareWithInvocationTarget:self] setRotationAngle:[self rotation]];
        [undoManager setActionName:NSLocalizedString(@"Rotate Page", @"Undo action name")];
        // this will dirty the document, even though no saveable change has been made
        // but we cannot undo the document change count because there may be real changes to the document in the script
        
        [self setRotation:angle];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:SKPDFPageBoundsDidChangeNotification 
                object:[self document] userInfo:[NSDictionary dictionaryWithObjectsAndKeys:SKPDFPageActionKey, SKPDFPageActionKey, self, SKPDFPagePageKey, nil]];
    }
}

- (NSData *)boundsAsQDRect {
    return [NSData dataWithRectAsQDRect:[self boundsForBox:kPDFDisplayBoxCropBox]];
}

- (void)setBoundsAsQDRect:(NSData *)inQDBoundsAsData {
    if ([self isEditable] && inQDBoundsAsData && [inQDBoundsAsData isEqual:[NSNull null]] == NO) {
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
                object:[self document] userInfo:[NSDictionary dictionaryWithObjectsAndKeys:SKPDFPageActionCrop, SKPDFPageActionKey, self, SKPDFPagePageKey, nil]];
    }
}

- (NSData *)mediaBoundsAsQDRect {
    return [NSData dataWithRectAsQDRect:[self boundsForBox:kPDFDisplayBoxMediaBox]];
}

- (void)setMediaBoundsAsQDRect:(NSData *)inQDBoundsAsData {
    if ([self isEditable] && inQDBoundsAsData && [inQDBoundsAsData isEqual:[NSNull null]] == NO) {
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
                object:[self document] userInfo:[NSDictionary dictionaryWithObjectsAndKeys:SKPDFPageActionResize, SKPDFPageActionKey, self, SKPDFPagePageKey, nil]];
    }
}

- (NSData *)contentBoundsAsQDRect {
    return [NSData dataWithRectAsQDRect:[self foregroundBox]];
}

- (NSArray *)lineBoundsAsQDRects {
    NSPointerArray *lineRects = [self lineRects];
    NSMutableArray *lineBounds = [NSMutableArray array];
    NSInteger i, count = [lineRects count];
    for (i = 0; i < count; i++)
        [lineBounds addObject:[NSData dataWithRectAsQDRect:[lineRects rectAtIndex:i]]];
    return lineBounds;
}

- (NSTextStorage *)richText {
    NSAttributedString *attrString = [self attributedString];
    return attrString ? [[[NSTextStorage alloc] initWithAttributedString:attrString] autorelease] : [[[NSTextStorage alloc] init] autorelease];
}

- (NSArray *)notes {
    NSMutableArray *notes = [NSMutableArray array];
    
    for (PDFAnnotation *annotation in [self annotations]) {
        if ([annotation isSkimNote])
            [notes addObject:annotation];
    }
    return notes;
}

- (id)valueInNotesWithUniqueID:(NSString *)aUniqueID {
    for (PDFAnnotation *annotation in [self annotations]) {
        if ([[annotation uniqueID] isEqualToString:aUniqueID])
            return annotation;
    }
    return nil;
}

- (void)insertObject:(id)newNote inNotesAtIndex:(NSUInteger)anIndex {
    if ([self isEditable]) {
        SKPDFView *pdfView = [(SKMainDocument *)[self containingDocument] pdfView];
        
        [pdfView addAnnotation:newNote toPage:self];
        [[pdfView undoManager] setActionName:NSLocalizedString(@"Add Note", @"Undo action name")];
    }
}

- (void)removeObjectFromNotesAtIndex:(NSUInteger)anIndex {
    if ([self isEditable]) {
        PDFAnnotation *note = [[self notes] objectAtIndex:anIndex];
        SKPDFView *pdfView = [(SKMainDocument *)[self containingDocument] pdfView];
        
        [pdfView removeAnnotation:note];
        [[pdfView undoManager] setActionName:NSLocalizedString(@"Remove Note", @"Undo action name")];
    }
}

- (id)newScriptingObjectOfClass:(Class)class forValueForKey:(NSString *)key withContentsValue:(id)contentsValue properties:(NSDictionary *)properties {
    if ([key isEqualToString:@"notes"]) {
        PDFAnnotation *annotation = nil;
        NSMutableDictionary *props = [[properties mutableCopy] autorelease];
        
        NSRect bounds = NSZeroRect;
        bounds.size.width = [[NSUserDefaults standardUserDefaults] floatForKey:SKDefaultNoteWidthKey];
        bounds.size.height = [[NSUserDefaults standardUserDefaults] floatForKey:SKDefaultNoteHeightKey];
        bounds = NSIntegralRect(SKRectFromCenterAndSize(SKIntegralPoint(SKCenterPoint([self boundsForBox:kPDFDisplayBoxCropBox])), bounds.size));
        
        NSString *type = [properties objectForKey:SKNPDFAnnotationTypeKey];
        [props removeObjectForKey:SKNPDFAnnotationTypeKey];
        if (type == nil && contentsValue)
            type = SKNHighlightString;
        
        if ([type isEqualToString:SKNHighlightString] || [type isEqualToString:SKNStrikeOutString] || [type isEqualToString:SKNUnderlineString ]) {
            id selSpec = contentsValue ?: [properties objectForKey:SKPDFAnnotationSelectionSpecifierKey];
            PDFSelection *selection;
            NSInteger markupType = 0;
            [props removeObjectForKey:SKPDFAnnotationSelectionSpecifierKey];
            if (selSpec == nil) {
                [[NSScriptCommand currentCommand] setScriptErrorNumber:NSRequiredArgumentsMissingScriptError]; 
                [[NSScriptCommand currentCommand] setScriptErrorString:NSLocalizedString(@"New markup notes need a selection.", @"Error description")];
            } else if ((selection = [PDFSelection selectionWithSpecifier:selSpec])) {
                if ([type isEqualToString:SKNHighlightString])
                    markupType = kPDFMarkupTypeHighlight;
                else if ([type isEqualToString:SKNUnderlineString])
                    markupType = kPDFMarkupTypeUnderline;
                else if ([type isEqualToString:SKNStrikeOutString])
                    markupType = kPDFMarkupTypeStrikeOut;
                annotation = [[PDFAnnotationMarkup alloc] initSkimNoteWithSelection:selection markupType:markupType];
            }
        } else if ([type isEqualToString:SKNInkString]) {
            NSArray *pointLists = [properties objectForKey:SKPDFAnnotationScriptingPointListsKey];
            [props removeObjectForKey:SKPDFAnnotationScriptingPointListsKey];
            if ([pointLists isKindOfClass:[NSArray class]] == NO) {
                [[NSScriptCommand currentCommand] setScriptErrorNumber:NSRequiredArgumentsMissingScriptError]; 
                [[NSScriptCommand currentCommand] setScriptErrorString:NSLocalizedString(@"New markup notes need a selection.", @"Error description")];
            } else {
                NSMutableArray *paths = [[NSMutableArray alloc] initWithCapacity:[pointLists count]];
                for (NSArray *list in pointLists) {
                    if ([list isKindOfClass:[NSArray class]]) {
                        NSBezierPath *path = [[NSBezierPath alloc] init];
                        for (id pt in list) {
                            NSPoint point;
                            if ([pt isKindOfClass:[NSData class]]) {
                                point = [pt pointValueAsQDPoint];
                            } else if ([pt isKindOfClass:[NSArray class]] && [pt count] == 2) {
                                Point qdPoint;
                                qdPoint.v = [[pt objectAtIndex:0] intValue];
                                qdPoint.h = [[pt objectAtIndex:1] intValue];
                                point = SKNSPointFromQDPoint(qdPoint);
                            } else continue;
                            [PDFAnnotationInk addPoint:point toSkimNotesPath:path];
                        }
                        if ([path elementCount] > 1)
                            [paths addObject:path];
                        [path release];
                    }
                }
                annotation = [[PDFAnnotationInk alloc] initSkimNoteWithPaths:paths];
                [paths release];
            }
        } else if ([type isEqualToString:SKNFreeTextString]) {
            annotation = [[PDFAnnotationFreeText alloc] initSkimNoteWithBounds:bounds];
        } else if ([type isEqualToString:SKNNoteString]) {
            bounds.size = SKNPDFAnnotationNoteSize;
            annotation = [[SKNPDFAnnotationNote alloc] initSkimNoteWithBounds:bounds];
        } else if ([type isEqualToString:SKNCircleString]) {
            annotation = [[PDFAnnotationCircle alloc] initSkimNoteWithBounds:bounds];
        } else if ([type isEqualToString:SKNSquareString]) {
            annotation = [[PDFAnnotationSquare alloc] initSkimNoteWithBounds:bounds];
        } else if ([type isEqualToString:SKNLineString]) {
            annotation = [[PDFAnnotationLine alloc] initSkimNoteWithBounds:bounds];
        } else {
            [[NSScriptCommand currentCommand] setScriptErrorNumber:NSRequiredArgumentsMissingScriptError]; 
            [[NSScriptCommand currentCommand] setScriptErrorString:NSLocalizedString(@"New notes need a type.", @"Error description")];
        }

        if (annotation) {
            [annotation registerUserName];
            if ([props count])
                [annotation setScriptingProperties:[annotation coerceValue:props forKey:@"scriptingProperties"]];
        }
        return annotation;
    }
    return [super newScriptingObjectOfClass:class forValueForKey:key withContentsValue:contentsValue properties:properties];
}

- (id)copyScriptingValue:(id)value forKey:(NSString *)key withProperties:(NSDictionary *)properties {
    if ([key isEqualToString:@"notes"]) {
        NSMutableArray *copiedValue = [[NSMutableArray alloc] init];
        for (PDFAnnotation *annotation in value) {
            if ([annotation isMovable]) {
                PDFAnnotation *copiedAnnotation = [[PDFAnnotation alloc] initSkimNoteWithProperties:[annotation SkimNoteProperties]];
                [copiedAnnotation registerUserName];
                if ([properties count])
                    [copiedAnnotation setScriptingProperties:[copiedAnnotation coerceValue:properties forKey:@"scriptingProperties"]];
                [copiedValue addObject:copiedAnnotation];
            } else {
                // we don't want to duplicate markup
                NSScriptCommand *cmd = [NSScriptCommand currentCommand];
                [cmd setScriptErrorNumber:NSReceiversCantHandleCommandScriptError];
                [cmd setScriptErrorString:@"Cannot duplicate markup note."];
                SKDESTROY(copiedValue);
            }
        }
        return copiedValue;
    }
    return [super copyScriptingValue:value forKey:key withProperties:properties];
}

- (id)handleGrabScriptCommand:(NSScriptCommand *)command {
	NSDictionary *args = [command evaluatedArguments];
    NSData *boundsData = [args objectForKey:@"Bounds"];
    id asTIFFNumber = [args objectForKey:@"AsTIFF"];
    id asTypeNumber = [args objectForKey:@"Type"];
    NSRect bounds = [boundsData respondsToSelector:@selector(rectValueAsQDRect)] ? [boundsData rectValueAsQDRect] : NSZeroRect;
    FourCharCode asType = [asTypeNumber respondsToSelector:@selector(unsignedIntValue)] ? [asTypeNumber unsignedIntValue] : 0; 
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
