//
//  SKSnapshotWindowController.h
//  Skim
//
//  Created by Michael McCracken on 12/6/06.
/*
 This software is Copyright (c) 2006-2014
 Michael O. McCracken. All rights reserved.

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:

 - Redistributions of source code must retain the above copyright
   notice, this list of conditions and the following disclaimer.

 - Redistributions in binary form must reproduce the above copyright
    notice, this list of conditions and the following disclaimer in
    the documentation and/or other materials provided with the
    distribution.

 - Neither the name of Michael O. McCracken nor the names of any
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

extern NSString *SKSnapshotCurrentSetupKey;

@class SKSnapshotPDFView, PDFDocument, PDFPage;
@protocol SKSnapshotWindowControllerDelegate;

@interface SKSnapshotWindowController : NSWindowController <NSWindowDelegate> {
    SKSnapshotPDFView* pdfView;
    NSImage *thumbnail;
    id <SKSnapshotWindowControllerDelegate> delegate;
    NSString *pageLabel;
    NSImage *windowImage;
    NSString *string;
    BOOL hasWindow;
    BOOL forceOnTop;
    BOOL animating;
}

@property (nonatomic, retain) IBOutlet SKSnapshotPDFView *pdfView;
@property (nonatomic, assign) id <SKSnapshotWindowControllerDelegate> delegate;
@property (nonatomic, retain) NSImage *thumbnail;
@property (nonatomic, readonly) NSUInteger pageIndex;
@property (nonatomic, readonly, copy) NSString *pageLabel;
@property (nonatomic, copy) NSString *string;
@property (nonatomic, readonly) BOOL hasWindow;
@property (nonatomic, readonly) NSDictionary *pageAndWindow;
@property (nonatomic, readonly) NSDictionary *currentSetup;
@property (nonatomic) BOOL forceOnTop;

@property (nonatomic, readonly) NSAttributedString *thumbnailAttachment, *thumbnail512Attachment, *thumbnail256Attachment, *thumbnail128Attachment, *thumbnail64Attachment, *thumbnail32Attachment;

- (void)setPdfDocument:(PDFDocument *)pdfDocument goToPageNumber:(NSInteger)pageNum rect:(NSRect)rect scaleFactor:(CGFloat)factor autoFits:(BOOL)autoFits;
- (void)setPdfDocument:(PDFDocument *)pdfDocument setup:(NSDictionary *)setup;

- (BOOL)isPageVisible:(PDFPage *)page;

- (void)redisplay;

- (NSImage *)thumbnailWithSize:(CGFloat)size;

- (NSAttributedString *)thumbnailAttachmentWithSize:(CGFloat)size;

- (void)miniaturize;
- (void)deminiaturize;

- (void)handlePageChangedNotification:(NSNotification *)notification;
- (void)handleDocumentDidUnlockNotification:(NSNotification *)notification;
- (void)handlePDFViewFrameChangedNotification:(NSNotification *)notification;
- (void)handleViewChangedNotification:(NSNotification *)notification;
- (void)handleDidAddRemoveAnnotationNotification:(NSNotification *)notification;
- (void)handleDidMoveAnnotationNotification:(NSNotification *)notification;

- (void)setNeedsDisplayInRect:(NSRect)rect ofPage:(PDFPage *)page;
- (void)setNeedsDisplayForAnnotation:(PDFAnnotation *)annotation onPage:(PDFPage *)page;

@end


@protocol SKSnapshotWindowControllerDelegate <NSObject>
@optional

- (void)snapshotControllerDidFinishSetup:(SKSnapshotWindowController *)controller;
- (void)snapshotControllerWillClose:(SKSnapshotWindowController *)controller;
- (void)snapshotControllerDidChange:(SKSnapshotWindowController *)controller;
- (NSRect)snapshotController:(SKSnapshotWindowController *)controller miniaturizedRect:(BOOL)isMiniaturize;

@end
