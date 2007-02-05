//
//  SKPDFView.h


//  This code is licensed under a BSD license. Please see the file LICENSE for details.
//
//  Created by Michael McCracken on 12/6/06.
//  Copyright 2006 Michael O. McCracken. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Quartz/Quartz.h>
#import "SKMainWindowController.h"

extern NSString *SKPDFViewToolModeChangedNotification;

typedef enum _SKToolMode {
    SKMoveToolMode,
    SKTextToolMode,
    SKMagnifyToolMode,
    SKPopUpToolMode,
    SKAnnotateToolMode
} SKToolMode;

@interface SKPDFView : PDFView {
    SKToolMode toolMode;
    BOOL autohidesCursor;
    BOOL hasNavigation;
    NSTimer *autohideTimer;
    SKNavigationWindow *navWindow;
    
	PDFAnnotation *activeAnnotation;
	PDFAnnotationTextWidget *editAnnotation;
	PDFPage *activePage;
	NSRect wasBounds;
	NSPoint mouseDownLoc;
	NSPoint clickDelta;
	BOOL dragging;
	BOOL resizing;
	BOOL mouseDownInAnnotation;
}

- (SKToolMode)toolMode;
- (void)setToolMode:(SKToolMode)newToolMode;

- (void)setHasNavigation:(BOOL)hasNav autohidesCursor:(BOOL)hideCursor;

- (void)showPDFHoverWindowWithDestination:(PDFDestination *)dest atPoint:(NSPoint)point;
- (void)cleanupPDFHoverView;

- (void)doAutohide:(BOOL)flag;
- (void)showHoverViewWithEvent:(NSEvent *)event;
- (void)popUpWithEvent:(NSEvent *)theEvent;
- (void)annotateWithEvent:(NSEvent *)theEvent;
- (void)selectAnnotationWithEvent:(NSEvent *)theEvent;
- (void)dragAnnotationWithEvent:(NSEvent *)theEvent;
- (void)magnifyWithEvent:(NSEvent *)theEvent;
- (void)dragWithEvent:(NSEvent *)theEvent;

- (IBAction)delete:(id)sender;

- (void) transformContextForPage:(PDFPage *)page;

- (PDFAnnotation *)activeAnnotation;
- (void)setActiveAnnotation:(PDFAnnotation *)newAnnotation;
- (NSRect)resizeThumbForRect:(NSRect)rect rotation:(int)rotation;
- (void)setNeedsDisplayForAnnotion:(PDFAnnotation *)annotation;

@end
