//
//  BibCollection.h
//  Bibdesk
//
//  Created by Michael McCracken on 1/5/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "BibPrefController.h"
#import "BDSKExporter.h"

/*!
    @header BibCollection
    @abstract   (description)
    @discussion (description)
*/

/*!
    @class BibCollection
    @abstract a collection of items, which can be any type
    @discussion (description)
*/

@interface BibCollection : NSObject {
    NSString *name;
	NSString *itemClassName;
    NSMutableArray *items;
    NSMutableArray *subCollections;
    id parent;
    NSMutableArray *exporters;
}


/*! 
@method description
*/
- (NSString *)description;

/*!
@method initWithParent:
 @abstract designated initializer

 */
- (id)initWithParent:(id)parent;

- (BibCollection *)copyWithZone:(NSZone *)aZone;
- (void)encodeWithCoder:(NSCoder *)aCoder;
- (id)initWithCoder:(NSCoder *)aDecoder;


	/*
 @method registerForNotifications
 @abstract sets up notification handlers
 @discussion
 */
- (void)registerForNotifications;

/*!
 @method undoManager
 @abstract returns the parent's undomanager
 */
- (NSUndoManager *)undoManager;

/*!
 @method parent
 @abstract accessor for the parent
*/
- (id)parent;

/*!
    @method setParent
 @abstract sets parent to the param
 @discussion 
 @param newParent
 */
- (void)setParent:(id)newParent;

/*!
@method name
@abstract the getter corresponding to setName
@result returns value for name
*/
- (NSString *)name;

/*!
@method setName
@abstract sets name to the param
@discussion 
@param newName 
*/
- (void)setName:(NSString *)newName;

/*!
* @method itemClassName
* @abstract the getter corresponding to setItemClassName
* @result returns value for itemClassName
*/
- (NSString *)itemClassName;

/*!
* @method setItemClassName
* @abstract sets itemClassName to the param
* @discussion 
* @param anItemClassName 
*/
- (void)setItemClassName:(NSString *)anItemClassName;

/*!
@method items
@abstract the getter corresponding to setitems
@result returns value for items
*/
- (NSMutableArray *)items;

/*!
@method setitems
@abstract sets items to the param
@discussion 
@param newitems - an array of bibitems
*/
- (void)setItems:(NSMutableArray *)newitems;

/*!
@method addItemsFromArray
@abstract adds the items in newitems
@discussion 
@param newitems - an array of bibitems
*/
- (void)addItemsFromArray:(NSMutableArray *)newitems;

- (void)addItem:(id)newItem;

    /*!
@method addItemsFromArray
@abstract removes the items in newitems
@discussion 
@param newitems - an array of bibitems
*/
- (void)removeItemsInArray:(NSMutableArray *)theItems;

- (void)removeItem:(id)item;

/*!
@method count
@abstract returns the count of the collection's children.
 @discussion This is a courtesy method, it has a somewhat 
 awkward name (it's not really an NSArray) because it makes code elsewhere simpler.
@result returns number of subCollections
*/
- (unsigned)count;

/*!
@method subCollections
@abstract the getter corresponding to setSubCollections
@result returns value for subCollections
*/
- (NSMutableArray *)subCollections;

	/*!
	@method setSubCollections
	 @abstract sets subCollections to the param
	 @discussion 
	 @param newSubCollections The new array of subcollections
	 */
- (void)setSubCollections:(NSMutableArray *)newSubCollections;

/*!
	@method addNewSubCollection
	 @abstract Adds a new empty subcollection with the same item class as the receiver.
	 @discussion 
	 */
- (void)addNewSubCollection;
	
/*!
	@method insertSubCollection:atIndex:
	 @abstract Inserts a new subCollection at the index
	 @discussion 
	 @param newSubCollection The new subcollection to add
	 @param index The location in the subcollections array to insert the new subcollection
	 */
- (void)insertSubCollection:(BibCollection *)newSubCollection atIndex:(unsigned int)index;

/*!
	@method addSubCollection:
	 @abstract Adds a subCollection
	 @discussion 
	 @param newSubCollection The new subcollection to add
	 */
- (void)addSubCollection:(BibCollection *)newSubCollection;

/*!
	@method removeSubCollection:
	 @abstract Removes a subCollection
	 @discussion 
	 @param subCollection The subcollection to remove
	 */
- (void)removeSubCollection:(BibCollection *)subCollection;

/*!
	@method subCollectionAtIndex:
	 @abstract Returns the subcollection at the given location in the array of subcollections
	 @discussion 
	 @param index The index for the requested subcollection
	 */
- (BibCollection *)subCollectionAtIndex:(unsigned int)index;

    /*!
    @method exporters
     @abstract the getter corresponding to setExporters
     @result returns value for exporters
     */
- (NSMutableArray *)exporters;

    /*!
    @method setExporters
     @abstract sets exporters to the param
     @discussion 
     @param newExporters 
     */
- (void)setExporters:(NSMutableArray *)newExporters;

- (void)addExporter:(id)exporter;
- (void)removeExporter:(id)exporter;


@end
