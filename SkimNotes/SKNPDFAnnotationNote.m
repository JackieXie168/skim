//
//  SKNPDFAnnotationNote.m
//  SkimNotes
//
//  Created by Christiaan Hofman on 6/15/08.
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

#import <SkimNotes/SKNPDFAnnotationNote.h>
#import <SkimNotes/PDFAnnotation_SKNExtensions.h>
#import <SkimNotes/PDFAnnotationText_SKNExtensions.h>

NSString *SKNPDFAnnotationTextKey = @"text";
NSString *SKNPDFAnnotationImageKey = @"image";

NSSize SKNPDFAnnotationNoteSize = {16.0, 16.0};


@implementation SKNPDFAnnotationNote

- (void)updateContents {
    NSMutableString *contents = [NSMutableString string];
    if ([string length])
        [contents appendString:string];
    if ([text length]) {
        [contents appendString:@"  "];
        [contents appendString:[text string]];
    }
    [self setContents:contents];
}

- (id)initSkimNoteWithBounds:(NSRect)bounds {
    if (self = [super initSkimNoteWithBounds:bounds]) {
        textStorage = [[NSTextStorage allocWithZone:[self zone]] init];
        [textStorage setDelegate:self];
        text = [[NSAttributedString alloc] init];
    }
    return self;
}

- (id)initSkimNoteWithProperties:(NSDictionary *)dict{
    if (self = [super initSkimNoteWithProperties:dict]) {
        Class attrStringClass = [NSAttributedString class];
        Class stringClass = [NSString class];
        Class imageClass = [NSImage class];
        NSAttributedString *aText = [dict objectForKey:SKNPDFAnnotationTextKey];
        NSImage *anImage = [dict objectForKey:SKNPDFAnnotationImageKey];
        if ([anImage isKindOfClass:imageClass])
            image = [anImage retain];
        if ([aText isKindOfClass:attrStringClass])
            text = [aText copy];
        else if ([aText isKindOfClass:stringClass])
            text = [[NSAttributedString alloc] initWithString:(NSString *)aText];
        [self updateContents];
    }
    return self;
}

- (void)dealloc {
    [textStorage release];
    [text release];
    [image release];
    [texts release];
    [super dealloc];
}

- (NSDictionary *)properties{
    NSMutableDictionary *dict = [[[super properties] mutableCopy] autorelease];
    [dict setValue:[self text] forKey:SKNPDFAnnotationTextKey];
    [dict setValue:[self image] forKey:SKNPDFAnnotationImageKey];
    return dict;
}

- (NSString *)type {
    return SKNNoteString;
}

- (NSString *)string {
    return string;
}

- (void)setString:(NSString *)newString {
    if (string != newString) {
        [string release];
        string = [newString retain];
        [self updateContents];
    }
}

- (NSImage *)image {
    return image;
}

- (void)setImage:(NSImage *)newImage {
    if (image != newImage) {
        [image release];
        image = [newImage retain];
    }
}

+ (BOOL)automaticallyNotifiesObserversForKey:(NSString *)key {
    if ([key isEqualToString:SKNPDFAnnotationTextKey])
        return NO;
    else
        return [super automaticallyNotifiesObserversForKey:key];
}

- (NSAttributedString *)text {
    return text;
}

- (void)setText:(NSAttributedString *)newText {
    if (textStorage != newText) {
        if (newText)
            [textStorage replaceCharactersInRange:NSMakeRange(0, [textStorage length]) withAttributedString:newText];
        else
            [textStorage deleteCharactersInRange:NSMakeRange(0, [textStorage length])];
    }
}

- (void)textStorageDidProcessEditing:(NSNotification *)notification;
{
    [texts makeObjectsPerformSelector:@selector(willChangeValueForKey:) withObject:SKNPDFAnnotationTextKey];
    [self willChangeValueForKey:SKNPDFAnnotationTextKey];
    [text release];
    text = [[NSAttributedString allocWithZone:[self zone]] initWithAttributedString:textStorage];
    [self didChangeValueForKey:SKNPDFAnnotationTextKey];
    [texts makeObjectsPerformSelector:@selector(didChangeValueForKey:) withObject:SKNPDFAnnotationTextKey];
    [self updateContents];
}

@end
