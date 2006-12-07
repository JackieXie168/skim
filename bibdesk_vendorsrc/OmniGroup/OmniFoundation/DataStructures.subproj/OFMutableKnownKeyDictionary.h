// Copyright 1998-2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniFoundation/DataStructures.subproj/OFMutableKnownKeyDictionary.h,v 1.8 2003/01/15 22:51:54 kc Exp $

#import <Foundation/NSDictionary.h>

@class OFKnownKeyDictionaryTemplate;

@interface OFMutableKnownKeyDictionary : NSMutableDictionary
/*.doc.
This subclass of NSMutableDictionary should be used when the set of possible keys is small and known ahead of time.  Due to the variable size of instances, this class cannot be easily subclassed.
*/
{
    OFKnownKeyDictionaryTemplate *_template;
    NSObject                     *_values[0];
}

+ (OFMutableKnownKeyDictionary *) newWithTemplate: (OFKnownKeyDictionaryTemplate *) template zone: (NSZone *) zone;
/*.doc.
Returns a new, retained, empty instance.
*/

+ (OFMutableKnownKeyDictionary *) newWithTemplate: (OFKnownKeyDictionaryTemplate *) template;
/*.doc.
Calls +newWithTemplate:zone: using the default zone.
*/

- (OFMutableKnownKeyDictionary *) mutableKnownKeyCopyWithZone: (NSZone *) zone;
/*.doc.
Returns a new retained mutable copy of the receive.  This is named as it is so that -mutableCopyWithZone: will still return a vanilla NSMutableDictionary.
*/

@end
