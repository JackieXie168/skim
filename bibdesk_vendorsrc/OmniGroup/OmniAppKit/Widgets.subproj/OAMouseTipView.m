// Copyright 2002-2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.

#import "OAMouseTipView.h"

#import <Cocoa/Cocoa.h>
#import <OmniBase/rcsid.h>

RCS_ID("$Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniAppKit/Widgets.subproj/OAMouseTipView.m,v 1.4 2003/02/21 19:57:23 kc Exp $");

@interface OAMouseTipView (Private)
@end

@implementation OAMouseTipView

static NSDictionary *_textAttributes;

+ (void)initialize;
{
    _textAttributes = [[NSDictionary dictionaryWithObjectsAndKeys:[NSFont systemFontOfSize:[NSFont labelFontSize]], NSFontAttributeName, nil] retain];
}

// API

- (void)setTitle:(NSString *)aTitle;
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
    [[NSColor colorWithCalibratedRed:1.0 green:0.98 blue:0.83 alpha:0.85] set]; // light yellow to match standard tooltip color
    NSRectFill(rect);
    [title drawAtPoint:NSMakePoint(NSMinX(_bounds) + TEXT_X_INSET, NSMinY(_bounds) + TEXT_Y_INSET) withAttributes:_textAttributes];
}

- (NSDictionary *)textAttributes;
{
    return _textAttributes;
}

@end

@implementation OAMouseTipView (Private)
@end
