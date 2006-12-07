//
//  BibCollection.h
//  Bibdesk
//
//  Created by Michael McCracken on 1/5/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "BibPrefController.h"

/*!
    @header BibCollection
    @abstract   (description)
    @discussion (description)
*/

/*!
    @class BibCollection
    @abstract   (description)
    @discussion (description)
*/

@interface BibCollection : NSObject {
    NSString *name;
    NSMutableArray *publications;
    NSMutableArray *subCollections;
    id parent;
}

/*!
@method initWithParent:
 @abstract designated initializer

 */
- (id)initWithParent:(id)parent;

- (void)encodeWithCoder:(NSCoder *)aCoder;
- (id)initWithCoder:(NSCoder *)aDecoder;


/*
 @method registerForNotifications
 @abstract sets up notification handlers
 @discussion
 */
- (void)registerForNotifications;

/*
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
@method publications
@abstract the getter corresponding to setPublications
@result returns value for publications
*/
- (NSMutableArray *)publications;

/*!
@method setPublications
@abstract sets publications to the param
@discussion 
@param newPublications - an array of bibitems
*/
- (void)setPublications:(NSMutableArray *)newPublications;

/*!
@method addPublicationsFromArray
@abstract adds the publications in newPublications
@discussion 
@param newPublications - an array of bibitems
*/
- (void)addPublicationsFromArray:(NSMutableArray *)newPublications;

    /*!
@method addPublicationsFromArray
@abstract removes the publications in newPublications
@discussion 
@param newPublications - an array of bibitems
*/
- (void)removePublicationsInArray:(NSMutableArray *)thePublications;

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
@param newSubCollections 
*/
- (void)setSubCollections:(NSMutableArray *)newSubCollections;



@end
