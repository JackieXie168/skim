//
//  SKMainWindowController.h
//  Skim
//
//  Created by Michael McCracken on 12/6/06.
/*
 This software is Copyright (c) 2006-2009
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

enum {
    SKThumbnailSidePaneState,
    SKOutlineSidePaneState
};
typedef NSInteger SKLeftSidePaneState;

enum {
    SKNoteSidePaneState,
    SKSnapshotSidePaneState
};
typedef NSInteger SKRightSidePaneState;

enum {
    SKSingularFindPaneState,
    SKGroupedFindPaneState
};
typedef NSInteger SKFindPaneState;

enum {
    SKDefaultWindowOption,
    SKMaximizeWindowOption,
    SKFitWindowOption
};

extern NSString *SKUnarchiveFromDataArrayTransformerName;

@class PDFAnnotation, SKPDFOutline, PDFSelection, SKThumbnail, SKGroupedSearchResult;
@class SKPDFView, SKSecondaryPDFView, SKTocOutlineView, SKNoteOutlineView, SKThumbnailTableView, SKSplitView, BDSKCollapsibleView, BDSKEdgeView, BDSKGradientView, SKColorSwatch, SKStatusBar;
@class SKFullScreenWindow, SKNavigationWindow, SKSideWindow, SKSnapshotWindowController, SKProgressController, SKPageSheetController, SKScaleSheetController, SKPasswordSheetController, SKBookmarkSheetController;

@interface SKMainWindowController : NSWindowController {
    IBOutlet SKSplitView            *splitView;
    
    IBOutlet NSView                 *pdfContentView;
    IBOutlet SKSplitView            *pdfSplitView;
    IBOutlet BDSKEdgeView           *pdfEdgeView;
    IBOutlet SKPDFView              *pdfView;
    
    BDSKEdgeView                    *secondaryPdfEdgeView;
    SKSecondaryPDFView              *secondaryPdfView;
    
    IBOutlet NSView                 *leftSideContentView;
    IBOutlet NSView                 *leftSideView;
    IBOutlet BDSKEdgeView           *leftSideEdgeView;
    IBOutlet BDSKCollapsibleView    *leftSideCollapsibleView;
    IBOutlet BDSKGradientView       *leftSideGradientView;
    IBOutlet NSSegmentedControl     *leftSideButton;
    IBOutlet NSSearchField          *searchField;
    
    IBOutlet NSView                 *rightSideContentView;
    IBOutlet NSView                 *rightSideView;
    IBOutlet BDSKEdgeView           *rightSideEdgeView;
    IBOutlet BDSKCollapsibleView    *rightSideCollapsibleView;
    IBOutlet BDSKGradientView       *rightSideGradientView;
    IBOutlet NSSegmentedControl     *rightSideButton;
    IBOutlet NSSearchField          *noteSearchField;
    
    IBOutlet NSView                 *currentLeftSideView;
    IBOutlet NSView                 *currentRightSideView;
    
    SKStatusBar                     *statusBar;
    
    IBOutlet SKTocOutlineView       *outlineView;
    IBOutlet NSView                 *tocView;
    SKPDFOutline                    *pdfOutline;
    
    IBOutlet NSObjectController     *ownerController;
    IBOutlet NSArrayController      *thumbnailArrayController;
    IBOutlet SKThumbnailTableView   *thumbnailTableView;
    IBOutlet NSView                 *thumbnailView;
    NSMutableArray                  *thumbnails;
    CGFloat                         roundedThumbnailSize;
    
    IBOutlet NSArrayController      *findArrayController;
    IBOutlet NSTableView            *findTableView;
    IBOutlet NSView                 *findView;
    NSMutableArray                  *searchResults;
    CFMutableSetRef                 temporaryAnnotations;
    NSTimer                         *temporaryAnnotationTimer;
    NSTimer                         *highlightTimer;
    
    IBOutlet NSArrayController      *groupedFindArrayController;
    IBOutlet NSTableView            *groupedFindTableView;
    IBOutlet NSView                 *groupedFindView;
    NSMutableArray                  *groupedSearchResults;
    IBOutlet NSSegmentedControl     *findButton;
    
    IBOutlet NSArrayController      *noteArrayController;
    IBOutlet SKNoteOutlineView      *noteOutlineView;
    IBOutlet NSView                 *noteView;
    NSMutableArray                  *notes;
    CFMutableDictionaryRef          rowHeights;
    
    IBOutlet NSArrayController      *snapshotArrayController;
    IBOutlet SKThumbnailTableView   *snapshotTableView;
    IBOutlet NSView                 *snapshotView;
    NSMutableArray                  *snapshots;
    NSMutableArray                  *dirtySnapshots;
    NSTimer                         *snapshotTimer;
    CGFloat                         roundedSnapshotThumbnailSize;
    
    NSMutableArray                  *tags;
    double                          rating;
    
    NSWindow                        *mainWindow;
    SKFullScreenWindow              *fullScreenWindow;
    SKSideWindow                    *leftSideWindow;
    SKSideWindow                    *rightSideWindow;
    NSMutableArray                  *blankingWindows;
    
    IBOutlet NSSegmentedControl     *backForwardButton;
    IBOutlet NSTextField            *pageNumberField;
    IBOutlet NSSegmentedControl     *previousNextPageButton;
    IBOutlet NSSegmentedControl     *previousPageButton;
    IBOutlet NSSegmentedControl     *nextPageButton;
    IBOutlet NSSegmentedControl     *previousNextFirstLastPageButton;
    IBOutlet NSSegmentedControl     *zoomInOutButton;
    IBOutlet NSSegmentedControl     *zoomInActualOutButton;
    IBOutlet NSSegmentedControl     *zoomActualButton;
    IBOutlet NSSegmentedControl     *zoomFitButton;
    IBOutlet NSSegmentedControl     *zoomSelectionButton;
    IBOutlet NSSegmentedControl     *rotateLeftButton;
    IBOutlet NSSegmentedControl     *rotateRightButton;
    IBOutlet NSSegmentedControl     *rotateLeftRightButton;
    IBOutlet NSSegmentedControl     *cropButton;
    IBOutlet NSSegmentedControl     *fullScreenButton;
    IBOutlet NSSegmentedControl     *presentationButton;
    IBOutlet NSSegmentedControl     *leftPaneButton;
    IBOutlet NSSegmentedControl     *rightPaneButton;
    IBOutlet NSSegmentedControl     *toolModeButton;
    IBOutlet NSSegmentedControl     *textNoteButton;
    IBOutlet NSSegmentedControl     *circleNoteButton;
    IBOutlet NSSegmentedControl     *markupNoteButton;
    IBOutlet NSSegmentedControl     *lineNoteButton;
    IBOutlet NSSegmentedControl     *singleTwoUpButton;
    IBOutlet NSSegmentedControl     *continuousButton;
    IBOutlet NSSegmentedControl     *displayModeButton;
    IBOutlet NSSegmentedControl     *displayBoxButton;
    IBOutlet NSSegmentedControl     *infoButton;
    IBOutlet NSSegmentedControl     *colorsButton;
    IBOutlet NSSegmentedControl     *fontsButton;
    IBOutlet NSSegmentedControl     *linesButton;
    IBOutlet NSSegmentedControl     *printButton;
    IBOutlet NSSegmentedControl     *customizeButton;
    IBOutlet NSTextField            *scaleField;
    IBOutlet NSSegmentedControl     *noteButton;
    IBOutlet SKColorSwatch          *colorSwatch;
    NSMutableDictionary             *toolbarItems;
    
    SKProgressController            *progressController;
    
    NSButton                        *colorAccessoryView;
    NSButton                        *textColorAccessoryView;
    
    NSMutableArray                  *pageLabels;
    
    NSString                        *pageLabel;
    NSUInteger                      pageNumber;
    
    NSUInteger                      markedPageIndex;
    NSUInteger                      beforeMarkedPageIndex;
    
    NSMutableArray                  *lastViewedPages;
    
    NSTimer                         *activityTimer;
    
    NSMutableDictionary             *savedNormalSetup;
    
    CGFloat                         lastLeftSidePaneWidth;
    CGFloat                         lastRightSidePaneWidth;
    CGFloat                         lastSecondaryPdfViewPaneHeight;
    
    CGFloat                         thumbnailCacheSize;
    CGFloat                         snapshotCacheSize;
    
    NSDrawer                        *leftSideDrawer;
    NSDrawer                        *rightSideDrawer;
    
    NSMutableDictionary             *undoGroupOldPropertiesPerNote;
    
    struct _mwcFlags {
        unsigned int leftSidePaneState : 1;
        unsigned int rightSidePaneState : 1;
        unsigned int savedLeftSidePaneState : 1;
        unsigned int findPaneState : 1;
        unsigned int updatingOutlineSelection : 1;
        unsigned int updatingThumbnailSelection : 1;
        unsigned int isAnimating : 1;
        unsigned int findPanelFind : 1;
        unsigned int caseInsensitiveSearch : 1;
        unsigned int wholeWordSearch : 1;
        unsigned int updatingNoteSelection : 1;
        unsigned int caseInsensitiveNoteSearch : 1;
        unsigned int updatingColor : 1;
        unsigned int updatingFont : 1;
        unsigned int updatingFontAttributes : 1;
        unsigned int updatingLine : 1;
        unsigned int settingUpWindow : 1;
        unsigned int isPresentation : 1;
        unsigned int usesDrawers : 1;
    } mwcFlags;
}

- (IBAction)enterFullScreen:(id)sender;
- (IBAction)exitFullScreen:(id)sender;
- (IBAction)enterPresentation:(id)sender;

- (void)displaySearchResultsForString:(NSString *)string;
- (IBAction)search:(id)sender;
- (IBAction)searchNotes:(id)sender;

- (void)showSnapshotAtPageNumber:(NSInteger)pageNum forRect:(NSRect)rect scaleFactor:(CGFloat)scaleFactor autoFits:(BOOL)autoFits;
- (void)showSnapshotsWithSetups:(NSArray *)setups;
- (void)showNote:(PDFAnnotation *)annotation;

- (SKPDFView *)pdfView;

- (PDFDocument *)pdfDocument;
- (void)setPdfDocument:(PDFDocument *)document;

- (SKProgressController *)progressController;

- (NSArray *)notes;
- (NSUInteger)countOfNotes;
- (PDFAnnotation *)objectInNotesAtIndex:(NSUInteger)theIndex;
- (void)insertObject:(PDFAnnotation *)note inNotesAtIndex:(NSUInteger)theIndex;
- (void)removeObjectFromNotesAtIndex:(NSUInteger)theIndex;
- (void)removeAllObjectsFromNotes;

- (NSArray *)thumbnails;
- (NSUInteger)countOfThumbnails;
- (SKThumbnail *)objectInThumbnailsAtIndex:(NSUInteger)theIndex;
- (void)insertObject:(SKThumbnail *)thumbnail inThumbnailsAtIndex:(NSUInteger)theIndex;
- (void)removeObjectFromThumbnailsAtIndex:(NSUInteger)theIndex;
- (void)removeAllObjectsFromThumbnails;

- (NSArray *)snapshots;
- (NSUInteger)countOfSnapshots;
- (SKSnapshotWindowController *)objectInSnapshotsAtIndex:(NSUInteger)theIndex;
- (void)insertObject:(SKSnapshotWindowController *)snapshot inSnapshotsAtIndex:(NSUInteger)theIndex;
- (void)removeObjectFromSnapshotsAtIndex:(NSUInteger)theIndex;
- (void)removeAllObjectsFromSnapshots;

- (NSArray *)searchResults;
- (void)setSearchResults:(NSArray *)newSearchResults;
- (NSUInteger)countOfSearchResults;
- (PDFSelection *)objectInSearchResultsAtIndex:(NSUInteger)theIndex;
- (void)insertObject:(PDFSelection *)searchResult inSearchResultsAtIndex:(NSUInteger)theIndex;
- (void)removeObjectFromSearchResultsAtIndex:(NSUInteger)theIndex;

- (NSArray *)groupedSearchResults;
- (void)setGroupedSearchResults:(NSArray *)newGroupedSearchResults;
- (NSUInteger)countOfGroupedSearchResults;
- (SKGroupedSearchResult *)objectInGroupedSearchResultsAtIndex:(NSUInteger)theIndex;
- (void)insertObject:(SKGroupedSearchResult *)groupedSearchResult inGroupedSearchResultsAtIndex:(NSUInteger)theIndex;
- (void)removeObjectFromGroupedSearchResultsAtIndex:(NSUInteger)theIndex;

- (NSDictionary *)presentationOptions;
- (void)setPresentationOptions:(NSDictionary *)dictionary;

- (NSArray *)tags;
- (double)rating;

- (NSArray *)selectedNotes;

- (NSUInteger)pageNumber;
- (void)setPageNumber:(NSUInteger)pageNumber;
- (NSString *)pageLabel;
- (void)setPageLabel:(NSString *)label;

- (BOOL)isFullScreen;
- (BOOL)isPresentation;

- (BOOL)autoScales;

- (SKLeftSidePaneState)leftSidePaneState;
- (void)setLeftSidePaneState:(SKLeftSidePaneState)newLeftSidePaneState;
- (SKRightSidePaneState)rightSidePaneState;
- (void)setRightSidePaneState:(SKRightSidePaneState)newRightSidePaneState;
- (SKFindPaneState)findPaneState;
- (void)setFindPaneState:(SKFindPaneState)newFindPaneState;

- (void)showLeftSideWindowOnScreen:(NSScreen *)screen;
- (void)showRightSideWindowOnScreen:(NSScreen *)screen;
- (void)hideLeftSideWindow;
- (void)hideRightSideWindow;

- (BOOL)leftSidePaneIsOpen;
- (BOOL)rightSidePaneIsOpen;

- (void)closeSideWindow:(SKSideWindow *)sideWindow;

- (void)displayOutlineView;
- (void)fadeInOutlineView;
- (void)displayThumbnailView;
- (void)fadeInThumbnailView;
- (void)displaySearchView;
- (void)fadeInSearchView;
- (void)displayGroupedSearchView;
- (void)fadeInGroupedSearchView;
- (void)displayNoteView;
- (void)displaySnapshotView;

- (void)removeTemporaryAnnotations;
- (void)addTemporaryAnnotationForPoint:(NSPoint)point onPage:(PDFPage *)page;

- (PDFSelection *)findString:(NSString *)string fromSelection:(PDFSelection *)selection withOptions:(NSInteger)options;

- (NSInteger)outlineRowForPageIndex:(NSUInteger)pageIndex;
- (void)updateOutlineSelection;

- (void)updateNoteSelection;

- (void)updateThumbnailSelection;
- (void)resetThumbnails;
- (void)resetThumbnailSizeIfNeeded;
- (void)updateThumbnailAtPageIndex:(NSUInteger)index;
- (void)allThumbnailsNeedUpdate;

- (void)resetSnapshotSizeIfNeeded;
- (void)snapshotNeedsUpdate:(SKSnapshotWindowController *)dirstySnapshot;
- (void)allSnapshotsNeedUpdate;
- (void)updateSnapshotsIfNeeded;
- (void)updateSnapshot:(NSTimer *)timer;

- (void)addAnnotationsFromDictionaries:(NSArray *)noteDicts undoable:(BOOL)undoable;
- (void)setAnnotationsFromDictionaries:(NSArray *)noteDicts undoable:(BOOL)undoable;

- (void)setOpenMetaTags:(NSArray *)tags;
- (void)setOpenMetaRating:(double)rating;

- (void)applySetup:(NSDictionary *)setup;
- (NSDictionary *)currentSetup;
- (void)applyPDFSettings:(NSDictionary *)setup;
- (NSDictionary *)currentPDFSettings;

- (void)goToDestination:(PDFDestination *)destination;
- (void)goToPage:(PDFPage *)page;

- (void)updateLeftStatus;
- (void)updateRightStatus;

@end

#pragma mark -

// forward declare all IBAction actions, because IB currently does not support categories defined in other headers
@interface SKMainWindowController (IBActions)

- (IBAction)changeColor:(id)sender;
- (IBAction)selectColor:(id)sender;
- (IBAction)changeFont:(id)sender;
- (IBAction)createNewNote:(id)sender;
- (IBAction)createNewTextNote:(id)sender;
- (IBAction)createNewCircleNote:(id)sender;
- (IBAction)createNewMarkupNote:(id)sender;
- (IBAction)createNewLineNote:(id)sender;
- (IBAction)editNote:(id)sender;
- (IBAction)toggleHideNotes:(id)sender;
- (IBAction)takeSnapshot:(id)sender;
- (IBAction)displaySinglePages:(id)sender;
- (IBAction)displayFacingPages:(id)sender;
- (IBAction)changeDisplaySinglePages:(id)sender;
- (IBAction)toggleDisplayContinuous:(id)sender;
- (IBAction)changeDisplayContinuous:(id)sender;
- (IBAction)changeDisplayMode:(id)sender;
- (IBAction)toggleDisplayAsBook:(id)sender;
- (IBAction)toggleDisplayPageBreaks:(id)sender;
- (IBAction)changeDisplayBox:(id)sender;
- (IBAction)doGoToNextPage:(id)sender;
- (IBAction)doGoToPreviousPage:(id)sender;
- (IBAction)doGoToFirstPage:(id)sender;
- (IBAction)doGoToLastPage:(id)sender;
- (IBAction)allGoToNextPage:(id)sender;
- (IBAction)allGoToPreviousPage:(id)sender;
- (IBAction)allGoToFirstPage:(id)sender;
- (IBAction)allGoToLastPage:(id)sender;
- (IBAction)goToPreviousNextFirstLastPage:(id)sender;
- (IBAction)doGoToPage:(id)sender;
- (IBAction)doGoBack:(id)sender;
- (IBAction)doGoForward:(id)sender;
- (IBAction)goBackOrForward:(id)sender;
- (IBAction)goToMarkedPage:(id)sender;
- (IBAction)markPage:(id)sender;
- (IBAction)doZoomIn:(id)sender;
- (IBAction)doZoomOut:(id)sender;
- (IBAction)doZoomToActualSize:(id)sender;
- (IBAction)doZoomToPhysicalSize:(id)sender;
- (IBAction)doZoomToFit:(id)sender;
- (IBAction)alternateZoomToFit:(id)sender;
- (IBAction)doZoomToSelection:(id)sender;
- (IBAction)zoomInActualOut:(id)sender;
- (IBAction)zoomLog:(id)sender;
- (IBAction)doAutoScale:(id)sender;
- (IBAction)toggleAutoScale:(id)sender;
- (IBAction)toggleAutoActualSize:(id)sender;
- (IBAction)rotateRight:(id)sender;
- (IBAction)rotateLeft:(id)sender;
- (IBAction)rotateAllRight:(id)sender;
- (IBAction)rotateAllLeft:(id)sender;
- (IBAction)rotateAllLeftRight:(id)sender;
- (IBAction)crop:(id)sender;
- (IBAction)cropAll:(id)sender;
- (IBAction)autoCropAll:(id)sender;
- (IBAction)smartAutoCropAll:(id)sender;
- (IBAction)autoSelectContent:(id)sender;
- (IBAction)getInfo:(id)sender;
- (IBAction)changeScaleFactor:(id)sender;
- (IBAction)chooseScale:(id)sender;
- (IBAction)changeToolMode:(id)sender;
- (IBAction)changeAnnotationMode:(id)sender;
- (IBAction)toggleLeftSidePane:(id)sender;
- (IBAction)toggleRightSidePane:(id)sender;
- (IBAction)changeLeftSidePaneState:(id)sender;
- (IBAction)changeRightSidePaneState:(id)sender;
- (IBAction)changeFindPaneState:(id)sender;
- (IBAction)toggleStatusBar:(id)sender;
- (IBAction)toggleSplitPDF:(id)sender;
- (IBAction)toggleReadingBar:(id)sender;
- (IBAction)searchPDF:(id)sender;
- (IBAction)toggleFullScreen:(id)sender;
- (IBAction)togglePresentation:(id)sender;
- (IBAction)performFit:(id)sender;
- (IBAction)password:(id)sender;
- (IBAction)savePDFSettingToDefaults:(id)sender;
- (IBAction)chooseTransition:(id)sender;
- (IBAction)toggleCaseInsensitiveSearch:(id)sender;
- (IBAction)toggleWholeWordSearch:(id)sender;
- (IBAction)toggleCaseInsensitiveNoteSearch:(id)sender;
- (IBAction)addBookmark:(id)sender;
- (IBAction)addSetupBookmark:(id)sender;
- (IBAction)addSessionBookmark:(id)sender;

@end
