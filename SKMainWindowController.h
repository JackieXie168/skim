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
@class SKPDFView, SKOutlineView, SKNoteOutlineView, SKThumbnailTableView, SKSnapshotTableView, SKSplitView, BDSKCollapsibleView, BDSKEdgeView, BDSKImagePopUpButton;
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
    NSMutableArray              *pdfOutlineItems;
    BOOL                        updatingOutlineSelection;
    
    IBOutlet NSObjectController *ownerController;
    IBOutlet NSArrayController  *thumbnailArrayController;
    IBOutlet SKThumbnailTableView *thumbnailTableView;
    IBOutlet NSView             *thumbnailView;
    NSMutableArray              *thumbnails;
    BOOL                        updatingThumbnailSelection;
    float                       roundedThumbnailSize;
    BOOL                        isAnimating;
    
    IBOutlet NSArrayController  *findArrayController;
    IBOutlet NSTableView        *findTableView;
    IBOutlet NSView             *findView;
    IBOutlet BDSKEdgeView       *findEdgeView;
    IBOutlet BDSKCollapsibleView *findCollapsibleView;
    IBOutlet NSProgressIndicator *spinner;
    NSMutableArray              *searchResults;
    BOOL                        findPanelFind;
    CFMutableSetRef             temporaryAnnotations;
    NSTimer                     *findTimer;
    
    IBOutlet NSArrayController  *noteArrayController;
    IBOutlet SKNoteOutlineView  *noteOutlineView;
    IBOutlet NSView             *noteView;
    NSMutableArray              *notes;
    BOOL                        updatingNoteSelection;
    
    IBOutlet NSArrayController  *snapshotArrayController;
    IBOutlet SKSnapshotTableView *snapshotTableView;
    IBOutlet NSView             *snapshotView;
    NSMutableArray              *snapshots;
    NSMutableArray              *dirtySnapshots;
    NSTimer                     *snapshotTimer;
    float                       roundedSnapshotThumbnailSize;
    
    NSWindow                    *mainWindow;
    SKFullScreenWindow          *fullScreenWindow;
    SKSideWindow                *leftSideWindow;
    SKSideWindow                *rightSideWindow;
    NSMutableArray              *blankingWindows;
    
    IBOutlet NSSegmentedControl *backForwardButton;
    IBOutlet NSView             *pageNumberView;
    IBOutlet NSStepper          *pageNumberStepper;
    IBOutlet NSTextField        *pageNumberField;
    IBOutlet NSSegmentedControl *toolModeButton;
    IBOutlet NSTextField        *scaleField;
    IBOutlet NSPopUpButton      *displayBoxPopUpButton;
    IBOutlet BDSKImagePopUpButton *notePopUpButton;
    IBOutlet BDSKImagePopUpButton *circlePopUpButton;
    IBOutlet BDSKImagePopUpButton *markupPopUpButton;
    NSMutableDictionary         *toolbarItems;
    
    IBOutlet NSWindow           *choosePageSheet;
    IBOutlet NSTextField        *choosePageField;
    
    IBOutlet NSWindow           *chooseScaleSheet;
    IBOutlet NSTextField        *chooseScaleField;
    
    IBOutlet NSWindow           *bookmarkSheet;
    IBOutlet NSTextField        *bookmarkField;
    
    IBOutlet NSWindow           *saveProgressSheet;
    IBOutlet NSProgressIndicator *saveProgressBar;
    
    IBOutlet NSWindow           *passwordSheet;
    IBOutlet NSTextField        *passwordField;
    
    NSMutableArray              *lastViewedPages;
    
    NSTimer                     *activityTimer;
    
    BOOL                        isPresentation;
    NSMutableDictionary         *savedNormalSetup;
    
    float                       lastLeftSidePaneWidth;
    float                       lastRightSidePaneWidth;
    
    float                       thumbnailCacheSize;
    float                       snapshotCacheSize;
    
    BOOL                        edited;
}

- (IBAction)pickColor:(id)sender;
- (IBAction)changeColor:(id)sender;
- (IBAction)createNewNote:(id)sender;
- (IBAction)takeSnapshot:(id)sender;
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
- (IBAction)doAutoScale:(id)sender;
- (IBAction)toggleAutoScale:(id)sender;
- (IBAction)toggleAutoActualSize:(id)sender;
- (IBAction)rotateRight:(id)sender;
- (IBAction)rotateLeft:(id)sender;
- (IBAction)rotateAllRight:(id)sender;
- (IBAction)rotateAllLeft:(id)sender;
- (IBAction)crop:(id)sender;
- (IBAction)cropAll:(id)sender;
- (IBAction)autoSelectContent:(id)sender;
- (IBAction)getInfo:(id)sender;
- (void)displaySearchResultsForString:(NSString *)string;
- (IBAction)search:(id)sender;
- (IBAction)changeScaleFactor:(id)sender;
- (IBAction)chooseScale:(id)sender;
- (IBAction)dismissChooseScaleSheet:(id)sender;
- (IBAction)changeToolMode:(id)sender;
- (IBAction)toggleLeftSidePane:(id)sender;
- (IBAction)toggleRightSidePane:(id)sender;
- (IBAction)changeLeftSidePaneState:(id)sender;
- (IBAction)changeRightSidePaneState:(id)sender;
- (IBAction)searchPDF:(id)sender;
- (IBAction)enterFullScreen:(id)sender;
- (IBAction)exitFullScreen:(id)sender;
- (IBAction)toggleFullScreen:(id)sender;
- (IBAction)enterPresentation:(id)sender;
- (IBAction)togglePresentation:(id)sender;
- (IBAction)performFit:(id)sender;
- (IBAction)password:(id)sender;
- (IBAction)dismissPasswordSheet:(id)sender;
- (IBAction)savePDFSettingToDefaults:(id)sender;

- (void)showSnapshotAtPageNumber:(int)pageNum forRect:(NSRect)rect factor:(int)factor;
- (void)toggleSnapshots:(NSArray *)snapshotArray;
- (void)showNote:(PDFAnnotation *)annotation;

- (SKPDFView *)pdfView;

- (PDFDocument *)pdfDocument;
- (void)setPdfDocument:(PDFDocument *)document;

- (NSArray *)notes;
- (void)setNotes:(NSArray *)newNotes;
- (unsigned)countOfNotes;
- (id)objectInNotesAtIndex:(unsigned)index;
- (void)insertObject:(id)obj inNotesAtIndex:(unsigned)index;
- (void)removeObjectFromNotesAtIndex:(unsigned)index;

- (unsigned)countOfThumbnails;
- (id)objectInThumbnailsAtIndex:(unsigned)theIndex;
- (void)insertObject:(id)obj inThumbnailsAtIndex:(unsigned)theIndex;
- (void)removeObjectFromThumbnailsAtIndex:(unsigned)theIndex;

- (NSArray *)snapshots;
- (void)setSnapshots:(NSArray *)newSnapshots;
- (unsigned)countOfSnapshots;
- (id)objectInSnapshotsAtIndex:(unsigned)theIndex;
- (void)insertObject:(id)obj inSnapshotsAtIndex:(unsigned)theIndex;
- (void)removeObjectFromSnapshotsAtIndex:(unsigned)theIndex;

- (PDFAnnotation *)selectedNote;

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
- (void)displaySnapshotView;

- (void)removeTemporaryAnnotations;

- (int)outlineRowForPageIndex:(unsigned int)pageIndex;
- (void)updateOutlineSelection;

- (void)updateNoteSelection;

- (void)updateThumbnailSelection;
- (void)resetThumbnails;
- (void)resetThumbnailSizeIfNeeded;
- (void)updateThumbnailAtPageIndex:(unsigned)index;
- (void)allThumbnailsNeedUpdate;

- (void)resetSnapshotSizeIfNeeded;
- (void)snapshotNeedsUpdate:(SKSnapshotWindowController *)dirstySnapshot;
- (void)allSnapshotsNeedUpdate;
- (void)updateSnapshotsIfNeeded;
- (void)updateSnapshot:(NSTimer *)timer;

- (IBAction)addBookmark:(id)sender;
- (IBAction)dismissBookmarkSheet:(id)sender;

- (void)registerForNotifications;
- (void)registerForDocumentNotifications;
- (void)unregisterForDocumentNotifications;
- (void)registerAsObserver;
- (void)unregisterAsObserver;

- (void)handleApplicationWillTerminateNotification:(NSNotification *)notification;
- (void)handlePageChangedNotification:(NSNotification *)notification;
- (void)handleScaleChangedNotification:(NSNotification *)notification;
- (void)handleToolModeChangedNotification:(NSNotification *)notification;
- (void)handleAnnotationModeChangedNotification:(NSNotification *)notification;
- (void)handleChangedHistoryNotification:(NSNotification *)notification;
- (void)handleDidChangeActiveAnnotationNotification:(NSNotification *)notification;
- (void)handleDidAddAnnotationNotification:(NSNotification *)notification;
- (void)handleDidRemoveAnnotationNotification:(NSNotification *)notification;
- (void)handleDidMoveAnnotationNotification:(NSNotification *)notification;
- (void)handleDoubleClickedAnnotationNotification:(NSNotification *)notification;
- (void)handleAnnotationDidChangeNotification:(NSNotification *)notification;
- (void)handleDocumentBeginWrite:(NSNotification *)notification;
- (void)handleDocumentEndWrite:(NSNotification *)notification;
- (void)handleDocumentEndPageWrite:(NSNotification *)notification;

- (void)addAnnotationsFromDictionaries:(NSArray *)noteDicts;
- (void)setAnnotationsFromDictionaries:(NSArray *)noteDicts;

- (void)setupWindow:(NSDictionary *)setup;
- (NSDictionary *)currentSetup;
- (void)applyPDFSettings:(NSDictionary *)setup;
- (NSDictionary *)currentPDFSettings;

- (void)setupToolbar;

@end
