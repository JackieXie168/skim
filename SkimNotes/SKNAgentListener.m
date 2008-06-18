/*
 *  SKNAgentListener.m
 *
 *  Created by Adam Maxwell on 04/10/07.
 *
 This software is Copyright (c) 2007-2008
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

#import "SKNAgentListener.h"
#import "SKNAgentListenerProtocol.h"
#import <AppKit/AppKit.h>
#import "SKNExtendedAttributeManager.h"

#define SKIM_NOTES_KEY @"net_sourceforge_skim-app_notes"
#define SKIM_RTF_NOTES_KEY @"net_sourceforge_skim-app_rtf_notes"
#define SKIM_TEXT_NOTES_KEY @"net_sourceforge_skim-app_text_notes"


@implementation SKNAgentListener

- (id)initWithServerName:(NSString *)serverName;
{
    self = [super init];
    if (self) {
        connection = [[NSConnection alloc] initWithReceivePort:[NSPort port] sendPort:nil];
        NSProtocolChecker *checker = [NSProtocolChecker protocolCheckerWithTarget:self protocol:@protocol(SKNAgentListenerProtocol)];
        [connection setRootObject:checker];
        [connection setDelegate:self];
        
        // user can pass nil, in which case we generate a server name to be read from standard output
        if (nil == serverName)
            serverName = [[NSProcessInfo processInfo] globallyUniqueString];

        if ([connection registerName:serverName] == NO) {
            fprintf(stderr, "SkimNotesAgent pid %d: unable to register connection name %s; another process must be running\n", getpid(), [serverName UTF8String]);
            [self destroyConnection];
            [self release];
            self = nil;
        }
        NSFileHandle *fh = [NSFileHandle fileHandleWithStandardOutput];
        [fh writeData:[serverName dataUsingEncoding:NSUTF8StringEncoding]];
        [fh closeFile];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self destroyConnection];
    [super dealloc];
}

- (NSString *)notesFileWithExtension:(NSString *)extension atPath:(NSString *)path error:(NSError **)error {
    NSString *filePath = nil;
    
    if ([extension caseInsensitiveCompare:@"skim"] == NSOrderedSame) {
        NSArray *files = [[NSFileManager defaultManager] subpathsAtPath:path];
        NSString *filename = @"notes.skim";
        if ([files containsObject:filename] == NO) {
            filename = [[[path lastPathComponent] stringByDeletingPathExtension] stringByAppendingPathExtension:extension];
            if ([files containsObject:filename] == NO) {
                unsigned idx = [[files valueForKeyPath:@"pathExtension.lowercaseString"] indexOfObject:@"skim"];
                filename = idx == NSNotFound ? nil : [files objectAtIndex:idx];
            }
        }
        if (filename)
            filePath = [path stringByAppendingPathComponent:filename];
    } else {
        NSString *skimFile = [self notesFileWithExtension:@"skim" atPath:path error:error];
        if (skimFile) {
            filePath = [[skimFile stringByDeletingPathExtension] stringByAppendingPathExtension:extension];
            if ([[NSFileManager defaultManager] fileExistsAtPath:filePath] == NO)
                filePath = nil;
        }
    }
    if (filePath == nil && error) 
        *error = [NSError errorWithDomain:NSPOSIXErrorDomain code:ENOENT userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"Notes file note found", NSLocalizedDescriptionKey, nil]];
    return filePath;
}

- (bycopy NSData *)SkimNotesAtPath:(in bycopy NSString *)aFile;
{
    NSError *error;
    NSData *data = nil;
    NSString *extension = [[aFile pathExtension] lastPathComponent];
    
    if ([extension caseInsensitiveCompare:@"pdfd"] == NSOrderedSame) {
        NSString *notePath = [self notesFileWithExtension:@"skim" atPath:aFile error:&error];
        if (notePath)
            data = [NSData dataWithContentsOfFile:notePath options:0 error:&error];
        if (nil == data)
            fprintf(stderr, "SkimNotesAgent pid %d: error getting Skim notes (%s)\n", getpid(), [[error description] UTF8String]);
    } else if ([extension caseInsensitiveCompare:@"skim"] == NSOrderedSame) {
        data = [NSData dataWithContentsOfFile:aFile options:0 error:&error];
        if (nil == data)
            fprintf(stderr, "SkimNotesAgent pid %d: error getting Skim notes (%s)\n", getpid(), [[error description] UTF8String]);
    } else {
        data = [[SKNExtendedAttributeManager sharedManager] extendedAttributeNamed:SKIM_NOTES_KEY atPath:[aFile stringByStandardizingPath] traverseLink:YES error:&error];
        if (nil == data && [error code] != ENOATTR)
            fprintf(stderr, "SkimNotesAgent pid %d: error getting Skim notes (%s)\n", getpid(), [[error description] UTF8String]);
    }
    return data;
}

- (bycopy NSData *)RTFNotesAtPath:(in bycopy NSString *)aFile;
{
    NSError *error;
    NSData *data = nil;
    NSString *extension = [[aFile pathExtension] lastPathComponent];
    
    if ([extension caseInsensitiveCompare:@"pdfd"] == NSOrderedSame) {
        NSString *notePath = [self notesFileWithExtension:@"rtf" atPath:aFile error:&error];
        if (notePath)
            data = [NSData dataWithContentsOfFile:notePath options:0 error:&error];
        if (nil == data)
            fprintf(stderr, "SkimNotesAgent pid %d: error getting RTF notes (%s)\n", getpid(), [[error description] UTF8String]);
    } else {
        data = [[SKNExtendedAttributeManager sharedManager] extendedAttributeNamed:SKIM_RTF_NOTES_KEY atPath:[aFile stringByStandardizingPath] traverseLink:YES error:&error];
        if (nil == data && [error code] != ENOATTR)
            fprintf(stderr, "SkimNotesAgent pid %d: error getting RTF notes (%s)\n", getpid(), [[error description] UTF8String]);
    }
    return data;
}

- (bycopy NSData *)textNotesAtPath:(in bycopy NSString *)aFile encoding:(NSStringEncoding)encoding;
{
    NSError *error;
    NSString *string = nil;
    NSString *extension = [[aFile pathExtension] lastPathComponent];
    
    if ([extension caseInsensitiveCompare:@"pdfd"] == NSOrderedSame) {
        NSString *notePath = [self notesFileWithExtension:@"txt" atPath:aFile error:&error];
        if (notePath)
            string = [NSString stringWithContentsOfFile:notePath encoding:NSUTF8StringEncoding error:&error];
        if (nil == string)
            fprintf(stderr, "SkimNotesAgent pid %d: error getting text notes (%s)\n", getpid(), [[error description] UTF8String]);
    } else {
        string = [[SKNExtendedAttributeManager sharedManager] propertyListFromExtendedAttributeNamed:SKIM_TEXT_NOTES_KEY atPath:[aFile stringByStandardizingPath] traverseLink:YES error:&error];
        if (nil == string && [[[error userInfo] objectForKey:NSUnderlyingErrorKey] code] != ENOATTR)
            fprintf(stderr, "SkimNotesAgent pid %d: error getting text notes (%s)\n", getpid(), [[error description] UTF8String]);
    }
    // Returning the string directly can fail under some conditions.  For some strings with corrupt copy-paste characters (typical for notes), -[NSString canBeConvertedToEncoding:NSUTF8StringEncoding] returns YES but the actual conversion fails.  A result seems to be that encoding the string also fails, which causes the DO client to get a timeout.  Returning NSUnicodeStringEncoding data seems to work in those cases (and is safe since we're not going over the wire between big/little-endian systems).
    return [string dataUsingEncoding:encoding];
}

- (void)destroyConnection;
{
    [connection registerName:nil];
    [[connection receivePort] invalidate];
    [[connection sendPort] invalidate];
    [connection invalidate];
    [connection release];
    connection = nil;
}

- (void)portDied:(NSNotification *)notification
{
    [self destroyConnection];
    fprintf(stderr, "SkimNotesAgent pid %d dying because port %s is invalid\n", getpid(), [[[notification object] description] UTF8String]);
    exit(0);
}

// first app to connect will be the owner of this instance of the program; when the connection dies, so do we
- (BOOL)makeNewConnection:(NSConnection *)newConnection sender:(NSConnection *)parentConnection
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(portDied:) name:NSPortDidBecomeInvalidNotification object:[newConnection sendPort]];
    fprintf(stderr, "SkimNotesAgent pid %d connection registered\n", getpid());
    return YES;
}

@end
