// Copyright 2003-2004 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import <OmniAppKit/OAVectorView.h>

#import <OmniBase/OmniBase.h>
#import <OmniAppKit/NSTextField-OAExtensions.h>
#import <OmniAppKit/OAVectorCell.h>

RCS_ID("$Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniAppKit/Widgets.subproj/OAVectorView.m,v 1.4 2004/02/10 05:17:53 kc Exp $")

@interface OAVectorView (PrivateAPI)
- (void)_updateFields;
@end

@implementation OAVectorView

//
// NSView subclass
//

- (BOOL)acceptsFirstMouse:(NSEvent *)theEvent;
{
    return YES;
}

//
// NSControl subclass
//
+ (Class)cellClass;
{
    return [OAVectorCell class];
}

- (void)setEnabled:(BOOL)flag;
{
    [super setEnabled:flag];
    [xField setEnabled:flag];
    [yField setEnabled:flag];
    [commaTextField changeColorAsIfEnabledStateWas:flag];
}

- (void)setObjectValue:(id)objectValue;
{
    OBPRECONDITION(!objectValue || [objectValue isKindOfClass:[OFPoint class]]);
    [super setObjectValue:objectValue];
    [self _updateFields];
}

#if 0
- (void)mouseDown:(NSEvent *)theEvent;
{
    if (!enabled)
        return;

    float   inset     = [self _scaling] * 8;
    NSRect  bounds    = NSInsetRect([self bounds], inset , inset);
    NSPoint center    = (NSPoint){NSMidX(bounds), NSMidY(bounds)};
    NSPoint lastPoint = vector;
    do {
        [self setNeedsDisplay:YES];

        NSPoint point = [self convertPoint:[theEvent locationInWindow] fromView:nil];
        point.x -= center.x;
        point.y -= center.y;

        if (point.y > 0 && fabs(point.x) <= 1)
            point.x = 0;
        else if (point.y > 3 && point.x > 3 && fabs(point.y - point.x) <=2) {
            point.x = point.y;
        }

        if (point.x > center.x - 10) {
            point.x = center.x - 10;
        } else if (point.x < (-center.x + 10)) {
            point.x = -center.x + 10;
        }
        if (point.y > center.y - 10) {
            point.y = center.y - 10;
        } else if (point.y < (-center.y + 10)) {
            point.y = -center.y + 10;
        }

        if (!NSEqualPoints(lastPoint, point)) {
            lastPoint = point;
            vector    = point;
            [target performSelector:action withObject:self];
            [xField setFloatValue:point.x];
            [yField setFloatValue:point.y];
        }
        theEvent = [[self window] nextEventMatchingMask:(NSLeftMouseDraggedMask | NSLeftMouseUpMask)];
    } while ([theEvent type] != NSLeftMouseUp);
}

- (void)drawRect:(NSRect)rect;
{
    NSRect bounds = [self bounds];
    float scaling = [self _scaling];
    float inset = 8 * scaling;

    if (imageCell == nil) {
        imageCell = [[NSImageCell alloc] initImageCell:nil];
        [imageCell setImageFrameStyle:NSImageFrameGrayBezel];
    }
    [imageCell setEnabled:[self isEnabled]];
    [imageCell drawWithFrame:bounds inView:self];

    bounds = NSInsetRect(bounds, inset, inset);
    //        cursorWidth = (bounds.size.width - 20) * scaling;
    int cursorWidth = inset * 2;

    NSPoint center;
    if (enabled && !isMultiple) {
        // Draw crosshair
        center.x = NSMidX(bounds) + vector.x;
        center.y = NSMidY(bounds) + vector.y;
        NSRect horizontalLine = NSMakeRect(center.x - cursorWidth/2, center.y, cursorWidth, 1);
        NSRect verticalLine = NSMakeRect(center.x, center.y - cursorWidth/2, 1, cursorWidth);

        [[NSColor grayColor] set];
        NSRectFill(NSInsetRect(horizontalLine, -0.5, -0.5)); // draw it fuzzy so it looks like a real shadow
        NSRectFill(NSInsetRect(verticalLine, -0.5, -0.5));

        NSRectFill(horizontalLine);
        NSRectFill(verticalLine);
    }

    // Draw axes
    center.x = NSMidX(bounds);
    center.y = NSMidY(bounds);
    if (enabled)
        [[NSColor blackColor] set];
    else
        [[NSColor grayColor] set];
    NSRectFill(NSMakeRect(center.x - cursorWidth/2, center.y, cursorWidth, 1));
    NSRectFill(NSMakeRect(center.x, center.y - cursorWidth/2, 1, cursorWidth));

}
#endif

//
// Actions
//

- (IBAction)vectorTextFieldAction:(id)sender;
{
    if ([[sender stringValue] isEqualToString:@"--"])
        return;

    OFPoint *pointValue = [self objectValue];
    NSPoint  point = pointValue ? [pointValue point] : NSZeroPoint;
    if (sender == xField)
        point.x = [sender floatValue];
    else
        point.y = [sender floatValue];

    pointValue = [[OFPoint alloc] initWithPoint:point];
    [self setObjectValue:pointValue];
    [pointValue release];
    
    OAVectorCell *cell = [self cell];
    [self sendAction:[cell action] to:[cell target]];
}


//
// API
//

- (void)setIsMultiple:(BOOL)flag;
{
    OAVectorCell *cell = [self cell];
    [cell setIsMultiple:flag];
    [self _updateFields];
}

- (BOOL)isMultiple;
{
    OAVectorCell *cell = [self cell];
    return [cell isMultiple];
}

@end

@implementation OAVectorView (PrivateAPI)
- (void)_updateFields;
{
    OFPoint *pointValue = [self objectValue];
    
    if ([self isMultiple] || !pointValue) {
        [xField setStringValue:@"--"];
        [yField setStringValue:@"--"];
    } else {
        NSPoint point = [pointValue point];
        [xField setFloatValue:point.x];
        [yField setFloatValue:point.y];
    }
}
@end
