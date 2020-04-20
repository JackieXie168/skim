//
//  SKShareMenuController.m
//  Skim
//
//  Created by Christiaan Hofman on 19/04/2020.
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

#import "SKShareMenuController.h"
#import "SKAttachmentEmailer.h"
#import "NSMenu_SKExtensions.h"
#import "NSDocument_SKExtensions.h"


@implementation SKShareMenuController

@synthesize document;

- (id)initForDocument:(NSDocument *)aDocument {
    self = [super init];
    if (self) {
        document = aDocument;
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)coder {
    [self release];
    return nil;
}

- (void)encodeWithCoder:(NSCoder *)coder {}

- (void)menuNeedsUpdate:(NSMenu *)menu {
    [menu removeAllItems];
    NSDocument *doc = [self document] ?: [[NSDocumentController sharedDocumentController] currentDocument];
    NSURL *fileURL = [doc fileURL];
    NSArray *services = nil;
    if (fileURL) {
        services = [NSClassFromString(@"NSSharingService") sharingServicesForItems:[NSArray arrayWithObjects:fileURL, nil]];
        SKAttachmentEmailer *emailer = [[[SKAttachmentEmailer alloc] init] autorelease];
        if (emailer && [[services valueForKey:@"title"] containsObject:[emailer title]] == NO && [emailer permissionToComposeMessage])
            services = services ? [services arrayByAddingObject:emailer] : [NSArray arrayWithObjects:emailer, nil];
    }
    if ([services count] == 0) {
        [menu addItemWithTitle:NSLocalizedString(@"No Document", @"Menu item title") action:NULL keyEquivalent:@""];
    } else {
        for (NSSharingService *service in services) {
            NSMenuItem *item = [menu addItemWithTitle:[service title] action:@selector(share:) target:doc];
            [item setRepresentedObject:service];
            [item setImage:[service image]];
        }
    }
}

- (BOOL)menuHasKeyEquivalent:(NSMenu *)menu forEvent:(NSEvent *)event target:(id *)target action:(SEL *)action { return NO; }

@end
