// Copyright 2002-2005 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import "OASwitcherBarButtonCell.h"

#import <AppKit/AppKit.h>
#import <OmniBase/OmniBase.h>
#import <OmniFoundation/OmniFoundation.h>
#import <OmniAppKit/OAAquaButton.h>
#import <OmniAppKit/NSImage-OAExtensions.h>

RCS_ID("$Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/OmniSourceRelease_2006-09-07/OmniGroup/Frameworks/OmniAppKit/Widgets.subproj/OASwitcherBarButtonCell.m 68913 2005-10-03 19:36:19Z kc $");

static BOOL ImagesSetup = NO;
static BOOL GraphiteImagesSetup = NO;
static NSImage *FillImage[7];
static NSImage *CapLeftImage[7];
static NSImage *CapRightImage[7];
static NSImage *DividerLeftImage[7];
static NSImage *DividerRightImage[7];

@interface OASwitcherBarButtonCell (Private)
+ (void)setupImages;
+ (void)setupGraphiteImages;
@end

@implementation OASwitcherBarButtonCell

// API

- (void)setCellLocation:(OASwitcherBarCellLocation)location;
{
    cellLocation = location;
}


// NSCell subclass

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView;
{
    BOOL isSelected;
    int tintHighlightIndex;
    NSImage *leftImage, *fillImage, *rightImage;
    NSRect leftImageFrame, fillImageFrame, rightImageFrame;
        
    OBASSERT([controlView isKindOfClass:[NSMatrix class]]);

    OAControlTint controlTint = OACurrentControlTint();
    if (controlTint == OAGraphiteTint && !GraphiteImagesSetup)
        [isa setupGraphiteImages];
    else if (!ImagesSetup)
        [isa setupImages];

//#warning RDR: Having trouble putting together on/off state and highlight state the right way; see comment.
    // Currently, when you mouseDown, the cell turns dark blue regardless of whether it was blue or gray before. If you switch the "isSelected =" lines below, the cell turns dark gray regardless of what color it was before. It's supposed to turn dark blue if it was blue, and dark gray if it was gray. Tried messing around with various wasy to get it to do the right thing, including implementing -highlight:withFrame:inView:, but without any luck -- ended up with some double-drawing instead (resulting in an undesirable dark shadow).
    isSelected = ([(NSMatrix *)[self controlView] selectedCell] == self);
    //isSelected = ([self state] == NSOnState);
    if (isSelected && ![[controlView window] isKeyWindow])
        tintHighlightIndex = 6;
    else
        tintHighlightIndex = (2 * controlTint * isSelected) + [self isHighlighted];
    
    switch (cellLocation) {
        case OASwitcherBarLeft:
            leftImage = CapLeftImage[tintHighlightIndex];
            rightImage = DividerRightImage[tintHighlightIndex];
            break;
        case OASwitcherBarRight:
            leftImage = DividerLeftImage[tintHighlightIndex];
            rightImage = CapRightImage[tintHighlightIndex];
            break;
        case OASwitcherBarMiddle:
        default:
            leftImage = DividerLeftImage[tintHighlightIndex];
            rightImage = DividerRightImage[tintHighlightIndex];
    }
    fillImage = FillImage[tintHighlightIndex];
    
    leftImageFrame = NSMakeRect(NSMinX(cellFrame), NSMinY(cellFrame),
                                [leftImage size].width, NSHeight(cellFrame));
    rightImageFrame = NSMakeRect(NSMaxX(cellFrame) - [rightImage size].width, NSMinY(cellFrame),
                                 [rightImage size].width, NSHeight(cellFrame));
    fillImageFrame = NSMakeRect(NSMinX(cellFrame) + leftImageFrame.size.width, NSMinY(cellFrame),
                                NSWidth(cellFrame) - (NSWidth(leftImageFrame) + NSWidth(rightImageFrame)), NSHeight(cellFrame));

    [leftImage drawFlippedInRect:leftImageFrame operation:NSCompositeSourceOver fraction:1.0];
    [fillImage drawFlippedInRect:fillImageFrame operation:NSCompositeSourceOver fraction:1.0];
    [rightImage drawFlippedInRect:rightImageFrame operation:NSCompositeSourceOver fraction:1.0];
    
    [self drawInteriorWithFrame:cellFrame inView:controlView];
}

/*
- (void)highlight:(BOOL)flag withFrame:(NSRect)cellFrame inView:(NSView *)controlView;
{
// maybe fix the problem here? how to do it without darkening partially transparent regions?
}
*/

@end

@implementation OASwitcherBarButtonCell (NotificationsDelegatesDatasources)
@end

@implementation OASwitcherBarButtonCell (Private)

+ (void)setupImages;
{
    NSBundle *bundle = [self bundle];
    
    // clear, normal
    FillImage[0] = [NSImage imageNamed:@"SwitcherBar_Fill" inBundle:bundle];
    CapLeftImage[0] = [NSImage imageNamed:@"SwitcherBar_CapLeft" inBundle:bundle];
    CapRightImage[0] = [NSImage imageNamed:@"SwitcherBar_CapRight" inBundle:bundle];
    DividerLeftImage[0] = [NSImage imageNamed:@"SwitcherBar_DivLeft" inBundle:bundle];
    DividerRightImage[0] = [NSImage imageNamed:@"SwitcherBar_DivRight" inBundle:bundle];
    // clear, pressed
    FillImage[1] = [NSImage imageNamed:@"SwitcherBar_Fill_Press" inBundle:bundle];
    CapLeftImage[1] = [NSImage imageNamed:@"SwitcherBar_CapLeft_Press" inBundle:bundle];
    CapRightImage[1] = [NSImage imageNamed:@"SwitcherBar_CapRight_Press" inBundle:bundle];
    DividerLeftImage[1] = [NSImage imageNamed:@"SwitcherBar_DivLeft_Press" inBundle:bundle];
    DividerRightImage[1] = [NSImage imageNamed:@"SwitcherBar_DivRight_Press" inBundle:bundle];
    // blue, normal
    FillImage[2] = [NSImage imageNamed:@"SwitcherBar_Fill_A" inBundle:bundle];
    CapLeftImage[2] = [NSImage imageNamed:@"SwitcherBar_CapLeft_A" inBundle:bundle];
    CapRightImage[2] = [NSImage imageNamed:@"SwitcherBar_CapRight_A" inBundle:bundle];
    DividerLeftImage[2] = [NSImage imageNamed:@"SwitcherBar_DivLeft_A" inBundle:bundle];
    DividerRightImage[2] = [NSImage imageNamed:@"SwitcherBar_DivRight_A" inBundle:bundle];
    // blue, pressed
    FillImage[3] = [NSImage imageNamed:@"SwitcherBar_Fill_Press_A" inBundle:bundle];
    CapLeftImage[3] = [NSImage imageNamed:@"SwitcherBar_CapLeft_Press_A" inBundle:bundle];
    CapRightImage[3] = [NSImage imageNamed:@"SwitcherBar_CapRight_Press_A" inBundle:bundle];
    DividerLeftImage[3] = [NSImage imageNamed:@"SwitcherBar_DivLeft_Press_A" inBundle:bundle];
    DividerRightImage[3] = [NSImage imageNamed:@"SwitcherBar_DivRight_Press_A" inBundle:bundle];
    // window is not key
    FillImage[6] = [NSImage imageNamed:@"SwitcherBar_Fill_Select" inBundle:bundle];
    CapLeftImage[6] = [NSImage imageNamed:@"SwitcherBar_CapLeft_Select" inBundle:bundle];
    CapRightImage[6] = [NSImage imageNamed:@"SwitcherBar_CapRight_Select" inBundle:bundle];
    DividerLeftImage[6] = [NSImage imageNamed:@"SwitcherBar_DivLeft_Select" inBundle:bundle];
    DividerRightImage[6] = [NSImage imageNamed:@"SwitcherBar_DivRight_Select" inBundle:bundle];
    
    ImagesSetup = YES; // that's a whole damn lot of images.
}

+ (void)setupGraphiteImages;
{
    NSBundle *bundle = [self bundle];

    // graphite, normal
    FillImage[4] = [NSImage imageNamed:@"SwitcherBar_Fill_G" inBundle:bundle];
    CapLeftImage[4] = [NSImage imageNamed:@"SwitcherBar_CapLeft_G" inBundle:bundle];
    CapRightImage[4] = [NSImage imageNamed:@"SwitcherBar_CapRight_G" inBundle:bundle];
    DividerLeftImage[4] = [NSImage imageNamed:@"SwitcherBar_DivLeft_G" inBundle:bundle];
    DividerRightImage[4] = [NSImage imageNamed:@"SwitcherBar_DivRight_G" inBundle:bundle];
    // graphite, pressed
    FillImage[5] = [NSImage imageNamed:@"SwitcherBar_Fill_Press_G" inBundle:bundle];
    CapLeftImage[5] = [NSImage imageNamed:@"SwitcherBar_CapLeft_Press_G" inBundle:bundle];
    CapRightImage[5] = [NSImage imageNamed:@"SwitcherBar_CapRight_Press_G" inBundle:bundle];
    DividerLeftImage[5] = [NSImage imageNamed:@"SwitcherBar_DivLeft_Press_G" inBundle:bundle];
    DividerRightImage[5] = [NSImage imageNamed:@"SwitcherBar_DivRight_Press_G" inBundle:bundle];
    
    GraphiteImagesSetup = YES;
}


@end
