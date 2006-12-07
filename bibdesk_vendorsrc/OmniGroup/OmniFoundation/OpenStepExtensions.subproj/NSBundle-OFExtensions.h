// Copyright 2005-2006 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/OmniSourceRelease_2006-09-07/OmniGroup/Frameworks/OmniFoundation/OpenStepExtensions.subproj/NSBundle-OFExtensions.h 79094 2006-09-08 00:06:21Z kc $

#import <Foundation/NSBundle.h>

#import <OmniBase/assertions.h>
#import <OmniFoundation/NSString-OFExtensions.h>

// This uses the OMNI_BUNDLE_IDENTIFIER compiler define set by the OmniGroup/Configurations/*Global*.xcconfig to look up the bundle for the calling code.
#define OMNI_BUNDLE _OFBundleWithIdentifier(OMNI_BUNDLE_IDENTIFIER)
static inline NSBundle *_OFBundleWithIdentifier(NSString *identifier)
{
    OBPRECONDITION(![NSString isEmptyString:identifier]); // Did you forget to set OMNI_BUNDLE_IDENTIFIER in your target?
    NSBundle *bundle = [NSBundle bundleWithIdentifier:identifier];
    OBPOSTCONDITION(bundle); // Did you set it to the wrong thing?
    return bundle;
}
