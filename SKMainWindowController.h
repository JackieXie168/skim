//
//  SKMainWindowController.h
//  This code is licensed under a BSD license. Please see the file LICENSE for details.
//
//  Created by Michael McCracken on 12/6/06.
//  Copyright 2006 Michael O. McCracken. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "SKStringConstants.h"

typedef enum _SKAnnotationMode {
    SKFreeTextAnnotationMode,
    SKTextAnnotationMode,
    SKCircleAnnotationMode
} SKAnnotationMode;

typedef struct _SKPDFViewState {
	int displayMode;
	BOOL autoScales;
	float scaleFactor;
	BOOL hasHorizontalScroller;
	BOOL hasVerticalScroller;
	BOOL autoHidesScrollers;
} SKPDFViewState;

@class SKPDFView, PDFOutline, SKCollapsibleView, SKNavigationWindow;

@interface SKMainWindowController : NSWindowController {
    IBOutlet SKPDFView          *pdfView;
    IBOutlet NSBox              *pdfContentBox;
    
    IBOutlet NSOutlineView      *outlineView;
    PDFOutline                  *pdfOutline;
    BOOL                        updatingOutlineSelection;
    
    IBOutlet NSDrawer           *notesDrawer;
    
    IBOutlet NSSegmentedControl *backForwardButton;
    IBOutlet NSView             *pageNumberView;
    IBOutlet NSStepper          *pageNumberStepper;
    IBOutlet NSTextField        *pageNumberField;
    IBOutlet NSSegmentedControl *toolModeButton;
    IBOutlet NSSegmentedControl *annotationModeButton;
    IBOutlet NSTextField        *scaleField;
    IBOutlet NSPopUpButton      *displayBoxPopUpButton;
    IBOutlet NSSearchField      *searchField;
    IBOutlet SKCollapsibleView  *searchBox;
    NSMutableDictionary         *toolbarItems;
    
    IBOutlet NSWindow          *choosePageSheet;
    IBOutlet NSTextField       *choosePageField;
    
    NSWindow *mainWindow;
    NSWindow *fullScreenWindow;
    
    SKAnnotationMode annotationMode;
    BOOL isPresentation;
    SKPDFViewState savedState;
    
    IBOutlet NSView *findCustomView;
    IBOutlet NSTableView *tableView;
    NSMutableArray *searchResults;
    IBOutlet NSArrayController *findArrayController;
    IBOutlet NSProgressIndicator *spinner;
    
    BOOL edited;
}

- (IBAction)pickColor:(id)sender;
- (IBAction)changeColor:(id)sender;
- (IBAction)doNewNote:(id)sender;
- (IBAction)createNewNote:(id)sender;
- (IBAction)displaySinglePages:(id)sender;
- (IBAction)displayFacingPages:(id)sender;
- (IBAction)toggleDisplayContinuous:(id)sender;
- (IBAction)toggleDisplayAsBook:(id)sender;
- (IBAction)toggleDisplayPageBreaks:(id)sender;
- (IBAction)displayMediaBox:(id)sender;
- (IBAction)displayCropBox:(id)sender;
- (IBAction)changeDisplayBox:(id)sender;
- (IBAction)doGoToNextPage:(id)sender;
- (IBAction)doGoToPreviousPage:(id)sender;
- (IBAction)doGoToPage:(id)sender;
- (IBAction)dismissChoosePageSheet:(id)sender;
- (IBAction)doGoBack:(id)sender;
- (IBAction)doGoForward:(id)sender;
- (IBAction)goBackOrForward:(id)sender;
- (IBAction)doZoomIn:(id)sender;
- (IBAction)doZoomOut:(id)sender;
- (IBAction)doZoomToActualSize:(id)sender;
- (IBAction)doZoomToFit:(id)sender;
- (IBAction)rotateRight:(id)sender;
- (IBAction)rotateLeft:(id)sender;
- (IBAction)rotateAllRight:(id)sender;
- (IBAction)rotateAllLeft:(id)sender;
- (IBAction)toggleNotesDrawer:(id)sender;
- (IBAction)getInfo:(id)sender;
- (IBAction)search:(id)sender;
- (IBAction)changePageNumber:(id)sender;
- (IBAction)changeScaleFactor:(id)sender;
- (IBAction)changeToolMode:(id)sender;
- (IBAction)changeAnnotationMode:(id)sender;
- (IBAction)enterFullScreen:(id)sender;
- (IBAction)exitFullScreen:(id)sender;
- (IBAction)toggleFullScreen:(id)sender;
- (IBAction)toggleFullScreen:(id)sender;
- (IBAction)enterPresentation:(id)sender;
- (IBAction)togglePresentation:(id)sender;

- (void)showSubWindowAtPageNumber:(int)pageNum location:(NSPoint)locationInPageSpace;
- (void)createNewNoteAtPageNumber:(int)pageNum location:(NSPoint)locationInPageSpace;

- (BOOL)isFullScreen;
- (BOOL)isPresentation;

- (BOOL)autoScales;

- (SKAnnotationMode)annotationMode;
- (void)setAnnotationMode:(SKAnnotationMode)newAnnotationMode;

- (void)updateOutlineSelection;

- (void)setupDocumentNotifications;

- (void)handleChangedHistoryNotification:(NSNotification *)notification;
- (void)handlePageChangedNotification:(NSNotification *)notification;
- (void)handleScaleChangedNotification:(NSNotification *)notification;
- (void)handleToolModeChangedNotification:(NSNotification *)notification;

- (void)setupToolbar;

@end
