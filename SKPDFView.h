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
    NSTimer *autohideTimer;
}

- (SKToolMode)toolMode;
- (void)setToolMode:(SKToolMode)newToolMode;

- (BOOL)autohidesCursor;
- (void)setAutohidesCursor:(BOOL)flag;

- (void)popUpWithEvent:(NSEvent *)theEvent;
- (void)annotateWithEvent:(NSEvent *)theEvent;
- (void)magnifyWithEvent:(NSEvent *)theEvent;
- (void)dragWithEvent:(NSEvent *)theEvent;

@end
