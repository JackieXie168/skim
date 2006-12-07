// Copyright 2003-2005 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/OmniSourceRelease_2006-09-07/OmniGroup/Frameworks/OmniFoundation/XML/OFXMLWhitespaceBehavior.h 68913 2005-10-03 19:36:19Z kc $

#import <OmniFoundation/OFObject.h>

typedef enum _OFXMLWhitespaceBehaviorType {
    OFXMLWhitespaceBehaviorTypeAuto,     // do whatever the parent node did -- the default
    OFXMLWhitespaceBehaviorTypeIgnore,   // whitespace is irrelevant
    OFXMLWhitespaceBehaviorTypePreserve, // whitespace is important -- leave it as is
} OFXMLWhitespaceBehaviorType;

@interface OFXMLWhitespaceBehavior : OFObject
{
    NSMutableDictionary         *_nameToBehavior;
}

- (void) setBehavior: (OFXMLWhitespaceBehaviorType) behavior forElementName: (NSString *) elementName;
- (OFXMLWhitespaceBehaviorType) behaviorForElementName: (NSString *) elementName;

@end
