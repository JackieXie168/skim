//
//  SKPSProgressController.m


//  This code is licensed under a BSD license. Please see the file LICENSE for details.
//
//  Created by Adam Maxwell on 12/6/06.
//  Copyright 2006 Adam R. Maxwell. All rights reserved.
//

#import "SKPSProgressController.h"

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
        [textField setStringValue:NSLocalizedString(@"Converter already stopped.", @"")];
        [cancelButton setTitle:NSLocalizedString(@"Close", @"")];
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
    [textField setStringValue:[NSString stringWithFormat:NSLocalizedString(@"Processing page %d%C", @""), [page intValue], 0x2026]];
}

- (void)postscriptConversionCompleted:(BOOL)didComplete;
{
    [textField setStringValue:NSLocalizedString(@"File successfully converted!", @"")];
    [progressBar stopAnimation:nil];
    [cancelButton setTitle:NSLocalizedString(@"Close", @"")];
    [cancelButton setAction:@selector(close:)];
}

- (void)postscriptConversionStarted;
{
    [progressBar startAnimation:nil];
    [textField setStringValue:[NSString stringWithFormat:NSLocalizedString(@"Converting PostScript%C", @""), 0x2026]];
}

- (void)showPostScriptConversionMessage:(NSString *)message;
{
    [textField setStringValue:message];
}

@end
