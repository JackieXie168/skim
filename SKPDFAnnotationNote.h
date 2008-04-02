//
//  SKPDFAnnotationNote.h
//  Skim
//
//  Created by Christiaan Hofman on 2/6/07.
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

#import <Cocoa/Cocoa.h>
#import <Quartz/Quartz.h>


enum {
    SKScriptingTextAnnotationIconComment = 'ICmt',
    SKScriptingTextAnnotationIconKey = 'IKey',
    SKScriptingTextAnnotationIconNote = 'INot',
    SKScriptingTextAnnotationIconHelp = 'IHlp',
    SKScriptingTextAnnotationIconNewParagraph = 'INPa',
    SKScriptingTextAnnotationIconParagraph = 'IPar',
    SKScriptingTextAnnotationIconInsert = 'IIns'
};


extern int SKScriptingIconTypeFromIconType(int iconType);
extern int SKIconTypeFromScriptingIconType(int iconType);


extern NSString *SKPDFAnnotationIconTypeKey;
extern NSString *SKPDFAnnotationTextKey;
extern NSString *SKPDFAnnotationImageKey;

extern NSString *SKPDFAnnotationScriptingIconTypeKey;
extern NSString *SKPDFAnnotationRichTextKey;


@interface PDFAnnotationText (SKLeopardDeprecated)
// these are deprecated on 10.5, but we don't want to use the popup for 10.4 compatibility; we check for existence before using this anyway
- (BOOL)windowIsOpen;
- (void)setWindowIsOpen:(BOOL)isOpen;
@end

#pragma mark -

@interface SKPDFAnnotationNote : PDFAnnotationText {
    NSString *string;
    NSImage *image;
    NSTextStorage *textStorage;
    NSAttributedString *text;
    NSArray *texts;
}

- (void)setImage:(NSImage *)newImage;
- (void)setText:(NSAttributedString *)newText;

- (void)setRichText:(id)newText;

@end

#pragma mark -

@interface SKNoteText : NSObject {
    PDFAnnotation *annotation;
}

- (id)initWithAnnotation:(PDFAnnotation *)anAnnotation;

- (PDFAnnotation *)annotation;

- (NSArray *)texts;

- (NSString *)type;
- (PDFPage *)page;
- (unsigned int)pageIndex;
- (NSAttributedString *)string;

@end
