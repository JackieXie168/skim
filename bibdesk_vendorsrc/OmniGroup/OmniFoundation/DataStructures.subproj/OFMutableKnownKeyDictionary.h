// Copyright 1998-2004 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniFoundation/DataStructures.subproj/OFMutableKnownKeyDictionary.h,v 1.12 2004/02/10 04:07:43 kc Exp $

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

+ (OFMutableKnownKeyDictionary *) newWithTemplate: (OFKnownKeyDictionaryTemplate *)aTemplate zone: (NSZone *) zone;
/*.doc.
Returns a new, retained, empty instance.
*/

+ (OFMutableKnownKeyDictionary *) newWithTemplate: (OFKnownKeyDictionaryTemplate *)aTemplate;
/*.doc.
Calls +newWithTemplate:zone: using the default zone.
*/

- (OFMutableKnownKeyDictionary *) mutableKnownKeyCopyWithZone: (NSZone *) zone;
/*.doc.
Returns a new retained mutable copy of the receive.  This is named as it is so that -mutableCopyWithZone: will still return a vanilla NSMutableDictionary.
*/

- (NSArray *) copyKeys;

@end
