//
//  SKThumbnail.m
//  Skim
//
//  Created by Christiaan Hofman on 2/16/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "SKThumbnail.h"


@implementation SKThumbnail

- (id)initWithImage:(NSImage *)anImage label:(NSString *)aLabel {
    if (self = [super init]) {
        image = [anImage retain];
        label = [aLabel retain];
        pageIndex = 0;
        controller = nil;
    }
    return self;
}

- (void)dealloc {
    [image release];
    [label release];
    [controller release];
    [super dealloc];
}

- (NSImage *)image {
    return image;
}

- (void)setImage:(NSImage *)newImage {
    if (image != newImage) {
        [image release];
        image = [newImage retain];
    }
}

- (NSString *)label {
    return label;
}

- (void)setLabel:(NSString *)newLabel {
    if (label != newLabel) {
        [label release];
        label = [newLabel retain];
    }
}

- (unsigned int)pageIndex {
    return pageIndex;
}

- (void)setPageIndex:(unsigned int)newPageIndex {
    if (pageIndex != newPageIndex) {
        pageIndex = newPageIndex;
    }
}

- (id)controller {
    return controller;
}

- (void)setController:(id)newController {
    if (controller != newController) {
        [controller release];
        controller = [newController retain];
    }
}

@end
