// Copyright 1997-2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniFoundation/OFBundleRegistry.h,v 1.14 2003/01/15 22:51:48 kc Exp $

// OFBundleRegistry searches for loadable bundles, then processes the OFRegistrations for all software components (i.e. frameworks, the application, and any loadable bundles).

#import <OmniFoundation/OFObject.h>

@class NSArray, NSBundle;

extern NSString *OFBundleRegistryDisabledBundlesDefaultsKey;
extern NSString *OFBundleRegistryChangedNotificationName;

@interface OFBundleRegistry : OFObject
{
}

+ (NSDictionary *)softwareVersionDictionary;
    // Returns a dictionary of the registered software versions
+ (NSArray *)knownBundles;
    // Returns the known bundle descriptions (see comments in the implementation for details)

+ (void)noteAdditionalBundles:(NSArray *)additionalBundles owner:bundleOwner;
    // Objects that maintain bundles or plugins that are not known to OFBundleRegistry can note their descriptions here and they will be included in +knownBundles

@end

// OFBundleRegistryTarget informal protocol
@interface NSObject (OFBundleRegistryTarget)
+ (void)registerItemName:(NSString *)itemName bundle:(NSBundle *)bundle description:(NSDictionary *)description;
@end
