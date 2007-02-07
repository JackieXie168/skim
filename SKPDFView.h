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
extern NSString *SKPDFViewActiveAnnotationDidChangeNotification;
extern NSString *SKPDFViewDidRemoveAnnotationNotification;
extern NSString *SKPDFViewDidChangeAnnotationNotification;
extern NSString *SKPDFViewAnnotationDoubleClickedNotification;

typedef enum _SKToolMode {
    SKTextToolMode,
    SKMoveToolMode,
    SKMagnifyToolMode
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

- (void)doAutohide:(BOOL)flag;
- (void)popUpWithEvent:(NSEvent *)theEvent;
- (void)annotateWithEvent:(NSEvent *)theEvent;
- (void)selectAnnotationWithEvent:(NSEvent *)theEvent;
- (void)dragAnnotationWithEvent:(NSEvent *)theEvent;
- (void)magnifyWithEvent:(NSEvent *)theEvent;
- (void)dragWithEvent:(NSEvent *)theEvent;

- (IBAction)delete:(id)sender;

- (PDFAnnotation *)activeAnnotation;
- (void)setActiveAnnotation:(PDFAnnotation *)newAnnotation;
- (void)setNeedsDisplayForAnnotation:(PDFAnnotation *)annotation;
- (void)endAnnotationEdit;

@end
