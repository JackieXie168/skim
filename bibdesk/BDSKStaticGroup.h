//
//  BDSKStaticGroup.h
//  Bibdesk
//
//  Created by Christiaan Hofman on 10/21/06.
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
#import "BDSKGroup.h"

@class BibItem;

@interface BDSKStaticGroup : BDSKMutableGroup {
	NSMutableArray *publications;
}

/*!
	@method initWithName:publications:
	@abstract Initializes and returns a new group instance with a name and publications.
	@discussion This is the designated initializer. 
	@param aName The name for the static group.
	@param array The publications for the static group.
*/
- (id)initWithName:(id)aName publications:(NSArray *)array;

/*!
	@method initForLastImport:
	@abstract Initializes and returns a new Last Import group. 
	@discussion -
	@param array The publications for the static group.
*/
- (id)initWithLastImport:(NSArray *)array;

/*!
	@method publications
	@abstract Returns the publications in the group.
	@discussion -
*/
- (NSArray *)publications;

/*!
	@method setPublications:
	@abstract Sets the publications of the group.
	@discussion -
	@param newPublications The publications to set.
*/
- (void)setPublications:(NSArray *)newPublications;

/*!
	@method addPublication:
	@abstract Adds a publication to the group.
	@discussion -
	@param item The publication to add.
*/
- (void)addPublication:(BibItem *)item;

/*!
	@method addPublicationsFromArray:
	@abstract Adds publications from the group.
	@discussion -
	@param items The publications to add.
*/
- (void)addPublicationsFromArray:(NSArray *)items;

/*!
	@method removePublication:
	@abstract Removes a publication from the group.
	@discussion -
	@param item The publication to remove.
*/
- (void)removePublication:(BibItem *)item;

/*!
	@method removePublicationsInArray:
	@abstract Removes publications from the group.
	@discussion -
	@param items The publications to remove.
*/
- (void)removePublicationsInArray:(NSArray *)items;

@end
