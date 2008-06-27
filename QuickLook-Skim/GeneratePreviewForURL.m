/*
 This software is Copyright (c) 2007-2008
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

#import <Foundation/Foundation.h>
#include <CoreFoundation/CoreFoundation.h>
#include <CoreServices/CoreServices.h>
#include <QuickLook/QuickLook.h>
#import <Cocoa/Cocoa.h>
#import "SKQLConverter.h"

static const CGFloat _fontSize = 12.0;

static NSDictionary *imageAttachments()
{
    NSMutableDictionary *attachments = [NSMutableDictionary dictionary];
    NSBundle *bundle = SKQLGetMainBundle();
    NSArray *allImageNames = [NSArray arrayWithObjects:@"FreeText", @"Note", @"Circle", @"Square", @"Highlight", @"Underline", @"StrikeOut", @"Line", nil];
    NSString *imageName;
    NSMutableDictionary *imgProps;
    NSData *imgData;
    
    for (imageName in allImageNames) {
        if (imgData = [NSData dataWithContentsOfFile:[bundle pathForResource:imageName ofType:@"png"]]) {
            imgProps = [[NSMutableDictionary alloc] init];
            [imgProps setObject:imgData forKey:(NSString *)kQLPreviewPropertyAttachmentDataKey];
            [attachments setObject:imgProps forKey:[imageName stringByAppendingPathExtension:@"png"]];
            [imgProps release];
        }
    }
    return attachments;
}

/* -----------------------------------------------------------------------------
   Generate a preview for file

   This function's job is to create preview for designated file
   ----------------------------------------------------------------------------- */

OSStatus GeneratePreviewForURL(void *thisInterface, QLPreviewRequestRef preview, CFURLRef url, CFStringRef contentTypeUTI, CFDictionaryRef options)
{
    NSAutoreleasePool *pool = [NSAutoreleasePool new];
    OSStatus err = 2;
    
    if (UTTypeEqual(CFSTR("net.sourceforge.skim-app.pdfd"), contentTypeUTI)) {
        
        NSString *pdfFile = SKQLPDFPathForPDFBundleURL((NSURL *)url);
        if (pdfFile) {
            NSData *data = [NSData dataWithContentsOfFile:pdfFile];
            if (data) {
                QLPreviewRequestSetDataRepresentation(preview, (CFDataRef)data, kUTTypePDF, NULL);
                err = noErr;
            }
        }
        
    } else if (UTTypeEqual(CFSTR("net.sourceforge.skim-app.skimnotes"), contentTypeUTI)) {
        
        NSData *data = [[NSData alloc] initWithContentsOfURL:(NSURL *)url options:NSUncachedRead error:NULL];
        if (data) {
            NSString *htmlString = [SKQLConverter htmlStringWithNotes:[NSKeyedUnarchiver unarchiveObjectWithData:data]];
            [data release];
            if (data = [htmlString dataUsingEncoding:NSUTF8StringEncoding]) {
                NSDictionary *props = [NSDictionary dictionaryWithObjectsAndKeys:
                                            @"UTF-8", (NSString *)kQLPreviewPropertyTextEncodingNameKey,
                                            @"text/html", (NSString *)kQLPreviewPropertyMIMETypeKey,
                                            imageAttachments(), (NSString *)kQLPreviewPropertyAttachmentsKey, nil];
                QLPreviewRequestSetDataRepresentation(preview, (CFDataRef)data, kUTTypeHTML, (CFDictionaryRef)props);
                err = noErr;
            }
        }
        
    }
    
    [pool release];
    
    return err;
}

void CancelPreviewGeneration(void* thisInterface, QLPreviewRequestRef preview)
{
    // implement only if supported
}
