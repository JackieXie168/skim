//
//  SKSnapshotPDFView.m
//  Skim
//
//  Created by Adam Maxwell on 07/23/05.
/*
 This software is Copyright (c) 2005-2020
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
 LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS ORd SERVICES; LOSS OF USE,
 DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "SKSnapshotPDFView.h"
#import "NSResponder_SKExtensions.h"
#import "NSEvent_SKExtensions.h"
#import "PDFPage_SKExtensions.h"
#import "SKMainDocument.h"
#import "SKPDFSynchronizer.h"
#import "SKStringConstants.h"
#import "SKTopBarView.h"
#import "PDFSelection_SKExtensions.h"
#import "PDFView_SKExtensions.h"
#import "NSGeometry_SKExtensions.h"
#import "NSMenu_SKExtensions.h"
#import "NSColor_SKExtensions.h"
#import "SKPDFView.h"
#import "NSGraphics_SKExtensions.h"


@interface SKSnapshotPDFView (SKPrivate)

- (void)resetAutoFitRectIfNeeded;

- (void)makeScalePopUpButton;
- (void)scalePopUpAction:(id)sender;

- (void)setAutoFits:(BOOL)newAuto adjustPopup:(BOOL)flag;
- (void)setScaleFactor:(CGFloat)factor adjustPopup:(BOOL)flag;

- (void)setAutoScales:(BOOL)newAuto adjustPopup:(BOOL)flag;

- (void)handlePDFViewFrameChangedNotification:(NSNotification *)notification;
- (void)handlePDFContentViewFrameChangedNotification:(NSNotification *)notification;
- (void)handlePDFContentViewFrameChangedDelayedNotification:(NSNotification *)notification;
- (void)handlePDFViewScaleChangedNotification:(NSNotification *)notification;
- (void)handleScrollerStyleChangedNotification:(NSNotification *)notification;

@end

@implementation SKSnapshotPDFView

@synthesize autoFits, shouldAutoFit;

#define SKPDFContentViewChangedNotification @"SKPDFContentViewChangedNotification"

static NSString *SKDefaultScaleMenuLabels[] = {@"Auto", @"10%", @"20%", @"25%", @"35%", @"50%", @"60%", @"70%", @"85%", @"100%", @"120%", @"140%", @"170%", @"200%", @"300%", @"400%", @"600%", @"800%", @"1000%", @"1200%", @"1400%", @"1700%", @"2000%"};
static CGFloat SKDefaultScaleMenuFactors[] = {0.0, 0.1, 0.2, 0.25, 0.35, 0.5, 0.6, 0.7, 0.85, 1.0, 1.2, 1.4, 1.7, 2.0, 3.0, 4.0, 6.0, 8.0, 10.0, 12.0, 14.0, 17.0, 20.0};

#define SKMinDefaultScaleMenuFactor (SKDefaultScaleMenuFactors[1])
#define SKDefaultScaleMenuFactorsCount (sizeof(SKDefaultScaleMenuFactors) / sizeof(CGFloat))

#define CONTROL_HEIGHT 16.0
#define CONTROL_WIDTH_OFFSET 20.0

#pragma mark Popup button

- (void)commonInitialization {
    autoFits = NO;
    shouldAutoFit = YES;
    switching = NO;
    scalePopUpButton = nil;
    autoFitPage = nil;
    autoFitRect = NSZeroRect;
    minHistoryIndex = 0;
    
    SKSetHasDefaultAppearance(self);
    SKSetHasLightAppearance([[self scrollView] contentView]);
    [self handleScrollerStyleChangedNotification:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleScrollerStyleChangedNotification:)
                                                 name:NSPreferredScrollerStyleDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handlePDFViewFrameChangedNotification:)
                                                 name:NSViewFrameDidChangeNotification object:self];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handlePDFViewFrameChangedNotification:)
                                                 name:NSViewBoundsDidChangeNotification object:self];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handlePDFContentViewFrameChangedNotification:) 
                                                 name:NSViewBoundsDidChangeNotification object:[[self scrollView] contentView]];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handlePDFContentViewFrameChangedDelayedNotification:)
                                                 name:SKPDFContentViewChangedNotification object:self];
    if ([PDFView instancesRespondToSelector:@selector(magnifyWithEvent:)] == NO || [PDFView instanceMethodForSelector:@selector(magnifyWithEvent:)] == [NSView instanceMethodForSelector:@selector(magnifyWithEvent:)])
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handlePDFViewScaleChangedNotification:)
                                                     name:PDFViewScaleChangedNotification object:self];
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
    SKDESTROY(scalePopUpButton);
    SKDESTROY(controlView);
    SKDESTROY(trackingArea);
    [super dealloc];
}

- (void)awakeFromNib {
    [self makeScalePopUpButton];
}

- (void)makeScalePopUpButton {
    
    if (scalePopUpButton == nil) {
        
        // create it
        scalePopUpButton = [[NSPopUpButton allocWithZone:[self zone]] initWithFrame:NSMakeRect(0.0, 0.0, 1.0, 1.0) pullsDown:NO];
        
        [[scalePopUpButton cell] setControlSize:NSSmallControlSize];
		[scalePopUpButton setBordered:NO];
		[scalePopUpButton setEnabled:YES];
		[scalePopUpButton setRefusesFirstResponder:YES];
		[[scalePopUpButton cell] setUsesItemFromMenu:YES];
        [scalePopUpButton setFont:[NSFont toolTipsFontOfSize:[NSFont smallSystemFontSize]]];
		
        NSUInteger cnt, numberOfDefaultItems = SKDefaultScaleMenuFactorsCount;
        id curItem;
        NSString *label;
        
        // fill it
        for (cnt = 0; cnt < numberOfDefaultItems; cnt++) {
            label = [[NSBundle mainBundle] localizedStringForKey:SKDefaultScaleMenuLabels[cnt] value:@"" table:@"ZoomValues"];
            [scalePopUpButton addItemWithTitle:label];
            curItem = [scalePopUpButton itemAtIndex:cnt];
            [curItem setRepresentedObject:(SKDefaultScaleMenuFactors[cnt] > 0.0 ? [NSNumber numberWithDouble:SKDefaultScaleMenuFactors[cnt]] : nil)];
        }
        
        // Make sure the popup is big enough to fit the largest cell
        [scalePopUpButton sizeToFit];
        [scalePopUpButton setFrameSize:NSMakeSize(NSWidth([scalePopUpButton frame]) - CONTROL_WIDTH_OFFSET, CONTROL_HEIGHT)];
        [scalePopUpButton setAutoresizingMask:NSViewMaxXMargin | NSViewMaxYMargin];
        
        // select the appropriate item, adjusting the scaleFactor if necessary
        if([self autoFits] || [self autoScales])
            [self setScaleFactor:0.0 adjustPopup:YES];
        else
            [self setScaleFactor:[self scaleFactor] adjustPopup:YES];
        
        // hook it up
        [scalePopUpButton setTarget:self];
        [scalePopUpButton setAction:@selector(scalePopUpAction:)];
        
        [scalePopUpButton setToolTip:NSLocalizedString(@"Zoom", @"Tool tip message")];

		// don't let it become first responder
		[scalePopUpButton setRefusesFirstResponder:YES];
        
        SKTopBarView *topBar = [[SKTopBarView alloc] initWithFrame:[scalePopUpButton frame]];
        [topBar setMinSize:[scalePopUpButton frame].size];
        if (RUNNING_BEFORE(10_14)) {
            [topBar setBackgroundColors:[NSArray arrayWithObjects:[NSColor pdfControlBackgroundColor], nil]];
            [topBar setAlternateBackgroundColors:nil];
        }
        [topBar addSubview:scalePopUpButton];
        
        controlView = topBar;
        [controlView setTranslatesAutoresizingMaskIntoConstraints:NO];
        NSLayoutConstraint *heightConstraint = [NSLayoutConstraint constraintWithItem:controlView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:0.0 constant:NSHeight([controlView bounds])];
        [heightConstraint setActive:YES];
        
        [self updateTrackingAreas];
    }
}

- (void)showControlView {
    NSRect rect = [self bounds];
    rect = SKSliceRect(rect, NSHeight([controlView frame]), [self isFlipped] ? NSMinYEdge : NSMaxYEdge);
    [controlView setFrame:rect];
    [controlView setAlphaValue:0.0];
    [self addSubview:controlView positioned:NSWindowAbove relativeTo:nil];
    NSArray *constraints = [NSArray arrayWithObjects:
        [NSLayoutConstraint constraintWithItem:controlView attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeLeading multiplier:1.0 constant:0.0],
        [NSLayoutConstraint constraintWithItem:controlView attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeTrailing multiplier:1.0 constant:0.0],
        [NSLayoutConstraint constraintWithItem:controlView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeTop multiplier:1.0 constant:0.0], nil];
    [NSLayoutConstraint activateConstraints:constraints];
    [[controlView animator] setAlphaValue:1.0];
}

- (void)mouseEntered:(NSEvent *)theEvent {
    if ([[SKSnapshotPDFView superclass] instancesRespondToSelector:_cmd])
        [super mouseEntered:theEvent];
    if (trackingArea && [theEvent trackingArea] == trackingArea) {
        [[self class] cancelPreviousPerformRequestsWithTarget:self selector:@selector(showControlView) object:nil];
        [self performSelector:@selector(showControlView) withObject:nil afterDelay:0.5];
    }
}

- (void)mouseExited:(NSEvent *)theEvent {
    if ([[SKSnapshotPDFView superclass] instancesRespondToSelector:_cmd])
        [super mouseExited:theEvent];
    if (trackingArea && [theEvent trackingArea] == trackingArea) {
        [[self class] cancelPreviousPerformRequestsWithTarget:self selector:@selector(showControlView) object:nil];
        [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context){
            [[controlView animator] setAlphaValue:0.0];
        } completionHandler:^{
            [controlView removeFromSuperview];
        }];
    }
}

- (void)updateTrackingAreas {
    [super updateTrackingAreas];
    if (trackingArea)
        [self removeTrackingArea:trackingArea];
    if (controlView) {
        NSRect rect = [self bounds];
        if (NSHeight(rect) > NSHeight([controlView frame])) {
            rect = SKSliceRect(rect, NSHeight([controlView frame]), [self isFlipped] ? NSMinYEdge : NSMaxYEdge);
            trackingArea = [[NSTrackingArea alloc] initWithRect:rect options:NSTrackingActiveInKeyWindow | NSTrackingMouseEnteredAndExited owner:self userInfo:nil];
            [self addTrackingArea:trackingArea];
        }
    }
}

- (id <SKSnapshotPDFViewDelegate>)delegate {
    return (id <SKSnapshotPDFViewDelegate>)[super delegate];
}

- (void)setDelegate:(id <SKSnapshotPDFViewDelegate>)newDelegate {
    [super setDelegate:newDelegate];
}

- (void)handlePDFViewFrameChangedNotification:(NSNotification *)notification {
    if ([self autoFits]) {
        NSView *clipView = [[self scrollView] contentView];
        NSRect clipRect = [self convertRect:[clipView visibleRect] fromView:clipView];
        NSRect rect = [self convertRect:autoFitRect fromPage:autoFitPage];
        CGFloat factor = fmin(NSWidth(clipRect) / NSWidth(rect), NSHeight(clipRect) / NSHeight(rect));
        rect = [self convertRect:NSInsetRect(rect, 0.5 * (NSWidth(rect) - NSWidth(clipRect) / factor), 0.5 * (NSHeight(rect) - NSHeight(clipRect) / factor)) toPage:autoFitPage];
        [super setScaleFactor:factor * [self scaleFactor]];
        [self goToRect:rect onPage:autoFitPage];
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

- (void)handlePDFViewScaleChangedNotification:(NSNotification *)notification {
    if ([self autoFits] == NO && [self autoScales] == NO)
        [self setScaleFactor:fmax([self scaleFactor], SKMinDefaultScaleMenuFactor) adjustPopup:YES];
}

- (void)handleScrollerStyleChangedNotification:(NSNotification *)notification {
    if ([NSScroller preferredScrollerStyle] == NSScrollerStyleLegacy) {
        SKSetHasDefaultAppearance([[self scrollView] verticalScroller]);
        SKSetHasDefaultAppearance([[self scrollView] horizontalScroller]);
    } else {
        SKSetHasLightAppearance([[self scrollView] verticalScroller]);
        SKSetHasLightAppearance([[self scrollView] horizontalScroller]);
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
    if (selectedFactorObject)
        [self setScaleFactor:[selectedFactorObject doubleValue] adjustPopup:NO];
    else if ([self shouldAutoFit])
        [self setAutoFits:YES adjustPopup:NO];
    else
        [self setAutoScales:YES adjustPopup:NO];
}

- (void)setAutoFits:(BOOL)newAuto {
    if ([self shouldAutoFit])
        [self setAutoFits:newAuto adjustPopup:YES];
}

- (void)setAutoFits:(BOOL)newAuto adjustPopup:(BOOL)flag {
    if ([self shouldAutoFit] && autoFits != newAuto) {
        BOOL savedSwitching = switching;
        switching = YES;
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
        switching = savedSwitching;
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
    BOOL savedSwitching = switching;
    switching = YES;
    if (savedSwitching)
        [super setScaleFactor:newScaleFactor];
    else
        [self setScaleFactor:newScaleFactor adjustPopup:YES];
    switching = savedSwitching;
}

- (void)setScaleFactor:(CGFloat)newScaleFactor adjustPopup:(BOOL)flag {
    BOOL savedSwitching = switching;
    switching = YES;
    if (flag) {
        NSUInteger i = [self indexForScaleFactor:newScaleFactor];
        [scalePopUpButton selectItemAtIndex:i];
        newScaleFactor = SKDefaultScaleMenuFactors[i];
    }
    if ([self autoFits])
        [self setAutoFits:NO adjustPopup:NO];
    else if ([self autoScales])
        [self setAutoScales:NO adjustPopup:NO];
    [super setScaleFactor:newScaleFactor];
    switching = savedSwitching;
}

- (void)setAutoScales:(BOOL)newAuto {
    if ([self shouldAutoFit] == NO) {
        BOOL savedSwitching = switching;
        switching = YES;
        if (savedSwitching)
            [super setAutoScales:newAuto];
        else
            [self setAutoScales:newAuto adjustPopup:YES];
        switching = savedSwitching;
    }
}

- (void)setAutoScales:(BOOL)newAuto adjustPopup:(BOOL)flag {
    if ([self shouldAutoFit] == NO) {
        BOOL savedSwitching = switching;
        switching = YES;
        if ([self autoFits])
            [self setAutoFits:NO adjustPopup:NO];
        [super setAutoScales:newAuto];
        if (newAuto && flag)
            [scalePopUpButton selectItemAtIndex:0];
        switching = savedSwitching;
    }
}

- (void)setShouldAutoFit:(BOOL)flag {
    if (flag != shouldAutoFit) {
        BOOL didAutoScale = [self autoScales];
        BOOL didAutoFit = [self autoFits];
        if (flag && didAutoScale)
            [self setAutoScales:NO adjustPopup:NO];
        else if (flag == NO && didAutoFit)
            [self setAutoFits:NO adjustPopup:NO];
        shouldAutoFit = flag;
        if (flag && didAutoScale)
            [self setAutoFits:YES adjustPopup:NO];
        else if (flag == NO && didAutoFit)
            [self setAutoScales:YES adjustPopup:NO];
    }
}

- (IBAction)zoomIn:(id)sender{
    if([self autoFits]){
        [super zoomIn:sender];
        [self setAutoFits:NO adjustPopup:YES];
    }else{
        NSUInteger numberOfDefaultItems = SKDefaultScaleMenuFactorsCount;
        NSUInteger i = [self lowerIndexForScaleFactor:[self scaleFactor]];
        if (i < numberOfDefaultItems - 1) i++;
        [self setScaleFactor:SKDefaultScaleMenuFactors[i] adjustPopup:YES];
    }
}

- (IBAction)zoomOut:(id)sender{
    if([self autoFits]){
        [super zoomOut:sender];
        [self setAutoFits:NO adjustPopup:YES];
    }else{
        NSUInteger i = [self upperIndexForScaleFactor:[self scaleFactor]];
        if (i > 1) i--;
        [self setScaleFactor:SKDefaultScaleMenuFactors[i] adjustPopup:YES];
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

- (void)doAutoFit:(id)sender {
    [self setAutoFits:YES];
}

- (void)doActualSize:(id)sender {
    [self setScaleFactor:1.0];
}

- (void)doPhysicalSize:(id)sender {
    [self setPhysicalScaleFactor:1.0];
}

- (void)externalGoTo:(id)sender {
    if ([[self delegate] respondsToSelector:@selector(PDFView:goToExternalDestination:)]) {
        PDFPage *page = [self currentPage];
        NSPoint point = [self convertPoint:SKTopLeftPoint([self bounds]) toPage:page];
        [[self delegate] PDFView:self goToExternalDestination:[[[PDFDestination alloc] initWithPage:page atPoint:point] autorelease]];
    }
}

// we don't want to steal the printDocument: action from the responder chain
- (void)printDocument:(id)sender{}

- (BOOL)respondsToSelector:(SEL)aSelector {
    return aSelector != @selector(printDocument:) && [super respondsToSelector:aSelector];
}

- (NSMenu *)menuForEvent:(NSEvent *)theEvent {
    static NSSet *selectionActions = nil;
    if (selectionActions == nil)
        selectionActions = [[NSSet alloc] initWithObjects:@"copy:", @"_searchInSpotlight:", @"_searchInGoogle:", @"_searchInDictionary:", @"_revealSelection:", nil];
    NSMenu *menu = [super menuForEvent:theEvent];
    NSInteger i = 0;
    
    if ([[menu itemAtIndex:0] view] != nil) {
        [menu removeItemAtIndex:0];
        if ([[menu itemAtIndex:0] isSeparatorItem])
            [menu removeItemAtIndex:0];
    }
    
    [self setCurrentSelection:nil];
    NSMenuItem *item;
    BOOL allowsSeparator = NO;
    while ([menu numberOfItems] > i) {
        item = [menu itemAtIndex:i];
        if ([item isSeparatorItem]) {
            if (allowsSeparator) {
                i++;
                allowsSeparator = NO;
            } else {
                [menu removeItemAtIndex:i];
            }
        } else if ([self validateMenuItem:item] == NO || [selectionActions containsObject:NSStringFromSelector([item action])]) {
            [menu removeItemAtIndex:i];
        } else {
            i++;
            allowsSeparator = YES;
        }
    }
    
    if ([self shouldAutoFit]) {
        i = [menu indexOfItemWithTarget:self andAction:NSSelectorFromString(@"_setAutoSize:")];
        if (i != -1)
            [[menu itemAtIndex:i] setAction:@selector(doAutoFit:)];
    }
    i = [menu indexOfItemWithTarget:self andAction:NSSelectorFromString(@"_setActualSize:")];
    if (i != -1) {
        [[menu itemAtIndex:i] setAction:@selector(doActualSize:)];
        item = [menu insertItemWithTitle:NSLocalizedString(@"Physical Size", @"Menu item title") action:@selector(doPhysicalSize:) target:self atIndex:i + 1];
        [item setKeyEquivalentModifierMask:NSAlternateKeyMask];
        [item setAlternate:YES];
    }
    
    [menu addItem:[NSMenuItem separatorItem]];
    [menu addItemWithTitle:NSLocalizedString(@"Go", @"Menu item title") action:@selector(externalGoTo:) target:self];
    
    return menu;
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem {
    if ([menuItem action] == @selector(doAutoFit:)) {
        [menuItem setState:[self autoFits] ? NSOnState : NSOffState];
        return [self shouldAutoFit];
    } else if ([menuItem action] == @selector(doActualSize:)) {
        [menuItem setState:fabs([self scaleFactor] - 1.0) < 0.1 ? NSOnState : NSOffState];
        return YES;
    } else if ([menuItem action] == @selector(doPhysicalSize:)) {
        [menuItem setState:([self autoScales] || fabs([self physicalScaleFactor] - 1.0 ) > 0.01) ? NSOffState : NSOnState];
        return YES;
    } else if ([[SKSnapshotPDFView superclass] instancesRespondToSelector:_cmd]) {
        return [super validateMenuItem:menuItem];
    }
    return YES;
}

- (void)keyDown:(NSEvent *)theEvent {
    if ([theEvent firstCharacter] == '?' && ([theEvent standardModifierFlags] & ~NSShiftKeyMask) == 0) {
        [[self class] cancelPreviousPerformRequestsWithTarget:self selector:@selector(showControlView) object:nil];
        if ([controlView superview])
            [controlView removeFromSuperview];
        else
            [self showControlView];
    } else {
        [super keyDown:theEvent];
    }
}

#pragma mark Gestures

- (void)beginGestureWithEvent:(NSEvent *)theEvent {
    if ([[SKSnapshotPDFView superclass] instancesRespondToSelector:_cmd])
        [super beginGestureWithEvent:theEvent];
    startScale = [self scaleFactor];
}

- (void)endGestureWithEvent:(NSEvent *)theEvent {
    if (fabs(startScale - [self scaleFactor]) > 0.001)
        [self setScaleFactor:fmax([self scaleFactor], SKMinDefaultScaleMenuFactor) adjustPopup:YES];
    if ([[SKSnapshotPDFView superclass] instancesRespondToSelector:_cmd])
        [super endGestureWithEvent:theEvent];
}

- (void)magnifyWithEvent:(NSEvent *)theEvent {
    if ([[NSUserDefaults standardUserDefaults] boolForKey:SKDisablePinchZoomKey] == NO) {
        if ([theEvent phase] == NSEventPhaseBegan)
            startScale = [self scaleFactor];
        CGFloat magnifyFactor = (1.0 + fmax(-0.5, fmin(1.0 , [theEvent magnification])));
        [super setScaleFactor:magnifyFactor * [self scaleFactor]];
        if (([theEvent phase] == NSEventPhaseEnded || [theEvent phase] == NSEventPhaseCancelled) && fabs(startScale - [self scaleFactor]) > 0.001)
            [self setScaleFactor:fmax([self scaleFactor], SKMinDefaultScaleMenuFactor) adjustPopup:YES];
    }
}

#pragma mark Dragging

- (void)mouseDown:(NSEvent *)theEvent{
    [[self class] cancelPreviousPerformRequestsWithTarget:self selector:@selector(showControlView) object:nil];
    [[self window] makeFirstResponder:self];
	
    if ([theEvent standardModifierFlags] == NSCommandKeyMask) {
        
        [[NSCursor arrowCursor] push];
        
        // eat up mouseDragged/mouseUp events, so we won't get their event handlers
        NSEvent *lastEvent = theEvent;
        while (YES) {
            lastEvent = [[self window] nextEventMatchingMask: NSLeftMouseUpMask | NSLeftMouseDraggedMask];
            if ([lastEvent type] == NSLeftMouseUp)
                break;
        }
        
        [NSCursor pop];
        [self performSelector:@selector(mouseMoved:) withObject:lastEvent afterDelay:0];
        
        if ([[self delegate] respondsToSelector:@selector(PDFView:goToExternalDestination:)]) {
            NSPoint location = NSZeroPoint;
            PDFPage *page = [self pageAndPoint:&location forEvent:theEvent nearest:YES];
            [[self delegate] PDFView:self goToExternalDestination:[[[PDFDestination alloc] initWithPage:page atPoint:location] autorelease]];
        }
        
    } else if ([theEvent standardModifierFlags] == (NSCommandKeyMask | NSShiftKeyMask)) {
        
        [self doPdfsyncWithEvent:theEvent];
        
    } else {
        
        [self doDragWithEvent:theEvent];
        
    }
}

- (PDFAreaOfInterest)areaOfInterestForMouse:(NSEvent *)theEvent {
    PDFAreaOfInterest area = [super areaOfInterestForMouse:theEvent];
    NSInteger modifiers = [theEvent standardModifierFlags];
    
    if ([controlView superview] && NSMouseInRect([theEvent locationInView:controlView], [controlView bounds], [controlView isFlipped])) {
        area = kPDFNoArea;
    } else if (modifiers == (NSCommandKeyMask | NSShiftKeyMask)) {
        area = (area & kPDFPageArea) | SKSpecialToolArea;
    } else {
        area = (area & kPDFPageArea) | SKDragArea;
    }
    
    return area;
}

- (void)setCursorForAreaOfInterest:(PDFAreaOfInterest)area {
    if ((area & SKSpecialToolArea))
        [[NSCursor arrowCursor] set];
    else if ((area & SKDragArea))
        [[NSCursor openHandCursor] set];
    else
        [super setCursorForAreaOfInterest:area];
}

@end
