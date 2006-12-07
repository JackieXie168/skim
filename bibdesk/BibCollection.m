//
//  BibCollection.m
//  Bibdesk
//
//  Created by Michael McCracken on 1/5/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "BibCollection.h"


@implementation BibCollection

- (NSString *)description{
    return [NSString stringWithFormat:@"Collection \"%@\" %d items %d subCollections %d exporters",
        name, [items count], [subCollections count], [exporters count]];
}

// init
- (id)initWithParent:(id)newParent{
    if (self = [super init]) {
        [self setParent:newParent];
        name = [[NSString alloc] initWithString:NSLocalizedString(@"New Collection", @"New Collection")];
        items = [[NSMutableArray alloc] initWithCapacity:1];
        subCollections = [[NSMutableArray alloc] initWithCapacity:1];
        exporters = [[NSMutableArray alloc] initWithCapacity:1];
		itemClassName = nil;

        [self registerForNotifications];
    }
    return self;
}

- (BibCollection *)copyWithZone:(NSZone *)aZone{
    BibCollection *copy = [[BibCollection allocWithZone:aZone] initWithParent:[self parent]];
    copy->name = [[self name] copyWithZone:aZone];
    copy->items = [[self items] mutableCopyWithZone:aZone];
    copy->subCollections = [[self subCollections] mutableCopyWithZone:aZone];
    copy->exporters = [[self exporters] mutableCopyWithZone:aZone];
    copy->itemClassName = [[self itemClassName] copyWithZone:aZone];
    return copy;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:[self name] forKey:@"name"];
	[coder encodeObject:[self itemClassName] forKey:@"itemClassName"];
    [coder encodeObject:[self items] forKey:@"items"];
    [coder encodeObject:[self subCollections] forKey:@"subCollections"];
    [coder encodeObject:[self exporters] forKey:@"exporters"];
}

- (id)initWithCoder:(NSCoder *)coder {
    if (self = [super init]) {
        name = [[coder decodeObjectForKey:@"name"] retain];
		itemClassName = [[coder decodeObjectForKey:@"itemClassName"] retain];
        items = [[coder decodeObjectForKey:@"items"] mutableCopy];
        exporters = [[coder decodeObjectForKey:@"exporters"] mutableCopy];
        if(!exporters){
            exporters = [[NSMutableArray alloc] initWithCapacity:1];
        }
        parent = nil;
        subCollections = [[coder decodeObjectForKey:@"subCollections"] mutableCopy];

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
    if([items containsObject:pub]){
        // should be [self removeitem:pub]; which would do proper undoing.
        [items removeObject:pub];
    }
}

- (NSUndoManager *)undoManager{
    if(parent)
        return [parent undoManager];
    else 
        return nil;
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

#warning, do we need to make this recurse?
- (NSString *)itemClassName { return [[itemClassName retain] autorelease]; }

- (void)setItemClassName:(NSString *)anItemClassName {
    [itemClassName release];
    itemClassName = [anItemClassName copy];
}

- (NSMutableArray *)items { return [[items retain] autorelease]; }


- (void)setItems:(NSMutableArray *)newitems {
    //NSLog(@"in -setitems:, old value of items: %@, changed to: %@", items, newitems);
    
    if (items != newitems) {
        [items release];
        items = [newitems mutableCopy];
    }
}

- (void)addItem:(id)newItem{
    NSUndoManager *um = [self undoManager];
    if(um){
        [[um prepareWithInvocationTarget:self] removeItem:newItem];
    }
    [items addObject:newItem];
    NSDictionary *notifInfo = [NSDictionary dictionaryWithObjectsAndKeys:newItem, @"item",nil];
	[[NSNotificationCenter defaultCenter] postNotificationName:BDSKBibCollectionItemAddedNotification
														object:self
													  userInfo:notifInfo];
    
}

- (void)addItemsFromArray:(NSMutableArray *)newitems {
    NSSet *existingSet = [NSSet setWithArray:items];

    foreach(pub, newitems){
        if(![existingSet containsObject:pub]){
            [self addItem:pub];
        }
    }
}

- (void)removeItemsInArray:(NSMutableArray *)theItems {
    foreach(item, theItems){
        [self removeItem:item];
    }
}

- (void)removeItem:(id)item{
    NSUndoManager *um = [self undoManager];
    if(um){
        [[um prepareWithInvocationTarget:self] addItem:item];
    }
    [items removeObject:item];
    NSDictionary *notifInfo = [NSDictionary dictionaryWithObjectsAndKeys:item, @"item",nil];
	[[NSNotificationCenter defaultCenter] postNotificationName:BDSKBibCollectionItemRemovedNotification
														object:self
													  userInfo:notifInfo];
    
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

- (void)addNewSubCollection{
	BibCollection *newBC = [[BibCollection alloc] initWithParent:self];
	[newBC setItemClassName:[self itemClassName]];
	[self addSubCollection:[newBC autorelease]];
}

- (void)insertSubCollection:(BibCollection *)newSubCollection atIndex:(unsigned int)index{
	[subCollections insertObject:newSubCollection atIndex:index];
}

- (void)addSubCollection:(BibCollection *)newSubCollection{
	[subCollections addObject:newSubCollection];
}

- (void)removeSubCollection:(BibCollection *)subCollection{
	[subCollections removeObject:subCollection];
}

- (BibCollection *)subCollectionAtIndex:(unsigned int)index{
	[subCollections objectAtIndex:index];
}


- (NSMutableArray *)exporters { return [[exporters retain] autorelease]; }


- (void)setExporters:(NSMutableArray *)newExporters {
    //NSLog(@"in -setExporters:, old value of exporters: %@, changed to: %@", exporters, newExporters);
    
    if (exporters != newExporters) {
        [exporters release];
        exporters = [newExporters copy];
    }
}

- (void)addExporter:(id)exporter{
    [exporters addObject:exporter];
}


- (void)removeExporter:(id)exporter{
    [exporters removeObject:exporter];
}



- (void)dealloc {
    [name release];
    [items release];
    [subCollections release];
    [exporters release];
    [super dealloc];
}


@end
