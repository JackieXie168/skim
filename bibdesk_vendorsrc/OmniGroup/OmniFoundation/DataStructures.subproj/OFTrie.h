// Copyright 1997-2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniFoundation/DataStructures.subproj/OFTrie.h,v 1.12 2003/01/15 22:51:55 kc Exp $

#import <OmniFoundation/OFObject.h>

@class OFTrieBucket, OFTrieNode;

@interface OFTrie : OFObject
{
    OFTrieNode *head;
    BOOL caseSensitive;
}

- initCaseSensitive:(BOOL)shouldBeCaseSensitive;
- (NSEnumerator *)objectEnumerator;
- (BOOL)isCaseSensitive;
- (void)addBucket:(OFTrieBucket *)bucket forString:(NSString *)aString;
- (OFTrieBucket *)bucketForString:(NSString *)aString;
- (OFTrieNode *)headNode;

@end
