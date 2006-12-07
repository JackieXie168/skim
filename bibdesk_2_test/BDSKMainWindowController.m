//
//  BDSKMainWindowController.m
//  bd2
//
//  Created by Michael McCracken on 6/16/05.
//  Copyright 2005 Michael McCracken. All rights reserved.
//

#import "BDSKMainWindowController.h"
#import "BDSKDataModelNames.h"
#import "BDSKDocument.h"
#import "BDSKGroup.h"
#import "ImageAndTextCell.h"
#import "BDSKBibTeXParser.h"
#import "BDSKSmartGroupEditor.h"

#import "BDSKPublicationTableDisplayController.h" // @@ TODO: itemdisplayflex this should be temporary
#import "BDSKNoteTableDisplayController.h" // @@ TODO: itemdisplayflex this should be temporary


@implementation BDSKMainWindowController

+ (void)initialize {
    [self setKeys:[NSArray arrayWithObject:@"sourceGroup"] triggerChangeNotificationsForDependentKey:@"sourceListSelectedItems"];
}

- (id)initWithWindowNibName:(NSString *)windowNibName{
    if (self = [super initWithWindowNibName:windowNibName]){
    }
    
    return self;
}

- (void)awakeFromNib{
    // this sets up the displayControllers
    [super awakeFromNib];

    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"priority" ascending:NO];
    [sourceListTreeController setSortDescriptors:[NSArray arrayWithObject:sortDescriptor]];
    [sortDescriptor release];    
    
    NSTableColumn *tc = [sourceList tableColumnWithIdentifier:@"mainColumn"];
    ImageAndTextCell *cell = [[[ImageAndTextCell alloc] init] autorelease];
    [cell setLineBreakMode:NSLineBreakByTruncatingTail];
    [tc setDataCell:cell];
    
    [sourceListTreeController addObserver:self forKeyPath:@"selectedObjects" options:0 context:NULL];
    [sourceList selectRow:0 byExtendingSelection:NO]; //@@TODO: might want to store last row as a pref

	[sourceList registerForDraggedTypes:[NSArray arrayWithObjects:BDSKPublicationPboardType, BDSKPersonPboardType, BDSKInstitutionPboardType, BDSKVenuePboardType, BDSKNotePboardType, BDSKTagPboardType, nil]];
}

- (void)dealloc{
    [sourceListTreeController removeObserver:self forKeyPath:@"selectedObjects"];
    [super dealloc];
}

-(void)windowDidLoad{ 
}

- (NSString *)windowTitleForDocumentDisplayName:(NSString *)displayName{
    return displayName;
}

#pragma mark Accessors

- (NSSet *)sourceListSelectedItems{
    BDSKGroup *selectedGroup = [self sourceGroup];
    if (NSIsControllerMarker(selectedGroup)) 
        return [NSSet set];
    return [selectedGroup valueForKey:@"items"];
}

- (void)addSourceListSelectedItemsObject:(id)obj{
    BDSKGroup *selectedGroup = [self sourceGroup];
    if (NSIsControllerMarker(selectedGroup) == NO) 
        [[selectedGroup mutableSetValueForKey:@"items"] addObject:obj];
}

- (void)removeSourceListSelectedItemsObject:(id)obj{
    BDSKGroup *selectedGroup = [self sourceGroup];
    if (NSIsControllerMarker(selectedGroup) == NO) 
        [[selectedGroup mutableSetValueForKey:@"items"] removeObject:obj];
}

#pragma mark Actions

- (IBAction)showWindowForSourceListSelection:(id)sender{
    BDSKGroup *selectedGroup = [self sourceGroup];
    if (NSIsControllerMarker(selectedGroup) || [selectedGroup isCategory]) {
        NSBeep();
        return;
    }
    
    BDSKSecondaryWindowController *swc = [[BDSKSecondaryWindowController alloc] initWithWindowNibName:@"BDSKSecondaryWindow"];
	[swc setSourceGroup:selectedGroup];
	[[self document] addWindowController:[swc autorelease]];
	[swc showWindow:sender];
}

- (IBAction)addNewGroup:(id)sender{
    BDSKGroup *selectedGroup = [self sourceGroup];
    if (NSIsControllerMarker(selectedGroup)) {
        NSBeep();
        return;
    }
    
    NSString *entityName = [selectedGroup valueForKey:@"itemEntityName"];
    NSManagedObjectContext *context = [self managedObjectContext];
    id newGroup = [NSEntityDescription insertNewObjectForEntityForName:StaticGroupEntityName
                                                inManagedObjectContext:context];
    
    [newGroup setValue:entityName forKey:@"itemEntityName"];
    [newGroup setValue:@"Untitled Group" forKey:@"name"];
    
    if ([selectedGroup canAddChildren] == YES) {
        // for folder groups we add the new group as a child
        [[selectedGroup mutableSetValueForKey:@"children"] addObject:newGroup];
    }
    
    [context processPendingChanges];
    // TODO: select the new group and edit. How to select?
}

- (IBAction)addNewFolderGroup:(id)sender{
    BDSKGroup *selectedGroup = [self sourceGroup];
    if (NSIsControllerMarker(selectedGroup)) {
        NSBeep();
        return;
    }
    
    NSString *entityName = [selectedGroup valueForKey:@"itemEntityName"];
    NSManagedObjectContext *context = [self managedObjectContext];
    id newFolderGroup = [NSEntityDescription insertNewObjectForEntityForName:FolderGroupEntityName
                                                      inManagedObjectContext:context];
    
    [newFolderGroup setValue:entityName forKey:@"itemEntityName"];
    [newFolderGroup setValue:@"Untitled Folder" forKey:@"name"];
    
    if ([selectedGroup canAddChildren] == YES) {
        // for non-smart groups we add the new group as a child
        [[selectedGroup mutableSetValueForKey:@"children"] addObject:newFolderGroup];
    }
    
    [context processPendingChanges];
    // TODO: select the new group and edit. How to select?
}

- (IBAction)addNewSmartGroup:(id)sender{
    BDSKGroup *selectedGroup = [self sourceGroup];
    if (NSIsControllerMarker(selectedGroup)) {
        NSBeep();
        return;
    }
    
    NSString *entityName = [selectedGroup valueForKey:@"itemEntityName"];
    NSManagedObjectContext *context = [self managedObjectContext];
    id newSmartGroup = [NSEntityDescription insertNewObjectForEntityForName:SmartGroupEntityName
                                                     inManagedObjectContext:context];
    
    [newSmartGroup setValue:entityName forKey:@"itemEntityName"];
    [newSmartGroup setValue:@"Untitled Smart Group" forKey:@"name"];
    
    if ([selectedGroup canAddChildren] == YES || [selectedGroup isStatic] == YES) {
        // for non-smart groups we add the new group as a child
        [[selectedGroup mutableSetValueForKey:@"children"] addObject:newSmartGroup];
    }
    
    [context processPendingChanges];
    // TODO: select the new group and edit. How to select?
}

- (IBAction)editSmartGroup:(id)sender{
    id selectedGroup = [self sourceGroup];
    if (NSIsControllerMarker(selectedGroup) || [selectedGroup canEdit] == NO) {
        NSBeep();
        return;
    }
    
    BDSKSmartGroupEditor *editor = [[BDSKSmartGroupEditor alloc] init];
    NSString *entityName = [selectedGroup valueForKey:@"itemEntityName"];
    NSString *propertyName = [selectedGroup valueForKey:@"itemPropertyName"];
    NSPredicate *predicate = [selectedGroup valueForKey:@"predicate"];
    [editor setManagedObjectContext:[self managedObjectContext]];
    [editor setEntityName:entityName];
    [editor setPropertyName:propertyName];
    [editor setPredicate:predicate];
    [editor setCanChangeEntityName:[selectedGroup isRoot]];
    
    [NSApp beginSheet:[editor window] 
       modalForWindow:[self window] 
        modalDelegate:self 
       didEndSelector:@selector(editSmartGroupSheetDidEnd:returnCode:contextInfo:) 
          contextInfo:editor];
}

- (void)editSmartGroupSheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(BDSKSmartGroupEditor *)editor {
    id selectedGroup = [self sourceGroup];
    if (returnCode == NSOKButton) {
    
        if ([editor commitEditing]) {
            @try {
                NSString *entityName = [editor entityName];
                NSString *propertyName = [editor propertyName];
                NSPredicate *predicate = [editor predicate];
                [selectedGroup setValue:entityName forKey:@"itemEntityName"];
                [selectedGroup setValue:propertyName forKey:@"itemPropertyName"];
                [selectedGroup setValue:predicate forKey:@"predicate"];
            } 
            @catch ( NSException *e ) {
                // an invalid predicate shouldn't get here, but if it does, we will reset the value
                [selectedGroup setValue:nil forKey:@"predicate"];
            }
        }
    }
    [editor reset];
    [editor release];
}

- (IBAction)getInfo:(id)sender{
    id selectedGroup = [self sourceGroup];
    if (NSIsControllerMarker(selectedGroup)) {
        NSBeep();
    } else if ([selectedGroup canEdit] == YES) {
        [self editSmartGroup:sender];
    } else {
        NSString *entityName = [selectedGroup valueForKey:@"itemEntityName"];
        NSAlert *alert = [[[NSAlert alloc] init] autorelease];
        [alert addButtonWithTitle:NSLocalizedString(@"OK", @"OK")];
        [alert setAlertStyle:NSInformationalAlertStyle];
        [alert setMessageText:([selectedGroup isSmart]) ? NSLocalizedString(@"Library", @"Library") : NSLocalizedString(@"Group", @"Group")];
        [alert setInformativeText:[NSString stringWithFormat:NSLocalizedString(@"This group contains %@ items.", @""), entityName]];
        [alert beginSheetModalForWindow:[self window] modalDelegate:nil didEndSelector:NULL contextInfo:NULL];
    }
}

#pragma mark Source List Outline View DataSource Methods and such

// these are required by the protocol, but unused
- (id)outlineView:(NSOutlineView *)outlineView child:(int)index ofItem:(id)item{
    return nil;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item{
    return NO;
}

- (int)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item{
    return 0;
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item{
    return nil;
}

- (NSDragOperation)outlineView:(NSOutlineView *)outlineView validateDrop:(id <NSDraggingInfo>)info proposedItem:(id)item proposedChildIndex:(int)index{
    NSPasteboard *pboard = [info draggingPasteboard];
    id groupItem = [item valueForKey:@"observedObject"];
    NSString *entityName = [groupItem valueForKey:@"itemEntityName"];
    NSString *pboardType = nil;
    
    if ([groupItem isStatic] == NO)
        return NSDragOperationNone;
    
    if ([entityName isEqualToString:PublicationEntityName])
        pboardType = BDSKPublicationPboardType;
    else if ([entityName isEqualToString:PersonEntityName])
        pboardType = BDSKPersonPboardType;
    else if ([entityName isEqualToString:InstitutionEntityName])
        pboardType = BDSKInstitutionPboardType;
    else if ([entityName isEqualToString:VenueEntityName])
        pboardType = BDSKVenuePboardType;
    else if ([entityName isEqualToString:NoteEntityName])
        pboardType = BDSKNotePboardType;
    else if ([entityName isEqualToString:TagEntityName])
        pboardType = BDSKTagPboardType;
    else return NSDragOperationNone;
    
    if ([pboard availableTypeFromArray:[NSArray arrayWithObjects:pboardType, nil]] == nil)
        return NSDragOperationNone;
    if (index != NSOutlineViewDropOnItemIndex)
        [outlineView setDropItem:item dropChildIndex:NSOutlineViewDropOnItemIndex];
    
    if ([[[info draggingSource] dataSource] document] != [self document])
        return NSDragOperationNone;
    
    return NSDragOperationLink;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView acceptDrop:(id <NSDraggingInfo>)info item:(id)item childIndex:(int)index{
    NSPasteboard *pboard = [info draggingPasteboard];
    id groupItem = [item valueForKey:@"observedObject"];
    NSString *entityName = [groupItem valueForKey:@"itemEntityName"];
    NSString *pboardType = nil;
    
    if ([groupItem isSmart] || [groupItem isCategory])
        return NO;
    
    if ([entityName isEqualToString:PublicationEntityName])
        pboardType = BDSKPublicationPboardType;
    else if ([entityName isEqualToString:PersonEntityName])
        pboardType = BDSKPersonPboardType;
    else if ([entityName isEqualToString:InstitutionEntityName])
        pboardType = BDSKInstitutionPboardType;
    else if ([entityName isEqualToString:VenueEntityName])
        pboardType = BDSKVenuePboardType;
    else if ([entityName isEqualToString:NoteEntityName])
        pboardType = BDSKNotePboardType;
    else if ([entityName isEqualToString:TagEntityName])
        pboardType = BDSKTagPboardType;
    else return NO;
    
    if ([pboard availableTypeFromArray:[NSArray arrayWithObjects:pboardType, nil]] == nil)
        return NO;
    
	NSArray *draggedURIs = [NSUnarchiver unarchiveObjectWithData:[pboard dataForType:pboardType]];
	NSEnumerator *uriE = [draggedURIs objectEnumerator];
	NSManagedObjectContext *moc = [self managedObjectContext];
	NSURL *moURI;
	NSMutableSet *items = [groupItem mutableSetValueForKey:@"items"];
	while (moURI = [uriE nextObject]) {
		NSManagedObject *item = [moc objectWithID:[[moc persistentStoreCoordinator] managedObjectIDForURIRepresentation:moURI]];
		if ([items containsObject:item] == NO)
			[items addObject:item];
	}
	return YES;
}

#pragma mark other file format stuff

// importing

// TODO: should this take an argument for the dictionary? what up there?
- (void)importUsingImporter:(id /*<BDSKImporter>*/)importer{
    // open a window using the importer's view 
    // save a ptr to the current importer.
}

- (IBAction)oneShotImportFromBibTeXFile:(id)sender{
    // open file chooser
    
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    int returnCode = [openPanel runModalForTypes:[NSArray arrayWithObject:@"bib"]];
    if (returnCode == NSCancelButton)
        return;
    
	NSString *path = [[openPanel filenames] objectAtIndex: 0];
	if (path == nil)
		return;

    NSData *data = [NSData dataWithContentsOfFile:path];
    NSError *error = nil;
    
    [BDSKBibTeXParser itemsFromData:data error:&error document:(BDSKDocument *)[self document]];
}

// TODO: implementation
- (void)importFromBibTeXFile:(id)sender{

}

#pragma mark KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (object == sourceListTreeController && [keyPath isEqual:@"selectedObjects"]) {
        NSArray *selectedItems = [sourceListTreeController selectedObjects];
        if ([selectedItems count] > 0)
            [self setSourceGroup:[selectedItems lastObject]];
    }
}

@end
