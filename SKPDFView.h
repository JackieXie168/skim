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
}

- (SKToolMode)toolMode;
- (void)setToolMode:(SKToolMode)newToolMode;

- (void)handlePopUpRequest:(NSEvent *)theEvent;
- (void)handleAnnotationRequest:(NSEvent *)theEvent;
- (void)handleMagnifyRequest:(NSEvent *)theEvent;
- (void)scrollByDragging:(NSEvent *)theEvent;

@end
