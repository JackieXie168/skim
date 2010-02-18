//
//  SKTextWithIconCell.m
//  Skim
//
//  Created by Christiaan Hofman on 9/13/07.
/*
 This software is Copyright (c) 2007-2010
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

NSString *SKTextWithIconCellStringKey = @"string";
NSString *SKTextWithIconCellImageKey = @"image";

#define BORDER_BETWEEN_EDGE_AND_IMAGE (2.0)
#define BORDER_BETWEEN_IMAGE_AND_TEXT (2.0)
#define IMAGE_OFFSET (1.0)

@implementation SKTextWithIconCell

static SKTextWithIconFormatter *textWithIconFormatter = nil;

+ (void)initialize {
    SKINITIALIZE;
    textWithIconFormatter = [[SKTextWithIconFormatter alloc] init];
}

- (id)init {
    if (self = [super initTextCell:@""]) {
        [self setFormatter:textWithIconFormatter];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)coder {
    if (self = [super initWithCoder:coder]) {
        if ([self formatter] == nil)
            [self setFormatter:textWithIconFormatter];
    }
    return self;
}

- (NSSize)cellSize {
    NSSize cellSize = [super cellSize];
    cellSize.width += cellSize.height - 1 + BORDER_BETWEEN_EDGE_AND_IMAGE + BORDER_BETWEEN_IMAGE_AND_TEXT;
    return cellSize;
}

- (NSRect)textRectForBounds:(NSRect)aRect {
    NSRect ignored, textRect = aRect;
    
    NSDivideRect(aRect, &ignored, &textRect, NSHeight(aRect) - 1 + BORDER_BETWEEN_EDGE_AND_IMAGE + BORDER_BETWEEN_IMAGE_AND_TEXT, NSMinXEdge);
    
    return textRect;
}

- (NSRect)iconRectForBounds:(NSRect)aRect {
    CGFloat imageWidth = NSHeight(aRect) - 1;
    NSRect ignored, imageRect = aRect;
    
    NSDivideRect(aRect, &ignored, &imageRect, BORDER_BETWEEN_EDGE_AND_IMAGE, NSMinXEdge);
    NSDivideRect(imageRect, &imageRect, &ignored, imageWidth, NSMinXEdge);
    
    return imageRect;
}

- (void)drawIconWithFrame:(NSRect)iconRect inView:(NSView *)controlView
{
    NSImage *img = [self icon];
    
    if (nil != img) {
        
        NSSize imgSize = [img size];
        
        NSRect drawFrame = iconRect;
        CGFloat ratio = MIN(NSWidth(drawFrame) / imgSize.width, NSHeight(drawFrame) / imgSize.height);
        drawFrame.size.width = ratio * imgSize.width;
        drawFrame.size.height = ratio * imgSize.height;
        
        drawFrame = SKCenterRect(iconRect, drawFrame.size, [controlView isFlipped]);
        
        NSGraphicsContext *ctxt = [NSGraphicsContext currentContext];
        [ctxt saveGraphicsState];
        
        // this is the critical part that NSImageCell doesn't do
        [ctxt setImageInterpolation:NSImageInterpolationHigh];
        
        if ([controlView isFlipped]) {
            NSAffineTransform *transform = [NSAffineTransform transform];
            [transform translateXBy:0.0 yBy:NSMaxY(drawFrame)];
            [transform scaleXBy:1.0 yBy:-1.0];
            [transform translateXBy:0.0 yBy:-NSMinY(drawFrame)];
            [transform concat];
            [img drawInRect:drawFrame fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
        }
        [img drawInRect:drawFrame fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
        
        [ctxt restoreGraphicsState];
    }
}

- (void)drawInteriorWithFrame:(NSRect)aRect inView:(NSView *)controlView {
    // let super draw the text, but vertically center the text for tall cells, because NSTextFieldCell aligns at the top
    NSRect textRect = [self textRectForBounds:aRect];
    if (NSHeight(textRect) > [self cellSize].height + 2.0)
        textRect = SKCenterRectVertically(textRect, [self cellSize].height + 2.0, [controlView isFlipped]);
    [super drawInteriorWithFrame:textRect inView:controlView];
    
    // Draw the image
    NSRect imageRect = [self iconRectForBounds:aRect];
    imageRect = SKCenterRectVertically(imageRect, NSWidth(imageRect), [controlView isFlipped]);
    imageRect.origin.y += [controlView isFlipped] ? -IMAGE_OFFSET : IMAGE_OFFSET;
    [self drawIconWithFrame:imageRect inView:controlView];
}

- (void)selectWithFrame:(NSRect)aRect inView:(NSView *)controlView editor:(NSText *)textObj delegate:(id)anObject start:(NSInteger)selStart length:(NSInteger)selLength {
    [super selectWithFrame:[self textRectForBounds:aRect] inView:controlView editor:textObj delegate:anObject start:selStart length:selLength];
}

- (NSUInteger)hitTestForEvent:(NSEvent *)event inRect:(NSRect)cellFrame ofView:(NSView *)controlView {
    NSRect textRect = [self textRectForBounds:cellFrame];
    NSPoint mouseLoc = [controlView convertPoint:[event locationInWindow] fromView:nil];
    NSUInteger hit = NSCellHitNone;
    if (NSMouseInRect(mouseLoc, textRect, [controlView isFlipped]))
        hit = [super hitTestForEvent:event inRect:textRect ofView:controlView];
    else if (NSMouseInRect(mouseLoc, [self iconRectForBounds:cellFrame], [controlView isFlipped]))
        hit = NSCellHitContentArea;
    return hit;
}

- (void)setObjectValue:(id <NSCopying>)obj {
    // the objectValue should be an object that's KVC compliant for the "string" and "image" keys
    
    // this can happen initially from the init, as there's no initializer passing an objectValue
    if ([(id)obj isKindOfClass:[NSString class]])
        obj = [NSDictionary dictionaryWithObjectsAndKeys:obj, SKTextWithIconCellStringKey, nil];
    
    // we should not set a derived value such as the string here, otherwise NSTableView will call tableView:setObjectValue:forTableColumn:row: whenever a cell is selected
    [super setObjectValue:obj];
}

- (NSImage *)icon {
    return [[self objectValue] valueForKey:SKTextWithIconCellImageKey];
}

@end

#pragma mark -

@implementation SKTextWithIconFormatter

- (NSString *)stringForObjectValue:(id)obj {
    return [obj isKindOfClass:[NSString class]] ? obj : [obj valueForKey:SKTextWithIconCellStringKey];
}

- (BOOL)getObjectValue:(id *)obj forString:(NSString *)string errorDescription:(NSString **)error {
    // even though 'string' is reported as immutable, it's actually changed after this method returns and before it's returned by the control!
    string = [[string copy] autorelease];
    *obj = [NSDictionary dictionaryWithObjectsAndKeys:string, SKTextWithIconCellStringKey, nil];
    return YES;
}

@end
