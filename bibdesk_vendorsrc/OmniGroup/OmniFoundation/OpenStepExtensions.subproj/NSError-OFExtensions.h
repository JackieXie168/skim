// Copyright 2005 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header$

#import <Foundation/NSError.h>

extern NSString *OFUserCancelledActionErrorKey;

@interface NSError (OFExtensions)
- (BOOL)causedByUserCancelling;
@end

extern void _OFError(NSError **error, NSString *bundleIdentifier, const char *name, NSString *firstKey, ...);

// It is expected that -DOMNI_BUNDLE_IDENTIFIER=@"com.foo.bar" will be set when building your code.  Build configurations make this easy since you can set it in the target's configuration and then have your Other C Flags have -DOMNI_BUNDLE_IDENTIFIER=@\"$(OMNI_BUNDLE_IDENTIFIER)\" and also use $(OMNI_BUNDLE_IDENTIFIER) in your Info.plist instead of duplicating it.
#define _OFError_(error, bundleIdentifier, name, ...) _OFError(error, bundleIdentifier, #name, ## __VA_ARGS__)
#define OFError(error, name, ...) _OFError_(error, OMNI_BUNDLE_IDENTIFIER, name, ## __VA_ARGS__)

extern void OFErrorWithDomainv(NSError **error, NSString *domain, NSString *firstKey, va_list args);
extern void OFErrorWithDomain(NSError **error, NSString *domain, NSString *firstKey, ...);
