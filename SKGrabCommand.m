//
//  SKGrabCommand.m
//  Skim
//
//  Created by Christiaan Hofman on 11/3/08.
/*
 This software is Copyright (c) 2008
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

#import "SKGrabCommand.h"
#import <Quartz/Quartz.h>
#import "NSData_SKExtensions.h"
#import "PDFPage_SKExtensions.h"


@implementation SKGrabCommand

- (id)performDefaultImplementation {
	NSDictionary *args = [self evaluatedArguments];
    PDFPage *page = [self evaluatedReceivers];
    NSData *boundsData = [args objectForKey:@"Bounds"];
    id asTIFF = [args objectForKey:@"AsTIFF"];
    NSAppleEventDescriptor *desc = nil;
    
    if ([page isKindOfClass:[PDFPage class]]) {
        if ([asTIFF boolValue]) {
            NSImage *pageImage = [page imageForBox:kPDFDisplayBoxMediaBox];
            if (boundsData) {
                NSRect pageBounds = [page boundsForBox:kPDFDisplayBoxMediaBox];
                NSRect bounds = [boundsData rectValueAsQDRect];
                NSRect sourceRect = bounds;
                NSRect targetRect = {NSZeroPoint,sourceRect.size };
                NSImage *image = nil;
                
                sourceRect.origin.x -= NSMinX(pageBounds);
                sourceRect.origin.y -= NSMinY(pageBounds);
                image = [[NSImage alloc] initWithSize:targetRect.size];
                [image lockFocus];
                [pageImage drawInRect:targetRect fromRect:sourceRect operation:NSCompositeCopy fraction:1.0];
                [image unlockFocus];
                pageImage = image;
            }
            desc = [NSAppleEventDescriptor descriptorWithDescriptorType:'TIFF' data:[pageImage TIFFRepresentation]];
        } else {
            NSData *data = nil;
            if (boundsData) {
                if ([boundsData isKindOfClass:[NSData class]] == NO)
                    return nil;
                PDFDocument *pdfDoc = [[PDFDocument alloc] initWithData:[page dataRepresentation]];
                PDFPage *pageCopy = [pdfDoc pageAtIndex:0];
                NSRect bounds = [boundsData rectValueAsQDRect];
                
                if (NSIsEmptyRect(bounds))
                    return nil;
                if (floor(NSAppKitVersionNumber) > NSAppKitVersionNumber10_4) {
                    [pageCopy setBounds:bounds forBox:kPDFDisplayBoxMediaBox];
                    [pageCopy setBounds:NSZeroRect forBox:kPDFDisplayBoxCropBox];
                } else {
                    // setting the media box is buggy on Tiger, see bug # 1928384
                    [pageCopy setBounds:bounds forBox:kPDFDisplayBoxCropBox];
                }
                [pageCopy setBounds:NSZeroRect forBox:kPDFDisplayBoxBleedBox];
                [pageCopy setBounds:NSZeroRect forBox:kPDFDisplayBoxTrimBox];
                [pageCopy setBounds:NSZeroRect forBox:kPDFDisplayBoxArtBox];
                data = [pageCopy dataRepresentation];
                [pdfDoc release];
            } else {
                data = [page dataRepresentation];
            }
            if (data)
                desc = [NSAppleEventDescriptor descriptorWithDescriptorType:'PDF ' data:data];
        }
    }
    
    return desc;
}

@end
