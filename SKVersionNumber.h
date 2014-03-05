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

#import <Foundation/Foundation.h>

enum {
    SKReleaseVersionType = 0,
    SKReleaseCandidateVersionType = -1,
    SKBetaVersionType = -2,
    SKDevelopmentVersionType = -3,
    SKAlphaVersionType = -4
};

@interface SKVersionNumber : NSObject <NSCopying>
{
    NSString *originalVersionString;
    NSString *cleanVersionString;
    
    NSUInteger componentCount;
    NSInteger *components;
    NSInteger releaseType;
}

@property (nonatomic, readonly) NSString *originalVersionString, *cleanVersionString;
@property (nonatomic, readonly) NSUInteger componentCount;
@property (nonatomic, readonly) NSInteger releaseType;

+ (NSComparisonResult)compareVersionString:(NSString *)versionString toVersionString:(NSString *)otherVersionString;

- (id)initWithVersionString:(NSString *)versionString;

- (NSInteger)componentAtIndex:(NSUInteger)componentIndex;

- (NSComparisonResult)compare:(SKVersionNumber *)otherVersion;

@end
