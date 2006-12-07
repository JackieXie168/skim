//  PDFImageView.m

//  Copyright (c) 2003, Apple Computer, Inc. All rights reserved.

// See legal notice below.

#import "PDFImageView.h"
#import "DraggableScrollView.h"


@implementation PDFImageView

#pragma mark PRIVATE INSTANCE METHODS

//	pdfRep -- Return the image-representation used for PDFs. This
//	representation can tell us things like the PDF's page count.
- (NSPDFImageRep *) pdfRep
{
    //	Assume our sole representation is the PDF representation.
    return [[[self image] representations] lastObject];
}


#pragma mark PUBLIC INSTANCE METHODS

//	loadFromPath: -- Load the PDF at the specified path into the view.
//	This automatically resizes the view to fit all pages of the document.
- (void) loadFromPath: (NSString *) path
{
    NSPDFImageRep	*pdfRep;
    NSImage			*pdfImage;
    NSRect			frame;

    //	Load the file into an image-representation,
    //	then create an image and add the representation to it.
    pdfRep = [NSPDFImageRep imageRepWithContentsOfFile: path];
    pdfImage = [[[NSImage alloc] init] autorelease];
    [pdfImage addRepresentation: pdfRep];

    //	Figure our frame by getting the bounds, which is really the size
    //	of one page, and multiplying the height by the page count.
    frame = [pdfRep bounds];
    frame.size.height *= [pdfRep pageCount];

    //	Install the image (remember, we're an NSImageView subclass)
    [self setImage: pdfImage];

    //	Set our frame to match the PDF's full height (all pages)
    //	(don't involve our override of -setFrame:, or things won't work right)
    [super setFrame: frame];

    //	Always scroll to show the top of the image
    if ([self isFlipped])
        [self scrollPoint: NSMakePoint (0, 0)];
    else
        [self scrollPoint: NSMakePoint (0, frame.size.height)];
}


#pragma mark PUBLIC INSTANCE METHODS -- NSView OVERRIDES

//	drawRect: -- Display all pages of the PDF document.
- (void) drawRect: (NSRect) rect
{
    NSPDFImageRep	*rep;
    int				pageCount, pageNumber;
    NSRect			onePageBounds;

    //	Apparently, a PDF doesn't always draw its margins, so make them white
    //	by drawing our entire background as white.
    [[NSColor whiteColor] set];
    NSRectFill (rect);

    //	Get the information from the PDF image representation:
    //	how many pages, and how large is each one?
    rep = [self pdfRep];
    pageCount = [rep pageCount];

    //	Iterate through all pages
    for (pageNumber = 0; pageNumber < pageCount; pageNumber++)
    {
        //	Use the printing code (which uses one-based numbering) to find where
        //	this page appears.
        onePageBounds = [self rectForPage: (1+pageNumber)];

        //	Draw this page only if some of its bounds overlap the drawing area
        if (! NSIntersectsRect (rect, onePageBounds))
            continue;

        //	Draw by setting the image representation to the correct page,
        //	then having the image representation draw.
        [rep setCurrentPage: pageNumber];
        [rep drawInRect: onePageBounds];
    }
}

//	mouseDown: -- If we have an enclosing scroll-view which knows how to drag,
//	hand the event off to that scroll-view.
- (void) mouseDown:(NSEvent *) theEvent
{
    NSScrollView	*scrollView;

    scrollView = [self enclosingScrollView];

    if ([scrollView respondsToSelector: @selector(dragDocumentWithMouseDown:)])
        [(DraggableScrollView*)scrollView dragDocumentWithMouseDown: theEvent];
    else
        [super mouseDown: theEvent];
}

//	-setFrameSize: -- Override this method to make sure we keep our aspect ratio.
//	This assumes -setFrameSize: is a primitive method (i.e., -setFrame: invokes it)
- (void) setFrameSize: (NSSize) newSize
{
    NSSize	PDFsize;
    float	correctHeight;

    PDFsize = [[self pdfRep] bounds].size;
    correctHeight = [[self pdfRep] pageCount] * (PDFsize.height/PDFsize.width) * newSize.width;
    correctHeight = ceil (correctHeight); // not sure we need this

    //	If the height's almost right, don't fuss with it.
    if (abs (correctHeight - newSize.height) > 3.0)
        newSize.height = correctHeight;

    [super setFrameSize: newSize];
}


#pragma mark PUBLIC INSTANCE METHODS -- NSView OVERRIDES FOR PRINTING

- (BOOL) knowsPageRange: (NSRangePointer) range
{
    range->location = 1;				// page numbers are one-based
    range->length = [[self pdfRep] pageCount];

    return YES;
}

- (NSRect) rectForPage: (int) pageNumber // INPUT: ONE-based page number
{
    NSPDFImageRep	*rep;
    int				pageCount;
    NSRect			result;

    rep = [self pdfRep];
    pageCount = [rep pageCount];

    //	Start at the first page
    result = [rep bounds];
    if (! [self isFlipped])
        result = NSOffsetRect (result, 0.0, (pageCount-1)*result.size.height);

    //	Move to the N'th page
    if ([self isFlipped])
        result = NSOffsetRect (result, 0.0, (pageNumber-1) * result.size.height);
    else
        result = NSOffsetRect (result, 0.0, - (pageNumber-1) * result.size.height);

    return result;
}

@end



/*
 IMPORTANT:  This Apple software is supplied to you by Apple Computer, Inc. ("Apple") in
 consideration of your agreement to the following terms, and your use, installation, 
 modification or redistribution of this Apple software constitutes acceptance of these 
 terms.  If you do not agree with these terms, please do not use, install, modify or 
 redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and subject to these 
 terms, Apple grants you a personal, non-exclusive license, under Apple's copyrights in 
 this original Apple software (the "Apple Software"), to use, reproduce, modify and 
 redistribute the Apple Software, with or without modifications, in source and/or binary 
 forms; provided that if you redistribute the Apple Software in its entirety and without 
 modifications, you must retain this notice and the following text and disclaimers in all 
 such redistributions of the Apple Software.  Neither the name, trademarks, service marks 
 or logos of Apple Computer, Inc. may be used to endorse or promote products derived from 
 the Apple Software without specific prior written permission from Apple. Except as expressly
 stated in this notice, no other rights or licenses, express or implied, are granted by Apple
 herein, including but not limited to any patent rights that may be infringed by your 
 derivative works or by other works in which the Apple Software may be incorporated.
 
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE MAKES NO WARRANTIES, 
 EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, 
 MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS 
 USE AND OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
 
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL OR CONSEQUENTIAL 
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS 
 OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, 
 REPRODUCTION, MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED AND 
 WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE), STRICT LIABILITY OR 
 OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/
