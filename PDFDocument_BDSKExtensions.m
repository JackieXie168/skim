//
//  PDFDocument_BDSKExtensions.m
//  Bibdesk
//
//  Created by Adam Maxwell on 02/20/06.
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

#import "PDFDocument_BDSKExtensions.h"
#import "SKPSProgressController.h"

@implementation PDFDocument (BDSKExtensions)

+ (NSData *)PDFDataWithPostScriptData:(NSData *)psData
{
    CGPSConverterCallbacks converterCallbacks = { 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL };
    
    CGPSConverterRef converter = CGPSConverterCreate(NULL, &converterCallbacks, NULL);
    NSAssert(converter != NULL, @"unable to create PS converter");
    
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((CFDataRef)psData);
    
    CFMutableDataRef pdfData = CFDataCreateMutable(CFGetAllocator((CFDataRef)psData), 0);
    CGDataConsumerRef consumer = CGDataConsumerCreateWithCFData(pdfData);
    Boolean success = CGPSConverterConvert(converter, provider, consumer, NULL);
    
    CGDataProviderRelease(provider);
    CGDataConsumerRelease(consumer);
    CFRelease(converter);

    if(success == FALSE){
        CFRelease(pdfData);
        pdfData = nil;
    }
    
    return [(id)pdfData autorelease];
}

// [self note] this is a category, so don't call super...
- (id)initWithPostScriptData:(NSData *)data;
{
    SKPSProgressController *progressController = [[SKPSProgressController alloc] init];
    NSData *pdfData = [progressController PDFDataWithPostScriptData:data];
    [progressController autorelease];
    return [self initWithData:pdfData];
}
        
- (id)initWithPostScriptURL:(NSURL *)fileURL;
{
    return [self initWithPostScriptData:[NSData dataWithContentsOfURL:fileURL]];
}

    
@end
