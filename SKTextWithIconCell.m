//
//  SKTextWithIconCell.m
//  Skim
//
//  Created by Christiaan Hofman on 9/13/07.
/*
 This software is Copyright (c) 2007-2008
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

#import "SKTextWithIconCell.h"
#import "NSImage_SKExtensions.h"
#import "NSGeometry_SKExtensions.h"

// Almost all of this code is copy-and-paste from OmniAppKit/OATextWithIconCell, with some simplifications for features we're not interested in

NSString *SKTextWithIconCellImageKey = @"image";
NSString *SKTextWithIconCellStringKey = @"string";

#define BORDER_BETWEEN_EDGE_AND_IMAGE (2.0)
#define BORDER_BETWEEN_IMAGE_AND_TEXT (2.0)

@implementation SKTextWithIconCell

// Init and dealloc

- (id)init {
    if (self = [super initTextCell:@""]) {
        [self setEditable:YES];
        [self setScrollable:YES];
    }
    return self;
}

- (void)dealloc {
    [icon release];
    [super dealloc];
}

// NSCopying protocol

- (id)copyWithZone:(NSZone *)zone {
    SKTextWithIconCell *copy = [super copyWithZone:zone];
    copy->icon = [icon retain];
    return copy;
}

- (NSSize)cellSize {
    NSSize cellSize = [super cellSize];
    cellSize.width += [icon size].width + BORDER_BETWEEN_EDGE_AND_IMAGE + BORDER_BETWEEN_IMAGE_AND_TEXT;
    return cellSize;
}

- (NSRect)textRectForBounds:(NSRect)aRect {
    float imageWidth = NSHeight(aRect) - 1;
    NSRect ignored, textRect = aRect;
    
    NSDivideRect(aRect, &ignored, &textRect, BORDER_BETWEEN_EDGE_AND_IMAGE + imageWidth + BORDER_BETWEEN_IMAGE_AND_TEXT, NSMinXEdge);
    
    return textRect;
}

- (NSRect)iconRectForBounds:(NSRect)aRect {
    float imageWidth = NSHeight(aRect) - 1;
    NSRect ignored, imageRect = aRect;
    
    NSDivideRect(aRect, &ignored, &imageRect, BORDER_BETWEEN_EDGE_AND_IMAGE, NSMinXEdge);
    NSDivideRect(imageRect, &imageRect, &ignored, imageWidth, NSMinXEdge);
    
    return imageRect;
}

- (void)drawIconWithFrame:(NSRect)iconRect inView:(NSView *)controlView
{
    NSImage *img = [self icon];
    
    if (nil != img) {
        
        NSRect srcRect = NSZeroRect;
        srcRect.size = [img size];
        
        NSRect drawFrame = iconRect;
        
        // NSImage will use the largest rep if it doesn't find an exact size match; we can improve on that by choosing the next larger one with respect to our drawing rect, and scaling it down.
        NSBitmapImageRep *rep = [img bestImageRepForSize:drawFrame.size device:nil];
        
        // draw the image rep directly to avoid creating a new NSImage and adding the rep to it
        if (0 && rep) {
            
            srcRect.size = [rep size];
            float ratio = fminf(NSWidth(drawFrame) / srcRect.size.width, NSHeight(drawFrame) / srcRect.size.height);
            drawFrame.size.width = ratio * srcRect.size.width;
            drawFrame.size.height = ratio * srcRect.size.height;
            
            drawFrame = SKCenterRect(drawFrame, drawFrame.size, [controlView isFlipped]);
            
            CGContextRef context = [[NSGraphicsContext currentContext] graphicsPort];
            CGContextSaveGState(context);
            CGContextClipToRect(context, *(CGRect *)&drawFrame);
            CGContextSetAllowsAntialiasing(context, true);
            CGContextSetInterpolationQuality(context, kCGInterpolationHigh);
            
            // draw into a new layer so we preserve the background of the tableview
            CGContextBeginTransparencyLayer(context, NULL);
            
            if ([controlView isFlipped]) {
                CGContextTranslateCTM(context, 0, NSMaxY(drawFrame));
                CGContextScaleCTM(context, 1, -1);
                drawFrame.origin.y = 0;
                [rep drawInRect:drawFrame];
            } else {
                [rep drawInRect:drawFrame];
            }
            
            CGContextEndTransparencyLayer(context);
            CGContextRestoreGState(context);
            
        } else {
            
            float ratio = MIN(NSWidth(drawFrame) / srcRect.size.width, NSHeight(drawFrame) / srcRect.size.height);
            drawFrame.size.width = ratio * srcRect.size.width;
            drawFrame.size.height = ratio * srcRect.size.height;
            
            drawFrame = SKCenterRect(drawFrame, drawFrame.size, [controlView isFlipped]);
            
            NSGraphicsContext *ctxt = [NSGraphicsContext currentContext];
            [ctxt saveGraphicsState];
            
            // this is the critical part that NSImageCell doesn't do
            [ctxt setImageInterpolation:NSImageInterpolationHigh];
            
            [img drawFlipped:[controlView isFlipped] inRect:drawFrame fromRect:srcRect operation:NSCompositeSourceOver fraction:1.0];
            
            [ctxt restoreGraphicsState];
        }
    }
}

- (void)drawWithFrame:(NSRect)aRect inView:(NSView *)controlView {
    // let super draw the text, but vertically center the text for tall cells, because NSTextFieldCell aligns at the top
    NSRect textRect = [self textRectForBounds:aRect];
    if (NSHeight(textRect) > [self cellSize].height + 2.0)
        textRect = SKCenterRectVertically(textRect, [self cellSize].height + 2.0, [controlView isFlipped]);
    [super drawWithFrame:textRect inView:controlView];
    
    // Draw the image
    NSRect imageRect = [self iconRectForBounds:aRect];
    float imageHeight = 0.0;
    imageHeight = NSHeight(aRect) - 1;
    imageRect = SKCenterRectVertically(imageRect, imageHeight, [controlView isFlipped]);
    [self drawIconWithFrame:imageRect inView:controlView];
}

- (void)selectWithFrame:(NSRect)aRect inView:(NSView *)controlView editor:(NSText *)textObj delegate:(id)anObject start:(int)selStart length:(int)selLength {
    [super selectWithFrame:[self textRectForBounds:aRect] inView:controlView editor:textObj delegate:anObject start:selStart length:selLength];
}

- (void)setObjectValue:(id<NSCopying>)obj {
    NSImage *image;
    NSString *string;
    @try {
        image = [(id)obj valueForKey:SKTextWithIconCellImageKey];
        string = [(id)obj valueForKey:SKTextWithIconCellStringKey];
        [self setIcon:image];
        [super setObjectValue:string];
    }
    @catch (id exception) {
        [super setObjectValue:obj];
    }
}

// API

- (NSImage *)icon {
    return icon;
}

- (void)setIcon:(NSImage *)anIcon {
    if (anIcon != icon) {
        [icon release];
        icon = [anIcon retain];
    }
}

@end
