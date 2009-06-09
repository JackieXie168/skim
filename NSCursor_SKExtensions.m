//
//  NSCursor_SKExtensions.m
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

+ (NSCursor *)resizeLeftUpCursor {
    static NSCursor *resizeLeftUpCursor = nil;
    if (nil == resizeLeftUpCursor) {
        NSImage *cursorImage = [[[NSImage imageNamed:SKImageNameResizeLeftUpCursor] copy] autorelease];
        resizeLeftUpCursor = [[NSCursor alloc] initWithImage:cursorImage hotSpot:NSMakePoint(8.0, 8.0)];
    }
    return resizeLeftUpCursor;
}

+ (NSCursor *)resizeLeftDownCursor {
    static NSCursor *resizeLeftDownCursor = nil;
    if (nil == resizeLeftDownCursor) {
        NSImage *cursorImage = [[[NSImage imageNamed:SKImageNameResizeLeftDownCursor] copy] autorelease];
        resizeLeftDownCursor = [[NSCursor alloc] initWithImage:cursorImage hotSpot:NSMakePoint(8.0, 8.0)];
    }
    return resizeLeftDownCursor;
}

+ (NSCursor *)resizeRightUpCursor {
    static NSCursor *resizeRightUpCursor = nil;
    if (nil == resizeRightUpCursor) {
        NSImage *cursorImage = [[[NSImage imageNamed:SKImageNameResizeRightUpCursor] copy] autorelease];
        resizeRightUpCursor = [[NSCursor alloc] initWithImage:cursorImage hotSpot:NSMakePoint(8.0, 8.0)];
    }
    return resizeRightUpCursor;
}

+ (NSCursor *)resizeRightDownCursor {
    static NSCursor *resizeRightDownCursor = nil;
    if (nil == resizeRightDownCursor) {
        NSImage *cursorImage = [[[NSImage imageNamed:SKImageNameResizeRightDownCursor] copy] autorelease];
        resizeRightDownCursor = [[NSCursor alloc] initWithImage:cursorImage hotSpot:NSMakePoint(8.0, 8.0)];
    }
    return resizeRightDownCursor;
}

+ (NSCursor *)cameraCursor {
    static NSCursor *cameraCursor = nil;
    if (nil == cameraCursor) {
        NSImage *cursorImage = [[[NSImage imageNamed:@"CameraCursor"] copy] autorelease];
        cameraCursor = [[NSCursor alloc] initWithImage:cursorImage hotSpot:NSMakePoint(8.0, 8.0)];
    }
    return cameraCursor;
}

@end
