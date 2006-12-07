//
//  BDSKForm.h
//  Bibdesk
//
//  Created by Adam Maxwell on 05/22/05.
/*
 This software is Copyright (c) 2005,2006
 Adam Maxwell. All rights reserved.
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:
 
 - Redistributions of source code must retain the above copyright
 notice, this list of conditions and the following disclaimer.
 
 - Redistributions in binary form must reproduce the above copyright
 notice, this list of conditions and the following disclaimer in
 the documentation and/or other materials provided with the
 distribution.
 
 - Neither the name of Adam Maxwell nor the names of any
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
#import "BDSKFormCell.h"

@protocol BDSKFormDelegate <NSObject>
- (void)arrowClickedInFormCell:(id)aCell;
- (BOOL)formCellHasArrowButton:(id)aCell;
- (BOOL)formCellHasFileIcon:(id)cell;
- (NSImage *)fileIconForFormCell:(id)cell;
- (NSImage *)dragIconForFormCell:(id)cell;
- (void)iconClickedInFormCell:(id)cell;
- (void)doubleClickedTitleOfFormCell:(id)cell;
- (BOOL)writeDataToPasteboard:(NSPasteboard *)pasteboard forFormCell:(id)cell;
- (NSArray *)namesOfPromisedFilesDroppedAtDestination:(NSURL *)dropDestination forFormCell:(id)cell;
- (void)cleanUpAfterDragOperation:(NSDragOperation)operation forFormCell:(id)cell;
- (NSDragOperation)canReceiveDrag:(id <NSDraggingInfo>)sender forFormCell:(id)aCell;
- (BOOL)receiveDrag:(id <NSDraggingInfo>)sender forFormCell:(id)aCell;
@end

@interface BDSKForm : NSForm {
    @private
	int dragRow;
	BOOL highlight;
	id dragSourceCell;
}
/*!
    @method     removeAllEntries
    @abstract   Removes all cells from the form.
    @discussion (comprehensive description)
*/
- (void)removeAllEntries;
/*!
@method     insertEntry:usingTitleFont:attributesForTitle:atIndex:tag:objectValue:
 @abstract   Wrapper method used to clean up some repeated calls.
 @discussion (comprehensive description)
 @param      title The text of the title
 @param      titleFont Font used for the title; pass nil for defaults
 @param      attrs Dictionary of attributes for the title (NSAttributedString); pass nil for defaults
 @param      indexAndTag Index and tag of the item, set to the same value
 @param      objectValue The contents of the cell (must conform to NSCopying)
 @result     An NSFormCell or the prototype cell for the form.
 */
- (NSFormCell *)insertEntry:(NSString *)title usingTitleFont:(NSFont *)titleFont attributesForTitle:(NSDictionary *)attrs indexAndTag:(int)index objectValue:(id<NSCopying>)objectValue;

- (void)setDelegate:(id <BDSKFormDelegate>)aDelegate;
- (id <BDSKFormDelegate>)delegate;

- (id)dragSourceCell;

@end

#define BDSKFormConcreteImplementation_NULL_IMPLEMENTATION                                           \
- (void)arrowClickedInFormCell:(id)aCell;                                                            \
{                                                                                                    \
}                                                                                                    \
- (BOOL)formCellHasArrowButton:(id)aCell;                                                            \
{                                                                                                    \
    return NO;                                                                                       \
}                                                                                                    \
- (BOOL)formCellHasFileIcon:(id)cell;                                                                \
{                                                                                                    \
    return NO;                                                                                       \
}                                                                                                    \
- (NSImage *)fileIconForFormCell:(id)cell;                                                           \
{                                                                                                    \
    return nil;                                                                                      \
}                                                                                                    \
- (void)iconClickedInFormCell:(id)cell;                                                              \
{                                                                                                    \
}                                                                                                    \
- (void)doubleClickedTitleOfFormCell:(id)cell;                                                              \
{                                                                                                    \
}                                                                                                    \
- (BOOL)control:(NSControl *)control textShouldStartEditing:(NSText *)fieldEditor;                   \
{                                                                                                    \
    return YES;                                                                                      \
}                                                                                                    \
- (BOOL)writeDataToPasteboard:(NSPasteboard *)pasteboard forFormCell:(id)cell;                       \
{                                                                                                    \
    return NO;                                                                                       \
}                                                                                                    \
- (NSArray *)namesOfPromisedFilesDroppedAtDestination:(NSURL *)dropDestination forFormCell:(id)cell; \
{                                                                                                    \
    return nil;                                                                                      \
}                                                                                                    \
- (void)cleanUpAfterDragOperation:(NSDragOperation)operation forFormCell:(id)cell;                   \
{                                                                                                    \
}                                                                                                    \
- (BOOL)canReceiveDrag:(id <NSDraggingInfo>)sender forFormCell:(id)aCell;                            \
{                                                                                                    \
    return NO;                                                                                       \
}                                                                                                    \
- (BOOL)receiveDrag:(id <NSDraggingInfo>)sender forFormCell:(id)aCell;                               \
{                                                                                                    \
    return NO;                                                                                       \
}
