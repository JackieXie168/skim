// Copyright 2001-2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.

#import "OATextWithIconCell.h"

#import <Cocoa/Cocoa.h>
#import <OmniBase/rcsid.h>

#import "NSImage-OAExtensions.h"
#import "NSAttributedString-OAExtensions.h"
#import "OAExtendedOutlineView.h"

RCS_ID("$Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniAppKit/Widgets.subproj/OATextWithIconCell.m,v 1.13 2003/04/10 01:00:14 neo Exp $");

@interface OATextWithIconCell (Private)
@end

@interface NSColor (JaguarAPI)
+ (NSColor *)alternateSelectedControlColor;
+ (NSColor *)alternateSelectedControlTextColor;
@end

@implementation OATextWithIconCell

// Init and dealloc

- init;
{
    if (![super initTextCell:@""])
        return nil;
    [self setEditable:YES];
    [self setLeaf:YES];
    return self;
}

- (void)dealloc;
{
    [super dealloc];
}


// API


// NSCell Subclass

#define TEXT_VERTICAL_OFFSET (-1.0)
#define FLIP_VERTICAL_OFFSET (-4.0)
#define LEFT_BORDER 3.0    

- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView;
{
    NSAttributedString *label;
    NSRect imageRect;
    NSRect textRect;
    cellFrame.origin.x += LEFT_BORDER;
    cellFrame.size.width -= LEFT_BORDER;
    
    NSDivideRect(cellFrame, &imageRect, &textRect, NSHeight(cellFrame), NSMinXEdge);
    
    // Draw the text
    textRect = NSInsetRect(textRect, 1.0, 0.0);
    if ([controlView isFlipped])
        textRect.origin.y += TEXT_VERTICAL_OFFSET; // Move it up a pixel so we don't draw off the bottom
    else
        textRect.origin.y -= (textRect.size.height + FLIP_VERTICAL_OFFSET);

    label = [self attributedStringValue];
    if ([NSColor respondsToSelector:@selector(alternateSelectedControlColor)]) {
        NSColor *highlightColor = [self highlightColorWithFrame:cellFrame inView:controlView];
        BOOL highlighted = [self isHighlighted];

        if (highlighted && [highlightColor isEqual:[NSColor alternateSelectedControlColor]]) {
            NSMutableAttributedString *labelCopy = [[label mutableCopy] autorelease];
            // add the alternate text color attribute.
            [labelCopy addAttribute:NSForegroundColorAttributeName
                              value:[NSColor alternateSelectedControlTextColor]
                              range:NSMakeRange(0,[label length])];
            label = labelCopy;
        }
    }
    
    [label drawInRectangle:textRect alignment:NSLeftTextAlignment verticallyCentered:NO];
    
    // Draw the image
    imageRect.size.width -= 1.0;
    imageRect.size.height -= 1.0;
    if ([controlView isFlipped])
        [[self image] drawFlippedInRect:imageRect operation:NSCompositeSourceOver];
    else
        [[self image] drawInRect:imageRect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
}

@end

@implementation OATextWithIconCell (NotificationsDelegatesDatasources)

// OAExtendedOutlineView's DataCellExtraMethods

- (void)modifyFieldEditor:(NSText *)fieldEditor forOutlineView:(OAExtendedOutlineView *)outlineView column:(int)columnIndex row:(int)rowIndex;
{
    NSRect cellFrame, imageRect, textRect;
    
    cellFrame = [outlineView frameOfCellAtColumn:columnIndex row:rowIndex];
    NSDivideRect(cellFrame, &imageRect, &textRect, NSHeight(cellFrame), NSMinXEdge);
    textRect.origin.y += TEXT_VERTICAL_OFFSET;
    textRect.origin.x += 2.0;
    textRect.size.width -= 2.0;
    [[fieldEditor superview] setFrame:textRect];
}


@end

@implementation OATextWithIconCell (Private)
@end
