//
//  PDFPage_SKExtensions.h
//  Skim
//
//  Created by Christiaan Hofman on 2/16/07.
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
#import "NSValue_SKExtensions.h"

extern NSString *SKPDFDocumentPageBoundsDidChangeNotification;

@class SKDocument;

@interface PDFPage (SKExtensions)

- (NSRect)foregroundBox;
- (NSImage *)image;
- (NSImage *)imageForBox:(PDFDisplayBox)box;
- (NSImage *)thumbnailWithSize:(float)size forBox:(PDFDisplayBox)box;
- (NSImage *)thumbnailWithSize:(float)size forBox:(PDFDisplayBox)box readingBarRect:(NSRect)readingBarRect;
- (NSImage *)thumbnailWithSize:(float)size forBox:(PDFDisplayBox)box shadowBlurRadius:(float)shadowBlurRadius shadowOffset:(NSSize)shadowOffset readingBarRect:(NSRect)readingBarRect;

- (NSAttributedString *)thumbnailAttachmentWithSize:(float)size;
- (NSAttributedString *)thumbnailAttachment;
- (NSAttributedString *)thumbnail512Attachment;
- (NSAttributedString *)thumbnail256Attachment;
- (NSAttributedString *)thumbnail128Attachment;
- (NSAttributedString *)thumbnail64Attachment;
- (NSAttributedString *)thumbnail32Attachment;

- (NSArray *)lineBounds;

- (unsigned int)pageIndex;

- (NSScriptObjectSpecifier *)objectSpecifier;
- (SKDocument *)containingDocument;
- (unsigned int)index;
- (int)rotationAngle;
- (void)setRotationAngle:(int)angle;
- (NSData *)boundsAsQDRect;
- (void)setBoundsAsQDRect:(NSData *)inQDBoundsAsData;
- (NSData *)mediaBoundsAsQDRect;
- (void)setMediaBoundsAsQDRect:(NSData *)inQDBoundsAsData;
- (NSData *)contentBoundsAsQDRect;
- (id)richText;
- (NSArray *)notes;
- (void)insertInNotes:(id)newNote;
- (void)insertInNotes:(id)newNote atIndex:(unsigned int)index;
- (void)removeFromNotesAtIndex:(unsigned int)index;

@end
