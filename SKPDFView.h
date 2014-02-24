//
//  SKPDFView.h
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
#import <Quartz/Quartz.h>
#import "NSDocument_SKExtensions.h"

extern NSString *SKPDFViewToolModeChangedNotification;
extern NSString *SKPDFViewAnnotationModeChangedNotification;
extern NSString *SKPDFViewActiveAnnotationDidChangeNotification;
extern NSString *SKPDFViewDidAddAnnotationNotification;
extern NSString *SKPDFViewDidRemoveAnnotationNotification;
extern NSString *SKPDFViewDidMoveAnnotationNotification;
extern NSString *SKPDFViewReadingBarDidChangeNotification;
extern NSString *SKPDFViewSelectionChangedNotification;
extern NSString *SKPDFViewMagnificationChangedNotification;

extern NSString *SKPDFViewAnnotationKey;
extern NSString *SKPDFViewPageKey;
extern NSString *SKPDFViewOldPageKey;
extern NSString *SKPDFViewNewPageKey;

enum _SKToolMode {
    SKTextToolMode,
    SKMoveToolMode,
    SKMagnifyToolMode,
    SKSelectToolMode,
    SKNoteToolMode
};
typedef NSInteger SKToolMode;

enum {
    SKFreeTextNote,
    SKAnchoredNote,
    SKCircleNote,
    SKSquareNote,
    SKHighlightNote,
    SKUnderlineNote,
    SKStrikeOutNote,
    SKLineNote,
    SKInkNote
};
typedef NSInteger SKNoteType;

enum {
    SKReadingBarArea = 1 << 16,
    SKReadingBarResizeArea = 1 << 17
};

@class SKReadingBar, SKTransitionController, SKTypeSelectHelper, SKNavigationWindow, SKTextNoteEditor, SKSyncDot;

@interface SKPDFView : PDFView {
    SKToolMode toolMode;
    SKNoteType annotationMode;
    SKInteractionMode interactionMode;
    
    BOOL hideNotes;
    
    NSInteger navigationMode;
    SKNavigationWindow *navWindow;
    
    SKReadingBar *readingBar;
    
    SKTransitionController *transitionController;
    
    SKTypeSelectHelper *typeSelectHelper;
    
    NSArray *accessibilityChildren;
    
	PDFAnnotation *activeAnnotation;
	PDFAnnotation *highlightAnnotation;
    
    SKTextNoteEditor *editor;
    
    NSRect selectionRect;
    NSUInteger selectionPageIndex;
    
    SKSyncDot *syncDot;
    
    CGFloat magnification;
    
    CGFloat gestureRotation;
    NSUInteger gesturePageIndex;
    
    BOOL isZooming;
    
    NSInteger minHistoryIndex;
    
    NSTrackingArea *trackingArea;
    
    NSInteger spellingTag;
}

@property (nonatomic) SKToolMode toolMode;
@property (nonatomic) SKNoteType annotationMode;
@property (nonatomic) SKInteractionMode interactionMode;
@property (nonatomic, retain) PDFAnnotation *activeAnnotation;
@property (nonatomic, readonly) BOOL isZooming;
@property (nonatomic, readonly) NSTextField *editTextField;
@property (nonatomic) NSRect currentSelectionRect;
@property (nonatomic, retain) PDFPage *currentSelectionPage;
@property (nonatomic, readonly) CGFloat currentMagnification;
@property (nonatomic) BOOL hideNotes;
@property (nonatomic, readonly) BOOL hasReadingBar;
@property (nonatomic, readonly) SKReadingBar *readingBar;
@property (nonatomic, readonly) SKTransitionController *transitionController;
@property (nonatomic, retain) SKTypeSelectHelper *typeSelectHelper;

- (void)toggleReadingBar;

- (IBAction)delete:(id)sender;
- (IBAction)paste:(id)sender;
- (IBAction)alternatePaste:(id)sender;
- (IBAction)pasteAsPlainText:(id)sender;
- (IBAction)copy:(id)sender;
- (IBAction)cut:(id)sender;
- (IBAction)deselectAll:(id)sender;
- (IBAction)autoSelectContent:(id)sender;
- (IBAction)changeToolMode:(id)sender;
- (IBAction)changeAnnotationMode:(id)sender;

- (void)zoomLog:(id)sender;
- (void)toggleAutoActualSize:(id)sender;
- (void)exitFullscreen:(id)sender;

- (void)addAnnotation:(id)sender;
- (void)addAnnotationWithType:(SKNoteType)annotationType;
- (void)addAnnotation:(PDFAnnotation *)annotation toPage:(PDFPage *)page;
- (void)removeActiveAnnotation:(id)sender;
- (void)removeThisAnnotation:(id)sender;
- (void)removeAnnotation:(PDFAnnotation *)annotation;

- (void)editActiveAnnotation:(id)sender;
- (void)editThisAnnotation:(id)sender;

- (void)selectNextActiveAnnotation:(id)sender;
- (void)selectPreviousActiveAnnotation:(id)sender;

- (void)scrollAnnotationToVisible:(PDFAnnotation *)annotation;
- (void)scrollPageToVisible:(PDFPage *)page;
- (void)displayLineAtPoint:(NSPoint)point inPageAtIndex:(NSUInteger)pageIndex showReadingBar:(BOOL)showBar;

- (void)takeSnapshot:(id)sender;

- (void)resetPDFToolTipRects;
- (void)removePDFToolTipRects;

- (void)resetHistory;

- (PDFAreaOfInterest)extendedAreaOfInterestForMouse:(NSEvent *)theEvent;

- (NSArray *)accessibilityChildren;
- (id)accessibilityChildAtPoint:(NSPoint)point;
- (id)accessibilityFocusedChild;

@end

#pragma mark -

@interface NSObject (SKPDFViewDelegate)
- (void)PDFViewDidBeginEditing:(PDFView *)sender;
- (void)PDFViewDidEndEditing:(PDFView *)sender;
- (void)PDFView:(PDFView *)sender editAnnotation:(PDFAnnotation *)annotation;
- (void)PDFView:(PDFView *)sender showSnapshotAtPageNumber:(NSInteger)pageNum forRect:(NSRect)rect scaleFactor:(CGFloat)scaleFactor autoFits:(BOOL)autoFits;
- (void)PDFViewExitFullscreen:(PDFView *)sender;
- (void)PDFViewToggleContents:(PDFView *)sender;
@end
