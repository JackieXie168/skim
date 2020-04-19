//
//  SKFileShare.m
//  Skim
//
//  Created by Christiaan Hofman on 17/04/2020.
/*
This software is Copyright (c) 2020
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

#import "SKFileShare.h"

@implementation SKFileShare

@synthesize fileURL, sharingService, completionHandler;

- (void)dealloc {
    SKDESTROY(fileURL);
    SKDESTROY(sharingService);
    SKDESTROY(completionHandler);
    [super dealloc];
}

- (void)finishWithSuccess:(BOOL)success {
    if ([self completionHandler])
        [self completionHandler](success);
    [self autorelease];
}

- (void)shareFileURL {
    NSArray *items = [NSArray arrayWithObjects:[self fileURL], nil];
    if ([[self sharingService] canPerformWithItems:items])
        [[self sharingService] performWithItems:items];
    else
        [self finishWithSuccess:NO];
}

- (void)taskFinished:(NSNotification *)notification {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSTaskDidTerminateNotification object:nil];
    NSTask *task = [notification object];
    BOOL success = (task && [[self fileURL] checkResourceIsReachableAndReturnError:NULL] && [task terminationStatus] == 0);
    if (success)
        [self shareFileURL];
    else
        [self finishWithSuccess:NO];
}

- (void)launchTask:(NSTask *)task {
    [self retain];
    if (task) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(taskFinished:) name:NSTaskDidTerminateNotification object:task];
        @try {
            [task launch];
        }
        @catch (id exception) {
            [self taskFinished:nil];
        }
    } else if ([[self fileURL] checkResourceIsReachableAndReturnError:NULL]) {
        [self shareFileURL];
    } else {
        [self finishWithSuccess:NO];
    }
}


- (void)sharingService:(NSSharingService *)sharingService didShareItems:(NSArray *)items {
    [self finishWithSuccess:YES];
}

- (void)sharingService:(NSSharingService *)sharingService didFailToShareItems:(NSArray *)items error:(NSError *)error {
    [self finishWithSuccess:NO];
}

+ (void)shareURL:(NSURL *)aFileURL preparedByTask:(NSTask *)task usingService:(NSSharingService *)aSharingService completionHandler:(void (^)(BOOL success))aCompletionHandler {
    SKFileShare *sharer = [[[self alloc] init] autorelease];
    [sharer setFileURL:aFileURL];
    [sharer setSharingService:aSharingService];
    [sharer setCompletionHandler:aCompletionHandler];
    [aSharingService setDelegate:sharer];
    [sharer launchTask:task];
}

@end
