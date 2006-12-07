//
//  BibAuthor.h
//  Bibdesk
//
//  Created by Michael McCracken on Wed Dec 19 2001.
//  Copyright (c) 2001 Michael McCracken. All rights reserved.
//
/*! @header BibAuthor.h
    @discussion declares an interface to author model objects
*/
#import <Cocoa/Cocoa.h>
@class BibItem;

/*!
    @class BibAuthor
    @abstract Modeling authors as objects that can have interesting relationships
    @discussion This isn't really used, but I think it has a lot of potential once I get the outlineview going on.
*/
@interface BibAuthor : NSObject {
    NSMutableArray *pubs;
    NSString *name;
}

// maybe this should be 'and pubs'
- (id)initWithName:(NSString *)aName andPub:(BibItem *)aPub;
- (void)dealloc;
- (void)setPubs:(NSArray *)newPubs;

- (int)numberOfChildren;
- (NSArray *)children;

- (NSString *)description;
- (NSString *)name;
- (void)setName:(NSString *)newName;

- (BibItem *)pubAtIndex:(int)index;
- (void)addPub:(BibItem *)pub;
- (void)removePubFromAuthorList:(BibItem *)pub;
@end
