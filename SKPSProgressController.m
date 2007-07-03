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

enum {
    SKConversionCanceled = -1,
    SKConversionSucceeded = 0,
    SKConversionFailed = 1
};

@interface SKConversionProgressController (Private)
- (int)runModalConversionInWithInfo:(NSDictionary *)info;
- (void)doConversionWithInfo:(NSDictionary *)info;
- (void)conversionCompleted:(BOOL)didComplete;
- (void)conversionStarted;
- (NSString *)fileType;
@end

@interface SKPSProgressController (Private)
- (void)processingPostScriptPage:(NSNumber *)page;
- (void)showPostScriptConversionMessage:(NSString *)message;
@end

static void PSConverterBeginDocumentCallback(void *info)
{
    id delegate = (id)info;
    if (delegate && [delegate respondsToSelector:@selector(conversionStarted)])
        [delegate performSelectorOnMainThread:@selector(conversionStarted) withObject:nil waitUntilDone:NO];
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
    if (delegate && [delegate respondsToSelector:@selector(conversionCompleted:)]) {
        NSMethodSignature *ms = [delegate methodSignatureForSelector:@selector(conversionCompleted:)];
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:ms];
        [invocation setTarget:delegate];
        [invocation setSelector:@selector(conversionCompleted:)];
        
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

#pragma mark -

@implementation SKConversionProgressController

- (void)awakeFromNib
{
    [progressBar setUsesThreadedAnimation:YES];
    [[self window] setTitle:@""];
}

- (NSString *)windowNibName { return @"ConversionProgressWindow"; }

- (IBAction)close:(id)sender { [self close]; }

- (IBAction)cancel:(id)sender {}

@end


@implementation SKConversionProgressController (Private)

- (int)runModalConversionInWithInfo:(NSDictionary *)info {
    
    NSModalSession session = [NSApp beginModalSessionForWindow:[self window]];
    BOOL didDetach = NO;
    int rv = 0;
    
    while (1) {
        
        // we run this inside the modal session since the thread could end before runModalForWindow starts
        if (NO == didDetach) {
            [NSThread detachNewThreadSelector:@selector(doConversionWithInfo:) toTarget:self withObject:info];
            didDetach = YES;
        }
        
        rv = [NSApp runModalSession:session];
        if (rv != NSRunContinuesResponse)
            break;
    }
    
    [NSApp endModalSession:session];
    
    // close the window when finished
    [self close];
    
    return rv;
}

- (void)doConversionWithInfo:(NSDictionary *)info {}    

- (NSString *)fileType { return @""; }

- (void)conversionCompleted:(BOOL)didComplete;
{
    [textField setStringValue:NSLocalizedString(@"File successfully converted!", @"PS conversion progress message")];
    [progressBar stopAnimation:nil];
    [cancelButton setTitle:NSLocalizedString(@"Close", @"Button title")];
    [cancelButton setAction:@selector(close:)];
}

- (void)conversionStarted;
{
    [progressBar startAnimation:nil];
    [textField setStringValue:[[NSString stringWithFormat:NSLocalizedString(@"Converting %@", @"PS conversion progress message"), [self fileType]] stringByAppendingEllipsis]];
}

@end

#pragma mark -

@implementation SKPSProgressController

- (void)dealloc
{
    if (converter) CFRelease(converter);
    [super dealloc];
}

- (IBAction)cancel:(id)sender
{
    [NSApp stopModalWithCode:SKConversionCanceled];

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
    
    int rv = [self runModalConversionInWithInfo:dictionary];
    
    CGDataProviderRelease(provider);
    CGDataConsumerRelease(consumer);
    
    if (rv != SKConversionSucceeded) {
        CFRelease(pdfData);
        pdfData = nil;
    }
    
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
    
    int val = (success ? SKConversionSucceeded : SKConversionFailed);
    
    NSMethodSignature *ms = [NSApp methodSignatureForSelector:@selector(stopModalWithCode:)];
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:ms];
    [invocation setTarget:NSApp];
    [invocation setSelector:@selector(stopModalWithCode:)];
    [invocation setArgument:&val atIndex:2];
    [invocation performSelectorOnMainThread:@selector(invoke) withObject:nil waitUntilDone:NO];
    
    [pool release];
}    

- (NSString *)fileType {
    return @"PostScript";
}

- (void)processingPostScriptPage:(NSNumber *)page;
{
    [textField setStringValue:[[NSString stringWithFormat:NSLocalizedString(@"Processing page %d", @"PS conversion progress message"), [page intValue]] stringByAppendingEllipsis]];
}

- (void)showPostScriptConversionMessage:(NSString *)message;
{
    [textField setStringValue:message];
}

@end

#pragma mark -

@implementation SKDVIProgressController

- (IBAction)cancel:(id)sender
{
    if (task == nil) {
        NSBeep();
        [textField setStringValue:NSLocalizedString(@"Converter already stopped.", @"PS conversion progress message")];
        [cancelButton setTitle:NSLocalizedString(@"Close", @"Button title")];
        [cancelButton setAction:@selector(close:)];
    } else {
        [task terminate];
    }
}

- (NSData *)PDFDataWithDVIFile:(NSString *)dviFile {
    NSMutableData *pdfData = [[NSMutableData alloc] init];
    
    NSDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys:dviFile, @"dviFile", pdfData, @"pdfData", nil];
    
    int rv = [self runModalConversionInWithInfo:dictionary];
    
    if (rv != SKConversionSucceeded) {
        [pdfData release];
        pdfData = nil;
    }
    
    return [pdfData autorelease];
}

@end

@implementation SKDVIProgressController (Private)

- (void)doConversionWithInfo:(NSDictionary *)info {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    NSString *dviFile = [info objectForKey:@"dviFile"];
    NSString *dvipdfmxPath = [[NSUserDefaults standardUserDefaults] stringForKey:@"SKDvipdfmxBinaryPath"];
    NSFileManager *fm = [NSFileManager defaultManager];
    NSArray *paths = [NSArray arrayWithObjects:@"/usr/texbin", @"/usr/local/teTeX/bin/powerpc-apple-darwin-current", @"/sw/bin", @"/opt/local/bin", @"/usr/local/bin", nil];
    int i = 0, count = [paths count];
    
    while ([fm isExecutableFileAtPath:dvipdfmxPath] == NO) {
        if (i < count) {
            dvipdfmxPath = [[paths objectAtIndex:i++] stringByAppendingPathComponent:@"dvipdfmx"];
        } else {
            dvipdfmxPath = nil;
            break;
        }
    }
    
    NSString *tmpDir = NSTemporaryDirectory();
    NSString *pdfFile = [tmpDir stringByAppendingPathComponent:[[[dviFile lastPathComponent] stringByDeletingPathExtension] stringByAppendingPathExtension:@"pdf"]];
    BOOL success = dvipdfmxPath != nil && [fm fileExistsAtPath:dviFile];
    
    NSMethodSignature *ms;
    NSInvocation *invocation;
    
    if (success) {
        
        [fm createDirectoryAtPath:tmpDir attributes:nil];
        
        task = [[NSTask alloc] init];
        [task setLaunchPath:dvipdfmxPath];
        [task setArguments:[NSArray arrayWithObjects:@"-o", pdfFile, dviFile, nil]]; 
        [task setCurrentDirectoryPath:[dviFile stringByDeletingLastPathComponent]];
        [task setStandardError:[NSFileHandle fileHandleWithNullDevice]];
        
        @try {
            [task launch];
        }
        @catch(id exception) {
            if([task isRunning])
                [task terminate];
            NSLog(@"%@ %@ failed", [task description], [task launchPath]);
            success = NO;
        }
        
        ms = [self methodSignatureForSelector:@selector(conversionStarted)];
        invocation = [NSInvocation invocationWithMethodSignature:ms];
        [invocation setTarget:self];
        [invocation setSelector:@selector(conversionStarted)];
        [invocation performSelectorOnMainThread:@selector(invoke) withObject:nil waitUntilDone:NO];
        
        if (success) {
            [task waitUntilExit];
            [task terminate];
            success = 0 == [task terminationStatus];
        }
    }
    
    [task release];
    task = nil;
    
    if (success)
        [[info objectForKey:@"pdfData"] setData:[NSData dataWithContentsOfFile:pdfFile]];
    [fm removeFileAtPath:tmpDir handler:nil];
    
    ms = [self methodSignatureForSelector:@selector(conversionCompleted:)];
    invocation = [NSInvocation invocationWithMethodSignature:ms];
    [invocation setTarget:self];
    [invocation setSelector:@selector(conversionCompleted:)];
    [invocation setArgument:&success atIndex:2];
    [invocation performSelectorOnMainThread:@selector(invoke) withObject:nil waitUntilDone:NO];
    
    int val = (success ? SKConversionSucceeded : SKConversionFailed);
    ms = [NSApp methodSignatureForSelector:@selector(stopModalWithCode:)];
    invocation = [NSInvocation invocationWithMethodSignature:ms];
    [invocation setTarget:NSApp];
    [invocation setSelector:@selector(stopModalWithCode:)];
    [invocation setArgument:&val atIndex:2];
    [invocation performSelectorOnMainThread:@selector(invoke) withObject:nil waitUntilDone:NO];
    
    [pool release];
}

- (NSString *)fileType {
    return @"DVI";
}

@end
