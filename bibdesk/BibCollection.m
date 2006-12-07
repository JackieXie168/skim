//
//  BibCollection.m
//  Bibdesk
//
//  Created by Michael McCracken on 1/5/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "BibCollection.h"


@implementation BibCollection


// init
- (id)initWithParent:(id)newParent{
    if (self = [super init]) {
        parent = newParent; // don't retain - they retain us.
        name = [[NSString alloc] initWithString:NSLocalizedString(@"New Collection", @"New Collection")];
        publications = [[NSMutableArray alloc] initWithCapacity:1];
        subCollections = [[NSMutableArray alloc] initWithCapacity:1];
        [self registerForNotifications];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:[self name] forKey:@"name"];
    [coder encodeObject:[self publications] forKey:@"publications"];
    [coder encodeObject:[self subCollections] forKey:@"subCollections"];
}

- (id)initWithCoder:(NSCoder *)coder {
    if (self = [super init]) {
        [self setName:[coder decodeObjectForKey:@"name"]];
        [self setPublications:[coder decodeObjectForKey:@"publications"]];
        parent = nil;
        [self setSubCollections:[coder decodeObjectForKey:@"subCollections"]];
        foreach(collection, subCollections){
            [collection setParent:self];
        }
        
        [self registerForNotifications];
    }
    return self;
}

- (void)registerForNotifications{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleBibItemDeleteNotification:)
                                                 name:BDSKDocDelItemNotification
                                               object:parent];
}

- (void)handleBibItemDeleteNotification:(NSNotification *)notification{
    NSDictionary *info = [notification userInfo];
    id pub = [info objectForKey:@"pub"];
    if([publications containsObject:pub]){
        // should be [self removePublication:pub]; which would do proper undoing.
        [publications removeObject:pub];
    }
}

- (id)parent { return parent; }

- (void)setParent:(id)newParent{
    parent = newParent;
}

- (NSString *)name { return [[name retain] autorelease]; }


- (void)setName:(NSString *)newName {
    //NSLog(@"in -setName:, old value of name: %@, changed to: %@", name, newName);
    
    if (name != newName) {
        [name release];
        name = [newName copy];
    }
}


- (NSMutableArray *)publications { return [[publications retain] autorelease]; }


- (void)setPublications:(NSMutableArray *)newPublications {
    //NSLog(@"in -setPublications:, old value of publications: %@, changed to: %@", publications, newPublications);
    
    if (publications != newPublications) {
        [publications release];
        publications = [newPublications mutableCopy];
    }
}

- (void)addPublicationsFromArray:(NSMutableArray *)newPublications {
    NSSet *existingSet = [NSSet setWithArray:publications];

    // note that undo should use the trimmed set.
    foreach(pub, newPublications){
        if(![existingSet containsObject:pub]){
            [publications addObject:pub];
        }
    }
}

- (void)removePublicationsInArray:(NSMutableArray *)thePublications {
    [publications removeObjectsInArray:thePublications];
}

- (unsigned)count { return [subCollections count]; }

- (NSMutableArray *)subCollections { return [[subCollections retain] autorelease]; }


- (void)setSubCollections:(NSMutableArray *)newSubCollections {
    //NSLog(@"in -setSubCollections:, old value of subCollections: %@, changed to: %@", subCollections, newSubCollections);
    
    if (subCollections != newSubCollections) {
        [subCollections release];
        subCollections = [newSubCollections mutableCopy];
    }
}



- (void)dealloc {
    [name release];
    [publications release];
    [subCollections release];
    [super dealloc];
}


@end
