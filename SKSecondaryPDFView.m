//
//  SKSecondaryPDFView.m
//  Skim
//
//  Created by Christiaan Hofman on 9/19/07.
/*
 This software is Copyright (c) 2007-2008
 Christiaan Hofman. All rights reserved.

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:

 - Redistributions of source code must retain the above copyright
   notice, this list of conditions and the following disclaimer.

 - Redistributions in binary form must reproduce the above copyright
    notice, this list of conditions and the following disclaimer in
    the documentation and/or other materials provided with the
    distribution.

 - Neither the name of Christiaan Hofman nor the names of any
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

#import "SKSecondaryPDFView.h"
#import "BDSKHeaderPopUpButton.h"
#import "NSScrollView_SKExtensions.h"
#import "PDFAnnotation_SKExtensions.h"
#import "PDFPage_SKExtensions.h"
#import "SKStringConstants.h"


@interface SKSecondaryPDFView (SKPrivate)

- (void)makePopUpButtons;
- (void)reloadPagePopUpButton;

- (void)setSynchronizeZoom:(BOOL)newSync adjustPopup:(BOOL)flag;
- (void)setAutoScales:(BOOL)newAuto adjustPopup:(BOOL)flag;
- (void)setScaleFactor:(float)factor adjustPopup:(BOOL)flag;

- (void)startObservingSynchronizedPDFView;
- (void)stopObservingSynchronizedPDFView;

- (void)handleSynchronizedScaleChangedNotification:(NSNotification *)notification;
- (void)handlePageChangedNotification:(NSNotification *)notification;
- (void)handleDocumentDidUnlockNotification:(NSNotification *)notification;

@end

@implementation SKSecondaryPDFView

/* For genstrings:
    NSLocalizedStringFromTable(@"=", @"ZoomValues", @"Zoom popup entry")
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
static NSString *SKDefaultScaleMenuLabels[] = {@"=", @"Auto", @"10%", @"20%", @"25%", @"35%", @"50%", @"60%", @"71%", @"85%", @"100%", @"120%", @"141%", @"170%", @"200%", @"300%", @"400%", @"600%", @"800%"};
static float SKDefaultScaleMenuFactors[] = {0.0, 0.0, 0.1, 0.2, 0.25, 0.35, 0.5, 0.6, 0.71, 0.85, 1.0, 1.2, 1.41, 1.7, 2.0, 3.0, 4.0, 6.0, 8.0};
static float SKPopUpMenuFontSize = 11.0;

- (void)commonInitialization {
    scalePopUpButton = nil;
    pagePopUpButton = nil;
    synchronizedPDFView = nil;
    synchronizeZoom = NO;
    
    [self makePopUpButtons];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handlePageChangedNotification:) 
                                                 name:PDFViewPageChangedNotification object:self];
}

- (id)initWithFrame:(NSRect)frameRect {
    if (self = [super initWithFrame:frameRect]) {
        [self commonInitialization];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)decoder {
    if (self = [super initWithCoder:decoder]) {
        [self commonInitialization];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [synchronizedPDFView release];
    [super dealloc];
}

- (void)setDocument:(PDFDocument *)document {
    if ([self document])
        [[NSNotificationCenter defaultCenter] removeObserver:self name:PDFViewPageChangedNotification object:[self document]];
    [super setDocument:document];
    [self reloadPagePopUpButton];
    if (document && [document isLocked])
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleDocumentDidUnlockNotification:) 
                                                     name:PDFDocumentDidUnlockNotification object:document];
}

- (void)setNeedsDisplayInRect:(NSRect)rect ofPage:(PDFPage *)page {
    NSRect aRect = [self convertRect:rect fromPage:page];
    float scale = [self scaleFactor];
	float maxX = ceilf(NSMaxX(aRect) + scale);
	float maxY = ceilf(NSMaxY(aRect) + scale);
	float minX = floorf(NSMinX(aRect) - scale);
	float minY = floorf(NSMinY(aRect) - scale);
	
    aRect = NSIntersectionRect([self bounds], NSMakeRect(minX, minY, maxX - minX, maxY - minY));
    if (NSIsEmptyRect(aRect) == NO)
        [self setNeedsDisplayInRect:aRect];
}

- (void)setNeedsDisplayForAnnotation:(PDFAnnotation *)annotation onPage:(PDFPage *)page {
    [self setNeedsDisplayInRect:[annotation displayRectForBounds:[annotation bounds]] ofPage:page];
}

#pragma mark Popup buttons

- (void)reloadPagePopUpButton {
    PDFDocument *pdfDoc = [self document];
    unsigned i, count = [pagePopUpButton numberOfItems];
    NSString *label;
    float width, maxWidth = 0.0;
    NSSize size = NSMakeSize(1000.0, 1000.0);
    NSDictionary *attrs = [NSDictionary dictionaryWithObjectsAndKeys:[pagePopUpButton font], NSFontAttributeName, nil];
    unsigned maxIndex = 0;
    
    while (count--)
        [pagePopUpButton removeItemAtIndex:count];
    
    if (count = [pdfDoc pageCount]) {
        for (i = 0; i < count; i++) {
            label = [[pdfDoc pageAtIndex:i] displayLabel];
            width = NSWidth([label boundingRectWithSize:size options:0 attributes:attrs]);
            if (width > maxWidth) {
                maxWidth = width;
                maxIndex = i;
            }
            [pagePopUpButton addItemWithTitle:label];
        }
        
        i = [pagePopUpButton indexOfSelectedItem];
        [pagePopUpButton selectItemAtIndex:maxIndex];
        [pagePopUpButton sizeToFit];
        [pagePopUpButton selectItemAtIndex:i];
        
        [pagePopUpButton selectItemAtIndex:[pdfDoc indexForPage:[self currentPage]]];
    }
}


- (void)makePopUpButtons {
    if (scalePopUpButton && pagePopUpButton)
        return;
    
    NSScrollView *scrollView = [self scrollView];
    [scrollView setHasHorizontalScroller:YES];
    NSControlSize controlSize = [[scrollView horizontalScroller] controlSize];
    
    if (scalePopUpButton == nil) {

        // create it        
        scalePopUpButton = [[BDSKHeaderPopUpButton allocWithZone:[self zone]] initWithFrame:NSMakeRect(0.0, 0.0, 1.0, 1.0) pullsDown:NO];
        
        [[scalePopUpButton cell] setControlSize:controlSize];

        // set a suitable font, the control size is 0, 1 or 2
        [scalePopUpButton setFont:[NSFont toolTipsFontOfSize: SKPopUpMenuFontSize - controlSize]];

        unsigned cnt, numberOfDefaultItems = (sizeof(SKDefaultScaleMenuLabels) / sizeof(NSString *));
        id curItem;
        NSString *label;
        float width, maxWidth = 0.0;
        NSSize size = NSMakeSize(1000.0, 1000.0);
        NSDictionary *attrs = [NSDictionary dictionaryWithObjectsAndKeys:[scalePopUpButton font], NSFontAttributeName, nil];
        unsigned maxIndex = 0;
        
        // fill it
        for (cnt = 0; cnt < numberOfDefaultItems; cnt++) {
            label = [[NSBundle mainBundle] localizedStringForKey:SKDefaultScaleMenuLabels[cnt] value:@"" table:@"ZoomValues"];
            width = NSWidth([label boundingRectWithSize:size options:0 attributes:attrs]);
            if (width > maxWidth) {
                maxWidth = width;
                maxIndex = cnt;
            }
            [scalePopUpButton addItemWithTitle:label];
            curItem = [scalePopUpButton itemAtIndex:cnt];
            [curItem setRepresentedObject:(SKDefaultScaleMenuFactors[cnt] > 0.0 ? [NSNumber numberWithFloat:SKDefaultScaleMenuFactors[cnt]] : nil)];
        }
        // select the appropriate item, adjusting the scaleFactor if necessary
        if([self autoScales])
            [self setScaleFactor:0.0 adjustPopup:YES];
        else
            [self setScaleFactor:[self scaleFactor] adjustPopup:YES];

        // Make sure the popup is big enough to fit the largest cell
        cnt = [scalePopUpButton indexOfSelectedItem];
        [scalePopUpButton selectItemAtIndex:maxIndex];
        [scalePopUpButton sizeToFit];
        [scalePopUpButton selectItemAtIndex:cnt];

		// don't let it become first responder
		[scalePopUpButton setRefusesFirstResponder:YES];

        // hook it up
        [scalePopUpButton setTarget:self];
        [scalePopUpButton setAction:@selector(scalePopUpAction:)];
        
    }
    
    if (pagePopUpButton == nil) {
        
        // create it        
        pagePopUpButton = [[BDSKHeaderPopUpButton allocWithZone:[self zone]] initWithFrame:NSMakeRect(0.0, 0.0, 1.0, 1.0) pullsDown:NO];
        
        [[pagePopUpButton cell] setControlSize:controlSize];

        // set a suitable font, the control size is 0, 1 or 2
        [pagePopUpButton setFont:[NSFont toolTipsFontOfSize: SKPopUpMenuFontSize - controlSize]];
		
        [self reloadPagePopUpButton];

		// don't let it become first responder
		[pagePopUpButton setRefusesFirstResponder:YES];
        
        // hook it up
        [pagePopUpButton setTarget:self];
        [pagePopUpButton setAction:@selector(pagePopUpAction:)];

        // put it in the scrollview
        [scrollView setPlacards:[NSArray arrayWithObjects:pagePopUpButton, scalePopUpButton, nil]];
        [scalePopUpButton release];
        [pagePopUpButton release];
    }
}

- (void)scalePopUpAction:(id)sender {
    NSNumber *selectedFactorObject = [[sender selectedItem] representedObject];
    if (selectedFactorObject)
        [self setScaleFactor:[selectedFactorObject floatValue] adjustPopup:NO];
    else if ([sender indexOfSelectedItem] == 0)
        [self setSynchronizeZoom:YES adjustPopup:NO];
    else
        [self setAutoScales:YES adjustPopup:NO];
}

- (void)pagePopUpAction:(id)sender {
    [self goToPage:[[self document] pageAtIndex:[sender indexOfSelectedItem]]];
}

- (PDFView *)synchronizedPDFView {
    return synchronizedPDFView;
}

- (void)setSynchronizedPDFView:(PDFView *)newSynchronizedPDFView {
    if (synchronizedPDFView != newSynchronizedPDFView) {
        if ([self synchronizeZoom])
            [self stopObservingSynchronizedPDFView];
        [synchronizedPDFView release];
        synchronizedPDFView = [newSynchronizedPDFView retain];
        if ([self synchronizeZoom])
            [self startObservingSynchronizedPDFView];
    }
}

- (BOOL)synchronizeZoom {
    return synchronizeZoom;
}

- (void)setSynchronizeZoom:(BOOL)newSync {
    [self setSynchronizeZoom:newSync adjustPopup:YES];
}

- (void)setSynchronizeZoom:(BOOL)newSync adjustPopup:(BOOL)flag {
    if (synchronizeZoom != newSync) {
        BOOL savedSwitching = switching;
        switching = YES;
        synchronizeZoom = newSync;
        if (newSync) {
            if ([self autoScales])
                [super setAutoScales:NO];
            [super setScaleFactor:synchronizedPDFView ? [synchronizedPDFView scaleFactor] : 1.0];
            [self startObservingSynchronizedPDFView];
            if (flag)
                [scalePopUpButton selectItemAtIndex:0];
        } else {
            [self stopObservingSynchronizedPDFView];
            [self setScaleFactor:[self scaleFactor] adjustPopup:flag];
        }
        switching = savedSwitching;
    }
}

- (void)setAutoScales:(BOOL)newAuto {
    BOOL savedSwitching = switching;
    switching = YES;
    if (savedSwitching)
        [super setAutoScales:newAuto];
    else
        [self setAutoScales:newAuto adjustPopup:YES];
    switching = savedSwitching;
}

- (void)setAutoScales:(BOOL)newAuto adjustPopup:(BOOL)flag {
    BOOL savedSwitching = switching;
    switching = YES;
    if ([self synchronizeZoom])
        [self setSynchronizeZoom:NO adjustPopup:NO];
    [super setAutoScales:newAuto];
    if (newAuto && flag)
        [scalePopUpButton selectItemAtIndex:1];
    switching = savedSwitching;
}

- (void)setScaleFactor:(float)newScaleFactor {
    BOOL savedSwitching = switching;
    switching = YES;
    if ([self synchronizeZoom] || savedSwitching)
        [super setScaleFactor:newScaleFactor];
    else
        [self setScaleFactor:newScaleFactor adjustPopup:YES];
    switching = savedSwitching;
}

- (void)setScaleFactor:(float)newScaleFactor adjustPopup:(BOOL)flag {
    BOOL savedSwitching = switching;
    switching = YES;
    if ([self synchronizeZoom])
        [self setSynchronizeZoom:NO adjustPopup:NO];
	
    if (flag) {
		if (newScaleFactor < 0.01) {
            newScaleFactor = 0.0;
        } else {
            unsigned cnt = 2, numberOfDefaultItems = (sizeof(SKDefaultScaleMenuFactors) / sizeof(float));
            
            // We only work with some preset zoom values, so choose one of the appropriate values
            while (cnt < numberOfDefaultItems - 1 && newScaleFactor > 0.5 * (SKDefaultScaleMenuFactors[cnt] + SKDefaultScaleMenuFactors[cnt + 1])) cnt++;
            [scalePopUpButton selectItemAtIndex:cnt];
            newScaleFactor = SKDefaultScaleMenuFactors[cnt];
        }
    }
    
    if (newScaleFactor < 0.01) {
        if ([self autoScales] == NO)
            [self setAutoScales:YES];
    } else {
        if ([self autoScales])
            [self setAutoScales:NO adjustPopup:NO];
        [super setScaleFactor:newScaleFactor];
    }
    switching = savedSwitching;
}

- (IBAction)zoomIn:(id)sender{
    int cnt = 2, numberOfDefaultItems = (sizeof(SKDefaultScaleMenuFactors) / sizeof(float));
    float scaleFactor = [self scaleFactor];
    
    // We only work with some preset zoom values, so choose one of the appropriate values (Fudge a little for floating point == to work)
    while (cnt < numberOfDefaultItems && scaleFactor * .99 > SKDefaultScaleMenuFactors[cnt]) cnt++;
    cnt++;
    while (cnt >= numberOfDefaultItems) cnt--;
    [self setScaleFactor:SKDefaultScaleMenuFactors[cnt] adjustPopup:YES];
}

- (IBAction)zoomOut:(id)sender{
    int cnt = 2, numberOfDefaultItems = (sizeof(SKDefaultScaleMenuFactors) / sizeof(float));
    float scaleFactor = [self scaleFactor];
    
    // We only work with some preset zoom values, so choose one of the appropriate values (Fudge a little for floating point == to work)
    while (cnt < numberOfDefaultItems && scaleFactor * .99 > SKDefaultScaleMenuFactors[cnt]) cnt++;
    cnt--;
    while (cnt < 2) cnt++;
    [self setScaleFactor:SKDefaultScaleMenuFactors[cnt] adjustPopup:YES];
}

- (BOOL)canZoomIn{
    if ([super canZoomIn] == NO)
        return NO;
    
    unsigned cnt = 2, numberOfDefaultItems = (sizeof(SKDefaultScaleMenuFactors) / sizeof(float));
    float scaleFactor = [self scaleFactor];
    
    // We only work with some preset zoom values, so choose one of the appropriate values (Fudge a little for floating point == to work)
    while (cnt < numberOfDefaultItems && scaleFactor * .99 > SKDefaultScaleMenuFactors[cnt]) cnt++;
    return cnt < numberOfDefaultItems - 1;
}

- (BOOL)canZoomOut{
    if ([super canZoomOut] == NO)
        return NO;
    
    unsigned cnt = 2, numberOfDefaultItems = (sizeof(SKDefaultScaleMenuFactors) / sizeof(float));
    float scaleFactor = [self scaleFactor];
    
    // We only work with some preset zoom values, so choose one of the appropriate values (Fudge a little for floating point == to work)
    while (cnt < numberOfDefaultItems && scaleFactor * .99 > SKDefaultScaleMenuFactors[cnt]) cnt++;
    return cnt > 2;
}


- (IBAction)toggleDisplayAsBookFromMenu:(id)sender {
    [self setDisplaysAsBook:[self displaysAsBook] == NO];
}

- (IBAction)toggleDisplayPageBreaksFromMenu:(id)sender {
    [self setDisplaysPageBreaks:[self displaysPageBreaks] == NO];
}

- (void)printDocument:(id)sender{
    id document = [[[self window] windowController] document];
    if ([document respondsToSelector:_cmd])
        [document printDocument:sender];
    else if ([[SKSecondaryPDFView superclass] instancesRespondToSelector:_cmd])
        [(id)super printDocument:sender];
}

- (NSMenu *)menuForEvent:(NSEvent *)theEvent {
    static NSSet *selectionActions = nil;
    if (selectionActions == nil)
        selectionActions = [[NSSet alloc] initWithObjects:@"_searchInSpotlight:", @"_searchInGoogle:", @"_searchInDictionary:", nil];
    NSMenu *menu = [super menuForEvent:theEvent];
    NSMenuItem *item;
    
    [self setCurrentSelection:nil];
    while ([menu numberOfItems]) {
        item = [menu itemAtIndex:0];
        if ([item isSeparatorItem] || [self validateMenuItem:item] == NO || [selectionActions containsObject:NSStringFromSelector([item action])])
            [menu removeItemAtIndex:0];
        else
            break;
    }
    
    int i = [menu indexOfItemWithTarget:self andAction:NSSelectorFromString(@"_setDoublePageScrolling:")];
    if (i == -1)
        i = [menu indexOfItemWithTarget:self andAction:NSSelectorFromString(@"_toggleContinuous:")];
    if (i != -1) {
        PDFDisplayMode displayMode = [self displayMode];
        [menu insertItem:[NSMenuItem separatorItem] atIndex:++i];
        if (displayMode == kPDFDisplayTwoUp || displayMode == kPDFDisplayTwoUpContinuous) { 
            item = [menu insertItemWithTitle:NSLocalizedString(@"Book Mode", @"Menu item title") action:@selector(toggleDisplayAsBookFromMenu:) keyEquivalent:@"" atIndex:++i];
            [item setTarget:self];
        }
        item = [menu insertItemWithTitle:NSLocalizedString(@"Page Breaks", @"Menu item title") action:@selector(toggleDisplayPageBreaksFromMenu:) keyEquivalent:@"" atIndex:++i];
        [item setTarget:self];
    }
    
    return menu;
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem {
    if ([menuItem action] == @selector(toggleDisplayAsBookFromMenu:)) {
        [menuItem setState:[self displaysAsBook] ? NSOnState : NSOffState];
        return YES;
    } else if ([menuItem action] == @selector(toggleDisplayPageBreaksFromMenu:)) {
        [menuItem setState:[self displaysPageBreaks] ? NSOnState : NSOffState];
        return YES;
    } else if ([menuItem action] == @selector(printDocument:)) {
        return [[self document] allowsPrinting];
    } else if ([[SKSecondaryPDFView superclass] instancesRespondToSelector:_cmd]) {
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
	if (scalePopUpButton) {
		[[scalePopUpButton cell] setControlSize:controlSize];
        [scalePopUpButton setFont:[NSFont toolTipsFontOfSize: SKPopUpMenuFontSize - controlSize]];
	}
	if (pagePopUpButton) {
		[[pagePopUpButton cell] setControlSize:controlSize];
        [pagePopUpButton setFont:[NSFont toolTipsFontOfSize: SKPopUpMenuFontSize - controlSize]];
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
    // ??? PDFView's delayed layout seems to reset the cursor to an arrow
    [self performSelector:@selector(mouseMoved:) withObject:theEvent afterDelay:0];
}

#pragma mark Notification handling

- (void)startObservingSynchronizedPDFView {
    if (synchronizedPDFView)
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleSynchronizedScaleChangedNotification:) 
                                                     name:PDFViewScaleChangedNotification object:synchronizedPDFView];
}

- (void)stopObservingSynchronizedPDFView {
    if (synchronizedPDFView)
        [[NSNotificationCenter defaultCenter] removeObserver:self name:PDFViewScaleChangedNotification object:synchronizedPDFView];
}

- (void)handlePageChangedNotification:(NSNotification *)notification {
    [pagePopUpButton selectItemAtIndex:[[self document] indexForPage:[self currentPage]]];
}

- (void)handleSynchronizedScaleChangedNotification:(NSNotification *)notification {
    if ([self synchronizeZoom])
        [self setScaleFactor:[synchronizedPDFView scaleFactor]];
}

- (void)handleDocumentDidUnlockNotification:(NSNotification *)notification {
    [self reloadPagePopUpButton];
    [[self scrollView] tile];
}

@end
