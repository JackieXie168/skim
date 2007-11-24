/*
 This software is Copyright (c) 2007
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

@interface NSColor (SKQLExtensions)
- (NSString *)hexString;
@end

@implementation NSColor (SKQLExtensions)
- (NSString *)hexString {
    static char hexChars[16] = "0123456789abcdef";
    NSColor *color = self;
    if ([self alphaComponent] < 1.0)
        color = [[NSColor controlBackgroundColor] blendedColorWithFraction:[self alphaComponent] ofColor:[self colorWithAlphaComponent:1.0]];
    int red = (int)roundf(255 * [color redComponent]);
    int green = (int)roundf(255 * [color greenComponent]);
    int blue = (int)roundf(255 * [color blueComponent]);
    return [NSString stringWithFormat:@"%C%C%C%C%C%C", hexChars[red / 16], hexChars[red % 16], hexChars[green / 16], hexChars[green % 16], hexChars[blue / 16], hexChars[blue % 16]];
}
@end

/* -----------------------------------------------------------------------------
   Generate a preview for file

   This function's job is to create preview for designated file
   ----------------------------------------------------------------------------- */

OSStatus GeneratePreviewForURL(void *thisInterface, QLPreviewRequestRef preview, CFURLRef url, CFStringRef contentTypeUTI, CFDictionaryRef options)
{
    NSAutoreleasePool *pool = [NSAutoreleasePool new];
    
    OSStatus err = noErr;
    
    if (UTTypeEqual(CFSTR("net.sourceforge.skim-app.pdfd"), contentTypeUTI)) {
        
        NSString *filePath = [(NSURL *)url path];
        NSArray *files = [[NSFileManager defaultManager] subpathsAtPath:filePath];
        NSString *fileName = [[[path stringByDeletingLastPathComponent] stringByDeletingPathExtension] stringByAppendingPathExtension:@"pdf"];
        NSString *pdfFile = nil;
        
        if ([subfiles containsObject:fileName]) {
            pdfFile = fileName;
        } else {
            unsigned int index = [[subfiles valueForKeyPath:@"pathExtension.lowercaseString"] indexOfObject:@"pdf"];
            if (index != NSNotFound)
                pdfFile = [subfiles objectAtIndex:index];
        }
        pdfFile = pdfFile ? [filePath stringByAppendingPathComponent:pdfFile] : nil;
        NSData *data = pdfFile ? [NSData dataWithContentsOfFile:pdfFile] : nil;
        if (data) {
            QLPreviewRequestSetDataRepresentation(preview, (CFDataRef)data, kUTTypePDF, (CFDictionaryRef)properties);
        } else {
            err = 2;
        }
        
    } else if (UTTypeEqual(CFSTR("net.sourceforge.skim-app.skimnotes"), contentTypeUTI)) {
        
        NSData *data = [[NSData alloc] initWithContentsOfURL:(NSURL *)url options:NSUncachedRead error:NULL];
        if (data) {
            NSMutableString *htmlString = [[NSMutableString alloc] init];
            NSArray *array = [NSKeyedUnarchiver unarchiveObjectWithData:data];
            [data release];
            
            [htmlString appendString:@"<html><head><style type=\"text/css\">"];
            [htmlString appendString:@"body {font-family:Helvetica} "];
            [htmlString appendString:@"dd {font-family:LucidaHandwriting-Italic, Helvetica;font-style:italic} "];
            [htmlString appendString:@".note-text {font-size:smaller} "];
            [htmlString appendString:@"</style></head><body><dl>"];
            
            if (array) {
                NSSortDescriptor *sortDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"pageIndex" ascending:YES] autorelease];
                NSEnumerator *noteEnum = [[array sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortDescriptor]] objectEnumerator];
                NSDictionary *note;
                while (note = [noteEnum nextObject]) {
                    NSString *type = [note objectForKey:@"type"];
                    NSString *contents = [note objectForKey:@"contents"];
                    NSString *text = [[note objectForKey:@"text"] string];
                    NSColor *color = [note objectForKey:@"color"];
                    unsigned int pageIndex = [[note objectForKey:@"pageIndex"] unsignedIntValue];
                    [htmlString appendFormat:@"<dt><img src=\"cid:%@.png\" style=\"background-color:#\" />%@ (page %i)</dt>", type, [color hexString], type, pageIndex+1];
                    [htmlString appendFormat:@"<dd>%@", contents];
                    if (text)
                        [htmlString appendFormat:@"<div class=\"note-text\">%@</div>", text];
                    [htmlString appendString:@"</dd>"];
                }
            }
            
            [htmlString appendString:@"</dl></body></html>"];
            
            NSMutableDictionary *props = [[NSMutableDictionary alloc] init];
            NSMutableDictionary *attachmentProps = [[NSMutableDictionary alloc] init];
            NSMutableDictionary *imgProps;
            NSBundle *bundle = [NSBundle bundleWithIdentifier:@"net.sourceforge.skim-app.quicklookgenerator"];
            NSImage *image;
            
            imgProps = [[NSMutableDictionary alloc] init];
            image = [NSData dataWithContentsOfFile:[bundle pathForResource:@"FreeText" ofType:@"png"]];
            [imgProps setObject:@"image/png" forKey:(NSString *)kQLPreviewPropertyMIMETypeKey];
            [imgProps setObject:image forKey:(NSString *)kQLPreviewPropertyAttachmentDataKey];
            [attachmentProps setObject:imgProps forKey:@"FreeText.png"];
            [imgProps release];
            
            imgProps = [[NSMutableDictionary alloc] init];
            image = [NSData dataWithContentsOfFile:[bundle pathForResource:@"Note" ofType:@"png"]];
            [imgProps setObject:@"image/png" forKey:(NSString *)kQLPreviewPropertyMIMETypeKey];
            [imgProps setObject:image forKey:(NSString *)kQLPreviewPropertyAttachmentDataKey];
            [attachmentProps setObject:imgProps forKey:@"Note.png"];
            [imgProps release];
            
            imgProps = [[NSMutableDictionary alloc] init];
            image = [NSData dataWithContentsOfFile:[bundle pathForResource:@"Circle" ofType:@"png"]];
            [imgProps setObject:@"image/png" forKey:(NSString *)kQLPreviewPropertyMIMETypeKey];
            [imgProps setObject:image forKey:(NSString *)kQLPreviewPropertyAttachmentDataKey];
            [attachmentProps setObject:imgProps forKey:@"Circle.png"];
            [imgProps release];
            
            imgProps = [[NSMutableDictionary alloc] init];
            image = [NSData dataWithContentsOfFile:[bundle pathForResource:@"Square" ofType:@"png"]];
            [imgProps setObject:@"image/png" forKey:(NSString *)kQLPreviewPropertyMIMETypeKey];
            [imgProps setObject:image forKey:(NSString *)kQLPreviewPropertyAttachmentDataKey];
            [attachmentProps setObject:imgProps forKey:@"Square.png"];
            [imgProps release];
            
            imgProps = [[NSMutableDictionary alloc] init];
            image = [NSData dataWithContentsOfFile:[bundle pathForResource:@"Highlight" ofType:@"png"]];
            [imgProps setObject:@"image/png" forKey:(NSString *)kQLPreviewPropertyMIMETypeKey];
            [imgProps setObject:image forKey:(NSString *)kQLPreviewPropertyAttachmentDataKey];
            [attachmentProps setObject:imgProps forKey:@"Highlight.png"];
            [imgProps release];
            
            imgProps = [[NSMutableDictionary alloc] init];
            image = [NSData dataWithContentsOfFile:[bundle pathForResource:@"Underline" ofType:@"png"]];
            [imgProps setObject:@"image/png" forKey:(NSString *)kQLPreviewPropertyMIMETypeKey];
            [imgProps setObject:image forKey:(NSString *)kQLPreviewPropertyAttachmentDataKey];
            [attachmentProps setObject:imgProps forKey:@"Underline.png"];
            [imgProps release];
            
            imgProps = [[NSMutableDictionary alloc] init];
            image = [NSData dataWithContentsOfFile:[bundle pathForResource:@"StrikeOut" ofType:@"png"]];
            [imgProps setObject:@"image/png" forKey:(NSString *)kQLPreviewPropertyMIMETypeKey];
            [imgProps setObject:image forKey:(NSString *)kQLPreviewPropertyAttachmentDataKey];
            [attachmentProps setObject:imgProps forKey:@"StrikeOut.png"];
            [imgProps release];
            
            imgProps = [[NSMutableDictionary alloc] init];
            image = [NSData dataWithContentsOfFile:[bundle pathForResource:@"Line" ofType:@"png"]];
            [imgProps setObject:@"image/png" forKey:(NSString *)kQLPreviewPropertyMIMETypeKey];
            [imgProps setObject:image forKey:(NSString *)kQLPreviewPropertyAttachmentDataKey];
            [attachmentProps setObject:imgProps forKey:@"Line.png"];
            [imgProps release];
            
            [props setObject:attachmentProps forKey:(NSString *)kQLPreviewPropertyAttachmentsKey];
            [props setObject:@"UTF-8" forKey:(NSString *)kQLPreviewPropertyTextEncodingNameKey];
            [props setObject:@"text/html" forKey:(NSString *)kQLPreviewPropertyMIMETypeKey];            
            
            QLPreviewRequestSetDataRepresentation(preview,(CFDataRef)[htmlString dataUsingEncoding:NSUTF8StringEncoding], kUTTypeHTML, (CFDictionaryRef)props);
            
            [htmlString release];
            [props release];
            
        } else {
            err = 2;
        }
        
static OSStatus hotKeyEventHandler(EventHandlerCallRef inHandlerRef, EventRef inEvent, void* refCon );
    }
    
    [pool release];
    
    return err;
}

void CancelPreviewGeneration(void* thisInterface, QLPreviewRequestRef preview)
{
    // implement only if supported
}
