//
//  SKReadingBar.m
//  Skim
//
//  Created by Christiaan Hofman on 3/30/07.
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

#import "SKReadingBar.h"
#import "PDFPage_SKExtensions.h"


@implementation SKReadingBar

- (id)initWithPage:(PDFPage *)aPage {
    if (self = [super init]) {
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
    [page release];
    [lineRects release];
    [super dealloc];
}

- (PDFPage *)page {
    return page;
}

- (void)setPage:(PDFPage *)newPage {
    if (page != newPage) {
        [page release];
        page = [newPage retain];
        [lineRects release];
        lineRects = [[page lineRects] retain];
        currentLine = -1;
    } 
}

- (int)currentLine {
    return currentLine;
}

- (void)setCurrentLine:(int)lineIndex {
    currentLine = lineIndex;
}

- (int)currentLastLine {
    return MIN([lineRects count], currentLine + numberOfLines) - 1;
}

- (unsigned int)numberOfLines {
    return numberOfLines;
}

- (void)setNumberOfLines:(unsigned int)number {
    numberOfLines = number;
}

- (NSRect)currentBounds {
    if (page == nil || currentLine == -1)
        return NSZeroRect;
    NSRect rect = NSZeroRect;
    int i, lastLine = [self currentLastLine];
    for (i = currentLine; i <= lastLine; i++)
        rect = NSUnionRect(rect, [[lineRects objectAtIndex:i] rectValue]);
    return rect;
}

- (NSRect)currentBoundsForBox:(PDFDisplayBox)box {
    if (page == nil || currentLine == -1)
        return NSZeroRect;
    NSRect rect = [self currentBounds];
    NSRect bounds = [page boundsForBox:box];
    rect.origin.x = NSMinX(bounds);
    rect.size.width = NSWidth(bounds);
    return rect;
}

- (BOOL)goToNextLine {
    BOOL didMove = NO;
    if (currentLine < (int)[lineRects count] - (int)numberOfLines) {
        ++currentLine;
        didMove = YES;
    } else if ([self goToNextPage]) {
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
        didMove =  YES;
    } else if ([self goToPreviousPage]) {
        currentLine = MAX(0, (int)[lineRects count] - (int)numberOfLines);
        didMove = YES;
    }
    return didMove;
}

- (BOOL)goToNextPage {
    BOOL didMove = NO;
    PDFDocument *doc = [page document];
    int i = [page pageIndex], iMax = [doc pageCount];
    
    while (++i < iMax) {
        PDFPage *nextPage = [doc pageAtIndex:i];
        NSArray *lines = [nextPage lineRects];
        if ([lines count]) {
            [page release];
            page = [nextPage retain];
            [lineRects release];
            lineRects = [lines retain];
            currentLine = 0;
            didMove = YES;
            break;
        }
    }
    return didMove;
}

- (BOOL)goToPreviousPage {
    BOOL didMove = NO;
    PDFDocument *doc = [page document];
    int i = [doc indexForPage:page];
    
    while (i-- > 0) {
        PDFPage *prevPage = [doc pageAtIndex:i];
        NSArray *lines = [prevPage lineRects];
        if ([lines count]) {
            [page release];
            page = [prevPage retain];
            [lineRects release];
            lineRects = [lines retain];
            currentLine = 0;
            didMove = YES;
            break;
        }
    }
    return didMove;
}

@end
