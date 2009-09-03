//
//  SKConversionProgressController.m
//  Skim
//
//  Created by Adam Maxwell on 12/6/06.
/*
 This software is Copyright (c) 2006-2009
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

#import "SKConversionProgressController.h"
#import "NSString_SKExtensions.h"
#import "NSTask_SKExtensions.h"
#import "Files_SKExtensions.h"
#import "NSInvocation_SKExtensions.h"
#import <libkern/OSAtomic.h>

#define PROVIDER_KEY    @"provider"
#define CONSUMER_KEY    @"consumer"
#define DVIFILE_KEY     @"dviFile"
#define PDFPATH_KEY     @"pdfData"
#define DVITOOLPATH_KEY @"dviToolPath"

#define SKDviConversionCommandKey @"SKDviConversionCommand"

enum {
    SKConversionSucceeded = 0,
    SKConversionFailed = 1
};

@interface SKConversionProgressController (Private)
- (NSInteger)runModalConversionWithInfo:(NSDictionary *)info;
- (void)doConversionWithInfo:(NSDictionary *)info;
- (void)stopModalOnMainThread:(BOOL)success;
- (void)conversionCompleted:(BOOL)didComplete;
- (void)conversionStarted;
- (void)converterWasStopped;
- (NSString *)fileType;
- (void)setButtonTitle:(NSString *)title action:(SEL)action;
@end

#pragma mark Callbacks

static void PSConverterBeginDocumentCallback(void *info)
{
    id delegate = (id)info;
    if ([delegate respondsToSelector:@selector(conversionStarted)])
        [delegate performSelectorOnMainThread:@selector(conversionStarted) withObject:nil waitUntilDone:NO];
}

static void PSConverterEndDocumentCallback(void *info, bool success)
{
    id delegate = (id)info;
    if ([delegate respondsToSelector:@selector(conversionCompleted:)]) {
        BOOL val = (success == true);
        NSInvocation *invocation = [NSInvocation invocationWithTarget:delegate selector:@selector(conversionCompleted:) argument:&val];
        [invocation performSelectorOnMainThread:@selector(invoke) withObject:nil waitUntilDone:NO];
    }
}

CGPSConverterCallbacks SKPSConverterCallbacks = { 
    0, 
    PSConverterBeginDocumentCallback, 
    PSConverterEndDocumentCallback, 
    NULL, // haven't seen this called in my testing
    NULL, 
    NULL, 
    NULL, // messages are usually not useful
    NULL 
};

#pragma mark -

@implementation SKConversionProgressController

+ (NSData *)PDFDataWithPostScriptData:(NSData *)psData
{
    return [[[[SKPSProgressController alloc] init] autorelease] PDFDataWithPostScriptData:psData];
}

+ (NSData *)PDFDataWithDVIFile:(NSString *)dviFile
{
    return [[[[SKDVIProgressController alloc] init] autorelease] PDFDataWithDVIFile:dviFile];
}

- (void)awakeFromNib
{
    [[self window] setCollectionBehavior:NSWindowCollectionBehaviorMoveToActiveSpace];
    [progressBar setUsesThreadedAnimation:YES];
    [self setButtonTitle:NSLocalizedString(@"Cancel", @"Button title") action:@selector(cancel:)];
    [[self window] setTitle:[NSString stringWithFormat:NSLocalizedString(@"Converting %@", @"PS conversion progress message"), [[NSDocumentController sharedDocumentController] displayNameForType:[self fileType]]]];
}

- (NSString *)windowNibName { return @"ConversionProgressWindow"; }

- (IBAction)close:(id)sender { [self close]; }

- (IBAction)cancel:(id)sender {}

- (NSInteger)runModalConversionWithInfo:(NSDictionary *)info {
    
    NSModalSession session = [NSApp beginModalSessionForWindow:[self window]];
    BOOL didDetach = NO;
    NSInteger rv = 0;
    
    while (YES) {
        
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

- (void)doConversionWithInfo:(NSDictionary *)info { [self stopModalOnMainThread:NO]; }   
 
- (void)stopModalOnMainThread:(BOOL)success {
    NSInteger val = (success ? SKConversionSucceeded : SKConversionFailed);
    NSInvocation *invocation = [NSInvocation invocationWithTarget:NSApp selector:@selector(stopModalWithCode:) argument:&val];
    [invocation performSelectorOnMainThread:@selector(invoke) withObject:nil waitUntilDone:NO];
}

- (void)converterWasStopped {
    NSBeep();
    [textField setStringValue:NSLocalizedString(@"Converter already stopped.", @"PS conversion progress message")];
    [self setButtonTitle:NSLocalizedString(@"Close", @"Button title") action:@selector(close:)];
}

- (NSString *)fileType { return @""; }

- (void)conversionCompleted:(BOOL)didComplete;
{
    [textField setStringValue:NSLocalizedString(@"File successfully converted!", @"PS conversion progress message")];
    [progressBar stopAnimation:nil];
    [self setButtonTitle:NSLocalizedString(@"Close", @"Button title") action:@selector(close:)];
}

- (void)conversionStarted;
{
    [progressBar startAnimation:nil];
    [textField setStringValue:[[[self window] title] stringByAppendingEllipsis]];
}

- (void)setButtonTitle:(NSString *)title action:(SEL)action {
    [cancelButton setTitle:title];
    [cancelButton setAction:action];
    NSRect frame = [cancelButton frame];
    [cancelButton sizeToFit];
    CGFloat width = SKMax(NSWidth([cancelButton frame]), 90.0);
    frame.origin.x = NSMaxX(frame) - width;
    frame.size.width = width;
    [cancelButton setFrame:frame];
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
    
    NSDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys:(id)provider, PROVIDER_KEY, (id)consumer, CONSUMER_KEY, nil];
    
    NSInteger rv = [self runModalConversionWithInfo:dictionary];
    
    CGDataProviderRelease(provider);
    CGDataConsumerRelease(consumer);
    
    if (rv != SKConversionSucceeded) {
        CFRelease(pdfData);
        pdfData = nil;
    }
    
    return [(id)pdfData autorelease];
}

- (void)doConversionWithInfo:(NSDictionary *)info;
{
    NSAutoreleasePool *pool = [NSAutoreleasePool new];
    
    CGDataProviderRef provider = (void *)[info objectForKey:PROVIDER_KEY];
    CGDataConsumerRef consumer = (void *)[info objectForKey:CONSUMER_KEY];
    Boolean success = CGPSConverterConvert(converter, provider, consumer, NULL);
    
    [self stopModalOnMainThread:success];
    
    [pool release];
}    

- (NSString *)fileType {
    return @"PostScript";
}

@end

#pragma mark -

@implementation SKDVIProgressController

+ (NSString *)dviToolPath {
    static NSString *dviToolPath = nil;
    
    if (dviToolPath == nil) {
        NSString *commandPath = [[NSUserDefaults standardUserDefaults] stringForKey:SKDviConversionCommandKey];
        NSString *commandName = [commandPath lastPathComponent];
        NSArray *paths = [NSArray arrayWithObjects:@"/usr/texbin", @"/sw/bin", @"/opt/local/bin", @"/usr/local/bin", nil];
        NSInteger i = 0, iMax = [paths count];
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
    if (convertingPS)
        [super cancel:sender];
    else if (taskShouldStop == 0)
        OSAtomicCompareAndSwap32Barrier(0, 1, (int32_t *)&taskShouldStop);
    else
        [self converterWasStopped];
}

- (NSData *)PDFDataWithDVIFile:(NSString *)dviFile {
    NSString *dviToolPath = [[self class] dviToolPath];
    NSMutableData *pdfData = nil;
    
    if (dviToolPath) {
        taskShouldStop = 0;
        pdfData = [[NSMutableData alloc] init];
        
        NSDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys:dviFile, DVIFILE_KEY, pdfData, PDFPATH_KEY, dviToolPath, DVITOOLPATH_KEY, nil];
        
        NSInteger rv = [self runModalConversionWithInfo:dictionary];
        
        if (rv != SKConversionSucceeded) {
            [pdfData release];
            pdfData = nil;
        }
    } else {
        NSBeep();
    }
    return [pdfData autorelease];
}

- (BOOL)shouldKeepRunning {
    OSMemoryBarrier();
    return taskShouldStop == 0;
}

- (void)doConversionWithInfo:(NSDictionary *)info {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    NSString *dviFile = [info objectForKey:DVIFILE_KEY];
    NSString *commandPath = [info objectForKey:DVITOOLPATH_KEY];
    NSString *commandName = [commandPath lastPathComponent];
    NSString *tmpDir = SKUniqueTemporaryDirectory();
    BOOL outputPS = [commandName isEqualToString:@"dvips"];
    NSString *outFile = [tmpDir stringByAppendingPathComponent:[[dviFile lastPathComponent] stringByReplacingPathExtension:outputPS ? @"ps" : @"pdf"]];
    NSArray *arguments = [commandName isEqualToString:@"dvipdf"] ? [NSArray arrayWithObjects:dviFile, outFile, nil] : [NSArray arrayWithObjects:@"-o", outFile, dviFile, nil];
    BOOL success = NO;
    
    NSInvocation *invocation;
    
    if (SKFileExistsAtPath(dviFile) && [self shouldKeepRunning]) {
        NSTask *task = [NSTask launchedTaskWithLaunchPath:commandPath arguments:arguments currentDirectoryPath:[dviFile stringByDeletingLastPathComponent]];
        if (task) {
            invocation = [NSInvocation invocationWithTarget:self selector:@selector(conversionStarted)];
            [invocation performSelectorOnMainThread:@selector(invoke) withObject:nil waitUntilDone:NO];
        
            while ([task isRunning] && [self shouldKeepRunning])
                [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
            if ([task isRunning])
                [task terminate];
            else if ([self shouldKeepRunning])
                success = ([task terminationStatus] == 0);
        }
    }
    
    NSData *outData = success ? [NSData dataWithContentsOfFile:outFile] : nil;
    NSMutableData *pdfData = [info objectForKey:PDFPATH_KEY];
    
    if (outputPS && success) {
        NSAssert(NULL == converter, @"attempted to reenter SKPSProgressController, but this is not supported");
        
        // pass self as info
        converter = CGPSConverterCreate((void *)self, &SKPSConverterCallbacks, NULL);
        NSAssert(converter != NULL, @"unable to create PS converter");
        
        CGDataProviderRef provider = CGDataProviderCreateWithCFData((CFDataRef)outData);
        CGDataConsumerRef consumer = CGDataConsumerCreateWithCFData((CFMutableDataRef)pdfData);
        
        NSDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys:(id)provider, PROVIDER_KEY, (id)consumer, CONSUMER_KEY, nil];
        
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
