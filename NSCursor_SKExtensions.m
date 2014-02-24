//
//  NSCursor_SKExtensions.m
//  Skim
//
//  Created by Christiaan Hofman on 2/16/07.
/*
 This software is Copyright (c) 2007-2014
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

#import "NSCursor_SKExtensions.h"
#import "NSImage_SKExtensions.h"


@implementation NSCursor (SKExtensions)

+ (NSCursor *)zoomInCursor {
    static NSCursor *zoomInCursor = nil;
    if (nil == zoomInCursor) {
        NSImage *cursorImage = [[[NSImage imageNamed:SKImageNameZoomInCursor] copy] autorelease];
        zoomInCursor = [[NSCursor alloc] initWithImage:cursorImage hotSpot:NSMakePoint(6.0, 6.0)];
    }
    return zoomInCursor;
}

+ (NSCursor *)zoomOutCursor {
    static NSCursor *zoomOutCursor = nil;
    if (nil == zoomOutCursor) {
        NSImage *cursorImage = [[[NSImage imageNamed:SKImageNameZoomOutCursor] copy] autorelease];
        zoomOutCursor = [[NSCursor alloc] initWithImage:cursorImage hotSpot:NSMakePoint(6.0, 6.0)];
    }
    return zoomOutCursor;
}

+ (NSCursor *)resizeDiagonal45Cursor {
    static NSCursor *resizeDiagonal45Cursor = nil;
    if (nil == resizeDiagonal45Cursor) {
        NSImage *cursorImage = [[[NSImage imageNamed:SKImageNameResizeDiagonal45Cursor] copy] autorelease];
        resizeDiagonal45Cursor = [[NSCursor alloc] initWithImage:cursorImage hotSpot:NSMakePoint(8.0, 8.0)];
    }
    return resizeDiagonal45Cursor;
}

+ (NSCursor *)resizeDiagonal135Cursor {
    static NSCursor *resizeDiagonal135Cursor = nil;
    if (nil == resizeDiagonal135Cursor) {
        NSImage *cursorImage = [[[NSImage imageNamed:SKImageNameResizeDiagonal135Cursor] copy] autorelease];
        resizeDiagonal135Cursor = [[NSCursor alloc] initWithImage:cursorImage hotSpot:NSMakePoint(8.0, 8.0)];
    }
    return resizeDiagonal135Cursor;
}

+ (NSCursor *)cameraCursor {
    static NSCursor *cameraCursor = nil;
    if (nil == cameraCursor) {
        NSImage *cursorImage = [[[NSImage imageNamed:SKImageNameCameraCursor] copy] autorelease];
        cameraCursor = [[NSCursor alloc] initWithImage:cursorImage hotSpot:NSMakePoint(8.0, 8.0)];
    }
    return cameraCursor;
}

+ (NSCursor *)openHandBarCursor {
    static NSCursor *openHandBarCursor = nil;
    if (nil == openHandBarCursor) {
        NSImage *cursorImage = [[[NSImage imageNamed:SKImageNameOpenHandBarCursor] copy] autorelease];
        openHandBarCursor = [[NSCursor alloc] initWithImage:cursorImage hotSpot:[[self openHandCursor] hotSpot]];
    }
    return openHandBarCursor;
}

+ (NSCursor *)closedHandBarCursor {
    static NSCursor *closedHandBarCursor = nil;
    if (nil == closedHandBarCursor) {
        NSImage *cursorImage = [[[NSImage imageNamed:SKImageNameClosedHandBarCursor] copy] autorelease];
        closedHandBarCursor = [[NSCursor alloc] initWithImage:cursorImage hotSpot:[[self closedHandCursor] hotSpot]];
    }
    return closedHandBarCursor;
}

+ (NSCursor *)textNoteCursor {
    static NSCursor *textNoteCursor = nil;
    if (nil == textNoteCursor) {
        NSImage *cursorImage = [[[NSImage imageNamed:SKImageNameTextNoteCursor] copy] autorelease];
        textNoteCursor = [[NSCursor alloc] initWithImage:cursorImage hotSpot:[[self arrowCursor] hotSpot]];
    }
    return textNoteCursor;
}

+ (NSCursor *)anchoredNoteCursor {
    static NSCursor *anchoredNoteCursor = nil;
    if (nil == anchoredNoteCursor) {
        NSImage *cursorImage = [[[NSImage imageNamed:SKImageNameAnchoredNoteCursor] copy] autorelease];
        anchoredNoteCursor = [[NSCursor alloc] initWithImage:cursorImage hotSpot:[[self arrowCursor] hotSpot]];
    }
    return anchoredNoteCursor;
}

+ (NSCursor *)circleNoteCursor {
    static NSCursor *circleNoteCursor = nil;
    if (nil == circleNoteCursor) {
        NSImage *cursorImage = [[[NSImage imageNamed:SKImageNameCircleNoteCursor] copy] autorelease];
        circleNoteCursor = [[NSCursor alloc] initWithImage:cursorImage hotSpot:[[self arrowCursor] hotSpot]];
    }
    return circleNoteCursor;
}

+ (NSCursor *)squareNoteCursor {
    static NSCursor *squareNoteCursor = nil;
    if (nil == squareNoteCursor) {
        NSImage *cursorImage = [[[NSImage imageNamed:SKImageNameSquareNoteCursor] copy] autorelease];
        squareNoteCursor = [[NSCursor alloc] initWithImage:cursorImage hotSpot:[[self arrowCursor] hotSpot]];
    }
    return squareNoteCursor;
}

+ (NSCursor *)highlightNoteCursor {
    static NSCursor *highlightNoteCursor = nil;
    if (nil == highlightNoteCursor) {
        NSImage *cursorImage = [[[NSImage imageNamed:SKImageNameHighlightNoteCursor] copy] autorelease];
        highlightNoteCursor = [[NSCursor alloc] initWithImage:cursorImage hotSpot:[[self arrowCursor] hotSpot]];
    }
    return highlightNoteCursor;
}

+ (NSCursor *)underlineNoteCursor {
    static NSCursor *underlineNoteCursor = nil;
    if (nil == underlineNoteCursor) {
        NSImage *cursorImage = [[[NSImage imageNamed:SKImageNameUnderlineNoteCursor] copy] autorelease];
        underlineNoteCursor = [[NSCursor alloc] initWithImage:cursorImage hotSpot:[[self arrowCursor] hotSpot]];
    }
    return underlineNoteCursor;
}

+ (NSCursor *)strikeOutNoteCursor {
    static NSCursor *strikeOutNoteCursor = nil;
    if (nil == strikeOutNoteCursor) {
        NSImage *cursorImage = [[[NSImage imageNamed:SKImageNameStrikeOutNoteCursor] copy] autorelease];
        strikeOutNoteCursor = [[NSCursor alloc] initWithImage:cursorImage hotSpot:[[self arrowCursor] hotSpot]];
    }
    return strikeOutNoteCursor;
}

+ (NSCursor *)lineNoteCursor {
    static NSCursor *lineNoteCursor = nil;
    if (nil == lineNoteCursor) {
        NSImage *cursorImage = [[[NSImage imageNamed:SKImageNameLineNoteCursor] copy] autorelease];
        lineNoteCursor = [[NSCursor alloc] initWithImage:cursorImage hotSpot:[[self arrowCursor] hotSpot]];
    }
    return lineNoteCursor;
}

+ (NSCursor *)inkNoteCursor {
    static NSCursor *inkNoteCursor = nil;
    if (nil == inkNoteCursor) {
        NSImage *cursorImage = [[[NSImage imageNamed:SKImageNameInkNoteCursor] copy] autorelease];
        inkNoteCursor = [[NSCursor alloc] initWithImage:cursorImage hotSpot:[[self arrowCursor] hotSpot]];
    }
    return inkNoteCursor;
}

@end
