//
//  SKSnapshotPDFView.m
//  Bibdesk
//
//  Created by Adam Maxwell on 07/23/05.
/*
 This software is Copyright (c) 2005-2008
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

#import "SKSnapshotPDFView.h"
#import "BDSKHeaderPopUpButton.h"
#import "NSScrollView_SKExtensions.h"
#import "NSResponder_SKExtensions.h"
#import "NSEvent_SKExtensions.h"


@implementation SKSnapshotPDFView

/* For genstrings:
    NSLocalizedStringFromTable(@"Auto", @"ZoomValues", @"Zoom popup entry")
    NSLocalizedStringFromTable(@"10%", @"ZoomValues", @"Zoom popup entry")
    NSLocalizedStringFromTable(@"20%", @"ZoomValues", @"Zoom popup entry")
    NSLocalizedStringFromTable(@"25%", @"ZoomValues", @"Zoom popup entry")
    NSLocalizedStringFromTable(@"35%", @"ZoomValues", @"Zoom popup entry")
    NSLocalizedStringFromTable(@"50%", @"ZoomValues", @"Zoom popup entry")
    NSLocalizedStringFromTable(@"60%", @"ZoomValues", @"Zoom popup entry")
    NSLocalizedStringFromTable(@"71%", @"ZoomValues", @"Zoom popup entry")
    NSLocalizedStringFromTable(@"85%", @"ZoomValues", @"Zoom popup entry")
    NSLocalizedStringFromTable(@"100%", @"ZoomValues", @"Zoom popup entry")
    NSLocalizedStringFromTable(@"120%", @"ZoomValues", @"Zoom popup entry")
    NSLocalizedStringFromTable(@"141%", @"ZoomValues", @"Zoom popup entry")
    NSLocalizedStringFromTable(@"170%", @"ZoomValues", @"Zoom popup entry")
    NSLocalizedStringFromTable(@"200%", @"ZoomValues", @"Zoom popup entry")
    NSLocalizedStringFromTable(@"300%", @"ZoomValues", @"Zoom popup entry")
    NSLocalizedStringFromTable(@"400%", @"ZoomValues", @"Zoom popup entry")
    NSLocalizedStringFromTable(@"600%", @"ZoomValues", @"Zoom popup entry")
    NSLocalizedStringFromTable(@"800%", @"ZoomValues", @"Zoom popup entry")
*/   
static NSString *BDSKDefaultScaleMenuLabels[] = {@"Auto", @"10%", @"20%", @"25%", @"35%", @"50%", @"60%", @"71%", @"85%", @"100%", @"120%", @"141%", @"170%", @"200%", @"300%", @"400%", @"600%", @"800%"};
static float BDSKDefaultScaleMenuFactors[] = {0.0, 0.1, 0.2, 0.25, 0.35, 0.5, 0.6, 0.71, 0.85, 1.0, 1.2, 1.41, 1.7, 2.0, 3.0, 4.0, 6.0, 8.0};
static float BDSKScaleMenuFontSize = 11.0;

#pragma mark Popup button

- (id)initWithFrame:(NSRect)frameRect {
    if (self = [super initWithFrame:frameRect]) {
        scalePopUpButton = nil;
        autoFitPage = nil;
        autoFitRect = NSZeroRect;
        pinchZoomFactor = 1.0;
        
        [self makeScalePopUpButton];
        
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
        pinchZoomFactor = 1.0;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handlePDFViewFrameChangedNotification:) 
                                                     name:NSViewFrameDidChangeNotification object:self];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handlePDFViewFrameChangedNotification:) 
                                                     name:NSViewBoundsDidChangeNotification object:self];
        [self makeScalePopUpButton];
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
        [scrollView setHasHorizontalScroller:YES];
        
        // create it        
        scalePopUpButton = [[BDSKHeaderPopUpButton allocWithZone:[self zone]] initWithFrame:NSMakeRect(0.0, 0.0, 1.0, 1.0) pullsDown:NO];
        
        NSControlSize controlSize = [[scrollView horizontalScroller] controlSize];
        [[scalePopUpButton cell] setControlSize:controlSize];
        
        // set a suitable font, the control size is 0, 1 or 2
        [scalePopUpButton setFont:[NSFont toolTipsFontOfSize: BDSKScaleMenuFontSize - controlSize]];
		
        unsigned cnt, numberOfDefaultItems = (sizeof(BDSKDefaultScaleMenuLabels) / sizeof(NSString *));
        id curItem;
        NSString *label;
        float width, maxWidth = 0.0;
        NSSize size = NSMakeSize(1000.0, 1000.0);
        NSDictionary *attrs = [NSDictionary dictionaryWithObjectsAndKeys:[scalePopUpButton font], NSFontAttributeName, nil];
        unsigned maxIndex = 0;
        
        // fill it
        for (cnt = 0; cnt < numberOfDefaultItems; cnt++) {
            label = [[NSBundle mainBundle] localizedStringForKey:BDSKDefaultScaleMenuLabels[cnt] value:@"" table:@"ZoomValues"];
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
        [scrollView setPlacards:[NSArray arrayWithObject:scalePopUpButton]];
        [scalePopUpButton release];
    }
}

- (NSPopUpButton *)scalePopUpButton {
    return scalePopUpButton;
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

- (unsigned int)lowerIndexForScaleFactor:(float)scaleFactor {
    unsigned int i, count = (sizeof(BDSKDefaultScaleMenuFactors) / sizeof(float));
    for (i = count - 1; i > 0; i--) {
        if (scaleFactor * 1.01 > BDSKDefaultScaleMenuFactors[i])
            return i;
    }
    return 1;
}

- (unsigned int)upperIndexForScaleFactor:(float)scaleFactor {
    unsigned int i, count = (sizeof(BDSKDefaultScaleMenuFactors) / sizeof(float));
    for (i = 1; i < count; i++) {
        if (scaleFactor * 0.99 < BDSKDefaultScaleMenuFactors[i])
            return i;
    }
    return count - 1;
}

- (unsigned int)indexForScaleFactor:(float)scaleFactor {
    unsigned int lower = [self lowerIndexForScaleFactor:scaleFactor], upper = [self upperIndexForScaleFactor:scaleFactor];
    if (upper > lower && scaleFactor < 0.5 * (BDSKDefaultScaleMenuFactors[lower] + BDSKDefaultScaleMenuFactors[upper]))
        return lower;
    return upper;
}

- (void)setScaleFactor:(float)newScaleFactor {
	[self setScaleFactor:newScaleFactor adjustPopup:YES];
}

- (void)setScaleFactor:(float)newScaleFactor adjustPopup:(BOOL)flag {
    
	if (flag) {
		if (newScaleFactor < 0.01) {
            newScaleFactor = 0.0;
        } else {
            unsigned int i = [self indexForScaleFactor:newScaleFactor];
            [scalePopUpButton selectItemAtIndex:i];
            newScaleFactor = BDSKDefaultScaleMenuFactors[i];
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
        unsigned int numberOfDefaultItems = (sizeof(BDSKDefaultScaleMenuFactors) / sizeof(float));
        unsigned int i = [self lowerIndexForScaleFactor:[self scaleFactor]];
        if (i < numberOfDefaultItems - 1) i++;
        [self setScaleFactor:BDSKDefaultScaleMenuFactors[i]];
    }
}

- (IBAction)zoomOut:(id)sender{
    if([self autoFits]){
        [super zoomOut:sender];
        [self setAutoFits:NO adjustPopup:YES];
    }else{
        unsigned int i = [self upperIndexForScaleFactor:[self scaleFactor]];
        if (i > 1) i--;
        [self setScaleFactor:BDSKDefaultScaleMenuFactors[i]];
    }
}

- (BOOL)canZoomIn{
    if ([super canZoomIn] == NO)
        return NO;
    unsigned int numberOfDefaultItems = (sizeof(BDSKDefaultScaleMenuFactors) / sizeof(float));
    unsigned int i = [self lowerIndexForScaleFactor:[self scaleFactor]];
    return i < numberOfDefaultItems - 1;
}

- (BOOL)canZoomOut{
    if ([super canZoomOut] == NO)
        return NO;
    unsigned int i = [self upperIndexForScaleFactor:[self scaleFactor]];
    return i > 1;
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

- (void)printDocument:(id)sender{
    id document = [[[self window] windowController] document];
    if ([document respondsToSelector:_cmd])
        [document printDocument:sender];
    else if ([[SKSnapshotPDFView superclass] instancesRespondToSelector:_cmd])
        [(id)super printDocument:sender];
}

- (NSMenu *)menuForEvent:(NSEvent *)theEvent {
    static NSSet *selectionActions = nil;
    if (selectionActions == nil)
        selectionActions = [[NSSet alloc] initWithObjects:@"copy:", @"_searchInSpotlight:", @"_searchInGoogle:", @"_searchInDictionary:", nil];
    NSMenu *menu = [super menuForEvent:theEvent];
    
    [self setCurrentSelection:nil];
    while ([menu numberOfItems]) {
        NSMenuItem *item = [menu itemAtIndex:0];
        if ([item isSeparatorItem] || [self validateMenuItem:item] == NO || [selectionActions containsObject:NSStringFromSelector([item action])])
            [menu removeItemAtIndex:0];
        else
            break;
    }
    
    unsigned int i = [menu indexOfItemWithTarget:self andAction:NSSelectorFromString(@"_setAutoSize:")];
    if (i != NSNotFound)
        [[menu itemAtIndex:i] setAction:@selector(doAutoFit:)];
    
    return menu;
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem {
    if ([menuItem action] == @selector(doAutoFit:)) {
        [menuItem setState:[self autoFits] ? NSOnState : NSOffState];
        return YES;
    } else if ([menuItem action] == @selector(printDocument:)) {
        return [[self document] allowsPrinting];
    } else if ([[SKSnapshotPDFView superclass] instancesRespondToSelector:_cmd]) {
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

#pragma mark Gestures

- (void)beginGestureWithEvent:(NSEvent *)theEvent {
    if ([[SKSnapshotPDFView superclass] instancesRespondToSelector:_cmd])
        [super beginGestureWithEvent:theEvent];
    pinchZoomFactor = 1.0;
}

- (void)endGestureWithEvent:(NSEvent *)theEvent {
    if (fabsf(pinchZoomFactor - 1.0) > 0.1)
        [self setScaleFactor:fmaxf(pinchZoomFactor * [self scaleFactor], BDSKDefaultScaleMenuFactors[1])];
    pinchZoomFactor = 1.0;
    if ([[SKSnapshotPDFView superclass] instancesRespondToSelector:_cmd])
        [super endGestureWithEvent:theEvent];
}

- (void)magnifyWithEvent:(NSEvent *)theEvent {
    if ([theEvent respondsToSelector:@selector(magnification)]) {
        pinchZoomFactor *= 1.0 + fmaxf(-0.5, fminf(1.0 , [theEvent magnification]));
        float scaleFactor = pinchZoomFactor * [self scaleFactor];
        unsigned int i = [self indexForScaleFactor:fmaxf(scaleFactor, BDSKDefaultScaleMenuFactors[1])];
        if (i != [self indexForScaleFactor:[self scaleFactor]]) {
            [self setScaleFactor:BDSKDefaultScaleMenuFactors[i]];
            pinchZoomFactor = scaleFactor / [self scaleFactor];
        }
    }
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
