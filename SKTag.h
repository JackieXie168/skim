//
//  SKTag.h
//  Skim
//
//  Created by Christiaan Hofman on 10/12/07.
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

#import <Cocoa/Cocoa.h>

enum {
    SKValueTagType,
    SKCollectionTagType,
    SKConditionTagType,
    SKTextTagType
};

@interface SKTag : NSObject {
}
- (int)type;
@end

#pragma mark -

@interface SKValueTag : SKTag {
    NSString *keyPath;
}

- (id)initWithKeyPath:(NSString *)aKeyPath;

- (NSString *)keyPath;

@end

#pragma mark -

@interface SKRichValueTag : SKValueTag {
    NSDictionary *attributes;
}

- (id)initWithKeyPath:(NSString *)aKeyPath attributes:(NSDictionary *)anAttributes;

- (NSDictionary *)attributes;

@end

#pragma mark -

@interface SKCollectionTag : SKValueTag {
    NSString *itemTemplateString;
    NSString *separatorTemplateString;
    NSMutableArray *itemTemplate;
    NSMutableArray *separatorTemplate;
}

- (id)initWithKeyPath:(NSString *)aKeyPath itemTemplateString:(NSString *)anItemTemplateString separatorTemplateString:(NSString *)aSeparatorTemplateString;

- (NSArray *)itemTemplate;
- (NSArray *)separatorTemplate;

@end

#pragma mark -

@interface SKRichCollectionTag : SKValueTag {
    NSAttributedString *itemTemplateAttributedString;
    NSAttributedString *separatorTemplateAttributedString;
    NSMutableArray *itemTemplate;
    NSMutableArray *separatorTemplate;
}

- (id)initWithKeyPath:(NSString *)aKeyPath itemTemplateAttributedString:(NSAttributedString *)anItemTemplateString separatorTemplateAttributedString:(NSAttributedString *)aSeparatorTemplateString;

- (NSArray *)itemTemplate;
- (NSArray *)separatorTemplate;

@end

#pragma mark -

@interface SKConditionTag : SKValueTag {
    int matchType;
    NSMutableArray *subtemplates;
    NSArray *matchStrings;
}

- (id)initWithKeyPath:(NSString *)aKeyPath matchType:(int)aMatchType matchStrings:(NSArray *)aMatchStrings subtemplates:(NSArray *)aSubtemplates;

- (int)matchType;
- (NSArray *)matchStrings;
- (NSArray *)subtemplates;
- (NSArray *)subtemplateAtIndex:(unsigned)index;

@end

#pragma mark -

@interface SKRichConditionTag : SKConditionTag
@end

#pragma mark -

@interface SKTextTag : SKTag {
    NSString *text;
}

- (id)initWithText:(NSString *)aText;

- (NSString *)text;
- (void)setText:(NSString *)newText;

@end

#pragma mark -

@interface SKRichTextTag : SKTag {
    NSAttributedString *attributedText;
}

- (id)initWithAttributedText:(NSAttributedString *)anAttributedText;

- (NSAttributedString *)attributedText;
- (void)setAttributedText:(NSAttributedString *)newAttributedText;

@end
