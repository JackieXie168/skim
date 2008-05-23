//
//  NSDocument_SKExtensions.m
//  Skim
//
//  Created by Christiaan Hofman on 5/23/08.
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

#import "NSDocument_SKExtensions.h"
#import "SKApplicationController.h"
#import "SKTemplateParser.h"

NSString *SKDocumentErrorDomain = @"SKDocumentErrorDomain";

@implementation NSDocument (SKExtensions)

- (NSString *)notesStringUsingTemplateFile:(NSString *)templateFile {
    NSString *templatePath = [[NSApp delegate] pathForApplicationSupportFile:[templateFile stringByDeletingPathExtension] ofType:[templateFile pathExtension] inDirectory:@"Templates"];
    NSError *error = nil;
    NSString *templateString = [[NSString alloc] initWithContentsOfFile:templatePath encoding:NSUTF8StringEncoding error:&error];
    NSString *string = [SKTemplateParser stringByParsingTemplate:templateString usingObject:self];
    [templateString release];
    return string;
}

- (NSData *)notesDataUsingTemplateFile:(NSString *)templateFile {
    static NSSet *richTextTypes = nil;
    if (richTextTypes == nil) {
        if (floor(NSAppKitVersionNumber) > NSAppKitVersionNumber10_4)
            richTextTypes = [[NSSet alloc] initWithObjects:@"rtf", @"doc", @"odt", nil];
        else
            richTextTypes = [[NSSet alloc] initWithObjects:@"rtf", @"doc", nil];
    }
    NSString *fileType = [[templateFile pathExtension] lowercaseString];
    NSData *data = nil;
    if ([richTextTypes containsObject:fileType]) {
        NSString *templatePath = [[NSApp delegate] pathForApplicationSupportFile:[templateFile stringByDeletingPathExtension] ofType:[templateFile pathExtension] inDirectory:@"Templates"];
        NSDictionary *docAttributes = nil;
        NSError *error = nil;
        NSAttributedString *templateAttrString = [[NSAttributedString alloc] initWithPath:templatePath documentAttributes:&docAttributes];
        NSAttributedString *attrString = [SKTemplateParser attributedStringByParsingTemplate:templateAttrString usingObject:self];
        data = [attrString dataFromRange:NSMakeRange(0, [attrString length]) documentAttributes:docAttributes error:&error];
        [templateAttrString release];
    } else if ([fileType caseInsensitiveCompare:@"rtfd"] != NSOrderedSame && [fileType caseInsensitiveCompare:@"odt"] != NSOrderedSame) {
        data = [[self notesStringUsingTemplateFile:templateFile] dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:NO];
    }
    return data;
}

- (NSFileWrapper *)notesFileWrapperUsingTemplateFile:(NSString *)templateFile {
    NSString *templatePath = [[NSApp delegate] pathForApplicationSupportFile:[templateFile stringByDeletingPathExtension] ofType:[templateFile pathExtension] inDirectory:@"Templates"];
    NSDictionary *docAttributes = nil;
    NSAttributedString *templateAttrString = [[NSAttributedString alloc] initWithPath:templatePath documentAttributes:&docAttributes];
    NSAttributedString *attrString = [SKTemplateParser attributedStringByParsingTemplate:templateAttrString usingObject:self];
    NSFileWrapper *fileWrapper = [attrString RTFDFileWrapperFromRange:NSMakeRange(0, [attrString length]) documentAttributes:docAttributes];
    [templateAttrString release];
    return fileWrapper;
}

- (NSString *)notesString {
    return [self notesStringUsingTemplateFile:@"notesTemplate.txt"];
}

- (NSData *)notesRTFData {
    return [self notesDataUsingTemplateFile:@"notesTemplate.rtf"];
}

- (NSFileWrapper *)notesRTFDFileWrapper {
    return [self notesFileWrapperUsingTemplateFile:@"notesTemplate.rtfd"];
}

- (void)saveRecentDocumentInfo {}

@end
