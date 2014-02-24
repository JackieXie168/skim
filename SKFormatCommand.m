//
//  SKFormatCommand.m
//  Skim
//
//  Created by Christiaan Hofman on 8/19/09.
/*
 This software is Copyright (c) 2009-2014
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

#import "SKFormatCommand.h"
#import "SKTemplateParser.h"
#import "SKTemplateManager.h"
#import "NSAttributedString_SKExtensions.h"


@implementation SKFormatCommand

- (id)performDefaultImplementation {
    id receiver = [self evaluatedReceivers];
    NSDictionary *args = [self evaluatedArguments];
    id template = [args objectForKey:@"template"];
    id file = [args objectForKey:@"to"];
    NSAttributedString *attrString = nil;
    NSString *string = nil;
    NSDictionary *docAttrs = nil;
    id text = nil;
    
    if (template == nil)
		[self setScriptErrorNumber:NSRequiredArgumentsMissingScriptError]; 
    else if ([template isKindOfClass:[NSString class]])
        string = template;
    else if ([template isKindOfClass:[NSAttributedString class]])
        attrString = template;
    else if ([template isKindOfClass:[NSURL class]] == NO)
		[self setScriptErrorNumber:NSArgumentsWrongScriptError]; 
    else if ([[SKTemplateManager sharedManager] isRichTextTemplateType:[template path]])
        attrString = [[[NSAttributedString alloc] initWithURL:template documentAttributes:&docAttrs] autorelease];
    else
        string = [NSString stringWithContentsOfURL:template encoding:NSUTF8StringEncoding error:NULL];
    
    if (string) {
        text = [SKTemplateParser stringByParsingTemplateString:string usingObject:receiver];
        if (file)
            [text writeToURL:file atomically:YES encoding:NSUTF8StringEncoding error:NULL];
    } else if (attrString) {
        NSAttributedString *attrText = [SKTemplateParser attributedStringByParsingTemplateAttributedString:attrString usingObject:receiver];
        if (attrText) {
            text = [attrText richTextSpecifier];
            if (file) {
                NSMutableDictionary *mutableDocAttrs = [NSMutableDictionary dictionaryWithDictionary:docAttrs];
                NSString *ext = [[[file path] pathExtension] lowercaseString];
                if ([ext isEqualToString:@"rtfd"]) {
                    [mutableDocAttrs setObject:NSRTFDTextDocumentType forKey:NSDocumentTypeDocumentAttribute];
                    [[attrText RTFDFileWrapperFromRange:NSMakeRange(0, [attrText length]) documentAttributes:mutableDocAttrs] writeToFile:[file path] atomically:YES updateFilenames:NO];
                } else {
                    NSString *docType = nil;
                    if ([ext isEqualToString:@"rtf"])
                        docType = NSRTFTextDocumentType;
                    else if ([ext isEqualToString:@"doc"])
                        docType = NSDocFormatTextDocumentType;
                    else if ([ext isEqualToString:@"docx"])
                        docType = NSOfficeOpenXMLTextDocumentType;
                    else if ([ext isEqualToString:@"odt"])
                        docType = NSOpenDocumentTextDocumentType;
                    else if ([ext isEqualToString:@"webarchive"])
                        docType = NSWebArchiveTextDocumentType;
                    if (docType) {
                        [mutableDocAttrs setObject:docType forKey:NSDocumentTypeDocumentAttribute];
                        [[attrText dataFromRange:NSMakeRange(0, [attrText length]) documentAttributes:mutableDocAttrs error:NULL] writeToURL:file atomically:YES];
                    }
                }
            }
        }
    }
    
    return text;
}

@end
