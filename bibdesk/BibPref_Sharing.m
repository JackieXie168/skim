//
//  BibPref_Sharing.m
//  BibDesk
//
//  Created by Adam Maxwell on Fri Mar 31 2006.
//  Copyright (c) 2006 Adam R. Maxwell. All rights reserved.
/*
 This software is Copyright (c) 2006
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

#import "BibPref_Sharing.h"
#import "BibPrefController.h"
#import "BDSKSharingBrowser.h"
#import <Security/Security.h>
#import "BDSKSharingServer.h"
#import "BDSKPasswordController.h"

@implementation BibPref_Sharing

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleSharingNameChanged:) name:BDSKSharingNameChangedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleClientConnectionsChanged:) name:BDSKClientConnectionsChangedNotification object:nil];
    
    NSData *pwData = [BDSKPasswordController sharingPasswordForCurrentUserUnhashed];
    if(pwData != nil){
        NSString *pwString = [[NSString alloc] initWithData:pwData encoding:NSUTF8StringEncoding];
        [passwordField setStringValue:pwString];
        [pwString release];
    }    
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}

- (void)handleSharingNameChanged:(NSNotification *)aNotification;
{
    if([aNotification object] != self)
        [self updateUI];
}

- (void)handleClientConnectionsChanged:(NSNotification *)aNotification;
{
    [self updateUI];
}

- (void)updateUI
{
    [enableSharingButton setState:[defaults boolForKey:BDSKShouldShareFilesKey] ? NSOnState : NSOffState];
    [enableBrowsingButton setState:[defaults boolForKey:BDSKShouldLookForSharedFilesKey] ? NSOnState : NSOffState];
    [usePasswordButton setState:[defaults boolForKey:BDSKSharingRequiresPasswordKey] ? NSOnState : NSOffState];
    [passwordField setEnabled:[defaults boolForKey:BDSKSharingRequiresPasswordKey]];
    
    [sharedNameField setStringValue:[BDSKSharingServer sharingName]];
    NSString *statusMessage = nil;
    if([defaults boolForKey:BDSKShouldShareFilesKey]){
        unsigned int number = [[BDSKSharingServer defaultServer] numberOfConnections];
        if(number == 1)
            statusMessage = NSLocalizedString(@"On, 1 user connected", @"Bonjour sharing is on status message, single connection");
        else
            statusMessage = [NSString stringWithFormat:NSLocalizedString(@"On, %i users connected", @"Bonjour sharing is on status message, multiple connections"), number];
    }else{
        statusMessage = NSLocalizedString(@"Off", @"Bonjour sharing is off status message");
    }
    [statusField setStringValue:statusMessage];
}

- (IBAction)togglePassword:(id)sender
{
    [defaults setBool:([sender state] == NSOnState) forKey:BDSKSharingRequiresPasswordKey];
    [self valuesHaveChanged];
    [[NSNotificationCenter defaultCenter] postNotificationName:BDSKSharingPasswordChangedNotification object:nil];
}

- (IBAction)changePassword:(id)sender
{
    [BDSKPasswordController addOrModifyPassword:[sender stringValue] name:BDSKServiceNameForKeychain userName:nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:BDSKSharingPasswordChangedNotification object:nil];
}

// setting to the empty string will restore the default
- (IBAction)changeSharedName:(id)sender
{
    [defaults setObject:[sender stringValue] forKey:BDSKSharingNameKey];
    [[NSNotificationCenter defaultCenter] postNotificationName:BDSKSharingNameChangedNotification object:self];
    [self valuesHaveChanged];
}

- (IBAction)toggleBrowsing:(id)sender
{
    BOOL flag = ([sender state] == NSOnState);
    [defaults setBool:flag forKey:BDSKShouldLookForSharedFilesKey];
    [defaults autoSynchronize];
    if(flag == YES)
        [[BDSKSharingBrowser sharedBrowser] enableSharedBrowsing];
    else
        [[BDSKSharingBrowser sharedBrowser] disableSharedBrowsing];
}

- (IBAction)toggleSharing:(id)sender
{
    if([sender state] == NSOnState)
        [[BDSKSharingServer defaultServer] enableSharing];
    else
        [[BDSKSharingServer defaultServer] disableSharing];

    [defaults setBool:([sender state] == NSOnState) forKey:BDSKShouldShareFilesKey];
    
    [self valuesHaveChanged];
}

@end
