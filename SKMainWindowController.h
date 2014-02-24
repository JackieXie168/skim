//
//  SKMainWindowController.h
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
#import "SKSnapshotWindowController.h"
#import "SKThumbnail.h"
#import "SKFindController.h"
#import "NSDocument_SKExtensions.h"
#import <IOKit/pwr_mgt/IOPMLib.h>

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

@class PDFAnnotation, PDFSelection, SKGroupedSearchResult, SKFloatMapTable;
@class SKPDFView, SKSecondaryPDFView, SKStatusBar, SKFindController, SKSplitView, SKFieldEditor, SKSideWindow;
@class SKLeftSideViewController, SKRightSideViewController, SKMainToolbarController, SKProgressController, SKPresentationOptionsSheetController, SKNoteTypeSheetController;

@interface SKMainWindowController : NSWindowController <SKSnapshotWindowControllerDelegate, SKThumbnailDelegate, SKFindControllerDelegate> {
    SKSplitView                         *splitView;
    
    NSView                              *centerContentView;
    SKSplitView                         *pdfSplitView;
    NSView                              *pdfContentView;
    SKPDFView                           *pdfView;
    
    NSView                              *secondaryPdfContentView;
    SKSecondaryPDFView                  *secondaryPdfView;
    
    SKLeftSideViewController            *leftSideController;
    SKRightSideViewController           *rightSideController;
    
    SKMainToolbarController             *toolbarController;
    
    NSView                              *leftSideContentView;
    NSView                              *rightSideContentView;
    
    SKStatusBar                         *statusBar;
    
    SKFindController                    *findController;
    
    SKFieldEditor                       *fieldEditor;
    
    NSMutableArray                      *thumbnails;
    CGFloat                             roundedThumbnailSize;
    
    NSMutableArray                      *searchResults;
    NSInteger                           searchResultIndex;
    
    NSMutableArray                      *groupedSearchResults;
    
    SKNoteTypeSheetController           *noteTypeSheetController;
    NSMutableArray                      *notes;
    SKFloatMapTable                     *rowHeights;
    
    NSMutableArray                      *snapshots;
    NSMutableArray                      *dirtySnapshots;
    NSTimer                             *snapshotTimer;
    CGFloat                             roundedSnapshotThumbnailSize;
    
    NSArray                             *tags;
    double                              rating;
    
    NSWindow                            *mainWindow;
    SKSideWindow                        *leftSideWindow;
    SKSideWindow                        *rightSideWindow;
    NSMutableArray                      *blankingWindows;
    
    SKInteractionMode                   interactionMode;
    
    SKProgressController                *progressController;
    
    SKPresentationOptionsSheetController *presentationSheetController;
    
    NSDocument                          *presentationNotesDocument;
    
    NSButton                            *colorAccessoryView;
    NSButton                            *textColorAccessoryView;
    
    NSMutableArray                      *pageLabels;
    
    NSString                            *pageLabel;
    NSUInteger                          pageNumber;
    
    NSUInteger                          markedPageIndex;
    NSUInteger                          beforeMarkedPageIndex;
    
    NSPointerArray                      *lastViewedPages;
    
    IOPMAssertionID                     activityAssertionID;
    
    NSMutableDictionary                 *savedNormalSetup;
    
    CGFloat                             lastLeftSidePaneWidth;
    CGFloat                             lastRightSidePaneWidth;
    CGFloat                             lastSplitPDFHeight;
    
    CGFloat                             thumbnailCacheSize;
    CGFloat                             snapshotCacheSize;
    
    NSDrawer                            *leftSideDrawer;
    NSDrawer                            *rightSideDrawer;
    
    NSMapTable                          *undoGroupOldPropertiesPerNote;
    
    struct _mwcFlags {
        unsigned int leftSidePaneState:1;
        unsigned int rightSidePaneState:1;
        unsigned int savedLeftSidePaneState:1;
        unsigned int findPaneState:1;
        unsigned int updatingOutlineSelection:1;
        unsigned int updatingThumbnailSelection:1;
        unsigned int isAnimating:1;
        unsigned int caseInsensitiveSearch:1;
        unsigned int wholeWordSearch:1;
        unsigned int updatingNoteSelection:1;
        unsigned int caseInsensitiveNoteSearch:1;
        unsigned int updatingColor:1;
        unsigned int updatingFont:1;
        unsigned int updatingFontAttributes:1;
        unsigned int updatingLine:1;
        unsigned int settingUpWindow:1;
        unsigned int usesDrawers:1;
        unsigned int isEditingPDF:1;
        unsigned int isEditingTable:1;
        unsigned int isSwitchingFullScreen:1;
    } mwcFlags;
}

@property (nonatomic, retain) IBOutlet NSWindow *mainWindow;

@property (nonatomic, retain) IBOutlet SKSplitView *splitView;
    
@property (nonatomic, retain) IBOutlet NSView *centerContentView;
@property (nonatomic, retain) IBOutlet SKSplitView *pdfSplitView;
@property (nonatomic, retain) IBOutlet NSView *pdfContentView;

@property (nonatomic, retain) IBOutlet SKLeftSideViewController *leftSideController;
@property (nonatomic, retain) IBOutlet SKRightSideViewController *rightSideController;
    
@property (nonatomic, retain) IBOutlet SKMainToolbarController *toolbarController;
    
@property (nonatomic, retain) IBOutlet NSView *leftSideContentView, *rightSideContentView;

- (IBAction)enterFullscreen:(id)sender;
- (IBAction)exitFullscreen:(id)sender;
- (IBAction)enterPresentation:(id)sender;

- (void)displaySearchResultsForString:(NSString *)string;
- (IBAction)search:(id)sender;
- (IBAction)searchNotes:(id)sender;

- (void)showSnapshotAtPageNumber:(NSInteger)pageNum forRect:(NSRect)rect scaleFactor:(CGFloat)scaleFactor autoFits:(BOOL)autoFits;
- (void)showSnapshotsWithSetups:(NSArray *)setups;
- (void)showNote:(PDFAnnotation *)annotation;

- (NSWindowController *)windowControllerForNote:(PDFAnnotation *)annotation;

@property (nonatomic, readonly) SKPDFView *pdfView;
@property (nonatomic, retain) PDFDocument *pdfDocument;

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

@property (nonatomic, copy) NSDictionary *presentationOptions;

@property (nonatomic, retain) NSDocument *presentationNotesDocument;

@property (nonatomic, copy) NSArray *tags;
@property (nonatomic) double rating;

@property (nonatomic, readonly) NSArray *selectedNotes;

@property (nonatomic) NSUInteger pageNumber;
@property (nonatomic, copy) NSString *pageLabel;

@property (nonatomic, readonly) SKInteractionMode interactionMode;

@property (nonatomic, readonly) BOOL autoScales;

@property (nonatomic) SKLeftSidePaneState leftSidePaneState;
@property (nonatomic) SKRightSidePaneState rightSidePaneState;
@property (nonatomic) SKFindPaneState findPaneState;

- (void)showLeftSideWindow;
- (void)showRightSideWindow;
- (void)hideLeftSideWindow;
- (void)hideRightSideWindow;

@property (nonatomic, readonly) BOOL leftSidePaneIsOpen, rightSidePaneIsOpen;

- (void)displayTocViewAnimating:(BOOL)animate;
- (void)displayThumbnailViewAnimating:(BOOL)animate;
- (void)displayFindViewAnimating:(BOOL)animate;
- (void)displayGroupedFindViewAnimating:(BOOL)animate;
- (void)displayNoteViewAnimating:(BOOL)animate;
- (void)displaySnapshotViewAnimating:(BOOL)animate;

- (void)showFindBar;

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

- (void)addAnnotationsFromDictionaries:(NSArray *)noteDicts replace:(BOOL)replace;

- (void)applySetup:(NSDictionary *)setup;
- (NSDictionary *)currentSetup;
- (void)applyPDFSettings:(NSDictionary *)setup;
- (NSDictionary *)currentPDFSettings;

- (void)updateLeftStatus;
- (void)updateRightStatus;

- (void)beginProgressSheetWithMessage:(NSString *)message maxValue:(NSUInteger)maxValue;
- (void)incrementProgressSheet;
- (void)dismissProgressSheet;

@end
