// Copyright 1997-2005 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import <OmniAppKit/NSSplitView-OAExtensions.h>

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <OmniBase/OmniBase.h>
#import <OmniFoundation/OmniFoundation.h>

RCS_ID("$Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/OmniSourceRelease_2006-09-07/OmniGroup/Frameworks/OmniAppKit/OpenStepExtensions.subproj/NSSplitView-OAExtensions.m 68913 2005-10-03 19:36:19Z kc $")

@implementation NSSplitView (OAExtensions)

// ARM: added variant of fraction methods for vertical dividers

- (float)horizontalDividerFraction;
{
    NSRect topFrame, bottomFrame;
    
    if ([[self subviews] count] < 2)
        return 0.0;
    
    topFrame = [[[self subviews] objectAtIndex:0] frame];
    bottomFrame = [[[self subviews] objectAtIndex:1] frame];
    return NSHeight(bottomFrame) / (NSHeight(bottomFrame) + NSHeight(topFrame));
}

- (void)setHorizontalDividerFraction:(float)newFract;
{
    NSRect topFrame, bottomFrame;
    NSView *topSubView;
    NSView *bottomSubView;
    float totalHeight;
    
    if ([[self subviews] count] < 2)
        return;
    
    topSubView = [[self subviews] objectAtIndex:0];
    bottomSubView = [[self subviews] objectAtIndex:1];
    topFrame = [topSubView frame];
    bottomFrame = [bottomSubView frame];
    totalHeight = NSHeight(bottomFrame) + NSHeight(topFrame);
    bottomFrame.size.height = newFract * totalHeight;
    topFrame.size.height = totalHeight - NSHeight(bottomFrame);
    [topSubView setFrame:topFrame];
    [bottomSubView setFrame:bottomFrame];
    [self adjustSubviews];
    [self setNeedsDisplay: YES];
}

- (float)verticalDividerFraction;
{
    NSRect leftFrame, rightFrame;
    
    if ([[self subviews] count] < 2)
        return 0.0;
    
    leftFrame = [[[self subviews] objectAtIndex:0] frame];
    rightFrame = [[[self subviews] objectAtIndex:1] frame];
    return NSWidth(rightFrame) / (NSWidth(rightFrame) + NSWidth(leftFrame));
}

- (void)setVerticalDividerFraction:(float)newFract;
{
    NSRect leftFrame, rightFrame;
    NSView *leftSubView;
    NSView *rightSubView;
    float totalWidth;
    
    if ([[self subviews] count] < 2)
        return;
    
    leftSubView = [[self subviews] objectAtIndex:0];
    rightSubView = [[self subviews] objectAtIndex:1];
    leftFrame = [leftSubView frame];
    rightFrame = [rightSubView frame];
    totalWidth = NSWidth(rightFrame) + NSWidth(leftFrame);
    rightFrame.size.width = newFract * totalWidth;
    leftFrame.size.width = totalWidth - NSWidth(rightFrame);
    [leftSubView setFrame:leftFrame];
    [rightSubView setFrame:rightFrame];
    [self adjustSubviews];
    [self setNeedsDisplay: YES];
}

- (float)fraction;
{
    return [self isVertical] ? [self verticalDividerFraction] : [self horizontalDividerFraction];
}

- (void)setFraction:(float)newFract;
{
    if ([self isVertical])
        [self setVerticalDividerFraction:newFract];
    else
        [self setHorizontalDividerFraction:newFract];
}

- (int)topPixels;
{
    NSRect subFrame;
    NSView *subView = [[self subviews] objectAtIndex:0];

    subFrame = [subView frame];
    return subFrame.size.height;	
}

- (void)setTopPixels:(int)newTop;
{
    NSRect                      topFrame, bottomFrame;
    NSView                       *topSubView;
    NSView                       *bottomSubView;
    float                       totalHeight;

    if ([[self subviews] count] < 2)
	return;

    topSubView = [[self subviews] objectAtIndex:0];
    bottomSubView = [[self subviews] objectAtIndex:1];
    topFrame = [topSubView frame];
    bottomFrame = [bottomSubView frame];
    totalHeight = bottomFrame.size.height + topFrame.size.height;
    if (newTop > totalHeight)
	newTop = totalHeight;
    topFrame.size.height = newTop;
    bottomFrame.size.height = totalHeight - newTop;
    [topSubView setFrame:topFrame];
    [bottomSubView setFrame:bottomFrame];
    [self adjustSubviews];
    [self setNeedsDisplay: YES];
}

- (int)bottomPixels;
{
    NSRect subFrame;
    NSView *subView = [[self subviews] objectAtIndex:1];

    subFrame = [subView frame];
    return subFrame.size.height;	
}

- (void)setBottomPixels:(int)newBottom;
{
    NSRect                      topFrame, bottomFrame;
    NSView                       *topSubView;
    NSView                       *bottomSubView;
    float                       totalHeight;

    if ([[self subviews] count] < 2)
	return;

    topSubView = [[self subviews] objectAtIndex:0];
    bottomSubView = [[self subviews] objectAtIndex:1];
    topFrame = [topSubView frame];
    bottomFrame = [bottomSubView frame];
    totalHeight = bottomFrame.size.height + topFrame.size.height;
    if (newBottom > totalHeight)
	newBottom = totalHeight;
    bottomFrame.size.height = newBottom;
    topFrame.size.height = totalHeight - newBottom;
    [topSubView setFrame:topFrame];
    [bottomSubView setFrame:bottomFrame];
    [self adjustSubviews];
    [self setNeedsDisplay: YES];
}

@end
