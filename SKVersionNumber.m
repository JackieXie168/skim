//
//  SKVersionNumber.h
//  Skim
//
//  Created by Christiaan Hofman on 2/15/07.

// Much of this code is copied and modified from OmniFoundation/OFVersionNumber and subject to the following copyright.

// Copyright 2004-2008 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import "SKVersionNumber.h"


@implementation SKVersionNumber

+ (id)versionNumberWithVersionString:(NSString *)versionString;
{
    return [[[[self class] alloc] initWithVersionString:versionString] autorelease];
}

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
        NSScanner *scanner = [[NSScanner alloc] initWithString:versionString];
        NSString *sep = @"";
        
        [scanner setCharactersToBeSkipped:[NSCharacterSet whitespaceCharacterSet]];
        
        // ignore a leading "version" or "v", possibly followed by "-"
        if ([scanner scanString:@"version" intoString:NULL] || [scanner scanString:@"v" intoString:NULL])
            [scanner scanString:@"-" intoString:NULL];
        
        while ([scanner isAtEnd] == NO && sep != nil) {
            NSInteger component;
            
            if ([scanner scanInt:&component] && component >= 0) {
            
                [mutableVersionString appendFormat:@"%@%i", sep, component];
                
                componentCount++;
                components = realloc(components, sizeof(*components) * componentCount);
                components[componentCount - 1] = component;
            
                if ([scanner isAtEnd] == NO) {
                    sep = nil;
                    if ([scanner scanString:@"." intoString:NULL] || [scanner scanString:@"-" intoString:NULL] || [scanner scanString:@"version" intoString:NULL] || [scanner scanString:@"v" intoString:NULL]) {
                        sep = @".";
                    }
                    if (releaseType == SKReleaseVersionType) {
                        if ([scanner scanString:@"alpha" intoString:NULL] || [scanner scanString:@"a" intoString:NULL]) {
                            releaseType = SKAlphaVersionType;
                            [mutableVersionString appendString:@"a"];
                        } else if ([scanner scanString:@"beta" intoString:NULL] || [scanner scanString:@"b" intoString:NULL]) {
                            releaseType = SKBetaVersionType;
                            [mutableVersionString appendString:@"b"];
                        } else if ([scanner scanString:@"development" intoString:NULL] || [scanner scanString:@"d" intoString:NULL]) {
                            releaseType = SKDevelopmentVersionType;
                            [mutableVersionString appendString:@"d"];
                        } else if ([scanner scanString:@"final" intoString:NULL] || [scanner scanString:@"f" intoString:NULL]) {
                            releaseType = SKReleaseCandidateVersionType;
                            [mutableVersionString appendString:@"f"];
                        } else if ([scanner scanString:@"release candidate" intoString:NULL] || [scanner scanString:@"rc" intoString:NULL] || [scanner scanString:@"f" intoString:NULL]) {
                            releaseType = SKReleaseCandidateVersionType;
                            [mutableVersionString appendString:@"rc"];
                        }
                        
                        if (releaseType != SKReleaseVersionType) {
                            // we scanned an "a", "b", "d", "f", or "rc"
                            componentCount++;
                            components = realloc(components, sizeof(*components) * componentCount);
                            components[componentCount - 1] = -releaseType;
                            
                            sep = @"";
                            
                            // ignore a "." or "-"
                            [scanner scanString:@"." intoString:NULL] || [scanner scanString:@"-" intoString:NULL];
                        }
                    }
                }
            } else
                sep = nil;
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

- (NSUInteger)componentCount;
{
    return componentCount;
}

- (NSInteger)componentAtIndex:(NSUInteger)componentIndex;
{
    // This treats the version as a infinite sequence ending in "...0.0.0.0", making comparison easier
    if (componentIndex < componentCount)
        return components[componentIndex];
    return 0;
}

- (NSInteger)releaseType;
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

- (BOOL)isDevelopment;
{
    return releaseType == SKDevelopmentVersionType;
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

- (NSUInteger)hash;
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

    NSUInteger idx, count = MAX(componentCount, [otherVersion componentCount]);
    for (idx = 0; idx < count; idx++) {
        NSInteger component = [self componentAtIndex:idx];
        NSInteger otherComponent = [otherVersion componentAtIndex:idx];

        if (component < otherComponent)
            return NSOrderedAscending;
        else if (component > otherComponent)
            return NSOrderedDescending;
    }

    return NSOrderedSame;
}

@end
