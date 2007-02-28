// Copyright 2003-2005 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/OmniSourceRelease_2006-09-07/OmniGroup/Frameworks/OmniFoundation/XML/OFXMLElement.h 66265 2005-07-29 04:07:59Z bungi $

#import <OmniFoundation/OFObject.h>

#import <CoreFoundation/CFXMLParser.h>
#import <OmniFoundation/OFXMLWhitespaceBehavior.h>

@class NSArray, NSMutableArray, NSMutableDictionary, NSMutableString;
@class OFXMLDocument, OFXMLElement;

typedef void (*OFXMLElementApplier)(OFXMLElement *element, void *context);


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
- (OFXMLElement *)deepCopyWithName:(NSString *)name;

- (NSString *) name;
- (NSArray *) children;
- (unsigned int)childrenCount;
- (id) childAtIndex: (unsigned int) childIndex;
- (id) lastChild;
- (unsigned int)indexOfChildIdenticalTo:(id)child;
- (void)insertChild:(id)child atIndex:(unsigned int)childIndex;
- (void) appendChild: (id) child;  // Either a OFXMLElement or an NSString
- (void) removeChild: (id) child;
- (void) removeChildAtIndex: (unsigned int) childIndex;
- (void)removeAllChildren;
- (void)sortChildrenUsingFunction:(int (*)(id, id, void *))comparator context:(void *)context;
- (OFXMLElement *)firstChildNamed:(NSString *)childName;
- (OFXMLElement *)firstChildAtPath:(NSString *)path;
- (OFXMLElement *)firstChildWithAttribute:(NSString *)attribute value:(NSString *)value;

- (void)setIgnoreUnlessReferenced:(BOOL)yn;
- (BOOL)ignoreUnlessReferenced;
- (void)markAsReferenced;
- (BOOL)shouldIgnore;

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
- (void)sortAttributesUsingFunction:(int (*)(id, id, void *))comparator context:(void *)context;
- (void)sortAttributesUsingSelector:(SEL)comparator;

- (void)applyFunction:(OFXMLElementApplier)applier context:(void *)context;

@end

// This is called by OFXMLDocument when reading from an existing blob of XML
@interface OFXMLElement (OFXMLReading)
- initWithName: (NSString *) name elementInfo: (const CFXMLElementInfo *) elementInfo;
@end

@interface NSObject (OFXMLWriting)
- (void)appendXML:(struct _OFXMLBuffer *)xml withParentWhiteSpaceBehavior: (OFXMLWhitespaceBehaviorType) parentBehavior document: (OFXMLDocument *) doc level: (unsigned int) level;
- (BOOL)xmlRepresentationCanContainChildren;
- (NSObject *)createFrozenElement;
@end

extern CFStringRef OFXMLGetIndentationString(unsigned int level);

