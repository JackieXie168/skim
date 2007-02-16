//
//  NSCursor_SKExtensions.m
//  Skim
//
//  Created by Christiaan Hofman on 2/16/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "NSCursor_SKExtensions.h"


@implementation NSCursor (SKExtensions)

+ (NSCursor *)zoomInCursor {
    static NSCursor *zoomInCursor = nil;
    if (nil == zoomInCursor) {
        NSImage *cursorImage = [[[NSImage imageNamed:@"zoomInCursor"] copy] autorelease];
        zoomInCursor = [[NSCursor alloc] initWithImage:cursorImage hotSpot:NSMakePoint(6.0, 6.0)];
    }
    return zoomInCursor;
}

+ (NSCursor *)zoomOutCursor {
    static NSCursor *zoomOutCursor = nil;
    if (nil == zoomOutCursor) {
        NSImage *cursorImage = [[[NSImage imageNamed:@"zoomOutCursor"] copy] autorelease];
        zoomOutCursor = [[NSCursor alloc] initWithImage:cursorImage hotSpot:NSMakePoint(6.0, 6.0)];
    }
    return zoomOutCursor;
}

+ (NSCursor *)cameraCursor {
    NSCursor *cameraCursor = nil;
    
    if (cameraCursor == nil)
        cameraCursor = [[NSCursor alloc] initWithImage:[NSImage imageNamed:@"CameraCursor"] hotSpot:NSMakePoint(8.0, 8.0)];
    
    return cameraCursor;
}

@end
