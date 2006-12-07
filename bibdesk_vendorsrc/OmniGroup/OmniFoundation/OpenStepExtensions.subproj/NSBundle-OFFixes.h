// Copyright 1999-2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniFoundation/OpenStepExtensions.subproj/NSBundle-OFFixes.h,v 1.5 2003/01/15 22:51:58 kc Exp $

#import <Foundation/NSBundle.h>


@interface NSBundle (OFFixes)

#ifdef __MACH__
- (void) fixFrameworkVersioning;
#endif


@end
