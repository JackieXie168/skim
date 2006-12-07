#import "ImageAndTextCell.h"

@implementation ImageAndTextCell

- (void)dealloc {
    [leftImage release];
    leftImage = nil;
    [super dealloc];
}

- copyWithZone:(NSZone *)zone {
    ImageAndTextCell *cell = (ImageAndTextCell *)[super copyWithZone:zone];
    cell->leftImage = [leftImage retain];
    return cell;
}

- (void)setLeftImage:(NSImage *)anImage {
    if (anImage != leftImage) {
        [leftImage release];
        leftImage = [anImage retain];
    }
}

- (NSImage *)leftImage {
    return leftImage;
}

- (void)setObjectValue:(id)value{
    if ([value isKindOfClass:[NSDictionary class]]) {
        [super setObjectValue:[value objectForKey:@"name"]];
        [self setLeftImage:[value objectForKey:@"icon"]];
    } else {
        [super setObjectValue:value];
    }
}

- (NSRect)leftImageFrameForCellFrame:(NSRect)cellFrame {
    if (leftImage != nil) {
        NSRect leftImageFrame;
        leftImageFrame.size = [leftImage size];
        leftImageFrame.origin = cellFrame.origin;
        leftImageFrame.origin.x += 3;
        leftImageFrame.origin.y += ceil((cellFrame.size.height - leftImageFrame.size.height) / 2);
        return leftImageFrame;
    }
    else
        return NSZeroRect;
}

- (void)editWithFrame:(NSRect)aRect inView:(NSView *)controlView editor:(NSText *)textObj delegate:(id)anObject event:(NSEvent *)theEvent {
    NSRect textFrame, leftImageFrame;
    NSDivideRect (aRect, &leftImageFrame, &textFrame, 3 + [leftImage size].width, NSMinXEdge);
    [super editWithFrame: textFrame inView: controlView editor:textObj delegate:anObject event: theEvent];
}

- (void)selectWithFrame:(NSRect)aRect inView:(NSView *)controlView editor:(NSText *)textObj delegate:(id)anObject start:(int)selStart length:(int)selLength {
    NSRect textFrame, leftImageFrame;
    NSDivideRect (aRect, &leftImageFrame, &textFrame, 3 + [leftImage size].width, NSMinXEdge);
    [super selectWithFrame: textFrame inView: controlView editor:textObj delegate:anObject start:selStart length:selLength];
}

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
    if (leftImage != nil) {
        NSSize	leftImageSize;
        NSRect	leftImageFrame;

        leftImageSize = [leftImage size];
        NSDivideRect(cellFrame, &leftImageFrame, &cellFrame, 3 + leftImageSize.width, NSMinXEdge);
        if ([self drawsBackground]) {
            [[self backgroundColor] set];
            NSRectFill(leftImageFrame);
        }
        leftImageFrame.origin.x += 3;
        leftImageFrame.size = leftImageSize;

        if ([controlView isFlipped])
            leftImageFrame.origin.y += ceil((cellFrame.size.height + leftImageFrame.size.height) / 2);
        else
            leftImageFrame.origin.y += ceil((cellFrame.size.height - leftImageFrame.size.height) / 2);

        [leftImage compositeToPoint:leftImageFrame.origin operation:NSCompositeSourceOver];
    }
    [super drawWithFrame:cellFrame inView:controlView];
}

- (NSSize)cellSize {
    NSSize cellSize = [super cellSize];
    cellSize.width += (leftImage ? [leftImage size].width : 0) + 3;
    return cellSize;
}

@end

