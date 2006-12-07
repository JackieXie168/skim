// Copyright 2000-2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniFoundation/OFWeakRetainProtocol.h,v 1.5 2003/01/15 22:51:51 kc Exp $

@protocol OFWeakRetain
// Must be implemented by the class itself
- (void)invalidateWeakRetains;

// Implemented by the OFWeakRetainConcreteImplementation_IMPLEMENTATION macro
- (void)incrementWeakRetainCount;
- (void)decrementWeakRetainCount;
@end
