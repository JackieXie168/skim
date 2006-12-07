// Copyright 1997-2004 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniFoundation/Scheduling.subproj/OFResultHolder.h,v 1.10 2004/02/10 04:07:47 kc Exp $

#import <OmniFoundation/OFObject.h>

@class NSConditionLock;

@interface OFResultHolder : OFObject
{
    id result;
    NSConditionLock *resultLock;
}

- (void)setResult:(id)newResult;
- (id)result;

@end
