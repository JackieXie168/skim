// Copyright 2004-2006 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/OmniSourceRelease_2006-09-07/OmniGroup/Frameworks/OmniFoundation/OFBinding.h 79081 2006-09-07 22:50:49Z kc $

#import <Foundation/NSObject.h>

@interface OFBinding : NSObject
{
@protected
    unsigned int _enabledCount;
    BOOL _registered;
    id        _sourceObject;
    NSString *_sourceKey;
    id        _nonretained_destinationObject; // We assume the destantion owns us
    NSString *_destinationKey;
}

- initWithSourceObject:(id)sourceObject sourceKey:(NSString *)sourceKey
     destinationObject:(id)destinationObject destinationKey:(NSString *)destinationKey;

- (void)invalidate;

- (BOOL)isEnabled;
- (void)enable;
- (void)disable;

- (void)reset;

- (id)sourceObject;
- (NSString *)sourceKey;

- (id)destinationObject;
- (NSString *)destinationKey;

- (id)currentValue;
- (void)propagateCurrentValue;

- (NSString *)humanReadableDescription;
- (NSString *)shortHumanReadableDescription;

- (BOOL)isEqualConsideringSourceAndKey:(OFBinding *)otherBinding;

@end


@interface NSObject (OFBindingSourceObject)
- (void)bindingWillInvalidate:(OFBinding *)binding;
- (NSString *)humanReadableDescriptionForKey:(NSString *)key;
- (NSString *)shortHumanReadableDescriptionForKey:(NSString *)key;
@end


// For plain attributes and to-one relationships.  If you bind this for a to-many, it won't do insert/remove/replace calls.
// This is the default if you create an ODBinding
@interface OFObjectBinding : OFBinding
@end

// Ordered to-many properties
@interface OFArrayBinding : OFBinding
@end

// Unordered to-many properties
@interface OFSetBinding : OFBinding
@end
