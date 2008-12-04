//
//  SKSnapshotWindowController.h
//  Skim
//
//  Created by Michael McCracken on 12/6/06.
/*
 This software is Copyright (c) 2006-2008
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

@interface SKSnapshotWindowController : NSWindowController {
    IBOutlet SKSnapshotPDFView* pdfView;
    NSImage *thumbnail;
    id delegate;
    NSString *pageLabel;
    BOOL hasWindow;
    BOOL miniaturizing;
    BOOL forceOnTop;
}

- (void)setPdfDocument:(PDFDocument *)pdfDocument scaleFactor:(float)factor goToPageNumber:(int)pageNum rect:(NSRect)rect autoFits:(BOOL)autoFits;
- (void)setPdfDocument:(PDFDocument *)pdfDocument setup:(NSDictionary *)setup;

- (BOOL)isPageVisible:(PDFPage *)page;

- (void)redisplay;

- (id)delegate;
- (void)setDelegate:(id)newDelegate;

- (PDFView *)pdfView;
- (NSImage *)thumbnail;
- (void)setThumbnail:(NSImage *)newThumbnail;

- (unsigned int)pageIndex;
- (NSString *)pageLabel;
- (BOOL)hasWindow;
- (NSDictionary *)pageAndWindow;

- (NSDictionary *)currentSetup;

- (BOOL)forceOnTop;
- (void)setForceOnTop:(BOOL)flag;

- (NSImage *)thumbnailWithSize:(float)size;
- (NSImage *)thumbnailWithSize:(float)size shadowBlurRadius:(float)shadowBlurRadius shadowOffset:(NSSize)shadowOffset;

- (NSAttributedString *)thumbnailAttachmentWithSize:(float)size;
- (NSAttributedString *)thumbnailAttachment;
- (NSAttributedString *)thumbnail512Attachment;
- (NSAttributedString *)thumbnail256Attachment;
- (NSAttributedString *)thumbnail128Attachment;
- (NSAttributedString *)thumbnail64Attachment;
- (NSAttributedString *)thumbnail32Attachment;

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


@interface SKSnapshotWindow : NSWindow {
	IBOutlet SKSnapshotPDFView *pdfView;
}
@end


@interface NSObject (SKSnapshotWindowControllerDelegate)
- (void)snapshotControllerDidFinishSetup:(SKSnapshotWindowController *)controller;
- (void)snapshotControllerWindowWillClose:(SKSnapshotWindowController *)controller;
- (void)snapshotControllerViewDidChange:(SKSnapshotWindowController *)controller;
- (NSRect)snapshotControllerTargetRectForMiniaturize:(SKSnapshotWindowController *)controller;
- (NSRect)snapshotControllerSourceRectForDeminiaturize:(SKSnapshotWindowController *)controller;
@end
