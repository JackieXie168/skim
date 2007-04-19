//
//  SKPDFView.h
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
#import <Quartz/Quartz.h>
#import "SKMainWindowController.h"

extern NSString *SKPDFViewToolModeChangedNotification;
extern NSString *SKPDFViewActiveAnnotationDidChangeNotification;
extern NSString *SKPDFViewDidAddAnnotationNotification;
extern NSString *SKPDFViewDidRemoveAnnotationNotification;
extern NSString *SKPDFViewAnnotationDoubleClickedNotification;

extern NSString *SKSkimNotePboardType;

typedef enum _SKToolMode {
    SKTextToolMode,
    SKMoveToolMode,
    SKMagnifyToolMode
} SKToolMode;

typedef enum _SKNoteType {
    SKFreeTextNote,
    SKAnchoredNote,
    SKCircleNote,
    SKSquareNote,
    SKHighlightNote,
    SKUnderlineNote,
    SKStrikeOutNote,
    SKArrowNote
} SKNoteType;

@class SKReadingBar;

@interface SKPDFView : PDFView {
    SKToolMode toolMode;
    
    BOOL autohidesCursor;
    BOOL hasNavigation;
    NSTimer *autohideTimer;
    SKNavigationWindow *navWindow;
    
    SKReadingBar *readingBar;
    
	PDFAnnotation *activeAnnotation;
	PDFAnnotationTextWidget *editAnnotation;
	NSRect wasBounds;
    NSPoint wasStartPoint;
    NSPoint wasEndPoint;
	NSPoint mouseDownLoc;
	NSPoint clickDelta;
	BOOL resizingAnnotation;
	BOOL draggingAnnotation;
	BOOL draggingStartPoint;
    BOOL mouseDownInAnnotation;
    
    int trackingRect;
}

- (SKToolMode)toolMode;
- (void)setToolMode:(SKToolMode)newToolMode;

- (PDFAnnotation *)activeAnnotation;
- (void)setActiveAnnotation:(PDFAnnotation *)newAnnotation;

- (BOOL)hasReadingBar;

- (void)toggleReadingBar;

- (IBAction)delete:(id)sender;

- (void)addAnnotationFromMenu:(id)sender;
- (void)addAnnotationFromSelectionWithType:(SKNoteType)annotationType;
- (void)addAnnotationWithType:(SKNoteType)annotationType contents:(NSString *)text page:(PDFPage *)page bounds:(NSRect)bounds;
- (void)removeActiveAnnotation:(id)sender;
- (void)removeThisAnnotation:(id)sender;
- (void)removeAnnotation:(PDFAnnotation *)annotation;
- (void)editActiveAnnotation:(id)sender;
- (void)editThisAnnotation:(id)sender;
- (void)endAnnotationEdit:(id)sender;
- (void)selectNextActiveAnnotation:(id)sender;
- (void)selectPreviousActiveAnnotation:(id)sender;
- (void)scrollAnnotationToVisible:(PDFAnnotation *)annotation;

- (void)takeSnapshot:(id)sender;

- (void)setHasNavigation:(BOOL)hasNav autohidesCursor:(BOOL)hideCursor;

- (void)setNeedsDisplayInRect:(NSRect)rect ofPage:(PDFPage *)page;
- (void)setNeedsDisplayForAnnotation:(PDFAnnotation *)annotation;

- (void)handleAnnotationWillChangeNotification:(NSNotification *)notification;
- (void)handleAnnotationDidChangeNotification:(NSNotification *)notification;
- (void)handleWindowWillCloseNotification:(NSNotification *)notification;

@end
