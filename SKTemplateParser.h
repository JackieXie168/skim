//
//  SKTemplateParser.h
//  Skim
//
//  Created by Christiaan Hofman on 5/26/07.
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

#import <Cocoa/Cocoa.h>


@interface SKTemplateParser : NSObject

+ (NSString *)stringByParsingTemplateString:(NSString *)templateString usingObject:(id)object;
+ (NSArray *)arrayByParsingTemplateString:(NSString *)templateString;
+ (NSArray *)arrayByParsingTemplateString:(NSString *)templateString isSubtemplate:(BOOL)isSubtemplate;
+ (NSString *)stringFromTemplateArray:(NSArray *)templateArray usingObject:(id)object atIndex:(NSInteger)anIndex;

+ (NSAttributedString *)attributedStringByParsingTemplateAttributedString:(NSAttributedString *)templateAttrString usingObject:(id)object;
+ (NSArray *)arrayByParsingTemplateAttributedString:(NSAttributedString *)templateAttrString;
+ (NSArray *)arrayByParsingTemplateAttributedString:(NSAttributedString *)templateAttrString isSubtemplate:(BOOL)isSubtemplate;
+ (NSAttributedString *)attributedStringFromTemplateArray:(NSArray *)templateArray usingObject:(id)object atIndex:(NSInteger)anIndex;

@end

#pragma mark -

@interface NSObject (SKTemplateParser)

- (BOOL)isNotEmpty;

- (NSString *)templateStringValue;
- (NSAttributedString *)templateAttributedStringValueWithAttributes:(NSDictionary *)attributes;

@end
