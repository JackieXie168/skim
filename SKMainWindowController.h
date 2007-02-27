//
//  SKMainWindowController.h
//  Skim
//
//  Created by Michael McCracken on 12/6/06.
/*
 This software is Copyright (c) 2006,2007
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

typedef enum _SKLeftSidePaneState {
    SKThumbnailSidePaneState,
    SKOutlineSidePaneState
} SKLeftSidePaneState;

typedef enum _SKRightSidePaneState {
    SKNoteSidePaneState,
    SKSnapshotSidePaneState
} SKRightSidePaneState;

typedef struct _SKPDFViewState {
	int displayMode;
	BOOL autoScales;
	float scaleFactor;
	BOOL hasHorizontalScroller;
	BOOL hasVerticalScroller;
	BOOL autoHidesScrollers;
} SKPDFViewState;

@class PDFOutline, SKThumbnail;
@class SKPDFView, SKOutlineView, SKNoteOutlineView, SKThumbnailTableView, SKSnapshotTableView, SKSplitView, BDSKCollapsibleView, BDSKEdgeView;
@class SKFullScreenWindow, SKNavigationWindow, SKSideWindow, SKSnapshotWindowController;

@interface SKMainWindowController : NSWindowController {
    IBOutlet SKSplitView        *splitView;
    
    IBOutlet SKPDFView          *pdfView;
    IBOutlet BDSKEdgeView       *pdfContentBox;
    
    IBOutlet NSBox              *leftSideContentBox;
    IBOutlet NSBox              *leftSideBox;
    IBOutlet BDSKEdgeView       *leftSideEdgeView;
    IBOutlet BDSKCollapsibleView *leftSideCollapsibleView;
    IBOutlet NSSegmentedControl *leftSideButton;
    IBOutlet NSSearchField      *searchField;
    
    IBOutlet NSBox              *rightSideContentBox;
    IBOutlet NSBox              *rightSideBox;
    IBOutlet BDSKEdgeView       *rightSideEdgeView;
    IBOutlet NSSegmentedControl *rightSideButton;
    
    IBOutlet NSView             *currentLeftSideView;
    IBOutlet NSView             *currentRightSideView;
    SKLeftSidePaneState         leftSidePaneState;
    SKRightSidePaneState        rightSidePaneState;
    
    IBOutlet NSOutlineView      *outlineView;
    IBOutlet NSView             *tocView;
    PDFOutline                  *pdfOutline;
    BOOL                        updatingOutlineSelection;
    
    IBOutlet NSArrayController  *thumbnailArrayController;
    IBOutlet SKThumbnailTableView *thumbnailTableView;
    IBOutlet NSView             *thumbnailView;
    NSMutableArray              *thumbnails;
    BOOL                        updatingThumbnailSelection;
    NSMutableArray              *dirtyThumbnails;
    NSTimer                     *thumbnailTimer;
    
    IBOutlet NSArrayController  *findArrayController;
    IBOutlet NSTableView        *findTableView;
    IBOutlet NSView             *findView;
    IBOutlet BDSKEdgeView       *findEdgeView;
    IBOutlet BDSKCollapsibleView *findCollapsibleView;
    IBOutlet NSProgressIndicator *spinner;
    NSMutableArray              *searchResults;
    BOOL                        findPanelFind;
    
    IBOutlet NSArrayController  *noteArrayController;
    IBOutlet NSTreeController   *noteTreeController;
    IBOutlet SKNoteOutlineView  *noteOutlineView;
    IBOutlet NSView             *noteView;
    BOOL                        updatingNoteSelection;
    NSArray                     *selectedNoteIndexPaths;
    PDFAnnotation               *selectedNote;
    
    IBOutlet NSArrayController  *snapshotArrayController;
    IBOutlet SKSnapshotTableView *snapshotTableView;
    IBOutlet NSView             *snapshotView;
    NSMutableArray              *snapshots;
    NSMutableArray              *dirtySnapshots;
    NSTimer                     *snapshotTimer;
    
    NSWindow                    *mainWindow;
    SKFullScreenWindow          *fullScreenWindow;
    SKSideWindow                *leftSideWindow;
    SKSideWindow                *rightSideWindow;
    
    IBOutlet NSSegmentedControl *backForwardButton;
    IBOutlet NSView             *pageNumberView;
    IBOutlet NSStepper          *pageNumberStepper;
    IBOutlet NSTextField        *pageNumberField;
    IBOutlet NSSegmentedControl *toolModeButton;
    IBOutlet NSSegmentedControl *annotationModeButton;
    IBOutlet NSTextField        *scaleField;
    IBOutlet NSPopUpButton      *displayBoxPopUpButton;
    NSMutableDictionary         *toolbarItems;
    
    IBOutlet NSWindow           *choosePageSheet;
    IBOutlet NSTextField        *choosePageField;
    
    IBOutlet NSWindow           *chooseScaleSheet;
    IBOutlet NSTextField        *chooseScaleField;
    
    IBOutlet NSWindow           *saveProgressSheet;
    IBOutlet NSProgressIndicator *saveProgressBar;
    
    NSMutableArray              *lastViewedPages;
    
    BOOL                        isPresentation;
    SKPDFViewState              savedState;
    
    float                       lastLeftSidePaneWidth;
    float                       lastRightSidePaneWidth;
    
    float                       thumbnailCacheSize;
    float                       snapshotCacheSize;
    
    BOOL                        edited;
}

- (IBAction)pickColor:(id)sender;
- (IBAction)changeColor:(id)sender;
- (IBAction)createNewNote:(id)sender;
- (IBAction)displaySinglePages:(id)sender;
- (IBAction)displayFacingPages:(id)sender;
- (IBAction)toggleDisplayContinuous:(id)sender;
- (IBAction)toggleDisplayAsBook:(id)sender;
- (IBAction)toggleDisplayPageBreaks:(id)sender;
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
- (IBAction)toggleZoomToFit:(id)sender;
- (IBAction)rotateRight:(id)sender;
- (IBAction)rotateLeft:(id)sender;
- (IBAction)rotateAllRight:(id)sender;
- (IBAction)rotateAllLeft:(id)sender;
- (IBAction)getInfo:(id)sender;
- (IBAction)search:(id)sender;
- (IBAction)changeScaleFactor:(id)sender;
- (IBAction)chooseScale:(id)sender;
- (IBAction)dismissChooseScaleSheet:(id)sender;
- (IBAction)changeToolMode:(id)sender;
- (IBAction)changeAnnotationMode:(id)sender;
- (IBAction)toggleLeftSidePane:(id)sender;
- (IBAction)toggleRightSidePane:(id)sender;
- (IBAction)changeLeftSidePaneState:(id)sender;
- (IBAction)changeRightSidePaneState:(id)sender;
- (IBAction)enterFullScreen:(id)sender;
- (IBAction)exitFullScreen:(id)sender;
- (IBAction)toggleFullScreen:(id)sender;
- (IBAction)toggleFullScreen:(id)sender;
- (IBAction)enterPresentation:(id)sender;
- (IBAction)togglePresentation:(id)sender;

- (void)showSnapshotAtPageNumber:(int)pageNum forRect:(NSRect)rect factor:(int)factor;
- (void)toggleSnapshots:(NSArray *)snapshotArray;
- (void)showNote:(PDFAnnotation *)annotation;

- (PDFView *)pdfView;

- (PDFDocument *)pdfDocument;
- (void)setPdfDocument:(PDFDocument *)document;

- (unsigned int)pageNumber;
- (void)setPageNumber:(unsigned int)pageNumber;

- (BOOL)isFullScreen;
- (BOOL)isPresentation;

- (BOOL)autoScales;

- (SKLeftSidePaneState)leftSidePaneState;
- (void)setLeftSidePaneState:(SKLeftSidePaneState)newLeftSidePaneState;
- (SKRightSidePaneState)rightSidePaneState;
- (void)setRightSidePaneState:(SKRightSidePaneState)newRightSidePaneState;

- (void)displayOutlineView;
- (void)fadeInOutlineView;
- (void)displayThumbnailView;
- (void)fadeInThumbnailView;
- (void)displaySearchView;
- (void)fadeInSearchView;
- (void)displayNoteView;
- (void)fadeInNoteView;
- (void)displaySnapshotView;
- (void)fadeInSnapshotView;

- (void)removeTemporaryAnnotations;

- (int)outlineRowForPageIndex:(unsigned int)pageIndex;
- (void)updateOutlineSelection;

- (void)updateNoteSelection;

- (void)updateThumbnailSelection;
- (void)resetThumbnails;
- (void)resetThumbnailSizeIfNeeded;
- (void)thumbnailNeedsUpdate:(SKThumbnail *)dirtyThumbnail;
- (void)allThumbnailsNeedUpdate;
- (void)updateThumbnailsIfNeeded;
- (void)updateThumbnail:(NSTimer *)timer;

- (void)resetSnapshotSizeIfNeeded;
- (void)snapshotNeedsUpdate:(SKSnapshotWindowController *)dirstySnapshot;
- (void)allSnapshotsNeedUpdate;
- (void)updateSnapshotsIfNeeded;
- (void)updateSnapshot:(NSTimer *)timer;

- (void)registerForNotifications;
- (void)registerForDocumentNotifications;
- (void)unregisterForDocumentNotifications;
- (void)registerAsObserver;
- (void)unregisterForChangeNotification;

- (void)handleApplicationWillTerminateNotification:(NSNotification *)notification;
- (void)handleApplicationWillResignActiveNotification:(NSNotification *)notification;
- (void)handlePageChangedNotification:(NSNotification *)notification;
- (void)handleScaleChangedNotification:(NSNotification *)notification;
- (void)handleChangedHistoryNotification:(NSNotification *)notification;
- (void)handleDidChangeActiveAnnotationNotification:(NSNotification *)notification;
- (void)handleDidAddAnnotationNotification:(NSNotification *)notification;
- (void)handleDidRemoveAnnotationNotification:(NSNotification *)notification;
- (void)handleDoubleClickedAnnotationNotification:(NSNotification *)notification;
- (void)handleAnnotationDidChangeNotification:(NSNotification *)notification;
- (void)handleDocumentBeginWrite:(NSNotification *)notification;
- (void)handleDocumentEndWrite:(NSNotification *)notification;
- (void)handleDocumentEndPageWrite:(NSNotification *)notification;

- (void)setAnnotationsFromDictionaries:(NSArray *)noteDicts;

- (void)setupWindow:(NSDictionary *)setup;
- (NSDictionary *)currentSetup;

- (void)setupToolbar;

@end
