//
//  BDSKShellCommandFormatter.m
//  Bibdesk
//
//  Created by Adam Maxwell on 09/23/06.
/*
 This software is Copyright (c) 2006,2007
 Adam Maxwell. All rights reserved.
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:
 
 - Redistributions of source code must retain the above copyright
 notice, this list of conditions and the following disclaimer.
 
 - Redistributions in binary form must reproduce the above copyright
 notice, this list of conditions and the following disclaimer in
 the documentation and/or other materials provided with the
 distribution.
 
 - Neither the name of Adam Maxwell nor the names of any
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

#import "BDSKShellCommandFormatter.h"
#import "NSString_BDSKExtensions.h"


@implementation BDSKShellCommandFormatter

+ (NSString *)pathByRemovingArgumentsFromCommand:(NSString *)command;
{
    // strip command arguments
    NSRange spaceRange = [command rangeOfString:@" "];
    if (spaceRange.length)
        command = [command substringToIndex:spaceRange.location];
    return command;
}

+ (NSArray *)argumentsFromCommand:(NSString *)command;
{
    NSRange spaceRange = [command rangeOfString:@" "];
    return (spaceRange.length) ? [[command substringFromIndex:spaceRange.location + 1] shellScriptArgumentsArray] : [NSArray array];
}    

+ (BOOL)isValidExecutableCommand:(NSString *)command;
{
    NSString  *path = [self pathByRemovingArgumentsFromCommand:command];
    BOOL isDir;
    BOOL isValidPath = NO;
    if ([[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDir] && NO == isDir)
        isValidPath = [[NSFileManager defaultManager] isExecutableFileAtPath:path];
    
    return isValidPath;
}

- (NSString *)stringForObjectValue:(id)obj { return obj; }

- (BOOL)getObjectValue:(id *)obj forString:(NSString *)string errorDescription:(NSString **)error;
{
    if ([[self class] isValidExecutableCommand:string]) {
        if (obj) *obj = string;
        return YES;
    } else {
        if (obj) *obj = nil;
        if (error) *error = [NSString stringWithFormat:NSLocalizedString(@"File \"%@\" does not exist or is not executable.", @"Error description"), [[self class] pathByRemovingArgumentsFromCommand:string]];
        return NO;
    }
}

@end
