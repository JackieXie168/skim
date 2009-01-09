//
//  SKPDFView.h
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
#import <Quartz/Quartz.h>
#import "SKMainWindowController.h"
#import "SKTransitionController.h"

extern NSString *SKPDFViewToolModeChangedNotification;
extern NSString *SKPDFViewAnnotationModeChangedNotification;
extern NSString *SKPDFViewActiveAnnotationDidChangeNotification;
extern NSString *SKPDFViewDidAddAnnotationNotification;
extern NSString *SKPDFViewDidRemoveAnnotationNotification;
extern NSString *SKPDFViewDidMoveAnnotationNotification;
extern NSString *SKPDFViewReadingBarDidChangeNotification;
extern NSString *SKPDFViewSelectionChangedNotification;
extern NSString *SKPDFViewMagnificationChangedNotification;
extern NSString *SKPDFViewDisplayModeChangedNotification;
extern NSString *SKPDFViewDisplayAsBookChangedNotification;
extern NSString *SKPDFViewDisplayBoxChangedNotification;

extern NSString *SKPDFViewAnnotationKey;
extern NSString *SKPDFViewPageKey;
extern NSString *SKPDFViewOldPageKey;
extern NSString *SKPDFViewNewPageKey;

extern NSString *SKSkimNotePboardType;

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
    SKNormalMode,
    SKFullScreenMode,
    SKPresentationMode
};
typedef NSInteger SKInteractionMode;

@class SKReadingBar, SKTransitionController, SKTypeSelectHelper;

@interface SKPDFView : PDFView {
    SKToolMode toolMode;
    SKNoteType annotationMode;
    SKInteractionMode interactionMode;
    
    BOOL hideNotes;
    
    BOOL activateNavigationAtBottom;
    NSTimer *autohideTimer;
    SKNavigationWindow *navWindow;
    
    SKReadingBar *readingBar;
    
    SKTransitionController *transitionController;
    
    SKTypeSelectHelper *typeSelectHelper;
    
    NSMutableArray *accessibilityChildren;
    
	PDFAnnotation *activeAnnotation;
	PDFAnnotation *highlightAnnotation;
    NSTextField *editField;
	NSRect wasBounds;
    NSPoint wasStartPoint;
    NSPoint wasEndPoint;
	NSPoint mouseDownLoc;
	NSPoint clickDelta;
    NSRect selectionRect;
    unsigned int selectionPageIndex;
    float magnification;
    BOOL didSelect;
    BOOL mouseDownInAnnotation;
    int dragMask;
    NSBezierPath *bezierPath;
    unsigned int pathPageIndex;
    float gestureRotation;
    unsigned int gesturePageIndex;
    
    int trackingRect;
    CFMutableArrayRef PDFToolTipRects;
    int PDFToolTipRect;
    
    int spellingTag;
}

- (SKToolMode)toolMode;
- (void)setToolMode:(SKToolMode)newToolMode;

- (SKNoteType)annotationMode;
- (void)setAnnotationMode:(SKNoteType)newAnnotationMode;

- (SKInteractionMode)interactionMode;
- (void)setInteractionMode:(SKInteractionMode)newInteractionMode screen:(NSScreen *)screen;

- (PDFAnnotation *)activeAnnotation;
- (void)setActiveAnnotation:(PDFAnnotation *)newAnnotation;

- (BOOL)isEditing;

- (NSRect)currentSelectionRect;
- (void)setCurrentSelectionRect:(NSRect)rect;

- (PDFPage *)currentSelectionPage;
- (void)setCurrentSelectionPage:(PDFPage *)page;

- (float)currentMagnification;

- (BOOL)hideNotes;
- (void)setHideNotes:(BOOL)flag;

- (BOOL)hasReadingBar;
- (SKReadingBar *)readingBar;

- (void)toggleReadingBar;

- (SKTransitionController *)transitionController;

- (SKTypeSelectHelper *)typeSelectHelper;
- (void)setTypeSelectHelper:(SKTypeSelectHelper *)newTypeSelectHelper;

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

- (void)addAnnotation:(id)sender;
- (void)addAnnotationWithType:(SKNoteType)annotationType;
- (void)addAnnotation:(PDFAnnotation *)annotation toPage:(PDFPage *)page;
- (void)addAnnotation:(PDFAnnotation *)annotation toPage:(PDFPage *)page undoable:(BOOL)undoable;
- (void)removeActiveAnnotation:(id)sender;
- (void)removeThisAnnotation:(id)sender;
- (void)removeAnnotation:(PDFAnnotation *)annotation;
- (void)removeAnnotation:(PDFAnnotation *)annotation undoable:(BOOL)undoable;

- (void)editActiveAnnotation:(id)sender;
- (void)editThisAnnotation:(id)sender;
- (void)endAnnotationEdit:(id)sender;

- (void)selectNextActiveAnnotation:(id)sender;
- (void)selectPreviousActiveAnnotation:(id)sender;

- (void)scrollAnnotationToVisible:(PDFAnnotation *)annotation;
- (void)scrollRect:(NSRect)rect inPageToVisible:(PDFPage *)page;
- (void)displayLineAtPoint:(NSPoint)point inPageAtIndex:(unsigned int)pageIndex;

- (void)takeSnapshot:(id)sender;

- (void)setNeedsDisplayInRect:(NSRect)rect ofPage:(PDFPage *)page;
- (void)setNeedsDisplayForAnnotation:(PDFAnnotation *)annotation;

- (void)handlePageChangedNotification:(NSNotification *)notification;
- (void)handleScaleChangedNotification:(NSNotification *)notification;
- (void)handleWindowWillCloseNotification:(NSNotification *)notification;

- (void)resetPDFToolTipRects;
- (void)removePDFToolTipRects;

- (NSArray *)accessibilityChildren;
- (id)accessibilityChildAtPoint:(NSPoint)point;
- (id)accessibilityFocusedChild;

- (NSUndoManager *)undoManager;

@end

#pragma mark -

@interface NSObject (SKPDFViewDelegate)
- (void)PDFView:(PDFView *)sender editAnnotation:(PDFAnnotation *)annotation;
@end
