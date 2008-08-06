//
//  NSURL_SKExtensions.m
//  Skim
//
//  Created by Christiaan Hofman on 8/13/07.
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

#import "NSURL_SKExtensions.h"
#import "SKRuntime.h"

NSString *SKWeblocFilePboardType = @"CorePasteboardFlavorType 0x75726C20";

@implementation NSURL (SKExtensions)

static id (*originalInitFileURLWithPath)(id, SEL, id) = NULL;
static id (*originalInitWithString)(id, SEL, id) = NULL;

- (id)replacementInitFileURLWithPath:(NSString *)path {
    return path == nil ? nil : originalInitFileURLWithPath(self, _cmd, path);
}

- (id)replacementInitWithString:(NSString *)URLString {
    return URLString == nil ? nil : originalInitWithString(self, _cmd, URLString);
}

+ (void)load {
    originalInitFileURLWithPath = (id (*)(id, SEL, id))SKReplaceMethodImplementationFromSelector(self, @selector(initFileURLWithPath:), @selector(replacementInitFileURLWithPath:), YES);
    originalInitWithString = (id (*)(id, SEL, id))SKReplaceMethodImplementationFromSelector(self, @selector(initWithString:), @selector(replacementInitWithString:), YES);
}

+ (NSURL *)URLFromPasteboardAnyType:(NSPasteboard *)pasteboard {
    NSString *pboardType = [pasteboard availableTypeFromArray:[NSArray arrayWithObjects:SKWeblocFilePboardType, NSURLPboardType, NSStringPboardType, nil]];
    NSURL *theURL = nil;
    if ([pboardType isEqualToString:NSURLPboardType]) {
        theURL = [NSURL URLFromPasteboard:pasteboard];
    } else if ([pboardType isEqualToString:SKWeblocFilePboardType]) {
        theURL = [NSURL URLWithString:[pasteboard stringForType:SKWeblocFilePboardType]];
    } else if ([pboardType isEqualToString:NSStringPboardType]) {
        NSString *string = [[pasteboard stringForType:NSStringPboardType] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if ([string rangeOfString:@"://"].length) {
            if ([string hasPrefix:@"<"] && [string hasSuffix:@">"])
                string = [string substringWithRange:NSMakeRange(1, [string length] - 2)];
            theURL = [NSURL URLWithString:string];
        }
        if (theURL == nil) {
            if ([string hasPrefix:@"~"])
                string = [string stringByExpandingTildeInPath];
            if ([[NSFileManager defaultManager] fileExistsAtPath:string])
                theURL = [NSURL fileURLWithPath:string];
        }
    }
    return theURL;
}

- (NSAttributedString *)icon {
    NSAttributedString *attrString = nil;
    
    NSString *name = [self isFileURL] ? [self path] : [self relativeString];
    if (name) {
        NSImage *image = [[NSWorkspace sharedWorkspace] iconForFile:name];
        name = [[[name lastPathComponent] stringByDeletingPathExtension] stringByAppendingPathExtension:@"tiff"];
        
        NSFileWrapper *wrapper = [[NSFileWrapper alloc] initRegularFileWithContents:[image TIFFRepresentation]];
        [wrapper setFilename:name];
        [wrapper setPreferredFilename:name];

        NSTextAttachment *attachment = [[NSTextAttachment alloc] initWithFileWrapper:wrapper];
        [wrapper release];
        attrString = [NSAttributedString attributedStringWithAttachment:attachment];
        [attachment release];
    }
    return attrString;
}

- (NSAttributedString *)smallIcon {
    NSAttributedString *attrString = nil;
    
    NSString *name = [self isFileURL] ? [self path] : [self relativeString];
    if (name) {
        NSImage *image = [[NSWorkspace sharedWorkspace] iconForFile:name];
        [image setSize:NSMakeSize(16, 16)];
        name = [[[name lastPathComponent] stringByDeletingPathExtension] stringByAppendingPathExtension:@"tiff"];
        
        NSFileWrapper *wrapper = [[NSFileWrapper alloc] initRegularFileWithContents:[image TIFFRepresentation]];
        [wrapper setFilename:name];
        [wrapper setPreferredFilename:name];

        NSTextAttachment *attachment = [[NSTextAttachment alloc] initWithFileWrapper:wrapper];
        [wrapper release];
        attrString = [NSAttributedString attributedStringWithAttachment:attachment];
        [attachment release];
    }
    return attrString;
}

@end
