// Copyright 2004-2005 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header$

#import <OmniFoundation/OFObject.h>
#import <CoreFoundation/CFDictionary.h>
#import <OmniBase/assertions.h>
#import <OmniFoundation/OFXMLIdentifierRegistryObject.h>

@interface OFXMLIdentifierRegistry : OFObject
{
@private
    CFMutableDictionaryRef _idToObject;
    CFMutableDictionaryRef _objectToID;
}

- (id)initWithRegistry:(OFXMLIdentifierRegistry *)registry;

- (NSString *)registerIdentifier:(NSString *)identifier forObject:(id <OFXMLIdentifierRegistryObject>)object;
- (id <OFXMLIdentifierRegistryObject>)objectForIdentifier:(NSString *)identifier;
- (NSString *)identifierForObject:(id <OFXMLIdentifierRegistryObject>)object;

- (void)applyFunction:(CFDictionaryApplierFunction)function context:(void *)context;

- (void)clearRegistrations;

#ifdef OMNI_ASSERTIONS_ON
- (BOOL)checkInvariants;
#endif

@end

extern NSString *OFXMLCreateID(void);
extern NSString *OFXMLIDFromString(NSString *str);
