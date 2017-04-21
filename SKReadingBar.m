//
//  SKReadingBar.m
//  Skim
//
//  Created by Christiaan Hofman on 3/30/07.
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

#import "SKReadingBar.h"
#import "PDFPage_SKExtensions.h"
#import "SKStringConstants.h"
#import "NSGeometry_SKExtensions.h"
#import "NSUserDefaults_SKExtensions.h"
#import "NSPointerArray_SKExtensions.h"


@implementation SKReadingBar

@synthesize currentLine, numberOfLines;
@dynamic page, currentLastLine, currentBounds;

- (id)initWithPage:(PDFPage *)aPage {
    self = [super init];
    if (self) {
        numberOfLines = 1;
        lineRects = nil;
        currentLine = -1;
        [self setPage:aPage];
    }
    return self;
}

- (id)init {
    return [self initWithPage:nil];
}

- (void)dealloc {
    SKDESTROY(page);
    SKDESTROY(lineRects);
    [super dealloc];
}

- (PDFPage *)page {
    PDFPage *aPage = nil;
    @synchronized (self) {
        aPage = [page retain];
    }
    return [aPage autorelease];
}

- (void)setPage:(PDFPage *)newPage {
    @synchronized (self) {
        if (page != newPage) {
            [page release];
            page = [newPage retain];
            [lineRects release];
            lineRects = [[page lineRects] retain];
            currentLine = -1;
            currentBounds = NSZeroRect;
        }
    }
}

- (NSInteger)currentLastLine {
    return MIN([lineRects count], currentLine + numberOfLines) - 1;
}

- (void)updateCurrentBounds {
    NSRect rect = NSZeroRect;
    if (currentLine >= 0) {
        NSInteger i, lastLine = [self currentLastLine];
        for (i = currentLine; i <= lastLine; i++)
            rect = NSUnionRect(rect, [lineRects rectAtIndex:i]);
    }
    @synchronized (self) {
        currentBounds = page == nil ? NSZeroRect : rect;
    }
}

- (void)setCurrentLine:(NSInteger)line {
    currentLine = line;
    [self updateCurrentBounds];
}

- (void)setNumberOfLines:(NSUInteger)number {
    numberOfLines = number;
    [self updateCurrentBounds];
}

- (NSRect)currentBounds {
    NSRect bounds;
    @synchronized (self) {
        bounds = currentBounds;
    }
    return bounds;
}

- (NSRect)currentBoundsForBox:(PDFDisplayBox)box {
    NSRect rect, bounds;
    BOOL rotated;
    @synchronized (self) {
        rect = currentBounds;
        bounds = [page boundsForBox:box];
        rotated = ([page intrinsicRotation] % 180) != 0;
    }
    if (NSEqualRects(rect, NSZeroRect))
        return NSZeroRect;
    if (rotated) {
        rect.origin.y = NSMinY(bounds);
        rect.size.height = NSHeight(bounds);
    } else {
        rect.origin.x = NSMinX(bounds);
        rect.size.width = NSWidth(bounds);
    }
    return rect;
}

- (BOOL)goToNextPageAtTop:(BOOL)atTop {
    BOOL didMove = NO;
    PDFDocument *doc = [page document];
    NSInteger i = [page pageIndex], iMax = [doc pageCount];
    
    while (++i < iMax) {
        PDFPage *nextPage = [doc pageAtIndex:i];
        NSPointerArray *lines = [nextPage lineRects];
        if ([lines count]) {
            @synchronized (self) {
                [page release];
                page = [nextPage retain];
            }
            [lineRects release];
            lineRects = [lines retain];
            currentLine = atTop ? 0 : MAX(0, (NSInteger)[lineRects count] - (NSInteger)numberOfLines);
            [self updateCurrentBounds];
            didMove = YES;
            break;
        }
    }
    return didMove;
}

- (BOOL)goToPreviousPageAtTop:(BOOL)atTop {
    BOOL didMove = NO;
    PDFDocument *doc = [page document];
    NSInteger i = [doc indexForPage:page];
    
    while (i-- > 0) {
        PDFPage *prevPage = [doc pageAtIndex:i];
        NSPointerArray *lines = [prevPage lineRects];
        if ([lines count]) {
            @synchronized (self) {
                [page release];
                page = [prevPage retain];
            }
            [lineRects release];
            lineRects = [lines retain];
            currentLine = atTop ? 0 : MAX(0, (NSInteger)[lineRects count] - (NSInteger)numberOfLines);
            [self updateCurrentBounds];
            didMove = YES;
            break;
        }
    }
    return didMove;
}

- (BOOL)goToNextLine {
    BOOL didMove = NO;
    if (currentLine < (NSInteger)[lineRects count] - (NSInteger)numberOfLines) {
        ++currentLine;
        [self updateCurrentBounds];
        didMove = YES;
    } else if ([self goToNextPageAtTop:YES]) {
        didMove = YES;
    }
    return didMove;
}

- (BOOL)goToPreviousLine {
    BOOL didMove = NO;
    if (currentLine == -1 && [lineRects count])
        currentLine = [lineRects count];
    if (currentLine > 0) {
        --currentLine;
        [self updateCurrentBounds];
        didMove =  YES;
    } else if ([self goToPreviousPageAtTop:NO]) {
        didMove = YES;
    }
    return didMove;
}

- (BOOL)goToNextPage {
    return [self goToNextPageAtTop:YES];
}

- (BOOL)goToPreviousPage {
    return [self goToPreviousPageAtTop:YES];
}

static inline BOOL topAbovePoint(NSRect rect, NSPoint point, NSInteger rotation) {
    switch (rotation) {
        case 0:   return NSMaxY(rect) >= point.y;
        case 90:  return NSMinX(rect) <= point.x;
        case 180: return NSMinY(rect) <= point.y;
        case 270: return NSMaxX(rect) >= point.x;
        default:  return NSMaxY(rect) >= point.x;
    }
}

- (BOOL)goToLineForPoint:(NSPoint)point {
    if ([lineRects count] == 0)
        return NO;
    NSInteger i = [lineRects count] - numberOfLines;
    NSInteger rotation = [page intrinsicRotation];
    while (--i >= 0)
        if (topAbovePoint([lineRects rectAtIndex:i], point, rotation)) break;
    currentLine = MAX(0, i);
    [self updateCurrentBounds];
    return YES;
}

- (void)drawForPage:(PDFPage *)pdfPage withBox:(PDFDisplayBox)box inContext:(CGContextRef)context {
    BOOL invert = [[NSUserDefaults standardUserDefaults] boolForKey:SKReadingBarInvertKey];
    
    CGContextSaveGState(context);
    
    CGContextSetFillColorWithColor(context, [[[NSUserDefaults standardUserDefaults] colorForKey:SKReadingBarColorKey] CGColor]);
    
    if ([[self page] isEqual:pdfPage]) {
        NSRect rect = [self currentBoundsForBox:box];
        if (invert) {
            NSRect bounds = [pdfPage boundsForBox:box];
            if (NSEqualRects(rect, NSZeroRect)) {
                CGContextFillRect(context, NSRectToCGRect(bounds));
            } else if (([pdfPage intrinsicRotation] % 180)) {
                CGContextFillRect(context, NSRectToCGRect(SKSliceRect(bounds, NSMaxX(bounds) - NSMaxX(rect), NSMaxXEdge)));
                CGContextFillRect(context, NSRectToCGRect(SKSliceRect(bounds, NSMinX(rect) - NSMinX(bounds), NSMinXEdge)));
            } else {
                CGContextFillRect(context, NSRectToCGRect(SKSliceRect(bounds, NSMaxY(bounds) - NSMaxY(rect), NSMaxYEdge)));
                CGContextFillRect(context, NSRectToCGRect(SKSliceRect(bounds, NSMinY(rect) - NSMinY(bounds), NSMinYEdge)));
            }
        } else {
            CGContextSetBlendMode(context, kCGBlendModeMultiply);
            CGContextFillRect(context, NSRectToCGRect(rect));
        }
    } else if (invert) {
        CGContextFillRect(context, NSRectToCGRect([pdfPage boundsForBox:box]));
    }
    
    
    CGContextRestoreGState(context);
}

@end
