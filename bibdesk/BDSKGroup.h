//
//  BDSKGroup.h
//  Bibdesk
//
//  Created by Christiaan Hofman on 8/11/05.
/*
 This software is Copyright (c) 2005,2006
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

@class BibItem;

/* note that NSCoding support is presently limited in some cases */

@interface BDSKGroup : NSObject <NSCopying, NSCoding> {
	id name;
	int count;
}

/*!
	@method initWithName:count:
	@abstract Initializes and returns a new group instance with a name and count. 
	@discussion This is the designated initializer. 
	@param aName The name for the group.
	@param count The count for the group.
*/
- (id)initWithName:(id)aName count:(int)aCount;

/*!
	@method initLibraryGroup
	@abstract Initializes and returns a new Library group. 
	@discussion -
*/
- (id)initLibraryGroup;

- (id)initWithDictionary:(NSDictionary *)groupDict;
- (NSDictionary *)dictionaryValue;

/*!
	@method name
	@abstract Returns the name of the group.
	@discussion -
*/
- (id)name;

/*!
	@method count
	@abstract Returns the count of the group.
	@discussion -
*/
- (int)count;

/*!
	@method setCount:
	@abstract Sets the count for the group.
	@discussion -
	@param newCount The new count to set.
*/
- (void)setCount:(int)newCount;

/*!
	@method count
	@abstract Returns the icon for the group.
	@discussion -
*/
- (NSImage *)icon;

/*!
	@method isStatic
	@abstract Boolean, returns whether the receiver is a static group. 
	@discussion -
*/
- (BOOL)isStatic;

/*!
	@method isSmart
	@abstract Boolean, returns whether the receiver is a smart group. 
	@discussion -
*/
- (BOOL)isSmart;

/*!
	@method isCategory
	@abstract Boolean, returns whether the receiver is a category group. 
	@discussion -
*/
- (BOOL)isCategory;

/*!
	@method isShared
	@abstract Boolean, returns whether the receiver is a shared group. 
	@discussion -
*/
- (BOOL)isShared;

/*!
	@method isURL
	@abstract Boolean, returns whether the receiver is a URL group. 
	@discussion -
*/
- (BOOL)isURL;

/*!
	@method isScript
	@abstract Boolean, returns whether the receiver is a script group. 
	@discussion -
*/
- (BOOL)isScript;

/*!
	@method isSearch
	@abstract Boolean, returns whether the receiver is a search group. 
	@discussion -
*/
- (BOOL)isSearch;

/*!
	@method isExternal
	@abstract Boolean, returns whether the receiver is an external source group (shared, URL or script). 
	@discussion -
*/
- (BOOL)isExternal;

/*!
    @method     hasEditableName
    @abstract   Returns NO by default.  Editable subclasses should override this to allow changing the name of a group.
*/
- (BOOL)hasEditableName;

/*!
    @method     isEditable
    @abstract   Returns NO by default.  Editable subclasses should override this to allow editing of its properties.
*/
- (BOOL)isEditable;

/*!
    @method     failedDownload
    @abstract   Method for remote groups.  Returns NO by default.
*/
- (BOOL)failedDownload;

/*!
    @method     isRetrieving
    @abstract   Method for remote groups.  Returns NO by default.
*/
- (BOOL)isRetrieving;

/*!
    @method     isValidDropTarget
    @abstract   Some subclasses (e.g. BDSKSharedGroup) are never valid drop targets, while others are generally valid.  Returns NO by default.
    @discussion (comprehensive description)
    @result     (description)
*/
- (BOOL)isValidDropTarget;

/*!
	@method stringValue
	@abstract Returns string value of the name.
	@discussion -
*/
- (NSString *)stringValue;

/*!
	@method numberValue
	@abstract Returns count as an NSNumber.
	@discussion -
*/
- (NSNumber *)numberValue;

/*!
	@method nameCompare:
	@abstract Compares the string value of the receiver and the otherGroup. 
	@discussion -
	@param otherGroup The group object to compare the receiver with.
*/
- (NSComparisonResult)nameCompare:(BDSKGroup *)otherGroup;

/*!
	@method nameCompare:
	@abstract Compares the number value of the receiver and the otherGroup. 
	@discussion -
	@param otherGroup The group object to compare the receiver with.
*/
- (NSComparisonResult)countCompare:(BDSKGroup *)otherGroup;

/*!
	@method containsItem:
	@abstract Returns a boolean indicating whether the item is contained in the group.
	@discussion -
	@param item A BibItem to test for containment.
*/
- (BOOL)containsItem:(BibItem *)item;

@end


@interface BDSKMutableGroup : BDSKGroup {
	NSUndoManager *undoManager;
}

/*!
	@method setName:
	@abstract Sets the name for the group.
	@discussion -
	@param newName The new name to set.
*/
- (void)setName:(id)newName;

/*!
	@method undoManager
	@abstract Returns the undo manager of the group.
	@discussion -
*/
- (NSUndoManager *)undoManager;

/*!
	@method setUndoManager:
	@abstract Sets the undo manager for the group.
	@discussion -
	@param newUndoManager The new undo manager to set.
*/
- (void)setUndoManager:(NSUndoManager *)newUndoManager;

@end
