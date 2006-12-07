// Copyright 2003-2004 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniFoundation/XML/OFXMLElement.h,v 1.17 2004/02/10 04:07:49 kc Exp $

#import <OmniFoundation/OFObject.h>

#import <CoreFoundation/CFXMLParser.h>
#import <OmniFoundation/OFXMLWhitespaceBehavior.h>

@class NSArray, NSMutableArray, NSMutableDictionary;
@class OFXMLDocument;

@interface OFXMLElement : OFObject
{
    NSString            *_name;
    NSMutableArray      *_children;
    NSMutableArray      *_attributeOrder;
    NSMutableDictionary *_attributes;
    struct {
        unsigned int ignoreUnlessReferenced : 1;
        unsigned int markedAsReferenced     : 1;
    } _flags;
}

- initWithName: (NSString *) name;

- (id)deepCopy;

- (NSString *) name;
- (NSArray *) children;
- (id) childAtIndex: (unsigned int) childIndex;
- (id) lastChild;
- (void) appendChild: (id) child;  // Either a OFXMLElement or an NSString
- (void) removeChild: (id) child;
- (void) removeChildAtIndex: (unsigned int) childIndex;

- (void)setIgnoreUnlessReferenced:(BOOL)yn;
- (BOOL)ignoreUnlessReferenced;
- (void)markAsReferenced;

- (NSArray *) attributeNames;
- (NSString *) attributeNamed: (NSString *) name;
- (void) setAttribute: (NSString *) name string: (NSString *) value;
- (void) setAttribute: (NSString *) name value: (id) value;
- (void) setAttribute: (NSString *) name integer: (int) value;
- (void) setAttribute: (NSString *) name integer: (int) value;
- (void) setAttribute: (NSString *) name real: (float) value;  // "%g"
- (void) setAttribute: (NSString *) name real: (float) value format: (NSString *) formatString;
- (void) appendElement: (NSString *) elementName containingString: (NSString *) contents;
- (void) appendElement: (NSString *) elementName containingInteger: (int) contents;
- (void) appendElement: (NSString *) elementName containingReal: (float) contents; // "%g"
- (void) appendElement: (NSString *) elementName containingReal: (float) contents format: (NSString *) formatString;
- (void) removeAttributeNamed: (NSString *) name;

// Writing support called from OFXMLDocument
- (CFXMLTreeRef) createTreeWithParentWhiteSpaceBehavior: (OFXMLWhitespaceBehaviorType) parentBehavior document: (OFXMLDocument *) doc level: (unsigned int) level;
+ (CFXMLTreeRef) createTreeForValue: (id) value parentWhiteSpaceBehavior: (OFXMLWhitespaceBehaviorType) parentBehavior document: (OFXMLDocument *) doc level: (unsigned int) level;
+ (CFXMLTreeRef) createNewlineTree;
+ (CFXMLTreeRef) createSpaceTree: (unsigned int) spaces;
+ (CFXMLTreeRef) createTextTree: (NSString *) text quotingMask: (unsigned int) quotingMask newlineReplacement: (NSString *) newlineReplacement stringEncoding: (CFStringEncoding) stringEncoding;
@end

// This is called by OFXMLDocument when reading from an existing blob of XML
@interface OFXMLElement (OFXMLReading)
- initWithName: (NSString *) name elementInfo: (const CFXMLElementInfo *) elementInfo;
@end
