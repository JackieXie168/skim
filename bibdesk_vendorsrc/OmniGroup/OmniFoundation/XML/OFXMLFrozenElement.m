// Copyright 2003-2005 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import "OFXMLFrozenElement.h"

#import <OmniFoundation/CFArray-OFExtensions.h>
#import <OmniFoundation/OFXMLDocument.h>
#import <OmniFoundation/OFXMLElement.h>
#import <OmniFoundation/OFXMLString.h>
#import <Foundation/Foundation.h>
#import <OmniBase/rcsid.h>

#import "OFXMLBuffer.h"

RCS_ID("$Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/OmniSourceRelease_2006-09-07/OmniGroup/Frameworks/OmniFoundation/XML/OFXMLFrozenElement.m 66265 2005-07-29 04:07:59Z bungi $");

#define SAFE_ALLOCA_SIZE (8 * 8192)

@implementation OFXMLFrozenElement

- initWithName:(NSString *)name children:(NSArray *)children attributes:(NSDictionary *)attributes attributeOrder:(NSArray *)attributeOrder;
{
    _name = [name copy];

    // Create with a fixed capacity
    unsigned int childIndex, childCount = [children count];
    if (childCount) {
        NSMutableArray *frozenChildren = (NSMutableArray *)CFArrayCreateMutable(kCFAllocatorDefault, childCount, &OFNSObjectArrayCallbacks);
        for (childIndex = 0; childIndex < childCount; childIndex++) {
            id child = [[children objectAtIndex:childIndex] createFrozenElement];
            [frozenChildren addObject:child];
            [child release];
        }

        _children = [[NSArray alloc] initWithArray:frozenChildren];
        [frozenChildren release];
    }

    if (attributeOrder) {
        unsigned int attributeIndex, attributeCount = [attributeOrder count];

	// Should only be a few attributes in the vastly common case
	size_t bufferSize = 2*attributeCount*sizeof(id);
	BOOL useMalloc = bufferSize >= SAFE_ALLOCA_SIZE;	
	
	id *buffer = useMalloc ? (id *)malloc(bufferSize) : (id *)alloca(bufferSize);
	unsigned int bufferIndex = 0;

        for (attributeIndex = 0; attributeIndex < attributeCount; attributeIndex++) {
            NSString *name = [attributeOrder objectAtIndex:attributeIndex];
            NSString *value = [attributes objectForKey:name];
            if (!value)
                continue;

            // TODO: It would be nice to pre-quote the values here, but that would require us to know the target encoding (and then if the user decided to change encodings, we'd need to be able to deal with that somehow).
	    buffer[bufferIndex + 0] = name;
	    buffer[bufferIndex + 1] = value;
	    bufferIndex += 2;
        }

        _attributeNamesAndValues = [[NSArray alloc] initWithObjects:buffer count:bufferIndex];
	if (useMalloc)
	    free(buffer);
    }

    return self;
}

- (void)dealloc;
{
    [_name release];
    [_children release];
    [_attributeNamesAndValues release];
    [super dealloc];
}

// Needed for -[OFXMLElement firstChildNamed:]
- (NSString *)name;
{
    return _name;
}

// This is mostly the same as the OFXMLElement version, but trimmed down to reflect the different storage format
- (void)appendXML:(struct _OFXMLBuffer *)xml withParentWhiteSpaceBehavior: (OFXMLWhitespaceBehaviorType) parentBehavior document: (OFXMLDocument *) doc level: (unsigned int) level;
{
    OFXMLWhitespaceBehaviorType whitespaceBehavior;

    whitespaceBehavior = [[doc whitespaceBehavior] behaviorForElementName: _name];
    if (whitespaceBehavior == OFXMLWhitespaceBehaviorTypeAuto)
        whitespaceBehavior = parentBehavior;

    OFXMLBufferAppendASCIICString(xml, "<");
    OFXMLBufferAppendString(xml, (CFStringRef)_name);

    if (_attributeNamesAndValues) {
        // Quote the attribute values
        CFStringEncoding encoding = [doc stringEncoding];
        unsigned int attributeIndex, attributeCount = [_attributeNamesAndValues count] / 2;
        for (attributeIndex = 0; attributeIndex < attributeCount; attributeIndex++) {
            NSString *name  = [_attributeNamesAndValues objectAtIndex:2*attributeIndex+0];
            NSString *value = [_attributeNamesAndValues objectAtIndex:2*attributeIndex+1];
            
            OFXMLBufferAppendASCIICString(xml, " ");
            OFXMLBufferAppendString(xml, (CFStringRef)name);

            OFXMLBufferAppendASCIICString(xml, "=\"");
            NSString *quotedString = OFXMLCreateStringWithEntityReferencesInCFEncoding(value, OFXMLBasicEntityMask, nil, encoding);
            OFXMLBufferAppendString(xml, (CFStringRef)quotedString);
            [quotedString release];
            OFXMLBufferAppendASCIICString(xml, "\"");
        }
    }

    BOOL hasWrittenChild = NO;
    BOOL doIntenting = NO;

    // See if any of our children are non-ignored and use this for isEmpty instead of the plain count
    unsigned int childIndex, childCount = [_children count];
    for (childIndex = 0; childIndex < childCount; childIndex++) {
        id child = [_children objectAtIndex:childIndex];

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

@end
