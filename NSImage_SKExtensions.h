//
//  NSImage_SKExtensions.h
//  Skim
//
//  Created by Christiaan Hofman on 7/27/07.
/*
 This software is Copyright (c) 2007-2008
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
extern NSString *SKImageNameToolbarMediaBox;
extern NSString *SKImageNameToolbarCropBox;
extern NSString *SKImageNameToolbarLeftPane;
extern NSString *SKImageNameToolbarRightPane;
extern NSString *SKImageNameToolbarTextNote;
extern NSString *SKImageNameToolbarAnchoredNote;
extern NSString *SKImageNameToolbarCircleNote;
extern NSString *SKImageNameToolbarSquareNote;
extern NSString *SKImageNameToolbarHighlightNote;
extern NSString *SKImageNameToolbarUnderlineNote;
extern NSString *SKImageNameToolbarStrikeOutNote;
extern NSString *SKImageNameToolbarLineNote;
extern NSString *SKImageNameToolbarTextNoteMenu;
extern NSString *SKImageNameToolbarAnchoredNoteMenu;
extern NSString *SKImageNameToolbarCircleNoteMenu;
extern NSString *SKImageNameToolbarSquareNoteMenu;
extern NSString *SKImageNameToolbarHighlightNoteMenu;
extern NSString *SKImageNameToolbarUnderlineNoteMenu;
extern NSString *SKImageNameToolbarStrikeOutNoteMenu;
extern NSString *SKImageNameToolbarLineNoteMenu;
extern NSString *SKImageNameToolbarAddTextNote;
extern NSString *SKImageNameToolbarAddAnchoredNote;
extern NSString *SKImageNameToolbarAddCircleNote;
extern NSString *SKImageNameToolbarAddSquareNote;
extern NSString *SKImageNameToolbarAddHighlightNote;
extern NSString *SKImageNameToolbarAddUnderlineNote;
extern NSString *SKImageNameToolbarAddStrikeOutNote;
extern NSString *SKImageNameToolbarAddLineNote;
extern NSString *SKImageNameToolbarAddTextNoteMenu;
extern NSString *SKImageNameToolbarAddAnchoredNoteMenu;
extern NSString *SKImageNameToolbarAddCircleNoteMenu;
extern NSString *SKImageNameToolbarAddSquareNoteMenu;
extern NSString *SKImageNameToolbarAddHighlightNoteMenu;
extern NSString *SKImageNameToolbarAddUnderlineNoteMenu;
extern NSString *SKImageNameToolbarAddStrikeOutNoteMenu;
extern NSString *SKImageNameToolbarAddLineNoteMenu;
extern NSString *SKImageNameToolbarTextTool;
extern NSString *SKImageNameToolbarMoveTool;
extern NSString *SKImageNameToolbarMagnifyTool;
extern NSString *SKImageNameToolbarSelectTool;
extern NSString *SKImageNameToolbarNewFolder;
extern NSString *SKImageNameToolbarNewSeparator;

extern NSString *SKImageNameOutlineViewAdorn;
extern NSString *SKImageNameThumbnailViewAdorn;
extern NSString *SKImageNameNoteViewAdorn;
extern NSString *SKImageNameSnapshotViewAdorn;
extern NSString *SKImageNameFindViewAdorn;
extern NSString *SKImageNameGroupedFindViewAdorn;
extern NSString *SKImageNameTextNoteAdorn;
extern NSString *SKImageNameAnchoredNoteAdorn;
extern NSString *SKImageNameCircleNoteAdorn;
extern NSString *SKImageNameSquareNoteAdorn;
extern NSString *SKImageNameHighlightNoteAdorn;
extern NSString *SKImageNameUnderlineNoteAdorn;
extern NSString *SKImageNameStrikeOutNoteAdorn;
extern NSString *SKImageNameLineNoteAdorn;

@interface NSImage (SKExtensions)

+ (void)makeToolbarImages;
+ (void)makeAdornImages;

+ (NSImage *)iconWithSize:(NSSize)iconSize forToolboxCode:(OSType)code;
+ (NSImage *)smallImageWithIconForToolboxCode:(OSType)code;
+ (NSImage *)tinyImageWithIconForToolboxCode:(OSType) code;

+ (NSImage *)smallFolderImage;
+ (NSImage *)tinyFolderImage;

+ (NSImage *)smallMissingFileImage;
+ (NSImage *)tinyMissingFileImage;

- (void)drawFlippedInRect:(NSRect)dstRect fromRect:(NSRect)srcRect operation:(NSCompositingOperation)op fraction:(float)delta;
- (void)drawFlipped:(BOOL)isFlipped inRect:(NSRect)dstRect fromRect:(NSRect)srcRect operation:(NSCompositingOperation)op fraction:(float)delta;

- (NSBitmapImageRep *)bestImageRepForSize:(NSSize)preferredSize device:(NSDictionary *)deviceDescription;

@end
