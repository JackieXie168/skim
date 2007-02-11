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
	BOOL dragging;
	BOOL resizing;
	BOOL mouseDownInAnnotation;
}

- (SKToolMode)toolMode;
- (void)setToolMode:(SKToolMode)newToolMode;

- (SKAnnotationMode)annotationMode;
- (void)setAnnotationMode:(SKAnnotationMode)newAnnotationMode;

- (void)setHasNavigation:(BOOL)hasNav autohidesCursor:(BOOL)hideCursor;

- (void)doAutohide:(BOOL)flag;
- (void)popUpWithEvent:(NSEvent *)theEvent;
- (void)selectAnnotationWithEvent:(NSEvent *)theEvent;
- (void)dragAnnotationWithEvent:(NSEvent *)theEvent;
- (void)magnifyWithEvent:(NSEvent *)theEvent;
- (void)dragWithEvent:(NSEvent *)theEvent;

- (IBAction)delete:(id)sender;

- (PDFAnnotation *)activeAnnotation;
- (void)setActiveAnnotation:(PDFAnnotation *)newAnnotation;
- (void)setNeedsDisplayForAnnotation:(PDFAnnotation *)annotation;
- (PDFAnnotation *)addAnnotationFromSelection:(PDFSelection *)selection;
- (void)endAnnotationEdit;

@end


@interface PDFPage (SKExtensions) 
- (NSImage *)image;
- (NSImage *)thumbnailWithSize:(float)size shadowBlurRadius:(float)shadowBlurRadius shadowOffset:(NSSize)shadowOffset;
@end
