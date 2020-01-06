//
//  SKAttachmentEmailer.m
//  Skim
//
//  Created by Christiaan Hofman on 11/4/12.
/*
 This software is Copyright (c) 2012-2020
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

#import "SKAttachmentEmailer.h"
#import "NSString_SKExtensions.h"
#import "NSFileManager_SKExtensions.h"

#if !SDK_BEFORE(10_14)
extern OSStatus AEDeterminePermissionToAutomateTarget( const AEAddressDesc* target, AEEventClass theAEEventClass, AEEventID theAEEventID, Boolean askUserIfNeeded ) WEAK_IMPORT_ATTRIBUTE;
#endif

@implementation SKAttachmentEmailer

@synthesize fileURL, subject, completionHandler;

+ (BOOL)permissionToComposeMessage {
#if !SDK_BEFORE(10_14)
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wpartial-availability"
    if (AEDeterminePermissionToAutomateTarget != NULL) {
        NSString *mailAppID = [(NSString *)LSCopyDefaultHandlerForURLScheme(CFSTR("mailto")) autorelease] ?: @"com.apple.mail";
        NSAppleEventDescriptor *targetDescriptor = [NSAppleEventDescriptor descriptorWithBundleIdentifier:mailAppID];
        return noErr == AEDeterminePermissionToAutomateTarget(targetDescriptor.aeDesc, typeWildCard, typeWildCard, true);
    }
#pragma clang diagnostic pop
#endif
    return YES;
}

+ (void)emailAttachmentWithURL:(NSURL *)aFileURL subject:(NSString *)aSubject preparedByTask:(NSTask *)task completionHandler:(void (^)(BOOL success))aCompletionHandler {
    SKAttachmentEmailer *emailer = [[[self alloc] init] autorelease];
    [emailer setFileURL:aFileURL];
    [emailer setSubject:aSubject];
    [emailer setCompletionHandler:aCompletionHandler];
    [emailer launchTask:task];
}

- (void)dealloc {
    SKDESTROY(fileURL);
    SKDESTROY(subject);
    SKDESTROY(completionHandler);
    [super dealloc];
}

- (void)emailAttachmentFile {
    NSString *scriptFormat = nil;
    NSString *mailAppID = [(NSString *)LSCopyDefaultHandlerForURLScheme(CFSTR("mailto")) autorelease];
    
    if ([@"com.microsoft.entourage" isCaseInsensitiveEqual:mailAppID]) {
        scriptFormat = @"tell application \"Microsoft Entourage\"\n"
                       @"activate\n"
                       @"set m to make new draft window with properties {subject:\"%@\", visible:true}\n"
                       @"tell m\n"
                       @"make new attachment with properties {file:POSIX file \"%@\"}\n"
                       @"end tell\n"
                       @"end tell\n";
    } else if ([@"com.microsoft.outlook" isCaseInsensitiveEqual:mailAppID]) {
        scriptFormat = @"tell application \"Microsoft Outlook\"\n"
                       @"activate\n"
                       @"set m to make new draft window with properties {subject:\"%@\", visible:true}\n"
                       @"tell m\n"
                       @"make new attachment with properties {file:POSIX file \"%@\"}\n"
                       @"end tell\n"
                       @"end tell\n";
    } else if ([@"com.barebones.mailsmith" isCaseInsensitiveEqual:mailAppID]) {
        scriptFormat = @"tell application \"Mailsmith\"\n"
                       @"activate\n"
                       @"set m to make new message window with properties {subject:\"%@\", visible:true}\n"
                       @"tell m\n"
                       @"make new enclosure with properties {file:POSIX file \"%@\"}\n"
                       @"end tell\n"
                       @"end tell\n";
    } else if ([@"com.mailplaneapp.Mailplane" isCaseInsensitiveEqual:mailAppID]) {
        scriptFormat = @"tell application \"Mailplane\"\n"
                       @"activate\n"
                       @"set m to make new outgoing message with properties {subject:\"%@\", visible:true}\n"
                       @"tell m\n"
                       @"make new mail attachment with properties {path:\"%@\"}\n"
                       @"end tell\n"
                       @"end tell\n";
    } else if ([@"com.postbox-inc.postboxexpress" isCaseInsensitiveEqual:mailAppID]) {
        scriptFormat = @"tell application \"PostboxExpress\"\n"
                       @"activate\n"
                       @"send message subject \"%@\" attachment \"%@\"\n"
                       @"end tell\n";
    } else if ([@"com.postbox-inc.postbox" isCaseInsensitiveEqual:mailAppID]) {
        scriptFormat = @"tell application \"Postbox\"\n"
                       @"activate\n"
                       @"send message subject \"%@\" attachment \"%@\"\n"
                       @"end tell\n";
    } else {
        scriptFormat = @"tell application \"Mail\"\n"
                       @"activate\n"
                       @"set m to make new outgoing message with properties {subject:\"%@\", visible:true}\n"
                       @"tell content of m\n"
                       @"make new attachment at after last character with properties {file name:\"%@\"}\n"
                       @"end tell\n"
                       @"end tell\n";
    }
    
    NSString *scriptString = [NSString stringWithFormat:scriptFormat, [self subject], [[self fileURL] path]];
    NSAppleScript *script = [[[NSAppleScript alloc] initWithSource:scriptString] autorelease];
    void (^handler)(BOOL) = [self completionHandler];
    static dispatch_queue_t queue = NULL;
    if (queue == NULL)
        queue = dispatch_queue_create("net.sourceforge.skim-app.queue.NSAppleScript", NULL);
    dispatch_async(queue, ^{
        NSDictionary *errorDict = nil;
        BOOL success = [script compileAndReturnError:&errorDict];
        if (success == NO) {
            NSLog(@"Error compiling mail to script: %@", errorDict);
        } else {
            success = [script executeAndReturnError:&errorDict];
            if (success == NO)
                NSLog(@"Error running mail to script: %@", errorDict);
        }
        if (handler)
            handler(success);
    });
}

- (void)taskFinished:(NSNotification *)notification {
    NSTask *task = [notification object];
    BOOL success = (task && [[self fileURL] checkResourceIsReachableAndReturnError:NULL] && [task terminationStatus] == 0);
    if (success) {
        [self emailAttachmentFile];
    } else {
        if ([self completionHandler])
            [self completionHandler](NO);
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self autorelease];
}

- (void)launchTask:(NSTask *)task {
    if (task) {
        [self retain];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(taskFinished:) name:NSTaskDidTerminateNotification object:task];
        @try {
            [task launch];
        }
        @catch (id exception) {
            [self taskFinished:nil];
        }
    } else if ([[self fileURL] checkResourceIsReachableAndReturnError:NULL]) {
        [self emailAttachmentFile];
    } else if ([self completionHandler]) {
        [self completionHandler](NO);
    }
}

@end
