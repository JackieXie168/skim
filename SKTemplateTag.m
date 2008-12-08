//
//  SKTemplateTag.m
//  Skim
//
//  Created by Christiaan Hofman on 10/12/07.
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

#import "SKTemplateTag.h"
#import "SKTemplateParser.h"


@implementation SKTemplateTag
- (SKTemplateTagType)type { return -1; }
@end

#pragma mark -

@implementation SKPlaceholderTemplateTag

- (id)initWithString:(NSString *)aString atStartOfLine:(BOOL)flag {
    if (self = [super init]) {
        string = [aString copy];
        inlineOptions = SKTemplateInlineAtEnd;
        if (flag)
            inlineOptions = SKTemplateInlineAtStart;
    }
    return self;
}

- (void)dealloc {
    [string release];
    [super dealloc];
}

- (NSString *)string {
    return string;
}

- (NSArray *)templateArray {
    return [SKTemplateParser arrayByParsingTemplateString:string inlineOptions:inlineOptions];
}

@end

#pragma mark -

@implementation SKRichPlaceholderTemplateTag

- (id)initWithAttributedString:(NSAttributedString *)anAttributedString atStartOfLine:(BOOL)flag {
    if (self = [super init]) {
        attributedString = [anAttributedString copy];
        inlineOptions = SKTemplateInlineAtEnd;
        if (flag)
            inlineOptions = SKTemplateInlineAtStart;
    }
    return self;
}

- (void)dealloc {
    [attributedString release];
    [super dealloc];
}

- (NSAttributedString *)attributedString {
    return attributedString;
}

- (NSArray *)templateArray {
    return [SKTemplateParser arrayByParsingTemplateAttributedString:attributedString inlineOptions:inlineOptions];
}

@end

#pragma mark -

@implementation SKValueTemplateTag

- (id)initWithKeyPath:(NSString *)aKeyPath {
    if (self = [super init]) {
        keyPath = [aKeyPath copy];
    }
    return self;
}

- (void)dealloc {
    [keyPath release];
    [super dealloc];
}

- (SKTemplateTagType)type { return SKValueTemplateTagType; }

- (NSString *)keyPath {
    return keyPath;
}

@end

#pragma mark -

@implementation SKRichValueTemplateTag

- (id)initWithKeyPath:(NSString *)aKeyPath attributes:(NSDictionary *)anAttributes {
    if (self = [super initWithKeyPath:aKeyPath]) {
        attributes = [anAttributes copy];
    }
    return self;
}

- (void)dealloc {
    [attributes release];
    [super dealloc];
}

- (NSDictionary *)attributes {
    return attributes;
}

@end

#pragma mark -

@implementation SKCollectionTemplateTag

- (id)initWithKeyPath:(NSString *)aKeyPath itemTemplate:(SKPlaceholderTemplateTag *)anItemTemplate separatorTemplate:(SKPlaceholderTemplateTag *)aSeparatorTemplate {
    if (self = [super initWithKeyPath:aKeyPath]) {
        itemPlaceholderTemplate = [anItemTemplate retain];
        separatorPlaceholderTemplate = [aSeparatorTemplate retain];
        itemTemplate = nil;
        separatorTemplate = nil;
    }
    return self;
}

- (void)dealloc {
    [itemPlaceholderTemplate release];
    [separatorPlaceholderTemplate release];
    [itemTemplate release];
    [separatorTemplate release];
    [super dealloc];
}

- (SKTemplateTagType)type { return SKCollectionTemplateTagType; }

- (NSArray *)itemTemplate {
    if (itemTemplate == nil && itemPlaceholderTemplate)
        itemTemplate = [[itemPlaceholderTemplate templateArray] retain];
    return itemTemplate;
}

- (NSArray *)separatorTemplate {
    if (separatorTemplate == nil && separatorPlaceholderTemplate)
        separatorTemplate = [[separatorPlaceholderTemplate templateArray] retain];
    return separatorTemplate;
}

@end

#pragma mark -

@implementation SKRichCollectionTemplateTag

- (id)initWithKeyPath:(NSString *)aKeyPath itemTemplate:(SKRichPlaceholderTemplateTag *)anItemTemplate separatorTemplate:(SKRichPlaceholderTemplateTag *)aSeparatorTemplate {
    if (self = [super initWithKeyPath:aKeyPath]) {
        itemPlaceholderTemplate = [anItemTemplate retain];
        separatorPlaceholderTemplate = [aSeparatorTemplate retain];
        itemTemplate = nil;
        separatorTemplate = nil;
    }
    return self;
}

- (void)dealloc {
    [itemPlaceholderTemplate release];
    [separatorPlaceholderTemplate release];
    [itemTemplate release];
    [separatorTemplate release];
    [super dealloc];
}

- (SKTemplateTagType)type { return SKCollectionTemplateTagType; }

- (NSArray *)itemTemplate {
    if (itemTemplate == nil && itemPlaceholderTemplate)
        itemTemplate = [[itemPlaceholderTemplate templateArray] retain];
    return itemTemplate;
}

- (NSArray *)separatorTemplate {
    if (separatorTemplate == nil && separatorPlaceholderTemplate)
        separatorTemplate = [[separatorPlaceholderTemplate templateArray] retain];
    return separatorTemplate;
}

@end

#pragma mark -

@implementation SKConditionTemplateTag

- (id)initWithKeyPath:(NSString *)aKeyPath matchType:(SKTemplateTagMatchType)aMatchType matchStrings:(NSArray *)aMatchStrings subtemplates:(NSArray *)aSubtemplates {
    if (self = [super initWithKeyPath:aKeyPath]) {
        matchType = aMatchType;
        matchStrings = [aMatchStrings copy];
        subtemplates = [aSubtemplates mutableCopy];
    }
    return self;
}

- (void)dealloc {
    [subtemplates release];
    [matchStrings release];
    [super dealloc];
}

- (SKTemplateTagType)type { return SKConditionTemplateTagType; }

- (SKTemplateTagMatchType)matchType {
    return matchType;
}

- (NSArray *)subtemplates {
    return subtemplates;
}

- (NSArray *)matchStrings {
    return matchStrings;
}

- (NSArray *)subtemplateAtIndex:(unsigned)anIndex {
    id subtemplate = [subtemplates objectAtIndex:anIndex];
    if ([subtemplate isKindOfClass:[NSArray class]] == NO) {
         subtemplate = [subtemplate templateArray];
        [subtemplates replaceObjectAtIndex:anIndex withObject:subtemplate];
    }
    return subtemplate;
}

@end

#pragma mark -

@implementation SKRichConditionTemplateTag

- (NSArray *)subtemplateAtIndex:(unsigned)anIndex {
    id subtemplate = [subtemplates objectAtIndex:anIndex];
    if ([subtemplate isKindOfClass:[NSArray class]] == NO) {
        subtemplate = [subtemplate templateArray];
        [subtemplates replaceObjectAtIndex:anIndex withObject:subtemplate];
    }
    return subtemplate;
}

@end

#pragma mark -

@implementation SKTextTemplateTag

- (id)initWithText:(NSString *)aText {
    if (self = [super init]) {
        text = [aText retain];
    }
    return self;
}

- (void)dealloc {
    [text release];
    [super dealloc];
}

- (SKTemplateTagType)type { return SKTextTemplateTagType; }

- (NSString *)text {
    return text;
}

- (void)setText:(NSString *)newText {
    if (text != newText) {
        [text release];
        text = [newText retain];
    }
}

@end

#pragma mark -

@implementation SKRichTextTemplateTag

- (id)initWithAttributedText:(NSAttributedString *)anAttributedText {
    if (self = [super init]) {
        attributedText = [anAttributedText retain];
    }
    return self;
}

- (void)dealloc {
    [attributedText release];
    [super dealloc];
}

- (SKTemplateTagType)type { return SKTextTemplateTagType; }

- (NSAttributedString *)attributedText {
    return attributedText;
}

- (void)setAttributedText:(NSAttributedString *)newAttributedText {
    if (attributedText != newAttributedText) {
        [attributedText release];
        attributedText = [newAttributedText retain];
    }
}

@end
