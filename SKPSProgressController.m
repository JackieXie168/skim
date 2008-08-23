//
//  SKPSProgressController.m
//  Skim
//
//  Created by Adam Maxwell on 12/6/06.
/*
 This software is Copyright (c) 2006-2008
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
#import "NSTask_SKExtensions.h"
#import "Files_SKExtensions.h"
#import "NSInvocation_SKExtensions.h"
#import <libkern/OSAtomic.h>

static NSString *SKPSProgressProviderKey = @"provider";
static NSString *SKPSProgressConsumerKey = @"consumer";
static NSString *SKPSProgressDviFileKey = @"dviFile";
static NSString *SKPSProgressPdfDataKey = @"pdfData";
static NSString *SKPSProgressDviToolPathKey = @"dviToolPath";

static NSString *SKDviConversionCommandKey = @"SKDviConversionCommand";

enum {
    SKConversionSucceeded = 0,
    SKConversionFailed = 1
};

@interface SKConversionProgressController (Private)
- (int)runModalConversionWithInfo:(NSDictionary *)info;
- (void)doConversionWithInfo:(NSDictionary *)info;
- (void)stopModalOnMainThread:(BOOL)success;
- (void)conversionCompleted:(BOOL)didComplete;
- (void)conversionStarted;
- (void)converterWasStopped;
- (NSString *)fileType;
@end

@interface SKPSProgressController (Private)
- (void)processingPostScriptPage:(NSNumber *)page;
- (void)showPostScriptConversionMessage:(NSString *)message;
@end

#pragma mark Callbacks

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
        BOOL val = (success == true);
        NSInvocation *invocation = [NSInvocation invocationWithTarget:delegate selector:@selector(conversionCompleted:) argument:&val];
        [invocation performSelectorOnMainThread:@selector(invoke) withObject:nil waitUntilDone:NO];
    }
}
/*
static void PSConverterMessageCallback(void *info, CFStringRef message)
{
    id delegate = (id)info;
    if (delegate && [delegate respondsToSelector:@selector(showPostScriptConversionMessage:)])
        [delegate performSelectorOnMainThread:@selector(showPostScriptConversionMessage:) withObject:(id)message waitUntilDone:NO];
}
*/
CGPSConverterCallbacks SKPSConverterCallbacks = { 
    0, 
    PSConverterBeginDocumentCallback, 
    PSConverterEndDocumentCallback, 
    PSConverterBeginPageCallback,   /* haven't seen this called in my testing */
    NULL, 
    NULL, 
    NULL,     /* could use PSConverterMessageCallback, but messages are usually not useful */
    NULL 
};

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

- (int)runModalConversionWithInfo:(NSDictionary *)info {
    
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
 
- (void)stopModalOnMainThread:(BOOL)success {
    int val = (success ? SKConversionSucceeded : SKConversionFailed);
    NSInvocation *invocation = [NSInvocation invocationWithTarget:NSApp selector:@selector(stopModalWithCode:) argument:&val];
    [invocation performSelectorOnMainThread:@selector(invoke) withObject:nil waitUntilDone:NO];
}

- (void)converterWasStopped {
    NSBeep();
    [textField setStringValue:NSLocalizedString(@"Converter already stopped.", @"PS conversion progress message")];
    [cancelButton setTitle:NSLocalizedString(@"Close", @"Button title")];
    [cancelButton setAction:@selector(close:)];
}

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
    [textField setStringValue:[[NSString stringWithFormat:NSLocalizedString(@"Converting %@", @"PS conversion progress message"), [[NSDocumentController sharedDocumentController] displayNameForType:[self fileType]]] stringByAppendingEllipsis]];
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
    if (CGPSConverterAbort(converter) == false)
        [self converterWasStopped];
}

- (NSData *)PDFDataWithPostScriptData:(NSData *)psData
{
    NSAssert(NULL == converter, @"attempted to reenter SKPSProgressController, but this is not supported");
    
    // pass self as info
    converter = CGPSConverterCreate((void *)self, &SKPSConverterCallbacks, NULL);
    NSAssert(converter != NULL, @"unable to create PS converter");
    
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((CFDataRef)psData);
    
    CFMutableDataRef pdfData = CFDataCreateMutable(CFGetAllocator((CFDataRef)psData), 0);
    CGDataConsumerRef consumer = CGDataConsumerCreateWithCFData(pdfData);
    
    NSDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys:(id)provider, SKPSProgressProviderKey, (id)consumer, SKPSProgressConsumerKey, nil];
    
    int rv = [self runModalConversionWithInfo:dictionary];
    
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
    
    CGDataProviderRef provider = (void *)[info objectForKey:SKPSProgressProviderKey];
    CGDataConsumerRef consumer = (void *)[info objectForKey:SKPSProgressConsumerKey];
    Boolean success = CGPSConverterConvert(converter, provider, consumer, NULL);
    
    [self stopModalOnMainThread:success];
    
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

+ (NSString *)dviToolPath {
    static NSString *dviToolPath = nil;
    
    if (dviToolPath == nil) {
        NSString *commandPath = [[NSUserDefaults standardUserDefaults] stringForKey:SKDviConversionCommandKey];
        NSString *commandName = [commandPath lastPathComponent];
        NSArray *paths = [NSArray arrayWithObjects:@"/usr/texbin", @"/usr/local/gwTeX/bin/powerpc-apple-darwin-current", @"/usr/local/gwTeX/bin/i386-apple-darwin-current", @"/sw/bin", @"/opt/local/bin", @"/usr/local/bin", nil];
        int i = 0, iMax = [paths count];
        NSFileManager *fm = [NSFileManager defaultManager];
        NSArray *supportedTools = [NSArray arrayWithObjects:@"dvipdfmx", @"dvipdfm", @"dvipdf", @"dvips", nil];
        NSEnumerator *toolEnum = [supportedTools objectEnumerator];
        
        NSAssert1(commandName == nil || [supportedTools containsObject:commandName], @"DVI converter %@ is not supported", commandName);
        if (commandName == nil || [supportedTools containsObject:commandName] == NO)
            commandName = [toolEnum nextObject];
        do {
            i = 0;
            while ([fm isExecutableFileAtPath:commandPath] == NO) {
                if (i >= iMax) {
                    commandPath = nil;
                    break;
                }
                commandPath = [[paths objectAtIndex:i++] stringByAppendingPathComponent:commandName];
            }
        } while (commandPath == nil && (commandName = [toolEnum nextObject]));
        dviToolPath = [commandPath retain];
    }
    
    return dviToolPath;
}

- (IBAction)cancel:(id)sender
{
    OSMemoryBarrier();
    if (convertingPS) {
        [super cancel:sender];
    } else {
        BOOL wasRunning = NO;
        @synchronized(self) {
            wasRunning = [task isRunning];
            if (wasRunning)
                [task terminate];
        }
        if (wasRunning == NO)
            [self converterWasStopped];
    }
}

- (NSData *)PDFDataWithDVIFile:(NSString *)dviFile {
    NSString *dviToolPath = [[self class] dviToolPath];
    NSMutableData *pdfData = nil;
    
    if (dviToolPath) {
        pdfData = [[NSMutableData alloc] init];
        
        NSDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys:dviFile, SKPSProgressDviFileKey, pdfData, SKPSProgressPdfDataKey, dviToolPath, SKPSProgressDviToolPathKey, nil];
        
        int rv = [self runModalConversionWithInfo:dictionary];
        
        if (rv != SKConversionSucceeded) {
            [pdfData release];
            pdfData = nil;
        }
    } else {
        NSBeep();
    }
    return [pdfData autorelease];
}

@end

#pragma mark -

@implementation SKDVIProgressController (Private)

- (void)doConversionWithInfo:(NSDictionary *)info {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    NSString *dviFile = [info objectForKey:SKPSProgressDviFileKey];
    NSString *commandPath = [info objectForKey:SKPSProgressDviToolPathKey];
    NSString *commandName = [commandPath lastPathComponent];
    NSString *tmpDir = SKUniqueTemporaryDirectory();
    BOOL outputPS = [commandName isEqualToString:@"dvips"];
    NSString *outFile = [tmpDir stringByAppendingPathComponent:[[dviFile lastPathComponent] stringByReplacingPathExtension:outputPS ? @"ps" : @"pdf"]];
    NSArray *arguments = [commandName isEqualToString:@"dvipdf"] ? [NSArray arrayWithObjects:dviFile, outFile, nil] : [NSArray arrayWithObjects:@"-o", outFile, dviFile, nil];
    BOOL success = SKFileExistsAtPath(dviFile);
    
    NSInvocation *invocation;
    
    if (success) {
        
        @synchronized(self) {
            task = [[NSTask launchedTaskWithLaunchPath:commandPath arguments:arguments currentDirectoryPath:[dviFile stringByDeletingLastPathComponent]] retain];
        }
        
        invocation = [NSInvocation invocationWithTarget:self selector:@selector(conversionStarted)];
        [invocation performSelectorOnMainThread:@selector(invoke) withObject:nil waitUntilDone:NO];
        
        if (success) {
            [task waitUntilExit];
            [task terminate];
            success = 0 == [task terminationStatus];
        }
    }
    
    @synchronized(self) {
        [task release];
        task = nil;
    }
    
    NSData *outData = success ? [NSData dataWithContentsOfFile:outFile] : nil;
    NSMutableData *pdfData = [info objectForKey:SKPSProgressPdfDataKey];
    
    if (outputPS && success) {
        NSAssert(NULL == converter, @"attempted to reenter SKPSProgressController, but this is not supported");
        
        // pass self as info
        converter = CGPSConverterCreate((void *)self, &SKPSConverterCallbacks, NULL);
        NSAssert(converter != NULL, @"unable to create PS converter");
        
        CGDataProviderRef provider = CGDataProviderCreateWithCFData((CFDataRef)outData);
        CGDataConsumerRef consumer = CGDataConsumerCreateWithCFData((CFMutableDataRef)pdfData);
        
        NSDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys:(id)provider, SKPSProgressProviderKey, (id)consumer, SKPSProgressConsumerKey, nil];
        
        OSAtomicCompareAndSwap32Barrier(0, 1, (int32_t *)&convertingPS);
        
        [super doConversionWithInfo:dictionary];
        
        CGDataProviderRelease(provider);
        CGDataConsumerRelease(consumer);
    } else {
        if (success)
            [pdfData setData:outData];
        
        invocation = [NSInvocation invocationWithTarget:self selector:@selector(conversionCompleted:) argument:&success];
        [invocation performSelectorOnMainThread:@selector(invoke) withObject:nil waitUntilDone:NO];
        
        [self stopModalOnMainThread:success];
    }
    
    FSPathDeleteContainer((UInt8 *)[tmpDir fileSystemRepresentation]);
    
    [pool release];
}

- (NSString *)fileType {
    return @"DVI";
}

@end
