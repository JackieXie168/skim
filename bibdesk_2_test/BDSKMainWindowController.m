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
#import "BDSKTableDisplayController.h"


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
	[[self document] addWindowController:[swc autorelease]];
	[swc setSourceGroup:selectedGroup];
	[swc showWindow:sender];
}

- (NSString *)itemEntityNameOfType:(int)tag parentGroup:(BDSKGroup *)parentGroup{
    if (NSIsControllerMarker(parentGroup)) 
        return nil;
    
    NSString *parentEntityName = [parentGroup valueForKey:@"itemEntityName"];
    NSString *entityName = nil;
    
    switch (tag) {
        case 1:
            entityName = PublicationEntityName;
            break;
        case 2:
            entityName = PersonEntityName;
            break;
        case 3:
            entityName = InstitutionEntityName;
            break;
        case 4:
            entityName = VenueEntityName;
            break;
        case 5:
            entityName = NoteEntityName;
            break;
        case 6:
            entityName = TagEntityName;
            break;
        case 7:
            entityName = ItemEntityName;
            break;
        case 8:
            entityName = TaggedItemEntityName;
            break;
        default:
            entityName = parentEntityName;
    }
    
    if ([parentEntityName isEqualToString:ItemEntityName] == NO && [parentEntityName isEqualToString:TaggedItemEntityName] == NO && 
        [parentGroup canAddChildren] == YES && [parentEntityName isEqualToString:entityName] == NO) 
        return nil;
    
    return entityName;
}

- (IBAction)addNewGroup:(id)sender{
    BDSKGroup *selectedGroup = [self sourceGroup];
    NSString *entityName = [self itemEntityNameOfType:[sender tag] parentGroup:selectedGroup];
    
    if (entityName == nil) {
        NSBeep();
        return;
    }
    
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
    NSString *entityName = [self itemEntityNameOfType:[sender tag] parentGroup:selectedGroup];
    
    if (entityName == nil) {
        NSBeep();
        return;
    }
    
    NSManagedObjectContext *context = [self managedObjectContext];
    id newFolderGroup = [NSEntityDescription insertNewObjectForEntityForName:FolderGroupEntityName
                                                      inManagedObjectContext:context];
    
    [newFolderGroup setValue:entityName forKey:@"itemEntityName"];
    [newFolderGroup setValue:@"Untitled Folder" forKey:@"name"];
    
    if ([selectedGroup canAddChildren] == YES) {
        // for folder groups we add the new group as a child
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

- (IBAction)removeSelectedGroup:(id)sender{
    BDSKGroup *selectedGroup = [self sourceGroup];
    if (NSIsControllerMarker(selectedGroup) || [selectedGroup isLibrary] || [selectedGroup isCategory]) {
        NSBeep();
        return;
    }
    
    NSManagedObjectContext *context = [self managedObjectContext];
    [context deleteObject:selectedGroup];
    [context processPendingChanges];
    // dirty fix for CoreData bug, which registers an extra change when objects are deleted
    [[self document] updateChangeCount:NSChangeUndone];
}

- (IBAction)delete:(id)sender {
    id firstResponder = [[self window] firstResponder];
    if ([firstResponder isKindOfClass:[NSText class]] && [firstResponder isFieldEditor])
        firstResponder = [firstResponder delegate];
    if (firstResponder == sourceList) {
        [self removeSelectedGroup:sender];
    } else if (firstResponder == [currentDisplayController itemsTableView]) {
        [self removeSelectedItems:sender];
    } else {
        NSBeep();
    }
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
        [alert setMessageText:([selectedGroup isLibrary]) ? NSLocalizedString(@"Library", @"Library") : NSLocalizedString(@"Group", @"Group")];
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
    NSArray *pboardTypes = nil;
    
    if ([groupItem isStatic] == NO)
        return NSDragOperationNone;
    
    if ([entityName isEqualToString:PublicationEntityName])
        pboardTypes = [NSArray arrayWithObjects:BDSKPublicationPboardType, nil];
    else if ([entityName isEqualToString:PersonEntityName])
        pboardTypes = [NSArray arrayWithObjects:BDSKPersonPboardType, nil];
    else if ([entityName isEqualToString:InstitutionEntityName])
        pboardTypes = [NSArray arrayWithObjects:BDSKInstitutionPboardType, nil];
    else if ([entityName isEqualToString:VenueEntityName])
        pboardTypes = [NSArray arrayWithObjects:BDSKVenuePboardType, nil];
    else if ([entityName isEqualToString:NoteEntityName])
        pboardTypes = [NSArray arrayWithObjects:BDSKNotePboardType, nil];
    else if ([entityName isEqualToString:TagEntityName])
        pboardTypes = [NSArray arrayWithObjects:BDSKTagPboardType, nil];
    else if ([entityName isEqualToString:TaggedItemEntityName])
        pboardTypes = [NSArray arrayWithObjects:BDSKPublicationPboardType, BDSKPersonPboardType, BDSKInstitutionPboardType, BDSKVenuePboardType, nil];
    else if ([entityName isEqualToString:ItemEntityName])
        pboardTypes = [NSArray arrayWithObjects:BDSKPublicationPboardType, BDSKPersonPboardType, BDSKInstitutionPboardType, BDSKVenuePboardType, BDSKNotePboardType, BDSKTagPboardType, nil];
    else return NO;
    
    pboardType = [pboard availableTypeFromArray:pboardTypes];
    if (pboardType == nil)
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
    NSArray *pboardTypes = nil;
    
    if ([groupItem isSmart] || [groupItem isCategory])
        return NO;
    
    if ([entityName isEqualToString:PublicationEntityName])
        pboardTypes = [NSArray arrayWithObjects:BDSKPublicationPboardType, nil];
    else if ([entityName isEqualToString:PersonEntityName])
        pboardTypes = [NSArray arrayWithObjects:BDSKPersonPboardType, nil];
    else if ([entityName isEqualToString:InstitutionEntityName])
        pboardTypes = [NSArray arrayWithObjects:BDSKInstitutionPboardType, nil];
    else if ([entityName isEqualToString:VenueEntityName])
        pboardTypes = [NSArray arrayWithObjects:BDSKVenuePboardType, nil];
    else if ([entityName isEqualToString:NoteEntityName])
        pboardTypes = [NSArray arrayWithObjects:BDSKNotePboardType, nil];
    else if ([entityName isEqualToString:TagEntityName])
        pboardTypes = [NSArray arrayWithObjects:BDSKTagPboardType, nil];
    else if ([entityName isEqualToString:TaggedItemEntityName])
        pboardTypes = [NSArray arrayWithObjects:BDSKPublicationPboardType, BDSKPersonPboardType, BDSKInstitutionPboardType, BDSKVenuePboardType, nil];
    else if ([entityName isEqualToString:ItemEntityName])
        pboardTypes = [NSArray arrayWithObjects:BDSKPublicationPboardType, BDSKPersonPboardType, BDSKInstitutionPboardType, BDSKVenuePboardType, BDSKNotePboardType, BDSKTagPboardType, nil];
    else return NO;
    
    pboardType = [pboard availableTypeFromArray:pboardTypes];
    if (pboardType == nil)
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

#pragma mark Importing


- (void)importUsingImporter:(id<BDSKImporter>)importer userInfo:(NSDictionary *)userInfo{
    NSMutableDictionary *cinfo = [NSMutableDictionary dictionaryWithDictionary:userInfo];
    [cinfo setObject:importer forKey:@"importer"];
    
    NSView *view = [importer view];
    NSSize winSize = [[importSettingsWindow contentView] frame].size;
    NSSize oldSize = [importSettingsMainBox frame].size;
    NSSize newSize = [view frame].size;
    winSize.width += newSize.width - oldSize.width;
    winSize.height += newSize.height - oldSize.height;
    [importSettingsWindow setContentSize:winSize];
    [importSettingsMainBox setContentView:view];
    
    [NSApp beginSheet:importSettingsWindow
       modalForWindow:[self window]
        modalDelegate:self
       didEndSelector:@selector(importSheetDidEnd:returnCode:contextInfo:)
          contextInfo:[cinfo retain]]; 
}

- (IBAction)closeImportSettingsSheet:(id)sender{
    [NSApp endSheet:importSettingsWindow returnCode:[sender tag]];
}

- (void)importSheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(NSMutableDictionary *)userInfo{
    if(returnCode == NSCancelButton){
        [sheet orderOut:self];
        return; // do nothing
    }
    
    id<BDSKImporter> importer = [userInfo objectForKey:@"importer"];
    
    NSError *error = nil;
    
    // TODO: give a better error, please
    if ([importer importIntoDocument:[self document] userInfo:userInfo error:&error] == NO) {
        NSRunAlertPanel(@"alert",@"import didn't work",@"OK",nil,nil);
    }
    
    [sheet orderOut:self];
}

- (IBAction)oneShotImportFromBibTeXFile:(id)sender{
    
    // this action is just an import from a BDSKBibTeXImporter with no extra settings.
    NSDictionary *info = [NSDictionary dictionary];

    [self importUsingImporter:[BDSKBibTeXImporter sharedImporter] 
                     userInfo:info];
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

#pragma mark Toolbar stuff

- (NSToolbar *) setupToolbar {
    NSToolbar *toolbar = [super setupToolbar];
    
    NSImage *image;
    NSRect badgeRect = NSMakeRect(20.0, 0.0, 12.0, 12.0);
    NSRect iconRect = NSMakeRect(0.0, 0.0, 32.0, 32.0);
    
    image = [[NSImage alloc] initWithSize:iconRect.size];
    [image lockFocus];
    [[NSImage imageNamed:@"New"] compositeToPoint:NSZeroPoint operation:NSCompositeCopy];
    [[NSImage imageNamed:@"GroupIcon"] drawInRect:badgeRect fromRect:iconRect operation:NSCompositeSourceOver fraction:1.0];
    [image unlockFocus];

    [self addToolbarItemWithIdentifier:BDSKDocumentToolbarNewGroupIdentifier
                                 label:NSLocalizedString(@"New Group",@"")
                          paletteLabel:NSLocalizedString(@"New Group",@"")
                               toolTip:NSLocalizedString(@"Create New Group",@"")
                                target:self
                                action:@selector(addNewGroup:)
                           itemContent:image
                              menuItem:nil];
    [image release];

    image = [[NSImage alloc] initWithSize:iconRect.size];
    [image lockFocus];
    [[NSImage imageNamed:@"New"] compositeToPoint:NSZeroPoint operation:NSCompositeCopy];
    [[NSImage imageNamed:@"SmartGroupIcon"] drawInRect:badgeRect fromRect:iconRect operation:NSCompositeSourceOver fraction:1.0];
    [image unlockFocus];

    [self addToolbarItemWithIdentifier:BDSKDocumentToolbarNewSmartGroupIdentifier
                                 label:NSLocalizedString(@"New Smart Group",@"")
                          paletteLabel:NSLocalizedString(@"New Smart Group",@"")
                               toolTip:NSLocalizedString(@"Create New Smart Group",@"")
                                target:self
                                action:@selector(addNewSmartGroup:)
                           itemContent:image
                              menuItem:nil];
    [image release];

    image = [[NSImage alloc] initWithSize:iconRect.size];
    [image lockFocus];
    [[NSImage imageNamed:@"New"] compositeToPoint:NSZeroPoint operation:NSCompositeCopy];
    [[NSImage imageNamed:@"FolderGroupIcon"] drawInRect:badgeRect fromRect:iconRect operation:NSCompositeSourceOver fraction:1.0];
    [image unlockFocus];

    [self addToolbarItemWithIdentifier:BDSKDocumentToolbarNewFolderIdentifier
                                 label:NSLocalizedString(@"New Folder",@"")
                          paletteLabel:NSLocalizedString(@"New Folder",@"")
                               toolTip:NSLocalizedString(@"Create New Folder Group",@"")
                                target:self
                                action:@selector(addNewFolderGroup:)
                           itemContent:image
                              menuItem:nil];
    [image release];

    image = [[NSImage alloc] initWithSize:iconRect.size];
    [image lockFocus];
    [[NSImage imageNamed:@"Delete"] compositeToPoint:NSZeroPoint operation:NSCompositeCopy];
    [[NSImage imageNamed:@"GroupIcon"] drawInRect:badgeRect fromRect:iconRect operation:NSCompositeSourceOver fraction:1.0];
    [image unlockFocus];

    [self addToolbarItemWithIdentifier:BDSKDocumentToolbarDeleteGroupIdentifier
                                 label:NSLocalizedString(@"Delete Group",@"")
                          paletteLabel:NSLocalizedString(@"Delete Group",@"")
                               toolTip:NSLocalizedString(@"Delete Selected Group",@"")
                                target:self
                                action:@selector(removeSelectedGroup:)
                           itemContent:image
                              menuItem:nil];
    [image release];

    [self addToolbarItemWithIdentifier:BDSKDocumentToolbarGetInfoIdentifier
                                 label:NSLocalizedString(@"Get Info",@"")
                          paletteLabel:NSLocalizedString(@"Get Info",@"")
                               toolTip:NSLocalizedString(@"Get Info for Selected Group",@"")
                                target:self
                                action:@selector(getInfo:)
                           itemContent:[NSImage imageNamed: @"Edit"]
                              menuItem:nil];

    [self addToolbarItemWithIdentifier:BDSKDocumentToolbarDetachIdentifier
                                 label:NSLocalizedString(@"Detach",@"")
                          paletteLabel:NSLocalizedString(@"Detach",@"")
                               toolTip:NSLocalizedString(@"Detach Selected Group",@"")
                                target:self
                                action:@selector(showWindowForSourceListSelection:)
                           itemContent:[NSImage imageNamed: @"Detach"]
                              menuItem:nil];

    return toolbar;
}

- (NSArray *) toolbarDefaultItemIdentifiers: (NSToolbar *) toolbar {
    return [NSArray arrayWithObjects:
		BDSKDocumentToolbarNewItemIdentifier, 
		BDSKDocumentToolbarNewGroupIdentifier, 
		BDSKDocumentToolbarDetachIdentifier, 
		NSToolbarFlexibleSpaceItemIdentifier, 
		BDSKDocumentToolbarSearchItemIdentifier, nil];
}

- (NSArray *) toolbarAllowedItemIdentifiers: (NSToolbar *) toolbar {
    return [NSArray arrayWithObjects: 
		BDSKDocumentToolbarNewItemIdentifier, 
		BDSKDocumentToolbarDeleteItemIdentifier, 
		BDSKDocumentToolbarNewGroupIdentifier, 
		BDSKDocumentToolbarNewSmartGroupIdentifier, 
		BDSKDocumentToolbarNewFolderIdentifier, 
		BDSKDocumentToolbarDeleteGroupIdentifier, 
		BDSKDocumentToolbarGetInfoIdentifier, 
		BDSKDocumentToolbarDetachIdentifier, 
		BDSKDocumentToolbarSearchItemIdentifier,
		NSToolbarFlexibleSpaceItemIdentifier, 
		NSToolbarSpaceItemIdentifier, 
		NSToolbarSeparatorItemIdentifier, 
		NSToolbarCustomizeToolbarItemIdentifier, nil];
}

- (BOOL) validateToolbarItem: (NSToolbarItem *) toolbarItem {
    BDSKGroup *selectedGroup = [self sourceGroup];
    
    NSString *identifier = [toolbarItem itemIdentifier];
    if ([identifier isEqualToString:BDSKDocumentToolbarNewItemIdentifier]) {
        return NSIsControllerMarker(selectedGroup) == NO && [selectedGroup canAddItems] && [[currentDisplayController itemsArrayController] canAdd];
    }else if([identifier isEqualToString:BDSKDocumentToolbarDeleteItemIdentifier]) {
        return NSIsControllerMarker(selectedGroup) == NO && [selectedGroup canAddItems] && [[currentDisplayController itemsArrayController] canRemove];
    }else if([identifier isEqualToString:BDSKDocumentToolbarNewGroupIdentifier] ||
             [identifier isEqualToString:BDSKDocumentToolbarNewSmartGroupIdentifier] ||
             [identifier isEqualToString:BDSKDocumentToolbarNewFolderIdentifier] ||
             [identifier isEqualToString:BDSKDocumentToolbarGetInfoIdentifier]) {
        return NSIsControllerMarker(selectedGroup) == NO;
    }else if([identifier isEqualToString:BDSKDocumentToolbarDeleteGroupIdentifier]) {
        return NSIsControllerMarker(selectedGroup) == NO && [selectedGroup isLibrary] == NO && [selectedGroup isCategory] == NO;
    }else if([identifier isEqualToString:BDSKDocumentToolbarDetachIdentifier]) {
        return NSIsControllerMarker(selectedGroup) == NO;
    }

    return YES;
}

@end
