//
//  SKSecondaryPDFView.m
//  Skim
//
//  Created by Christiaan Hofman on 9/19/07.
/*
 This software is Copyright (c) 2007-2009
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
#import "NSScrollView_SKExtensions.h"
#import "PDFAnnotation_SKExtensions.h"
#import "PDFPage_SKExtensions.h"
#import "SKStringConstants.h"
#import "NSResponder_SKExtensions.h"
#import "NSEvent_SKExtensions.h"
#import "SKHighlightingPopUpButton.h"
#import "SKMainDocument.h"
#import "SKPDFSynchronizer.h"
#import "SKStringConstants.h"
#import "PDFSelection_SKExtensions.h"


@interface NSResponder (BDSKGesturesPrivate)
- (void)magnifyWithEvent:(NSEvent *)theEvent;
- (void)beginGestureWithEvent:(NSEvent *)theEvent;
- (void)endGestureWithEvent:(NSEvent *)theEvent;
@end

@interface NSEvent (BDSKGesturesPrivate)
- (CGFloat)magnification;
@end

@interface SKSecondaryPDFView (SKPrivate)

- (void)makePopUpButtons;
- (void)reloadPagePopUpButton;

- (void)setSynchronizeZoom:(BOOL)newSync adjustPopup:(BOOL)flag;
- (void)setAutoScales:(BOOL)newAuto adjustPopup:(BOOL)flag;
- (void)setScaleFactor:(CGFloat)factor adjustPopup:(BOOL)flag;

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
static CGFloat SKDefaultScaleMenuFactors[] = {0.0, 0.0, 0.1, 0.2, 0.25, 0.35, 0.5, 0.6, 0.71, 0.85, 1.0, 1.2, 1.41, 1.7, 2.0, 3.0, 4.0, 6.0, 8.0};

#define SKMinDefaultScaleMenuFactor (SKDefaultScaleMenuFactors[2])
#define SKDefaultScaleMenuFactorsCount (sizeof(SKDefaultScaleMenuFactors) / sizeof(CGFloat))

#define SKPopUpMenuFontSize ((CGFloat)11.0)

- (void)commonInitialization {
    scalePopUpButton = nil;
    pagePopUpButton = nil;
    synchronizedPDFView = nil;
    synchronizeZoom = NO;
    pinchZoomFactor = 1.0;
    
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
    SKDESTROY(synchronizedPDFView);
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
    CGFloat scale = [self scaleFactor];
	CGFloat maxX = SKCeil(NSMaxX(aRect) + scale);
	CGFloat maxY = SKCeil(NSMaxY(aRect) + scale);
	CGFloat minX = SKFloor(NSMinX(aRect) - scale);
	CGFloat minY = SKFloor(NSMinY(aRect) - scale);
	
    aRect = NSIntersectionRect([self bounds], NSMakeRect(minX, minY, maxX - minX, maxY - minY));
    if (NSIsEmptyRect(aRect) == NO)
        [self setNeedsDisplayInRect:aRect];
}

- (void)setNeedsDisplayForAnnotation:(PDFAnnotation *)annotation onPage:(PDFPage *)page {
    [self setNeedsDisplayInRect:[annotation displayRectForBounds:[annotation bounds]] ofPage:page];
}

#pragma mark Popup buttons

static void sizePopUpToItemAtIndex(NSPopUpButton *popUpButton, NSUInteger anIndex) {
    NSUInteger i = [popUpButton indexOfSelectedItem];
    [popUpButton selectItemAtIndex:anIndex];
    [popUpButton sizeToFit];
    NSSize frameSize = [popUpButton frame].size;
    frameSize.width -= 22.0 + 2 * [[popUpButton cell] controlSize];
    [popUpButton setFrameSize:frameSize];
    [popUpButton selectItemAtIndex:i];
}

- (void)reloadPagePopUpButton {
    PDFDocument *pdfDoc = [self document];
    NSUInteger i, count = [pagePopUpButton numberOfItems];
    NSString *label;
    CGFloat width, maxWidth = 0.0;
    NSSize size = NSMakeSize(1000.0, 1000.0);
    NSDictionary *attrs = [NSDictionary dictionaryWithObjectsAndKeys:[pagePopUpButton font], NSFontAttributeName, nil];
    NSUInteger maxIndex = 0;
    
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
        
        sizePopUpToItemAtIndex(pagePopUpButton, maxIndex);
        
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
        scalePopUpButton = [[SKHighlightingPopUpButton allocWithZone:[self zone]] initWithFrame:NSMakeRect(0.0, 0.0, 1.0, 1.0) pullsDown:NO];
        
        [[scalePopUpButton cell] setControlSize:controlSize];
		[scalePopUpButton setBordered:NO];
		[scalePopUpButton setEnabled:YES];
		[scalePopUpButton setRefusesFirstResponder:YES];
		[[scalePopUpButton cell] setUsesItemFromMenu:YES];

        // set a suitable font, the control size is 0, 1 or 2
        [scalePopUpButton setFont:[NSFont toolTipsFontOfSize: SKPopUpMenuFontSize - controlSize]];

        NSUInteger cnt, numberOfDefaultItems = SKDefaultScaleMenuFactorsCount;
        id curItem;
        NSString *label;
        CGFloat width, maxWidth = 0.0;
        NSSize size = NSMakeSize(1000.0, 1000.0);
        NSDictionary *attrs = [NSDictionary dictionaryWithObjectsAndKeys:[scalePopUpButton font], NSFontAttributeName, nil];
        NSUInteger maxIndex = 0;
        
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
            [curItem setRepresentedObject:(SKDefaultScaleMenuFactors[cnt] > 0.0 ? [NSNumber numberWithDouble:SKDefaultScaleMenuFactors[cnt]] : nil)];
        }
        // select the appropriate item, adjusting the scaleFactor if necessary
        if([self autoScales])
            [self setScaleFactor:0.0 adjustPopup:YES];
        else
            [self setScaleFactor:[self scaleFactor] adjustPopup:YES];

        // Make sure the popup is big enough to fit the largest cell
        sizePopUpToItemAtIndex(scalePopUpButton, maxIndex);

		// don't let it become first responder
		[scalePopUpButton setRefusesFirstResponder:YES];

        // hook it up
        [scalePopUpButton setTarget:self];
        [scalePopUpButton setAction:@selector(scalePopUpAction:)];
        
    }
    
    if (pagePopUpButton == nil) {
        
        // create it        
        pagePopUpButton = [[SKHighlightingPopUpButton allocWithZone:[self zone]] initWithFrame:NSMakeRect(0.0, 0.0, 1.0, 1.0) pullsDown:NO];
        
        [[pagePopUpButton cell] setControlSize:controlSize];
		[pagePopUpButton setBordered:NO];
		[pagePopUpButton setEnabled:YES];
		[pagePopUpButton setRefusesFirstResponder:YES];
		[[pagePopUpButton cell] setUsesItemFromMenu:YES];

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
        [self setScaleFactor:[selectedFactorObject doubleValue] adjustPopup:NO];
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

- (NSUInteger)lowerIndexForScaleFactor:(CGFloat)scaleFactor {
    NSUInteger i, count = SKDefaultScaleMenuFactorsCount;
    for (i = count - 1; i > 1; i--) {
        if (scaleFactor * 1.01 > SKDefaultScaleMenuFactors[i])
            return i;
    }
    return 2;
}

- (NSUInteger)upperIndexForScaleFactor:(CGFloat)scaleFactor {
    NSUInteger i, count = SKDefaultScaleMenuFactorsCount;
    for (i = 2; i < count; i++) {
        if (scaleFactor * 0.99 < SKDefaultScaleMenuFactors[i])
            return i;
    }
    return count - 1;
}

- (NSUInteger)indexForScaleFactor:(CGFloat)scaleFactor {
    NSUInteger lower = [self lowerIndexForScaleFactor:scaleFactor], upper = [self upperIndexForScaleFactor:scaleFactor];
    if (upper > lower && scaleFactor < 0.5 * (SKDefaultScaleMenuFactors[lower] + SKDefaultScaleMenuFactors[upper]))
        return lower;
    return upper;
}

- (void)setScaleFactor:(CGFloat)newScaleFactor {
    BOOL savedSwitching = switching;
    switching = YES;
    if ([self synchronizeZoom] || savedSwitching)
        [super setScaleFactor:newScaleFactor];
    else
        [self setScaleFactor:newScaleFactor adjustPopup:YES];
    switching = savedSwitching;
}

- (void)setScaleFactor:(CGFloat)newScaleFactor adjustPopup:(BOOL)flag {
    BOOL savedSwitching = switching;
    switching = YES;
    if ([self synchronizeZoom])
        [self setSynchronizeZoom:NO adjustPopup:NO];
    if (flag) {
		NSUInteger i = [self indexForScaleFactor:newScaleFactor];
        [scalePopUpButton selectItemAtIndex:i];
        newScaleFactor = SKDefaultScaleMenuFactors[i];
    }
    if ([self autoScales])
        [self setAutoScales:NO adjustPopup:NO];
    [super setScaleFactor:newScaleFactor];
    switching = savedSwitching;
}

- (IBAction)zoomIn:(id)sender{
    NSUInteger numberOfDefaultItems = SKDefaultScaleMenuFactorsCount;
    NSUInteger i = [self lowerIndexForScaleFactor:[self scaleFactor]];
    if (i < numberOfDefaultItems - 1) i++;
    [self setScaleFactor:SKDefaultScaleMenuFactors[i] adjustPopup:YES];
}

- (IBAction)zoomOut:(id)sender{
    NSUInteger i = [self upperIndexForScaleFactor:[self scaleFactor]];
    if (i > 2) i--;
    [self setScaleFactor:SKDefaultScaleMenuFactors[i] adjustPopup:YES];
}

- (BOOL)canZoomIn{
    if ([super canZoomIn] == NO)
        return NO;
    NSUInteger numberOfDefaultItems = SKDefaultScaleMenuFactorsCount;
    NSUInteger i = [self lowerIndexForScaleFactor:[self scaleFactor]];
    return i < numberOfDefaultItems - 1;
}

- (BOOL)canZoomOut{
    if ([super canZoomOut] == NO)
        return NO;
    NSUInteger i = [self upperIndexForScaleFactor:[self scaleFactor]];
    return i > 2;
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
        selectionActions = [[NSSet alloc] initWithObjects:@"copy:", @"_searchInSpotlight:", @"_searchInGoogle:", @"_searchInDictionary:", nil];
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
    
    NSInteger i = [menu indexOfItemWithTarget:self andAction:NSSelectorFromString(@"_setDoublePageScrolling:")];
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

#pragma mark Gestures

- (void)beginGestureWithEvent:(NSEvent *)theEvent {
    if ([[SKSecondaryPDFView superclass] instancesRespondToSelector:_cmd])
        [super beginGestureWithEvent:theEvent];
    pinchZoomFactor = 1.0;
}

- (void)endGestureWithEvent:(NSEvent *)theEvent {
    if (SKAbs(pinchZoomFactor - 1.0) > 0.1)
        [self setScaleFactor:SKMax(pinchZoomFactor * [self scaleFactor], SKMinDefaultScaleMenuFactor)];
    pinchZoomFactor = 1.0;
    if ([[SKSecondaryPDFView superclass] instancesRespondToSelector:_cmd])
        [super endGestureWithEvent:theEvent];
}

- (void)magnifyWithEvent:(NSEvent *)theEvent {
    if ([[NSUserDefaults standardUserDefaults] boolForKey:SKDisablePinchZoomKey] == NO && [theEvent respondsToSelector:@selector(magnification)]) {
        pinchZoomFactor *= 1.0 + SKMax(-0.5, SKMin(1.0 , [theEvent magnification]));
        CGFloat scaleFactor = pinchZoomFactor * [self scaleFactor];
        NSUInteger i = [self indexForScaleFactor:SKMax(scaleFactor, SKMinDefaultScaleMenuFactor)];
        if (i != [self indexForScaleFactor:[self scaleFactor]]) {
            [self setScaleFactor:SKDefaultScaleMenuFactors[i]];
            pinchZoomFactor = scaleFactor / [self scaleFactor];
        }
    }
}

#pragma mark Dragging

- (void)mouseDown:(NSEvent *)theEvent{
	if ((NSCommandKeyMask | NSShiftKeyMask) == ([theEvent modifierFlags] & (NSCommandKeyMask | NSShiftKeyMask))) {
        // eat up mouseDragged/mouseUp events, so we won't get their event handlers
        while (YES) {
            if ([[[self window] nextEventMatchingMask: NSLeftMouseUpMask | NSLeftMouseDraggedMask] type] == NSLeftMouseUp)
                break;
        }
        
        SKMainDocument *document = (SKMainDocument *)[[[self window] windowController] document];
        
        if ([document respondsToSelector:@selector(synchronizer)]) {
            
            NSPoint mouseLoc = [self convertPoint:[theEvent locationInWindow] fromView:nil];
            PDFPage *page = [self pageForPoint:mouseLoc nearest:YES];
            NSPoint location = [self convertPoint:mouseLoc toPage:page];
            NSUInteger pageIndex = [page pageIndex];
            PDFSelection *sel = [page selectionForLineAtPoint:location];
            NSRect rect = [sel hasCharacters] ? [sel boundsForPage:page] : NSMakeRect(location.x - 20.0, location.y - 5.0, 40.0, 10.0);
            
            [[document synchronizer] findFileAndLineForLocation:location inRect:rect pageBounds:[page boundsForBox:kPDFDisplayBoxMediaBox] atPageIndex:pageIndex];
        }
    } else {
        [[NSCursor closedHandCursor] push];
    }
}

- (void)mouseUp:(NSEvent *)theEvent{
    [NSCursor pop];
    [self mouseMoved:theEvent];
}

- (void)mouseMoved:(NSEvent *)theEvent {
	NSView *view = [self documentView];
    NSPoint mouseLoc = [view convertPoint:[theEvent locationInWindow] fromView:nil];
    if (NSMouseInRect(mouseLoc, [view visibleRect], [view isFlipped]))
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
				CGFloat	xDelta, yDelta;
				
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
