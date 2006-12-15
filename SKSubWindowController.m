//
//  SKSubWindowController.m


//  This code is licensed under a BSD license. Please see the file LICENSE for details.
//
//  Created by Michael McCracken on 12/6/06.
//  Copyright 2006 Michael O. McCracken. All rights reserved.
//

#import "SKSubWindowController.h"
#import <Quartz/Quartz.h>


@implementation SKSubWindowController
- (id)init{
    self = [super initWithWindowNibName:@"SubWindow" owner:self];
    
    if(self){
        subWindowControllers = [[NSMutableArray alloc] initWithCapacity:10];
    }
    
    return self;
}


- (void)setPdfDocument:(PDFDocument *)pdfDocument scaleFactor:(int)factor autoScales:(BOOL)autoScales{
    [self window];
    [pdfView setDocument:pdfDocument];
    [pdfView setScaleFactor:factor];
    [pdfView setAutoScales:autoScales];
}

- (void)goToPageNumber:(int)pageNum point:(NSPoint)locationInPageSpace{
    [pdfView becomeFirstResponder];

    PDFPage *page = [[pdfView document] pageAtIndex:pageNum];
    PDFDestination *dest = [[[PDFDestination alloc] initWithPage:page
                                                         atPoint:locationInPageSpace] autorelease];
    // Delayed to allow PDFView to finish its bookkeeping 
    // fixes bug of apparently ignoring the point but getting the page right.
    [pdfView performSelector:@selector(goToDestination:)
                  withObject:dest 
                  afterDelay:0.1];
    NSRect frame = [[self window] frame];
    frame.size.width = [pdfView rowSizeForPage:[dest page]].width;
    [[self window] setFrame:frame display:NO animate:NO];
}

@end
