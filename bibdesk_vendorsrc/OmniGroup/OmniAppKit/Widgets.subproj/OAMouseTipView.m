// Copyright 2002-2004 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import "OAMouseTipView.h"

#import <Cocoa/Cocoa.h>
#import <OmniBase/rcsid.h>

RCS_ID("$Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniAppKit/Widgets.subproj/OAMouseTipView.m,v 1.10 2004/02/11 22:37:53 toon Exp $");

@interface OAMouseTipView (Private)
@end

@implementation OAMouseTipView

static NSDictionary *_tooltipAttributes, *_exposeAttributes, *_dockAttributes;

+ (void)initialize;
{
    NSMutableParagraphStyle *paraStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    [paraStyle setAlignment:NSCenterTextAlignment];
    
    _tooltipAttributes = [[NSDictionary dictionaryWithObjectsAndKeys:[NSFont toolTipsFontOfSize:[NSFont labelFontSize]], NSFontAttributeName, nil] retain];
    _exposeAttributes = [[NSDictionary dictionaryWithObjectsAndKeys:[NSFont boldSystemFontOfSize:[NSFont labelFontSize]], NSFontAttributeName, [NSColor whiteColor], NSForegroundColorAttributeName, paraStyle, NSParagraphStyleAttributeName, nil] retain];
    _dockAttributes = [[NSDictionary dictionaryWithObjectsAndKeys:[NSFont boldSystemFontOfSize:[NSFont systemFontSize]], NSFontAttributeName, [NSColor whiteColor], NSForegroundColorAttributeName, paraStyle, NSParagraphStyleAttributeName, nil] retain];
    
    [paraStyle release];
}

// API

- (void)setStyle:(OAMouseTipStyle)aStyle;
{
    style = aStyle;
    [self setNeedsDisplay:YES];
}

- (void)setTitle:(NSString *)aTitle;
{
    [title release];
    title = [[NSAttributedString alloc] initWithString:aTitle attributes:[self textAttributes]];
    [self setNeedsDisplay:YES];
}

- (void)setAttributedTitle:(NSAttributedString *)aTitle;
{
    if (title != aTitle) {
        [title release];
        title = [aTitle retain];
        [self setNeedsDisplay:YES];
    }
}

// NSView subclass

#define TEXT_X_INSET 7.0
#define TEXT_Y_INSET 3.0

- (void)drawRect:(NSRect)rect;
{
    rect = _bounds;
    [[NSColor clearColor] set];
    NSRectFill(rect);
        
    if (style == MouseTip_TooltipStyle) {
        [[NSColor colorWithCalibratedRed:1.0 green:0.98 blue:0.83 alpha:0.85] set]; // light yellow to match standard tooltip color
        NSRectFill(rect);
    } else if (style == MouseTip_ExposeStyle) {
        float radius = 5;
        NSPoint point;
        NSBezierPath *path;
            
        if (NSWidth(rect) < 10 || NSHeight(rect) < 10) {
            if (NSWidth(rect) < NSHeight(rect)) {
                radius = NSWidth(rect);
            } else {
                radius = NSHeight(rect);
            }
        }
        
        path = [NSBezierPath bezierPath];
        point.x = NSMinX(rect) + radius;
        point.y = NSMinY(rect);
        [path moveToPoint:point];
        
        point.x = NSMaxX(rect) - radius;
        point.y = NSMinY(rect) + radius;
        [path appendBezierPathWithArcWithCenter:point radius:-radius startAngle:90 endAngle:180 clockwise:NO];
        point.x = NSMaxX(rect) - radius;
        point.y = NSMaxY(rect) - radius;
        [path appendBezierPathWithArcWithCenter:point radius:-radius startAngle:180 endAngle:270 clockwise:NO];
        point.x = NSMinX(rect) + radius;
        point.y = NSMaxY(rect) - radius;
        [path appendBezierPathWithArcWithCenter:point radius:-radius startAngle:270 endAngle:360 clockwise:NO];
        point.x = NSMinX(rect) + radius;
        point.y = NSMinY(rect) + radius;
        [path appendBezierPathWithArcWithCenter:point radius:-radius startAngle:0 endAngle:90 clockwise:NO];
        [[NSColor colorWithCalibratedRed:0.2 green:0.2 blue:0.2 alpha:0.85] set]; 
        [path fill];
    } else {
        NSMutableAttributedString *shadow = [title mutableCopy];
        
        [shadow addAttribute:NSForegroundColorAttributeName value:[NSColor blackColor] range:NSMakeRange(0, [shadow length])];
        [shadow drawAtPoint:NSMakePoint(NSMinX(_bounds) + TEXT_X_INSET -1.5, NSMinY(_bounds) + TEXT_Y_INSET)];
        [shadow drawAtPoint:NSMakePoint(NSMinX(_bounds) + TEXT_X_INSET, NSMinY(_bounds) + TEXT_Y_INSET -1.5)];
        [shadow drawAtPoint:NSMakePoint(NSMinX(_bounds) + TEXT_X_INSET +0.5, NSMinY(_bounds) + TEXT_Y_INSET +0.5)];
        [shadow release];
    }
    [title drawInRect:NSInsetRect(_bounds, TEXT_X_INSET, TEXT_Y_INSET)];
}

- (NSDictionary *)textAttributes;
{
    if (style == MouseTip_TooltipStyle)
        return _tooltipAttributes;
    else if (style == MouseTip_ExposeStyle)
        return _exposeAttributes;
    else
        return _dockAttributes;
}

@end

@implementation OAMouseTipView (Private)
@end
