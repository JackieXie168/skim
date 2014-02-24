/*
 This software is Copyright (c) 2007-2014
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

#import "SKQLConverter.h"
#include <tgmath.h>

static NSString *_noteFontName = @"LucidaHandwriting-Italic";
static const CGFloat _noteIndent = 20.0;
// readable in Cover Flow view, and distinguishable as text in icon view
static const CGFloat _fontSize = 20.0;
static const CGFloat _smallFontSize = 10.0;

NSString *SKQLPDFPathForPDFBundleURL(NSURL *url)
{
    NSString *filePath = [url path];
    NSArray *files = [[NSFileManager defaultManager] subpathsAtPath:filePath];
    NSString *fileName = [[[filePath lastPathComponent] stringByDeletingPathExtension] stringByAppendingPathExtension:@"pdf"];
    NSString *pdfFile = nil;
    
    if ([files containsObject:fileName]) {
        pdfFile = fileName;
    } else {
        NSUInteger idx = [[files valueForKeyPath:@"pathExtension.lowercaseString"] indexOfObject:@"pdf"];
        if (idx != NSNotFound)
            pdfFile = [files objectAtIndex:idx];
    }
    return pdfFile ? [filePath stringByAppendingPathComponent:pdfFile] : nil;
}

static NSAttributedString *imageAttachmentForPath(NSString *path)
{        
    NSFileWrapper *wrapper = [[NSFileWrapper alloc] initWithPath:path];
    [wrapper setPreferredFilename:[path lastPathComponent]];
    
    NSTextAttachment *attachment = [[NSTextAttachment alloc] initWithFileWrapper:wrapper];
    [wrapper release];
    NSAttributedString *attrString = [NSAttributedString attributedStringWithAttachment:attachment];
    [attachment release];
    
    return attrString;
}

static NSString *hexStringWithColor(NSColor *color)
{
    static char hexChars[16] = "0123456789abcdef";
    if ([color alphaComponent] < 1.0)
        color = [[NSColor controlBackgroundColor] blendedColorWithFraction:[color alphaComponent] ofColor:[color colorWithAlphaComponent:1.0]];
    NSInteger red = (NSInteger)round(255 * [color redComponent]);
    NSInteger green = (NSInteger)round(255 * [color greenComponent]);
    NSInteger blue = (NSInteger)round(255 * [color blueComponent]);
    return [NSString stringWithFormat:@"%C%C%C%C%C%C", hexChars[red / 16], hexChars[red % 16], hexChars[green / 16], hexChars[green % 16], hexChars[blue / 16], hexChars[blue % 16]];
}

// Stolen from OmniFoundation; modified to use malloc instead of alloca()
static NSString *HTMLEscapeString(NSString *htmlString)
{
    unichar *ptr, *begin, *end;
    NSMutableString *result;
    NSString *string;
    NSInteger length;
    
#define APPEND_PREVIOUS() \
    string = [[NSString alloc] initWithCharacters:begin length:(ptr - begin)]; \
    [result appendString:string]; \
    [string release]; \
    begin = ptr + 1;
    
    length = [htmlString length];
    ptr = NSZoneMalloc(NULL, length * sizeof(unichar));
    if (!ptr)
        return nil;
    
    // keep a pointer that we can free later
    unichar *originalPtr = ptr;

    end = ptr + length;
    [htmlString getCharacters:ptr];
    result = [NSMutableString stringWithCapacity:length];
    
    begin = ptr;
    while (ptr < end) {
        if (*ptr > 127) {
            APPEND_PREVIOUS();
            [result appendFormat:@"&#%ld;", (long)*ptr];
        } else if (*ptr == '&') {
            APPEND_PREVIOUS();
            [result appendString:@"&amp;"];
        } else if (*ptr == '\"') {
            APPEND_PREVIOUS();
            [result appendString:@"&quot;"];
        } else if (*ptr == '<') {
             APPEND_PREVIOUS();
            [result appendString:@"&lt;"];
        } else if (*ptr == '>') {
            APPEND_PREVIOUS();
            [result appendString:@"&gt;"];
        } else if (*ptr == '\r') {
            APPEND_PREVIOUS();
            if (ptr+1 == end || *(ptr+1) != '\n')
                [result appendString:@"<br />"];
        } else if (*ptr == '\n') {
            APPEND_PREVIOUS();
            [result appendString:@"<br />"];
        }
        ptr++;
    }
    APPEND_PREVIOUS();
    NSZoneFree(NULL, originalPtr);
    return result;
}

@implementation SKQLConverter

+ (NSAttributedString *)attributedStringWithNotes:(NSArray *)notes forThumbnail:(QLThumbnailRequestRef)thumbnail;
{
    NSMutableAttributedString *attrString = [[[NSMutableAttributedString alloc] init] autorelease];
    NSFont *font = [NSFont userFontOfSize:_fontSize];
    NSFont *noteFont = [NSFont fontWithName:_noteFontName size:_fontSize];
    NSFont *noteTextFont = [NSFont fontWithName:_noteFontName size:_smallFontSize];
    NSDictionary *attrs = [NSDictionary dictionaryWithObjectsAndKeys:font, NSFontAttributeName, nil];
    NSDictionary *noteAttrs = [NSDictionary dictionaryWithObjectsAndKeys:noteFont, NSFontAttributeName, [NSParagraphStyle defaultParagraphStyle], NSParagraphStyleAttributeName, nil];
    NSDictionary *noteTextAttrs = [NSDictionary dictionaryWithObjectsAndKeys:noteTextFont, NSFontAttributeName, [NSParagraphStyle defaultParagraphStyle], NSParagraphStyleAttributeName, nil];
    NSMutableParagraphStyle *noteParStyle = [[[NSParagraphStyle defaultParagraphStyle] mutableCopy] autorelease];
    
    [noteParStyle setFirstLineHeadIndent:_noteIndent];
    [noteParStyle setHeadIndent:_noteIndent];
    
    if (notes) {
        CFBundleRef bundle = QLThumbnailRequestGetGeneratorBundle(thumbnail);
        NSSortDescriptor *sortDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"pageIndex" ascending:YES] autorelease];
        NSEnumerator *noteEnum = [[notes sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortDescriptor]] objectEnumerator];
        NSDictionary *note;
        while (note = [noteEnum nextObject]) {
            NSString *type = [note objectForKey:@"type"];
            NSString *contents = [note objectForKey:@"contents"];
            NSString *text = [[note objectForKey:@"text"] string];
            NSColor *color = [note objectForKey:@"color"];
            NSUInteger pageIndex = [[note objectForKey:@"pageIndex"] unsignedIntegerValue];
            NSURL *imgURL = [(NSURL *)CFBundleCopyResourceURL(bundle, (CFStringRef)type, CFSTR("png"), NULL) autorelease];
            NSInteger start;
            
            [attrString appendAttributedString:imageAttachmentForPath([imgURL path])];
            [attrString addAttribute:NSBackgroundColorAttributeName value:color range:NSMakeRange([attrString length] - 1, 1)];
            [attrString appendAttributedString:[[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@ (page %ld)\n", type, (long)(pageIndex+1)] attributes:attrs] autorelease]];
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
    
    return attrString;
}

+ (NSString *)htmlStringWithNotes:(NSArray *)notes;
{
    NSMutableString *htmlString = [NSMutableString string];
    [htmlString appendString:@"<html><head><style type=\"text/css\">"];
    [htmlString appendString:@"body {font-family:Helvetica} "];
    [htmlString appendString:@"dd {font-style:italic} "];
    [htmlString appendString:@".note-text {font-size:smaller} "];
    [htmlString appendString:@"</style></head><body><dl>"];
    
    if (notes) {
        NSSortDescriptor *sortDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"pageIndex" ascending:YES] autorelease];
        NSEnumerator *noteEnum = [[notes sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortDescriptor]] objectEnumerator];
        NSDictionary *note;
        while (note = [noteEnum nextObject]) {
            NSString *type = [note objectForKey:@"type"];
            NSString *contents = [note objectForKey:@"contents"];
            NSString *text = [[note objectForKey:@"text"] string];
            NSColor *color = [note objectForKey:@"color"];
            NSUInteger pageIndex = [[note objectForKey:@"pageIndex"] unsignedIntegerValue];
            [htmlString appendFormat:@"<dt><img src=\"cid:%@.png\" style=\"background-color:#%@\" />%@ (page %ld)</dt>", type, hexStringWithColor(color), type, (long)(pageIndex+1)];
            [htmlString appendFormat:@"<dd>%@", HTMLEscapeString(contents)];
            if (text)
                [htmlString appendFormat:@"<div class=\"note-text\">%@</div>", HTMLEscapeString(text)];
            [htmlString appendString:@"</dd>"];
        }
    }
    
    [htmlString appendString:@"</dl></body></html>"];
    
    return htmlString;
}

@end
