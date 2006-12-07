//
//  BDSKTableDisplayController.m
//  bd2xtest
//
//  Created by Christiaan Hofman on 1/29/06.
//  Copyright 2006. All rights reserved.
//

#import "BDSKTableDisplayController.h"
#import "BDSKDataModelNames.h"
#import "BDSKDocument.h"
#import "NSTableView_BDSKExtensions.h"


@implementation BDSKTableDisplayController

- (id)init{
	if (self = [super init]) {
        NSDictionary *infoDict = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"DisplayControllers" ofType:@"plist"]];
        itemDisplayControllersInfoDict = [[infoDict objectForKey:@"ItemDisplayControllers"] retain];
        itemDisplayControllers = [[NSMutableArray alloc] initWithCapacity:10];
        currentItemDisplayControllerForEntity = [[NSMutableDictionary alloc] initWithCapacity:10];
		currentItem = nil;
        isEditable = NO;
	}
	return self;
}

- (void)dealloc{
    [itemsArrayController removeObserver:self forKeyPath:@"selectedObjects"];
    if (currentItemDisplayView) 
        [self setItemDisplayController:nil];
    [itemDisplayControllers release];
    [currentItemDisplayControllerForEntity release];        
    [itemDisplayControllersInfoDict release];
	[currentItem release];
    [super dealloc];
}

- (NSString *)windowNibName{
	return @"BDSKGenericTableDisplay";
}

- (void)awakeFromNib{
    [super awakeFromNib];
    [mainView retain];
    [self setWindow:nil];
    
    [self setupItemDisplayControllers];
	
    [self updateUI];
    
    [itemsArrayController addObserver:self forKeyPath:@"selectedObjects" options:0 context:NULL];
}

- (void)updateUI {
    [self setupTableColumns];
    
    if (currentItemDisplayController == nil && currentItemDisplayView != nil) {
        NSEntityDescription *entity = [[self currentItem] entity];
        BDSKItemDisplayController *newDisplayController = [self itemDisplayControllerForEntity:entity];
        if (newDisplayController != currentItemDisplayController){
            [self unbindItemDisplayController:currentItemDisplayController];
            [self setItemDisplayController:newDisplayController];
        }
    }
    NSArray *newTypes = [self acceptableDraggedTypes];
    NSArray *oldTypes = [itemsTableView registeredDraggedTypes];
    if ([oldTypes isEqualToArray:newTypes] == NO) {
        if ([oldTypes count])
            [itemsTableView unregisterDraggedTypes];
        if ([newTypes count])
            [itemsTableView registerForDraggedTypes:newTypes];
    }
}

- (void)setupTableColumns{
    NSArray *columnInfo = [self columnInfo];
    NSArray *tableColumns = [itemsTableView tableColumns];
    NSTableColumn *tableColumn;
    int i, count = [tableColumns count];
    while (count--) {
        tableColumn = [tableColumns objectAtIndex:count];
        [tableColumn unbind:@"value"];
        [itemsTableView removeTableColumn:tableColumn];
    }
    count = [columnInfo count];
    for (i = 0; i < count; i++) {
        NSDictionary *dict = [columnInfo objectAtIndex:i];
        NSString *displayName = [dict objectForKey:@"displayName"];
        NSString *keyPath = [dict objectForKey:@"keyPath"];
        tableColumn = [[[NSTableColumn alloc] initWithIdentifier:keyPath] autorelease];
        [[tableColumn headerCell] setStringValue:displayName];
        [itemsTableView addTableColumn:tableColumn];
        keyPath = [NSString stringWithFormat:@"arrangedObjects.%@", keyPath];
        [tableColumn bind:@"value" toObject:itemsArrayController withKeyPath:keyPath options:0];
    }
    [itemsTableView sizeToFit];
}

#pragma mark Accessors

- (NSArrayController *)itemsArrayController{
    return itemsArrayController;
}

- (NSTableView *)itemsTableView{
    return itemsTableView;
}

- (NSArray *)filterPredicates {
    static NSDictionary *filterPredicateInfo = nil;
    if (filterPredicateInfo == nil) {
        filterPredicateInfo = [[NSDictionary alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"FilterPredicates" ofType:@"plist"]];
    }
    
    NSString *entityName = [self itemEntityName];
    return (entityName == nil) ? nil : [filterPredicateInfo objectForKey:entityName];
}

- (NSArray *)columnInfo {
    static NSDictionary *columnInfo = nil;
    if (columnInfo == nil) {
        columnInfo = [[NSDictionary alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"ColumnInfo" ofType:@"plist"]];
    }
    NSString *entityName = [self itemEntityName];
    return (entityName == nil) ? nil : [columnInfo objectForKey:entityName];
}

- (BOOL)isEditable {
    return isEditable;
}

- (void)setEditable:(BOOL)value {
    isEditable = value;
}

- (NSManagedObject *)currentItem{
	return currentItem;
}

// this cannot be called after the display controller has been bound, due to binding issues.
- (void)setCurrentItem:(NSManagedObject *)newItem{
	if (newItem != currentItem) {
		
		BDSKItemDisplayController *newDisplayController = nil;
		BOOL shouldChangeDisplayController = NO;
		
        if (currentItemDisplayView) {
            NSString *oldEntityClassName = [[currentItem entity] name];
            NSString *newEntityClassName = [[newItem entity] name];
            
            if ([newEntityClassName isEqualToString:oldEntityClassName] == NO) {
                newDisplayController = [self itemDisplayControllerForEntity:[newItem entity]];
                if (newDisplayController != currentItemDisplayController){
                    [self unbindItemDisplayController:currentItemDisplayController];
                    shouldChangeDisplayController = YES;
                }
            }
        }
		
		[currentItem autorelease];
		currentItem = [newItem retain];
		
		if (shouldChangeDisplayController == YES)
			[self setItemDisplayController:newDisplayController];
	}
}

- (BDSKItemDisplayController *)itemDisplayController{
    return currentItemDisplayController;
}

- (void)setItemDisplayController:(BDSKItemDisplayController *)newDisplayController{
    if(newDisplayController != currentItemDisplayController){
        [currentItemDisplayController autorelease];
        if(currentItemDisplayController)
            [self unbindItemDisplayController:currentItemDisplayController];
        
        NSView *view = [newDisplayController view];
        if (view == nil) 
            view = [[[NSView alloc] init] autorelease];
        [view setFrame:[currentItemDisplayView frame]];
        [[currentItemDisplayView superview] replaceSubview:currentItemDisplayView with:view];
        currentItemDisplayView = view;
        currentItemDisplayController = [newDisplayController retain];
        [self bindItemDisplayController:currentItemDisplayController];
    }
}

- (NSArray *)itemDisplayControllers{
	return itemDisplayControllers;
}

// TODO: this is totally incomplete.
- (NSArray *)itemDisplayControllersForCurrentType{
    NSSet* currentTypes = nil; // temporary, removed treecontroller.
    NSLog(@"itemDisplayControllersForCurrentType - currentTypes is %@.", currentTypes);
    
    return [NSArray arrayWithObjects:currentItemDisplayController, nil];
}


#pragma mark Item Display Controller management

- (void)setupItemDisplayControllers{
    
    NSArray *displayControllerClassNames = [itemDisplayControllersInfoDict allKeys];
    NSEnumerator *displayControllerClassNameE = [displayControllerClassNames objectEnumerator];
    NSString *displayControllerClassName = nil;
    
    while (displayControllerClassName = [displayControllerClassNameE nextObject]){
        Class controllerClass = NSClassFromString(displayControllerClassName);
        BDSKItemDisplayController *controllerObject = [[controllerClass alloc] init];
        [controllerObject setDocument:[self document]];
        [itemDisplayControllers addObject:controllerObject];
        [controllerObject release];

        NSDictionary *infoDict = [itemDisplayControllersInfoDict objectForKey:displayControllerClassName];
           
        //TODO: for now we have a 1:1 between DCs and entity names. 
        // this code will need to get smarter when that changes.
        NSString *displayableEntity = [[infoDict objectForKey:@"DisplayableEntities"] objectAtIndex:0];
        [currentItemDisplayControllerForEntity setObject:controllerObject
                                              forKey:displayableEntity];
    }
    
}

- (BDSKItemDisplayController *)itemDisplayControllerForEntity:(NSEntityDescription *)entity{
    NSManagedObjectContext *context = [self managedObjectContext];
    id displayController = nil;
    
    if (entity == nil)
        entity = [NSEntityDescription entityForName:[self itemEntityName] inManagedObjectContext:context];
    
    while (displayController == nil && entity != nil) {
        displayController = [currentItemDisplayControllerForEntity objectForKey:[entity name]];
        entity = [entity superentity];
    }
    return displayController;
}

- (void)bindItemDisplayController:(BDSKItemDisplayController *)displayController{
	// Not binding the contentSet will get all the managed objects for the entity
	// Binding contentSet will not update a dynamic smart group
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:NO], NSRaisesForNotApplicableKeysBindingOption, [NSNumber numberWithBool:YES], NSConditionallySetsEnabledBindingOption, [NSNumber numberWithBool:YES], NSDeletesObjectsOnRemoveBindingsOption, nil];
    // TODO: in future, this should create multiple bindings.?    
    [[displayController itemObjectController] bind:@"contentObject" toObject:self
                                       withKeyPath:@"currentItem" options:options];
}


// TODO: as the above method creates multiple bindings, this one will have to keep up.
- (void)unbindItemDisplayController:(BDSKItemDisplayController *)displayController{
	[[displayController itemObjectController] unbind:@"contentObject"];
}

#pragma mark Actions

- (void)addItem {
    if ([itemsArrayController canAdd] == NO || [self isEditable] == NO)
        return;
    
	NSManagedObjectContext *moc = [self managedObjectContext];
    NSString *entityName = [self itemEntityName];
    if ([entityName isEqualToString:ItemEntityName] || [entityName isEqualToString:TaggedItemEntityName])
        entityName = PublicationEntityName;
	NSManagedObject *mo = [NSEntityDescription insertNewObjectForEntityForName:entityName inManagedObjectContext:moc];
    [itemsArrayController addObject:mo];
    [moc processPendingChanges];
    [itemsArrayController setSelectedObjects:[NSArray arrayWithObject:mo]];
}

- (void)removeItems:(NSArray *)selectedItems {
    if (NSIsControllerMarker(selectedItems) || [itemsArrayController canRemove] == NO)
        return;
    
	NSManagedObjectContext *moc = [self managedObjectContext];
	NSEnumerator *selEnum = [selectedItems objectEnumerator];
	NSManagedObject *mo;
	while (mo = [selEnum nextObject]) 
		[moc deleteObject:mo];
    [moc processPendingChanges];
    // dirty fix for CoreData bug, which registers an extra change when objects are deleted
    [[self document] updateChangeCount:NSChangeUndone];
}

#pragma mark Drag/drop

- (NSArray *)acceptableDraggedTypes {
    NSString *entityName = [self itemEntityName];
    NSArray *pboardTypes = nil;
    
    if ([entityName isEqualToString:PublicationEntityName])
        pboardTypes = [NSArray arrayWithObjects:BDSKPersonPboardType, BDSKInstitutionPboardType, BDSKVenuePboardType, BDSKTagPboardType, nil];
    else if ([entityName isEqualToString:PersonEntityName])
        pboardTypes = [NSArray arrayWithObjects:BDSKPublicationPboardType, BDSKInstitutionPboardType, BDSKTagPboardType, nil];
    else if ([entityName isEqualToString:InstitutionEntityName])
        pboardTypes = [NSArray arrayWithObjects:BDSKPublicationPboardType, BDSKPersonPboardType, BDSKTagPboardType, nil];
    else if ([entityName isEqualToString:VenueEntityName])
        pboardTypes = [NSArray arrayWithObjects:BDSKPublicationPboardType, nil];
    else if ([entityName isEqualToString:NoteEntityName])
        pboardTypes = [NSArray arrayWithObjects:nil];
    else if ([entityName isEqualToString:TagEntityName])
        pboardTypes = [NSArray arrayWithObjects:BDSKPublicationPboardType, BDSKPersonPboardType, BDSKInstitutionPboardType, nil];
    else if ([entityName isEqualToString:TaggedItemEntityName])
        pboardTypes = [NSArray arrayWithObjects:BDSKPublicationPboardType, BDSKPersonPboardType, BDSKInstitutionPboardType, BDSKVenuePboardType, nil];
    else if ([entityName isEqualToString:ItemEntityName])
        pboardTypes = [NSArray arrayWithObjects:BDSKPublicationPboardType, BDSKPersonPboardType, BDSKInstitutionPboardType, BDSKVenuePboardType, BDSKTagPboardType, nil];
    
    return pboardTypes;
}

- (NSString *)pasteboardTypeForEntityName:(NSString *)entityName {
    if ([entityName isEqualToString:PublicationEntityName])
        return BDSKPublicationPboardType;
    else if ([entityName isEqualToString:PersonEntityName])
        return BDSKPersonPboardType;
    else if ([entityName isEqualToString:InstitutionEntityName])
        return BDSKInstitutionPboardType;
    else if ([entityName isEqualToString:VenueEntityName])
        return BDSKVenuePboardType;
    else if ([entityName isEqualToString:NoteEntityName])
        return BDSKNotePboardType;
    else if ([entityName isEqualToString:TagEntityName])
        return BDSKTagPboardType;
    else
        return nil;
}

- (BOOL)writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard *)pboard forType:(NSString *)type {
    NSArray *allItems = [itemsArrayController arrangedObjects];
    NSMutableDictionary *draggedItemsDict = [[NSMutableDictionary alloc] initWithCapacity:6];
    NSMutableArray *draggedItems;
    unsigned row = [rowIndexes firstIndex];
    NSManagedObject *mo;
    NSMutableArray *draggedTypes = [[NSMutableArray alloc] initWithCapacity:6];
    NSString *entityName;
    
    while (row != NSNotFound) {
        mo = [allItems objectAtIndex:row];
        entityName = [[mo entity] name];
        draggedItems = [draggedItemsDict objectForKey:entityName];
        if (draggedItems == nil) {
            draggedItems = [[NSMutableArray alloc] initWithCapacity:[rowIndexes count]];
            [draggedItemsDict setObject:draggedItems forKey:entityName];
            [draggedItems release];
            [draggedTypes addObject:[self pasteboardTypeForEntityName:entityName]];
        }
        [draggedItems addObject:[[mo objectID] URIRepresentation]];
        row = [rowIndexes indexGreaterThanIndex:row];
    }
    
    [pboard declareTypes:draggedTypes owner:self];
    
    NSEnumerator *entityE = [draggedItemsDict keyEnumerator];
    
    while (entityName = [entityE nextObject]) {
        [pboard setData:[NSArchiver archivedDataWithRootObject:[draggedItemsDict objectForKey:entityName]] 
                forType:[self pasteboardTypeForEntityName:entityName]];
    }
    
    [draggedItemsDict release];
    [draggedTypes release];
    
    return YES;
}

- (BOOL)canAddRelationshipsFromPasteboardType:(NSString *)type parentRow:(int)row{
	if (row == -1)
		row = [itemsArrayController selectionIndex];
	if (row == -1)
		return NO;
	NSManagedObject *parent = [[itemsArrayController arrangedObjects] objectAtIndex:row];
    
    return [self canAddRelationshipsFromPasteboardType:type parent:parent];
}

- (BOOL)addRelationshipsFromPasteboard:(NSPasteboard *)pboard forType:(NSString *)type parentRow:(int)row keyPath:(NSString *)keyPath {
	if (row == -1)
		row = [itemsArrayController selectionIndex];
	if (row == -1)
		return NO;
	NSManagedObject *parent = [[itemsArrayController arrangedObjects] objectAtIndex:row];
    
    return [self addRelationshipsFromPasteboard:pboard forType:type parent:parent keyPath:keyPath];
}

#pragma mark NSTableView DataSource protocol

// dummy implementation as the NSTableView DataSource protocols requires these methods
- (int)numberOfRowsInTableView:(NSTableView *)tv {
	return 0;
}

// dummy implementation as the NSTableView DataSource protocols requires these methods
- (id)tableView:(NSTableView *)tv objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row {
	return nil;
}

- (BOOL)tableView:(NSTableView *)tv writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard *)pboard {
	if (tv == itemsTableView) {
        return [self writeRowsWithIndexes:rowIndexes toPasteboard:pboard forType:nil];
	}
    
	return NO;
}

- (NSDragOperation)tableView:(NSTableView*)tv validateDrop:(id <NSDraggingInfo>)info proposedRow:(int)row proposedDropOperation:(NSTableViewDropOperation)op {
	NSArray *pboardTypes = [self acceptableDraggedTypes];
    NSPasteboard *pboard = [info draggingPasteboard];
	
    if (tv == itemsTableView) {
        
        if ([tv setValidDropRow:&row dropOperation:NSTableViewDropOn] == NO)
            return NSDragOperationNone;
		
        NSEnumerator *typeEnum = [pboardTypes objectEnumerator];
        NSString *type;
        
        while (type = [typeEnum nextObject]) {
            if ([pboard availableTypeFromArray:[NSArray arrayWithObject:type]] && [self canAddRelationshipsFromPasteboardType:type parentRow:row]) {
                if ([[[info draggingSource] dataSource] document] == [self document])
                    return NSDragOperationLink;
                else
                    return NSDragOperationCopy;
            }
		}
        
	}
    
	return NSDragOperationNone;
}

- (BOOL)tableView:(NSTableView *)tv acceptDrop:(id <NSDraggingInfo>)info row:(int)row dropOperation:(NSTableViewDropOperation)op {
	NSArray *pboardTypes = [self acceptableDraggedTypes];
    NSPasteboard *pboard = [info draggingPasteboard];
    BOOL success = NO;
	
    if (tv == itemsTableView) {
        
		if (!([info draggingSourceOperationMask] & NSDragOperationLink))
			return NO;
		
        NSEnumerator *typeEnum = [pboardTypes objectEnumerator];
        NSString *type;
        
        while (type = [typeEnum nextObject]) {
            if ([pboard availableTypeFromArray:[NSArray arrayWithObject:type]]) {
                if ([self addRelationshipsFromPasteboard:pboard forType:type parentRow:row keyPath:nil])
                    success = YES;
            }
		}
        
	}
    
	return success;
}

#pragma mark KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (object == itemsArrayController && [keyPath isEqual:@"selectedObjects"]) {
        NSArray *selectedItems = [itemsArrayController selectedObjects];
        if ([selectedItems count] > 0)
            [self setCurrentItem:[selectedItems lastObject]];
        else
            [self setCurrentItem:nil];
    }
}

@end
