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

RCS_ID("$Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/SourceRelease_2005-10-03/OmniGroup/Frameworks/OmniAppKit/OpenStepExtensions.subproj/NSSplitView-OAExtensions.m 68913 2005-10-03 19:36:19Z kc $")

@implementation NSSplitView (OAExtensions)

- (float)fraction;
{
    NSRect                      topFrame, bottomFrame;

    if ([[self subviews] count] < 2)
	return 0.0;

    topFrame = [[[self subviews] objectAtIndex:0] frame];
    bottomFrame = [[[self subviews] objectAtIndex:1] frame];
    return bottomFrame.size.height
      / (bottomFrame.size.height + topFrame.size.height);
}

- (void)setFraction:(float)newFract;
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
    bottomFrame.size.height = newFract * totalHeight;
    topFrame.size.height = totalHeight - bottomFrame.size.height;
    [topSubView setFrame:topFrame];
    [bottomSubView setFrame:bottomFrame];
    [self adjustSubviews];
    [self setNeedsDisplay: YES];
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
