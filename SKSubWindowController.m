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

- (NSString *)windowNibName {
    return @"SubWindow";
}

- (void)setPdfDocument:(PDFDocument *)pdfDocument scaleFactor:(int)factor autoScales:(BOOL)autoScales goToPageNumber:(int)pageNum point:(NSPoint)locationInPageSpace{
    [self window];
    [pdfView setDocument:pdfDocument];
    [pdfView setScaleFactor:factor];
    
    PDFPage *page = [pdfDocument pageAtIndex:pageNum];
    PDFDestination *dest = [[[PDFDestination alloc] initWithPage:page atPoint:locationInPageSpace] autorelease];
    NSRect frame = [[self window] frame];
    frame.size.width = [pdfView rowSizeForPage:[dest page]].width;
    [[self window] setFrame:frame display:NO animate:NO];
    
    [pdfView setAutoScales:autoScales];
    
    [pdfView becomeFirstResponder];
    // Delayed to allow PDFView to finish its bookkeeping 
    // fixes bug of apparently ignoring the point but getting the page right.
    [pdfView performSelector:@selector(goToDestination:) withObject:dest afterDelay:0.1];
}

- (void)windowWillClose:(NSNotification *)aNotification {
    [[[self window] parentWindow] removeChildWindow:[self window]];
}

@end
