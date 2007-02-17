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
extern NSString *SKPDFViewAnnotationModeChangedNotification;
extern NSString *SKPDFViewActiveAnnotationDidChangeNotification;
extern NSString *SKPDFViewDidAddAnnotationNotification;
extern NSString *SKPDFViewDidRemoveAnnotationNotification;
extern NSString *SKPDFViewDidChangeAnnotationNotification;
extern NSString *SKPDFViewAnnotationDoubleClickedNotification;

typedef enum _SKToolMode {
    SKTextToolMode,
    SKMoveToolMode,
    SKMagnifyToolMode
} SKToolMode;

typedef enum _SKAnnotationMode {
    SKFreeTextAnnotationMode,
    SKNoteAnnotationMode,
    SKCircleAnnotationMode,
    SKTextAnnotationMode,
    SKSquareAnnotationMode
} SKAnnotationMode;

@interface SKPDFView : PDFView {
    SKToolMode toolMode;
    SKAnnotationMode annotationMode;
    
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
	BOOL selecting;
	BOOL resizing;
	BOOL mouseDownInAnnotation;
}

- (SKToolMode)toolMode;
- (void)setToolMode:(SKToolMode)newToolMode;

- (SKAnnotationMode)annotationMode;
- (void)setAnnotationMode:(SKAnnotationMode)newAnnotationMode;

- (PDFAnnotation *)activeAnnotation;
- (void)setActiveAnnotation:(PDFAnnotation *)newAnnotation;

- (IBAction)delete:(id)sender;

- (void)addAnnotation:(id)sender;
- (void)removeActiveAnnotation:(id)sender;
- (void)removeThisAnnotation:(id)sender;
- (void)removeAnnotation:(PDFAnnotation *)annotation;
- (void)editActiveAnnotation:(id)sender;
- (void)editThisAnnotation:(id)sender;
- (void)endAnnotationEdit:(id)sender;

- (void)setHasNavigation:(BOOL)hasNav autohidesCursor:(BOOL)hideCursor;

- (void)setNeedsDisplayInRect:(NSRect)rect ofPage:(PDFPage *)page;
- (void)setNeedsDisplayForAnnotation:(PDFAnnotation *)annotation;

@end
