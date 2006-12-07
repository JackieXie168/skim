// Copyright 1997-2005 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import <OmniFoundation/OFTrie.h>

#import <Foundation/Foundation.h>
#import <OmniBase/OmniBase.h>

#import <OmniFoundation/OFTrieNode.h>
#import <OmniFoundation/OFTrieBucket.h>

#import "OFTrieEnumerator.h"

RCS_ID("$Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/OmniSourceRelease_2006-09-07/OmniGroup/Frameworks/OmniFoundation/DataStructures.subproj/OFTrie.m 68913 2005-10-03 19:36:19Z kc $")

@implementation OFTrie

// Init and dealloc

- initCaseSensitive:(BOOL)shouldBeCaseSensitive;
{
    if (![super init])
        return nil;

    head = [[OFTrieNode allocWithZone:[self zone]] init];
    caseSensitive = shouldBeCaseSensitive;

    return self;
}

- (void)dealloc;
{
    [head release];
    [super dealloc];
}

//

- (NSEnumerator *)objectEnumerator;
{
    return [[[OFTrieEnumerator alloc] initWithTrie:self] autorelease];
}

- (BOOL)isCaseSensitive;
{
    return caseSensitive;
}

#define SAFE_ALLOCA_SIZE (8 * 8192)

- (void)addBucket:(OFTrieBucket *)bucket forString:(NSString *)aString;
{
    unsigned int length;
    unichar *buffer, *upperBuffer, *ptr;
    OFTrieNode *to, *attachTo = head;
    Class trieNodeClass;
    unsigned int bufferSize;
    BOOL useMalloc;

    length = [aString length];
    bufferSize = (length + 1) * sizeof(unichar);
    useMalloc = bufferSize * 2 >= SAFE_ALLOCA_SIZE;
    if (useMalloc) {
	buffer = (unichar *)NSZoneMalloc(NULL, bufferSize);
    } else {
        buffer = (unichar *)alloca(bufferSize);
    }
    if (!caseSensitive) {
        if (useMalloc) {
            upperBuffer = (unichar *)NSZoneMalloc(NULL, bufferSize);
        } else {
            upperBuffer = (unichar *)alloca(bufferSize);
        }
    } else {
        upperBuffer = NULL; // Let's just ensure that nobody dereferences this
    }

    ptr = buffer;

    if (!caseSensitive) {
#warning -addBucket:forString: assumes that -uppercaseString and -lowercaseString return strings of identical length as the original string
        // This isn't actually true for unicode.
        // Also, they assume that string equality is equivalent to having the same unichars in the same sequence, which isn't generally true for unicode.

        aString = [aString uppercaseString];
	[aString getCharacters:upperBuffer];
	upperBuffer[length] = '\0';
	aString = [aString lowercaseString];
    }
    [aString getCharacters:buffer];
    buffer[length] = '\0';
    trieNodeClass = ((OFTrie *)head)->isa;
    if (head->childCount != 0) {
	while ((to = trieFindChild(attachTo, *ptr))) {
            if (((OFTrie *)to)->isa != trieNodeClass) {
		OFTrieBucket *existingBucket;
		OFTrieNode *end;
		unichar *existingPtr;
		unichar *ptrPosition;

		if (!*ptr)
		    break;
		existingBucket = (OFTrieBucket *)to;
		end = attachTo;
		existingPtr = existingBucket->lowerCharacters - 1;
		ptrPosition = ptr;
                [existingBucket retain];
		do {
                    OFTrieNode *new;

                    new = [[OFTrieNode allocWithZone:[end zone]] init];
		    [end addChild:new withCharacter:*ptr];
                    if (!caseSensitive)
                        [end addChild:new withCharacter:upperBuffer[ptr - buffer]];
		    [new release];
		    end = new;
		    ptr++;
		    existingPtr++;
		} while (*ptr && *ptr == *existingPtr);

		if (*existingPtr || *ptr) {
                    unsigned int offset;

                    offset = existingPtr - existingBucket->lowerCharacters;
		    if (*existingPtr) {
                        unsigned int existingLength;

			[end addChild:existingBucket withCharacter:*existingPtr];
                        if (!caseSensitive)
                            [end addChild:existingBucket withCharacter:existingBucket->upperCharacters[offset]];
		
                        existingLength = 0;
                        while (*++existingPtr != '\0')
                            existingLength++;
			offset++;
			[existingBucket setRemainingLower:existingBucket->lowerCharacters + offset upper:existingBucket->upperCharacters + offset length:existingLength];
		    } else {
			[end addChild:existingBucket withCharacter:0];
			offset++;
			[existingBucket setRemainingLower:existingBucket->lowerCharacters + offset upper:existingBucket->upperCharacters + offset length:0];
		    }
		    attachTo = end;
		} else {
		    ptr = ptrPosition;
		}
                [existingBucket release];
		break;
	    }
	    attachTo = to;
	    ptr++;	
	}
    }
    [attachTo addChild:bucket withCharacter:*ptr];
    if (caseSensitive) {
        ptr++;
	[bucket setRemainingLower:ptr upper:ptr length:length - (ptr - buffer)];
    } else {
        [attachTo addChild:bucket withCharacter:upperBuffer[ptr - buffer]];
        ptr++;
	[bucket setRemainingLower:ptr upper:upperBuffer + (ptr - buffer) length:length - (ptr - buffer)];
    }

    if (useMalloc) {
	NSZoneFree(NULL, buffer);
        if (!caseSensitive)
            NSZoneFree(NULL, upperBuffer);
    }
}

- (OFTrieBucket *)bucketForString:(NSString *)aString;
{
    unsigned int length;
    unichar *buffer, *ptr;
    OFTrieNode *currentNode;
    Class trieNodeClass;
    BOOL useMalloc;

    if (head->childCount == 0)
	return nil;

    length = [aString length];
    useMalloc = (length + 1) * sizeof(*buffer) >= SAFE_ALLOCA_SIZE;
    if (useMalloc)
	buffer = (unichar *)NSZoneMalloc(NULL, (length + 1) * sizeof(*buffer));
    else
	buffer = (unichar *)alloca((length + 1) * sizeof(*buffer));
    [aString getCharacters:buffer];
    buffer[length] = 0;
    ptr = buffer;
    currentNode = head;
    trieNodeClass = ((OFTrie *)head)->isa;
    while ((currentNode = trieFindChild(currentNode, *ptr++))) {
	if (((OFTrie *)currentNode)->isa != trieNodeClass) {
	    OFTrieBucket *test;
	    unichar *lowerPtr, *upperPtr;

	    test = (OFTrieBucket *)currentNode;
	    lowerPtr = test->lowerCharacters;
	    upperPtr = test->upperCharacters;
	    if (!ptr[-1] && !*lowerPtr) {
		if (useMalloc)
		    NSZoneFree(NULL, buffer);
		return test;
	    }
	    while (*ptr) {
		if (*ptr != *lowerPtr && *ptr != *upperPtr)
		    return nil;
		lowerPtr++, upperPtr++, ptr++;
	    }
	    if (useMalloc)
		NSZoneFree(NULL, buffer);
	    return *lowerPtr ? nil : test;
	}
    }
    if (useMalloc)
	NSZoneFree(NULL, buffer);
    return nil;
}

- (OFTrieNode *)headNode;
{
    return head;
}

// Debugging

- (NSMutableDictionary *)debugDictionary;
{
    NSMutableDictionary *debugDictionary;

    debugDictionary = [super debugDictionary];
    [debugDictionary setObject:head forKey:@"head"];
    return debugDictionary;
}

@end
