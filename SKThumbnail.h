//
//  SKThumbnail.h
//  Skim
//
//  Created by Christiaan Hofman on 2/16/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface SKThumbnail : NSObject {
    NSImage *image;
    NSString *label;
    unsigned int pageIndex;
    id controller;
}

- (id)initWithImage:(NSImage *)anImage label:(NSString *)aLabel;

- (NSImage *)image;
- (void)setImage:(NSImage *)newImage;

- (NSString *)label;
- (void)setLabel:(NSString *)newLabel;

- (unsigned int)pageIndex;
- (void)setPageIndex:(unsigned int)newPageIndex;

- (id)controller;
- (void)setController:(id)newController;

@end
