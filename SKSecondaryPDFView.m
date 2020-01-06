//
//  SKSecondaryPDFView.m
//  Skim
//
//  Created by Christiaan Hofman on 9/19/07.
/*
 This software is Copyright (c) 2007-2020
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
#import "PDFAnnotation_SKExtensions.h"
#import "PDFPage_SKExtensions.h"
#import "PDFDocument_SKExtensions.h"
#import "SKStringConstants.h"
#import "NSResponder_SKExtensions.h"
#import "NSEvent_SKExtensions.h"
#import "SKMainDocument.h"
#import "SKPDFSynchronizer.h"
#import "SKStringConstants.h"
#import "PDFSelection_SKExtensions.h"
#import "PDFView_SKExtensions.h"
#import "NSMenu_SKExtensions.h"
#import "NSImage_SKExtensions.h"
#import "SKPDFView.h"
#import "SKGradientView.h"
#import "NSColor_SKExtensions.h"
#import "NSGraphics_SKExtensions.h"


@interface SKSecondaryPDFView (SKPrivate)

- (void)reloadPagePopUpButton;
- (void)makeControls;

- (void)scalePopUpAction:(id)sender;
- (void)pagePopUpAction:(id)sender;
- (void)toolModeButtonAction:(id)sender;

- (void)setSynchronizeZoom:(BOOL)newSync adjustPopup:(BOOL)flag;
- (void)setAutoScales:(BOOL)newAuto adjustPopup:(BOOL)flag;
- (void)setScaleFactor:(CGFloat)factor adjustPopup:(BOOL)flag;

- (void)startObservingSynchronizedPDFView;
- (void)stopObservingSynchronizedPDFView;

- (void)handleSynchronizedScaleChangedNotification:(NSNotification *)notification;
- (void)handlePageChangedNotification:(NSNotification *)notification;
- (void)handleDocumentDidUnlockNotification:(NSNotification *)notification;
- (void)handlePDFViewScaleChangedNotification:(NSNotification *)notification;
- (void)handleScrollerStyleChangedNotification:(NSNotification *)notification;

@end

@implementation SKSecondaryPDFView

@synthesize synchronizedPDFView, synchronizeZoom, selectsText;

static NSString *SKDefaultScaleMenuLabels[] = {@"=", @"Auto", @"10%", @"20%", @"25%", @"35%", @"50%", @"60%", @"70%", @"85%", @"100%", @"120%", @"140%", @"170%", @"200%", @"300%", @"400%", @"600%", @"800%", @"1000%", @"1200%", @"1400%", @"1700%", @"2000%"};
static CGFloat SKDefaultScaleMenuFactors[] = {0.0, 0.0, 0.1, 0.2, 0.25, 0.35, 0.5, 0.6, 0.7, 0.85, 1.0, 1.2, 1.4, 1.7, 2.0, 3.0, 4.0, 6.0, 8.0, 10.0, 12.0, 14.0, 17.0, 20.0};

#define SKMinDefaultScaleMenuFactor (SKDefaultScaleMenuFactors[2])
#define SKDefaultScaleMenuFactorsCount (sizeof(SKDefaultScaleMenuFactors) / sizeof(CGFloat))

#define CONTROL_HEIGHT 16.0
#define CONTROL_WIDTH_OFFSET 20.0

- (void)commonInitialization {
    scalePopUpButton = nil;
    pagePopUpButton = nil;
    synchronizedPDFView = nil;
    synchronizeZoom = NO;
    selectsText = [[NSUserDefaults standardUserDefaults] boolForKey:SKLastSecondarySelectsTextKey];
    
    SKSetHasDefaultAppearance(self);
    [self handleScrollerStyleChangedNotification:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleScrollerStyleChangedNotification:)
                                                 name:NSPreferredScrollerStyleDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handlePageChangedNotification:)
                                                 name:PDFViewPageChangedNotification object:self];
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
    SKDESTROY(synchronizedPDFView);
    SKDESTROY(scalePopUpButton);
    SKDESTROY(pagePopUpButton);
    SKDESTROY(toolModeButton);
    SKDESTROY(controlView);
    SKDESTROY(trackingArea);
    [super dealloc];
}

- (void)awakeFromNib {
    [self makeControls];
}
- (void)viewWillMoveToWindow:(NSWindow *)newWindow {
    [super viewWillMoveToWindow:newWindow];
    if (controlView == nil)
        [self makeControls];
}

- (void)setDocument:(PDFDocument *)document {
    if ([self document])
        [[NSNotificationCenter defaultCenter] removeObserver:self name:PDFDocumentDidUnlockNotification object:[self document]];
    [super setDocument:document];
    [self reloadPagePopUpButton];
    if (document && [document isLocked])
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleDocumentDidUnlockNotification:) 
                                                     name:PDFDocumentDidUnlockNotification object:document];
}

#pragma mark Popup buttons

static void sizePopUpToItemAtIndex(NSPopUpButton *popUpButton, NSUInteger anIndex) {
    NSUInteger i = [popUpButton indexOfSelectedItem];
    [popUpButton selectItemAtIndex:anIndex];
    [popUpButton sizeToFit];
    [popUpButton setFrameSize:NSMakeSize(NSWidth([popUpButton frame]) - CONTROL_WIDTH_OFFSET, CONTROL_HEIGHT)];
    [popUpButton selectItemAtIndex:i];
}

- (void)reloadPagePopUpButton {
    NSArray *labels = [[self document] pageLabels];
    NSUInteger count = [pagePopUpButton numberOfItems];
    NSSize size = NSMakeSize(1000.0, 1000.0);
    NSDictionary *attrs = [NSDictionary dictionaryWithObjectsAndKeys:[pagePopUpButton font], NSFontAttributeName, nil];
    __block CGFloat maxWidth = 0.0;
    __block NSUInteger maxIndex = 0;
    
    while (count--)
        [pagePopUpButton removeItemAtIndex:count];
    
    if ([labels count] > 0) {
        [labels enumerateObjectsUsingBlock:^(id label, NSUInteger i, BOOL *stop) {
            CGFloat width = NSWidth([label boundingRectWithSize:size options:0 attributes:attrs]);
            if (width > maxWidth) {
                maxWidth = width;
                maxIndex = i;
            }
            [pagePopUpButton addItemWithTitle:label];
        }];
        
        sizePopUpToItemAtIndex(pagePopUpButton, maxIndex);
        
        [pagePopUpButton selectItemAtIndex:[[self currentPage] pageIndex]];
        
        if (controlView)
            [(SKGradientView *)controlView setMinSize:NSMakeSize(NSWidth([toolModeButton frame]) + NSWidth([pagePopUpButton frame]) + NSWidth([scalePopUpButton frame]), CONTROL_HEIGHT)];
        
        if (scalePopUpButton)
            [scalePopUpButton setFrameOrigin:NSMakePoint(NSMaxX([pagePopUpButton frame]), 0.0)];
    }
}

- (void)makeControls {
    
    if (scalePopUpButton == nil) {

        // create it        
        scalePopUpButton = [[NSPopUpButton allocWithZone:[self zone]] initWithFrame:NSMakeRect(0.0, 0.0, 1.0, 1.0) pullsDown:NO];
        
        [[scalePopUpButton cell] setControlSize:NSSmallControlSize];
		[scalePopUpButton setBordered:NO];
		[scalePopUpButton setEnabled:YES];
		[scalePopUpButton setRefusesFirstResponder:YES];
		[[scalePopUpButton cell] setUsesItemFromMenu:YES];
        [scalePopUpButton setFont:[NSFont systemFontOfSize:[NSFont smallSystemFontSize]]];

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
        if([self synchronizeZoom])
            [self setSynchronizeZoom:YES adjustPopup:YES];
        else if([self autoScales])
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
        
        [scalePopUpButton setToolTip:NSLocalizedString(@"Zoom", @"Tool tip message")];
        
    }
    
    if (pagePopUpButton == nil) {
        
        // create it        
        pagePopUpButton = [[NSPopUpButton allocWithZone:[self zone]] initWithFrame:NSMakeRect(0.0, 0.0, 1.0, 1.0) pullsDown:NO];
        
        [[pagePopUpButton cell] setControlSize:NSSmallControlSize];
		[pagePopUpButton setBordered:NO];
		[pagePopUpButton setEnabled:YES];
		[pagePopUpButton setRefusesFirstResponder:YES];
		[[pagePopUpButton cell] setUsesItemFromMenu:YES];

        // set a suitable font, the control size is 0, 1 or 2
        [pagePopUpButton setFont:[NSFont systemFontOfSize:[NSFont smallSystemFontSize]]];
		
        [self reloadPagePopUpButton];

        // don't let it become first responder
        [pagePopUpButton setRefusesFirstResponder:YES];

        // hook it up
        [pagePopUpButton setTarget:self];
        [pagePopUpButton setAction:@selector(pagePopUpAction:)];
        
        [pagePopUpButton setToolTip:NSLocalizedString(@"Page", @"Tool tip message")];
        
    }
    
    if (toolModeButton == nil) {
        
        // create it
        toolModeButton = [[NSButton alloc] initWithFrame:NSMakeRect(0.0, 0.0, CONTROL_HEIGHT, CONTROL_HEIGHT)];
        
        [toolModeButton setButtonType:NSToggleButton];
        [toolModeButton setBordered:NO];
        [toolModeButton setImage:[NSImage imageNamed:SKImageNameTextToolAdorn]];
        
        [toolModeButton setState:[self selectsText]];
        
        // don't let it become first responder
        [toolModeButton setRefusesFirstResponder:YES];
        
        // hook it up
        [toolModeButton setTarget:self];
        [toolModeButton setAction:@selector(toolModeButtonAction:)];
        
        [toolModeButton setToolTip:NSLocalizedString(@"Tool Mode", @"Tool tip message")];
        
    }
    
    if (controlView == nil) {
        
        NSRect toolRect = [toolModeButton frame];
        NSRect pageRect = [pagePopUpButton frame];
        NSRect scaleRect = [scalePopUpButton frame];
        NSRect rect = NSMakeRect(0.0, 0.0, NSWidth(toolRect) + NSWidth(pageRect) + NSWidth(scaleRect), CONTROL_HEIGHT);
        
        SKGradientView *gradientView = [[SKGradientView alloc] initWithFrame:rect];
        [gradientView setMinSize:rect.size];
        [gradientView setBackgroundColors:[NSArray arrayWithObjects:[NSColor pdfControlBackgroundColor], nil]];
        
        NSDivideRect(rect, &toolRect, &rect, NSWidth(toolRect), NSMinXEdge);
        NSDivideRect(rect, &pageRect, &scaleRect, NSWidth(pageRect), NSMinXEdge);
        [toolModeButton setFrame:toolRect];
        [pagePopUpButton setFrame:pageRect];
        [scalePopUpButton setFrame:scaleRect];
        [toolModeButton setAutoresizingMask:NSViewMaxXMargin | NSViewMaxYMargin];
        [pagePopUpButton setAutoresizingMask:NSViewMaxXMargin | NSViewMaxYMargin];
        [scalePopUpButton setAutoresizingMask:NSViewMaxXMargin | NSViewMaxYMargin];
        [gradientView addSubview:toolModeButton];
        [gradientView addSubview:pagePopUpButton];
        [gradientView addSubview:scalePopUpButton];
        
        controlView = gradientView;
        
        [self updateTrackingAreas];
        
    }
}

- (void)showControlView {
    NSRect rect = [self bounds];
    rect = SKSliceRect(rect, NSHeight([controlView frame]), [self isFlipped] ? NSMinYEdge : NSMaxYEdge);
    [controlView setFrame:rect];
    [controlView setAlphaValue:0.0];
    [self addSubview:controlView positioned:NSWindowAbove relativeTo:nil];
    [[controlView animator] setAlphaValue:1.0];
}

- (void)mouseEntered:(NSEvent *)theEvent {
    if ([[SKSecondaryPDFView superclass] instancesRespondToSelector:_cmd])
        [super mouseEntered:theEvent];
    if (trackingArea && [theEvent trackingArea] == trackingArea) {
        [[self class] cancelPreviousPerformRequestsWithTarget:self selector:@selector(showControlView) object:nil];
        [self performSelector:@selector(showControlView) withObject:nil afterDelay:0.5];
    }
}

- (void)mouseExited:(NSEvent *)theEvent {
    if ([[SKSecondaryPDFView superclass] instancesRespondToSelector:_cmd])
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

- (void)toolModeButtonAction:(id)sender {
    [self setSelectsText:[(NSButton *)sender state]];
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

- (void)setSelectsText:(BOOL)newSelectsText {
    if (newSelectsText != selectsText) {
        selectsText = newSelectsText;
        if (selectsText == NO)
            [self setCurrentSelection:RUNNING(10_12) ? [[[PDFSelection alloc] initWithDocument:[self document]] autorelease] : nil];
        [toolModeButton setState:selectsText ? NSOnState : NSOffState];
        [[NSUserDefaults standardUserDefaults] setBool:selectsText forKey:SKLastSecondarySelectsTextKey];
    }
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

- (BOOL)performKeyEquivalent:(NSEvent *)theEvent { return NO; }

- (IBAction)toggleDisplayAsBookFromMenu:(id)sender {
    [self setDisplaysAsBook:[self displaysAsBook] == NO];
}

- (IBAction)toggleDisplayPageBreaksFromMenu:(id)sender {
    [self setDisplaysPageBreaks:[self displaysPageBreaks] == NO];
}

- (void)doActualSize:(id)sender {
    [self setScaleFactor:1.0];
}

- (void)doPhysicalSize:(id)sender {
    [self setPhysicalScaleFactor:1.0];
}

- (void)changeToolMode:(id)sender {
    [self setSelectsText:(BOOL)[sender tag]];
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
    NSMenuItem *item;
    NSInteger i = 0;
    
    if ([[menu itemAtIndex:0] view] != nil) {
        [menu removeItemAtIndex:0];
        if ([[menu itemAtIndex:0] isSeparatorItem])
            [menu removeItemAtIndex:0];
    }
    
    if ([self selectsText] == NO) {
        [self setCurrentSelection:RUNNING(10_12) ? [[[PDFSelection alloc] initWithDocument:[self document]] autorelease] : nil];
        while ([menu numberOfItems] > i) {
            item = [menu itemAtIndex:i];
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
        }
    }
    
    i = [menu indexOfItemWithTarget:self andAction:NSSelectorFromString(@"_setDoublePageScrolling:")];
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
    i = [menu indexOfItemWithTarget:self andAction:NSSelectorFromString(@"_setActualSize:")];
    if (i != -1) {
        [[menu itemAtIndex:i] setAction:@selector(doActualSize:)];
        item = [menu insertItemWithTitle:NSLocalizedString(@"Physical Size", @"Menu item title") action:@selector(doPhysicalSize:) target:self atIndex:i + 1];
        [item setKeyEquivalentModifierMask:NSAlternateKeyMask];
        [item setAlternate:YES];
    }
    
    i = [menu indexOfItemWithTarget:self andAction:NSSelectorFromString(@"goToNextPage:")];
    i = i == NSNotFound || i == 0 ? [menu numberOfItems] : i - 1;
    
    [menu insertItemWithTitle:NSLocalizedString(@"Scroll Tool", @"Menu item title") action:@selector(changeToolMode:) target:self tag:0 atIndex:i];
    [menu insertItemWithTitle:NSLocalizedString(@"Text Tool", @"Menu item title") action:@selector(changeToolMode:) target:self tag:1 atIndex:i];
    [menu insertItem:[NSMenuItem separatorItem]atIndex:i];

    return menu;
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem {
    if ([menuItem action] == @selector(toggleDisplayAsBookFromMenu:)) {
        [menuItem setState:[self displaysAsBook] ? NSOnState : NSOffState];
        return YES;
    } else if ([menuItem action] == @selector(toggleDisplayPageBreaksFromMenu:)) {
        [menuItem setState:[self displaysPageBreaks] ? NSOnState : NSOffState];
        return YES;
    } else if ([menuItem action] == @selector(doActualSize:)) {
        [menuItem setState:fabs([self scaleFactor] - 1.0) < 0.1 ? NSOnState : NSOffState];
        return YES;
    } else if ([menuItem action] == @selector(doPhysicalSize:)) {
        [menuItem setState:([self autoScales] || fabs([self physicalScaleFactor] - 1.0 ) > 0.01) ? NSOffState : NSOnState];
        return YES;
    } else if ([menuItem action] == @selector(changeToolMode:)) {
        [menuItem setState:[self selectsText] == (BOOL)[menuItem tag] ? NSOnState : NSOffState];
        return YES;
    } else if ([[SKSecondaryPDFView superclass] instancesRespondToSelector:_cmd]) {
        return [super validateMenuItem:menuItem];
    }
    return YES;
}

#pragma mark Gestures

- (void)beginGestureWithEvent:(NSEvent *)theEvent {
    if ([[SKSecondaryPDFView superclass] instancesRespondToSelector:_cmd])
        [super beginGestureWithEvent:theEvent];
    startScale = [self scaleFactor];
}

- (void)endGestureWithEvent:(NSEvent *)theEvent {
    if (fabs(startScale - [self scaleFactor]) > 0.001)
        [self setScaleFactor:fmax([self scaleFactor], SKMinDefaultScaleMenuFactor) adjustPopup:YES];
    if ([[SKSecondaryPDFView superclass] instancesRespondToSelector:_cmd])
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
	
    NSUInteger modifiers = [theEvent standardModifierFlags];
	
	if (modifiers == NSCommandKeyMask) {
        
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
        
        NSPoint location = NSZeroPoint;
        PDFPage *page = [self pageAndPoint:&location forEvent:theEvent nearest:YES];
        [synchronizedPDFView goToDestination:[[[PDFDestination alloc] initWithPage:page atPoint:location] autorelease]];
        
    } else if (modifiers == (NSCommandKeyMask | NSShiftKeyMask)) {
        
        [self doPdfsyncWithEvent:theEvent];
        
    } else if ([self selectsText] == NO) {
        
        [self doDragWithEvent:theEvent];
        
    } else if (([self areaOfInterestForMouse:theEvent] & SKDragArea)) {
        
        [self doDragWithEvent:theEvent];
        
    } else if ([self doDragTextWithEvent:theEvent] == NO) {
        
        [super mouseDown:theEvent];
        
    }
}

#define TEXT_SELECT_MARGIN_SIZE ((NSSize){80.0, 100.0})

- (PDFAreaOfInterest)areaOfInterestForMouse:(NSEvent *)theEvent {
    PDFAreaOfInterest area = [super areaOfInterestForMouse:theEvent];
    NSInteger modifiers = [theEvent standardModifierFlags];
    
    if ([controlView superview] && NSMouseInRect([theEvent locationInView:controlView], [controlView bounds], [controlView isFlipped])) {
        area = kPDFNoArea;
    } else if ((modifiers & ~NSShiftKeyMask) == NSCommandKeyMask) {
        area = (area & kPDFPageArea) | SKSpecialToolArea;
    } else if ([self selectsText] == NO) {
        area = (area & kPDFPageArea) | SKDragArea;
    } else if ((area & kPDFPageArea) && (area & kPDFTextArea) == 0 && modifiers == 0) {
        NSPoint p = [theEvent locationInWindow];
        PDFPage *page = [self pageAndPoint:&p forEvent:theEvent nearest:YES];
        if ([[page selectionForRect:SKRectFromCenterAndSize(p, TEXT_SELECT_MARGIN_SIZE)] hasCharacters] == NO)
            area |= SKDragArea;
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

#pragma mark Services

- (BOOL)writeSelectionToPasteboard:(NSPasteboard *)pboard types:(NSArray *)types {
    if ([[self currentSelection] hasCharacters]) {
        if ([types containsObject:NSPasteboardTypeRTF] || [types containsObject:NSRTFPboardType]) {
            [pboard clearContents];
            [pboard writeObjects:[NSArray arrayWithObjects:[[self currentSelection] attributedString], nil]];
            return YES;
        } else if ([types containsObject:NSPasteboardTypeString] || [types containsObject:NSStringPboardType]) {
            [pboard clearContents];
            [pboard writeObjects:[NSArray arrayWithObjects:[[self currentSelection] string], nil]];
            return YES;
        }
    }
    if ([[SKSecondaryPDFView superclass] instancesRespondToSelector:_cmd])            [super writeSelectionToPasteboard:pboard types:types];
    return NO;
}

- (id)validRequestorForSendType:(NSString *)sendType returnType:(NSString *)returnType {
    if ([[self currentSelection] hasCharacters] && returnType == nil && ([sendType isEqualToString:NSPasteboardTypeString] || [sendType isEqualToString:NSPasteboardTypeRTF])) {
        return self;
    }
    return [super validRequestorForSendType:sendType returnType:returnType];
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
}

- (void)handlePDFViewScaleChangedNotification:(NSNotification *)notification {
    if ([self autoScales] == NO && [self synchronizeZoom] == NO)
        [self setScaleFactor:fmax([self scaleFactor], SKMinDefaultScaleMenuFactor) adjustPopup:YES];
}

- (void)handleScrollerStyleChangedNotification:(NSNotification *)notification {
    if ([NSScroller preferredScrollerStyle] == NSScrollerStyleLegacy)
        SKSetHasDefaultAppearance([self scrollView]);
    else
        SKSetHasLightAppearance([self scrollView]);
}

@end
