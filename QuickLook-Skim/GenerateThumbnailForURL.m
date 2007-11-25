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

#import <AppKit/AppKit.h>
#include <CoreFoundation/CoreFoundation.h>
#include <CoreServices/CoreServices.h>
#include <QuickLook/QuickLook.h>
#import <Foundation/Foundation.h>

static NSAttributedString *imageAttachmentForType(NSString *type)
{        
    NSBundle *bundle = [NSBundle bundleWithIdentifier:@"net.sourceforge.skim-app.quicklookgenerator"];
    NSImage *image = [[NSImage alloc] initWithContentsOfFile:[bundle pathForResource:@"Note" ofType:@"png"]];
    NSFileWrapper *wrapper = [[NSFileWrapper alloc] initRegularFileWithContents:[image TIFFRepresentation]];
    [image release];
    [wrapper setPreferredFilename:[NSString stringWithFormat:@"%@.tiff", type]];
    
    NSTextAttachment *attachment = [[NSTextAttachment alloc] initWithFileWrapper:wrapper];
    [wrapper release];
    NSAttributedString *attrString = [NSAttributedString attributedStringWithAttachment:attachment];
    [attachment release];
    
    return attrString;
}

/* -----------------------------------------------------------------------------
    Generate a thumbnail for file

   This function's job is to create thumbnail for designated file as fast as possible
   ----------------------------------------------------------------------------- */

OSStatus GenerateThumbnailForURL(void *thisInterface, QLThumbnailRequestRef thumbnail, CFURLRef url, CFStringRef contentTypeUTI, CFDictionaryRef options, CGSize maxSize)
{
    NSAutoreleasePool *pool = [NSAutoreleasePool new];
    
    
    // return file icons for tiny sizes; this doesn't seem to be used, though; Finder asks for 108 x 107 icons when I have my desktop icon size set to 48 x 48
    if (maxSize.height > 32) {
        
        if (UTTypeEqual(CFSTR("net.sourceforge.skim-app.pdfd"), contentTypeUTI)) {
            
            NSString *filePath = [(NSURL *)url path];
            NSArray *files = [[NSFileManager defaultManager] subpathsAtPath:filePath];
            NSString *fileName = [[[filePath stringByDeletingLastPathComponent] stringByDeletingPathExtension] stringByAppendingPathExtension:@"pdf"];
            NSString *pdfFile = nil;
            
            if ([files containsObject:fileName]) {
                pdfFile = fileName;
            } else {
                unsigned int index = [[files valueForKeyPath:@"pathExtension.lowercaseString"] indexOfObject:@"pdf"];
                if (index != NSNotFound)
                    pdfFile = [files objectAtIndex:index];
            }
            if (pdfFile) {
                // sadly, we can't use the system's QL generator from inside quicklookd, so we don't get the fancy binder on the left edge
                pdfFile = [filePath stringByAppendingPathComponent:pdfFile];
                CGPDFDocumentRef pdfDoc = CGPDFDocumentCreateWithURL((CFURLRef)[NSURL fileURLWithPath:pdfFile]);
                CGPDFPageRef pdfPage = NULL;
                if (pdfDoc && CGPDFDocumentGetNumberOfPages(pdfDoc) > 0)
                    pdfPage = CGPDFDocumentGetPage(pdfDoc, 1);
                
                BOOL failed = NO;
                if (pdfPage) {
                    CGRect pageRect = CGPDFPageGetBoxRect(pdfPage, kCGPDFCropBox);
                    CGContextRef ctxt = QLThumbnailRequestCreateContext(thumbnail, pageRect.size, FALSE, NULL);
                    CGAffineTransform t = CGPDFPageGetDrawingTransform(pdfPage, kCGPDFCropBox, pageRect, 0, true);
                    CGContextConcatCTM(ctxt, t);
                    CGContextClipToRect(ctxt, pageRect);
                    CGContextDrawPDFPage(ctxt, pdfPage);
                    QLThumbnailRequestFlushContext(thumbnail, ctxt);
                }
                else {
                    failed = YES;
                }
                CGPDFDocumentRelease(pdfDoc);
                if (NO == failed) {
                    // !!! early return
                    [pool release];
                    return noErr;
                }
            }
            
        } else if (UTTypeEqual(CFSTR("net.sourceforge.skim-app.skimnotes"), contentTypeUTI)) {
            
            NSData *data = [[NSData alloc] initWithContentsOfURL:(NSURL *)url options:NSUncachedRead error:NULL];
            if (data) {
                NSArray *array = [NSKeyedUnarchiver unarchiveObjectWithData:data];
                [data release];
                
                NSMutableAttributedString *attrString = [[NSMutableAttributedString alloc] init];
                // large font size for thumbnails
                NSFont *font = [NSFont userFontOfSize:20.0];
                NSFont *noteFont = [NSFont fontWithName:@"LucidaHandwriting-Italic" size:20.0];
                NSFont *noteTextFont = [NSFont fontWithName:@"LucidaHandwriting-Italic" size:10.0];
                NSDictionary *attrs = [NSDictionary dictionaryWithObjectsAndKeys:font, NSFontAttributeName, nil];
                NSDictionary *noteAttrs = [NSDictionary dictionaryWithObjectsAndKeys:noteFont, NSFontAttributeName, [NSParagraphStyle defaultParagraphStyle], NSParagraphStyleAttributeName, nil];
                NSDictionary *noteTextAttrs = [NSDictionary dictionaryWithObjectsAndKeys:noteTextFont, NSFontAttributeName, [NSParagraphStyle defaultParagraphStyle], NSParagraphStyleAttributeName, nil];
                NSMutableParagraphStyle *noteParStyle = [[[NSParagraphStyle defaultParagraphStyle] mutableCopy] autorelease];
                [noteParStyle setFirstLineHeadIndent:20.0];
                [noteParStyle setHeadIndent:20.0];
                 
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
                        int start;
                        
                        [attrString appendAttributedString:imageAttachmentForType(type)];
                        [attrString addAttribute:NSBackgroundColorAttributeName value:color range:NSMakeRange([attrString length] - 1, 1)];
                        [attrString appendAttributedString:[[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@ (page %i)\n", type, pageIndex+1] attributes:attrs] autorelease]];
                        start = [attrString length];
                        [attrString appendAttributedString:[[[NSAttributedString alloc] initWithString:contents attributes:noteAttrs] autorelease]];
                        if (text) {
                            [attrString appendAttributedString:[[[NSAttributedString alloc] initWithString:@"\n"] autorelease]];
                            [attrString appendAttributedString:[[[NSAttributedString alloc] initWithString:text attributes:noteTextAttrs] autorelease]];
                        }
                        [attrString appendAttributedString:[[[NSAttributedString alloc] initWithString:@"\n"] autorelease]];
                        [attrString addAttribute:NSParagraphStyleAttributeName value:noteParStyle range:NSMakeRange(start, [attrString length] - start)];
                    }
                    [attrString fixAttributesInRange:NSMakeRange(0, [attrString length])];
                }
                
                NSBundle *bundle = [NSBundle bundleWithIdentifier:@"net.sourceforge.skim-app.quicklookgenerator"];
                NSImage *skimIcon = [[[NSImage alloc] initWithContentsOfFile:[bundle pathForResource:@"Skim" ofType:@"icns"] autorelease];
                NSRect sourceRect = {NSZeroPoint, [skimIcon size]};
                NSRect targetRect = NSMakeRect(50, 140, 512, 512);
                NSSize paperSize = NSMakeSize(612, 792);
                NSRect pageRect = NSMakeRect(0, 0, paperSize.width, paperSize.height);
                CGContextRef ctxt = QLThumbnailRequestCreateContext(thumbnail, *(CGSize *)&paperSize, FALSE, NULL);
                NSGraphicsContext *nsContext = [NSGraphicsContext graphicsContextWithGraphicsPort:ctxt flipped:NO];
                [NSGraphicsContext saveGraphicsState];
                [NSGraphicsContext setCurrentContext:nsContext];
                [[NSColor whiteColor] setFill];
                NSRectFillUsingOperation(pageRect, NSCompositeSourceOver);
                [skimIcon drawInRect:targetRect fromRect:sourceRect operation:NSCompositeSourceOver fraction:0.5];
                [attrString drawInRect:NSInsetRect(pageRect, 20.0f, 20.0f)];
                QLThumbnailRequestFlushContext(thumbnail, ctxt);
                CGContextRelease(ctxt);
                [attrString release];
                [NSGraphicsContext restoreGraphicsState];
                
                // !!! early return
                [pool release];
                return noErr;
            }
            
        }
    }
    /* fallback case: draw the file icon using Icon Services */
    
    FSRef fileRef;
    OSStatus err;
    if (CFURLGetFSRef(url, &fileRef))
        err = noErr;
    else
        err = fnfErr;
    
    IconRef iconRef;
    CGRect rect = CGRectZero;
    CGFloat side = MIN(maxSize.width, maxSize.height);
    rect.size.width = side;
    rect.size.height = side;
    if (noErr == err)
        err = GetIconRefFromFileInfo(&fileRef, 0, NULL, kFSCatInfoNone, NULL, kIconServicesNormalUsageFlag, &iconRef, NULL);
    if (noErr == err) {
        CGContextRef ctxt = QLThumbnailRequestCreateContext(thumbnail, rect.size, TRUE, NULL);
        err = PlotIconRefInContext(ctxt, &rect, kAlignAbsoluteCenter, kTransformNone, NULL, kPlotIconRefNormalFlags, iconRef);
        CGContextRelease(ctxt);
        ReleaseIconRef(iconRef);
    }
    
    [pool release];
    
    return noErr;
}

void CancelThumbnailGeneration(void* thisInterface, QLThumbnailRequestRef thumbnail)
{
    // implement only if supported
}
