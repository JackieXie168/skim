//
//  SKNPDFAnnotationNote.h
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

#import <Cocoa/Cocoa.h>
#import <Quartz/Quartz.h>

extern NSString *SKNPDFAnnotationTextKey;
extern NSString *SKNPDFAnnotationImageKey;

extern NSSize SKNPDFAnnotationNoteSize;

@interface SKNPDFAnnotationNote : PDFAnnotationText {
    NSString *string;
    NSImage *image;
    NSTextStorage *textStorage;
    NSAttributedString *text;
    NSArray *texts;
}

/*!
    @method     string
    @abstract   This is overridden and different from the contents.
    @discussion (comprehensive description)
    @result     (description)
*/
- (NSString *)string;

/*!
    @method     setString:
    @abstract   This is overridden and different from the contents.  This calls updateContents.
    @discussion (comprehensive description)
*/
- (void)setString:(NSString *)newString;

/*!
    @method     text
    @abstract   The rich text of the annotation.
    @discussion (comprehensive description)
*/
- (NSAttributedString *)text;

/*!
    @method     setText:
    @abstract   Sets the rich text of the annotation.  This calls updateContents.
    @discussion (comprehensive description)
*/
- (void)setText:(NSAttributedString *)newText;

/*!
    @method     image
    @abstract   The image of the annotation.
    @discussion (comprehensive description)
*/
- (NSImage *)image;

/*!
    @method     setImage:
    @abstract   Sets the image of the annotation.
    @discussion (comprehensive description)
*/
- (void)setImage:(NSImage *)newImage;

/*!
    @method     updateContents
    @abstract   Synchronizes the contents of the annotation with the string and text.  This sets the contents to the string and the text.
    @discussion (comprehensive description)
*/
- (void)updateContents;

@end
