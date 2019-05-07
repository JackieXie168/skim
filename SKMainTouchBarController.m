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
#import "SKPDFView.h"
#import "PDFView_SKExtensions.h"
#import "PDFSelection_SKExtensions.h"
#import "NSImage_SKExtensions.h"
#import "NSEvent_SKExtensions.h"

#define SKDocumentTouchBarIdentifier @"SKDocumentTouchBar"

#define SKDocumentTouchBarPreviousNextItemIdentifier @"SKDocumentTouchBarPreviousNextItemIdentifier"
#define SKDocumentTouchBarZoomInActualOutItemIdentifier @"SKDocumentTouchBarZoomInActualOutItemIdentifier"
#define SKDocumentTouchBarToolModeItemIdentifier @"SKDocumentTouchBarToolModeItemIdentifier"
#define SKDocumentTouchBarAnnotationModeItemIdentifier @"SKDocumentTouchBarAnnotationModeItemIdentifier"
#define SKDocumentTouchBarAddNoteItemIdentifier @"SKDocumentTouchBarAddNoteItemIdentifier"

static NSString *noteToolImageNames[] = {@"ToolbarTextNotePopover", @"ToolbarAnchoredNotePopover", @"ToolbarCircleNotePopover", @"ToolbarSquareNotePopover", @"ToolbarHighlightNotePopover", @"ToolbarUnderlineNotePopover", @"ToolbarStrikeOutNotePopover", @"ToolbarLineNotePopover", @"ToolbarInkNotePopover"};

#if SDK_BEFORE(10_12)
@interface NSSegmentedControl (SKSierraDeclarations)
+ (NSSegmentedControl *)segmentedControlWithImages:(NSArray *)images trackingMode:(NSSegmentSwitchTracking)trackingMode target:(id)target action:(SEL)action;
@end
#endif

@interface SKMainTouchBarController (SKPrivate)

- (void)goToPreviousNextPage:(id)sender;
- (void)zoomInActualOut:(id)sender;
- (void)changeToolMode:(id)sender;
- (void)changeAnnotationMode:(id)sender;
- (void)createNewNote:(id)sender;

- (void)registerForNotifications;
- (void)handlePageChangedNotification:(NSNotification *)notification;
- (void)handleToolModeChangedNotification:(NSNotification *)notification;
- (void)handleAnnotationModeChangedNotification:(NSNotification *)notification;
- (void)handleSelectionChangedNotification:(NSNotification *)notification;

@end

@implementation SKMainTouchBarController

@synthesize mainController;

- (void)setMainController:(SKMainWindowController *)newMainController {
    if (newMainController != mainController) {
        if (mainController != nil)
            [[NSNotificationCenter defaultCenter] removeObserver: self];
        mainController = newMainController;
        [self registerForNotifications];
    }
}

- (void)dealloc {
    SKDESTROY(previousNextPageButton);
    SKDESTROY(zoomInActualOutButton);
    SKDESTROY(toolModeButton);
    SKDESTROY(annotationModeButton);
    SKDESTROY(noteButton);
    SKDESTROY(touchBar);
    SKDESTROY(touchBarItems);
    [super dealloc];
}

- (NSTouchBar *)touchBar {
    if (touchBar == nil) {
        touchBar = [[NSClassFromString(@"NSTouchBar") alloc] init];
        [touchBar setCustomizationIdentifier:SKDocumentTouchBarIdentifier];
        [touchBar setDelegate:self];
        [touchBar setCustomizationAllowedItemIdentifiers:[NSArray arrayWithObjects:SKDocumentTouchBarPreviousNextItemIdentifier, SKDocumentTouchBarZoomInActualOutItemIdentifier, SKDocumentTouchBarToolModeItemIdentifier, SKDocumentTouchBarAddNoteItemIdentifier, nil]];
        [touchBar setDefaultItemIdentifiers:[NSArray arrayWithObjects:SKDocumentTouchBarPreviousNextItemIdentifier, SKDocumentTouchBarToolModeItemIdentifier, nil]];
    }
    return touchBar;
}

- (NSTouchBarItem *)touchBar:(NSTouchBar *)aTouchBar makeItemForIdentifier:(NSTouchBarItemIdentifier)identifier {
    NSTouchBarItem *item = [touchBarItems objectForKey:identifier];
    if (item == nil) {
        if (touchBarItems == nil)
            touchBarItems = [[NSMutableDictionary alloc] init];
        if ([identifier isEqualToString:SKDocumentTouchBarPreviousNextItemIdentifier]) {
            NSArray *images = [NSArray arrayWithObjects:[NSImage imageNamed:SKImageNameToolbarPageUp], [NSImage imageNamed:SKImageNameToolbarPageDown], nil];
            if (previousNextPageButton == nil) {
                previousNextPageButton = [[NSSegmentedControl segmentedControlWithImages:images trackingMode:NSSegmentSwitchTrackingMomentary target:self action:@selector(goToPreviousNextPage:)] retain];
                [self handlePageChangedNotification:nil];
            }
            item = [[[NSClassFromString(@"NSCustomTouchBarItem") alloc] initWithIdentifier:identifier] autorelease];
            [(NSCustomTouchBarItem *)item setView:previousNextPageButton];
            [(NSCustomTouchBarItem *)item setCustomizationLabel:NSLocalizedString(@"Previous/Next", @"Toolbar item label")];
        } else if ([identifier isEqualToString:SKDocumentTouchBarZoomInActualOutItemIdentifier]) {
            if (zoomInActualOutButton == nil) {
                NSArray *images = [NSArray arrayWithObjects:[NSImage imageNamed:SKImageNameToolbarZoomIn], [NSImage imageNamed:SKImageNameToolbarZoomActual], [NSImage imageNamed:SKImageNameToolbarZoomOut], nil];
                zoomInActualOutButton = [[NSSegmentedControl segmentedControlWithImages:images trackingMode:NSSegmentSwitchTrackingMomentary target:self action:@selector(zoomInActualOut:)] retain];
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
                toolModeButton = [[NSSegmentedControl segmentedControlWithImages:images trackingMode:NSSegmentSwitchTrackingSelectOne target:self action:@selector(changeToolMode:)] retain];
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
                annotationModeButton = [[NSSegmentedControl segmentedControlWithImages:images trackingMode:NSSegmentSwitchTrackingSelectOne target:self action:@selector(changeAnnotationMode:)] retain];
                [self handleAnnotationModeChangedNotification:nil];
                [self handleSelectionChangedNotification:nil];
            }
            item = [[[NSClassFromString(@"NSCustomTouchBarItem") alloc] initWithIdentifier:identifier] autorelease];
            [(NSCustomTouchBarItem *)item setView:annotationModeButton];
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
                noteButton = [[NSSegmentedControl segmentedControlWithImages:images trackingMode:NSSegmentSwitchTrackingMomentary target:self action:@selector(createNewNote:)] retain];
            }
            item = [[[NSClassFromString(@"NSCustomTouchBarItem") alloc] initWithIdentifier:identifier] autorelease];
            [(NSCustomTouchBarItem *)item setView:noteButton];
            [(NSCustomTouchBarItem *)item setCustomizationLabel:NSLocalizedString(@"Add Note", @"Toolbar item label")];
        }
        if (item) {
            [touchBarItems setObject:item forKey:identifier];
        }
    }
    return item;
    
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
    if (newToolMode == SKNoteToolMode)
        [(NSPopoverTouchBarItem *)[touchBarItems objectForKey:SKDocumentTouchBarToolModeItemIdentifier] showPopover:nil];
}

- (void)changeAnnotationMode:(id)sender {
    NSInteger newAnnotationMode = [sender selectedTag];
    [mainController.pdfView setToolMode:SKNoteToolMode];
    [mainController.pdfView setAnnotationMode:newAnnotationMode];
    [(NSPopoverTouchBarItem *)[touchBarItems objectForKey:SKDocumentTouchBarToolModeItemIdentifier] dismissPopover:nil];
}

- (void)createNewNote:(id)sender {
    if ([mainController.pdfView hideNotes] == NO && [mainController.pdfView.document allowsNotes]) {
        NSInteger type = [sender selectedTag];
        [mainController.pdfView addAnnotationWithType:type];
    } else NSBeep();
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
}

@end
