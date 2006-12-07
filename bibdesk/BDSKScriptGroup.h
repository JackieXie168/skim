//
//  BDSKScriptGroup.h
//  Bibdesk
//
//  Created by Christiaan Hofman on 10/19/06.
/*
 This software is Copyright (c) 2006
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

#import <Cocoa/Cocoa.h>
#import "BDSKGroup.h"
#import <OmniFoundation/OFWeakRetainConcreteImplementation.h>
#import "BDSKOwnerProtocol.h"

@class OFMessageQueue, BDSKPublicationsArray, BDSKMacroResolver;

enum {
    BDSKShellScriptType,
    BDSKAppleScriptType
};

@interface BDSKScriptGroup : BDSKMutableGroup <BDSKOwner> {
    BDSKPublicationsArray *publications;
    BDSKMacroResolver *macroResolver;
    NSString *scriptPath;
    NSString *scriptArguments;
    NSArray *argsArray;
    int scriptType;
    BOOL isRetrieving;
    BOOL failedDownload;
    OFMessageQueue *messageQueue;
    NSTask *currentTask;
    NSString *workingDirPath;
    NSData *stdoutData;
    OFSimpleLockType processingLock;    
    OFSimpleLockType currentTaskLock;
}

- (id)initWithScriptPath:(NSString *)path scriptArguments:(NSString *)arguments scriptType:(int)type;
- (id)initWithName:(NSString *)aName scriptPath:(NSString *)path scriptArguments:(NSString *)arguments scriptType:(int)type;

- (BDSKPublicationsArray *)publications;
- (void)setPublications:(NSArray *)newPubs;

- (NSString *)scriptPath;
- (void)setScriptPath:(NSString *)newPath;

- (NSString *)scriptArguments;
- (void)setScriptArguments:(NSString *)newArguments;

- (int)scriptType;
- (void)setScriptType:(int)newType;

- (void)startRunningScript;
- (void)scriptDidFinishWithResult:(NSString *)outputString;
- (void)scriptDidFailWithError:(NSError *)error;
- (void)runShellScriptAtPath:(NSString *)path withArguments:(NSArray *)args;
- (void)terminate;
- (BOOL)isProcessing;
- (void)stdoutNowAvailable:(NSNotification *)notification;

@end
