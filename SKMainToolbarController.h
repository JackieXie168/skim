//
//  SKMainToolbarController.h
//  Skim
//
//  Created by Christiaan Hofman on 4/2/08.
/*
 This software is Copyright (c) 2008-2014
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

#import <Cocoa/Cocoa.h>

extern NSString *SKUnarchiveFromDataArrayTransformerName;

@class SKMainWindowController, SKPDFView, SKColorSwatch;

@interface SKMainToolbarController : NSViewController <NSToolbarDelegate> {
    SKMainWindowController *mainController;
    NSSegmentedControl *backForwardButton;
    NSTextField *pageNumberField;
    NSSegmentedControl *previousNextPageButton;
    NSSegmentedControl *previousPageButton;
    NSSegmentedControl *nextPageButton;
    NSSegmentedControl *previousNextFirstLastPageButton;
    NSSegmentedControl *zoomInOutButton;
    NSSegmentedControl *zoomInActualOutButton;
    NSSegmentedControl *zoomActualButton;
    NSSegmentedControl *zoomFitButton;
    NSSegmentedControl *zoomSelectionButton;
    NSSegmentedControl *rotateLeftButton;
    NSSegmentedControl *rotateRightButton;
    NSSegmentedControl *rotateLeftRightButton;
    NSSegmentedControl *cropButton;
    NSSegmentedControl *fullScreenButton;
    NSSegmentedControl *presentationButton;
    NSSegmentedControl *leftPaneButton;
    NSSegmentedControl *rightPaneButton;
    NSSegmentedControl *toolModeButton;
    NSSegmentedControl *textNoteButton;
    NSSegmentedControl *circleNoteButton;
    NSSegmentedControl *markupNoteButton;
    NSSegmentedControl *lineNoteButton;
    NSSegmentedControl *singleTwoUpButton;
    NSSegmentedControl *continuousButton;
    NSSegmentedControl *displayModeButton;
    NSSegmentedControl *displayBoxButton;
    NSSegmentedControl *infoButton;
    NSSegmentedControl *colorsButton;
    NSSegmentedControl *fontsButton;
    NSSegmentedControl *linesButton;
    NSSegmentedControl *printButton;
    NSSegmentedControl *customizeButton;
    NSTextField *scaleField;
    NSSegmentedControl *noteButton;
    SKColorSwatch *colorSwatch;
    NSMutableDictionary *toolbarItems;
}

@property (nonatomic, assign) IBOutlet SKMainWindowController *mainController;
@property (nonatomic, retain) IBOutlet NSSegmentedControl *backForwardButton, *previousNextPageButton, *previousPageButton, *nextPageButton, *previousNextFirstLastPageButton, *zoomInOutButton, *zoomInActualOutButton, *zoomActualButton, *zoomFitButton, *zoomSelectionButton, *rotateLeftButton, *rotateRightButton, *rotateLeftRightButton, *cropButton, *fullScreenButton, *presentationButton, *leftPaneButton, *rightPaneButton, *toolModeButton, *textNoteButton, *circleNoteButton, *markupNoteButton, *lineNoteButton, *singleTwoUpButton, *continuousButton, *displayModeButton, *displayBoxButton, *infoButton, *colorsButton, *fontsButton, *linesButton, *printButton, *customizeButton, *noteButton;
@property (nonatomic, retain) IBOutlet NSTextField *pageNumberField, *scaleField;
@property (nonatomic, retain) IBOutlet SKColorSwatch *colorSwatch;

- (void)setupToolbar;

- (void)registerForNotifications;
- (void)handleChangedHistoryNotification:(NSNotification *)notification;
- (void)handlePageChangedNotification:(NSNotification *)notification;

#pragma mark Actions

- (IBAction)goToPreviousNextFirstLastPage:(id)sender;
- (IBAction)goBackOrForward:(id)sender;
- (IBAction)changeScaleFactor:(id)sender;
- (void)chooseScale:(id)sender;
- (void)zoomActualPhysical:(id)sender;
- (IBAction)zoomInActualOut:(id)sender;
- (IBAction)zoomToFit:(id)sender;
- (IBAction)zoomToSelection:(id)sender;
- (IBAction)rotateAllLeftRight:(id)sender;
- (IBAction)cropAll:(id)sender;
- (IBAction)enterFullscreen:(id)sender;
- (IBAction)enterPresentation:(id)sender;
- (IBAction)toggleLeftSidePane:(id)sender;
- (IBAction)toggleRightSidePane:(id)sender;
- (IBAction)changeDisplayBox:(id)sender;
- (IBAction)changeDisplaySinglePages:(id)sender;
- (IBAction)changeDisplayContinuous:(id)sender;
- (IBAction)changeDisplayMode:(id)sender;
- (void)createNewTextNote:(id)sender;
- (void)createNewCircleNote:(id)sender;
- (void)createNewMarkupNote:(id)sender;
- (IBAction)createNewNote:(id)sender;
- (IBAction)changeToolMode:(id)sender;
- (IBAction)selectColor:(id)sender;

@end
