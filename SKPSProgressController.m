//
//  SKPSProgressController.m
//  Skim
//
//  Created by Adam Maxwell on 12/6/06.
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

#import "SKPSProgressController.h"
#import "NSString_SKExtensions.h"

typedef enum {
    SKPSConversionCanceled = -1,
    SKPSConversionSucceeded = 0,
    SKPSConversionFailed = 1
} SKPSConversionStatus;

@interface SKPSProgressController (Private)
- (void)doConversionWithInfo:(NSDictionary *)info;
- (void)processingPostScriptPage:(NSNumber *)page;
- (void)postscriptConversionCompleted:(BOOL)didComplete;
- (void)postscriptConversionStarted;
- (void)showPostScriptConversionMessage:(NSString *)message;
@end

static void PSConverterBeginDocumentCallback(void *info)
{
    id delegate = (id)info;
    if (delegate && [delegate respondsToSelector:@selector(postscriptConversionStarted)])
        [delegate performSelectorOnMainThread:@selector(postscriptConversionStarted) withObject:nil waitUntilDone:NO];
}

static void PSConverterBeginPageCallback(void *info, size_t pageNumber, CFDictionaryRef pageInfo)
{
    id delegate = (id)info;
    if (delegate && [delegate respondsToSelector:@selector(processingPostScriptPage:)])
        [delegate performSelectorOnMainThread:@selector(processingPostScriptPage:) withObject:[NSNumber numberWithInt:pageNumber] waitUntilDone:NO];
}

static void PSConverterEndDocumentCallback(void *info, bool success)
{
    id delegate = (id)info;
    if (delegate && [delegate respondsToSelector:@selector(postscriptConversionCompleted:)]) {
        NSMethodSignature *ms = [delegate methodSignatureForSelector:@selector(postscriptConversionCompleted:)];
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:ms];
        [invocation setTarget:delegate];
        [invocation setSelector:@selector(postscriptConversionCompleted:)];
        
        BOOL val = (success == true);
        [invocation setArgument:&val atIndex:2];
        [invocation performSelectorOnMainThread:@selector(invoke) withObject:nil waitUntilDone:NO];
    }
}

static void PSConverterMessageCallback(void *info, CFStringRef message)
{
    id delegate = (id)info;
    if (delegate && [delegate respondsToSelector:@selector(showPostScriptConversionMessage:)])
        [delegate performSelectorOnMainThread:@selector(showPostScriptConversionMessage:) withObject:(id)message waitUntilDone:NO];
}

@implementation SKPSProgressController

- (id)init
{
    return [super initWithWindowNibName:[self windowNibName] owner:self];
}

- (void)awakeFromNib
{
    [progressBar setUsesThreadedAnimation:YES];
    [[self window] setTitle:@""];
}

- (void)dealloc
{
    if (converter) CFRelease(converter);
    [super dealloc];
}

- (NSString *)windowNibName { return @"ConversionProgressWindow"; }

- (IBAction)close:(id)sender { [self close]; }

- (IBAction)cancel:(id)sender
{
    [NSApp stopModalWithCode:SKPSConversionCanceled];

    if (CGPSConverterAbort(converter) == false) {
        NSBeep();
        [textField setStringValue:NSLocalizedString(@"Converter already stopped.", @"PS conversion progress message")];
        [cancelButton setTitle:NSLocalizedString(@"Close", @"Button title")];
        [cancelButton setAction:@selector(close:)];
    }
}

- (NSData *)PDFDataWithPostScriptData:(NSData *)psData
{
    NSAssert(NULL == converter, @"attempted to reenter SKPSProgressController, but this is not supported");
    
    CGPSConverterCallbacks converterCallbacks = { 
        0, 
        PSConverterBeginDocumentCallback, 
        PSConverterEndDocumentCallback, 
        PSConverterBeginPageCallback,   /* haven't seen this called in my testing */
        NULL, 
        NULL, 
        PSConverterMessageCallback,     /* haven't seen this called in my testing */
        NULL 
    };
    
    // pass self as info
    converter = CGPSConverterCreate((void *)self, &converterCallbacks, NULL);
    NSAssert(converter != NULL, @"unable to create PS converter");
    
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((CFDataRef)psData);
    
    CFMutableDataRef pdfData = CFDataCreateMutable(CFGetAllocator((CFDataRef)psData), 0);
    CGDataConsumerRef consumer = CGDataConsumerCreateWithCFData(pdfData);
    
    NSDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys:(id)provider, @"provider", (id)consumer, @"consumer", nil];
    
    NSModalSession session = [NSApp beginModalSessionForWindow:[self window]];
    BOOL didDetach = NO;
    int rv;
    
    while (1) {
        
        // we run this inside the modal session since the thread could end before runModalForWindow starts
        if (NO == didDetach) {
            [NSThread detachNewThreadSelector:@selector(doConversionWithInfo:) toTarget:self withObject:dictionary];
            didDetach = YES;
        }
        
        rv = [NSApp runModalSession:session];
        if (rv != NSRunContinuesResponse)
            break;
    }
    
    [NSApp endModalSession:session];
    
    CGDataProviderRelease(provider);
    CGDataConsumerRelease(consumer);
    
    if (rv != SKPSConversionSucceeded) {
        CFRelease(pdfData);
        pdfData = nil;
    }
    
    // close the window when finished
    [self close];
    
    return [(id)pdfData autorelease];
}

@end

@implementation SKPSProgressController (Private)

- (void)doConversionWithInfo:(NSDictionary *)info;
{
    NSAutoreleasePool *pool = [NSAutoreleasePool new];
    
    CGDataProviderRef provider = (void *)[info objectForKey:@"provider"];
    CGDataConsumerRef consumer = (void *)[info objectForKey:@"consumer"];
    Boolean success = CGPSConverterConvert(converter, provider, consumer, NULL);
    
    int val = (success ? SKPSConversionSucceeded : SKPSConversionFailed);
    
    NSMethodSignature *ms = [NSApp methodSignatureForSelector:@selector(stopModalWithCode:)];
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:ms];
    [invocation setTarget:NSApp];
    [invocation setSelector:@selector(stopModalWithCode:)];
    [invocation setArgument:&val atIndex:2];
    [invocation performSelectorOnMainThread:@selector(invoke) withObject:nil waitUntilDone:NO];
    
    [pool release];
}    

- (void)processingPostScriptPage:(NSNumber *)page;
{
    [textField setStringValue:[[NSString stringWithFormat:NSLocalizedString(@"Processing page %d", @"PS conversion progress message"), [page intValue]] stringByAppendingEllipsis]];
}

- (void)postscriptConversionCompleted:(BOOL)didComplete;
{
    [textField setStringValue:NSLocalizedString(@"File successfully converted!", @"PS conversion progress message")];
    [progressBar stopAnimation:nil];
    [cancelButton setTitle:NSLocalizedString(@"Close", @"Button title")];
    [cancelButton setAction:@selector(close:)];
}

- (void)postscriptConversionStarted;
{
    [progressBar startAnimation:nil];
    [textField setStringValue:[[NSString stringWithFormat:NSLocalizedString(@"Converting PostScript", @"PS conversion progress message")] stringByAppendingEllipsis]];
}

- (void)showPostScriptConversionMessage:(NSString *)message;
{
    [textField setStringValue:message];
}

@end


@implementation SKDVIProgressController

- (NSData *)PDFDataWithDVIFile:(NSString *)dviFile {
    NSData *psData = nil;
    
    NSString *dvipsPath = [[NSUserDefaults standardUserDefaults] stringForKey:@"SKDvipsBinaryPath"];
    NSFileManager *fm = [NSFileManager defaultManager];
    NSArray *paths = [NSArray arrayWithObjects:@"/usr/texbin", @"/usr/local/teTeX/bin/powerpc-apple-darwin-current", @"/sw/bin", @"/opt/local/bin", @"/usr/local/bin", nil];
    int i = 0, count = [paths count];
    
    while ([fm isExecutableFileAtPath:dvipsPath] == NO) {
        if (i < count) {
            dvipsPath = [[paths objectAtIndex:i++] stringByAppendingPathComponent:@"dvips"];
        } else {
            dvipsPath = nil;
            break;
        }
    }
    
    if (dvipsPath && [fm fileExistsAtPath:dviFile]) {
        NSTask *task = [[NSTask alloc] init];
        NSPipe *pipe = [NSPipe pipe];
        NSFileHandle *fileHandle = [pipe fileHandleForReading];
        
        [task setLaunchPath:dvipsPath];
        [task setArguments:[NSArray arrayWithObjects:@"-q", @"-f", dviFile, nil]]; 
        [task setCurrentDirectoryPath:[dviFile stringByDeletingLastPathComponent]];
        [task setStandardError:[NSFileHandle fileHandleWithNullDevice]];
        [task setStandardOutput:pipe];
        
        [task launch];
        
        psData = [fileHandle readDataToEndOfFile];
        
        [task release];
    }
    
    return [psData length] ? [self PDFDataWithPostScriptData:psData] : nil;
}

@end
