//
//  SKMainWindowController.h


//  This code is licensed under a BSD license. Please see the file LICENSE for details.
//
//  Created by Michael McCracken on 12/6/06.
//  Copyright 2006 Michael O. McCracken. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@class SKPDFView, PDFOutline;

@interface SKMainWindowController : NSWindowController {
    IBOutlet SKPDFView   *pdfView;
    
    IBOutlet NSOutlineView *outlineView;
    PDFOutline             *pdfOutline;
    BOOL                   updatingOutlineSelection;
    
    IBOutlet NSDrawer      *notesDrawer;
    
    IBOutlet NSSegmentedControl *backForwardButton;
    IBOutlet NSView             *pageNumberView;
    IBOutlet NSStepper          *pageNumberStepper;
    IBOutlet NSTextField        *pageNumberField;
    IBOutlet NSSegmentedControl *toolModeButton;
    IBOutlet NSSearchField      *searchField;
    NSMutableDictionary         *toolbarItems;
}

- (IBAction)createNewNote:(id)sender;
- (IBAction)goToNextPage:(id)sender;
- (IBAction)goToPreviousPage:(id)sender;
- (IBAction)goBackOrForward:(id)sender;
- (IBAction)zoomIn:(id)sender;
- (IBAction)zoomOut:(id)sender;
- (IBAction)zoomToActualSize:(id)sender;
- (IBAction)zoomToFit:(id)sender;
- (IBAction)rotateRight:(id)sender;
- (IBAction)rotateLeft:(id)sender;
- (IBAction)rotateAllRight:(id)sender;
- (IBAction)rotateAllLeft:(id)sender;
- (IBAction)fullScreen:(id)sender;
- (IBAction)toggleNotesDrawer:(id)sender;
- (IBAction)getInfo:(id)sender;
- (IBAction)search:(id)sender;
- (IBAction)changePageNumber:(id)sender;
- (IBAction)changeToolMode:(id)sender;

- (void)showSubWindowAtPageNumber:(int)pageNum location:(NSPoint)locationInPageSpace;
- (void)createNewNoteAtPageNumber:(int)pageNum location:(NSPoint)locationInPageSpace;

- (void)updateOutlineSelection;

- (void)setupDocumentNotifications;

- (void)handleChangedHistoryNotification:(NSNotification *)notification;
- (void)handlePageChangedNotification:(NSNotification *)notification;
- (void)handleToolModeChangedNotification:(NSNotification *)notification;

- (void)setupToolbar;

@end
