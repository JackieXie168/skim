// Copyright 2003-2004 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import "OAInspectorResizerAvoidingScrollView.h"

#import <Cocoa/Cocoa.h>
#import <OmniBase/rcsid.h>

#import "OAInspectorController.h"
#import "OAInspectorResizer.h"
#import "OAInspectorWindow.h"

RCS_ID("$Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniAppKit/Inspector.subproj/OAInspectorResizerAvoidingScrollView.m,v 1.4 2004/02/10 04:07:33 kc Exp $");

@interface OAInspectorResizerAvoidingScrollView (Private)
@end

@implementation OAInspectorResizerAvoidingScrollView

// NSScrollView subclass

#ifdef MAC_OS_X_VERSION_10_2
- (void)tile;
{
    [super tile];

    NSScroller *verticalScroller = [self verticalScroller];
    NSRect verticalSliderFrame = [verticalScroller frame];

    NSRect newVerticalSliderFrame, portionOfFrameObscuredByResizer;
    NSDivideRect(verticalSliderFrame, &portionOfFrameObscuredByResizer, &newVerticalSliderFrame, OAInspectorResizerWidth, NSMaxYEdge);

    [verticalScroller setFrame:newVerticalSliderFrame];
}
#endif

@end

@implementation OAInspectorResizerAvoidingScrollView (Private)
@end
