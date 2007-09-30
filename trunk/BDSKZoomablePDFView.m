//
//  BDSKZoomablePDFView.m
//  Bibdesk
//
//  Created by Adam Maxwell on 07/23/05.
/*
 This software is Copyright (c) 2005,2006
 Adam Maxwell. All rights reserved.
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:
 
 - Redistributions of source code must retain the above copyright
 notice, this list of conditions and the following disclaimer.
 
 - Redistributions in binary form must reproduce the above copyright
 notice, this list of conditions and the following disclaimer in
 the documentation and/or other materials provided with the
 distribution.
 
 - Neither the name of Adam Maxwell nor the names of any
 contributors may be used to endorse or promote products derived
 from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "BDSKZoomablePDFView.h"
#import "BDSKHeaderPopUpButton.h"
#import "NSScrollView_SKExtensions.h"


@interface PDFView (BDSKApplePrivateOverride)
- (void)adjustScrollbars:(id)obj;
@end

@implementation BDSKZoomablePDFView

/* For genstrings:
    NSLocalizedStringFromTable(@"Auto", @"ZoomValues", @"Zoom popup entry")
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
static NSString *BDSKDefaultScaleMenuLabels[] = {/* @"Set...", */ @"Auto", @"10%", @"25%", @"50%", @"75%", @"100%", @"128%", @"150%", @"200%", @"400%", @"800%"};
static float BDSKDefaultScaleMenuFactors[] = {/* 0.0, */ 0, 0.1, 0.25, 0.5, 0.75, 1.0, 1.28, 1.5, 2.0, 4.0, 8.0};
static float BDSKScaleMenuFontSize = 11.0;

#pragma mark Popup button

- (id)initWithFrame:(NSRect)frameRect {
    if (self = [super initWithFrame:frameRect]) {
        scalePopUpButton = nil;
        autoFitPage = nil;
        autoFitRect = NSZeroRect;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handlePDFViewFrameChangedNotification:) 
                                                     name:NSViewFrameDidChangeNotification object:self];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handlePDFViewFrameChangedNotification:) 
                                                     name:NSViewBoundsDidChangeNotification object:self];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)decoder {
    if (self = [super initWithCoder:decoder]) {
        scalePopUpButton = nil;
        autoFitPage = nil;
        autoFitRect = NSZeroRect;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handlePDFViewFrameChangedNotification:) 
                                                     name:NSViewFrameDidChangeNotification object:self];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handlePDFViewFrameChangedNotification:) 
                                                     name:NSViewBoundsDidChangeNotification object:self];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}

- (void)makeScalePopUpButton {
    
    if (scalePopUpButton == nil) {
        
        NSScrollView *scrollView = [self scrollView];
        [scrollView setAlwaysHasHorizontalScroller:YES];

        // create it        
        scalePopUpButton = [[BDSKHeaderPopUpButton allocWithZone:[self zone]] initWithFrame:NSMakeRect(0.0, 0.0, 1.0, 1.0) pullsDown:NO];
        
        NSControlSize controlSize = [[scrollView horizontalScroller] controlSize];
        [[scalePopUpButton cell] setControlSize:controlSize];
		
        unsigned cnt, numberOfDefaultItems = (sizeof(BDSKDefaultScaleMenuLabels) / sizeof(NSString *));
        id curItem;
        NSString *label;
        float width, maxWidth = 0.0;
        NSSize size = NSMakeSize(1000.0, 1000.0);
        NSDictionary *attrs = [[scalePopUpButton attributedTitle] attributesAtIndex:0 effectiveRange:NULL];
        unsigned maxIndex = 0;

        // set a suitable font, the control size is 0, 1 or 2
        [scalePopUpButton setFont:[NSFont toolTipsFontOfSize: BDSKScaleMenuFontSize - controlSize]];

        // fill it
        for (cnt = 0; cnt < numberOfDefaultItems; cnt++) {
            label = NSLocalizedStringFromTable(BDSKDefaultScaleMenuLabels[cnt], @"ZoomValues", nil);
            width = NSWidth([label boundingRectWithSize:size options:0 attributes:attrs]);
            if (width > maxWidth) {
                maxWidth = width;
                maxIndex = cnt;
            }
            [scalePopUpButton addItemWithTitle:label];
            curItem = [scalePopUpButton itemAtIndex:cnt];
            [curItem setRepresentedObject:(BDSKDefaultScaleMenuFactors[cnt] > 0.0 ? [NSNumber numberWithFloat:BDSKDefaultScaleMenuFactors[cnt]] : nil)];
        }
        // select the appropriate item, adjusting the scaleFactor if necessary
        if([self autoFits])
            [self setScaleFactor:0.0 adjustPopup:YES];
        else
            [self setScaleFactor:[self scaleFactor] adjustPopup:YES];

        // hook it up
        [scalePopUpButton setTarget:self];
        [scalePopUpButton setAction:@selector(scalePopUpAction:)];

		// don't let it become first responder
		[scalePopUpButton setRefusesFirstResponder:YES];

        // Make sure the popup is big enough to fit the largest cell
        cnt = [scalePopUpButton indexOfSelectedItem];
        [scalePopUpButton selectItemAtIndex:maxIndex];
        [scalePopUpButton sizeToFit];
        [scalePopUpButton selectItemAtIndex:cnt];

        // put it in the scrollview
        [scrollView addSubview:scalePopUpButton];
        [scalePopUpButton release];
    }
}

- (void)drawRect:(NSRect)rect {
    [self layoutScrollView];
    [super drawRect:rect];

    if ([scalePopUpButton superview]) {
        NSRect shadowRect = [scalePopUpButton frame];
        shadowRect.origin.x -= 1.0;
        shadowRect.origin.y -= 1.0;
        shadowRect.size.width += 1.0;
        shadowRect.size.height += 1.0;
		shadowRect = [self convertRect:shadowRect fromView:[scalePopUpButton superview]];
        if (NSIntersectsRect(rect, shadowRect)) {
            [[NSColor colorWithCalibratedWhite:0.75 alpha:1.0] set];
            NSRectFill(shadowRect);
        }
    }
}

- (void)handlePDFViewFrameChangedNotification:(NSNotification *)notification {
    if ([self autoFits]) {
        NSView *clipView = [[[self documentView] enclosingScrollView] contentView];
        NSRect rect = [self convertRect:[clipView visibleRect] fromView:clipView];
        BOOL scaleWidth = NSWidth(rect) / NSHeight(rect) < NSWidth(autoFitRect) / NSHeight(autoFitRect);
        float factor = scaleWidth ? NSWidth(rect) / NSWidth(autoFitRect) : NSHeight(rect) / NSHeight(autoFitRect);
        NSRect viewRect = scaleWidth ? NSInsetRect(autoFitRect, 0.0, 0.5 * (NSHeight(autoFitRect) - NSHeight(rect) / factor)) : NSInsetRect(autoFitRect, 0.5 * (NSWidth(autoFitRect) - NSWidth(rect) / factor), 0.0);
        [super setScaleFactor:factor];
        viewRect = [self convertRect:[self convertRect:viewRect fromPage:autoFitPage] toView:[self documentView]];
        [[self documentView] scrollRectToVisible:viewRect];
    }
}

- (void)resetAutoFitRectIfNeeded {
    if ([self autoFits]) {
        NSView *clipView = [[[self documentView] enclosingScrollView] contentView];
        autoFitPage = [self currentPage];
        autoFitRect = [self convertRect:[self convertRect:[clipView visibleRect] fromView:clipView] toPage:autoFitPage];
    }
}

- (void)scalePopUpAction:(id)sender {
    NSNumber *selectedFactorObject = [[sender selectedItem] representedObject];
    if(selectedFactorObject)
        [self setScaleFactor:[selectedFactorObject floatValue] adjustPopup:NO];
    else
        [self setAutoFits:YES adjustPopup:NO];
}

- (BOOL)autoFits {
    return autoFits;
}

- (void)setAutoFits:(BOOL)newAuto {
    [self setAutoFits:newAuto adjustPopup:YES];
}

- (void)setAutoFits:(BOOL)newAuto adjustPopup:(BOOL)flag {
    if (autoFits != newAuto) {
        autoFits = newAuto;
        if (autoFits) {
            [super setAutoScales:NO];
            [self resetAutoFitRectIfNeeded];
            if (flag)
                [scalePopUpButton selectItemAtIndex:0];
        } else {
            autoFitPage = nil;
            autoFitRect = NSZeroRect;
            if (flag)
                [self setScaleFactor:[self scaleFactor] adjustPopup:flag];
        }
    }
}

- (void)setScaleFactor:(float)newScaleFactor {
	[self setScaleFactor:newScaleFactor adjustPopup:YES];
}

- (void)setScaleFactor:(float)newScaleFactor adjustPopup:(BOOL)flag {
    
	if (flag) {
		if (newScaleFactor < 0.01) {
            newScaleFactor = 0.0;
        } else {
            unsigned cnt = 1, numberOfDefaultItems = (sizeof(BDSKDefaultScaleMenuFactors) / sizeof(float));
            
            // We only work with some preset zoom values, so choose one of the appropriate values
            while (cnt < numberOfDefaultItems - 1 && newScaleFactor > 0.5 * (BDSKDefaultScaleMenuFactors[cnt] + BDSKDefaultScaleMenuFactors[cnt + 1])) cnt++;
            [scalePopUpButton selectItemAtIndex:cnt];
            newScaleFactor = BDSKDefaultScaleMenuFactors[cnt];
        }
    }
    
    if(newScaleFactor < 0.01){
        [self setAutoFits:YES];
    }else{
        [self setAutoFits:NO adjustPopup:NO];
        [super setScaleFactor:newScaleFactor];
    }
}

- (void)setAutoScales:(BOOL)newAuto {}

- (IBAction)zoomIn:(id)sender{
    if([self autoFits]){
        [super zoomIn:sender];
        [self setAutoFits:NO adjustPopup:YES];
    }else{
        int cnt = 0, numberOfDefaultItems = (sizeof(BDSKDefaultScaleMenuFactors) / sizeof(float));
        float scaleFactor = [self scaleFactor];
        
        // We only work with some preset zoom values, so choose one of the appropriate values (Fudge a little for floating point == to work)
        while (cnt < numberOfDefaultItems && scaleFactor * .99 > BDSKDefaultScaleMenuFactors[cnt]) cnt++;
        cnt++;
        while (cnt >= numberOfDefaultItems) cnt--;
        [self setScaleFactor:BDSKDefaultScaleMenuFactors[cnt]];
    }
}

- (IBAction)zoomOut:(id)sender{
    if([self autoFits]){
        [super zoomOut:sender];
        [self setAutoFits:NO adjustPopup:YES];
    }else{
        int cnt = 0, numberOfDefaultItems = (sizeof(BDSKDefaultScaleMenuFactors) / sizeof(float));
        float scaleFactor = [self scaleFactor];
        
        // We only work with some preset zoom values, so choose one of the appropriate values (Fudge a little for floating point == to work)
        while (cnt < numberOfDefaultItems && scaleFactor * .99 > BDSKDefaultScaleMenuFactors[cnt]) cnt++;
        cnt--;
        if (cnt < 0) cnt++;
        [self setScaleFactor:BDSKDefaultScaleMenuFactors[cnt]];
    }
}

- (BOOL)canZoomIn{
    if ([super canZoomIn] == NO)
        return NO;
    unsigned cnt = 0, numberOfDefaultItems = (sizeof(BDSKDefaultScaleMenuFactors) / sizeof(float));
    float scaleFactor = [self scaleFactor];
    // We only work with some preset zoom values, so choose one of the appropriate values (Fudge a little for floating point == to work)
    while (cnt < numberOfDefaultItems && scaleFactor * .99 > BDSKDefaultScaleMenuFactors[cnt]) cnt++;
    return cnt < numberOfDefaultItems - 1;
}

- (BOOL)canZoomOut{
    if ([super canZoomOut] == NO)
        return NO;
    unsigned cnt = 0, numberOfDefaultItems = (sizeof(BDSKDefaultScaleMenuFactors) / sizeof(float));
    float scaleFactor = [self scaleFactor];
    // We only work with some preset zoom values, so choose one of the appropriate values (Fudge a little for floating point == to work)
    while (cnt < numberOfDefaultItems && scaleFactor * .99 > BDSKDefaultScaleMenuFactors[cnt]) cnt++;
    return cnt > 0;
}

- (void)goToPage:(PDFPage *)aPage {
    [super goToPage:aPage];
    [self resetAutoFitRectIfNeeded];
}

- (void)goToDestination:(PDFDestination *)destination {
    [super goToDestination:destination];
    [self resetAutoFitRectIfNeeded];
}

- (void)doAutoFit:(id)sender {
    [self setAutoFits:YES];
}

- (NSMenu *)menuForEvent:(NSEvent *)theEvent {
    NSMenu *menu = [super menuForEvent:theEvent];
    int i, count = [menu numberOfItems];
    
    for (i = 0; i < count; i++) {
        NSMenuItem *item = [menu itemAtIndex:i];
        if ([item action] == NSSelectorFromString(@"_setAutoSize:")) {
            [item setAction:@selector(doAutoFit:)];
            break;
        }
    }
    
    return menu;
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem {
    if ([menuItem action] == @selector(doAutoFit:)) {
        [menuItem setState:[self autoFits] ? NSOnState : NSOffState];
        return YES;
    } else if ([PDFView instancesRespondToSelector:_cmd]) {
        return [super validateMenuItem:menuItem];
    }
    return YES;
}

#pragma mark Scrollview

- (NSScrollView *)scrollView;
{
    return [[self documentView] enclosingScrollView];
}

- (void)setScrollerSize:(NSControlSize)controlSize;
{
    NSScrollView *scrollView = [[self documentView] enclosingScrollView];
    [scrollView setHasHorizontalScroller:YES];
    [scrollView setHasVerticalScroller:YES];
    [[scrollView horizontalScroller] setControlSize:controlSize];
    [[scrollView verticalScroller] setControlSize:controlSize];
	if(scalePopUpButton){
		[[scalePopUpButton cell] setControlSize:controlSize];
        [scalePopUpButton setFont:[NSFont toolTipsFontOfSize: BDSKScaleMenuFontSize - controlSize]];
	}
}

- (void)adjustScrollbars:(id)obj;
{
    // this private method is only called by PDFView, so super must implement it if it's called
    [super adjustScrollbars:obj];
    [self layoutScrollView];
    // be careful here; check the comment in -layoutScrollView before changing anything
}

- (void)layoutScrollView;
{
    NSScrollView *scrollView = [self scrollView];
    
    // Don't force scroller display on the scrollview; PDFView apparently uses a timer to call adjustScrollbars:, and preventing autohide will cause an endless loop if you zoom so that the vertical scroller is not displayed (regardless of whether we swizzle -[NSScrollView tile] or override -[PDFView adjustScrollbars:]).  Therefore, we always display the button,  even though it looks stupid without the scrollers.  Since it's not really readable anyway at 25%, this probably isn't a big deal, since this isn't supposed to be a thumbnail view.
    
    NSControlSize controlSize = NSRegularControlSize;
    
    if ([scrollView hasHorizontalScroller])
        controlSize = [[scrollView horizontalScroller] controlSize];
    else if ([scrollView hasVerticalScroller])
        controlSize = [[scrollView verticalScroller] controlSize];
    
    float scrollerWidth = [NSScroller scrollerWidthForControlSize:controlSize];
    
    if (!scalePopUpButton) [self makeScalePopUpButton];
    
    NSRect horizScrollerFrame, buttonFrame;
    buttonFrame = [scalePopUpButton frame];
    
    NSScroller *horizScroller = [scrollView horizontalScroller];
    
    if (horizScroller) {
        horizScrollerFrame = [horizScroller frame];
        
        // Now we'll just adjust the horizontal scroller size and set the button size and location.
        // Set it based on our frame, not the scroller's frame, since this gets called repeatedly.
        horizScrollerFrame.size.width = NSWidth([scrollView frame]) - NSWidth(buttonFrame) - scrollerWidth - 1.0;
        [horizScroller setFrameSize:horizScrollerFrame.size];
    }
    buttonFrame.size.height = scrollerWidth - 1.0;

    // @@ resolution independence: 2.0 may not work
    if ([scrollView isFlipped]) {
        buttonFrame.origin.x = NSMaxX([scrollView frame]) - scrollerWidth - NSWidth(buttonFrame);
        buttonFrame.origin.y = NSMaxY([scrollView frame]) - NSHeight(buttonFrame);            
    }
    else {
        buttonFrame.origin.x = NSMaxX([scrollView frame]) - scrollerWidth - NSWidth(buttonFrame);
        buttonFrame.origin.y = NSMinY([scrollView frame]);
    }
    [scalePopUpButton setFrame:buttonFrame];
}

#pragma mark Dragging

- (void)mouseDown:(NSEvent *)theEvent{
    [[NSCursor closedHandCursor] push];
}

- (void)mouseUp:(NSEvent *)theEvent{
    [NSCursor pop];
    [self mouseMoved:theEvent];
}

- (void)mouseMoved:(NSEvent *)theEvent {
	NSPoint mouseLoc = [[self documentView] convertPoint:[theEvent locationInWindow] fromView:nil];
    if (NSPointInRect(mouseLoc, [[self documentView] visibleRect]))
        [[NSCursor openHandCursor] set];
    else
        [[NSCursor arrowCursor] set];
}

- (void)mouseDragged:(NSEvent *)theEvent {
    [self dragWithEvent:theEvent];	
    // ??? PDFView's delayed layout seems to reset the cursor to an arrow
    [self performSelector:@selector(mouseMoved:) withObject:theEvent afterDelay:0];
}

- (void)dragWithEvent:(NSEvent *)theEvent {
	NSPoint initialLocation = [theEvent locationInWindow];
	NSRect visibleRect = [[self documentView] visibleRect];
	BOOL keepGoing = YES;
	
	while (keepGoing) {
		theEvent = [[self window] nextEventMatchingMask: NSLeftMouseUpMask | NSLeftMouseDraggedMask];
		switch ([theEvent type]) {
			case NSLeftMouseDragged:
            {
				NSPoint	newLocation;
				NSRect	newVisibleRect;
				float	xDelta, yDelta;
				
				newLocation = [theEvent locationInWindow];
				xDelta = initialLocation.x - newLocation.x;
				yDelta = initialLocation.y - newLocation.y;
				if ([self isFlipped])
					yDelta = -yDelta;
				
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
		} // end of switch (event type)
	} // end of mouse-tracking loop
    
    if ([self autoFits]) {
        NSView *clipView = [[[self documentView] enclosingScrollView] contentView];
        autoFitPage = [self currentPage];
        autoFitRect = [self convertRect:[self convertRect:[clipView visibleRect] fromView:clipView] toPage:autoFitPage];
    }
}

@end
