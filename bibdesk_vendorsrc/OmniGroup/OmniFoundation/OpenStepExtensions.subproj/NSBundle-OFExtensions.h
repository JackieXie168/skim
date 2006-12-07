// Copyright 2005 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header$

#import <Foundation/NSBundle.h>

#import <OmniFoundation/NSString-OFExtensions.h>

// This uses the OMNI_BUNDLE_IDENTIFIER compiler define set by the OmniGroup/Configurations/*Global*.xcconfig to look up the bundle for the calling code.
#define OMNI_BUNDLE _OFBundleWithIdentifier(OMNI_BUNDLE_IDENTIFIER)
static inline NSBundle *_OFBundleWithIdentifier(NSString *identifier)
{
    OBPRECONDITION(![NSString isEmptyString:identifier]); // Did you forget to set OMNI_BUNDLE_IDENTIFIER in your target?
    return [NSBundle bundleWithIdentifier:identifier];
}
