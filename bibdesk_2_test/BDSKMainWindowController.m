//
//  BDSKMainWindowController.m
//  bd2
//
//  Created by Michael McCracken on 6/16/05.
//  Copyright 2005 Michael McCracken. All rights reserved.
//

#import "BDSKMainWindowController.h"


@implementation BDSKMainWindowController

- (id)initWithWindowNibName:(NSString *)windowNibName{
    if (self = [super initWithWindowNibName:windowNibName]){
        currentEntityClassName = @""; //??
        displayControllersInfoDict = [[NSDictionary alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"DisplayControllers" ofType:@"plist"]];
        displayControllers = [[NSMutableArray alloc] initWithCapacity:10];
        currentDisplayControllerForEntity = [[NSMutableDictionary alloc] initWithCapacity:10];
    }
    
    return self;
}

- (void)awakeFromNib{
    // possibly temporary:
    
    [self bind:@"currentEntityClassName"
      toObject:sourceListTreeController
   withKeyPath:@"selection.entity.managedObjectClassName"
       options:nil];
    
    // Set up all available display controllers
    [self setupDisplayControllers];
    
    [sourceListTreeController performSelector:@selector(setSelectionIndexPath:)
                                   withObject:[NSIndexPath indexPathWithIndex:0]
                                   afterDelay:0.01];
    
    // permanent:
    NSTableColumn *tc = [sourceList tableColumnWithIdentifier:@"mainColumn"];
    [tc setDataCell:[[[ImageAndTextCell alloc] init] autorelease]];
}

- (void)dealloc{
    [self unbind:@"currentEntityClassName"];
    [currentEntityClassName release];
    [displayControllers release];
    [currentDisplayControllerForEntity release];        
    [displayControllersInfoDict release];
    [super dealloc];
}


#pragma mark Accessors

- (NSString *)currentEntityClassName{ return currentEntityClassName;}

- (void)setCurrentEntityClassName:(NSString *)newEntityClassName{
    if(newEntityClassName != currentEntityClassName){
        [currentEntityClassName autorelease];
        currentEntityClassName = [newEntityClassName copy];
        [self selectedEntityClassDidChange];
    }
}

- (NSArray *)displayControllers{ return displayControllers;}

- (NSArray *)displayControllersForCurrentType{
    NSSet* currentTypes = [[sourceListTreeController selectedObjects] valueForKeyPath:@"@distinctUnionOfObjects.entity.name"];
    NSLog(@"displayControllersForCurrentType - currentTypes is %@.", currentTypes);
    
    return [NSArray arrayWithObjects:currentDisplayController, nil];
}

- (void)setDisplayController:(id)newDisplayController{
    if(newDisplayController != currentDisplayController){
        [currentDisplayController autorelease];
        if(currentDisplayController)
            [self unbindDisplayController:currentDisplayController];
        
        [mainSplitView replaceSubview:currentDisplayView with:[newDisplayController view]];

        currentDisplayView = [newDisplayController view];
        currentDisplayController = [newDisplayController retain];
        [self bindDisplayController:currentDisplayController];
    }
}

#pragma mark Display Controller management

- (void)setupDisplayControllers{
    
    NSArray *displayControllerClassNames = [displayControllersInfoDict allKeys];
    NSEnumerator *displayControllerClassNameE = [displayControllerClassNames objectEnumerator];
    NSString *displayControllerClassName = nil;
    
    while (displayControllerClassName = [displayControllerClassNameE nextObject]){
        NSLog(@"registering one %@", displayControllerClassName);
        Class controllerClass = NSClassFromString(displayControllerClassName);
        id controllerObject = [[controllerClass alloc] initWithItemSource:self];
        [displayControllers addObject:controllerObject];

        NSDictionary *infoDict = [displayControllersInfoDict objectForKey:displayControllerClassName];
           
        //TODO: for now we have a 1:1 between DCs and entity names. 
        // this code will need to get smarter when that changes.
        NSString *displayableClass = [[infoDict objectForKey:@"DisplayableClasses"] objectAtIndex:0];
        [currentDisplayControllerForEntity setObject:controllerObject
                                              forKey:displayableClass];
    }
    
    [self setDisplayController:[displayControllers objectAtIndex:1]];
    
    NSLog(@"displayControllers is %@, %p", [self displayControllers], displayControllers);
}

- (void)bindDisplayController:(id)displayController{
    
    NSString *itemsKeyPath = [displayController itemsKeyPath];
    NSString *selectionKeyPath = [displayController selectionKeyPath];
    
    // TODO: in future, this should create multiple bindings.
    // also, mb selectionkeypath should be just the last component, in case it isn't always
    // just the selection, like if we have intervening filter controllers.
    [displayController bind:itemsKeyPath toObject:sourceListTreeController
                       withKeyPath:selectionKeyPath options:nil];
    
}

// TODO: as the above method creates multiple bindings, this one will have to keep up.
// mb the display controllers themselves should be 
- (void)unbindDisplayController:(id)displayController{
    [displayController unbind:[displayController itemsKeyPath]];
}


// Actions

// TODO: all of the add new *Group actions here could theoretically be better done
// by letting the sourceListTreeController know what class it should be creating
// and just going on that.

- (IBAction)addNewPublication:(id)sender{
    NSManagedObjectContext *managedObjectContext = [[self document] managedObjectContext];
    id newPublication = [NSEntityDescription insertNewObjectForEntityForName:PublicationEntityName
                                           inManagedObjectContext:managedObjectContext];
    
    id selectedPublicationGroup = [sourceListTreeController selection];
    if(selectedPublicationGroup == NSNotApplicableMarker ||
       selectedPublicationGroup == NSMultipleValuesMarker ||
       selectedPublicationGroup == NSNoSelectionMarker){
        NSLog(@"tried to add a pub to a %@. should have had the action disabled, fool", selectedPublicationGroup);
        return;
    }
    NSMutableSet *publications = [selectedPublicationGroup mutableSetValueForKey:@"publications"];
    [publications addObject:newPublication];
    
}

- (IBAction)addNewPublicationGroup:(id)sender{
    NSManagedObjectContext *managedObjectContext = [[self document] managedObjectContext];
    id newPublicationGroup = [NSEntityDescription insertNewObjectForEntityForName:PublicationGroupEntityName
                                                  inManagedObjectContext:managedObjectContext];
    
    [newPublicationGroup setValue:@"Untitled Publication Group" forKey:@"name"];
    
    id selectedPublicationGroup = [sourceListTreeController selection];
    if(selectedPublicationGroup == NSNotApplicableMarker ||
       selectedPublicationGroup == NSMultipleValuesMarker ||
       selectedPublicationGroup == NSNoSelectionMarker){
        NSLog(@"tried to add a pubGroup to a non-pubGroup. should have had the action disabled, fool");
        return;
    }
    NSMutableSet *children = [selectedPublicationGroup mutableSetValueForKey:@"children"];
    [children addObject:newPublicationGroup];
    
}


- (IBAction)addNewNote:(id)sender{
    NSManagedObjectContext *managedObjectContext = [[self document] managedObjectContext];
    id newNote = [NSEntityDescription insertNewObjectForEntityForName:NoteEntityName
                                               inManagedObjectContext:managedObjectContext];
    
    id selectedNoteGroup = [sourceListTreeController selection];
    if(selectedNoteGroup == NSNotApplicableMarker ||
       selectedNoteGroup == NSMultipleValuesMarker ||
       selectedNoteGroup == NSNoSelectionMarker){
        NSLog(@"tried to add a pub to a %@. should have had the action disabled, fool", selectedNoteGroup);
        return;
    }
    NSMutableSet *notes = [selectedNoteGroup mutableSetValueForKey:@"notes"];
    [notes addObject:newNote];
}

- (IBAction)addNewNoteGroup:(id)sender{
    NSManagedObjectContext *managedObjectContext = [[self document] managedObjectContext];
    id newNoteGroup = [NSEntityDescription insertNewObjectForEntityForName:NoteGroupEntityName
                                                 inManagedObjectContext:managedObjectContext];
    
    [newNoteGroup setValue:@"Untitled Note Group" forKey:@"name"];


    id selectedNoteGroup = [sourceListTreeController selection];
    if(selectedNoteGroup == NSNotApplicableMarker ||
       selectedNoteGroup == NSMultipleValuesMarker ||
       selectedNoteGroup == NSNoSelectionMarker){
        NSLog(@"tried to add a noteGroup to a non-noteGroup. should have had the action disabled, fool");
        return;
    }
    NSMutableSet *children = [selectedNoteGroup mutableSetValueForKey:@"children"];
    [children addObject:newNoteGroup];
}

#pragma mark Source List Outline View Delegate Methods and such

- (void)selectedEntityClassDidChange{
    
    NSLog(@"in sourceListSelectionDidChange, myentityclassname is %@ and selindp is %@", [self currentEntityClassName], [sourceListTreeController selectionIndexPath]);
    
    id newDC = [currentDisplayControllerForEntity objectForKey:[self currentEntityClassName]];
    
    NSLog(@"newDC is %@ from %@", newDC, currentDisplayControllerForEntity);
    
    [self setDisplayController:newDC];

}

// BEWARE: This is not the method you're looking for.
// If you want to change what we do when the selection changes, 
// look at -sourceListSelectionDidChange. Most of the interesting stuff is in there.
// That method responds to the treecontroller's selection binding changing.
// This method is more low-level, because we get it here as a result of being the 
//  outline view's delegate.
//
// We use this method to unbind the current displaycontroller
//  before the treecontroller notifies it of a change to its selection key,
// which might break that displaycontroller if it doesn't support the
// entity that the new selection represents.
// if it does support it, we might just end up reestablishing the same bindings
// over again.
- (void)outlineViewSelectionIsChanging:(NSNotification *)aNotification{
    
    if(currentDisplayController){
        [self unbindDisplayController:currentDisplayController];
    }
}

- (void)outlineView:(NSOutlineView *)olv 
    willDisplayCell:(NSCell *)cell 
     forTableColumn:(NSTableColumn *)tableColumn
               item:(id)item {    
    id itemObject = [item observedObject];
    
    if ([[tableColumn identifier] isEqualToString:@"mainColumn"]) {
        [(ImageAndTextCell*)cell setLeftImage:[itemObject icon]];
    }
}

@end
