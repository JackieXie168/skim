//
//  SKVersionNumber.h
//  Skim
//
//  Created by Christiaan Hofman on 2/15/07.
/*
 This software is Copyright (c) 2007-2014
 Christiaan Hofman. All rights reserved.
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:
 
 - Redistributions of source code must retain the above copyright
 notice, this list of conditions and the following disclaimer.
 
 - Redistributions in binary form must reproduce the above copyright
 notice, this list of conditions and the following disclaimer in
 the documentation and/or other materials provided with the
 distribution.
 
 - Neither the name of Christiaan Hofman nor the names of any
 contributors may be used to endorse or promote products derived
 from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "SKVersionNumber.h"

#define VERSION_LONG            @"version"
#define VERSION_SHORT           @"v"
#define ALPHA_LONG              @"alpha"
#define ALPHA_SHORT             @"a"
#define BETA_LONG               @"beta"
#define BETA_SHORT              @"b"
#define DEVELOPMENT_LONG        @"development"
#define DEVELOPMENT_SHORT       @"d"
#define FINAL_LONG              @"final"
#define FINAL_SHORT             @"f"
#define RELEASE_CANDIDATE_LONG  @"release candidate"
#define RELEASE_CANDIDATE_SHORT @"rc"
#define SEPARATOR               @"."
#define DASH                    @"-"
#define EMPTY                   @""

@implementation SKVersionNumber

@synthesize originalVersionString, cleanVersionString, componentCount, releaseType;

+ (NSComparisonResult)compareVersionString:(NSString *)versionString toVersionString:(NSString *)otherVersionString;
{   
    SKVersionNumber *versionNumber = [[self alloc] initWithVersionString:versionString];
    SKVersionNumber *otherVersionNumber = [[self alloc] initWithVersionString:otherVersionString];
    NSComparisonResult result = [versionNumber compare:otherVersionNumber];
    [versionNumber release];
    [otherVersionNumber release];
    return result;
}

// Initializes the receiver from a string representation of a version number.  The input string may have an optional leading 'v' or 'V' followed by a sequence of positive integers separated by '.'s.  Any trailing component of the input string that doesn't match this pattern is ignored.  If no portion of this string matches the pattern, nil is returned.
- (id)initWithVersionString:(NSString *)versionString;
{
    
    self = [super init];
    if (self) {
        // Input might be from a NSBundle info dictionary that could be misconfigured, so check at runtime too
        if (versionString == nil || [versionString isKindOfClass:[NSString class]] == NO) {
            [self release];
            return nil;
        }
        
        originalVersionString = [versionString copy];
        releaseType = SKReleaseVersionType;
        
        NSMutableString *mutableVersionString = [[NSMutableString alloc] init];
        NSScanner *scanner = [[NSScanner alloc] initWithString:versionString];
        NSString *sep = EMPTY;
        
        [scanner setCharactersToBeSkipped:[NSCharacterSet whitespaceCharacterSet]];
        
        // ignore a leading "version" or "v", possibly followed by "-"
        if ([scanner scanString:VERSION_LONG intoString:NULL] || [scanner scanString:VERSION_SHORT intoString:NULL])
            [scanner scanString:DASH intoString:NULL];
        
        while ([scanner isAtEnd] == NO && sep != nil) {
            NSInteger component;
            
            if ([scanner scanInteger:&component] && component >= 0) {
            
                [mutableVersionString appendFormat:@"%@%ld", sep, (long)component];
                
                componentCount++;
                components = (NSInteger *)NSZoneRealloc(NSDefaultMallocZone(), components, sizeof(NSInteger) * componentCount);
                components[componentCount - 1] = component;
            
                if ([scanner isAtEnd] == NO) {
                    sep = nil;
                    if ([scanner scanString:SEPARATOR intoString:NULL] || [scanner scanString:DASH intoString:NULL] || [scanner scanString:VERSION_LONG intoString:NULL] || [scanner scanString:VERSION_SHORT intoString:NULL]) {
                        sep = SEPARATOR;
                    }
                    if (releaseType == SKReleaseVersionType) {
                        if ([scanner scanString:ALPHA_LONG intoString:NULL] || [scanner scanString:ALPHA_SHORT intoString:NULL]) {
                            releaseType = SKAlphaVersionType;
                            [mutableVersionString appendString:ALPHA_SHORT];
                        } else if ([scanner scanString:BETA_LONG intoString:NULL] || [scanner scanString:BETA_SHORT intoString:NULL]) {
                            releaseType = SKBetaVersionType;
                            [mutableVersionString appendString:BETA_SHORT];
                        } else if ([scanner scanString:DEVELOPMENT_LONG intoString:NULL] || [scanner scanString:DEVELOPMENT_SHORT intoString:NULL]) {
                            releaseType = SKDevelopmentVersionType;
                            [mutableVersionString appendString:DEVELOPMENT_SHORT];
                        } else if ([scanner scanString:FINAL_LONG intoString:NULL] || [scanner scanString:FINAL_SHORT intoString:NULL]) {
                            releaseType = SKReleaseCandidateVersionType;
                            [mutableVersionString appendString:FINAL_SHORT];
                        } else if ([scanner scanString:RELEASE_CANDIDATE_LONG intoString:NULL] || [scanner scanString:RELEASE_CANDIDATE_SHORT intoString:NULL]) {
                            releaseType = SKReleaseCandidateVersionType;
                            [mutableVersionString appendString:RELEASE_CANDIDATE_SHORT];
                        }
                        
                        if (releaseType != SKReleaseVersionType) {
                            // we scanned an "a", "b", "d", "f", or "rc"
                            componentCount++;
                            components = (NSInteger *)NSZoneRealloc(NSDefaultMallocZone(), components, sizeof(NSInteger) * componentCount);
                            components[componentCount - 1] = releaseType;
                            
                            sep = EMPTY;
                            
                            // ignore a "." or "-"
                            if ([scanner scanString:SEPARATOR intoString:NULL] == NO)
                                [scanner scanString:DASH intoString:NULL];
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
    SKDESTROY(originalVersionString);
    SKDESTROY(cleanVersionString);
    SKZONEDESTROY(components);
    [super dealloc];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: %@>", [self class], [self originalVersionString]];
}

#pragma mark API

- (NSInteger)componentAtIndex:(NSUInteger)componentIndex;
{
    // This treats the version as a infinite sequence ending in "...0.0.0.0", making comparison easier
    if (componentIndex < componentCount)
        return components[componentIndex];
    return 0;
}

#pragma mark NSCopying

- (id)copyWithZone:(NSZone *)zone;
{
    if (NSShouldRetainWithZone(self, zone))
        return [self retain];
    else
        return [[[self class] allocWithZone:zone] initWithVersionString:originalVersionString];
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
    return [self compare:(SKVersionNumber *)otherObject] == NSOrderedSame;
}

- (NSComparisonResult)compare:(SKVersionNumber *)otherVersion;
{
    if (otherVersion == nil)
        return NSOrderedAscending;
    
    NSUInteger idx = 0, otherIdx = 0, otherCount = [otherVersion componentCount];
    while (idx < componentCount || otherIdx < otherCount) {
        NSInteger component = [self componentAtIndex:idx];
        NSInteger otherComponent = [otherVersion componentAtIndex:otherIdx];
        
        // insert zeros before matching possible a/d/b/rc components, e.g. to get 1b1 > 1.0a1
        if (component < 0 && otherComponent >= 0 && otherIdx < otherCount) {
            component = 0;
            otherIdx++;
        } else if (component >= 0 && otherComponent < 0 && idx < componentCount) {
            otherComponent = 0;
            idx++;
        } else {
            idx++;
            otherIdx++;
        }
        
        if (component < otherComponent)
            return NSOrderedAscending;
        else if (component > otherComponent)
            return NSOrderedDescending;
    }
    
    return NSOrderedSame;
}

@end
