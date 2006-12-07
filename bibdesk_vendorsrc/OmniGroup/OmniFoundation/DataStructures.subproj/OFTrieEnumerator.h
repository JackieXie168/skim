// Copyright 1997-2004 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniFoundation/DataStructures.subproj/OFTrieEnumerator.h,v 1.10 2004/02/10 04:07:44 kc Exp $

#import <Foundation/NSEnumerator.h>

@class NSMutableArray;
@class OFTrie;

@interface OFTrieEnumerator : NSEnumerator
{
    NSMutableArray *trieNodes;
    NSMutableArray *positions;
    BOOL isCaseSensitive;
}

- initWithTrie:(OFTrie *)aTrie;
- (id)nextObject;

@end
