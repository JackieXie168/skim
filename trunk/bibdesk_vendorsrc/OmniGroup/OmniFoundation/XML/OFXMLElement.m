// Copyright 2003-2005 Omni Development, Inc.  All rights reserved.
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
#import <OmniFoundation/CFArray-OFExtensions.h>

#import "OFXMLBuffer.h"
#import "OFXMLFrozenElement.h"

RCS_ID("$Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/OmniSourceRelease_2006-09-07/OmniGroup/Frameworks/OmniFoundation/XML/OFXMLElement.m 66265 2005-07-29 04:07:59Z bungi $");

@interface OFXMLElement (PrivateAPI)
@end

struct {
    NSLock        *lock;
    NSString     **levelStrings;
    unsigned int   levelCount;
} indentationState;

// +[NSString(OFExtensions) spacesOfLength:] works, but it returns an autoreleased substring of a shared string of spaces.  We can use a LOT of these when writing a big document with indentation, so we want to avoid all the extra creation/autorelease of the substrings.
CFStringRef OFXMLGetIndentationString(unsigned int level)
{
    // No need for locking if we don't need to create elements (since levelCount only increases)
    if (level >= indentationState.levelCount) {
        [indentationState.lock lock];

        // Check again in the lock (so that we don't cause deallocation of some previously returned string that the caller expects to have 'autoreleased' semantics)
        while (level >= indentationState.levelCount) {
            indentationState.levelStrings = realloc(indentationState.levelStrings, sizeof(indentationState.levelStrings) * (indentationState.levelCount + 1));
            indentationState.levelStrings[indentationState.levelCount] = [[NSString spacesOfLength:2*indentationState.levelCount] retain];
            indentationState.levelCount++;
        }

        [indentationState.lock unlock];
    }
    return (CFStringRef)indentationState.levelStrings[level];
}

@implementation OFXMLElement

+ (void)initialize;
{
    OBINITIALIZE;
    
    indentationState.lock = [[NSLock alloc] init];
}

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
    return [self deepCopyWithName:_name];
}

- (OFXMLElement *)deepCopyWithName:(NSString *)name;
{
    OFXMLElement *newElement = [[OFXMLElement alloc] initWithName:name];
    
    if (_attributeOrder != nil)
        newElement->_attributeOrder = [[NSMutableArray alloc] initWithArray:_attributeOrder];
    
    if (_attributes != nil)
        newElement->_attributes = [_attributes mutableCopy];	// don't need a deep copy because all the attributes are non-mutable strings, but we don need a unique copy of the attributes dictionary

    unsigned int childIndex, childCount = [_children count];
    for (childIndex = 0; childIndex < childCount; childIndex++) {
        BOOL copied = NO;

        id child = [_children objectAtIndex:childIndex];
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

- (unsigned int)childrenCount;
{
    return [_children count];
}

- (id) childAtIndex: (unsigned int) childIndex;
{
    return [_children objectAtIndex: childIndex];
}

- (id) lastChild;
{
    return [_children lastObject];
}

- (unsigned int)indexOfChildIdenticalTo:(id)child;
{
    return [_children indexOfObjectIdenticalTo:child];
}

- (void)insertChild:(id)child atIndex:(unsigned int)childIndex;
{
    if (!_children) {
        OBASSERT(childIndex == 0); // Else, certain doom
        _children = [[NSMutableArray alloc] initWithObjects:&child count:1];
    }
    [_children insertObject:child atIndex:childIndex];
}

- (void)appendChild:(id)child;  // Either a OFXMLElement or an NSString
{
    OBPRECONDITION([child respondsToSelector:@selector(appendXML:withParentWhiteSpaceBehavior:document:level:)]);

    if (!_children)
	// This happens a lot; avoid the placeholder goo
	_children = (NSMutableArray *)CFArrayCreateMutable(kCFAllocatorDefault, 0, &OFNSObjectArrayCallbacks);
    CFArrayAppendValue((CFMutableArrayRef)_children, child);
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

- (void)removeAllChildren;
{
    [_children removeAllObjects];
}

- (void)sortChildrenUsingFunction:(int (*)(id, id, void *))comparator context:(void *)context;
{
    [_children sortUsingFunction:comparator context:context];
}

// TODO: Really need a common superclass for OFXMLElement and OFXMLFrozenElement
- (OFXMLElement *)firstChildNamed:(NSString *)childName;
{
    unsigned int childIndex, childCount = [_children count];
    for (childIndex = 0; childIndex < childCount; childIndex++) {
        id child = [_children objectAtIndex:childIndex];
        if ([child respondsToSelector:@selector(name)]) {
            NSString *name = [child name];
            if ([name isEqualToString:childName])
                return child;
        }
    }

    return nil;
}

// Does a bunch of -firstChildNamed: calls with each name split by '/'.  This isn't XPath, just a convenience.  Don't put a '/' at the beginning since there is always relative to the receiver.
- (OFXMLElement *)firstChildAtPath:(NSString *)path;
{
    OBPRECONDITION([path hasPrefix:@"/"] == NO);
    
    // Not terribly efficient.  Might use CF later to avoid autoreleases at least.
    NSArray *pathComponents = [path componentsSeparatedByString:@"/"];
    unsigned int pathIndex, pathCount = [pathComponents count];

    OFXMLElement *currentElement = self;
    for (pathIndex = 0; pathIndex < pathCount; pathIndex++)
        currentElement = [currentElement firstChildNamed:[pathComponents objectAtIndex:pathIndex]];
    return currentElement;
}


- (OFXMLElement *)firstChildWithAttribute:(NSString *)attributeName value:(NSString *)value;
{
    OBPRECONDITION(attributeName);
    OBPRECONDITION(value); // Can't look for unset attributes for now.
    
    unsigned int childIndex, childCount = [_children count];
    for (childIndex = 0; childIndex < childCount; childIndex++) {
        id child = [_children objectAtIndex:childIndex];
        if ([child respondsToSelector:@selector(attributeNamed:)]) {
            NSString *attributeValue = [child attributeNamed:attributeName];
            if ([value isEqualToString:attributeValue])
                return child;
        }
    }
    
    return nil;
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

- (void)sortAttributesUsingFunction:(int (*)(id, id, void *))comparator context:(void *)context;
{
    [_attributeOrder sortUsingFunction:comparator context:context];
}

- (void)sortAttributesUsingSelector:(SEL)comparator;
{
    [_attributeOrder sortUsingSelector:comparator];
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

- (BOOL)shouldIgnore;
{
    if (_flags.ignoreUnlessReferenced)
        return !_flags.markedAsReferenced;
    return NO;
}

- (void)applyFunction:(OFXMLElementApplier)applier context:(void *)context;
{
    // We are an element
    applier(self, context);
    
    unsigned int childIndex, childCount = [_children count];
    for (childIndex = 0; childIndex < childCount; childIndex++) {
	id child = [_children objectAtIndex:childIndex];
	if ([child respondsToSelector:_cmd])
	    [(OFXMLElement *)child applyFunction:applier context:context];
    }
}

//
// NSObject (OFXMLWriting)
//
- (void)appendXML:(struct _OFXMLBuffer *)xml withParentWhiteSpaceBehavior: (OFXMLWhitespaceBehaviorType) parentBehavior document: (OFXMLDocument *) doc level: (unsigned int) level;
{
    OFXMLWhitespaceBehaviorType whitespaceBehavior;

    if (_flags.ignoreUnlessReferenced && !_flags.markedAsReferenced)
        return;

    whitespaceBehavior = [[doc whitespaceBehavior] behaviorForElementName: _name];
    if (whitespaceBehavior == OFXMLWhitespaceBehaviorTypeAuto)
        whitespaceBehavior = parentBehavior;

    OFXMLBufferAppendASCIICString(xml, "<");
    OFXMLBufferAppendString(xml, (CFStringRef)_name);
    
    if (_attributeOrder) {
        // Quote the attribute values
        CFStringEncoding encoding = [doc stringEncoding];
        unsigned int attributeIndex, attributeCount = [_attributeOrder count];
        for (attributeIndex = 0; attributeIndex < attributeCount; attributeIndex++) {
            NSString *name = [_attributeOrder objectAtIndex:attributeIndex];
            OFXMLBufferAppendASCIICString(xml, " ");
            OFXMLBufferAppendString(xml, (CFStringRef)name);
            
            NSString *value = [_attributes objectForKey:name];
            if (value) {
                OFXMLBufferAppendASCIICString(xml, "=\"");
                NSString *quotedString = OFXMLCreateStringWithEntityReferencesInCFEncoding(value, OFXMLBasicEntityMask, nil, encoding);
                OFXMLBufferAppendString(xml, (CFStringRef)quotedString);
                [quotedString release];
                OFXMLBufferAppendASCIICString(xml, "\"");
            }
        }
    }

    BOOL hasWrittenChild = NO;
    BOOL doIntenting = NO;
    
    // See if any of our children are non-ignored and use this for isEmpty instead of the plain count
    unsigned int childIndex, childCount = [_children count];
    for (childIndex = 0; childIndex < childCount; childIndex++) {
        id child = [_children objectAtIndex:childIndex];
        if ([child respondsToSelector:@selector(shouldIgnore)] && [child shouldIgnore])
            continue;
        
        // If we have actual element children and whitespace isn't important for this node, do some formatting.
        // We will produce output that is a little strange for something like '<x>foo<y/></x>' or any other mix of string and element children, but usually whitespace is important in this case and it won't be an issue.
        if (whitespaceBehavior == OFXMLWhitespaceBehaviorTypeIgnore)  {
            doIntenting = [child xmlRepresentationCanContainChildren];
        }

        // Close off the parent tag if this is the first child
        if (!hasWrittenChild)
            OFXMLBufferAppendASCIICString(xml, ">");
        
        if (doIntenting) {
            OFXMLBufferAppendASCIICString(xml, "\n");
            OFXMLBufferAppendString(xml, OFXMLGetIndentationString(level + 1));
        }

        [child appendXML:xml withParentWhiteSpaceBehavior:whitespaceBehavior document:doc level:level+1];

        hasWrittenChild = YES;
    }

    if (doIntenting) {
        OFXMLBufferAppendASCIICString(xml, "\n");
        OFXMLBufferAppendString(xml, OFXMLGetIndentationString(level));
    }
    
    if (hasWrittenChild) {
        OFXMLBufferAppendASCIICString(xml, "</");
        OFXMLBufferAppendString(xml, (CFStringRef)_name);
        OFXMLBufferAppendASCIICString(xml, ">");
    } else
        OFXMLBufferAppendASCIICString(xml, "/>");
}

- (BOOL)xmlRepresentationCanContainChildren;
{
    return YES;
}

- (NSObject *)createFrozenElement;
{
    // Frozen elements don't have any support for marking referenced
    return [[OFXMLFrozenElement alloc] initWithName:_name children:_children attributes:_attributes attributeOrder:_attributeOrder];
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


@implementation NSObject (OFXMLWritingPartial)

#if 0 // NOT implementing this since our precondition in -appendChild: is easier this way.
- (void)appendXML:(struct _OFXMLBuffer *)xml withParentWhiteSpaceBehavior: (OFXMLWhitespaceBehaviorType) parentBehavior document: (OFXMLDocument *) doc level: (unsigned int) level;
{
    OBRejectUnusedImplementation(isa, _cmd);
}
#endif

- (BOOL)xmlRepresentationCanContainChildren;
{
    return NO;
}

- (NSObject *)createFrozenElement;
{
    return [self retain];
}
@end
