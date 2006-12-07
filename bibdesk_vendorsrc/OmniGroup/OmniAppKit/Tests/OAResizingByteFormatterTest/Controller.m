// Copyright 2006 The Omni Group.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import "Controller.h"

#import <Foundation/Foundation.h>
#import <OmniBase/OmniBase.h>
#import <OmniFoundation/OmniFoundation.h>
#import <OmniAppKit/OmniAppKit.h>

RCS_ID("$Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/trunk/OmniGroup/Templates/Developer%20Tools/File%20Templates/%20Omni/OmniFoundation%20public%20class.pbfiletemplate/class.m 70671 2005-11-22 01:01:39Z kc $");

@implementation Controller

- init;
{
    sizes = [[NSArray alloc] initWithObjects:
	[NSNumber numberWithUnsignedLongLong:1ULL*1024],
	[NSNumber numberWithUnsignedLongLong:1ULL*1024*1024],
	[NSNumber numberWithUnsignedLongLong:1ULL*1024*1024*1024],
	[NSNumber numberWithUnsignedLongLong:1ULL*1024*1024*1024*1024],
	[NSNumber numberWithUnsignedLongLong:1ULL*1024*1024*1024*1024*1024],
	[NSNumber numberWithUnsignedLongLong:1ULL*1024*1024*1024*1024*1024*1024],
	nil];
    return self;
}

- (void)awakeFromNib;
{
    OAResizingByteFormatter *formatter = [[OAResizingByteFormatter alloc] initWithNonretainedTableColumn:tableColumn];
    [[tableColumn dataCell] setFormatter:formatter];
    [formatter release];
}

@end
