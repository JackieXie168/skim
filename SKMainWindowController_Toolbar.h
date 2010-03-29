//
//  SKMainWindowController_Toolbar.h
//  Skim
//
//  Created by Christiaan Hofman on 4/2/08.
/*
 This software is Copyright (c) 2008-2010
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

@class SKMainWindowController, SKColorSwatch;

@interface SKMainToolbarController : NSViewController {
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
@property (nonatomic, assign) IBOutlet NSSegmentedControl *backForwardButton;
@property (nonatomic, assign) IBOutlet NSTextField *pageNumberField;
@property (nonatomic, assign) IBOutlet NSSegmentedControl *previousNextPageButton;
@property (nonatomic, assign) IBOutlet NSSegmentedControl *previousPageButton;
@property (nonatomic, assign) IBOutlet NSSegmentedControl *nextPageButton;
@property (nonatomic, assign) IBOutlet NSSegmentedControl *previousNextFirstLastPageButton;
@property (nonatomic, assign) IBOutlet NSSegmentedControl *zoomInOutButton;
@property (nonatomic, assign) IBOutlet NSSegmentedControl *zoomInActualOutButton;
@property (nonatomic, assign) IBOutlet NSSegmentedControl *zoomActualButton;
@property (nonatomic, assign) IBOutlet NSSegmentedControl *zoomFitButton;
@property (nonatomic, assign) IBOutlet NSSegmentedControl *zoomSelectionButton;
@property (nonatomic, assign) IBOutlet NSSegmentedControl *rotateLeftButton;
@property (nonatomic, assign) IBOutlet NSSegmentedControl *rotateRightButton;
@property (nonatomic, assign) IBOutlet NSSegmentedControl *rotateLeftRightButton;
@property (nonatomic, assign) IBOutlet NSSegmentedControl *cropButton;
@property (nonatomic, assign) IBOutlet NSSegmentedControl *fullScreenButton;
@property (nonatomic, assign) IBOutlet NSSegmentedControl *presentationButton;
@property (nonatomic, assign) IBOutlet NSSegmentedControl *leftPaneButton;
@property (nonatomic, assign) IBOutlet NSSegmentedControl *rightPaneButton;
@property (nonatomic, assign) IBOutlet NSSegmentedControl *toolModeButton;
@property (nonatomic, assign) IBOutlet NSSegmentedControl *textNoteButton;
@property (nonatomic, assign) IBOutlet NSSegmentedControl *circleNoteButton;
@property (nonatomic, assign) IBOutlet NSSegmentedControl *markupNoteButton;
@property (nonatomic, assign) IBOutlet NSSegmentedControl *lineNoteButton;
@property (nonatomic, assign) IBOutlet NSSegmentedControl *singleTwoUpButton;
@property (nonatomic, assign) IBOutlet NSSegmentedControl *continuousButton;
@property (nonatomic, assign) IBOutlet NSSegmentedControl *displayModeButton;
@property (nonatomic, assign) IBOutlet NSSegmentedControl *displayBoxButton;
@property (nonatomic, assign) IBOutlet NSSegmentedControl *infoButton;
@property (nonatomic, assign) IBOutlet NSSegmentedControl *colorsButton;
@property (nonatomic, assign) IBOutlet NSSegmentedControl *fontsButton;
@property (nonatomic, assign) IBOutlet NSSegmentedControl *linesButton;
@property (nonatomic, assign) IBOutlet NSSegmentedControl *printButton;
@property (nonatomic, assign) IBOutlet NSSegmentedControl *customizeButton;
@property (nonatomic, assign) IBOutlet NSTextField *scaleField;
@property (nonatomic, assign) IBOutlet NSSegmentedControl *noteButton;
@property (nonatomic, assign) IBOutlet SKColorSwatch *colorSwatch;

- (void)setupToolbar;

@end
