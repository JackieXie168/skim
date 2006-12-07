//  DraggableScrollView.h

//  Copyright (c) 2003, Apple Computer, Inc. All rights reserved.

// See legal notice below.

#import "DraggableScrollView.h"

@implementation DraggableScrollView

#pragma mark PRIVATE CLASS METHODS

//	dragCursor -- Return a cursor which hints that the user can drag.
//	FIXME: A hand would be better than this pointing finger.
+ (NSCursor *) dragCursor
{
    static NSCursor	*openHandCursor = nil;

    if (openHandCursor == nil)
    {
        NSImage		*image;

        image = [NSImage imageNamed: @"fingerCursor"];
        openHandCursor = [[NSCursor alloc] initWithImage: image
            hotSpot: NSMakePoint (8, 8)]; // guess that the center is good
    }

    return openHandCursor;
}


#pragma mark PRIVATE INSTANCE METHODS

//	canScroll -- Return YES if the user could scroll.
- (BOOL) canScroll
{
    if ([[self documentView] frame].size.height > [self documentVisibleRect].size.height)
        return YES;
    if ([[self documentView] frame].size.width > [self documentVisibleRect].size.width)
        return YES;

    return NO;
}


#pragma mark PUBLIC INSTANCE METHODS -- OVERRIDES FROM NSScrolLView

//	tile -- Override to update the document cursor.
- (void) tile
{
    [super tile];

    //	If the user can scroll right now, make our document cursor reflect that.
	if ([self canScroll])
        [self setDocumentCursor: [[self class] dragCursor]];
    else
        [self setDocumentCursor: [NSCursor arrowCursor]];
}


#pragma mark PUBLIC INSTANCE METHODS

//	dragDocumentWithMouseDown: -- Given a mousedown event, which should be in
//	our document view, track the mouse to let the user drag the document.
- (BOOL) dragDocumentWithMouseDown: (NSEvent *) theEvent // RETURN: YES => user dragged (not clicked)
{
	NSPoint 		initialLocation;
    NSRect			visibleRect;
    BOOL			keepGoing;
    BOOL			result = NO;

	initialLocation = [theEvent locationInWindow];
    visibleRect = [[self documentView] visibleRect];
    keepGoing = YES;

    while (keepGoing)
    {
        theEvent = [[self window] nextEventMatchingMask: NSLeftMouseUpMask | NSLeftMouseDraggedMask];
        switch ([theEvent type])
        {
            case NSLeftMouseDragged:
            {
                NSPoint	newLocation;
                NSRect	newVisibleRect;
                float	xDelta, yDelta;

                newLocation = [theEvent locationInWindow];
                xDelta = initialLocation.x - newLocation.x;
                yDelta = initialLocation.y - newLocation.y;

                //	This was an amusing bug: without checking for flipped,
                //	you could drag up, and the document would sometimes move down!
                if ([[self documentView] isFlipped])
                    yDelta = -yDelta;

                //	If they drag MORE than one pixel, consider it a drag
                if ( (abs (xDelta) > 1) || (abs (yDelta) > 1) )
                    result = YES;

                newVisibleRect = NSOffsetRect (visibleRect, xDelta, yDelta);
                [[self documentView] scrollRectToVisible: newVisibleRect];
            }
            break;

            case NSLeftMouseUp:
                keepGoing = NO;
                break;

            default:
                /* Ignore any other kind of event. */
                break;
        }								// end of switch (event type)
    }									// end of mouse-tracking loop

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
