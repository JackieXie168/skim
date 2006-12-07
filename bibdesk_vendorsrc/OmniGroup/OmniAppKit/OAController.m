// Copyright 2004-2005 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import "OAController.h"
#import <AppKit/NSApplication.h>
#import <OmniBase/rcsid.h>

RCS_ID("$Header$")

@implementation OAController

- (void)gotPostponedTerminateResult:(BOOL)isReadyToTerminate;
{
    if (status == OFControllerPostponingTerminateStatus)
        [NSApp replyToApplicationShouldTerminate:isReadyToTerminate];
}

@end
