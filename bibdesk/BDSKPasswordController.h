//
//  BDSKPasswordController.m
//  BibDesk
//
//  Created by Adam Maxwell on Sat Apr 1 2006.
//  Copyright (c) 2006 Adam R. Maxwell. All rights reserved.
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

#import <Cocoa/Cocoa.h>

extern NSString *BDSKServiceNameForKeychain;

typedef enum {
    BDSKPasswordCancel = 0,
    BDSKPasswordReturn = 1
} BDSKPasswordControllerStatus;


@interface BDSKPasswordController : NSWindowController
{
    NSString *name;
    IBOutlet NSSecureTextField *passwordField;
    IBOutlet NSTextField *statusField;
}
- (void)setName:(NSString *)aName;
- (void)setStatus:(NSString *)status;
- (BDSKPasswordControllerStatus)runModalForKeychainServiceName:(NSString *)aName message:(NSString *)status;
- (IBAction)buttonAction:(id)sender;

+ (NSData *)sharingPasswordForCurrentUserUnhashed;
+ (void)addOrModifyPassword:(NSString *)password name:(NSString *)name userName:(NSString *)userName;
+ (NSData *)passwordHashedForKeychainServiceName:(NSString *)name;
+ (NSString *)keychainServiceNameWithComputerName:(NSString *)computerName;

@end
