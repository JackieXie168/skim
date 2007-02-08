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
    SKNoteAnnotationMode,
    SKCircleAnnotationMode,
    SKTextAnnotationMode,
    SKSquareAnnotationMode
} SKAnnotationMode;

typedef enum _SKSidePaneState {
    SKThumbnailSidePaneState,
    SKOutlineSidePaneState
} SKSidePaneState;

typedef struct _SKPDFViewState {
	int displayMode;
	BOOL autoScales;
	float scaleFactor;
	BOOL hasHorizontalScroller;
	BOOL hasVerticalScroller;
	BOOL autoHidesScrollers;
} SKPDFViewState;

extern NSString *SKThumbnailSizeKey;

@class SKPDFView, PDFOutline, SKCollapsibleView, SKNavigationWindow;

@interface SKMainWindowController : NSWindowController {
    IBOutlet SKPDFView          *pdfView;
    IBOutlet NSBox              *pdfContentBox;
    
    IBOutlet NSOutlineView      *outlineView;
    PDFOutline                  *pdfOutline;
    BOOL                        updatingOutlineSelection;
    
    IBOutlet NSSearchField      *findField;
    
    IBOutlet NSDrawer           *notesDrawer;
    IBOutlet NSArrayController  *notesArrayController;
    
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
    
    IBOutlet NSSegmentedControl *sidePaneViewButton;
    
    IBOutlet NSWindow          *choosePageSheet;
    IBOutlet NSTextField       *choosePageField;
    
    NSWindow *mainWindow;
    NSWindow *fullScreenWindow;
    
    SKAnnotationMode annotationMode;
    BOOL isPresentation;
    SKPDFViewState savedState;
    
    IBOutlet NSTableView *currentTableView;
    SKSidePaneState sidePaneState;
    
    IBOutlet NSView *findCustomView;
    IBOutlet NSTableView *findTableView;
    NSMutableArray *searchResults;
    IBOutlet NSArrayController *findArrayController;
    IBOutlet NSProgressIndicator *spinner;
    
    IBOutlet NSView *thumbnailView;
    IBOutlet NSArrayController *thumbnailArrayController;
    IBOutlet NSTableView *thumbnailTableView;
    NSMutableArray *thumbnails;
    BOOL updatingThumbnailSelection;
    NSMutableIndexSet *dirtyThumbnailIndexes;
    NSTimer *thumbnailTimer;
    
    BOOL edited;
}

- (IBAction)pickColor:(id)sender;
- (IBAction)changeColor:(id)sender;
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
- (IBAction)changeSidePaneView:(id)sender;
- (IBAction)enterFullScreen:(id)sender;
- (IBAction)exitFullScreen:(id)sender;
- (IBAction)toggleFullScreen:(id)sender;
- (IBAction)toggleFullScreen:(id)sender;
- (IBAction)enterPresentation:(id)sender;
- (IBAction)togglePresentation:(id)sender;

- (void)showSubWindowAtPageNumber:(int)pageNum location:(NSPoint)locationInPageSpace;
- (void)createNewNoteAtPageNumber:(int)pageNum location:(NSPoint)locationInPageSpace;
- (void)showNote:(PDFAnnotation *)annotation;

- (PDFDocument *)pdfDocument;
- (void)setPdfDocument:(PDFDocument *)document;

- (BOOL)isFullScreen;
- (BOOL)isPresentation;

- (BOOL)autoScales;

- (SKAnnotationMode)annotationMode;
- (void)setAnnotationMode:(SKAnnotationMode)newAnnotationMode;

- (void)displayOutlineView;
- (void)fadeInOutlineView;
- (void)displayThumbnailView;
- (void)fadeInThumbnailView;
- (void)displaySearchView;
- (void)fadeInSearchView;

- (void)removeTemporaryAnnotations;

- (void)updateOutlineSelection;

- (void)updateThumbnailSelection;
- (void)resetThumbnails;
- (void)thumbnailAtIndexNeedsUpdate:(unsigned)index;
- (void)thumbnailsAtIndexesNeedUpdate:(NSIndexSet *)indexes;
- (void)updateThumbnailsIfNeeded;
- (void)updateThumbnail:(NSTimer *)timer;

- (void)registerForNotifications;

- (void)handleAppWillTerminateNotification:(NSNotification *)notification;
- (void)handlePageChangedNotification:(NSNotification *)notification;
- (void)handleScaleChangedNotification:(NSNotification *)notification;
- (void)handleChangedHistoryNotification:(NSNotification *)notification;
- (void)handleToolModeChangedNotification:(NSNotification *)notification;
- (void)handleDidChangeActiveAnnotationNotification:(NSNotification *)notification;
- (void)handleDidRemoveAnnotationNotification:(NSNotification *)notification;
- (void)handleDidChangeAnnotationNotification:(NSNotification *)notification;
- (void)handleDoubleClickedAnnotationNotification:(NSNotification *)notification;

- (void)setAnnotationsFromDictionaries:(NSArray *)noteDicts;

- (void)setupToolbar;

@end
