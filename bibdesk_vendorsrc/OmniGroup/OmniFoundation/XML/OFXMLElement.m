// Copyright 2003-2004 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import <OmniFoundation/OFXMLElement.h>

#import <Foundation/Foundation.h>
#import <OmniBase/OmniBase.h>
#import <OmniBase/rcsid.h>

#import <OmniFoundation/OFXMLDocument.h>
#import <OmniFoundation/OFXMLString.h>
#import <OmniFoundation/NSString-OFExtensions.h>

RCS_ID("$Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniFoundation/XML/OFXMLElement.m,v 1.25 2004/02/10 04:07:49 kc Exp $");

@interface OFXMLElement (PrivateAPI)
+ (CFXMLTreeRef) _createWhitespaceTree: (NSString *) string;
@end

@implementation OFXMLElement

- initWithName: (NSString *) name;
{
    _name = [name copy];
    // _children is lazily allocated
    // _attributeOrder is lazily allocated
    // _attributes is lazily allocated

    return self;
}

- (void) dealloc;
{
    [_name release];
    [_children release];
    [_attributeOrder release];
    [_attributes release];
    [super dealloc];
}

- (id)deepCopy;
{
    OFXMLElement *newElement;
    int childCount, childIndex;

    newElement = [[OFXMLElement alloc] initWithName:_name];
    
    if (_attributeOrder != nil) {
        newElement->_attributeOrder = [[NSMutableArray alloc] initWithArray:_attributeOrder];
    }
    
    if (_attributes != nil) {
        newElement->_attributes = [_attributes mutableCopy];	// don't need a deep copy because all the attributes are non-mutable strings, but we don need a unique copy of the attributes dictionary
    }
    
    childCount = [_children count];
    for (childIndex = 0; childIndex < childCount; childIndex++) {
        id child;
        BOOL copied = NO;
        
        child = [_children objectAtIndex:childIndex];
        if ([child isKindOfClass:[OFXMLElement class]]) {
            child = [child deepCopy];
            copied = YES;
        }
        [newElement appendChild:child];
        if (copied)
            [child release];
    }

    return newElement;
}

- (NSString *) name;
{
    return _name;
}

- (NSArray *) children;
{
    return _children;
}

- (id) childAtIndex: (unsigned int) childIndex;
{
    return [_children objectAtIndex: childIndex];
}

- (id) lastChild;
{
    return [_children lastObject];
}

- (void) appendChild: (id) child;  // Either a OFXMLElement or an NSString
{
    OBPRECONDITION([child isKindOfClass: [NSString class]] ||
                   [child isKindOfClass: [OFXMLElement class]] ||
                   [child isKindOfClass: [OFXMLString class]]);

    if (!_children)
        _children = [[NSMutableArray alloc] initWithObjects: child, nil];
    else
        [_children addObject: child];
}

- (void) removeChild: (id) child;
{
    OBPRECONDITION([child isKindOfClass: [NSString class]] || [child isKindOfClass: [OFXMLElement class]]);

    [_children removeObjectIdenticalTo: child];
}

- (void) removeChildAtIndex: (unsigned int) childIndex;
{
    [_children removeObjectAtIndex: childIndex];
}

- (NSArray *) attributeNames;
{
    return _attributeOrder;
}

- (NSString *) attributeNamed: (NSString *) name;
{
    return [_attributes objectForKey: name];
}

- (void) setAttribute: (NSString *) name string: (NSString *) value;
{
    if (!_attributeOrder) {
        OBASSERT(!_attributes);
        _attributeOrder = [[NSMutableArray alloc] init];
        _attributes = [[NSMutableDictionary alloc] init];
    }

    OBASSERT([_attributeOrder count] == [_attributes count]);

    if (value) {
        if (![_attributes objectForKey:name])
            [_attributeOrder addObject:name];
        id copy = [value copy];
        [_attributes setObject:copy forKey:name];
        [copy release];
    } else {
        [_attributeOrder removeObject:name];
        [_attributes removeObjectForKey:name];
    }
}

- (void) setAttribute: (NSString *) name value: (id) value;
{
    [self setAttribute: name string: [value description]]; // For things like NSNumbers
}

- (void) setAttribute: (NSString *) name integer: (int) value;
{
    NSString *str;
    str = [[NSString alloc] initWithFormat: @"%d", value];
    [self setAttribute: name string: str];
    [str release];
}

- (void) setAttribute: (NSString *) name real: (float) value;  // "%g"
{
    [self setAttribute: name real: value format: @"%g"];
}

- (void) setAttribute: (NSString *) name real: (float) value format: (NSString *) formatString;
{
    NSString *str = [[NSString alloc] initWithFormat: formatString, value];
    [self setAttribute: name string: str];
    [str release];
}

- (void) appendElement: (NSString *) elementName containingString: (NSString *) contents;
{
    OFXMLElement *child;

    child = [[OFXMLElement alloc] initWithName: elementName];
    if (![NSString isEmptyString: contents])
        [child appendChild: contents];
    [self appendChild: child];
    [child release];
}

- (void) appendElement: (NSString *) elementName containingInteger: (int) contents;
{
    NSString *str;
    str = [[NSString alloc] initWithFormat: @"%d", contents];
    [self appendElement: elementName containingString: str];
    [str release];
}

- (void) appendElement: (NSString *) elementName containingReal: (float) contents; // "%g"
{
    [self appendElement: elementName containingReal: contents format: @"%g"];
}

- (void) appendElement: (NSString *) elementName containingReal: (float) contents format: (NSString *) formatString;
{
    NSString *str;
    str = [[NSString alloc] initWithFormat: formatString, contents];
    [self appendElement: elementName containingString: str];
    [str release];
}

- (void) removeAttributeNamed: (NSString *) name;
{
    if ([_attributes objectForKey: name]) {
        [_attributeOrder removeObject: name];
        [_attributes removeObjectForKey: name];
    }
}

- (void)setIgnoreUnlessReferenced:(BOOL)yn;
{
    _flags.ignoreUnlessReferenced = (yn != NO);
}

- (BOOL)ignoreUnlessReferenced;
{
    return (_flags.ignoreUnlessReferenced != 0);
}

- (void)markAsReferenced;
{
    _flags.markedAsReferenced = 1;
}

- (CFXMLTreeRef) createTreeWithParentWhiteSpaceBehavior: (OFXMLWhitespaceBehaviorType) parentBehavior document: (OFXMLDocument *) doc level: (unsigned int) level;
{
    OFXMLWhitespaceBehaviorType whitespaceBehavior;
    CFXMLTreeRef                tree;
    CFXMLNodeRef                node;
    CFXMLElementInfo            element;

    if (_flags.ignoreUnlessReferenced && !_flags.markedAsReferenced)
        return NULL;
    
    whitespaceBehavior = [[doc whitespaceBehavior] behaviorForElementName: _name];
    if (whitespaceBehavior == OFXMLWhitespaceBehaviorTypeAuto)
        whitespaceBehavior = parentBehavior;
    
    memset(&element, 0, sizeof(element));
    element.isEmpty        = ([_children count] == 0);
    element.attributeOrder = (CFArrayRef)_attributeOrder;

    // Quote the attribute values
    CFStringEncoding encoding = [doc stringEncoding];
    NSMutableDictionary *quotedAttributes = [[NSMutableDictionary alloc] init];
    unsigned int attributeIndex = [_attributeOrder count];
    while (attributeIndex--) {
        NSString *name = [_attributeOrder objectAtIndex:attributeIndex];
        NSString *value = [_attributes objectForKey:name];
        if (value) {
            value = OFXMLCreateStringWithEntityReferencesInCFEncoding(value, OFXMLBasicEntityMask, nil, encoding);
            [quotedAttributes setObject:value forKey:name];
            [value release];
        }
    }
    
    element.attributes = (CFDictionaryRef)quotedAttributes;
    
    node = CFXMLNodeCreate(kCFAllocatorDefault, kCFXMLNodeTypeElement, (CFStringRef)_name, &element, kCFXMLNodeCurrentVersion);
    tree = CFXMLTreeCreateWithNode(kCFAllocatorDefault, node);
    CFRelease(node);
    [quotedAttributes release];
    
    // Now add all our children.
    unsigned int childIndex, childCount = [_children count];
    BOOL doIntenting = NO;
    
    // If we have actual element children and whitespace isn't important for this node, do some formatting.
    // We will produce output that is a little strange for something like '<x>foo<y/></x>' or any other mix of string and element children, but usually whitespace is important in this case and it won't be an issue.
    if (whitespaceBehavior == OFXMLWhitespaceBehaviorTypeIgnore)  {
        for (childIndex = 0; childIndex < childCount; childIndex++) {
            id child;
            child = [_children objectAtIndex: childIndex];
            if ([child isKindOfClass: [OFXMLElement class]]) {
                doIntenting = YES;
                break;
            }
        }
    }

    CFXMLTreeRef childTree, spaceTree;

    // TJW: Spacing will not be perfect here if all the children get ignored
    
    if (doIntenting) {
        spaceTree = [isa createNewlineTree];
        CFTreeAppendChild(tree, spaceTree);
        CFRelease(spaceTree);
    }
    
    for (childIndex = 0; childIndex < childCount; childIndex++) {
        id child = [_children objectAtIndex:childIndex];
        childTree = [isa createTreeForValue: child parentWhiteSpaceBehavior:whitespaceBehavior document:doc level:level+1];
        if (!childTree)
            continue;
        
        if (doIntenting) {
            spaceTree = [isa createSpaceTree: 2 * (level + 1)];
            CFTreeAppendChild(tree, spaceTree);
            CFRelease(spaceTree);
        }

        CFTreeAppendChild(tree, childTree);
        CFRelease(childTree);

        if (doIntenting) {
            spaceTree = [isa createNewlineTree];
            CFTreeAppendChild(tree, spaceTree);
            CFRelease(spaceTree);
        }
    }

    if (doIntenting) {
        spaceTree = [isa createSpaceTree: 2 * level];
        CFTreeAppendChild(tree, spaceTree);
        CFRelease(spaceTree);
    }

    return tree;
}

+ (CFXMLTreeRef) createTreeForValue: (id) value parentWhiteSpaceBehavior: (OFXMLWhitespaceBehaviorType) parentBehavior document: (OFXMLDocument *) doc level: (unsigned int) level;
{
    if ([value respondsToSelector: @selector(createTreeWithParentWhiteSpaceBehavior:document:level:)])
        return [value createTreeWithParentWhiteSpaceBehavior:parentBehavior document:doc level:level];
    else {
        // Encode using defaults
        OBASSERT([value isKindOfClass:[NSString class]]);
        return [self createTextTree:value quotingMask:OFXMLBasicEntityMask newlineReplacement:nil stringEncoding:[doc stringEncoding]];
    }
}


+ (CFXMLTreeRef) createNewlineTree;
{
    return [self _createWhitespaceTree: @"\n"];
}

+ (CFXMLTreeRef) createSpaceTree: (unsigned int) spaces;
{
    return [self _createWhitespaceTree: [NSString spacesOfLength: spaces]];
}

+ (CFXMLTreeRef) createTextTree: (NSString *) text quotingMask: (unsigned int) quotingMask newlineReplacement: (NSString *) newlineReplacement stringEncoding: (CFStringEncoding) stringEncoding;
{
    CFXMLTreeRef     tree;
    CFXMLNodeRef     node;

    text = OFXMLCreateStringWithEntityReferencesInCFEncoding(text, quotingMask, newlineReplacement, stringEncoding);
    node = CFXMLNodeCreate(kCFAllocatorDefault, kCFXMLNodeTypeText, (CFStringRef)text, NULL, kCFXMLNodeCurrentVersion);
    [text release];
    
    tree = CFXMLTreeCreateWithNode(kCFAllocatorDefault, node);
    CFRelease(node);

    return tree;
}

//
// Debugging
//

- (NSMutableDictionary *) debugDictionary;
{
    NSMutableDictionary *debugDictionary;

    debugDictionary = [super debugDictionary];
    [debugDictionary setObject: _name forKey: @"_name"];
    if (_children)
        [debugDictionary setObject: _children forKey: @"_children"];
    if (_attributes) {
        [debugDictionary setObject: _attributeOrder forKey: @"_attributeOrder"];
        [debugDictionary setObject: _attributes forKey: @"_attributes"];
    }

    return debugDictionary;
}

@end

@implementation OFXMLElement (OFXMLReading)

// Note that we CANNOT simply retain the inputs since CFXMLParser plays funky games with memory managment of its parse structures for speed.
- initWithName: (NSString *) name elementInfo: (const CFXMLElementInfo *) elementInfo;
{
    OBPRECONDITION([(id)elementInfo->attributeOrder count] == [(id)elementInfo->attributes count]);

    if (!(self = [self initWithName: name]))
        return nil;
    
    unsigned int attrIndex, attrCount;
    attrCount = [(id)elementInfo->attributeOrder count];
    if (attrCount) {
        _attributeOrder = [[NSMutableArray alloc] initWithArray: (id)elementInfo->attributeOrder];
        _attributes     = [[NSMutableDictionary alloc] init];
        
        for (attrIndex = 0; attrIndex < attrCount; attrIndex++) {
            NSString *key = [_attributeOrder objectAtIndex: attrIndex];
            NSString *value = [(id)elementInfo->attributes objectForKey: key];
            OBASSERT(value); // i.e., the keys of the attributes dictionary must match up with the attribute order listing!

            // Parse entities up front so callers always get nice Unicode strings w/o worrying about this muck.
            value = OFXMLCreateParsedEntityString(value);

            [_attributes setObject: value forKey: key];
            [value release];
        }
    }

    return self;
}

@end

@implementation OFXMLElement (PrivateAPI)

+ (CFXMLTreeRef) _createWhitespaceTree: (NSString *) string;
{
    CFXMLTreeRef     tree;
    CFXMLNodeRef     node;

    node = CFXMLNodeCreate(kCFAllocatorDefault, kCFXMLNodeTypeWhitespace, (CFStringRef)string, NULL, kCFXMLNodeCurrentVersion);
    tree = CFXMLTreeCreateWithNode(kCFAllocatorDefault, node);
    CFRelease(node);

    return tree;
}

@end

