//  DraggableScrollView.h

//  Copyright (c) 2003, Apple Computer, Inc. All rights reserved.

// See legal notice below.

#import "DraggableScrollView.h"
#import <OmniAppKit/NSView-OAExtensions.h>

@implementation DraggableScrollView

/* For genstrings:
    NSLocalizedStringFromTable(@"10%", @"ZoomValues", @"Zoom popup entry")
    NSLocalizedStringFromTable(@"25%", @"ZoomValues", @"Zoom popup entry")
    NSLocalizedStringFromTable(@"50%", @"ZoomValues", @"Zoom popup entry")
    NSLocalizedStringFromTable(@"75%", @"ZoomValues", @"Zoom popup entry")
    NSLocalizedStringFromTable(@"100%", @"ZoomValues", @"Zoom popup entry")
    NSLocalizedStringFromTable(@"128%", @"ZoomValues", @"Zoom popup entry")
    NSLocalizedStringFromTable(@"200%", @"ZoomValues", @"Zoom popup entry")
    NSLocalizedStringFromTable(@"400%", @"ZoomValues", @"Zoom popup entry")
    NSLocalizedStringFromTable(@"800%", @"ZoomValues", @"Zoom popup entry")
*/   
static NSString *BDSKDefaultScaleMenuLabels[] = {/* @"Set...", */ @"10%", @"25%", @"50%", @"75%", @"100%", @"128%", @"150%", @"200%", @"400%", @"800%"};
static float BDSKDefaultScaleMenuFactors[] = {/* 0.0, */ 0.1, 0.25, 0.5, 0.75, 1.0, 1.28, 1.5, 2.0, 4.0, 8.0};
static unsigned BDSKDefaultScaleMenuSelectedItemIndex = 4;
static float BDSKScaleMenuFontSize = 11.0;

#pragma mark Class method for cursor

// Cursors -- Return the open and closed grab hand cursors for dragging
// Needed as the system ones are 10.3 only
+ (NSCursor *) openHandCursor
{
    static NSCursor	*openHandCursor = nil;

    if (openHandCursor == nil)
    {
        NSImage		*image;

        image = [NSImage imageNamed: @"openHandCursor"];
        openHandCursor = [[NSCursor alloc] initWithImage: image
            hotSpot: NSMakePoint (8, 8)]; // guess that the center is good
    }

    return openHandCursor;
}

+ (NSCursor *) closedHandCursor
{
    static NSCursor	*closedHandCursor = nil;

    if (closedHandCursor == nil)
    {
        NSImage		*image;

        image = [NSImage imageNamed: @"closedHandCursor"];
        closedHandCursor = [[NSCursor alloc] initWithImage: image
            hotSpot: NSMakePoint (8, 8)]; // guess that the center is good
    }

    return closedHandCursor;
}


#pragma mark Instance methods

- (id)initWithFrame:(NSRect)rect {
    if (self = [super initWithFrame:rect]) {
		scaleFactor = 1.0;
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)coder {
    if (self = [super initWithCoder:coder]) {
		scaleFactor = 1.0;
    }
    return self;
}

- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}

#pragma mark Instance methods - drag-scrolling related

//	canScroll -- Return YES if the user could scroll.
- (BOOL) canScroll
{
    if ([[self documentView] frame].size.height > [self documentVisibleRect].size.height)
        return YES;
    if ([[self documentView] frame].size.width > [self documentVisibleRect].size.width)
        return YES;

    return NO;
}

- (void)awakeFromNib
{
	// make sure we have a horizontal scroller to show the popup
	[self setHasHorizontalScroller:YES];
    if([self respondsToSelector:@selector(setAutohidesScrollers:)])
	[self setAutohidesScrollers:NO];
	
	NSView *clipView = [[self documentView] superview];
	[clipView setPostsBoundsChangedNotifications:YES];
	[[NSNotificationCenter defaultCenter] addObserver:self
						selector:@selector(clipViewBoundsDidChange)
							name:NSViewBoundsDidChangeNotification
						  object:clipView];
}

- (void)clipViewBoundsDidChange
{
	if ([self canScroll]) {
        [self setDocumentCursor: [[self class] openHandCursor]];
    } else {
        [self setDocumentCursor: [NSCursor arrowCursor]];
	}
}

//	dragDocumentWithMouseDown: -- Given a mousedown event, which should be in
//	our document view, track the mouse to let the user drag the document.
- (BOOL) dragDocumentWithMouseDown: (NSEvent *) theEvent // RETURN: YES => user dragged (not clicked)
{
	NSPoint 		initialLocation;
    NSRect			visibleRect;
    BOOL			keepGoing;
    BOOL			result = NO;

	[[[self class] closedHandCursor] push];
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

	[NSCursor pop];
    return result;
}

#pragma mark Instance methods - scaling related

- (void)makeScalePopUpButton {
    if (scalePopUpButton == nil) {
        unsigned cnt, numberOfDefaultItems = (sizeof(BDSKDefaultScaleMenuLabels) / sizeof(NSString *));
        id curItem;

        // create it
        scalePopUpButton = [[NSPopUpButton allocWithZone:[self zone]] initWithFrame:NSMakeRect(0.0, 0.0, 1.0, 1.0) pullsDown:NO];
        [[scalePopUpButton cell] setBezelStyle:NSShadowlessSquareBezelStyle];
        [[scalePopUpButton cell] setArrowPosition:NSPopUpArrowAtBottom];
        [[scalePopUpButton cell] setControlSize:[[self horizontalScroller] controlSize]];
		
        // fill it
        for (cnt = 0; cnt < numberOfDefaultItems; cnt++) {
            [scalePopUpButton addItemWithTitle:NSLocalizedStringFromTable(BDSKDefaultScaleMenuLabels[cnt], @"ZoomValues", nil)];
            curItem = [scalePopUpButton itemAtIndex:cnt];
            if (BDSKDefaultScaleMenuFactors[cnt] != 0.0) {
                [curItem setRepresentedObject:[NSNumber numberWithFloat:BDSKDefaultScaleMenuFactors[cnt]]];
            }
        }
        // select the appropriate item, adjusting the scaleFactor if necessary
		[self setScaleFactor:scaleFactor adjustPopup:YES];

        // hook it up
        [scalePopUpButton setTarget:self];
        [scalePopUpButton setAction:@selector(scalePopUpAction:)];

        // set a suitable font, the control size is 0, 1 or 2
        [scalePopUpButton setFont:[NSFont toolTipsFontOfSize: BDSKScaleMenuFontSize - [[scalePopUpButton cell] controlSize]]];

        // Make sure the popup is big enough to fit the cells.
        [scalePopUpButton sizeToFit];

		// don't let it become first responder
		[scalePopUpButton setRefusesFirstResponder:YES];

        // put it in the scrollview
        [self addSubview:scalePopUpButton];
        [scalePopUpButton release];
    }
}

- (void)drawRect:(NSRect)rect {
    NSRect verticalLineRect;
    
    [super drawRect:rect];

    if ([scalePopUpButton superview]) {
        verticalLineRect = [scalePopUpButton frame];
        verticalLineRect.origin.x -= 1.0;
        verticalLineRect.size.width = 1.0;
        if (NSIntersectsRect(rect, verticalLineRect)) {
            [[NSColor blackColor] set];
            NSRectFill(verticalLineRect);
        }
    }
}

- (void)scalePopUpAction:(id)sender {
    NSNumber *selectedFactorObject = [[sender selectedCell] representedObject];
    
    if (selectedFactorObject == nil) {
        NSLog(@"Scale popup action: setting arbitrary zoom factors is not yet supported.");
        return;
    } else {
        [self setScaleFactor:[selectedFactorObject floatValue] adjustPopup:NO];
    }
}

- (float)scaleFactor {
    return scaleFactor;
}

- (void)setScaleFactor:(float)newScaleFactor {
	[self setScaleFactor:newScaleFactor adjustPopup:YES];
}

- (void)setScaleFactor:(float)newScaleFactor adjustPopup:(BOOL)flag {
	if (flag) {
		unsigned cnt = 0, numberOfDefaultItems = (sizeof(BDSKDefaultScaleMenuFactors) / sizeof(float));
		
		// We only work with some preset zoom values, so choose one of the appropriate values (Fudge a little for floating point == to work)
		while (cnt < numberOfDefaultItems && newScaleFactor * .99 > BDSKDefaultScaleMenuFactors[cnt]) cnt++;
		if (cnt == numberOfDefaultItems) cnt--;
		[scalePopUpButton selectItemAtIndex:cnt];
		newScaleFactor = BDSKDefaultScaleMenuFactors[cnt];
    }
	
	if (scaleFactor != newScaleFactor) {
		NSSize curDocFrameSize, newDocBoundsSize;
		NSView *clipView = [[self documentView] superview];
        NSPoint scrollPoint = [self scrollPositionAsPercentage];
		
		scaleFactor = newScaleFactor;
		
		// Get the frame.  The frame must stay the same.
		curDocFrameSize = [clipView frame].size;
		
		// The new bounds will be frame divided by scale factor
		newDocBoundsSize.width = curDocFrameSize.width / scaleFactor;
		newDocBoundsSize.height = curDocFrameSize.height / scaleFactor;
		
		[clipView setBoundsSize:newDocBoundsSize];
		
		[self setScrollPositionAsPercentage:scrollPoint]; // maintain approximate scroll position
    }
}

- (void)setHasHorizontalScroller:(BOOL)flag {
    if (!flag) [self setScaleFactor:1.0 adjustPopup:NO];
    [super setHasHorizontalScroller:flag];
}

- (void) tile
{
    // Let the superclass do most of the work.
    [super tile];

	if (![self hasHorizontalScroller]) {
        if (scalePopUpButton) [scalePopUpButton removeFromSuperview];
        scalePopUpButton = nil;
    } else {
		NSScroller *horizScroller;
		NSRect horizScrollerFrame, buttonFrame;
	
        if (!scalePopUpButton) [self makeScalePopUpButton];

        horizScroller = [self horizontalScroller];
        horizScrollerFrame = [horizScroller frame];
        buttonFrame = [scalePopUpButton frame];

        // Now we'll just adjust the horizontal scroller size and set the button size and location.
        horizScrollerFrame.size.width = horizScrollerFrame.size.width - buttonFrame.size.width;
        [horizScroller setFrameSize:horizScrollerFrame.size];

        buttonFrame.origin.x = NSMaxX(horizScrollerFrame);
        buttonFrame.size.height = horizScrollerFrame.size.height + 1.0;
        buttonFrame.origin.y = [self bounds].size.height - buttonFrame.size.height + 1.0;
        [scalePopUpButton setFrame:buttonFrame];
    }
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
