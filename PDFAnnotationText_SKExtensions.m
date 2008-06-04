//
//  PDFAnnotationText_SKExtensions.m
//  Skim
//
//  Created by Christiaan Hofman on 6/3/08.
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

#import "PDFAnnotationText_SKExtensions.h"
#import "PDFAnnotation_SKExtensions.h"
#import "SKPDFAnnotationNote.h"
#import "SKFDFParser.h"


unsigned long SKScriptingIconTypeFromIconType(int iconType) {
    switch (iconType) {
        case kPDFTextAnnotationIconComment: return SKScriptingTextAnnotationIconComment;
        case kPDFTextAnnotationIconKey: return SKScriptingTextAnnotationIconKey;
        case kPDFTextAnnotationIconNote: return SKScriptingTextAnnotationIconNote;
        case kPDFTextAnnotationIconHelp: return SKScriptingTextAnnotationIconHelp;
        case kPDFTextAnnotationIconNewParagraph: return SKScriptingTextAnnotationIconNewParagraph;
        case kPDFTextAnnotationIconParagraph: return SKScriptingTextAnnotationIconParagraph;
        case kPDFTextAnnotationIconInsert: return SKScriptingTextAnnotationIconInsert;
        default: return kPDFTextAnnotationIconNote;
    }
}

int SKIconTypeFromScriptingIconType(unsigned long iconType) {
    switch (iconType) {
        case SKScriptingTextAnnotationIconComment: return kPDFTextAnnotationIconComment;
        case SKScriptingTextAnnotationIconKey: return kPDFTextAnnotationIconKey;
        case SKScriptingTextAnnotationIconNote: return kPDFTextAnnotationIconNote;
        case SKScriptingTextAnnotationIconHelp: return kPDFTextAnnotationIconHelp;
        case SKScriptingTextAnnotationIconNewParagraph: return kPDFTextAnnotationIconNewParagraph;
        case SKScriptingTextAnnotationIconParagraph: return kPDFTextAnnotationIconParagraph;
        case SKScriptingTextAnnotationIconInsert: return kPDFTextAnnotationIconInsert;
        default: return kPDFTextAnnotationIconNote;
    }
}


NSString *SKPDFAnnotationIconTypeKey = @"iconType";

NSString *SKPDFAnnotationScriptingIconTypeKey = @"scriptingIconType";

@implementation PDFAnnotationText (SKExtensions)

- (id)initNoteWithProperties:(NSDictionary *)dict{
    if (self = [super initNoteWithProperties:dict]) {
        NSNumber *iconType = [dict objectForKey:SKPDFAnnotationIconTypeKey];
        if ([iconType respondsToSelector:@selector(intValue)])
            [self setIconType:[iconType intValue]];
    }
    return self;
}

- (NSDictionary *)properties{
    NSMutableDictionary *dict = [[[super properties] mutableCopy] autorelease];
    [dict setValue:[NSNumber numberWithInt:[self iconType]] forKey:SKPDFAnnotationIconTypeKey];
    return dict;
}

- (NSString *)fdfString {
    NSMutableString *fdfString = [[[super fdfString] mutableCopy] autorelease];
    [fdfString appendFDFName:SKFDFAnnotationIconTypeKey];
    [fdfString appendFDFName:SKFDFTextAnnotationIconTypeFromPDFTextAnnotationIconType([self iconType])];
    return fdfString;
}

- (BOOL)isMovable { return [self isNote]; }

- (BOOL)isEditable { return [self isNote]; }

- (BOOL)isConvertibleAnnotation { return YES; }

- (NSSet *)keysForValuesToObserveForUndo {
    static NSSet *textKeys = nil;
    if (textKeys == nil) {
        NSMutableSet *mutableKeys = [[super keysForValuesToObserveForUndo] mutableCopy];
        [mutableKeys addObject:SKPDFAnnotationIconTypeKey];
        textKeys = [mutableKeys copy];
        [mutableKeys release];
    }
    return textKeys;
}

#pragma mark Scripting support

+ (NSSet *)customScriptingKeys {
    static NSSet *customTextScriptingKeys = nil;
    if (customTextScriptingKeys == nil) {
        NSMutableSet *customKeys = [[super customScriptingKeys] mutableCopy];
        [customKeys addObject:SKPDFAnnotationScriptingIconTypeKey];
        [customKeys removeObject:SKPDFAnnotationLineWidthKey];
        [customKeys removeObject:SKPDFAnnotationScriptingBorderStyleKey];
        [customKeys removeObject:SKPDFAnnotationDashPatternKey];
        customTextScriptingKeys = [customKeys copy];
        [customKeys release];
    }
    return customTextScriptingKeys;
}

- (unsigned long)scriptingIconType {
    return SKScriptingIconTypeFromIconType([self iconType]);
}

- (void)setScriptingIconType:(unsigned long)type {
    [self setIconType:SKIconTypeFromScriptingIconType(type)];
}

@end
