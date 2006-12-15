//
//  SKSubWindowController.h


//  This code is licensed under a BSD license. Please see the file LICENSE for details.
//
//  Created by Michael McCracken on 12/6/06.
//  Copyright 2006 Michael O. McCracken. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@class PDFView, PDFDocument;

@interface SKSubWindowController : NSWindowController {
    NSMutableArray *subWindowControllers;
    IBOutlet PDFView* pdfView;
    NSPoint startPoint;  
}
- (void)setPdfDocument:(PDFDocument *)pdfDocument scaleFactor:(int)factor autoScales:(BOOL)autoScales;

- (void)goToPageNumber:(int)pageNum point:(NSPoint)locationInPageSpace;

@end
