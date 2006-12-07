//
//  BDSKSmartGroup.h
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

@class BDSKFilter;

@interface BDSKSmartGroup : BDSKMutableGroup {
	BDSKFilter *filter;
}

/*!
	@method initWithFilter:
	@abstract Initializes and returns a new smart group instance with a filter. 
	@discussion This is the designated initializer. 
	@param aFilter The filter for the smart group with. 
*/
- (id)initWithFilter:(BDSKFilter *)aFilter;

/*!
	@method initWithName:count:filter:
	@abstract Initializes and returns a new group instance with a name, count and filter. 
	@discussion This is the designated initializer. 
	@param aName The name for the smart group.
	@param count The count for the smart group.
	@param aFilter The filter for the smart group with. 
*/
- (id)initWithName:(id)aName count:(int)aCount filter:(BDSKFilter *)aFilter;

/*!
	@method filter
	@abstract Returns the filter of the group.
	@discussion -
*/
- (BDSKFilter *)filter;

/*!
	@method setFilter:
	@abstract Sets the newFilter for the group.
	@discussion -
	@param newFilter The new filter to set.
*/
- (void)setFilter:(BDSKFilter *)newFilter;

/*!
	@method filterItems:
	@abstract Filters the items uding the receivers filters and updates the count.
	@discussion -
	@param items The array of BibItems to filter.
*/
- (NSArray *)filterItems:(NSArray *)items;

@end
