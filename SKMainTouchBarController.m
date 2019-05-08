//
//  SKMainTouchBarController.m
//  Skim
//
//  Created by Christiaan Hofman on 06/05/2019.
/*
 This software is Copyright (c) 2019
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

#import "SKMainTouchBarController.h"
#import "SKMainWindowController.h"
#import "SKMainWindowController_Actions.h"
#import "SKPDFView.h"
#import "PDFView_SKExtensions.h"
#import "PDFSelection_SKExtensions.h"
#import "NSImage_SKExtensions.h"
#import "NSEvent_SKExtensions.h"
#import <SkimNotes/SkimNotes.h>
#import "PDFAnnotation_SKExtensions.h"
#import "SKStringConstants.h"
#import "NSValueTransformer_SKExtensions.h"
#import "NSUserDefaultsController_SKExtensions.h"

#define SKDocumentTouchBarIdentifier @"SKDocumentTouchBar"

#define SKDocumentTouchBarPreviousNextItemIdentifier @"SKDocumentTouchBarPreviousNextItemIdentifier"
#define SKDocumentTouchBarZoomInActualOutItemIdentifier @"SKDocumentTouchBarZoomInActualOutItemIdentifier"
#define SKDocumentTouchBarToolModeItemIdentifier @"SKDocumentTouchBarToolModeItemIdentifier"
#define SKDocumentTouchBarAnnotationModeItemIdentifier @"SKDocumentTouchBarAnnotationModeItemIdentifier"
#define SKDocumentTouchBarAddNoteItemIdentifier @"SKDocumentTouchBarAddNoteItemIdentifier"
#define SKDocumentTouchBarAddNotePopoverItemIdentifier @"SKDocumentTouchBarAddNotePopoverItemIdentifier"
#define SKDocumentTouchBarFullScreenItemIdentifier @"SKDocumentTouchBarFullScreenItemIdentifier"
#define SKDocumentTouchBarPresentationItemIdentifier @"SKDocumentTouchBarPresentationItemIdentifier"
#define SKDocumentTouchBarFavoriteColorsItemIdentifier @"SKDocumentTouchBarFavoriteColorsItemIdentifier"
#define SKDocumentTouchBarFavoriteColorItemIdentifier @"SKDocumentTouchBarFavoriteColorItemIdentifier"

static NSString *noteToolImageNames[] = {@"ToolbarTextNotePopover", @"ToolbarAnchoredNotePopover", @"ToolbarCircleNotePopover", @"ToolbarSquareNotePopover", @"ToolbarHighlightNotePopover", @"ToolbarUnderlineNotePopover", @"ToolbarStrikeOutNotePopover", @"ToolbarLineNotePopover", @"ToolbarInkNotePopover"};

static char SKMainTouchBarDefaultsObservationContext;

#if SDK_BEFORE(10_12)
@interface NSSegmentedControl (SKSierraDeclarations)
+ (NSSegmentedControl *)segmentedControlWithImages:(NSArray *)images trackingMode:(NSSegmentSwitchTracking)trackingMode target:(id)target action:(SEL)action;
@end
#endif

#if SDK_BEFORE(10_10)
enum {
    NSSegmentStyleSeparated = 8
}
#endif

@interface SKMainTouchBarController (SKPrivate)

- (void)goToPreviousNextPage:(id)sender;
- (void)zoomInActualOut:(id)sender;
- (void)changeToolMode:(id)sender;
- (void)changeAnnotationMode:(id)sender;
- (void)createNewNote:(id)sender;
- (void)toggleFullscreen:(id)sender;
- (void)togglePresentation:(id)sender;

- (void)registerForNotifications;
- (void)unregisterForNotifications;
- (void)handlePageChangedNotification:(NSNotification *)notification;
- (void)handleToolModeChangedNotification:(NSNotification *)notification;
- (void)handleAnnotationModeChangedNotification:(NSNotification *)notification;
- (void)handleSelectionChangedNotification:(NSNotification *)notification;

@end

@implementation SKMainTouchBarController

@synthesize mainController;

- (void)setMainController:(SKMainWindowController *)newMainController {
    if (newMainController != mainController) {
        if (mainController)
            [self unregisterForNotifications];
        mainController = newMainController;
        if (mainController)
            [self registerForNotifications];
    }
}

- (void)dealloc {
    SKDESTROY(previousNextPageButton);
    SKDESTROY(zoomInActualOutButton);
    SKDESTROY(toolModeButton);
    SKDESTROY(annotationModeButton);
    SKDESTROY(noteButton);
    SKDESTROY(colorsScrubber);
    SKDESTROY(touchBarItems);
    SKDESTROY(colors);
    [super dealloc];
}

- (NSArray *)colors {
    if (colors == nil) {
        NSValueTransformer *transformer = [NSValueTransformer valueTransformerForName:SKUnarchiveFromDataArrayTransformerName];
        colors = [[transformer transformedValue:[[NSUserDefaults standardUserDefaults] objectForKey:SKSwatchColorsKey]] retain];
    }
    return colors;
}

- (NSTouchBar *)makeTouchBar {
    NSTouchBar *touchBar = [[[NSClassFromString(@"NSTouchBar") alloc] init] autorelease];
    [touchBar setCustomizationIdentifier:SKDocumentTouchBarIdentifier];
    [touchBar setDelegate:self];
    [touchBar setCustomizationAllowedItemIdentifiers:[NSArray arrayWithObjects:SKDocumentTouchBarPreviousNextItemIdentifier, SKDocumentTouchBarZoomInActualOutItemIdentifier, SKDocumentTouchBarToolModeItemIdentifier, SKDocumentTouchBarAddNotePopoverItemIdentifier, SKDocumentTouchBarFullScreenItemIdentifier, SKDocumentTouchBarPresentationItemIdentifier, SKDocumentTouchBarFavoriteColorsItemIdentifier, nil]];
    [touchBar setDefaultItemIdentifiers:[NSArray arrayWithObjects:SKDocumentTouchBarPreviousNextItemIdentifier, SKDocumentTouchBarToolModeItemIdentifier, SKDocumentTouchBarAddNotePopoverItemIdentifier, nil]];
    return touchBar;
}

- (NSTouchBarItem *)touchBar:(NSTouchBar *)aTouchBar makeItemForIdentifier:(NSString *)identifier {
    NSTouchBarItem *item = [touchBarItems objectForKey:identifier];
    if (item == nil) {
        if (touchBarItems == nil)
            touchBarItems = [[NSMutableDictionary alloc] init];
        if ([identifier isEqualToString:SKDocumentTouchBarPreviousNextItemIdentifier]) {
            if (previousNextPageButton == nil) {
                NSArray *images = [NSArray arrayWithObjects:[NSImage imageNamed:SKImageNameToolbarPageUp], [NSImage imageNamed:SKImageNameToolbarPageDown], nil];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wpartial-availability"
                previousNextPageButton = [[NSSegmentedControl segmentedControlWithImages:images trackingMode:NSSegmentSwitchTrackingMomentary target:self action:@selector(goToPreviousNextPage:)] retain];
#pragma clang diagnostic pop
                [self handlePageChangedNotification:nil];
                if (RUNNING_AFTER(10_9))
                    [previousNextPageButton setSegmentStyle:NSSegmentStyleSeparated];
            }
            item = [[[NSClassFromString(@"NSCustomTouchBarItem") alloc] initWithIdentifier:identifier] autorelease];
            [(NSCustomTouchBarItem *)item setView:previousNextPageButton];
            [(NSCustomTouchBarItem *)item setCustomizationLabel:NSLocalizedString(@"Previous/Next", @"Toolbar item label")];
        } else if ([identifier isEqualToString:SKDocumentTouchBarZoomInActualOutItemIdentifier]) {
            if (zoomInActualOutButton == nil) {
                NSArray *images = [NSArray arrayWithObjects:[NSImage imageNamed:SKImageNameToolbarZoomIn], [NSImage imageNamed:SKImageNameToolbarZoomActual], [NSImage imageNamed:SKImageNameToolbarZoomOut], nil];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wpartial-availability"
                zoomInActualOutButton = [[NSSegmentedControl segmentedControlWithImages:images trackingMode:NSSegmentSwitchTrackingMomentary target:self action:@selector(zoomInActualOut:)] retain];
#pragma clang diagnostic pop
                if (RUNNING_AFTER(10_9))
                    [zoomInActualOutButton setSegmentStyle:NSSegmentStyleSeparated];
                [self handleScaleChangedNotification:nil];
            }
            item = [[[NSClassFromString(@"NSCustomTouchBarItem") alloc] initWithIdentifier:identifier] autorelease];
            [(NSCustomTouchBarItem *)item setView:zoomInActualOutButton];
            [(NSCustomTouchBarItem *)item setCustomizationLabel:NSLocalizedString(@"Zoom", @"Toolbar item label")];
        } else if ([identifier isEqualToString:SKDocumentTouchBarToolModeItemIdentifier]) {
            NSTouchBar *popoverTouchBar = [[[NSClassFromString(@"NSTouchBar") alloc] init] autorelease];
            [popoverTouchBar setDelegate:self];
            [popoverTouchBar setDefaultItemIdentifiers:[NSArray arrayWithObjects:SKDocumentTouchBarAnnotationModeItemIdentifier, nil]];
            if (toolModeButton == nil) {
                NSArray *images = [NSArray arrayWithObjects:[NSImage imageNamed:SKImageNameToolbarTextTool],
                                   [NSImage imageNamed:SKImageNameToolbarMoveTool],
                                   [NSImage imageNamed:SKImageNameToolbarMagnifyTool],
                                   [NSImage imageNamed:SKImageNameToolbarSelectTool],
                                   [NSImage imageNamed:SKImageNameTextNote], nil];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wpartial-availability"
                toolModeButton = [[NSSegmentedControl segmentedControlWithImages:images trackingMode:NSSegmentSwitchTrackingSelectOne target:self action:@selector(changeToolMode:)] retain];
#pragma clang diagnostic pop
                [self handleToolModeChangedNotification:nil];
                [self handleAnnotationModeChangedNotification:nil];
            }
            item = [[[NSClassFromString(@"NSPopoverTouchBarItem") alloc] initWithIdentifier:identifier] autorelease];
            [(NSPopoverTouchBarItem *)item setCollapsedRepresentation:toolModeButton];
            [(NSPopoverTouchBarItem *)item setPopoverTouchBar:popoverTouchBar];
            [(NSPopoverTouchBarItem *)item setPressAndHoldTouchBar:popoverTouchBar];
            [(NSPopoverTouchBarItem *)item setCustomizationLabel:NSLocalizedString(@"Tool Mode", @"Toolbar item label")];
            [toolModeButton addGestureRecognizer:[(NSPopoverTouchBarItem *)item makeStandardActivatePopoverGestureRecognizer]];
        } else if ([identifier isEqualToString:SKDocumentTouchBarAnnotationModeItemIdentifier]) {
            if (annotationModeButton == nil) {
                NSArray *images = [NSArray arrayWithObjects:[NSImage imageNamed:SKImageNameTextNote],
                                   [NSImage imageNamed:SKImageNameAnchoredNote],
                                   [NSImage imageNamed:SKImageNameCircleNote],
                                   [NSImage imageNamed:SKImageNameSquareNote],
                                   [NSImage imageNamed:SKImageNameHighlightNote],
                                   [NSImage imageNamed:SKImageNameUnderlineNote],
                                   [NSImage imageNamed:SKImageNameStrikeOutNote],
                                   [NSImage imageNamed:SKImageNameLineNote],
                                   [NSImage imageNamed:SKImageNameInkNote], nil];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wpartial-availability"
                annotationModeButton = [[NSSegmentedControl segmentedControlWithImages:images trackingMode:NSSegmentSwitchTrackingSelectOne target:self action:@selector(changeAnnotationMode:)] retain];
#pragma clang diagnostic pop
                [self handleAnnotationModeChangedNotification:nil];
            }
            item = [[[NSClassFromString(@"NSCustomTouchBarItem") alloc] initWithIdentifier:identifier] autorelease];
            [(NSCustomTouchBarItem *)item setView:annotationModeButton];
        } else if ([identifier isEqualToString:SKDocumentTouchBarAddNotePopoverItemIdentifier]) {
            NSTouchBar *popoverTouchBar = [[[NSClassFromString(@"NSTouchBar") alloc] init] autorelease];
            [popoverTouchBar setDelegate:self];
            [popoverTouchBar setDefaultItemIdentifiers:[NSArray arrayWithObjects:SKDocumentTouchBarAddNoteItemIdentifier, nil]];
            item = [[[NSClassFromString(@"NSPopoverTouchBarItem") alloc] initWithIdentifier:identifier] autorelease];
            [(NSPopoverTouchBarItem *)item setCollapsedRepresentationImage:[NSImage imageNamed:@"NSTouchBarAddTemplate"]];
            [(NSPopoverTouchBarItem *)item setPopoverTouchBar:popoverTouchBar];
            [(NSPopoverTouchBarItem *)item setCustomizationLabel:NSLocalizedString(@"Add Note", @"Toolbar item label")];
        } else if ([identifier isEqualToString:SKDocumentTouchBarAddNoteItemIdentifier]) {
            if (noteButton == nil) {
                NSArray *images = [NSArray arrayWithObjects:[NSImage imageNamed:SKImageNameToolbarAddTextNote],
                                   [NSImage imageNamed:SKImageNameToolbarAddAnchoredNote],
                                   [NSImage imageNamed:SKImageNameToolbarAddCircleNote],
                                   [NSImage imageNamed:SKImageNameToolbarAddSquareNote],
                                   [NSImage imageNamed:SKImageNameToolbarAddHighlightNote],
                                   [NSImage imageNamed:SKImageNameToolbarAddUnderlineNote],
                                   [NSImage imageNamed:SKImageNameToolbarAddStrikeOutNote],
                                   [NSImage imageNamed:SKImageNameToolbarAddLineNote], nil];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wpartial-availability"
                noteButton = [[NSSegmentedControl segmentedControlWithImages:images trackingMode:NSSegmentSwitchTrackingMomentary target:self action:@selector(createNewNote:)] retain];
                [self handleToolModeChangedNotification:nil];
                [self handleSelectionChangedNotification:nil];
#pragma clang diagnostic pop
            }
            item = [[[NSClassFromString(@"NSCustomTouchBarItem") alloc] initWithIdentifier:identifier] autorelease];
            [(NSCustomTouchBarItem *)item setView:noteButton];
        } else if ([identifier isEqualToString:SKDocumentTouchBarFullScreenItemIdentifier]) {
            if (fullScreenButton == nil) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wpartial-availability"
                fullScreenButton = [[NSSegmentedControl segmentedControlWithImages:[NSArray arrayWithObjects:[NSImage imageNamed:@"NSTouchBarEnterFullScreenTemplate"], nil] trackingMode:NSSegmentSwitchTrackingMomentary target:self action:@selector(toggleFullscreen:)] retain];
#pragma clang diagnostic pop
                [self interactionModeChanged];
            }
            item = [[[NSClassFromString(@"NSCustomTouchBarItem") alloc] initWithIdentifier:identifier] autorelease];
            [(NSCustomTouchBarItem *)item setView:fullScreenButton];
            [(NSCustomTouchBarItem *)item setCustomizationLabel:NSLocalizedString(@"Full Screen", @"Toolbar item label")];
        } else if ([identifier isEqualToString:SKDocumentTouchBarPresentationItemIdentifier]) {
            if (presentationButton == nil) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wpartial-availability"
                presentationButton = [[NSSegmentedControl segmentedControlWithImages:[NSArray arrayWithObjects:[NSImage imageNamed:@"NSTouchBarSlideshowTemplate"], nil] trackingMode:NSSegmentSwitchTrackingMomentary target:self action:@selector(togglePresentation:)] retain];
#pragma clang diagnostic pop
            }
            item = [[[NSClassFromString(@"NSCustomTouchBarItem") alloc] initWithIdentifier:identifier] autorelease];
            [(NSCustomTouchBarItem *)item setView:presentationButton];
            [(NSCustomTouchBarItem *)item setCustomizationLabel:NSLocalizedString(@"Presentation", @"Toolbar item label")];
        } else if ([identifier isEqualToString:SKDocumentTouchBarFavoriteColorsItemIdentifier]) {
            if (colorsScrubber == nil) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wpartial-availability"
                colorsScrubber = [[NSClassFromString(@"NSScrubber") alloc] initWithFrame:NSMakeRect(0.0, 0.0, 150, 30.0)];
                [colorsScrubber setDelegate:self];
                [colorsScrubber setDataSource:self];
                [[colorsScrubber scrubberLayout] setItemSpacing:0.0];
                [[colorsScrubber scrubberLayout] setItemSize:NSMakeSize(30.0, 30.0)];
                [colorsScrubber registerClass:[NSClassFromString(@"NSScrubberImageItemView") class] forItemIdentifier:SKDocumentTouchBarFavoriteColorItemIdentifier];
                [colorsScrubber setSelectionOverlayStyle:[NSClassFromString(@"NSScrubberSelectionStyle") outlineOverlayStyle]];
#pragma clang diagnostic pop
            }
            item = [[[NSClassFromString(@"NSCustomTouchBarItem") alloc] initWithIdentifier:identifier] autorelease];
            [(NSCustomTouchBarItem *)item setView:colorsScrubber];
            [(NSColorPickerTouchBarItem *)item setCustomizationLabel:NSLocalizedString(@"Favorite Colors", @"Toolbar item label")];
        }
        if (item) {
            [touchBarItems setObject:item forKey:identifier];
        }
    }
    return item;
    
}

#pragma mark NSScrubberDataSource, NSScrubberDelegate, NSScrubberFlowLayoutDelegate

- (NSInteger)numberOfItemsForScrubber:(NSScrubber *)scrubber {
    return [[self colors] count];
}

- (NSScrubberItemView *)scrubber:(NSScrubber *)scrubber viewForItemAtIndex:(NSInteger)idx {
    NSScrubberImageItemView *itemView = [scrubber makeItemWithIdentifier:SKDocumentTouchBarFavoriteColorItemIdentifier owner:nil];
    NSColor *color = [[self colors] objectAtIndex:idx];
    NSImage *image = [NSImage bitmapImageWithSize:NSMakeSize(30.0, 30.0) drawingHandler:^(NSRect rect){ [color drawSwatchInRect:rect]; }];
    [itemView setImage:image];
    return itemView;
}

- (void)scrubber:(NSScrubber *)scrubber didSelectItemAtIndex:(NSInteger)selectedIndex {
    if (selectedIndex >= 0 && selectedIndex < (NSInteger)[[self colors] count]) {
        NSColor *color = [[self colors] objectAtIndex:selectedIndex];
        PDFAnnotation *annotation = [mainController.pdfView activeAnnotation];
        BOOL isShift = ([NSEvent standardModifierFlags] & NSShiftKeyMask) != 0;
        BOOL isAlt = ([NSEvent standardModifierFlags] & NSAlternateKeyMask) != 0;
        if ([annotation isSkimNote])
            [annotation setColor:color alternate:isAlt updateDefaults:isShift];
    }
    [scrubber setSelectedIndex:-1];
}

#pragma mark Actions

- (void)goToPreviousNextPage:(id)sender {
    NSInteger tag = [sender selectedTag];
    if (tag == 0)
        [mainController.pdfView goToPreviousPage:sender];
    else
        [mainController.pdfView goToNextPage:sender];
}

- (void)zoomInActualOut:(id)sender {
    NSInteger tag = [sender selectedTag];
    if (tag == 0)
        [mainController.pdfView zoomOut:sender];
    else if (tag == 1)
        ([NSEvent standardModifierFlags] & NSAlternateKeyMask) ? [mainController.pdfView setPhysicalScaleFactor:1.0] : [mainController.pdfView setScaleFactor:1.0];
    else if (tag == 2)
        [mainController.pdfView zoomIn:sender];
}

- (void)changeToolMode:(id)sender {
    NSInteger newToolMode = [sender selectedTag];
    [mainController.pdfView setToolMode:newToolMode];
}

- (void)changeAnnotationMode:(id)sender {
    NSInteger newAnnotationMode = [sender selectedTag];
    [mainController.pdfView setToolMode:SKNoteToolMode];
    [mainController.pdfView setAnnotationMode:newAnnotationMode];
}

- (void)createNewNote:(id)sender {
    if ([mainController.pdfView hideNotes] == NO && [mainController.pdfView.document allowsNotes]) {
        NSInteger type = [sender selectedTag];
        [mainController.pdfView addAnnotationWithType:type];
    } else NSBeep();
}

- (void)toggleFullscreen:(id)sender {
    [mainController toggleFullscreen:sender];
}

- (void)togglePresentation:(id)sender {
    [mainController togglePresentation:sender];
}

#pragma mark Notifications

- (void)handlePageChangedNotification:(NSNotification *)notification {
    [previousNextPageButton setEnabled:[mainController.pdfView canGoToPreviousPage] forSegment:0];
    [previousNextPageButton setEnabled:[mainController.pdfView canGoToNextPage] forSegment:1];
}

- (void)handleScaleChangedNotification:(NSNotification *)notification {
    [zoomInActualOutButton setEnabled:[mainController.pdfView canZoomOut] forSegment:0];
    [zoomInActualOutButton setEnabled:YES forSegment:1];
    [zoomInActualOutButton setEnabled:[mainController.pdfView canZoomIn] forSegment:2];
}

- (void)handleToolModeChangedNotification:(NSNotification *)notification {
    [toolModeButton selectSegmentWithTag:[mainController.pdfView toolMode]];
    BOOL enabled = ([mainController.pdfView toolMode] == SKTextToolMode || [mainController.pdfView toolMode] == SKNoteToolMode) && [mainController.pdfView hideNotes] == NO;
    [noteButton setEnabled:enabled];
}

- (void)handleAnnotationModeChangedNotification:(NSNotification *)notification {
    [toolModeButton setImage:[NSImage imageNamed:noteToolImageNames[[mainController.pdfView annotationMode]]] forSegment:SKNoteToolMode];
    [annotationModeButton selectSegmentWithTag:[mainController.pdfView annotationMode]];
}

- (void)handleSelectionChangedNotification:(NSNotification *)notification {
    BOOL enabled = ([mainController.pdfView toolMode] == SKTextToolMode || [mainController.pdfView toolMode] == SKNoteToolMode) && [mainController.pdfView hideNotes] == NO && [[mainController.pdfView currentSelection] hasCharacters];
    [noteButton setEnabled:enabled forSegment:SKHighlightNote];
    [noteButton setEnabled:enabled forSegment:SKUnderlineNote];
    [noteButton setEnabled:enabled forSegment:SKStrikeOutNote];
}

- (void)interactionModeChanged {
    SKInteractionMode mode = [mainController interactionMode];
    NSString *imageName = (mode == SKFullScreenMode || mode == SKLegacyFullScreenMode) ? NSImageNameTouchBarExitFullScreenTemplate : NSImageNameTouchBarEnterFullScreenTemplate;
    [fullScreenButton setImage:[NSImage imageNamed:imageName] forSegment:0];
}

- (void)registerForNotifications {
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    
    [nc addObserver:self selector:@selector(handlePageChangedNotification:)
               name:PDFViewPageChangedNotification object:mainController.pdfView];
    [nc addObserver:self selector:@selector(handleScaleChangedNotification:)
               name:PDFViewScaleChangedNotification object:mainController.pdfView];
    [nc addObserver:self selector:@selector(handleToolModeChangedNotification:)
               name:SKPDFViewToolModeChangedNotification object:mainController.pdfView];
    [nc addObserver:self selector:@selector(handleAnnotationModeChangedNotification:)
               name:SKPDFViewAnnotationModeChangedNotification object:mainController.pdfView];
    [nc addObserver:self selector:@selector(handleSelectionChangedNotification:)
               name:SKPDFViewCurrentSelectionChangedNotification object:mainController.pdfView];
    
    [[NSUserDefaultsController sharedUserDefaultsController] addObserver:self forKey:SKSwatchColorsKey context:&SKMainTouchBarDefaultsObservationContext];
}

- (void)unregisterForNotifications {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    @try {
        [[NSUserDefaultsController sharedUserDefaultsController] removeObserver:self forKey:SKSwatchColorsKey];
    }
    @catch (id e) {}
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (context == &SKMainTouchBarDefaultsObservationContext) {
        SKDESTROY(colors);
        [colorsScrubber reloadData];
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}
@end
