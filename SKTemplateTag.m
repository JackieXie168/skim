//
//  SKTemplateTag.m
//  Skim
//
//  Created by Christiaan Hofman on 10/12/07.
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

#import "SKTemplateTag.h"
#import "SKTemplateParser.h"


@implementation SKTemplateTag

@dynamic type;

- (SKTemplateTagType)type { return -1; }

@end

#pragma mark -

@implementation SKValueTemplateTag

@synthesize keyPath;

- (id)initWithKeyPath:(NSString *)aKeyPath {
    self = [super init];
    if (self) {
        keyPath = [aKeyPath copy];
    }
    return self;
}

- (void)dealloc {
    SKDESTROY(keyPath);
    [super dealloc];
}

- (SKTemplateTagType)type { return SKValueTemplateTagType; }

@end

#pragma mark -

@implementation SKRichValueTemplateTag

@synthesize attributes;

- (id)initWithKeyPath:(NSString *)aKeyPath attributes:(NSDictionary *)anAttributes {
    self = [super initWithKeyPath:aKeyPath];
    if (self) {
        attributes = [anAttributes copy];
    }
    return self;
}

- (void)dealloc {
    SKDESTROY(attributes);
    [super dealloc];
}

@end

#pragma mark -

@implementation SKCollectionTemplateTag

@dynamic itemTemplate, separatorTemplate;

- (id)initWithKeyPath:(NSString *)aKeyPath itemTemplateString:(NSString *)anItemTemplateString separatorTemplateString:(NSString *)aSeparatorTemplateString {
    self = [super initWithKeyPath:aKeyPath];
    if (self) {
        itemTemplateString = [anItemTemplateString retain];
        separatorTemplateString = [aSeparatorTemplateString retain];
        itemTemplate = nil;
        separatorTemplate = nil;
    }
    return self;
}

- (void)dealloc {
    SKDESTROY(itemTemplateString);
    SKDESTROY(separatorTemplateString);
    SKDESTROY(itemTemplate);
    SKDESTROY(separatorTemplate);
    [super dealloc];
}

- (SKTemplateTagType)type { return SKCollectionTemplateTagType; }

- (NSArray *)itemTemplate {
    if (itemTemplate == nil && itemTemplateString)
        itemTemplate = [[SKTemplateParser arrayByParsingTemplateString:itemTemplateString isSubtemplate:YES] retain];
    return itemTemplate;
}

- (NSArray *)separatorTemplate {
    if (separatorTemplate == nil && separatorTemplateString)
        separatorTemplate = [[SKTemplateParser arrayByParsingTemplateString:separatorTemplateString isSubtemplate:YES] retain];
    return separatorTemplate;
}

@end

#pragma mark -

@implementation SKRichCollectionTemplateTag

@dynamic itemTemplate, separatorTemplate;

- (id)initWithKeyPath:(NSString *)aKeyPath itemTemplateAttributedString:(NSAttributedString *)anItemTemplateAttributedString separatorTemplateAttributedString:(NSAttributedString *)aSeparatorTemplateAttributedString {
    self = [super initWithKeyPath:aKeyPath];
    if (self) {
        itemTemplateAttributedString = [anItemTemplateAttributedString retain];
        separatorTemplateAttributedString = [aSeparatorTemplateAttributedString retain];
        itemTemplate = nil;
        separatorTemplate = nil;
    }
    return self;
}

- (void)dealloc {
    SKDESTROY(itemTemplateAttributedString);
    SKDESTROY(separatorTemplateAttributedString);
    SKDESTROY(itemTemplate);
    SKDESTROY(separatorTemplate);
    [super dealloc];
}

- (SKTemplateTagType)type { return SKCollectionTemplateTagType; }

- (NSArray *)itemTemplate {
    if (itemTemplate == nil && itemTemplateAttributedString)
        itemTemplate = [[SKTemplateParser arrayByParsingTemplateAttributedString:itemTemplateAttributedString isSubtemplate:YES] retain];
    return itemTemplate;
}

- (NSArray *)separatorTemplate {
    if (separatorTemplate == nil && separatorTemplateAttributedString)
        separatorTemplate = [[SKTemplateParser arrayByParsingTemplateAttributedString:separatorTemplateAttributedString isSubtemplate:YES] retain];
    return separatorTemplate;
}

@end

#pragma mark -

@implementation SKConditionTemplateTag

@synthesize matchType, matchStrings;

- (id)initWithKeyPath:(NSString *)aKeyPath matchType:(SKTemplateTagMatchType)aMatchType matchStrings:(NSArray *)aMatchStrings subtemplates:(NSArray *)aSubtemplates {
    self = [super initWithKeyPath:aKeyPath];
    if (self) {
        matchType = aMatchType;
        matchStrings = [aMatchStrings copy];
        subtemplates = [aSubtemplates mutableCopy];
    }
    return self;
}

- (void)dealloc {
    SKDESTROY(subtemplates);
    SKDESTROY(matchStrings);
    [super dealloc];
}

- (SKTemplateTagType)type { return SKConditionTemplateTagType; }

- (NSUInteger)countOfSubtemplates {
    return [subtemplates count];
}

- (NSArray *)objectInSubtemplatesAtIndex:(NSUInteger)anIndex {
    id subtemplate = [subtemplates objectAtIndex:anIndex];
    if ([subtemplate isKindOfClass:[NSArray class]] == NO) {
        subtemplate = [SKTemplateParser arrayByParsingTemplateString:subtemplate isSubtemplate:YES];
        [subtemplates replaceObjectAtIndex:anIndex withObject:subtemplate];
    }
    return subtemplate;
}

@end

#pragma mark -

@implementation SKRichConditionTemplateTag

- (NSArray *)objectInSubtemplatesAtIndex:(NSUInteger)anIndex {
    id subtemplate = [subtemplates objectAtIndex:anIndex];
    if ([subtemplate isKindOfClass:[NSArray class]] == NO) {
        subtemplate = [SKTemplateParser arrayByParsingTemplateAttributedString:subtemplate isSubtemplate:YES];
        [subtemplates replaceObjectAtIndex:anIndex withObject:subtemplate];
    }
    return subtemplate;
}

@end

#pragma mark -

@implementation SKTextTemplateTag

@synthesize text;

- (id)initWithText:(NSString *)aText {
    self = [super init];
    if (self) {
        text = [aText retain];
    }
    return self;
}

- (void)dealloc {
    SKDESTROY(text);
    [super dealloc];
}

- (SKTemplateTagType)type { return SKTextTemplateTagType; }

- (void)appendText:(NSString *)newText {
    [self setText:[text stringByAppendingString:newText]];
}

@end

#pragma mark -

@implementation SKRichTextTemplateTag

@synthesize attributedText;

- (id)initWithAttributedText:(NSAttributedString *)anAttributedText {
    self = [super init];
    if (self) {
        attributedText = [anAttributedText retain];
    }
    return self;
}

- (void)dealloc {
    SKDESTROY(attributedText);
    [super dealloc];
}

- (SKTemplateTagType)type { return SKTextTemplateTagType; }

- (void)appendAttributedText:(NSAttributedString *)newAttributedText {
    NSMutableAttributedString *newAttrText = [attributedText mutableCopy];
    [newAttrText appendAttributedString:newAttributedText];
    [newAttrText fixAttributesInRange:NSMakeRange(0, [newAttrText length])];
    [self setAttributedText:newAttrText];
    [newAttrText release];
}

@end
