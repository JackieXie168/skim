// Copyright 2005 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/OmniSourceRelease_2006-09-07/OmniGroup/Frameworks/OmniFoundation/XML/OFXMLFrozenElement.h 66043 2005-07-25 21:17:05Z kc $

#import <OmniFoundation/OFObject.h>

#import <OmniFoundation/OFXMLWhitespaceBehavior.h>

@class OFXMLDocument;
@class NSArray;

@interface OFXMLFrozenElement : OFObject
{
    NSString  *_name;
    NSArray   *_children;
    NSArray   *_attributeNamesAndValues;
}

// API
- initWithName:(NSString *)name children:(NSArray *)children attributes:(NSDictionary *)attributes attributeOrder:(NSArray *)attributeOrder;

- (NSString *)name;

- (void)appendXML:(struct _OFXMLBuffer *)xml withParentWhiteSpaceBehavior: (OFXMLWhitespaceBehaviorType) parentBehavior document: (OFXMLDocument *) doc level: (unsigned int) level;

@end
