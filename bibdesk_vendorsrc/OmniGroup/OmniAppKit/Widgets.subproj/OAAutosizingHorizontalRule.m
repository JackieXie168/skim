// Copyright 2005-2006 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
#import "OAAutosizingHorizontalRule.h"

#import <OmniBase/OmniBase.h>
#import <AppKit/AppKit.h>

RCS_ID("$Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/OmniSourceRelease_2006-09-07/OmniGroup/Frameworks/OmniAppKit/Widgets.subproj/OAAutosizingHorizontalRule.m 79079 2006-09-07 22:35:32Z kc $");

@implementation OAAutosizingHorizontalRule

- (void)awakeFromNib;
{
    OBPRECONDITION(labelTextField);
    OBPRECONDITION([labelTextField isKindOfClass:[NSTextField class]]);
    OBPRECONDITION(![labelTextField isEditable]);
    
    [labelTextField sizeToFit];

    NSRect ruleFrame = [self frame];
    NSRect labelFrame = [labelTextField frame];
    
    // Only supporting labels to the left... we could detect and behave differently later if it comes up.
    OBASSERT(labelFrame.origin.x < ruleFrame.origin.x);
    
    // keep the right edge where it is.  Move the left edge to near the right edge of the
    float rightX = NSMaxX(ruleFrame);
    ruleFrame.origin.x = NSMaxX(labelFrame);
    ruleFrame.size.width = rightX - ruleFrame.origin.x;

    [self setFrame:ruleFrame];
}

@end
