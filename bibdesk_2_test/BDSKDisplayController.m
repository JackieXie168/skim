//
//  BDSKDisplayController.m
//  bd2xtest
//
//  Created by Christiaan Hofman on 1/29/06.
//  Copyright 2006. All rights reserved.
//

#import "BDSKDisplayController.h"
#import "BDSKDataModelNames.h"
#import "BDSKDocument.h"


@implementation BDSKDisplayController

+ (void)initialize{
   [self setKeys:[NSArray arrayWithObject:@"document"] triggerChangeNotificationsForDependentKey:@"managedObjectContext"];
}

- (id)init{
	if (self = [super init]) {
		document = nil;
	}
	return self;
}

- (void)dealloc{
	[mainView release];
    [super dealloc];
}

- (void)awakeFromNib{
    [mainView retain];
    [self setWindow:nil];
}

- (void)windowDidLoad {
}

- (NSView *)view{
    if (mainView == nil) {
        [self window]; // force load of the nib
    }
    return mainView;
}

- (NSDocument *)document{
	return document;
}

- (void)setDocument:(NSDocument *)newDocument{
	if (newDocument != nil && [newDocument isKindOfClass:[NSPersistentDocument class]] == NO)
		[NSException raise:@"BDSWrongDocumentException" format:@"Document class %@ is not a subclass of NSPersistentDocument.", [newDocument class]];
	else
		document = newDocument;
}

- (NSManagedObjectContext *)managedObjectContext{
	return [(NSPersistentDocument *)document managedObjectContext];
}

- (NSString *)itemEntityName {
    return itemEntityName;
}

- (void)setItemEntityName:(NSString *)entityName {
    if (entityName != itemEntityName) {
        [itemEntityName release];
        itemEntityName = [entityName retain];
        [self updateUI];
    }
}

- (void)updateUI {}

#pragma mark Drag/drop

- (NSString *)relationshipKeyForPasteboardType:(NSString *)type parent:(NSManagedObject *)parent{
    static NSDictionary *relationshipsKeyPathInfo = nil;
    if (relationshipsKeyPathInfo == nil) {
        relationshipsKeyPathInfo = [[NSDictionary alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"RelationshipsInfo" ofType:@"plist"]];
    }
    return [[relationshipsKeyPathInfo objectForKey:[[parent entity] name]] objectForKey:type];
}

- (BOOL)canAddRelationshipsFromPasteboardType:(NSString *)type parent:(NSManagedObject *)parent{
    return [self relationshipKeyForPasteboardType:type parent:parent] != nil;
}

- (BOOL)addRelationshipsFromPasteboard:(NSPasteboard *)pboard forType:(NSString *)type parent:(NSManagedObject *)parent keyPath:(NSString *)keyPath {
	if (keyPath == nil) {
        keyPath = [self relationshipKeyForPasteboardType:type parent:parent];
        if (keyPath == nil)
            return  NO;
    }
    
    NSString *childKey = keyPath;
	NSString *relationshipKey = keyPath;
	BOOL hasRelationshipEntity = NO;
	NSRange dotRange = [keyPath rangeOfString:@"."];
	if (dotRange.location != NSNotFound) {
		relationshipKey = [keyPath substringToIndex:dotRange.location];
		childKey = [keyPath substringFromIndex:dotRange.location + 1];
		hasRelationshipEntity = YES;
	}
	
	NSArray *draggedURIs = [NSUnarchiver unarchiveObjectWithData:[pboard dataForType:type]];
	NSEnumerator *uriE = [draggedURIs objectEnumerator];
	NSManagedObjectContext *moc = [self managedObjectContext];
	NSURL *moURI;
	NSString *entityName = [[[[[parent entity] relationshipsByName] objectForKey:relationshipKey] destinationEntity] name];
	BOOL isToMany = [[[[parent entity] relationshipsByName] objectForKey:relationshipKey] isToMany];
	NSMutableSet *relationships = (isToMany) ? [parent mutableSetValueForKey:relationshipKey] : nil;
	NSSet *children = relationships;
	BOOL hasIndex = NO;
    BOOL success = NO;
	
    if (hasRelationshipEntity) {
		children = [relationships valueForKeyPath:[NSString stringWithFormat:@"@distinctUnionOfObjects.%@", childKey]];
		hasIndex = [entityName isEqualToString:ContributorPublicationRelationshipEntityName];
	}
    
	while (moURI = [uriE nextObject]) {
		NSManagedObject *child = [moc objectWithID:[[moc persistentStoreCoordinator] managedObjectIDForURIRepresentation:moURI]];
		NSManagedObject *relationship = child;
		
        if ([children containsObject:child])
			continue;
		if (hasRelationshipEntity) {
			relationship = [NSEntityDescription insertNewObjectForEntityForName:entityName inManagedObjectContext:moc];
			if (hasIndex) {
				NSManagedObject *publication = [childKey isEqualToString:@"publication"] ? child : parent;
				NSNumber *index = [publication valueForKeyPath:@"contributorRelationships.@count"];
				[relationship setValue:index forKey:@"index"];
				if ([[[child entity] name] isEqualToString:@"Person"] || [[[parent entity] name] isEqualToString:@"Person"])
					[relationship setValue:@"author" forKey:@"relationshipType"];
				else if ([[[child entity] name] isEqualToString:@"Institution"] || [[[parent entity] name] isEqualToString:@"Institution"])
					[relationship setValue:@"institution" forKey:@"relationshipType"];
			}
			[relationship setValue:child forKey:childKey];
		}
        if (isToMany == YES) {
            [relationships addObject:relationship];
        } else {
            [parent setValue:relationship forKey:relationshipKey];
            return YES;
        }
        success = YES;
	}
    
	return success;
}

@end


@implementation BDSKItemDisplayController

- (NSObjectController *)itemObjectController{
    return itemObjectController;
}

#pragma mark Drag/drop

- (BOOL)addRelationshipsFromPasteboard:(NSPasteboard *)pboard forType:(NSString *)type keyPath:(NSString *)keyPath {
	NSManagedObject *parent = [itemObjectController content];
    
    if (parent == nil || NSIsControllerMarker(parent))
        return NO;
    
    return [self addRelationshipsFromPasteboard:pboard forType:type parent:parent keyPath:keyPath];
}

@end
