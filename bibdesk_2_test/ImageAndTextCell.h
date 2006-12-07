//
//  ImageAndTextCell.h
//
//  Copyright (c) 2001-2002, Apple. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface ImageAndTextCell : NSTextFieldCell {
@private
    NSImage	*leftImage;
}

- (void)setLeftImage:(NSImage *)anImage;
- (NSImage *)leftImage;

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView;
- (NSSize)cellSize;

@end
