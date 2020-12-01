//
//  SKMainWindowController_FullScreen.m
//  Skim
//
//  Created by Christiaan on 14/06/2019.
/*
 This software is Copyright (c) 2019-2020
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
#import "SKOverviewView.h"
#import "SKTopBarView.h"
#import "NSGeometry_SKExtensions.h"
#import "NSGraphics_SKExtensions.h"
#import "NSResponder_SKExtensions.h"
#import "NSView_SKExtensions.h"
#import "PDFView_SKExtensions.h"
#import "PDFPage_SKExtensions.h"
#import "NSImage_SKExtensions.h"
#import "NSScreen_SKExtensions.h"
#import "NSColor_SKExtensions.h"

#define MAINWINDOWFRAME_KEY         @"windowFrame"
#define LEFTSIDEPANEWIDTH_KEY       @"leftSidePaneWidth"
#define RIGHTSIDEPANEWIDTH_KEY      @"rightSidePaneWidth"
#define HASHORIZONTALSCROLLER_KEY   @"hasHorizontalScroller"
#define HASVERTICALSCROLLER_KEY     @"hasVerticalScroller"
#define AUTOHIDESSCROLLERS_KEY      @"autoHidesScrollers"
#define DRAWSBACKGROUND_KEY         @"drawsBackground"

#define WINDOW_KEY @"window"

#define SKAutoHideToolbarInFullScreenKey @"SKAutoHideToolbarInFullScreen"
#define SKCollapseSidePanesInFullScreenKey @"SKCollapseSidePanesInFullScreen"
#define SKResizablePresentationKey @"SKResizablePresentation"

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
    autoHideToolbarInFullScreen = [sud boolForKey:SKAutoHideToolbarInFullScreenKey];
    collapseSidePanesInFullScreen = [sud boolForKey:SKCollapseSidePanesInFullScreenKey];
    
    NSOperatingSystemVersion systemVersion = [[NSProcessInfo processInfo] operatingSystemVersion];
    SKFullScreenToolbarOffsetKey = [[NSString alloc] initWithFormat:@"SKFullScreenToolbarOffset%ld_%ld", (long)systemVersion.majorVersion, (long)systemVersion.minorVersion];
    fullScreenToolbarOffset = [sud doubleForKey:SKFullScreenToolbarOffsetKey];
}

#pragma mark Side Windows

- (void)showSideWindow {
    if ([[[leftSideController.view window] firstResponder] isDescendantOf:leftSideController.view])
        [[leftSideController.view window] makeFirstResponder:nil];
    
    if (sideWindow == nil)
        sideWindow = [[SKSideWindow alloc] initWithView:leftSideController.view];
    
    [leftSideController.topBar setDrawsBackground:NO];
    
    mwcFlags.savedLeftSidePaneState = [self leftSidePaneState];
    [self setLeftSidePaneState:SKSidePaneStateThumbnail];
    [sideWindow makeFirstResponder:leftSideController.thumbnailTableView];
    [sideWindow attachToWindow:[self window]];
}

- (void)hideSideWindow {
    if ([[leftSideController.view window] isEqual:sideWindow]) {
        [sideWindow remove];
        
        if ([[sideWindow firstResponder] isDescendantOf:leftSideController.view])
            [sideWindow makeFirstResponder:nil];
        [leftSideController.topBar setDrawsBackground:YES];
        [leftSideController.view setFrame:[leftSideContentView bounds]];
        [leftSideContentView addSubview:leftSideController.view];
        
        [self setLeftSidePaneState:mwcFlags.savedLeftSidePaneState];
        
        SKDESTROY(sideWindow);
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

static inline BOOL insufficientScreenSize(NSValue *value) {
    NSSize size = [value sizeValue];
    return size.height < 100.0 && size.width < 100.0;
}

- (NSArray *)alternateScreensForScreen:(NSScreen *)screen {
    NSMutableDictionary *screens = [NSMutableDictionary dictionary];
    NSMutableArray *screenNumbers = [NSMutableArray array];
    NSNumber *screenNumber = nil;
    for (NSScreen *aScreen in [NSScreen screens]) {
        NSDictionary *deviceDescription = [aScreen deviceDescription];
        if ([deviceDescription objectForKey:NSDeviceIsScreen] == nil ||
            insufficientScreenSize([deviceDescription objectForKey:NSDeviceSize]))
            continue;
        NSNumber *aScreenNumber = [deviceDescription objectForKey:@"NSScreenNumber"];
        [screens setObject:aScreen forKey:aScreenNumber];
        CGDirectDisplayID displayID = (CGDirectDisplayID)[aScreenNumber unsignedIntValue];
        displayID = CGDisplayMirrorsDisplay(displayID);
        if (displayID == kCGNullDirectDisplay)
            [screenNumbers addObject:aScreenNumber];
        if ([aScreen isEqual:screen])
            screenNumber = displayID == kCGNullDirectDisplay ? aScreenNumber : [NSNumber numberWithUnsignedInt:displayID];
    }
    NSMutableArray *alternateScreens = [NSMutableArray array];
    for (NSNumber *aScreenNumber in screenNumbers) {
        if ([aScreenNumber isEqual:screenNumber] == NO)
            [alternateScreens addObject:[screens objectForKey:aScreenNumber]];
    }
    return alternateScreens;
}

- (void)enterPresentationMode {
    NSScrollView *scrollView = [pdfView scrollView];
    [savedNormalSetup setObject:[NSNumber numberWithBool:[scrollView hasHorizontalScroller]] forKey:HASHORIZONTALSCROLLER_KEY];
    [savedNormalSetup setObject:[NSNumber numberWithBool:[scrollView hasVerticalScroller]] forKey:HASVERTICALSCROLLER_KEY];
    [savedNormalSetup setObject:[NSNumber numberWithBool:[scrollView autohidesScrollers]] forKey:AUTOHIDESSCROLLERS_KEY];
    [savedNormalSetup setObject:[NSNumber numberWithBool:[scrollView drawsBackground]] forKey:DRAWSBACKGROUND_KEY];
    // Set up presentation mode
    [pdfView setNeedsRewind:YES];
    [pdfView setBackgroundColor:[NSColor clearColor]];
    [pdfView setAutoScales:YES];
    [pdfView setDisplayMode:kPDFDisplaySinglePage];
    [pdfView setDisplayBox:kPDFDisplayBoxCropBox];
    [pdfView setDisplaysPageBreaks:NO];
    [scrollView setAutohidesScrollers:YES];
    [scrollView setHasHorizontalScroller:NO];
    [scrollView setHasVerticalScroller:NO];
    [scrollView setDrawsBackground:NO];
    
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
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:SKResizablePresentationKey]) {
        [[self window] setStyleMask:[[self window] styleMask] | NSResizableWindowMask];
        [[self window] setHasShadow:YES];
    }
    
    // prevent sleep
    if (activity == nil)
        activity = [[[NSProcessInfo processInfo] beginActivityWithOptions:NSActivityUserInitiated | NSActivityIdleDisplaySleepDisabled | NSActivityIdleSystemSleepDisabled  reason:@"Presentation"] retain];
}

- (void)exitPresentationMode {
    if (activity) {
        [[NSProcessInfo processInfo] endActivity:activity];
        SKDESTROY(activity);
    }
    
    if (presentationPreview) {
        [presentationPreview close];
        [presentationPreview autorelease];
        presentationPreview = nil;
    }
    [self removePresentationNotesNavigation];
    
    NSScrollView *scrollView = [pdfView scrollView];
    [scrollView setHasHorizontalScroller:[[savedNormalSetup objectForKey:HASHORIZONTALSCROLLER_KEY] boolValue]];
    [scrollView setHasVerticalScroller:[[savedNormalSetup objectForKey:HASVERTICALSCROLLER_KEY] boolValue]];
    [scrollView setAutohidesScrollers:[[savedNormalSetup objectForKey:AUTOHIDESSCROLLERS_KEY] boolValue]];
    [scrollView setDrawsBackground:[[savedNormalSetup objectForKey:DRAWSBACKGROUND_KEY] boolValue]];
}

- (void)fadeInFullScreenWindowOnScreen:(NSScreen *)screen {
    if ([[mainWindow firstResponder] isDescendantOf:pdfSplitView])
        [mainWindow makeFirstResponder:nil];
    
    SKFullScreenWindow *fullScreenWindow = [[SKFullScreenWindow alloc] initWithScreen:screen ?: [mainWindow screen] level:NSPopUpMenuWindowLevel isMain:YES];
    
    [mainWindow setDelegate:nil];
    [self setWindow:fullScreenWindow];
    [fullScreenWindow fadeInBlocking:YES];
    [fullScreenWindow makeKeyWindow];
    [NSApp updatePresentationOptionsForWindow:fullScreenWindow];
    [mainWindow setAnimationBehavior:NSWindowAnimationBehaviorNone];
    [mainWindow orderOut:nil];
    [mainWindow setAnimationBehavior:NSWindowAnimationBehaviorDefault];
    if ([[NSUserDefaults standardUserDefaults] boolForKey:SKUseNormalLevelForPresentationKey])
        [fullScreenWindow setLevel:NSNormalWindowLevel];
    [fullScreenWindow orderFront:nil];
    [NSApp addWindowsItem:fullScreenWindow title:[self windowTitleForDocumentDisplayName:[[self document] displayName]] filename:NO];
    [fullScreenWindow release];
}

- (void)fadeInFullScreenView {
    SKFullScreenWindow *fullScreenWindow = (SKFullScreenWindow *)[self window];
    SKFullScreenWindow *fadeWindow = [[[SKFullScreenWindow alloc] initWithScreen:[fullScreenWindow screen] level:[fullScreenWindow level] isMain:NO] autorelease];
    
    [fadeWindow setFrame:[fullScreenWindow frame] display:NO];
    [fadeWindow orderWindow:NSWindowAbove relativeTo:[fullScreenWindow windowNumber]];
    [pdfView setFrame:[[fullScreenWindow contentView] bounds]];
    [[fullScreenWindow contentView] addSubview:pdfView];
    [pdfView layoutDocumentView];
    [pdfView requiresDisplay];
    [fullScreenWindow makeFirstResponder:pdfView];
    [fullScreenWindow recalculateKeyViewLoop];
    [fullScreenWindow setDelegate:self];
    [fadeWindow fadeOutBlocking:NO];
}

- (void)fadeOutFullScreenView {
    SKFullScreenWindow *fullScreenWindow = (SKFullScreenWindow *)[self window];
    SKFullScreenWindow *fadeWindow = [[SKFullScreenWindow alloc] initWithScreen:[fullScreenWindow screen] level:[fullScreenWindow level] isMain:NO];
    
    [fadeWindow setFrame:[fullScreenWindow frame] display:NO];
    [fadeWindow setAlphaValue:0.0];
    [fadeWindow orderWindow:NSWindowAbove relativeTo:[fullScreenWindow windowNumber]];
    [fadeWindow fadeInBlocking:YES];
    
    while ([[fullScreenWindow childWindows] count] > 0) {
        NSWindow *childWindow = [[fullScreenWindow childWindows] lastObject];
        [fullScreenWindow removeChildWindow:childWindow];
        [childWindow orderOut:nil];
    }
    
    NSView *view = [[[fullScreenWindow contentView] subviews] firstObject];
    [view removeFromSuperview];
    [fullScreenWindow display];
    [fullScreenWindow setDelegate:nil];
    [fullScreenWindow makeFirstResponder:nil];
    [fadeWindow orderOut:nil];
    [fadeWindow release];
}

- (void)fadeOutFullScreenWindow {
    SKFullScreenWindow *fullScreenWindow = (SKFullScreenWindow *)[[[self window] retain] autorelease];
    
    [self setWindow:mainWindow];
    [mainWindow setAlphaValue:0.0];
    if (NSPointInRect(SKCenterPoint([mainWindow frame]), [[fullScreenWindow screen] frame])) {
        NSWindowCollectionBehavior collectionBehavior = [mainWindow collectionBehavior];
        [mainWindow setAnimationBehavior:NSWindowAnimationBehaviorNone];
        // trick to make sure the main window shows up in the same space as the fullscreen window
        [fullScreenWindow addChildWindow:mainWindow ordered:NSWindowBelow];
        [fullScreenWindow removeChildWindow:mainWindow];
        [fullScreenWindow setLevel:NSPopUpMenuWindowLevel];
        // these can change due to the child window trick
        [mainWindow setLevel:NSNormalWindowLevel];
        if (NSContainsRect([fullScreenWindow frame], [mainWindow frame]))
            [mainWindow setAlphaValue:1.0];
        [mainWindow setCollectionBehavior:collectionBehavior];
    } else {
        [mainWindow makeKeyAndOrderFront:nil];
    }
    [mainWindow display];
    [mainWindow makeFirstResponder:[self hasOverview] ? overviewView : pdfView];
    [mainWindow recalculateKeyViewLoop];
    [mainWindow setDelegate:self];
    [mainWindow makeKeyWindow];
    [NSApp updatePresentationOptionsForWindow:mainWindow];
    [mainWindow setAnimationBehavior:NSWindowAnimationBehaviorDefault];
    [NSApp removeWindowsItem:fullScreenWindow];
    [fullScreenWindow fadeOutBlocking:NO];
    if ([mainWindow alphaValue] < 1.0)
        [[mainWindow animator] setAlphaValue:1.0];
}

#pragma mark API

- (void)enterFullscreen {
    if ([self canEnterFullscreen]) {
        if ([self interactionMode] == SKPresentationMode)
            [self exitPresentation];
        [[self window] toggleFullScreen:nil];
    }
}

- (void)exitFullscreen {
    if ([self canExitFullscreen])
        [[self window] toggleFullScreen:nil];
}

- (void)enterPresentation {
    if ([self canEnterPresentation] == NO)
        return;
    
    if ([self interactionMode] == SKFullScreenMode) {
        mwcFlags.wantsPresentation = 1;
        [[self window] toggleFullScreen:nil];
        return;
    }
    
    if ([[self window] respondsToSelector:@selector(moveTabToNewWindow:)] && [[[self window] tabbedWindows] count] > 1)
        [[self window] moveTabToNewWindow:nil];
    
    PDFPage *page = [[self pdfView] currentPage];
    
    // remember normal setup to return to, we must do this before changing the interactionMode
    [savedNormalSetup setDictionary:[self currentPDFSettings]];
    
    mwcFlags.isSwitchingFullScreen = 1;
    
    interactionMode = SKPresentationMode;
    
    NSScreen *screen = [mainWindow screen];
    if ([self presentationNotesDocument] && [self presentationNotesDocument] != [self document]) {
        NSArray *screens = [self alternateScreensForScreen:[[[self presentationNotesDocument] mainWindow] screen]];
        if ([screens count] > 0 && [screens containsObject:[screen primaryScreen]] == NO)
            screen = [screens firstObject];
    }
    
    [self fadeInFullScreenWindowOnScreen:screen];
    
    if ([self hasOverview]) {
        [splitView setFrame:[overviewContentView frame]];
        [[overviewContentView superview] replaceSubview:overviewContentView with:splitView];
    }
    
    [self enterPresentationMode];
    
    [self fadeInFullScreenView];
    
    if ([[[self pdfView] currentPage] isEqual:page] == NO)
        [[self pdfView] goToPage:page];
    
    mwcFlags.isSwitchingFullScreen = 0;
    
    [pdfView setInteractionMode:SKPresentationMode];
    [touchBarController interactionModeChanged];
}

- (void)exitPresentation {
    if ([self canExitPresentation] == NO)
        return;
    
    NSColor *backgroundColor = [PDFView defaultBackgroundColor];
    PDFPage *page = [[self pdfView] currentPage];
    
    mwcFlags.isSwitchingFullScreen = 1;
    
    if ([self leftSidePaneIsOpen])
        [self hideSideWindow];
    
    // do this first, otherwise the navigation window may be covered by fadeWindow and then reveiled again, which looks odd
    [pdfView setInteractionMode:SKNormalMode];
    
    [self fadeOutFullScreenView];
    
    interactionMode = SKNormalMode;
    
    // this should be done before exitPresentationMode to get a smooth transition
    [pdfView setFrame:[pdfContentView bounds]];
    [pdfContentView addSubview:pdfView];
    [pdfView setBackgroundColor:backgroundColor];
    [secondaryPdfView setBackgroundColor:backgroundColor];
    
    [self exitPresentationMode];
    [self applyPDFSettings:savedNormalSetup rewind:YES];
    [savedNormalSetup removeAllObjects];
    
    [pdfView layoutDocumentView];
    [pdfView requiresDisplay];
    
    if ([[[self pdfView] currentPage] isEqual:page] == NO)
        [[self pdfView] goToPage:page];
    
    mwcFlags.isSwitchingFullScreen = 0;
    
    [self forceSubwindowsOnTop:NO];
    
    [touchBarController interactionModeChanged];
    
    [self fadeOutFullScreenWindow];
    
    // the page number may have changed
    [self synchronizeWindowTitleWithDocumentName];
}

- (BOOL)canEnterFullscreen {
    return mwcFlags.isSwitchingFullScreen == 0 && ([self interactionMode] == SKNormalMode || [self interactionMode] == SKPresentationMode);
}

- (BOOL)canEnterPresentation {
    return mwcFlags.isSwitchingFullScreen == 0 && [[self pdfDocument] isLocked] == NO && [self interactionMode] != SKPresentationMode;
}

- (BOOL)canExitFullscreen {
    return mwcFlags.isSwitchingFullScreen == 0 && [self interactionMode] == SKFullScreenMode;
}

- (BOOL)canExitPresentation {
    return mwcFlags.isSwitchingFullScreen == 0 && [self interactionMode] == SKPresentationMode;
}

#pragma mark NSWindowDelegate Full Screen Methods

static inline CGFloat fullScreenOffset(NSWindow *window) {
    CGFloat offset = 17.0;
    if (autoHideToolbarInFullScreen)
        offset = NSHeight([window frame]) - NSHeight([window contentLayoutRect]);
    else if ([[window toolbar] isVisible] == NO)
        offset = NSHeight([NSWindow frameRectForContentRect:NSZeroRect styleMask:NSTitledWindowMask]);
    else if (fullScreenToolbarOffset > 0.0)
        offset = fullScreenToolbarOffset;
    else if (!RUNNING_BEFORE(10_11))
        offset = 17.0;
    else
        offset = 13.0;
    return offset;
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
            [[window animator] setFrame:SKShrinkRect([[window screen] frame], -fullScreenOffset(window), NSMaxYEdge) display:YES];
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
    interactionMode = SKNormalMode;
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
}

- (NSArray *)customWindowsToExitFullScreenForWindow:(NSWindow *)window {
    return [[[self document] windowControllers] valueForKey:WINDOW_KEY];
}

- (void)window:(NSWindow *)window startCustomAnimationToExitFullScreenWithDuration:(NSTimeInterval)duration {
    NSString *frameString = [savedNormalSetup objectForKey:MAINWINDOWFRAME_KEY];
    NSRect frame = NSRectFromString(frameString);
    NSRect startFrame = [window frame];
    [(SKMainWindow *)window setDisableConstrainedFrame:YES];
    [window setStyleMask:[window styleMask] & ~NSFullScreenWindowMask];
    for (NSView *view in [[[window standardWindowButton:NSWindowCloseButton] superview] subviews])
        if ([view isKindOfClass:[NSControl class]])
            [view setAlphaValue:0.0];
    [window setFrame:SKShrinkRect(startFrame, -fullScreenOffset(window), NSMaxYEdge) display:YES];
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
            [presentationNotesButton setImage:[NSImage imageWithSize:NSMakeSize(30.0, 50.0) flipped:NO drawingHandler:^(NSRect rect){
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
                return YES;
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
