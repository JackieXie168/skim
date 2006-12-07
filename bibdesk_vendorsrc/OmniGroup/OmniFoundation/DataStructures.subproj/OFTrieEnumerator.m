// Copyright 1997-2005 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import "OFTrieEnumerator.h"

#import <Foundation/Foundation.h>
#import <OmniBase/OmniBase.h>

#import <OmniFoundation/OFTrie.h>
#import <OmniFoundation/OFTrieNode.h>

RCS_ID("$Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/OmniSourceRelease_2006-09-07/OmniGroup/Frameworks/OmniFoundation/DataStructures.subproj/OFTrieEnumerator.m 68913 2005-10-03 19:36:19Z kc $")

@implementation OFTrieEnumerator

static NSCharacterSet *uppercaseLetters;

+ (void)initialize;
{
    OBINITIALIZE;

    uppercaseLetters = [[NSCharacterSet uppercaseLetterCharacterSet] retain];
}

- initWithTrie:(OFTrie *)aTrie;
{
    [super init];
    trieNodes = [[NSMutableArray alloc] init];
    positions = [[NSMutableArray alloc] init];
    [trieNodes addObject:[aTrie headNode]];
    [positions addObject:[NSNumber numberWithInt:0]];
    isCaseSensitive = [aTrie isCaseSensitive];
    return self;
}

- (id)nextObject;
{
    OFTrieNode *node;
    unsigned int position;

    node = [trieNodes lastObject];
    position = [[positions lastObject] intValue];
    while (1) {
        OFTrieNode *child;

        if (position >= node->childCount) {
            [trieNodes removeLastObject];
            [positions removeLastObject];
            if (![trieNodes count])
                return nil;
            node = [trieNodes lastObject];
            position = [[positions lastObject] intValue] + 1;
            continue;
        } else if (!isCaseSensitive && [uppercaseLetters characterIsMember:node->characters[position]]) {
            position++;
            continue;
        }
        child = node->children[position];
        if ([child isKindOfClass:[OFTrieNode class]]) {
            [trieNodes addObject:child];
            [positions removeLastObject];
            [positions addObject:[NSNumber numberWithInt:position]];
            [positions addObject:[NSNumber numberWithInt:0]];
            node = child;
            position = 0;
            continue;
        } else {
            [positions removeLastObject];
            [positions addObject:[NSNumber numberWithInt:++position]];
            return child;
        }
    }
}

@end
