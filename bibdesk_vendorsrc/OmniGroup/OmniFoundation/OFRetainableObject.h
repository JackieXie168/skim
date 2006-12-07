// Copyright 1997-2004 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniFoundation/OFRetainableObject.h,v 1.10 2004/02/10 04:07:41 kc Exp $

// NeXT should have made this the root class and made NSObject a subclass of it

#import <Foundation/NSZone.h>

@interface OFRetainableObject
{
    Class isa;
}

+ (void)initialize;

+ alloc;
+ allocWithZone:(NSZone *)aZone;

- (unsigned)retainCount;
- (id)retain;
- (void)release;
- (id)autorelease;
- (void)dealloc;

@end

