//
//  SKSnapshotPDFView.m
//  Skim
//
//  Created by Adam Maxwell on 07/23/05.
/*
 This software is Copyright (c) 2005-2014
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
#import "NSScrollView_SKExtensions.h"
#import "NSResponder_SKExtensions.h"
#import "NSEvent_SKExtensions.h"
#import "SKHighlightingPopUpButton.h"
#import "PDFPage_SKExtensions.h"
#import "SKMainDocument.h"
#import "SKPDFSynchronizer.h"
#import "SKStringConstants.h"
#import "PDFSelection_SKExtensions.h"
#import "PDFView_SKExtensions.h"
#import "NSGeometry_SKExtensions.h"


@interface SKSnapshotPDFView (SKPrivate)

- (void)makeScalePopUpButton;

- (void)resetAutoFitRectIfNeeded;

- (void)scalePopUpAction:(id)sender;

- (void)setAutoFits:(BOOL)newAuto adjustPopup:(BOOL)flag;
- (void)setScaleFactor:(CGFloat)factor adjustPopup:(BOOL)flag;

- (void)handlePDFViewFrameChangedNotification:(NSNotification *)notification;
- (void)handlePDFContentViewFrameChangedNotification:(NSNotification *)notification;
- (void)handlePDFContentViewFrameChangedDelayedNotification:(NSNotification *)notification;

@end

@implementation SKSnapshotPDFView

@synthesize autoFits;

#define SKPDFContentViewChangedNotification @"SKPDFContentViewChangedNotification"

static NSString *SKDefaultScaleMenuLabels[] = {@"Auto", @"10%", @"20%", @"25%", @"35%", @"50%", @"60%", @"71%", @"85%", @"100%", @"120%", @"141%", @"170%", @"200%", @"300%", @"400%", @"600%", @"800%", @"1000%", @"1200%", @"1400%", @"1700%", @"2000%"};
static CGFloat SKDefaultScaleMenuFactors[] = {0.0, 0.1, 0.2, 0.25, 0.35, 0.5, 0.6, 0.71, 0.85, 1.0, 1.2, 1.41, 1.7, 2.0, 3.0, 4.0, 6.0, 8.0, 10.0, 12.0, 14.0, 17.0, 20.0};

#define SKMinDefaultScaleMenuFactor (SKDefaultScaleMenuFactors[1])
#define SKDefaultScaleMenuFactorsCount (sizeof(SKDefaultScaleMenuFactors) / sizeof(CGFloat))

#define SKScaleMenuFontSize ((CGFloat)11.0)

- (void)drawPage:(PDFPage *)pdfPage {
    NSImageInterpolation interpolation = [[NSUserDefaults standardUserDefaults] integerForKey:SKImageInterpolationKey];
    // smooth graphics when anti-aliasing
    if (interpolation == NSImageInterpolationDefault)
        interpolation = [self shouldAntiAlias] ? NSImageInterpolationHigh : NSImageInterpolationNone;
    [[NSGraphicsContext currentContext] setImageInterpolation:interpolation];
    [super drawPage:pdfPage];
    [[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationDefault];
}

#pragma mark Popup button

- (void)commonInitialization {
    scalePopUpButton = nil;
    autoFitPage = nil;
    autoFitRect = NSZeroRect;
    didMagnify = NO;
    
    [self makeScalePopUpButton];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handlePDFViewFrameChangedNotification:) 
                                                 name:NSViewFrameDidChangeNotification object:self];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handlePDFViewFrameChangedNotification:) 
                                                 name:NSViewBoundsDidChangeNotification object:self];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handlePDFContentViewFrameChangedNotification:) 
                                                 name:NSViewBoundsDidChangeNotification object:[[self scrollView] contentView]];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handlePDFContentViewFrameChangedDelayedNotification:) 
                                                 name:SKPDFContentViewChangedNotification object:self];
}

- (id)initWithFrame:(NSRect)frameRect {
    self = [super initWithFrame:frameRect];
    if (self) {
        [self commonInitialization];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)decoder {
    self = [super initWithCoder:decoder];
    if (self) {
        [self commonInitialization];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}

static void sizePopUpToItemAtIndex(NSPopUpButton *popUpButton, NSUInteger anIndex) {
    NSUInteger i = [popUpButton indexOfSelectedItem];
    [popUpButton selectItemAtIndex:anIndex];
    [popUpButton sizeToFit];
    NSSize frameSize = [popUpButton frame].size;
    frameSize.width -= 22.0 + 2 * [[popUpButton cell] controlSize];
    [popUpButton setFrameSize:frameSize];
    [popUpButton selectItemAtIndex:i];
}

- (void)makeScalePopUpButton {
    
    if (scalePopUpButton == nil) {
        
        NSScrollView *scrollView = [self scrollView];
        [scrollView setHasHorizontalScroller:YES];
        
        // create it        
        scalePopUpButton = [[SKHighlightingPopUpButton allocWithZone:[self zone]] initWithFrame:NSMakeRect(0.0, 0.0, 1.0, 1.0) pullsDown:NO];
        
        NSControlSize controlSize = [[scrollView horizontalScroller] controlSize];
        [[scalePopUpButton cell] setControlSize:controlSize];
		[scalePopUpButton setBordered:NO];
		[scalePopUpButton setEnabled:YES];
		[scalePopUpButton setRefusesFirstResponder:YES];
		[[scalePopUpButton cell] setUsesItemFromMenu:YES];
        
        // set a suitable font, the control size is 0, 1 or 2
        [scalePopUpButton setFont:[NSFont toolTipsFontOfSize: SKScaleMenuFontSize - controlSize]];
		
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
        sizePopUpToItemAtIndex(scalePopUpButton, maxIndex);
        
        // put it in the scrollview
        [scrollView setPlacards:[NSArray arrayWithObject:scalePopUpButton]];
        [scalePopUpButton release];
    }
}

- (void)handlePDFViewFrameChangedNotification:(NSNotification *)notification {
    if ([self autoFits]) {
        NSView *clipView = [[self scrollView] contentView];
        NSRect rect = [self convertRect:[clipView visibleRect] fromView:clipView];
        BOOL scaleWidth = NSWidth(rect) / NSHeight(rect) < NSWidth(autoFitRect) / NSHeight(autoFitRect);
        CGFloat factor = scaleWidth ? NSWidth(rect) / NSWidth(autoFitRect) : NSHeight(rect) / NSHeight(autoFitRect);
        NSRect viewRect = scaleWidth ? NSInsetRect(autoFitRect, 0.0, 0.5 * (NSHeight(autoFitRect) - NSHeight(rect) / factor)) : NSInsetRect(autoFitRect, 0.5 * (NSWidth(autoFitRect) - NSWidth(rect) / factor), 0.0);
        [super setScaleFactor:factor];
        viewRect = [self convertRect:[self convertRect:viewRect fromPage:autoFitPage] toView:[self documentView]];
        [[self documentView] scrollRectToVisible:viewRect];
    }
}

- (void)handlePDFContentViewFrameChangedDelayedNotification:(NSNotification *)notification {
    if ([self inLiveResize] == NO && [[self window] isZoomed] == NO)
        [self resetAutoFitRectIfNeeded];
}

- (void)handlePDFContentViewFrameChangedNotification:(NSNotification *)notification {
    if ([self inLiveResize] == NO && [[self window] isZoomed] == NO) {
        NSNotification *note = [NSNotification notificationWithName:SKPDFContentViewChangedNotification object:self];
        [[NSNotificationQueue defaultQueue] enqueueNotification:note postingStyle:NSPostWhenIdle coalesceMask:NSNotificationCoalescingOnName forModes:nil];
    }
}

- (void)resetAutoFitRectIfNeeded {
    if ([self autoFits]) {
        NSView *clipView = [[self scrollView] contentView];
        autoFitPage = [self currentPage];
        autoFitRect = [self convertRect:[self convertRect:[clipView visibleRect] fromView:clipView] toPage:autoFitPage];
    }
}

- (void)scalePopUpAction:(id)sender {
    NSNumber *selectedFactorObject = [[sender selectedItem] representedObject];
    if(selectedFactorObject)
        [self setScaleFactor:[selectedFactorObject doubleValue] adjustPopup:NO];
    else
        [self setAutoFits:YES adjustPopup:NO];
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

- (NSUInteger)lowerIndexForScaleFactor:(CGFloat)scaleFactor {
    NSUInteger i, count = SKDefaultScaleMenuFactorsCount;
    for (i = count - 1; i > 0; i--) {
        if (scaleFactor * 1.01 > SKDefaultScaleMenuFactors[i])
            return i;
    }
    return 1;
}

- (NSUInteger)upperIndexForScaleFactor:(CGFloat)scaleFactor {
    NSUInteger i, count = SKDefaultScaleMenuFactorsCount;
    for (i = 1; i < count; i++) {
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
	[self setScaleFactor:newScaleFactor adjustPopup:YES];
}

- (void)setScaleFactor:(CGFloat)newScaleFactor adjustPopup:(BOOL)flag {
	if (flag) {
		NSUInteger i = [self indexForScaleFactor:newScaleFactor];
        [scalePopUpButton selectItemAtIndex:i];
        newScaleFactor = SKDefaultScaleMenuFactors[i];
    }
    if ([self autoFits])
        [self setAutoFits:NO adjustPopup:NO];
    [super setScaleFactor:newScaleFactor];
}

- (void)setAutoScales:(BOOL)newAuto {}

- (IBAction)zoomIn:(id)sender{
    if([self autoFits]){
        [super zoomIn:sender];
        [self setAutoFits:NO adjustPopup:YES];
    }else{
        NSUInteger numberOfDefaultItems = SKDefaultScaleMenuFactorsCount;
        NSUInteger i = [self lowerIndexForScaleFactor:[self scaleFactor]];
        if (i < numberOfDefaultItems - 1) i++;
        [self setScaleFactor:SKDefaultScaleMenuFactors[i]];
    }
}

- (IBAction)zoomOut:(id)sender{
    if([self autoFits]){
        [super zoomOut:sender];
        [self setAutoFits:NO adjustPopup:YES];
    }else{
        NSUInteger i = [self upperIndexForScaleFactor:[self scaleFactor]];
        if (i > 1) i--;
        [self setScaleFactor:SKDefaultScaleMenuFactors[i]];
    }
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
    return i > 1;
}

- (BOOL)canGoBack {
    if ([self respondsToSelector:@selector(currentHistoryIndex)] && minHistoryIndex > 0)
        return minHistoryIndex < [self currentHistoryIndex];
    else
        return [super canGoBack];
}

- (void)resetHistory {
    if ([self respondsToSelector:@selector(currentHistoryIndex)])
        minHistoryIndex = [self currentHistoryIndex];
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

- (void)doActualSize:(id)sender {
    [self setScaleFactor:1.0];
}

// we don't want to steal the printDocument: action from the responder chain
- (void)printDocument:(id)sender{}

- (BOOL)respondsToSelector:(SEL)aSelector {
    return aSelector != @selector(printDocument:) && [super respondsToSelector:aSelector];
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
    
    NSInteger i = [menu indexOfItemWithTarget:self andAction:NSSelectorFromString(@"_setAutoSize:")];
    if (i != -1)
        [[menu itemAtIndex:i] setAction:@selector(doAutoFit:)];
    i = [menu indexOfItemWithTarget:self andAction:NSSelectorFromString(@"_setActualSize:")];
    if (i != -1)
        [[menu itemAtIndex:i] setAction:@selector(doActualSize:)];
    
    return menu;
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem {
    if ([menuItem action] == @selector(doAutoFit:)) {
        [menuItem setState:[self autoFits] ? NSOnState : NSOffState];
        return YES;
    } else if ([menuItem action] == @selector(doActualSize:)) {
        [menuItem setState:fabs([self scaleFactor] - 1.0) < 0.1 ? NSOnState : NSOffState];
        return YES;
    } else if ([[SKSnapshotPDFView superclass] instancesRespondToSelector:_cmd]) {
        return [super validateMenuItem:menuItem];
    }
    return YES;
}

#pragma mark Gestures

- (void)beginGestureWithEvent:(NSEvent *)theEvent {
    if ([[SKSnapshotPDFView superclass] instancesRespondToSelector:_cmd])
        [super beginGestureWithEvent:theEvent];
    didMagnify = NO;
}

- (void)endGestureWithEvent:(NSEvent *)theEvent {
    if (didMagnify)
        [self setScaleFactor:fmax([self scaleFactor], SKMinDefaultScaleMenuFactor) adjustPopup:YES];
    didMagnify = NO;
    if ([[SKSnapshotPDFView superclass] instancesRespondToSelector:_cmd])
        [super endGestureWithEvent:theEvent];
}

- (void)magnifyWithEvent:(NSEvent *)theEvent {
    if ([[NSUserDefaults standardUserDefaults] boolForKey:SKDisablePinchZoomKey] == NO && [theEvent respondsToSelector:@selector(magnification)]) {
        CGFloat magnifyFactor = (1.0 + fmax(-0.5, fmin(1.0 , [theEvent magnification])));
        [super setScaleFactor:magnifyFactor * [self scaleFactor]];
        didMagnify = YES;
    }
}

#pragma mark Dragging

- (void)mouseDown:(NSEvent *)theEvent{
    [[self window] makeFirstResponder:self];
	if ([theEvent standardModifierFlags] == (NSCommandKeyMask | NSShiftKeyMask)) {
        
        [self doPdfsyncWithEvent:theEvent];
        
    } else {
        
        NSPoint initialLocation = [theEvent locationInWindow];
        NSView *documentView = [[self scrollView] documentView];
        NSRect visibleRect = [documentView visibleRect];
        
        [[NSCursor closedHandCursor] push];
        
        while (YES) {
            
            theEvent = [[self window] nextEventMatchingMask: NSLeftMouseUpMask | NSLeftMouseDraggedMask];
            if ([theEvent type] == NSLeftMouseUp)
                break;
            
            // convert takes flipping and scaling into account
            NSPoint	startLocation = [documentView convertPoint:initialLocation fromView:nil];
            NSPoint	newLocation = [documentView convertPoint:[theEvent locationInWindow] fromView:nil];
            NSPoint	delta = SKSubstractPoints(startLocation, newLocation);
            
            [documentView scrollRectToVisible:NSOffsetRect(visibleRect, delta.x, delta.y)];
        }
        
        [NSCursor pop];
        // ??? PDFView's delayed layout seems to reset the cursor to an arrow
        [self performSelector:@selector(mouseMoved:) withObject:theEvent afterDelay:0];
        
    }
}

- (void)mouseMoved:(NSEvent *)theEvent {
	NSView *view = [self documentView];
    NSPoint mouseLoc = [theEvent locationInView:view];
    if (NSMouseInRect(mouseLoc, [view visibleRect], [view isFlipped]) == NO || [theEvent standardModifierFlags] == (NSCommandKeyMask | NSShiftKeyMask))
        [[NSCursor arrowCursor] set];
    else
        [[NSCursor openHandCursor] set];
}

@end
