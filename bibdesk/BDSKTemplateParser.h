//
//  BDSKTemplateParser.h
//  Bibdesk
//
//  Created by Christiaan Hofman on 5/17/06.
/*
 This software is Copyright (c) 2006,2007
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

#import <Cocoa/Cocoa.h>


@protocol BDSKTemplateParserDelegate

- (void)templateParserWillParseTemplate:(id)template usingObject:(id)object isAttributed:(BOOL)flag;
- (void)templateParserDidParseTemplate:(id)template usingObject:(id)object isAttributed:(BOOL)flag;

@end


/*!
@class BDSKTemplateParser
@abstract A parser class for parsing string and attributed string templates
@discussion This class provides class methods to parse a template, either a string or an attributed string. 
It replaces certain template tags by values obtained using KVC from an object. 
The template tag can be a single tag of the form "<$key/>", for which the value obtained using KVC is substituted. 
For attributed strings the attributes from the first character of the tag are added to the parsed value. 
Alternatively, the tag can be a pair of start/end tags like "<$key>item template</$key>", 
where the value obtained using KVC should be a collection, i.e. respond to objectEnumerator.
The content of the tag ("item template") is parsed for each item in the collection. 
Spaces up to a line break before and after a start or end tag are ignored, as well as the line break after it. 
The delegate is send a message before and after an item in a collection is used for parsing. 
The keys should be valid key paths (i.e. only letters and dots) and spaces are not allowed in the tags. 
*/
@interface BDSKTemplateParser : NSObject

+ (NSString *)stringByParsingTemplate:(NSString *)template usingObject:(id)object;
+ (NSString *)stringByParsingTemplate:(NSString *)template usingObject:(id)object delegate:(id <BDSKTemplateParserDelegate>)delegate;
+ (NSAttributedString *)attributedStringByParsingTemplate:(NSAttributedString *)template usingObject:(id)object;
+ (NSAttributedString *)attributedStringByParsingTemplate:(NSAttributedString *)template usingObject:(id)object delegate:(id <BDSKTemplateParserDelegate>)delegate;

@end


@interface NSObject (BDSKTemplateParser)
- (NSString *)stringDescription;
- (BOOL)isNotEmpty;
@end


@interface NSScanner (BDSKTemplateParser)
- (BOOL)scanEmptyLine;
@end
