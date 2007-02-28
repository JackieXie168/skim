//  BDSKZoomableScrollView.h

//  Copyright (c) 2003, Apple Computer, Inc. All rights reserved.

// See legal notice below.

#import "BDSKZoomableScrollView.h"
#import <OmniAppKit/NSView-OAExtensions.h>
#import "BDSKHeaderPopUpButton.h"

@implementation BDSKZoomableScrollView

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
static float BDSKScaleMenuFontSize = 11.0;

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

- (void)awakeFromNib
{
    // make sure we have a horizontal scroller to show the popup
    [self setHasHorizontalScroller:YES];
    if([self respondsToSelector:@selector(setAutohidesScrollers:)])
       [self setAutohidesScrollers:NO];
}

#pragma mark Instance methods - scaling related

- (void)makeScalePopUpButton {
    if (scalePopUpButton == nil) {
        unsigned cnt, numberOfDefaultItems = (sizeof(BDSKDefaultScaleMenuLabels) / sizeof(NSString *));
        id curItem;

        // create it
        scalePopUpButton = [[BDSKHeaderPopUpButton allocWithZone:[self zone]] initWithFrame:NSMakeRect(0.0, 0.0, 1.0, 1.0) pullsDown:NO];
        [[scalePopUpButton cell] setControlSize:[[self horizontalScroller] controlSize]];
		
        // fill it
        for (cnt = 0; cnt < numberOfDefaultItems; cnt++) {
            [scalePopUpButton addItemWithTitle:NSLocalizedStringFromTable(BDSKDefaultScaleMenuLabels[cnt], @"ZoomValues", nil)];
            curItem = [scalePopUpButton itemAtIndex:cnt];
            if (BDSKDefaultScaleMenuFactors[cnt] > 0.0) {
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
    [super drawRect:rect];

    if ([scalePopUpButton superview]) {
        NSRect shadowRect = [scalePopUpButton frame];
        shadowRect.origin.x -= 1.0;
        shadowRect.origin.y -= 1.0;
        shadowRect.size.width += 1.0;
        shadowRect.size.height += 1.0;
        if (NSIntersectsRect(rect, shadowRect)) {
            [[NSColor lightGrayColor] set];
            NSRectFill(shadowRect);
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
	
	if (fabs(scaleFactor - newScaleFactor) > 0.01) {
		NSSize curDocFrameSize, newDocBoundsSize;
		NSView *documentView = [self documentView];
		NSView *clipView = [documentView superview];
        NSPoint scrollPoint = [documentView scrollPositionAsPercentage];
		
		scaleFactor = newScaleFactor;
		
		// Get the frame.  The frame must stay the same.
		curDocFrameSize = [clipView frame].size;
		
		// The new bounds will be frame divided by scale factor
		newDocBoundsSize.width = curDocFrameSize.width / scaleFactor;
		newDocBoundsSize.height = curDocFrameSize.height / scaleFactor;
		
		[clipView setBoundsSize:newDocBoundsSize];
		
		[documentView setScrollPositionAsPercentage:scrollPoint]; // maintain approximate scroll position
    }
}

- (IBAction)zoomToActualSize:(id)sender{
    [self setScaleFactor:1.0];
}

- (IBAction)zoomIn:(id)sender{
    int cnt = 0, numberOfDefaultItems = (sizeof(BDSKDefaultScaleMenuFactors) / sizeof(float));
    
    // We only work with some preset zoom values, so choose one of the appropriate values (Fudge a little for floating point == to work)
    while (cnt < numberOfDefaultItems && scaleFactor * .99 > BDSKDefaultScaleMenuFactors[cnt]) cnt++;
    cnt++;
    while (cnt >= numberOfDefaultItems) cnt--;
    [self setScaleFactor:BDSKDefaultScaleMenuFactors[cnt]];
}

- (IBAction)zoomOut:(id)sender{
    int cnt = 0, numberOfDefaultItems = (sizeof(BDSKDefaultScaleMenuFactors) / sizeof(float));
    
    // We only work with some preset zoom values, so choose one of the appropriate values (Fudge a little for floating point == to work)
    while (cnt < numberOfDefaultItems && scaleFactor * .99 > BDSKDefaultScaleMenuFactors[cnt]) cnt++;
    cnt--;
    if (cnt < 0) cnt++;
    [self setScaleFactor:BDSKDefaultScaleMenuFactors[cnt]];
}

- (BOOL)canZoomToActualSize{
    return fabs(scaleFactor - 1.0) > 0.01;
}

- (BOOL)canZoomIn{
    unsigned cnt = 0, numberOfDefaultItems = (sizeof(BDSKDefaultScaleMenuFactors) / sizeof(float));
    while (cnt < numberOfDefaultItems && scaleFactor * .99 > BDSKDefaultScaleMenuFactors[cnt]) cnt++;
    return cnt < numberOfDefaultItems - 1;
}

- (BOOL)canZoomOut{
    unsigned cnt = 0, numberOfDefaultItems = (sizeof(BDSKDefaultScaleMenuFactors) / sizeof(float));
    while (cnt < numberOfDefaultItems && scaleFactor * .99 > BDSKDefaultScaleMenuFactors[cnt]) cnt++;
    return cnt > 0;
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
        horizScrollerFrame.size.width = horizScrollerFrame.size.width - buttonFrame.size.width - 1.0;
        [horizScroller setFrameSize:horizScrollerFrame.size];

        buttonFrame.origin.x = NSMaxX(horizScrollerFrame) + 1.0;
        buttonFrame.origin.y = horizScrollerFrame.origin.y + 1.0;
        buttonFrame.size.height = horizScrollerFrame.size.height - 1.0;
        [scalePopUpButton setFrame:buttonFrame];
    }
}

- (BOOL)validatMenuItem:(NSMenuItem *)menuItem{
    if([menuItem action] == @selector(zoomIn:))
        return [self canZoomIn];
    else if([menuItem action] == @selector(zoomOut:))
        return [self canZoomOut];
    else if([menuItem action] == @selector(zoomToActualSize:))
        return [self canZoomToActualSize];
    else if ([[self superclass] instancesRespondToSelector:_cmd])
        return [super validateMenuItem:menuItem];
    return YES;
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
