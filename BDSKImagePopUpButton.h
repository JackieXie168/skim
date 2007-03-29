//
//  BDSKImagePopUpButton.h
//  Bibdesk
//
//  Created by Christiaan Hofman on 3/22/05.
//
/*
 This software is Copyright (c) 2005,2006,2007
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
#import "BDSKImagePopUpButtonCell.h"

@class BDSKImageFadeAnimation;

@interface BDSKImagePopUpButton : NSPopUpButton
{
	BOOL highlight;
	id delegate;
    BDSKImageFadeAnimation *animation;
}
- (NSSize)iconSize;
- (void)setIconSize:(NSSize)iconSize;

- (BOOL)showsMenuWhenIconClicked;
- (void)setShowsMenuWhenIconClicked:(BOOL)showsMenuWhenIconClicked;

- (NSImage *)iconImage;
- (void)setIconImage:(NSImage *)iconImage;

- (NSImage *)arrowImage;
- (void) setArrowImage:(NSImage *)arrowImage;

- (BOOL)iconActionEnabled;
- (void)setIconActionEnabled:(BOOL)iconActionEnabled;

- (BOOL)refreshesMenu;
- (void)setRefreshesMenu:(BOOL)refreshesMenu;

- (id)delegate;
- (void)setDelegate:(id)newDelegate;

- (NSMenu *)menuForCell:(id)cell;

- (BOOL)startDraggingWithEvent:(NSEvent *)theEvent;

@end

@interface NSObject (BDSKImagePopUpButtonDelegate)
- (NSMenu *)menuForImagePopUpButton:(BDSKImagePopUpButton *)view;
@end

@interface NSObject (BDSKImagePopUpButtonDraggingDestination)
- (NSDragOperation)imagePopUpButton:(BDSKImagePopUpButton *)view canReceiveDrag:(id <NSDraggingInfo>)sender;
- (BOOL)imagePopUpButton:(BDSKImagePopUpButton *)view receiveDrag:(id <NSDraggingInfo>)sender;
@end

@interface NSObject (BDSKImagePopUpButtonDraggingSource)
- (BOOL)imagePopUpButton:(BDSKImagePopUpButton *)view writeDataToPasteboard:(NSPasteboard *)pasteboard;
- (NSArray *)imagePopUpButton:(BDSKImagePopUpButton *)view namesOfPromisedFilesDroppedAtDestination:(NSURL *)dropDestination;
- (void)imagePopUpButton:(BDSKImagePopUpButton *)view cleanUpAfterDragOperation:(NSDragOperation)operation;
@end
