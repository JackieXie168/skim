//
//  SKVersionNumber.h
//  Skim
//
//  Created by Christiaan Hofman on 2/15/07.

// Much of this code is copied and modified from OmniFoundation/OFVersionNumber and subject to the following copyright.

// Copyright 2004-2005 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header$

#import <Foundation/Foundation.h>

enum {
    SKReleaseVersionType,
    SKReleaseCandidateVersionType,
    SKBetaVersionType,
    SKAlphaVersionType,
};

@interface SKVersionNumber : NSObject <NSCopying>
{
    NSString *originalVersionString;
    NSString *cleanVersionString;
    
    unsigned int componentCount;
    int *components;
    int releaseType;
}

- (id)initWithVersionString:(NSString *)versionString;

- (NSString *)originalVersionString;
- (NSString *)cleanVersionString;

- (unsigned int)componentCount;
- (int)componentAtIndex:(unsigned int)componentIndex;

- (int)releaseType;
- (BOOL)isRelease;
- (BOOL)isReleaseCandidate;
- (BOOL)isBeta;
- (BOOL)isAlpha;

- (NSComparisonResult)compareToVersionNumber:(SKVersionNumber *)otherVersion;

@end
