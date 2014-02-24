//
//  SKConversionProgressController.m
//  Skim
//
//  Created by Adam Maxwell on 12/6/06.
/*
 This software is Copyright (c) 2006-2014
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
#import "NSURL_SKExtensions.h"
#import "NSFileManager_SKExtensions.h"
#import "NSInvocation_SKExtensions.h"
#import "SKDocumentController.h"
#import "NSGraphics_SKExtensions.h"
#import "NSDocument_SKExtensions.h"
#import "NSError_SKExtensions.h"

#define PROVIDER_KEY    @"provider"
#define CONSUMER_KEY    @"consumer"
#define INPUTURL_KEY    @"inputURL"
#define PDFDATA_KEY     @"pdfData"
#define TOOLPATH_KEY    @"toolPath"

#define SKDviConversionCommandKey @"SKDviConversionCommand"
#define SKXdvConversionCommandKey @"SKXdvConversionCommand"

#define MIN_BUTTON_WIDTH 90.0

enum {
    SKConversionSucceeded = 0,
    SKConversionFailed = 1
};

@interface SKConversionProgressController (Private)
+ (NSString *)dviToolPath;
+ (NSString *)xdvToolPath;
- (NSData *)newPDFDataWithPostScriptData:(NSData *)psData error:(NSError **)outError;
- (NSData *)newPDFDataWithDVIAtURL:(NSURL *)dviURL toolPath:(NSString *)toolPath fileType:(NSString *)aFileType error:(NSError **)outError;
- (void)conversionCompleted;
- (void)conversionStarted;
- (void)converterWasStopped;
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
    if ([delegate respondsToSelector:@selector(conversionCompleted)])
        [delegate performSelectorOnMainThread:@selector(conversionCompleted) withObject:nil waitUntilDone:NO];
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

@synthesize cancelButton, progressBar, textField;

+ (NSData *)newPDFDataWithPostScriptData:(NSData *)psData error:(NSError **)outError {
    return [[[[self alloc] init] autorelease] newPDFDataWithPostScriptData:psData error:outError];
}

+ (NSData *)newPDFDataWithDVIAtURL:(NSURL *)dviURL error:(NSError **)outError {
    NSString *dviToolPath = [self dviToolPath];
    if (dviToolPath)
        return [[[[self alloc] init] autorelease] newPDFDataWithDVIAtURL:dviURL toolPath:dviToolPath fileType:SKDVIDocumentType error:outError];
    else
        NSBeep();
    return nil;
}

+ (NSData *)newPDFDataWithXDVAtURL:(NSURL *)xdvURL error:(NSError **)outError {
    NSString *xdvToolPath = [self xdvToolPath];
    if (xdvToolPath)
        return [[[[self alloc] init] autorelease] newPDFDataWithDVIAtURL:xdvURL toolPath:xdvToolPath fileType:SKXDVDocumentType error:outError];
    else
        NSBeep();
    return nil;
}

- (void)dealloc {
    SKCFDESTROY(converter);
    SKDESTROY(outputFileURL);
    SKDESTROY(outputData);
    SKDESTROY(task);
    SKDESTROY(cancelButton);
    SKDESTROY(progressBar);
    SKDESTROY(textField);
    [super dealloc];
}

- (void)awakeFromNib {
    [[self window] setCollectionBehavior:NSWindowCollectionBehaviorMoveToActiveSpace];
    [progressBar setUsesThreadedAnimation:YES];
    [self setButtonTitle:NSLocalizedString(@"Cancel", @"Button title") action:@selector(cancel:)];
    [[self window] setTitle:[NSString stringWithFormat:NSLocalizedString(@"Converting %@", @"PS conversion progress message"), [[NSDocumentController sharedDocumentController] displayNameForType:fileType]]];
}

- (NSString *)windowNibName { return @"ConversionProgressWindow"; }

- (IBAction)close:(id)sender { [NSApp stopModalWithCode:SKConversionFailed]; }

- (IBAction)cancel:(id)sender {
    if (cancelled == YES) {
        [self converterWasStopped];
    } else {
        cancelled = YES;
        if (converter)
            CGPSConverterAbort(converter);
        else if ([task isRunning])
            [task terminate];
    }
}

- (NSInteger)runModalBlock:(void(^)(void))block {
    
    NSModalSession session = [NSApp beginModalSessionForWindow:[self window]];
    NSInteger rv = 0;
    
    // we run this inside the modal session since the thread could end before runModalForWindow starts
    block();
    
    while (YES) {
        rv = [NSApp runModalSession:session];
        if (rv != NSRunContinuesResponse)
            break;
    }
    
    [NSApp endModalSession:session];
    
    // close the window when finished
    [self close];
    
    return rv;
}

- (void)converterWasStopped {
    NSBeep();
    [textField setStringValue:NSLocalizedString(@"Converter already stopped.", @"PS conversion progress message")];
    [self setButtonTitle:NSLocalizedString(@"Close", @"Button title") action:@selector(close:)];
}

- (void)conversionCompleted {
    [textField setStringValue:NSLocalizedString(@"File successfully converted!", @"PS conversion progress message")];
    [progressBar stopAnimation:nil];
    [self setButtonTitle:NSLocalizedString(@"Close", @"Button title") action:@selector(close:)];
}

- (void)conversionStarted {
    [progressBar startAnimation:nil];
    [textField setStringValue:[[[self window] title] stringByAppendingEllipsis]];
}

- (void)setButtonTitle:(NSString *)title action:(SEL)action {
    [cancelButton setTitle:title];
    [cancelButton setAction:action];
    SKAutoSizeButtons([NSArray arrayWithObjects:cancelButton, nil], YES);
}

#pragma mark PostScript

- (void)stopModalWithResult:(NSNumber *)result {
    [NSApp stopModalWithCode:[result boolValue] ? SKConversionSucceeded : SKConversionFailed];
}

- (void)convertPostScriptData:(NSData *)psData {
    // pass self as info
    converter = CGPSConverterCreate((void *)self, &SKPSConverterCallbacks, NULL);
    NSAssert(converter != NULL, @"unable to create PS converter");
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        CFMutableDataRef pdfData = CFDataCreateMutable(CFGetAllocator((CFDataRef)psData), 0);
        CGDataProviderRef provider = CGDataProviderCreateWithCFData((CFDataRef)psData);
        CGDataConsumerRef consumer = CGDataConsumerCreateWithCFData(pdfData);
        
        Boolean success = CGPSConverterConvert(converter, provider, consumer, NULL);
        
        if (success)
            outputData = [(NSData *)pdfData copy];
        
        CGDataProviderRelease(provider);
        CGDataConsumerRelease(consumer);
        CFRelease(pdfData);
        
        // we don't use GCD for the callback, because on Mountain Lion the messages is never received, even though that works on Snow Leopard
        [self performSelectorOnMainThread:@selector(stopModalWithResult:) withObject:[NSNumber numberWithBool:success] waitUntilDone:NO];
    });
    
}

- (NSData *)newPDFDataWithPostScriptData:(NSData *)psData error:(NSError **)outError {
    NSAssert(NULL == converter, @"attempted to reenter SKConversionProgressController, but this is not supported");
    
    fileType = SKPostScriptDocumentType;
    cancelled = NO;
    
    NSInteger rv = [self runModalBlock:^{
        [self convertPostScriptData:psData];
    }];
    
    if (rv != SKConversionSucceeded && outError) {
        if (cancelled)
            *outError = [NSError userCancelledErrorWithUnderlyingError:nil];
        else
            *outError = [NSError readFileErrorWithLocalizedDescription:NSLocalizedString(@"Unable to load file", @"Error description")];
    }
    
    return [outputData retain];
}

#pragma mark DVI and XDV

+ (NSString *)newToolPath:(NSString *)commandPath supportedTools:(NSArray *)supportedTools {
    NSString *commandName = [commandPath lastPathComponent];
    NSArray *paths = [NSArray arrayWithObjects:@"/usr/texbin", @"/sw/bin", @"/opt/local/bin", @"/usr/local/bin", nil];
    NSInteger i = 0, iMax = [paths count];
    NSFileManager *fm = [NSFileManager defaultManager];
    NSEnumerator *toolEnum = [supportedTools objectEnumerator];
    
    NSAssert1(commandName == nil || [supportedTools containsObject:commandName], @"converter %@ is not supported", commandName);
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
    
    return [commandPath retain];
}

+ (NSString *)dviToolPath {
    static NSString *dviToolPath = nil;
    if (dviToolPath == nil) {
        NSString *commandPath = [[NSUserDefaults standardUserDefaults] stringForKey:SKDviConversionCommandKey];
        NSArray *supportedTools = [NSArray arrayWithObjects:@"dvipdfmx", @"dvipdfm", @"dvipdf", @"dvips", nil];
        dviToolPath = [self newToolPath:commandPath supportedTools:supportedTools];
    }
    return dviToolPath;
}

+ (NSString *)xdvToolPath {
    static NSString *xdvToolPath = nil;
    if (xdvToolPath == nil) {
        NSString *commandPath = [[NSUserDefaults standardUserDefaults] stringForKey:SKXdvConversionCommandKey];
        NSArray *supportedTools = [NSArray arrayWithObjects:@"xdvipdfmx", @"xdv2pdf", nil];
        xdvToolPath = [self newToolPath:commandPath supportedTools:supportedTools];
    }
    return xdvToolPath;
}

- (void)taskFinished:(NSNotification *)notification {
    NSData *outData = nil;
    BOOL success = [[notification object] terminationStatus] == 0 &&
                   [outputFileURL checkResourceIsReachableAndReturnError:NULL] &&
                   cancelled == NO;
    
    SKDESTROY(task);
    
    if (success)
        outData = [NSData dataWithContentsOfURL:outputFileURL];
    
    if ([[outputFileURL pathExtension] isCaseInsensitiveEqual:@"ps"]) {
        [self convertPostScriptData:outData];
    } else {
        if (success)
            outputData = [outData retain];
        [self conversionCompleted];
        [NSApp stopModalWithCode:success ? SKConversionSucceeded : SKConversionFailed];
    }
}

- (NSData *)newPDFDataWithDVIAtURL:(NSURL *)dviURL toolPath:(NSString *)toolPath fileType:(NSString *)aFileType error:(NSError **)outError {
    NSAssert(NULL == converter, @"attempted to reenter SKConversionProgressController, but this is not supported");
    
    fileType = aFileType;
    cancelled = NO;
    
    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *commandName = [toolPath lastPathComponent];
    NSURL *tmpDirURL = [fm URLForDirectory:NSItemReplacementDirectory inDomain:NSUserDomainMask appropriateForURL:dviURL create:YES error:NULL];
    BOOL outputPS = [commandName isEqualToString:@"dvips"];
    NSURL *outFileURL = [tmpDirURL URLByAppendingPathComponent:[dviURL lastPathComponentReplacingPathExtension:outputPS ? @"ps" : @"pdf"]];
    NSArray *arguments = [commandName isEqualToString:@"dvipdf"] ? [NSArray arrayWithObjects:[dviURL path], [outFileURL path], nil] : [NSArray arrayWithObjects:@"-o", [outFileURL path], [dviURL path], nil];
    
    task = [[NSTask alloc] init];
    [task setLaunchPath:toolPath];
    [task setArguments:arguments];
    [task setCurrentDirectoryPath:[[dviURL URLByDeletingLastPathComponent] path]];
    [task setStandardOutput:[NSFileHandle fileHandleWithNullDevice]];
    [task setStandardError:[NSFileHandle fileHandleWithNullDevice]];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(taskFinished:) name:NSTaskDidTerminateNotification object:task];
    
    outputFileURL = [outFileURL retain];
    
    NSInteger rv = [self runModalBlock:^{
        @try {
            [task launch];
            [self conversionStarted];
        }
        @catch(id exception) {
            SKDESTROY(task);
            [NSApp stopModalWithCode:SKConversionFailed];
        }
    }];
    
    [fm removeItemAtURL:tmpDirURL error:NULL];
    
    if (rv != SKConversionSucceeded && outError) {
        if (cancelled)
            *outError = [NSError userCancelledErrorWithUnderlyingError:nil];
        else
            *outError = [NSError readFileErrorWithLocalizedDescription:NSLocalizedString(@"Unable to load file", @"Error description")];
    }
    
    return [outputData retain];
}

@end
