//
//  ImageBackgroundBox.m
//  bd2xtest
//
//  Created by Michael McCracken on 7/26/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "ImageBackgroundBox.h"


@implementation ImageBackgroundBox

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        backgroundImage = nil;
    }
    return self;
}

- (void)drawRect:(NSRect)rect {
    if (backgroundImage) {
        [[NSColor colorWithPatternImage:backgroundImage] set];
    } else {
		[[NSColor whiteColor] set];
	}
	NSRectFill(rect);
}

- (NSImage *)backgroundImage{
    return backgroundImage;
}

- (void)setBackgroundImage:(NSImage *)image{
	[backgroundImage autorelease];
	if (image) {
		NSRect rect = {NSZeroPoint, [image size]};
		backgroundImage = [[NSImage alloc] initWithSize:rect.size];
		[backgroundImage lockFocus];
		[[NSColor whiteColor] set];
		NSRectFill(rect);
		[image compositeToPoint:NSZeroPoint operation:NSCompositeSourceOver fraction:0.2];
		[backgroundImage unlockFocus];
	} else {
		backgroundImage = nil;
	}
}

@end
