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

#import "SKVersionNumber.h"


@implementation SKVersionNumber

// Initializes the receiver from a string representation of a version number.  The input string may have an optional leading 'v' or 'V' followed by a sequence of positive integers separated by '.'s.  Any trailing component of the input string that doesn't match this pattern is ignored.  If no portion of this string matches the pattern, nil is returned.
- (id)initWithVersionString:(NSString *)versionString;
{
    
    if (self = [super init]) {
        // Input might be from a NSBundle info dictionary that could be misconfigured, so check at runtime too
        if (versionString == nil || [versionString isKindOfClass:[NSString class]] == NO) {
            [self release];
            return nil;
        }
        
        originalVersionString = [versionString copy];
        releaseType = SKReleaseVersionType;
        
        NSMutableString *mutableVersionString = [[NSMutableString alloc] init];
        NSString *lastSep = @"";
        NSScanner *scanner = [[NSScanner alloc] initWithString:versionString];
        
        [scanner setCharactersToBeSkipped:nil];
        
        unichar c = [versionString length] ? [versionString characterAtIndex:0] : 0;
        if (c == 'v' || c == 'V')
            [scanner setScanLocation:1];

        while ([scanner isAtEnd] == NO) {
            int component;

            if ([scanner scanInt:&component] == NO || component < 0)
                // Failed to scan integer
                break;

            [mutableVersionString appendFormat: @"%@%u", lastSep, component];

            componentCount++;
            components = realloc(components, sizeof(*components) * componentCount);
            components[componentCount - 1] = component;
            
            if ([scanner isAtEnd])
                break;
            
            c = [versionString characterAtIndex:[scanner scanLocation]];
            if (c == '.') {
                lastSep = @".";
            } else if (releaseType == SKReleaseVersionType) {
                if (c == 'a' || c == 'A') {
                    releaseType = SKAlphaVersionType;
                    lastSep = c == 'a' ? @"a" : @"A";
                } else if (c == 'b' || c == 'B') {
                    releaseType = SKBetaVersionType;
                    lastSep = c == 'b' ? @"b" : @"B";
                } else if (c == 'r' || c == 'R') {
                    scannerSkipPeekedCharacter(scanner);
                    c = scannerPeekCharacter(scanner);
                    if (c != 'c' && c != 'C')
                        break;
                    releaseType = SKReleaseCandidateVersionType;
                    lastSep = c == 'c' ? @"rc" : @"RC";
                } else 
                    break;
                
                componentCount++;
                components = realloc(components, sizeof(*components) * componentCount);
                components[componentCount - 1] = releaseType;
            } else
                break;
            [scanner setScanLocation:[scanner scanLocation] + 1];
        }

        if ([mutableVersionString isEqualToString:originalVersionString])
            cleanVersionString = [originalVersionString retain];
        else
            cleanVersionString = [mutableVersionString copy];
        
        [mutableVersionString release];
        [scanner release];

        if (componentCount == 0) {
            // Failed to parse anything and we don't allow empty version strings.  For now, we'll not assert on this, since people might want to use this to detect if a string begins with a valid version number.
            [self release];
            return nil;
        }
    }
    return self;
}

- (void)dealloc;
{
    [originalVersionString release];
    [cleanVersionString release];
    if (components)
        free(components);
    [super dealloc];
}

#pragma mark API

- (NSString *)originalVersionString;
{
    return originalVersionString;
}

- (NSString *)cleanVersionString;
{
    return cleanVersionString;
}

- (unsigned int)componentCount;
{
    return componentCount;
}

- (int)componentAtIndex:(unsigned int)componentIndex;
{
    // This treats the version as a infinite sequence ending in "...0.0.0.0", making comparison easier
    if (componentIndex < componentCount)
        return components[componentIndex];
    return 0;
}

- (int)releaseType;
{
    return releaseType;
}

- (BOOL)isRelease;
{
    return releaseType == SKReleaseVersionType;
}

- (BOOL)isReleaseCandidate;
{
    return releaseType == SKReleaseCandidateVersionType;
}

- (BOOL)isBeta;
{
    return releaseType == SKBetaVersionType;
}

- (BOOL)isAlpha;
{
    return releaseType == SKAlphaVersionType;
}

#pragma mark NSCopying

- (id)copyWithZone:(NSZone *)zone;
{
    return [self retain];
}

#pragma mark Comparison

- (unsigned)hash;
{
    return [cleanVersionString hash];
}

- (BOOL)isEqual:(id)otherObject;
{
    if ([otherObject isMemberOfClass:[self class]] == NO)
        return NO;
    return [self compareToVersionNumber:(SKVersionNumber *)otherObject] == NSOrderedSame;
}

- (NSComparisonResult)compareToVersionNumber:(SKVersionNumber *)otherVersion;
{
    if (otherVersion == nil)
        return NSOrderedAscending;

    unsigned int index, count = MAX(componentCount, [otherVersion componentCount]);
    for (index = 0; index < count; index++) {
        unsigned int component = [self componentAtIndex:index];
        unsigned int otherComponent = [otherVersion componentAtIndex:index];

        if (component < otherComponent)
            return NSOrderedAscending;
        else if (component > otherComponent)
            return NSOrderedDescending;
    }

    return NSOrderedSame;
}

@end
