//
//  SKMainWindowController_FullScreen.m
//  Skim
//
//  Created by Christiaan on 14/06/2019.
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

#import "SKMainWindowController_FullScreen.h"
#import "SKMainWindowController_UI.h"
#import "SKMainWindowController_Actions.h"
#import "SKSideWindow.h"
#import "SKFullScreenWindow.h"
#import "SKSideViewController.h"
#import "SKLeftSideViewController.h"
#import "SKRightSideViewController.h"
#import "SKApplication.h"
#import "SKTableView.h"
#import "SKSplitView.h"
#import "SKStringConstants.h"
#import "SKMainTouchBarController.h"
#import "SKMainDocument.h"
#import "SKSnapshotPDFView.h"
#import "NSGeometry_SKExtensions.h"
#import "NSGraphics_SKExtensions.h"
#import "NSResponder_SKExtensions.h"
#import "NSView_SKExtensions.h"
#import "PDFView_SKExtensions.h"
#import "PDFPage_SKExtensions.h"
#import "NSImage_SKExtensions.h"
#import "NSScreen_SKExtensions.h"

#define MAINWINDOWFRAME_KEY         @"windowFrame"
#define LEFTSIDEPANEWIDTH_KEY       @"leftSidePaneWidth"
#define RIGHTSIDEPANEWIDTH_KEY      @"rightSidePaneWidth"
#define HASHORIZONTALSCROLLER_KEY   @"hasHorizontalScroller"
#define HASVERTICALSCROLLER_KEY     @"hasVerticalScroller"
#define AUTOHIDESSCROLLERS_KEY      @"autoHidesScrollers"

#define WINDOW_KEY @"window"

#define PRESENTATION_SIDE_WINDOW_ALPHA 0.95

#define SKUseLegacyFullScreenKey @"SKUseLegacyFullScreen"
#define SKAutoHideToolbarInFullScreenKey @"SKAutoHideToolbarInFullScreen"
#define SKCollapseSidePanesInFullScreenKey @"SKCollapseSidePanesInFullScreen"

static BOOL useNativeFullScreen = NO;
static BOOL autoHideToolbarInFullScreen = NO;
static BOOL collapseSidePanesInFullScreen = NO;

static NSString *SKFullScreenToolbarOffsetKey = nil;
static CGFloat fullScreenToolbarOffset = 0.0;

@interface SKMainWindowController (SKFullScreenPrivate)
- (void)applyLeftSideWidth:(CGFloat)leftSideWidth rightSideWidth:(CGFloat)rightSideWidth;
@end

@implementation SKMainWindowController (FullScreen)

+ (void)defineFullScreenGlobalVariables {
    NSUserDefaults *sud = [NSUserDefaults standardUserDefaults];
    useNativeFullScreen = [sud boolForKey:SKUseLegacyFullScreenKey] == NO;
    autoHideToolbarInFullScreen = [sud boolForKey:SKAutoHideToolbarInFullScreenKey] || (RUNNING(10_7) && [sud objectForKey:SKAutoHideToolbarInFullScreenKey] == nil);
    collapseSidePanesInFullScreen = [sud boolForKey:SKCollapseSidePanesInFullScreenKey];
    
    SInt32 minor = 0;
    if (noErr == Gestalt(gestaltSystemVersionMinor, &minor)) {
        SKFullScreenToolbarOffsetKey = [[NSString alloc] initWithFormat:@"SKFullScreenToolbarOffset10_%i", (int)minor];
        fullScreenToolbarOffset = [sud doubleForKey:SKFullScreenToolbarOffsetKey];
    }
}

- (BOOL)useNativeFullScreen {
    return useNativeFullScreen;
}

#pragma mark Side Windows

- (void)showLeftSideWindow {
    if (leftSideWindow == nil)
        leftSideWindow = [[SKSideWindow alloc] initWithEdge:NSMinXEdge];
    
    if ([[[leftSideController.view window] firstResponder] isDescendantOf:leftSideController.view])
        [[leftSideController.view window] makeFirstResponder:nil];
    [leftSideWindow setMainView:leftSideController.view];
    
    if ([self interactionMode] == SKPresentationMode) {
        mwcFlags.savedLeftSidePaneState = [self leftSidePaneState];
        [self setLeftSidePaneState:SKSidePaneStateThumbnail];
        [leftSideWindow setAlphaValue:PRESENTATION_SIDE_WINDOW_ALPHA];
        [leftSideWindow setEnabled:NO];
        SKSetHasDarkAppearance(leftSideWindow);
        [leftSideWindow makeFirstResponder:leftSideController.thumbnailTableView];
        [leftSideWindow attachToWindow:[self window]];
        [leftSideWindow expand];
    } else {
        [leftSideWindow makeFirstResponder:leftSideController.searchField];
        [leftSideWindow attachToWindow:[self window]];
    }
}

- (void)showRightSideWindow {
    if (rightSideWindow == nil)
        rightSideWindow = [[SKSideWindow alloc] initWithEdge:NSMaxXEdge];
    
    if ([[[rightSideController.view window] firstResponder] isDescendantOf:rightSideController.view])
        [[rightSideController.view window] makeFirstResponder:nil];
    [rightSideWindow setMainView:rightSideController.view];
    
    if ([self interactionMode] == SKPresentationMode) {
        [rightSideWindow setAlphaValue:PRESENTATION_SIDE_WINDOW_ALPHA];
        [rightSideWindow setEnabled:NO];
        [rightSideWindow attachToWindow:[self window]];
        [rightSideWindow expand];
    } else {
        [rightSideWindow attachToWindow:[self window]];
    }
}

- (void)hideLeftSideWindow {
    if ([[leftSideController.view window] isEqual:leftSideWindow]) {
        [leftSideWindow remove];
        
        if ([[leftSideWindow firstResponder] isDescendantOf:leftSideController.view])
            [leftSideWindow makeFirstResponder:nil];
        [leftSideController.view setFrame:SKShrinkRect(NSInsetRect([leftSideContentView bounds], -1.0, -1.0), 1.0, NSMaxYEdge)];
        [leftSideContentView addSubview:leftSideController.view];
        
        if ([self interactionMode] == SKPresentationMode)
            [self setLeftSidePaneState:mwcFlags.savedLeftSidePaneState];
        
        SKDESTROY(leftSideWindow);
    }
}

- (void)hideRightSideWindow {
    if ([[rightSideController.view window] isEqual:rightSideWindow]) {
        [rightSideWindow remove];
        
        if ([[rightSideWindow firstResponder] isDescendantOf:rightSideController.view])
            [rightSideWindow makeFirstResponder:nil];
        [rightSideController.view setFrame:SKShrinkRect(NSInsetRect([rightSideContentView bounds], -1.0, -1.0), 1.0, NSMaxYEdge)];
        [rightSideContentView addSubview:rightSideController.view];
        
        SKDESTROY(rightSideWindow);
    }
}

#pragma mark Custom Full Screen Windows

- (BOOL)handleRightMouseDown:(NSEvent *)theEvent {
    if ([self interactionMode] == SKPresentationMode) {
        [self doGoToPreviousPage:nil];
        return YES;
    }
    return NO;
}

- (void)forceSubwindowsOnTop:(BOOL)flag {
    for (NSWindowController *wc in [[self document] windowControllers]) {
        if ([wc respondsToSelector:@selector(setForceOnTop:)] && wc != presentationPreview)
            [(id)wc setForceOnTop:flag];
    }
}

- (NSArray *)alternateScreensForScreen:(NSScreen *)screen {
    NSMutableDictionary *screens = [NSMutableDictionary dictionary];
    NSMutableArray *primaryIDs = [NSMutableArray array];
    NSNumber *primaryID = nil;
    for (NSScreen *aScreen in [NSScreen screens]) {
        NSDictionary *deviceDescription = [aScreen deviceDescription] ;
        if ([deviceDescription objectForKey:NSDeviceIsScreen] == nil)
            continue;
        NSNumber *aScreenNumber = [deviceDescription objectForKey:@"NSScreenNumber"];
        [screens setObject:aScreen forKey:aScreenNumber];
        CGDirectDisplayID displayID = (CGDirectDisplayID)[aScreenNumber unsignedIntValue];
        NSNumber *aPrimaryID = [NSNumber numberWithUnsignedInt:CGDisplayMirrorsDisplay(displayID) ?: displayID];
        if ([primaryIDs containsObject:aPrimaryID] == NO)
            [primaryIDs addObject:aPrimaryID];
        if (aScreen == screen)
            primaryID = aPrimaryID;
    }
    NSMutableArray *alternateScreens = [NSMutableArray array];
    for (NSNumber *aPrimaryID in primaryIDs) {
        if ([aPrimaryID isEqual:primaryID] == NO)
            [alternateScreens addObject:[screens objectForKey:aPrimaryID]];
    }
    return alternateScreens;
}

- (void)enterPresentationMode {
    NSScrollView *scrollView = [[pdfView documentView] enclosingScrollView];
    [savedNormalSetup setObject:[NSNumber numberWithBool:[scrollView hasHorizontalScroller]] forKey:HASHORIZONTALSCROLLER_KEY];
    [savedNormalSetup setObject:[NSNumber numberWithBool:[scrollView hasVerticalScroller]] forKey:HASVERTICALSCROLLER_KEY];
    [savedNormalSetup setObject:[NSNumber numberWithBool:[scrollView autohidesScrollers]] forKey:AUTOHIDESSCROLLERS_KEY];
    // Set up presentation mode
    [pdfView setNeedsRewind:YES];
    [pdfView setBackgroundColor:RUNNING(10_12) ? [NSColor blackColor] : [NSColor clearColor]];
    [pdfView setAutoScales:YES];
    [pdfView setDisplayMode:kPDFDisplaySinglePage];
    [pdfView setDisplayBox:kPDFDisplayBoxCropBox];
    [pdfView setDisplaysPageBreaks:NO];
    [scrollView setAutohidesScrollers:YES];
    [scrollView setHasHorizontalScroller:NO];
    [scrollView setHasVerticalScroller:NO];
    
    [pdfView setCurrentSelection:nil];
    if ([pdfView hasReadingBar])
        [pdfView toggleReadingBar];
    
    if ([self presentationNotesDocument]) {
        PDFDocument *pdfDoc = [[self presentationNotesDocument] pdfDocument];
        NSInteger offset = [self presentationNotesOffset];
        NSUInteger pageIndex = MAX(0, MIN((NSInteger)[pdfDoc pageCount], (NSInteger)[[pdfView currentPage] pageIndex] + offset));
        if ([self presentationNotesDocument] == [self document]) {
            presentationPreview = [[SKSnapshotWindowController alloc] init];
            
            [presentationPreview setDelegate:self];
            
            NSScreen *screen = [[self window] screen];
            screen = [[self alternateScreensForScreen:screen] firstObject] ?: screen;
            
            [presentationPreview setPdfDocument:[pdfView document]
                              previewPageNumber:pageIndex
                                displayOnScreen:screen];
            
            [[self document] addWindowController:presentationPreview];
        } else {
            [[self presentationNotesDocument] setCurrentPage:[pdfDoc pageAtIndex:pageIndex]];
        }
        [self addPresentationNotesNavigation];
    }
    
    // prevent sleep
    if (activityAssertionID == kIOPMNullAssertionID && kIOReturnSuccess != IOPMAssertionCreateWithName(kIOPMAssertionTypeNoDisplaySleep, kIOPMAssertionLevelOn, CFSTR("Skim"), &activityAssertionID))
        activityAssertionID = kIOPMNullAssertionID;
}

- (void)exitPresentationMode {
    if (activityAssertionID != kIOPMNullAssertionID && kIOReturnSuccess == IOPMAssertionRelease(activityAssertionID))
        activityAssertionID = kIOPMNullAssertionID;
    
    if (presentationPreview) {
        [presentationPreview close];
        [presentationPreview autorelease];
        presentationPreview = nil;
    }
    [self removePresentationNotesNavigation];
    
    NSScrollView *scrollView = [[pdfView documentView] enclosingScrollView];
    [scrollView setHasHorizontalScroller:[[savedNormalSetup objectForKey:HASHORIZONTALSCROLLER_KEY] boolValue]];
    [scrollView setHasVerticalScroller:[[savedNormalSetup objectForKey:HASVERTICALSCROLLER_KEY] boolValue]];
    [scrollView setAutohidesScrollers:[[savedNormalSetup objectForKey:AUTOHIDESSCROLLERS_KEY] boolValue]];
}

- (void)fadeInFullScreenWindowWithBackgroundColor:(NSColor *)backgroundColor level:(NSInteger)level screen:(NSScreen *)screen {
    if ([[mainWindow firstResponder] isDescendantOf:pdfSplitView])
        [mainWindow makeFirstResponder:nil];
    
    SKFullScreenWindow *fullScreenWindow = [[SKFullScreenWindow alloc] initWithScreen:screen ?: [mainWindow screen] backgroundColor:backgroundColor level:NSPopUpMenuWindowLevel isMain:YES];
    
    [mainWindow setDelegate:nil];
    [self setWindow:fullScreenWindow];
    [fullScreenWindow fadeInBlocking];
    [fullScreenWindow makeKeyWindow];
    [NSApp updatePresentationOptionsForWindow:fullScreenWindow];
    [mainWindow setAnimationBehavior:NSWindowAnimationBehaviorNone];
    [mainWindow orderOut:nil];
    [mainWindow setAnimationBehavior:NSWindowAnimationBehaviorDefault];
    [fullScreenWindow setLevel:level];
    [fullScreenWindow orderFront:nil];
    [NSApp addWindowsItem:fullScreenWindow title:[self windowTitleForDocumentDisplayName:[[self document] displayName]] filename:NO];
    [fullScreenWindow release];
}

- (void)fadeInFullScreenView:(NSView *)view inset:(CGFloat)inset {
    SKFullScreenWindow *fullScreenWindow = (SKFullScreenWindow *)[self window];
    SKFullScreenWindow *fadeWindow = [[[SKFullScreenWindow alloc] initWithScreen:[fullScreenWindow screen] backgroundColor:[fullScreenWindow backgroundColor] level:[fullScreenWindow level] isMain:NO] autorelease];
    
    [fadeWindow orderWindow:NSWindowAbove relativeTo:[fullScreenWindow windowNumber]];
    [view setFrame:NSInsetRect([[fullScreenWindow contentView] bounds], inset, 0.0)];
    [[fullScreenWindow contentView] addSubview:view];
    [pdfView layoutDocumentView];
    [pdfView requiresDisplay];
    [fullScreenWindow makeFirstResponder:pdfView];
    [fullScreenWindow recalculateKeyViewLoop];
    [fullScreenWindow setDelegate:self];
    [fadeWindow fadeOut];
}

- (void)fadeOutFullScreenView:(NSView *)view {
    SKFullScreenWindow *fullScreenWindow = (SKFullScreenWindow *)[self window];
    SKFullScreenWindow *fadeWindow = [[SKFullScreenWindow alloc] initWithScreen:[fullScreenWindow screen] backgroundColor:[fullScreenWindow backgroundColor] level:[fullScreenWindow level] isMain:NO];
    
    [fadeWindow setAlphaValue:0.0];
    [fadeWindow orderWindow:NSWindowAbove relativeTo:[fullScreenWindow windowNumber]];
    [fadeWindow fadeInBlocking];
    [view removeFromSuperview];
    [fullScreenWindow display];
    [fullScreenWindow setDelegate:nil];
    [fullScreenWindow makeFirstResponder:nil];
    [fadeWindow orderOut:nil];
    [fadeWindow release];
}

- (void)fadeOutFullScreenWindow {
    SKFullScreenWindow *fullScreenWindow = (SKFullScreenWindow *)[[[self window] retain] autorelease];
    NSWindowCollectionBehavior collectionBehavior = [mainWindow collectionBehavior];
    
    [self setWindow:mainWindow];
    if (NSPointInRect(SKCenterPoint([mainWindow frame]), [[fullScreenWindow screen] frame])) {
        [mainWindow setAlphaValue:0.0];
        [mainWindow setAnimationBehavior:NSWindowAnimationBehaviorNone];
        // trick to make sure the main window shows up in the same space as the fullscreen window
        [fullScreenWindow addChildWindow:mainWindow ordered:NSWindowBelow];
        [fullScreenWindow removeChildWindow:mainWindow];
        [fullScreenWindow setLevel:NSPopUpMenuWindowLevel];
        // these can change due to the child window trick
        [mainWindow setLevel:NSNormalWindowLevel];
        [mainWindow setAlphaValue:1.0];
        [mainWindow setCollectionBehavior:collectionBehavior];
    } else {
        [mainWindow makeKeyAndOrderFront:nil];
    }
    [mainWindow display];
    [mainWindow makeFirstResponder:pdfView];
    [mainWindow recalculateKeyViewLoop];
    [mainWindow setDelegate:self];
    [mainWindow makeKeyWindow];
    [NSApp updatePresentationOptionsForWindow:mainWindow];
    [mainWindow setAnimationBehavior:NSWindowAnimationBehaviorDefault];
    [NSApp removeWindowsItem:fullScreenWindow];
    [fullScreenWindow fadeOut];
}

- (void)showBlankingWindows {
    if ([[NSUserDefaults standardUserDefaults] boolForKey:SKBlankAllScreensInFullScreenKey]) {
        NSScreen *screen = [[self window] screen];
        NSArray *screensToBlank = [self alternateScreensForScreen:screen];
        if ([screensToBlank count] > 0) {
            if (nil == blankingWindows)
                blankingWindows = [[NSMutableArray alloc] init];
            NSColor *backgroundColor = [pdfView backgroundColor];
            for (NSScreen *screenToBlank in screensToBlank) {
                SKFullScreenWindow *aWindow = [[SKFullScreenWindow alloc] initWithScreen:screenToBlank backgroundColor:backgroundColor level:NSFloatingWindowLevel isMain:NO];
                [aWindow setCollectionBehavior:NSWindowCollectionBehaviorCanJoinAllSpaces];
                [aWindow setHidesOnDeactivate:YES];
                [aWindow fadeIn];
                [blankingWindows addObject:aWindow];
                [aWindow release];
            }
        }
    }
}

- (void)removeBlankingWindows {
    [blankingWindows makeObjectsPerformSelector:@selector(fadeOut)];
    [blankingWindows autorelease];
    blankingWindows = nil;
}

- (void)enterFullscreen {
    SKInteractionMode wasInteractionMode = [self interactionMode];
    if ([self canEnterFullscreen] == NO)
        return;
    
    if (wasInteractionMode == SKPresentationMode) {
        [self exitFullscreen];
    }
    
    if (useNativeFullScreen) {
        [[self window] toggleFullScreen:nil];
        return;
    }
    
    NSColor *backgroundColor = [PDFView defaultFullScreenBackgroundColor];
    NSDictionary *fullScreenSetup = [[NSUserDefaults standardUserDefaults] dictionaryForKey:SKDefaultFullScreenPDFDisplaySettingsKey];
    PDFPage *page = [[self pdfView] currentPage];
    
    mwcFlags.isSwitchingFullScreen = 1;
    
    if ([[findController view] window])
        [findController toggleAboveView:nil animate:NO];
    
    // remember normal setup to return to, we must do this before changing the interactionMode
    if (wasInteractionMode == SKNormalMode)
        [savedNormalSetup setDictionary:[self currentPDFSettings]];
    
    interactionMode = SKLegacyFullScreenMode;
    
    if (wasInteractionMode == SKPresentationMode) {
        [self exitPresentationMode];
        [self hideLeftSideWindow];
        
        [NSApp updatePresentationOptionsForWindow:[self window]];
        
        [pdfView setFrame:[pdfContentView bounds]];
        [pdfContentView addSubview:pdfView];
        [pdfSplitView setFrame:NSInsetRect([[[self window] contentView] bounds], [SKSideWindow requiredMargin], 0.0)];
        [[[self window] contentView] addSubview:pdfSplitView];
        
        [[self window] setBackgroundColor:backgroundColor];
        [[self window] setLevel:NSNormalWindowLevel];
        [pdfView setBackgroundColor:backgroundColor];
        [secondaryPdfView setBackgroundColor:backgroundColor];
        [self applyPDFSettings:[fullScreenSetup count] ? fullScreenSetup : savedNormalSetup rewind:YES];
        [pdfView layoutDocumentView];
        [pdfView requiresDisplay];
    } else {
        [self fadeInFullScreenWindowWithBackgroundColor:backgroundColor level:NSNormalWindowLevel screen:nil];
        
        [pdfView setBackgroundColor:backgroundColor];
        [secondaryPdfView setBackgroundColor:backgroundColor];
        [self applyPDFSettings:fullScreenSetup rewind:YES];
        
        [self fadeInFullScreenView:pdfSplitView inset:[SKSideWindow requiredMargin]];
    }
    
    if ([[[self pdfView] currentPage] isEqual:page] == NO)
        [[self pdfView] goToPage:page];
    
    mwcFlags.isSwitchingFullScreen = 0;
    
    [self forceSubwindowsOnTop:YES];
    
    [pdfView setInteractionMode:SKLegacyFullScreenMode];
    [touchBarController interactionModeChanged];
    
    [self showBlankingWindows];
    [self showLeftSideWindow];
    [self showRightSideWindow];
}

#pragma mark API

- (void)enterPresentation {
    SKInteractionMode wasInteractionMode = [self interactionMode];
    if ([self canEnterPresentation] == NO)
        return;
    
    if (wasInteractionMode == SKFullScreenMode) {
        mwcFlags.wantsPresentation = 1;
        [[self window] toggleFullScreen:nil];
        return;
    }
    
    NSColor *backgroundColor = [NSColor blackColor];
    NSInteger level = [[NSUserDefaults standardUserDefaults] boolForKey:SKUseNormalLevelForPresentationKey] ? NSNormalWindowLevel : NSPopUpMenuWindowLevel;
    PDFPage *page = [[self pdfView] currentPage];
    
    // remember normal setup to return to, we must do this before changing the interactionMode
    if (wasInteractionMode == SKNormalMode)
        [savedNormalSetup setDictionary:[self currentPDFSettings]];
    
    mwcFlags.isSwitchingFullScreen = 1;
    
    if ([[findController view] window])
        [findController toggleAboveView:nil animate:NO];
    
    interactionMode = SKPresentationMode;
    
    if (wasInteractionMode == SKLegacyFullScreenMode) {
        [self enterPresentationMode];
        
        [NSApp updatePresentationOptionsForWindow:[self window]];
        
        [pdfSplitView setFrame:[centerContentView bounds]];
        [centerContentView addSubview:pdfSplitView];
        [pdfView setFrame:[[[self window] contentView] bounds]];
        [[[self window] contentView] addSubview:pdfView];
        
        [[self window] setBackgroundColor:backgroundColor];
        [[self window] setLevel:level];
        [pdfView layoutDocumentView];
        [pdfView requiresDisplay];
        
        [self forceSubwindowsOnTop:NO];
        
        [self hideLeftSideWindow];
        [self hideRightSideWindow];
        [self removeBlankingWindows];
    } else {
        NSScreen *screen = [mainWindow screen];
        if ([self presentationNotesDocument] && [self presentationNotesDocument] != [self document]) {
            NSArray *screens = [self alternateScreensForScreen:[[[self presentationNotesDocument] mainWindow] screen]];
            if ([screens count] > 0 && [screens containsObject:screen] == NO)
                screen = [screens firstObject];
        }
        
        [self fadeInFullScreenWindowWithBackgroundColor:backgroundColor level:level screen:screen];
        
        [self enterPresentationMode];
        
        [self fadeInFullScreenView:pdfView inset:0.0];
    }
    
    if ([[[self pdfView] currentPage] isEqual:page] == NO)
        [[self pdfView] goToPage:page];
    
    mwcFlags.isSwitchingFullScreen = 0;
    
    [pdfView setInteractionMode:SKPresentationMode];
    [touchBarController interactionModeChanged];
}

- (void)exitFullscreen {
    SKInteractionMode wasInteractionMode = [self interactionMode];
    if ([self canExitFullscreen] == NO && [self canExitPresentation] == NO)
        return;
    
    if (wasInteractionMode == SKFullScreenMode) {
        [[self window] toggleFullScreen:nil];
        return;
    }
    
    NSColor *backgroundColor = [PDFView defaultBackgroundColor];
    NSView *view;
    NSView *contentView;
    PDFPage *page = [[self pdfView] currentPage];
    
    mwcFlags.isSwitchingFullScreen = 1;
    
    if ([[findController view] window])
        [findController toggleAboveView:nil animate:NO];
    
    if (wasInteractionMode == SKLegacyFullScreenMode) {
        view = pdfSplitView;
        contentView = centerContentView;
    } else {
        view = pdfView;
        contentView = pdfContentView;
    }
    
    [self hideLeftSideWindow];
    [self hideRightSideWindow];
    
    // do this first, otherwise the navigation window may be covered by fadeWindow and then reveiled again, which looks odd
    [pdfView setInteractionMode:SKNormalMode];
    
    [self fadeOutFullScreenView:view];
    
    // this should be done before exitPresentationMode to get a smooth transition
    [view setFrame:[contentView bounds]];
    [contentView addSubview:view];
    [pdfView setBackgroundColor:backgroundColor];
    [secondaryPdfView setBackgroundColor:backgroundColor];
    
    if (wasInteractionMode == SKPresentationMode)
        [self exitPresentationMode];
    [self applyPDFSettings:savedNormalSetup rewind:YES];
    [savedNormalSetup removeAllObjects];
    
    [pdfView layoutDocumentView];
    [pdfView requiresDisplay];
    
    if ([[[self pdfView] currentPage] isEqual:page] == NO)
        [[self pdfView] goToPage:page];
    
    mwcFlags.isSwitchingFullScreen = 0;
    
    [self forceSubwindowsOnTop:NO];
    
    interactionMode = SKNormalMode;
    [touchBarController interactionModeChanged];
    
    [self fadeOutFullScreenWindow];
    
    // the page number may have changed
    [self synchronizeWindowTitleWithDocumentName];
    
    [self removeBlankingWindows];
}

- (BOOL)canEnterFullscreen {
    if (mwcFlags.isSwitchingFullScreen)
        return NO;
    if (useNativeFullScreen)
        return [self interactionMode] == SKNormalMode || [self interactionMode] == SKPresentationMode;
    else
        return [[self pdfDocument] isLocked] == NO &&
        ([self interactionMode] == SKNormalMode || [self interactionMode] == SKPresentationMode) &&
        (!RUNNING(10_12) || [[[self window] tabbedWindows] count] < 2);
}

- (BOOL)canEnterPresentation {
    return mwcFlags.isSwitchingFullScreen == 0 && [[self pdfDocument] isLocked] == NO &&
    ([self interactionMode] == SKNormalMode || [self interactionMode] == SKFullScreenMode || [self interactionMode] == SKLegacyFullScreenMode) &&
    (!RUNNING(10_12) || [[[self window] tabbedWindows] count] < 2);
}

- (BOOL)canExitFullscreen {
    return mwcFlags.isSwitchingFullScreen == 0 &&
    ([self interactionMode] == SKFullScreenMode || [self interactionMode] == SKLegacyFullScreenMode);
}

- (BOOL)canExitPresentation {
    return mwcFlags.isSwitchingFullScreen == 0 && [self interactionMode] == SKPresentationMode;
}

#pragma mark NSWindowDelegate Full Screen Methods

static inline NSRect simulatedFullScreenWindowFrame(NSWindow *window) {
    CGFloat offset = 17.0;
    if (autoHideToolbarInFullScreen)
        offset = NSHeight([window frame]) - NSHeight([window respondsToSelector:@selector(contentLayoutRect)] ? [window contentLayoutRect] : [[window contentView] frame]);
    else if ([[window toolbar] isVisible] == NO)
        offset = NSHeight([NSWindow frameRectForContentRect:NSZeroRect styleMask:NSTitledWindowMask]);
    else if (fullScreenToolbarOffset > 0.0)
        offset = fullScreenToolbarOffset;
    else if (RUNNING_AFTER(10_10))
        offset = 17.0;
    else if (RUNNING_AFTER(10_8))
        offset = 13.0;
    else
        offset = 10.0;
    return SKShrinkRect([[window screen] frame], -offset, NSMaxYEdge);
}

static inline CGFloat toolbarViewOffset(NSWindow *window) {
    NSToolbar *toolbar = [window toolbar];
    NSView *view = nil;
    if ([toolbar displayMode] == NSToolbarDisplayModeLabelOnly) {
        @try { view = [toolbar valueForKey:@"toolbarView"]; }
        @catch (id e) {}
    } else {
        for (NSToolbarItem *item in [toolbar visibleItems])
            if ((view = [item view]))
                break;
    }
    if (view)
        return NSMaxY([view convertRectToScreen:[view frame]]) - NSMaxY([[view window] frame]);
    return 0.0;
}

- (void)windowWillEnterFullScreen:(NSNotification *)notification {
    mwcFlags.isSwitchingFullScreen = 1;
    interactionMode = SKFullScreenMode;
    if ([[pdfView document] isLocked] == NO || [savedNormalSetup count] == 0)
        [savedNormalSetup setDictionary:[self currentPDFSettings]];
    NSString *frameString = NSStringFromRect([[self window] frame]);
    [savedNormalSetup setObject:frameString forKey:MAINWINDOWFRAME_KEY];
}

- (NSApplicationPresentationOptions)window:(NSWindow *)window willUseFullScreenPresentationOptions:(NSApplicationPresentationOptions)proposedOptions {
    if (autoHideToolbarInFullScreen)
        return proposedOptions | NSApplicationPresentationAutoHideToolbar;
    return proposedOptions;
}

- (NSArray *)customWindowsToEnterFullScreenForWindow:(NSWindow *)window {
    return [[[self document] windowControllers] valueForKey:WINDOW_KEY];
}

- (void)window:(NSWindow *)window startCustomAnimationToEnterFullScreenWithDuration:(NSTimeInterval)duration {
    if (fullScreenToolbarOffset <= 0.0 && autoHideToolbarInFullScreen == NO && [[mainWindow toolbar] isVisible])
        fullScreenToolbarOffset = toolbarViewOffset(mainWindow);
    [(SKMainWindow *)window setDisableConstrainedFrame:YES];
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
        [context setDuration:duration - 0.1];
        [[window animator] setFrame:simulatedFullScreenWindowFrame(window) display:YES];
        for (NSView *view in [[[window standardWindowButton:NSWindowCloseButton] superview] subviews])
            if ([view isKindOfClass:[NSControl class]])
                [[view animator] setAlphaValue:0.0];
    }
                        completionHandler:^{
                            [(SKMainWindow *)window setDisableConstrainedFrame:NO];
                        }];
}

- (void)windowDidEnterFullScreen:(NSNotification *)notification {
    if (fullScreenToolbarOffset < 0.0 && autoHideToolbarInFullScreen == NO && [[mainWindow toolbar] isVisible]) {
        CGFloat toolbarItemOffset = toolbarViewOffset(mainWindow);
        if (toolbarItemOffset < 0.0)
            // save the offset for the next time, we may guess it wrong as it varies between OS versions
            fullScreenToolbarOffset = toolbarItemOffset - fullScreenToolbarOffset;
        if (SKFullScreenToolbarOffsetKey)
            [[NSUserDefaults standardUserDefaults] setDouble:fullScreenToolbarOffset forKey:SKFullScreenToolbarOffsetKey];
    }
    NSColor *backgroundColor = [PDFView defaultFullScreenBackgroundColor];
    NSDictionary *fullScreenSetup = [[NSUserDefaults standardUserDefaults] dictionaryForKey:SKDefaultFullScreenPDFDisplaySettingsKey];
    [pdfView setInteractionMode:SKFullScreenMode];
    [touchBarController interactionModeChanged];
    [pdfView setBackgroundColor:backgroundColor];
    [secondaryPdfView setBackgroundColor:backgroundColor];
    if ([[pdfView document] isLocked] == NO && [fullScreenSetup count])
        [self applyPDFSettings:fullScreenSetup rewind:YES];
    if (collapseSidePanesInFullScreen) {
        [savedNormalSetup setObject:[NSNumber numberWithDouble:[self leftSideWidth]] forKey:LEFTSIDEPANEWIDTH_KEY];
        [savedNormalSetup setObject:[NSNumber numberWithDouble:[self rightSideWidth]] forKey:RIGHTSIDEPANEWIDTH_KEY];
        [self applyLeftSideWidth:0.0 rightSideWidth:0.0];
    }
    [self forceSubwindowsOnTop:YES];
    mwcFlags.isSwitchingFullScreen = 0;
}

- (void)windowDidFailToEnterFullScreen:(NSWindow *)window {
    if ([[pdfView document] isLocked] == NO || [savedNormalSetup count] == 1)
        [savedNormalSetup removeAllObjects];
    interactionMode = SKNormalMode;
    mwcFlags.isSwitchingFullScreen = 0;
}

- (void)windowWillExitFullScreen:(NSNotification *)notification {
    mwcFlags.isSwitchingFullScreen = 1;
    NSColor *backgroundColor = [PDFView defaultBackgroundColor];
    [pdfView setInteractionMode:SKNormalMode];
    [pdfView setBackgroundColor:backgroundColor];
    [secondaryPdfView setBackgroundColor:backgroundColor];
    if ([[[NSUserDefaults standardUserDefaults] dictionaryForKey:SKDefaultFullScreenPDFDisplaySettingsKey] count])
        [self applyPDFSettings:savedNormalSetup rewind:YES];
    NSNumber *leftWidth = [savedNormalSetup objectForKey:LEFTSIDEPANEWIDTH_KEY];
    NSNumber *rightWidth = [savedNormalSetup objectForKey:RIGHTSIDEPANEWIDTH_KEY];
    if (leftWidth && rightWidth)
        [self applyLeftSideWidth:[leftWidth doubleValue] rightSideWidth:[rightWidth doubleValue]];
    [self forceSubwindowsOnTop:NO];
    interactionMode = SKNormalMode;
}

- (NSArray *)customWindowsToExitFullScreenForWindow:(NSWindow *)window {
    return [[[self document] windowControllers] valueForKey:WINDOW_KEY];
}

- (void)window:(NSWindow *)window startCustomAnimationToExitFullScreenWithDuration:(NSTimeInterval)duration {
    NSString *frameString = [savedNormalSetup objectForKey:MAINWINDOWFRAME_KEY];
    NSRect frame = NSRectFromString(frameString);
    [(SKMainWindow *)window setDisableConstrainedFrame:YES];
    [window setStyleMask:[window styleMask] & ~NSFullScreenWindowMask];
    for (NSView *view in [[[window standardWindowButton:NSWindowCloseButton] superview] subviews])
        if ([view isKindOfClass:[NSControl class]])
            [view setAlphaValue:0.0];
    [window setFrame:simulatedFullScreenWindowFrame(window) display:YES];
    [window setLevel:NSStatusWindowLevel];
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
        [context setDuration:duration - 0.1];
        [[window animator] setFrame:frame display:YES];
        for (NSView *view in [[[window standardWindowButton:NSWindowCloseButton] superview] subviews])
            if ([view isKindOfClass:[NSControl class]])
                [[view animator] setAlphaValue:1.0];
    }
                        completionHandler:^{
                            [(SKMainWindow *)window setDisableConstrainedFrame:NO];
                            [window setLevel:NSNormalWindowLevel];
                        }];
}

- (void)windowDidExitFullScreen:(NSNotification *)notification {
    NSString *frameString = [savedNormalSetup objectForKey:MAINWINDOWFRAME_KEY];
    if (frameString)
        [[self window] setFrame:NSRectFromString(frameString) display:YES];
    if ([[pdfView document] isLocked] == NO || [savedNormalSetup count] == 1)
        [savedNormalSetup removeAllObjects];
    mwcFlags.isSwitchingFullScreen = 0;
    if (mwcFlags.wantsPresentation) {
        mwcFlags.wantsPresentation = 0;
        [self enterPresentation];
    } else {
        [touchBarController interactionModeChanged];
    }
}

- (void)windowDidFailToExitFullScreen:(NSWindow *)window {
    if (interactionMode == SKNormalMode) {
        interactionMode = SKFullScreenMode;
        NSColor *backgroundColor = [PDFView defaultFullScreenBackgroundColor];
        NSDictionary *fullScreenSetup = [[NSUserDefaults standardUserDefaults] dictionaryForKey:SKDefaultFullScreenPDFDisplaySettingsKey];
        [pdfView setInteractionMode:SKFullScreenMode];
        [pdfView setBackgroundColor:backgroundColor];
        [secondaryPdfView setBackgroundColor:backgroundColor];
        if ([[pdfView document] isLocked] == NO)
            [self applyPDFSettings:fullScreenSetup rewind:YES];
        [self applyLeftSideWidth:0.0 rightSideWidth:0.0];
        [self forceSubwindowsOnTop:YES];
    }
    mwcFlags.isSwitchingFullScreen = 0;
    mwcFlags.wantsPresentation = 0;
}

#pragma mark Presentation Notes Navigation

- (NSView *)presentationNotesView {
    if ([[self presentationNotesDocument] isEqual:[self document]])
        return [presentationPreview pdfView];
    else
        return [(SKMainDocument *)[self presentationNotesDocument] pdfView];
}

- (void)addPresentationNotesNavigation {
    [self removePresentationNotesNavigation];
    NSView *notesView = [self presentationNotesView];
    if (notesView) {
        presentationNotesTrackingArea = [[NSTrackingArea alloc] initWithRect:NSZeroRect options:NSTrackingMouseEnteredAndExited | NSTrackingActiveInActiveApp | NSTrackingInVisibleRect owner:self userInfo:nil];
        [notesView addTrackingArea:presentationNotesTrackingArea];
    }
}

- (void)removePresentationNotesNavigation {
    if (presentationNotesTrackingArea) {
        [[self presentationNotesView] removeTrackingArea:presentationNotesTrackingArea];
        SKDESTROY(presentationNotesTrackingArea);
    }
    if (presentationNotesButton) {
        [presentationNotesButton removeFromSuperview];
        SKDESTROY(presentationNotesButton);
    }
}

- (void)mouseEntered:(NSEvent *)event {
    if ([event trackingArea] == presentationNotesTrackingArea) {
        NSView *notesView = [self presentationNotesView];
        if (presentationNotesButton == nil) {
            presentationNotesButton = [[NSButton alloc] initWithFrame:NSMakeRect(0.0, 0.0, 30.0, 50.0)];
            [presentationNotesButton setButtonType:NSMomentaryChangeButton];
            [presentationNotesButton setBordered:NO];
            [presentationNotesButton setImage:[NSImage bitmapImageWithSize:NSMakeSize(30.0, 50.0) drawingHandler:^(NSRect rect){
                NSBezierPath *path = [NSBezierPath bezierPath];
                [path moveToPoint:NSMakePoint(5.0, 45.0)];
                [path lineToPoint:NSMakePoint(25.0, 25.0)];
                [path lineToPoint:NSMakePoint(5.0, 5.0)];
                [path setLineCapStyle:NSRoundLineCapStyle];
                [path setLineWidth:10.0];
                [[NSColor whiteColor] setStroke];
                [path stroke];
                [path setLineWidth:5.0];
                [[NSColor blackColor] setStroke];
                [path stroke];
            }]];
            [presentationNotesButton setTarget:self];
            [presentationNotesButton setAction:@selector(doGoToNextPage:)];
            [presentationNotesButton setAutoresizingMask:NSViewMinXMargin | NSViewMaxXMargin | NSViewMinYMargin | NSViewMaxYMargin];
        }
        [presentationNotesButton setAlphaValue:0.0];
        [presentationNotesButton setFrame:SKRectFromCenterAndSize(SKCenterPoint([notesView frame]), [presentationNotesButton frame].size)];
        [notesView addSubview:presentationNotesButton positioned:NSWindowAbove relativeTo:nil];
        [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context){
            [[presentationNotesButton animator] setAlphaValue:1.0];
        } completionHandler:^{}];
    } else if ([[SKMainWindowController superclass] instancesRespondToSelector:_cmd]) {
        [super mouseEntered:event];
    }
}

- (void)mouseExited:(NSEvent *)event {
    if ([event trackingArea] == presentationNotesTrackingArea && presentationNotesButton) {
        [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context){
            [[presentationNotesButton animator] setAlphaValue:0.0];
        } completionHandler:^{
            [presentationNotesButton removeFromSuperview];
        }];
    } else if ([[SKMainWindowController superclass] instancesRespondToSelector:_cmd]) {
        [super mouseExited:event];
    }
}

@end
