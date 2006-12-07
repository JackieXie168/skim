//
//  BDSKSecondaryWindowController.m
//  bd2
//
//  Created by Christiaan Hofman on 1/29/06.
//  Copyright 2006 Christiaan Hofman. All rights reserved.
//

#import "BDSKSecondaryWindowController.h"
#import "BDSKTableDisplayController.h"
#import "BDSKGroup.h"
#import "BDSKDataModelNames.h"

NSString *BDSKDocumentToolbarIdentifier = @"BDSKDocumentToolbarIdentifier";
NSString *BDSKDocumentToolbarNewItemIdentifier = @"BDSKDocumentToolbarNewItemIdentifier";
NSString *BDSKDocumentToolbarDeleteItemIdentifier = @"BDSKDocumentToolbarDeleteItemIdentifier";
NSString *BDSKDocumentToolbarNewGroupIdentifier = @"BDSKDocumentToolbarNewGroupIdentifier";
NSString *BDSKDocumentToolbarNewSmartGroupIdentifier = @"BDSKDocumentToolbarNewSmartGroupIdentifier";
NSString *BDSKDocumentToolbarNewFolderIdentifier = @"BDSKDocumentToolbarNewFolderIdentifier";
NSString *BDSKDocumentToolbarDeleteGroupIdentifier = @"BDSKDocumentToolbarDeleteGroupIdentifier";
NSString *BDSKDocumentToolbarGetInfoIdentifier = @"BDSKDocumentToolbarGetInfoIdentifier";
NSString *BDSKDocumentToolbarDetachIdentifier = @"BDSKDocumentToolbarDetachIdentifier";
NSString *BDSKDocumentToolbarSearchItemIdentifier = @"BDSKDocumentToolbarSearchItemIdentifier";


@implementation BDSKSecondaryWindowController

+ (void)initialize{
   [self setKeys:[NSArray arrayWithObject:@"document"] triggerChangeNotificationsForDependentKey:@"managedObjectContext"];
}

- (id)initWithWindowNibName:(NSString *)windowNibName{
    if (self = [super initWithWindowNibName:windowNibName]){
        NSDictionary *infoDict = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"DisplayControllers" ofType:@"plist"]];
        displayControllersInfoDict = [[infoDict objectForKey:@"TableDisplayControllers"] retain];
        displayControllers = [[NSMutableArray alloc] initWithCapacity:10];
        currentDisplayControllerForEntity = [[NSMutableDictionary alloc] initWithCapacity:10];
		sourceGroup = nil;
    }
    
    return self;
}

- (void)awakeFromNib{
    
    [self setupDisplayControllers];
	
	NSString *entityClassName = [[self sourceGroup] itemEntityName];
	if (entityClassName != nil) {
		BDSKTableDisplayController *newDisplayController = [self displayControllerForEntityName:entityClassName];
		if (newDisplayController != currentDisplayController){
			[self unbindDisplayController:currentDisplayController];
			[self setDisplayController:newDisplayController];
		}
	}
}

- (void)dealloc{
    [displayControllers release];
    [currentDisplayControllerForEntity release];        
    [displayControllersInfoDict release];
	[sourceGroup release];
    [super dealloc];
}

-(void)windowDidLoad{
    // Attach the toolbar to the document window
    [[self window] setToolbar: [self setupToolbar]];
}

- (void)windowWillClose:(NSNotification *)notification{
    [self setDisplayController:nil]; // needed to remove the bindings in the displayController
}

- (NSString *)windowTitleForDocumentDisplayName:(NSString *)displayName{
	NSString *groupName = [[self sourceGroup] valueForKeyPath:@"name"];
	if (groupName != nil) {
		return [NSString stringWithFormat:@"%@ - %@", displayName, groupName];
	}
	return [super windowTitleForDocumentDisplayName:displayName];
}

#pragma mark Accessors

- (NSManagedObjectContext *)managedObjectContext {
	return [[self document] managedObjectContext];
}

- (BDSKGroup *)sourceGroup{
	return sourceGroup;
}

// this cannot be called after the display controller has been bound, due to binding issues.
- (void)setSourceGroup:(BDSKGroup *)newSourceGroup{
	if (newSourceGroup != sourceGroup) {
		
		NSString *oldEntityClassName = [sourceGroup itemEntityName];
		NSString *newEntityClassName = [newSourceGroup itemEntityName];
		BDSKTableDisplayController *newDisplayController = nil;
		BOOL shouldChangeDisplayController = NO;
		
		if ([newEntityClassName isEqualToString:oldEntityClassName] == NO) {
			newDisplayController = [self displayControllerForEntityName:newEntityClassName];
			//if (newDisplayController != currentDisplayController){
				[self unbindDisplayController:currentDisplayController];
				shouldChangeDisplayController = YES;
			//}
		}
		
		[sourceGroup autorelease];
		sourceGroup = [newSourceGroup retain];
		
		if (shouldChangeDisplayController == YES)
			[self setDisplayController:newDisplayController];
        
        [currentDisplayController setEditable:[sourceGroup canAddItems]];
	}
}

- (id)displayController{
    return currentDisplayController;
}

- (void)setDisplayController:(id)newDisplayController{
    //if(newDisplayController != currentDisplayController){
        [currentDisplayController autorelease];
        if(currentDisplayController)
            [self unbindDisplayController:currentDisplayController];
        
        NSView *view = [newDisplayController view];
        if (view == nil) 
            view = [[[NSView alloc] init] autorelease];
        [view setFrame:[currentDisplayView frame]];
        [[currentDisplayView superview] replaceSubview:currentDisplayView with:view];
        currentDisplayView = view;
        currentDisplayController = [newDisplayController retain];
        [currentDisplayController setItemEntityName:[sourceGroup itemEntityName]];
        [self bindDisplayController:currentDisplayController];
    //}
}

- (NSArray *)displayControllers{
	return displayControllers;
}

// TODO: this is totally incomplete.
- (NSArray *)displayControllersForCurrentType{
    NSSet* currentTypes = nil; // temporary, removed treecontroller.
    NSLog(@"displayControllersForCurrentType - currentTypes is %@.", currentTypes);
    
    return [NSArray arrayWithObjects:currentDisplayController, nil];
}


#pragma mark Display Controller management

- (void)setupDisplayControllers{
    
    NSArray *displayControllerClassNames = [displayControllersInfoDict allKeys];
    NSEnumerator *displayControllerClassNameE = [displayControllerClassNames objectEnumerator];
    NSString *displayControllerClassName = nil;
    
    while (displayControllerClassName = [displayControllerClassNameE nextObject]){
        Class controllerClass = NSClassFromString(displayControllerClassName);
        BDSKTableDisplayController *controllerObject = [[controllerClass alloc] init];
        [controllerObject setDocument:[self document]];
        [displayControllers addObject:controllerObject];
        [controllerObject release];

        NSDictionary *infoDict = [displayControllersInfoDict objectForKey:displayControllerClassName];
           
        //TODO: for now we have a 1:1 between DCs and entity names. 
        // this code will need to get smarter when that changes.
        NSString *displayableEntity = [[infoDict objectForKey:@"DisplayableEntities"] objectAtIndex:0];
        [currentDisplayControllerForEntity setObject:controllerObject
                                              forKey:displayableEntity];
    }
    
}

- (id)displayControllerForEntityName:(NSString *)entityName{
    NSManagedObjectContext *context = [self managedObjectContext];
    NSEntityDescription *entity = [NSEntityDescription entityForName:entityName inManagedObjectContext:context];
    id displayController = nil;
    
    while (displayController == nil && entity != nil) {
        displayController = [currentDisplayControllerForEntity objectForKey:[entity name]];
        entity = [entity superentity];
    }
    return displayController;
}

- (void)bindDisplayController:(id)displayController{
	// Not binding the contentSet will get all the managed objects for the entity
	// Binding contentSet will not update a dynamic smart group
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:NO], NSRaisesForNotApplicableKeysBindingOption, [NSNumber numberWithBool:YES], NSConditionallySetsEnabledBindingOption, [NSNumber numberWithBool:YES], NSDeletesObjectsOnRemoveBindingsOption, nil];
    // TODO: in future, this should create multiple bindings.?    
    [[displayController itemsArrayController] bind:@"contentSet" toObject:self
                                       withKeyPath:@"sourceGroup.items" options:options];
    // TODO: in future, this should create multiple bindings.?    
    
    NSArray *filterPredicates = [displayController filterPredicates];
    int i, count = [filterPredicates count];
    NSString *key = @"predicate";
    for (i = 0; i < count; i++) {
        if (i > 0) 
            key = [NSString stringWithFormat:@"predicate%i", i+1];
        options = [filterPredicates objectAtIndex:i];
        [searchField bind:key toObject:[displayController itemsArrayController]
                           withKeyPath:@"filterPredicate" options:options];
    }
}


// TODO: as the above method creates multiple bindings, this one will have to keep up.
// mb the display controllers themselves should be 
- (void)unbindDisplayController:(id)displayController{
    int i = [[displayController filterPredicates] count];
    NSString *key;
    while (i-- > 0) {
        key = (i == 0) ? @"predicate" : [NSString stringWithFormat:@"predicate%i", i+1];
        [searchField unbind:key];
    }
	[[displayController itemsArrayController] unbind:@"contentSet"];
}


#pragma mark Actions

- (IBAction)addNewItem:(id)sender{
    BDSKGroup *selectedGroup = [self sourceGroup];
    if (NSIsControllerMarker(selectedGroup) || [selectedGroup canAddItems] == NO) {
        NSBeep();
        return;
    }
    
    [currentDisplayController addItem];
}

- (IBAction)removeSelectedItems:(id)sender {
    BDSKGroup *selectedGroup = [self sourceGroup];
    NSArray *selectedItems = [[currentDisplayController itemsArrayController] selectedObjects];
    if (NSIsControllerMarker(selectedItems) || NSIsControllerMarker(selectedGroup) || [selectedGroup canAddItems] == NO) {
        NSBeep();
        return;
    }
    
    [currentDisplayController removeItems:selectedItems];
}

- (IBAction)delete:(id)sender {
    id firstResponder = [[self window] firstResponder];
    if ([firstResponder isKindOfClass:[NSText class]] && [firstResponder isFieldEditor])
        firstResponder = [firstResponder delegate];
    if (firstResponder == [currentDisplayController itemsTableView]) {
        [self removeSelectedItems:sender];
    } else {
        NSBeep();
    }
}

#pragma mark Toolbar stuff

// label, palettelabel, toolTip, action, and menu can all be NULL, depending upon what you want the item to do
- (NSToolbarItem *)addToolbarItemWithIdentifier:(NSString *)identifier label:(NSString *)label paletteLabel:(NSString *)paletteLabel toolTip:(NSString *)toolTip target:(id)target action:(SEL)action itemContent:(id)itemContent menuItem:(NSMenuItem *)menuItem
{
    // here we create the NSToolbarItem and setup its attributes in line with the parameters
    NSToolbarItem *item = [[NSToolbarItem alloc] initWithItemIdentifier:identifier];
    [item setLabel:label];
    [item setPaletteLabel:paletteLabel];
    [item setToolTip:toolTip];
    [item setTarget:target];
    if ([itemContent isKindOfClass:[NSImage class]]) 
        [item setImage:itemContent];
    else if ([itemContent isKindOfClass:[NSView class]]) {
        [item setView:itemContent];
        // If we have a custom view, we *have* to set the min/max size - otherwise, it'll default to 0,0 and the custom
        // view won't show up at all!  This doesn't affect toolbar items with images, however.
        [item setMinSize:[itemContent bounds].size];
        [item setMaxSize:[itemContent bounds].size];
    }
    [item setAction:action];
    // The menuItem to be shown in text only mode. Don't reset this when we use the default behavior. 
	if (menuItem != nil)
		[item setMenuFormRepresentation:menuItem];
    // Now that we've setup all the settings for this new toolbar item, we add it to the dictionary.
    // The dictionary retains the toolbar item for us, which is why we could autorelease it when we created
    // it (above).
    [toolbarItems setObject:item forKey:identifier];
    [item release];
    
    return item;
}

- (NSToolbar *) setupToolbar {
    // Create a new toolbar instance, and attach it to our document window
    NSToolbar *toolbar = [[[NSToolbar alloc] initWithIdentifier:BDSKDocumentToolbarIdentifier] autorelease];

    toolbarItems = [[NSMutableDictionary dictionary] retain];
    
    // Set up toolbar properties: Allow customization, give a default display mode, and remember state in user defaults
    [toolbar setAllowsUserCustomization: YES];
    [toolbar setAutosavesConfiguration: YES];
    [toolbar setDisplayMode: NSToolbarDisplayModeDefault];

    // We are the delegate
    [toolbar setDelegate: self];

    // add toolbaritems:
    NSToolbarItem *item;

    [self addToolbarItemWithIdentifier:BDSKDocumentToolbarNewItemIdentifier
                                 label:NSLocalizedString(@"New Item",@"")
                          paletteLabel:NSLocalizedString(@"New Item",@"")
                               toolTip:NSLocalizedString(@"Create New Item",@"")
                                target:self
                                action:@selector(addNewItem:)
                           itemContent:[NSImage imageNamed: @"New"]
                              menuItem:nil];

    [self addToolbarItemWithIdentifier:BDSKDocumentToolbarDeleteItemIdentifier
                                 label:NSLocalizedString(@"Delete Item",@"")
                          paletteLabel:NSLocalizedString(@"Delete Item",@"")
                               toolTip:NSLocalizedString(@"Delete Selected Item",@"")
                                target:self
                                action:@selector(removeSelectedItems:)
                           itemContent:[NSImage imageNamed: @"Delete"]
                              menuItem:nil];

    item = [self addToolbarItemWithIdentifier:BDSKDocumentToolbarSearchItemIdentifier
                                 label:NSLocalizedString(@"Search",@"")
                          paletteLabel:NSLocalizedString(@"Search",@"")
                               toolTip:NSLocalizedString(@"Search",@"")
                                target:nil
                                action:NULL
                           itemContent:searchField
                              menuItem:nil];
    [item setMinSize:NSMakeSize(50, NSHeight([searchField bounds]))];
    [item setMaxSize:NSMakeSize(1000, NSHeight([searchField bounds]))];
    
    return toolbar;
}

- (NSToolbarItem *) toolbar: (NSToolbar *)toolbar
      itemForItemIdentifier: (NSString *)itemIdent
  willBeInsertedIntoToolbar:(BOOL) willBeInserted {

    NSToolbarItem *item = [toolbarItems objectForKey:itemIdent];
    NSToolbarItem *newItem = [[item copy] autorelease];
    return newItem;
}

- (NSArray *) toolbarDefaultItemIdentifiers: (NSToolbar *) toolbar {
    return [NSArray arrayWithObjects:
		BDSKDocumentToolbarNewItemIdentifier,
		NSToolbarFlexibleSpaceItemIdentifier, 
		BDSKDocumentToolbarSearchItemIdentifier, nil];
}

- (NSArray *) toolbarAllowedItemIdentifiers: (NSToolbar *) toolbar {
    return [NSArray arrayWithObjects: 
		BDSKDocumentToolbarNewItemIdentifier, 
		BDSKDocumentToolbarDeleteItemIdentifier, 
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
    }

    return YES;
}

@end
