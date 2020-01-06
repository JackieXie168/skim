//
//  NSImage_SKExtensions.h
//  Skim
//
//  Created by Christiaan Hofman on 7/27/07.
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

#import <Cocoa/Cocoa.h>

extern NSString *SKImageNameTextNote;
extern NSString *SKImageNameAnchoredNote;
extern NSString *SKImageNameCircleNote;
extern NSString *SKImageNameSquareNote;
extern NSString *SKImageNameHighlightNote;
extern NSString *SKImageNameUnderlineNote;
extern NSString *SKImageNameStrikeOutNote;
extern NSString *SKImageNameLineNote;
extern NSString *SKImageNameInkNote;

extern NSString *SKImageNameToolbarPageUp;
extern NSString *SKImageNameToolbarPageDown;
extern NSString *SKImageNameToolbarFirstPage;
extern NSString *SKImageNameToolbarLastPage;
extern NSString *SKImageNameToolbarBack;
extern NSString *SKImageNameToolbarForward;
extern NSString *SKImageNameToolbarZoomIn;
extern NSString *SKImageNameToolbarZoomOut;
extern NSString *SKImageNameToolbarZoomActual;
extern NSString *SKImageNameToolbarZoomToFit;
extern NSString *SKImageNameToolbarZoomToSelection;
extern NSString *SKImageNameToolbarRotateRight;
extern NSString *SKImageNameToolbarRotateLeft;
extern NSString *SKImageNameToolbarCrop;
extern NSString *SKImageNameToolbarFullScreen;
extern NSString *SKImageNameToolbarPresentation;
extern NSString *SKImageNameToolbarSinglePage;
extern NSString *SKImageNameToolbarTwoUp;
extern NSString *SKImageNameToolbarSinglePageContinuous;
extern NSString *SKImageNameToolbarTwoUpContinuous;
extern NSString *SKImageNameToolbarBookMode;
extern NSString *SKImageNameToolbarPageBreaks;
extern NSString *SKImageNameToolbarMediaBox;
extern NSString *SKImageNameToolbarCropBox;
extern NSString *SKImageNameToolbarLeftPane;
extern NSString *SKImageNameToolbarRightPane;
extern NSString *SKImageNameToolbarTextNoteMenu;
extern NSString *SKImageNameToolbarAnchoredNoteMenu;
extern NSString *SKImageNameToolbarCircleNoteMenu;
extern NSString *SKImageNameToolbarSquareNoteMenu;
extern NSString *SKImageNameToolbarHighlightNoteMenu;
extern NSString *SKImageNameToolbarUnderlineNoteMenu;
extern NSString *SKImageNameToolbarStrikeOutNoteMenu;
extern NSString *SKImageNameToolbarLineNoteMenu;
extern NSString *SKImageNameToolbarInkNoteMenu;
extern NSString *SKImageNameToolbarAddTextNote;
extern NSString *SKImageNameToolbarAddAnchoredNote;
extern NSString *SKImageNameToolbarAddCircleNote;
extern NSString *SKImageNameToolbarAddSquareNote;
extern NSString *SKImageNameToolbarAddHighlightNote;
extern NSString *SKImageNameToolbarAddUnderlineNote;
extern NSString *SKImageNameToolbarAddStrikeOutNote;
extern NSString *SKImageNameToolbarAddLineNote;
extern NSString *SKImageNameToolbarAddInkNote;
extern NSString *SKImageNameToolbarAddTextNoteMenu;
extern NSString *SKImageNameToolbarAddAnchoredNoteMenu;
extern NSString *SKImageNameToolbarAddCircleNoteMenu;
extern NSString *SKImageNameToolbarAddSquareNoteMenu;
extern NSString *SKImageNameToolbarAddHighlightNoteMenu;
extern NSString *SKImageNameToolbarAddUnderlineNoteMenu;
extern NSString *SKImageNameToolbarAddStrikeOutNoteMenu;
extern NSString *SKImageNameToolbarAddLineNoteMenu;
extern NSString *SKImageNameToolbarAddInkNoteMenu;
extern NSString *SKImageNameToolbarTextTool;
extern NSString *SKImageNameToolbarMoveTool;
extern NSString *SKImageNameToolbarMagnifyTool;
extern NSString *SKImageNameToolbarSelectTool;
extern NSString *SKImageNameToolbarInfo;
extern NSString *SKImageNameToolbarColors;
extern NSString *SKImageNameToolbarFonts;
extern NSString *SKImageNameToolbarLines;
extern NSString *SKImageNameToolbarPrint;
extern NSString *SKImageNameToolbarCustomize;

extern NSString *SKImageNameTouchBarPageUp;
extern NSString *SKImageNameTouchBarPageDown;
extern NSString *SKImageNameTouchBarFirstPage;
extern NSString *SKImageNameTouchBarLastPage;
extern NSString *SKImageNameTouchBarZoomIn;
extern NSString *SKImageNameTouchBarZoomOut;
extern NSString *SKImageNameTouchBarZoomActual;
extern NSString *SKImageNameTouchBarTextTool;
extern NSString *SKImageNameTouchBarMoveTool;
extern NSString *SKImageNameTouchBarMagnifyTool;
extern NSString *SKImageNameTouchBarSelectTool;
extern NSString *SKImageNameTouchBarTextNote;
extern NSString *SKImageNameTouchBarAnchoredNote;
extern NSString *SKImageNameTouchBarCircleNote;
extern NSString *SKImageNameTouchBarSquareNote;
extern NSString *SKImageNameTouchBarHighlightNote;
extern NSString *SKImageNameTouchBarUnderlineNote;
extern NSString *SKImageNameTouchBarStrikeOutNote;
extern NSString *SKImageNameTouchBarLineNote;
extern NSString *SKImageNameTouchBarInkNote;
extern NSString *SKImageNameTouchBarTextNotePopover;
extern NSString *SKImageNameTouchBarAnchoredNotePopover;
extern NSString *SKImageNameTouchBarCircleNotePopover;
extern NSString *SKImageNameTouchBarSquareNotePopover;
extern NSString *SKImageNameTouchBarHighlightNotePopover;
extern NSString *SKImageNameTouchBarUnderlineNotePopover;
extern NSString *SKImageNameTouchBarStrikeOutNotePopover;
extern NSString *SKImageNameTouchBarLineNotePopover;
extern NSString *SKImageNameTouchBarInkNotePopover;
extern NSString *SKImageNameTouchBarAddTextNote;
extern NSString *SKImageNameTouchBarAddAnchoredNote;
extern NSString *SKImageNameTouchBarAddCircleNote;
extern NSString *SKImageNameTouchBarAddSquareNote;
extern NSString *SKImageNameTouchBarAddHighlightNote;
extern NSString *SKImageNameTouchBarAddUnderlineNote;
extern NSString *SKImageNameTouchBarAddStrikeOutNote;
extern NSString *SKImageNameTouchBarAddLineNote;
extern NSString *SKImageNameTouchBarAddInkNote;
extern NSString *SKImageNameTouchBarNewSeparator;
extern NSString *SKImageNameTouchBarRefresh;
extern NSString *SKImageNameTouchBarStopProgress;

extern NSString *SKImageNameGeneralPreferences;
extern NSString *SKImageNameDisplayPreferences;
extern NSString *SKImageNameNotesPreferences;
extern NSString *SKImageNameSyncPreferences;

extern NSString *SKImageNameNewFolder;
extern NSString *SKImageNameNewSeparator;

extern NSString *SKImageNameOutlineViewAdorn;
extern NSString *SKImageNameThumbnailViewAdorn;
extern NSString *SKImageNameNoteViewAdorn;
extern NSString *SKImageNameSnapshotViewAdorn;
extern NSString *SKImageNameFindViewAdorn;
extern NSString *SKImageNameGroupedFindViewAdorn;
extern NSString *SKImageNameTextToolAdorn;

extern NSString *SKImageNameTextAlignLeft;
extern NSString *SKImageNameTextAlignCenter;
extern NSString *SKImageNameTextAlignRight;

extern NSString *SKImageNameResizeDiagonal45Cursor;
extern NSString *SKImageNameResizeDiagonal135Cursor;
extern NSString *SKImageNameZoomInCursor;
extern NSString *SKImageNameZoomOutCursor;
extern NSString *SKImageNameCameraCursor;
extern NSString *SKImageNameOpenHandBarCursor;
extern NSString *SKImageNameClosedHandBarCursor;
extern NSString *SKImageNameTextNoteCursor;
extern NSString *SKImageNameAnchoredNoteCursor;
extern NSString *SKImageNameCircleNoteCursor;
extern NSString *SKImageNameSquareNoteCursor;
extern NSString *SKImageNameHighlightNoteCursor;
extern NSString *SKImageNameUnderlineNoteCursor;
extern NSString *SKImageNameStrikeOutNoteCursor;
extern NSString *SKImageNameLineNoteCursor;
extern NSString *SKImageNameInkNoteCursor;

extern NSString *SKImageNameRemoteStateResize;
extern NSString *SKImageNameRemoteStateScroll;

@interface NSImage (SKExtensions)

+ (NSImage *)imageWithSize:(NSSize)size drawingHandler:(BOOL (^)(NSRect dstRect))drawingHandler;
+ (NSImage *)bitmapImageWithSize:(NSSize)size scale:(CGFloat)scale drawingHandler:(void (^)(NSRect dstRect))drawingHandler;
+ (NSImage *)bitmapImageWithSize:(NSSize)size drawingHandler:(void (^)(NSRect dstRect))drawingHandler;
+ (NSImage *)PDFImageWithSize:(NSSize)size drawingHandler:(void (^)(NSRect dstRect))drawingHandler;

+ (void)makeImages;

@end
