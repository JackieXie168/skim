// Copyright 1997-2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniFoundation/OFRetainableObject.h,v 1.8 2003/01/15 22:51:50 kc Exp $

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

