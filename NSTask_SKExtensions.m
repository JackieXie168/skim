//
//  NSTask_SKExtensions.m
//  Skim
//
//  Created by Christiaan Hofman on 9/1/07.
/*
 This software is Copyright (c) 2007-2008
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

#import "NSTask_SKExtensions.h"


@implementation NSTask (SKExtensions) 

+ (NSTask *)launchedTaskWithLaunchPath:(NSString *)launchPath arguments:(NSArray *)arguments currentDirectoryPath:(NSString *)directoryPath {
    NSTask *task = [[[NSTask alloc] init] autorelease];
    
    [task setLaunchPath:launchPath];
    if (directoryPath)
        [task setCurrentDirectoryPath:directoryPath];
    [task setArguments:arguments];
    [task setStandardOutput:[NSFileHandle fileHandleWithNullDevice]];
    [task setStandardError:[NSFileHandle fileHandleWithNullDevice]];
    @try {
        [task launch];
    }
    @catch(id exception) {
        if ([task isRunning])
            [task terminate];
        NSLog(@"%@ %@ failed", [task description], [task launchPath]);
        task = nil;
    }
    return task;
}

+ (BOOL)runTaskWithLaunchPath:(NSString *)launchPath arguments:(NSArray *)arguments currentDirectoryPath:(NSString *)directoryPath {
    NSTask *task = [[self class] launchedTaskWithLaunchPath:launchPath arguments:arguments currentDirectoryPath:directoryPath];
    BOOL success = task != nil;
    
    if (success) {
        if ([task isRunning])
            [task waitUntilExit];
        if ([task isRunning]) {
            [task terminate];
            success = NO;
        } else {
            success = 0 == [task terminationStatus];
        }
    }
    return success;
}

@end
