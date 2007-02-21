//
//  SKSnapshotWindowController.h


//  This code is licensed under a BSD license. Please see the file LICENSE for details.
//
//  Created by Michael McCracken on 12/6/06.
//  Copyright 2006 Michael O. McCracken. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@class PDFView, PDFDocument;

@interface SKSnapshotWindowController : NSWindowController {
    IBOutlet PDFView* pdfView;
    NSImage *thumbnail;
    id delegate;
    BOOL miniaturizing;
}
- (void)setPdfDocument:(PDFDocument *)pdfDocument scaleFactor:(float)factor goToPageNumber:(int)pageNum rect:(NSRect)rect;
- (id)delegate;
- (void)setDelegate:(id)newDelegate;
- (PDFView *)pdfView;
- (NSImage *)thumbnail;
- (void)setThumbnail:(NSImage *)newThumbnail;
- (NSString *)pageLabel;
- (unsigned int)pageIndex;
- (NSImage *)thumbnailWithSize:(float)size shadowBlurRadius:(float)shadowBlurRadius shadowOffset:(NSSize)shadowOffset;
- (void)miniaturize;
- (void)deminiaturize;
- (void)handlePageChangedNotification:(NSNotification *)notification;
- (void)handlePDFViewFrameChangedNotification:(NSNotification *)notification;
- (void)handleViewChangedNotification:(NSNotification *)notification;
@end


@interface SKSnapshotWindow : NSWindow
@end


@interface NSObject (SKSnapshotWindowControllerDelegate)
- (void)snapshotControllerDidFinishSetup:(SKSnapshotWindowController *)controller;
- (void)snapshotControllerWindowWillClose:(SKSnapshotWindowController *)controller;
- (void)snapshotControllerViewDidChange:(SKSnapshotWindowController *)controller;
- (NSRect)snapshotControllerTargetRectForMiniaturize:(SKSnapshotWindowController *)controller;
- (NSRect)snapshotControllerSourceRectForDeminiaturize:(SKSnapshotWindowController *)controller;
@end
