//  BDSKDocument.m
//  bd2
//
//  Created by Michael McCracken on 5/14/05.
//  Copyright Michael McCracken 2005 . All rights reserved.

#import "BDSKDocument.h"

@implementation BDSKDocument

- (id)init{
    self = [super init];
    if (self != nil) {
        // initialization code
    }
    return self;
}

- (id)initWithType:(NSString *)typeName error:(NSError **)outError{
    // this method is invoked exactly once per document at the initial creation
    // of the document.  It will not be invoked when a document is opened after
    // being saved to disk.
    self = [super initWithType:typeName error:outError];
    if (self == nil)
        return nil;
    
    NSManagedObjectContext *managedObjectContext = [self managedObjectContext];
    
    
    id pubGroup = [NSEntityDescription insertNewObjectForEntityForName:PublicationGroupEntityName
                                                  inManagedObjectContext:managedObjectContext];
    [pubGroup setValue:[NSNumber numberWithBool:YES]
                forKey:@"isRoot"];
    [pubGroup setValue:NSLocalizedString(@"All Publications", @"Top level Publication group name")
                forKey:@"name"];
    
    id personGroup = [NSEntityDescription insertNewObjectForEntityForName:PersonGroupEntityName
                                             inManagedObjectContext:managedObjectContext];
    [personGroup setValue:[NSNumber numberWithBool:YES]
                   forKey:@"isRoot"];
    [personGroup setValue:NSLocalizedString(@"All People", @"Top level Person group name")
                   forKey:@"name"];
    
    id noteGroup = [NSEntityDescription insertNewObjectForEntityForName:NoteGroupEntityName
                                             inManagedObjectContext:managedObjectContext];
    [noteGroup setValue:[NSNumber numberWithBool:YES]
                 forKey:@"isRoot"];
    [noteGroup setValue:NSLocalizedString(@"All Notes", @"Top level Note group name")
                 forKey:@"name"];
    
    
    // clear the undo manager and change count for the document such that
    // untitled documents start with zero unsaved changes
    [managedObjectContext processPendingChanges];
    [[managedObjectContext undoManager] removeAllActions];
    [self updateChangeCount:NSChangeCleared];
        
    return self;
}


- (void)makeWindowControllers{
    BDSKMainWindowController *mwc = [[BDSKMainWindowController alloc] initWithWindowNibName:@"BDSKMainWindow"];
    [self addWindowController:[mwc autorelease]];
}


- (void)windowControllerDidLoadNib:(NSWindowController *)windowController{
    [super windowControllerDidLoadNib:windowController];
    // user interface preparation code
}


/* Accessors for root objects. Not currently used...
 */
- (NSManagedObject *)rootPubGroup{
    
    NSPredicate *rootItemPredicate = [NSPredicate predicateWithFormat:@"isRoot == YES "];
    
    NSManagedObjectContext *moc = [self managedObjectContext];
    
    NSFetchRequest *publicationGroupFetchRequest = [[NSFetchRequest alloc] init];
    [publicationGroupFetchRequest setPredicate:rootItemPredicate];
    
    NSError *fetchError = nil;
    NSArray *fetchResults;
    @try {
        NSEntityDescription *entity = [NSEntityDescription entityForName:PublicationGroupEntityName
                                                  inManagedObjectContext:moc];
        [publicationGroupFetchRequest setEntity:entity];
        fetchResults = [moc executeFetchRequest:publicationGroupFetchRequest error:&fetchError];
    } @finally {
        [publicationGroupFetchRequest release];
    }
    if ((fetchResults != nil) && ([fetchResults count] == 1) && (fetchError == nil)) {
        
        return [fetchResults objectAtIndex:0];
    }
    if (fetchError != nil) {
        [self presentError:fetchError];
        return nil;
    }
    
    return nil;   
    
}

- (NSManagedObject *)rootPersonGroup{
    
    NSPredicate *rootItemPredicate = [NSPredicate predicateWithFormat:@"isRoot == YES"];
    NSManagedObjectContext *moc = [self managedObjectContext];
    NSFetchRequest *groupFetchRequest = [[NSFetchRequest alloc] init];

    [groupFetchRequest setPredicate:rootItemPredicate];
    
    NSError *fetchError = nil;
    NSArray *fetchResults;
    @try {
        NSEntityDescription *entity = [NSEntityDescription entityForName:PersonGroupEntityName
                                                  inManagedObjectContext:moc];
        [groupFetchRequest setEntity:entity];
        fetchResults = [moc executeFetchRequest:groupFetchRequest error:&fetchError];
    } @finally {
        [groupFetchRequest release];
    }
    if ((fetchResults != nil) && ([fetchResults count] == 1) && (fetchError == nil)) {
        
        return [fetchResults objectAtIndex:0];
    }
    if (fetchError != nil) {
        [self presentError:fetchError];
        return nil;
    }
    
    return nil;   
}


@end
