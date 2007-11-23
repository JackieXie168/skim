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

@interface NSAttributedString (SKQLExtensions)
+ (NSAttributedString *)imageAttachmentForType:(NSString *)type;
@end

@implementation NSAttributedString (SKQLExtensions)
+ (NSAttributedString *)imageAttachmentForType:(NSString *)type {
    static NSMutableDictionary *imageAttachments = nil;
    
    NSAttributedString *attrString = nil;
    if (attrString == nil) {
        if (imageAttachments == nil) {
            imageAttachments = [[NSMutableDictionary alloc] init];
        NSBundle *bundle = [NSBundle bundleWithIdentifier:@"net.sourceforge.skim-app.quicklookgenerator"];
        image = [[NSImage alloc] initWithContentsOfFile:[bundle pathForResource:@"Note" ofType:@"png"]];
        [image release];
        NSFileWrapper *wrapper = [[NSFileWrapper alloc] initRegularFileWithContents:[image TIFFRepresentation]];
        [wrapper setPreferredFilename:[NSString stringWithFormat:@"%@.tiff", type]];
        
        NSTextAttachment *attachment = [[NSTextAttachment alloc] initWithFileWrapper:wrapper];
        [wrapper release];
        attrString = [NSAttributedString attributedStringWithAttachment:attachment];
        [imageAttachments setObject:attrString forKey:type];
        [attachment release];
    }
    
    return attrString;
}
@end


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
            NSString *fileName = [[[path stringByDeletingLastPathComponent] stringByDeletingPathExtension] stringByAppendingPathExtension:@"pdf"];
            NSString *pdfFile = nil;
            
            if ([subfiles containsObject:fileName]) {
                pdfFile = fileName;
            } else {
                unsigned int index = [[subfiles valueForKeyPath:@"pathExtension.lowercaseString"] indexOfObject:@"pdf"];
                if (index != NSNotFound)
                    pdfFile = [subfiles objectAtIndex:index];
            }
            if (pdfFile) {
                pdfFile = [filePath stringByAppendingPathComponent:pdfFile];
                CGImageRef image = QLThumbnailImageCreate(kCFAllocatorDefault, (CFURLRef)[NSURL fileURLWithPath:pdfFile], maxSize, options);
                if (image != NULL) {
                    CFDictionaryRef properties = CFDictionaryCreate(NULL, NULL, NULL, 0, NULL, NULL);
                    QLThumbnailRequestSetImage(thumbnail, image, properties);
                    CGImageRelease(image);
                    CFRelease(properties);

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
                NSFont *font = [self userFontOfSize:0.0];
                NSFont *boldFont = [[NSFontManager sharedFontManager] convertFont:font toHaveTrait:NSBoldFontMask];
                NSDictionary *attrs = [NSDictionary dictionaryWithObjectsAndKeys:font, NSFontAttributeName, nil];
                NSDictionary *boldAttrs = [NSDictionary dictionaryWithObjectsAndKeys:boldFont, NSFontAttributeName, [NSParagraphStyle defaultParagraphStyle], NSParagraphStyleAttributeName, nil];
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
                        NSString *color = [note objectForKey:@"color"];
                        unsigned int pageIndex = [[note objectForKey:@"pageIndex"] unsignedIntValue];
                        int start;
                        
                        [attrString appendAttributedString:[NSAttributedString imageAttachmentForType:type]];
                        [attrString addAttribute:NSBackgroundColorAttributeName value:color range:NSMakeRange([attrString length] - 1, 1)];
                        [attrString appendAttributedString:[[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@ (page %i)\n", type, pageIndex+1] attributes:attrs] autorelease]];
                        start = [attrString length];
                        [attrString appendAttributedString:[[[NSAttributedString alloc] initWithString:contents attributes:boldAttrs] autorelease]];
                        if (text) {
                            [attrString appendAttributedString:[[[NSAttributedString alloc] initWithString:@"\n"] autorelease]];
                            [attrString appendAttributedString:[[[NSAttributedString alloc] initWithString:text attributes:attrs] autorelease]];
                        }
                        [attrString appendAttributedString:[[[NSAttributedString alloc] initWithString:@"\n"] autorelease]];
                        [attrString addAttribute:NSParagraphStyleAttributeName value:noteParStyle range:NSMakeRange(start, [attrString length] - start)];
                    }
                    [attrString fixAttributesInRange:NSMakerange(0, [attrString length])];
                }
                
                NSSize paperSize = NSMakeSize(612, 792);
                CGContextRef ctxt = QLThumbnailRequestCreateContext(thumbnail, *(CGSize *)&paperSize, FALSE, NULL);
                NSGraphicsContext *nsContext = [NSGraphicsContext graphicsContextWithGraphicsPort:ctxt flipped:NO];
                [NSGraphicsContext saveGraphicsState];
                [NSGraphicsContext setCurrentContext:nsContext];
                [[NSColor whiteColor] setFill];
                NSRect pageRect = NSMakeRect(0, 0, paperSize.width, paperSize.height);
                NSRectFillUsingOperation(pageRect, NSCompositeSourceOver);
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
