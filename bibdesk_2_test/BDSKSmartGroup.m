// 
//  BDSKSmartGroup.m
//  bd2xtest
//
//  Created by Christiaan Hofman on 2/4/06.
//  Copyright 2006. All rights reserved.
//

#import "BDSKSmartGroup.h"
#import "BDSKDataModelNames.h"


@implementation BDSKSmartGroup 

+ (void)initialize {
    // we need to call super's implementation, even though the docs say not to, because otherwise we loose dependent keys
    [super initialize]; 
    [self setKeys:[NSArray arrayWithObjects:@"predicateData", @"itemEntityName", nil]
        triggerChangeNotificationsForDependentKey:@"fetchRequest"];
    [self setKeys:[NSArray arrayWithObjects:@"fetchRequest", nil]
        triggerChangeNotificationsForDependentKey:@"items"];
    [self setKeys:[NSArray arrayWithObjects:@"itemPropertyName", nil]
        triggerChangeNotificationsForDependentKey:@"isLeaf"];
}

- (id)initWithEntity:(NSEntityDescription*)entity insertIntoManagedObjectContext:(NSManagedObjectContext*)context{
	if (self = [super initWithEntity:entity insertIntoManagedObjectContext:context]) {
        [self addObserver:self forKeyPath:@"parent" options:0 context:NULL];
        [self addObserver:self forKeyPath:@"itemPropertyName" options:0 context:NULL];
        [self addObserver:self forKeyPath:@"itemEntityName" options:0 context:NULL];
        [self addObserver:self forKeyPath:@"fetchRequest" options:0 context:NULL];
	}
	return self;
}

- (void)dealloc{
	[self removeObserver:self forKeyPath:@"parent"];
	[self removeObserver:self forKeyPath:@"itemPropertyName"];
	[self removeObserver:self forKeyPath:@"itemEntityName"];
    [self removeObserver:self forKeyPath:@"fetchRequest"];
    
	[super dealloc];
}

- (void)commonAwake {
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(managedObjectContextObjectsDidChange:) 
                                                 name:NSManagedObjectContextObjectsDidChangeNotification 
                                               object:[self managedObjectContext]];        
    
    items = nil;
    children = nil;
    
    [self willAccessValueForKey:@"priority"];
    [self setValue:[NSNumber numberWithInt:1] forKeyPath:@"priority"];
    [self didAccessValueForKey:@"priority"];
    
    [self refreshMetaData];
}

- (void)awakeFromInsert  {
    [super awakeFromInsert];
    [self commonAwake];
    [self setPredicate:[NSPredicate predicateWithValue:YES]];
}

- (void)awakeFromFetch {
    [super awakeFromFetch];
    [self commonAwake];
}

- (void)didTurnIntoFault {
    [[NSNotificationCenter defaultCenter] removeObserver:self 
                                                    name:NSManagedObjectContextObjectsDidChangeNotification 
                                                  object:[self managedObjectContext]];
	
    [items release];
    items = nil;
    
    if ([children count]) {
        NSManagedObjectContext *moc = [self managedObjectContext];
        NSEnumerator *childEnum = [children objectEnumerator];
        NSManagedObject *child;
        
        [moc processPendingChanges];
        [[moc undoManager] disableUndoRegistration];
        
        while (child = [childEnum nextObject]) {
            [moc deleteObject:child];
        }
        
        [moc processPendingChanges];
        [[moc undoManager] enableUndoRegistration];
    }
    
	[children release];
    children = nil;    
    
    [super didTurnIntoFault];
}

- (void)refreshMetaData {
    NSManagedObjectContext *context = [self managedObjectContext];
    NSString *entityName = [self itemEntityName];
    NSString *propertyName = [self itemPropertyName];
    NSEntityDescription *entity = [NSEntityDescription entityForName:entityName inManagedObjectContext:context];
    
    isToMany = NO;
    
    if (propertyName == nil || entity == nil)   
        return;
    
    NSArray *components = [propertyName componentsSeparatedByString:@"."];
    int i, count = [components count] - 1;
    NSRelationshipDescription *relationship;
    
    for (i = 0; i < count; i++) {
        relationship = [[entity relationshipsByName] objectForKey:[components objectAtIndex:i]];
        if (relationship == nil || [relationship isToMany]) {
            isToMany = YES;
            return;
        }
        entity = [relationship destinationEntity];
    }
}

- (void)refreshItems {
	[self willChangeValueForKey:@"items"];
	[items release];
    items = nil;
	[self didChangeValueForKey:@"items"];
}

- (void)refreshChildren {
    NSManagedObjectContext *moc = [self managedObjectContext];
    [moc processPendingChanges];
    [[moc undoManager] disableUndoRegistration];
    
    if ([children count]) {
        NSEnumerator *childEnum = [children objectEnumerator];
        NSManagedObject *child;
        
        while (child = [childEnum nextObject]) {
            [moc deleteObject:child];
        }
    }    
    
    [self willChangeValueForKey:@"children"];
	[children release];
    children = nil;    
    [self didChangeValueForKey:@"children"];
    
    [moc processPendingChanges];
    [[moc undoManager] enableUndoRegistration];
}

- (void)managedObjectContextObjectsDidChange:(NSNotification *)notification {
    NSDictionary *userInfo = [notification userInfo];
    NSMutableSet *modifiedObjects = [NSMutableSet set];
	
	[modifiedObjects unionSet:[userInfo objectForKey:NSUpdatedObjectsKey]];
	[modifiedObjects unionSet:[userInfo objectForKey:NSInsertedObjectsKey]];
	[modifiedObjects unionSet:[userInfo objectForKey:NSDeletedObjectsKey]];
	
    // TODO: can depend on other entities through relationships
    NSEntityDescription *entity = [NSEntityDescription entityForName:[self itemEntityName] inManagedObjectContext:[self managedObjectContext]];
	BDSKGroup *parent = [self valueForKey:@"parent"];
    NSEnumerator *enumerator = [modifiedObjects objectEnumerator];	
	id object;
	BOOL refresh = NO;
	
	while (object = [enumerator nextObject]) {
		if ([object entity] == entity || object == parent) {
			refresh = YES;
            break;
		}
	}
	    
    if (refresh == NO && [modifiedObjects count] == 0) {
        refresh = YES;
    }
	
    if (refresh) {
		[self refreshItems];
        // we need to call it this way, or the document gets an extra changeCount when this is called in managedObjectContextObjectsDidChange. Don't ask me why...
        [self performSelector:@selector(refreshChildren) withObject:nil afterDelay:0.0];
    }
}

- (void)willSave {
    NSPredicate *predicate = [[self primitiveValueForKey:@"fetchRequest"] predicate];
    NSData *predicateData = nil;
    
    if (predicate != nil) {
        predicateData = [NSKeyedArchiver archivedDataWithRootObject:predicate];
    }
    [self setPrimitiveValue:predicateData forKey:@"predicateData"];
    
    [super willSave];
}

#pragma mark Accessors

- (NSFetchRequest *)fetchRequest  {
    NSFetchRequest *fetchRequest;
    [self willAccessValueForKey:@"fetchRequest"];
    fetchRequest = [self primitiveValueForKey:@"fetchRequest"];
    [self didAccessValueForKey:@"fetchRequest"];
    
    if (fetchRequest == nil) {
        NSString *entityName = [self itemEntityName];
        NSData *predicateData = [self valueForKey:@"predicateData"];
        fetchRequest = [[[NSFetchRequest alloc] init] autorelease];
        [fetchRequest setEntity: [NSEntityDescription entityForName:entityName inManagedObjectContext:[self managedObjectContext]]];
        if (predicateData != nil) {
            [fetchRequest setPredicate:[NSKeyedUnarchiver unarchiveObjectWithData:predicateData]];
        }
        [self setPrimitiveValue:fetchRequest forKey:@"fetchRequest"];
    }
    
    return fetchRequest;
}

- (NSPredicate *)predicate {
    return [[self fetchRequest] predicate];
}

- (void)setPredicate:(NSPredicate *)newPredicate {
    [[self fetchRequest] setPredicate:newPredicate];
}

- (NSString *)itemEntityName {
    NSString *entityName = nil;
    [self willAccessValueForKey:@"itemEntityName"];
    entityName = [self primitiveValueForKey:@"itemEntityName"];
    [self didAccessValueForKey:@"itemEntityName"];
    return entityName;
}

- (void)setItemEntityName:(NSString *)entityName {
    [self willChangeValueForKey: @"itemEntityName"];
    [self setPrimitiveValue:entityName forKey:@"itemEntityName"];
    [self didChangeValueForKey:@"itemEntityName"];
    
    NSFetchRequest *fetchRequest = [self fetchRequest];
    [fetchRequest setEntity:[NSEntityDescription entityForName:entityName inManagedObjectContext:[self managedObjectContext]]];
    [fetchRequest setPredicate:[NSPredicate predicateWithValue:YES]];

    [self setValue:nil forKey:@"itemPropertyName"];
}

- (NSString *)itemPropertyName {
    NSString *propertyName = nil;
    [self willAccessValueForKey:@"itemPropertyName"];
    propertyName = [self primitiveValueForKey:@"itemPropertyName"];
    [self didAccessValueForKey:@"itemPropertyName"];
    return propertyName;
}

- (void)setItemPropertyName:(NSString *)propertyName {
    [self willChangeValueForKey:@"itemPropertyName"];
    [self setPrimitiveValue:propertyName forKey:@"itemPropertyName"];
    [self didChangeValueForKey:@"itemPropertyName"];
}

- (NSString *)groupImageName {
    return @"SmartGroupIcon";
}

- (BOOL)isLeaf { return ([self valueForKey:@"itemPropertyName"] == nil); }

- (BOOL)isSmart { return YES; }

- (BOOL)canEdit { return YES; }

- (BOOL)canEditName { return YES; }

- (NSSet *)items {
    if (items == nil)  {
        BDSKGroup *parent = [self valueForKey:@"parent"];
        if (parent != nil && [parent isStatic] == YES) {
            NSMutableArray *results = [[[parent valueForKey:@"items"] allObjects] mutableCopy];
            NSString *entityName = [self itemEntityName];
            NSPredicate *predicate = [self predicate];
            if (entityName && predicate) {
                // TODO: we should also match subentities
                NSPredicate *entityPredicate = [NSPredicate predicateWithFormat:@"entity.name == %@", entityName];
                [results filterUsingPredicate:[NSCompoundPredicate andPredicateWithSubpredicates:[NSArray arrayWithObjects:entityPredicate, predicate, nil]]];
            }
            items = [[NSSet alloc] initWithArray:results];
            [results release];
        } else {
            NSError *error = nil;
            NSArray *results = nil;
            @try {  results = [[self managedObjectContext] executeFetchRequest:[self fetchRequest] error:&error];  }
            @catch ( NSException *e ) {  /* no-op */ }
            items = ( error != nil || results == nil) ? [[NSSet alloc] init] : [[NSSet alloc] initWithArray:results];
        }
    }
    return items;
}

- (void)setItems:(NSSet *)newItems  { /* no-op */ }

- (NSSet *)children {
    if (children == nil)  {
        NSString *entityName = [self itemEntityName];
        NSString *propertyName = [self itemPropertyName];
        
        if (entityName == nil || propertyName == nil || recreatingChildren == YES) 
            return [NSSet set];
        
        // our fetchRequest in -items can call -children while we are building, effectively adding them twice. Is there a better way to avoid?
        recreatingChildren = YES;
        
        children = [[NSMutableSet alloc] init];
        
        NSString *allValuesKeyPath = (isToMany) ? [NSString stringWithFormat:@"@distinctUnionOfSets.%@", propertyName] : propertyName;
        NSSet *allItems = [self items];
        NSArray *allItemsArray = [allItems allObjects];
        NSSet *allValues = [allItems valueForKeyPath:allValuesKeyPath];
        NSEnumerator *valueEnum = [allValues objectEnumerator];
        id value;
        BDSKSmartGroup *child;
        NSString *predicateFormat = (isToMany) ? @"any %K == %@" : @"%K == %@";
        NSSet *childItems;
        NSPredicate *predicate;
	
        // adding the children should not be undoable
        NSManagedObjectContext *moc = [self managedObjectContext];
        [moc processPendingChanges];
        [[moc undoManager] disableUndoRegistration];
        
        predicate = [NSPredicate predicateWithFormat:(isToMany) ? @"all %K == nil" : @"%K == nil", propertyName];
        childItems = [[NSSet alloc] initWithArray:[allItemsArray filteredArrayUsingPredicate:predicate]];
        if ([childItems count] > 0) {
            child = [NSEntityDescription insertNewObjectForEntityForName:CategoryGroupEntityName inManagedObjectContext:moc];
            [child setValue:entityName forKey:@"itemEntityName"];
            [child setValue:[NSString stringWithFormat:NSLocalizedString(@"Empty", @"Empty"), propertyName] forKey:@"name"];
            [child setValue:childItems forKey:@"items"];
            [child setValue:[NSNumber numberWithInt:1] forKey:@"priority"];
            [children addObject:child];
        }
        [childItems release];
        
        while (value = [valueEnum nextObject]) {
            child = [NSEntityDescription insertNewObjectForEntityForName:CategoryGroupEntityName inManagedObjectContext:moc];
            [child setValue:entityName forKey:@"itemEntityName"];
            [child setValue:value forKey:@"name"];
            predicate = [NSPredicate predicateWithFormat:predicateFormat, propertyName, value];
            childItems = [[NSSet alloc] initWithArray:[allItemsArray filteredArrayUsingPredicate:predicate]];
            [child setValue:childItems forKey:@"items"];
            [childItems release];
            [children addObject:child];
        }
	
        [moc processPendingChanges];
        [[moc undoManager] enableUndoRegistration];
        
        recreatingChildren = NO;
    }
    return children;
}

- (void)setChildren:(NSSet *)newChildren { /* no-op */ }

#pragma mark KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"itemEntityName"]) {
        [self refreshMetaData];
    } else if ([keyPath isEqualToString:@"itemPropertyName"]) {
        [self refreshMetaData];
        [self refreshChildren];
    } else if ([keyPath isEqualToString:@"fetchRequest"] || [keyPath isEqualToString:@"parent"]) {
        [self refreshItems];
        [self refreshChildren];
    }
}

@end


@implementation BDSKLibraryGroup 

- (BOOL)isRoot { return YES; }

- (BOOL)isLeaf { return YES; }

- (BOOL)isLibrary { return YES; }

- (BOOL)canAddItems { return YES; }

- (BOOL)canEdit { return NO; }

- (BOOL)canEditName { return NO; }

- (void)setGroupImageName:(NSString *)imageName {
    if (![groupImageName isEqualToString:imageName]) {
        [groupImageName release];
        groupImageName = [imageName retain];
        [cachedIcon release];
        cachedIcon = nil;
    }
}

- (NSString *)groupImageName {
    return (groupImageName != nil) ? groupImageName : @"LibraryGroupIcon";
}

- (NSString *)itemPropertyName { return nil; }

- (void)setItemPropertyName:(NSString *)propertyName { /* no-op */ }

- (NSSet *)children { return [NSSet set]; }

@end


@implementation BDSKCategoryGroup

- (void)awakeFromInsert {
    [super awakeFromInsert];
    items = nil;
}

- (void)awakeFromFetch {
    [super awakeFromFetch];
    items = nil;
}

- (void)didTurnIntoFault {
    [items release];
    items = nil;
    
    [super didTurnIntoFault];
}

#pragma mark Accessors

- (BOOL)isRoot { return NO; }

- (BOOL)isLeaf { return YES; }

- (BOOL)isCategory { return YES; }

- (BOOL)canEdit { return NO; }

- (BOOL)canEditName { return NO; }

- (NSSet *)items { return items; }

- (void)setItems:(NSSet *)newItems  {
    if (items != newItems) {
        [items release];
        items = [newItems retain];
    }
}

- (NSSet *)children { return [NSSet set]; }

- (void)setChildren:(NSSet *)newChildren  { /* no-op */ }

@end
