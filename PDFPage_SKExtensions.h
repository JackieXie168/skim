//
//  PDFPage_SKExtensions.h
//  Skim
//
//  Created by Christiaan Hofman on 2/16/07.
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
#import <Quartz/Quartz.h>
#import "NSValue_SKExtensions.h"

extern NSString *SKPDFPageBoundsDidChangeNotification;

extern NSString *SKPDFPagePageKey;
extern NSString *SKPDFPageActionKey;
extern NSString *SKPDFPageActionCrop;
extern NSString *SKPDFPageActionResize;
extern NSString *SKPDFPageActionRotate;

@class SKMainDocument, SKReadingBar;

@interface PDFPage (SKExtensions)

+ (BOOL)usesSequentialPageNumbering;
+ (void)setUsesSequentialPageNumbering:(BOOL)flag;

- (NSRect)foregroundBox;

- (NSImage *)pageImage;
- (NSImage *)thumbnailWithSize:(CGFloat)size forBox:(PDFDisplayBox)box;
- (NSImage *)thumbnailWithSize:(CGFloat)size forBox:(PDFDisplayBox)box readingBar:(SKReadingBar *)readingBar;
- (NSImage *)thumbnailWithSize:(CGFloat)size forBox:(PDFDisplayBox)box shadowBlurRadius:(CGFloat)shadowBlurRadius shadowOffset:(NSSize)shadowOffset readingBar:(SKReadingBar *)readingBar;

- (NSAttributedString *)thumbnailAttachmentWithSize:(CGFloat)size;
- (NSAttributedString *)thumbnailAttachment;
- (NSAttributedString *)thumbnail512Attachment;
- (NSAttributedString *)thumbnail256Attachment;
- (NSAttributedString *)thumbnail128Attachment;
- (NSAttributedString *)thumbnail64Attachment;
- (NSAttributedString *)thumbnail32Attachment;

- (NSData *)PDFDataForRect:(NSRect)rect;
- (NSData *)TIFFDataForRect:(NSRect)rect;

- (NSPointerArray *)lineRects;

- (NSUInteger)pageIndex;
- (NSString *)sequentialLabel;
- (NSString *)displayLabel;

- (BOOL)isEditable;

- (NSAffineTransform *)affineTransformForBox:(PDFDisplayBox)box;

- (NSScriptObjectSpecifier *)objectSpecifier;
- (NSDocument *)containingDocument;
- (NSUInteger)index;
- (NSInteger)rotationAngle;
- (void)setRotationAngle:(NSInteger)angle;
- (NSData *)boundsAsQDRect;
- (void)setBoundsAsQDRect:(NSData *)inQDBoundsAsData;
- (NSData *)mediaBoundsAsQDRect;
- (void)setMediaBoundsAsQDRect:(NSData *)inQDBoundsAsData;
- (NSData *)contentBoundsAsQDRect;
- (NSArray *)lineBoundsAsQDRects;
- (NSTextStorage *)richText;
- (NSArray *)notes;
- (void)insertObject:(id)newNote inNotesAtIndex:(NSUInteger)index;
- (void)removeObjectFromNotesAtIndex:(NSUInteger)index;

- (id)handleGrabScriptCommand:(NSScriptCommand *)command;

@end
