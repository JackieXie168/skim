//  BDSKDocument.m
//  bd2
//
//  Created by Michael McCracken on 5/14/05.
//  Copyright Michael McCracken 2005 . All rights reserved.

#import "BDSKDocument.h"
#import "BDSKImporters.h"
#import "BDSKBibTeXParser.h"
#import "BDSKPerson.h"

NSString *BDSKPublicationPboardType = @"BDSKPublicationPboardType";
NSString *BDSKPersonPboardType = @"BDSKPersonPboardType";
NSString *BDSKNotePboardType = @"BDSKNotePboardType";
NSString *BDSKInstitutionPboardType = @"BDSKInstitutionPboardType";
NSString *BDSKVenuePboardType = @"BDSKVenuePboardType";
NSString *BDSKTagPboardType = @"BDSKTagPboardType";

@implementation BDSKDocument

- (id)init{
    self = [super init];
    if (self != nil) {
        NSManagedObjectContext *context = [self managedObjectContext];
        NSPersistentStoreCoordinator *coordinator = [context persistentStoreCoordinator];
        
        if (coordinator != nil) {
            inMemoryStore = [[coordinator addPersistentStoreWithType:NSInMemoryStoreType configuration:@"InMemoryConfiguration" URL:nil options:nil error:nil] retain];
        }
        
        // add the library groups
        // disable undo, because we don't want the document to be dirtied
        
        [[context undoManager] disableUndoRegistration];
        
        id libraryGroup = [NSEntityDescription insertNewObjectForEntityForName:LibraryGroupEntityName
                                                        inManagedObjectContext:[self managedObjectContext]];
        [libraryGroup setValue:PublicationEntityName forKey:@"itemEntityName"];
        [libraryGroup setValue:NSLocalizedString(@"All Publications", @"Top level Publication group name") forKey:@"name"];
        [libraryGroup setValue:[NSNumber numberWithShort:9] forKey:@"priority"];
        
        libraryGroup = [NSEntityDescription insertNewObjectForEntityForName:LibraryGroupEntityName
                                                     inManagedObjectContext:[self managedObjectContext]];
        [libraryGroup setValue:PersonEntityName forKey:@"itemEntityName"];
        [libraryGroup setValue:NSLocalizedString(@"All People", @"Top level Person group name") forKey:@"name"];
        [libraryGroup setValue:[NSNumber numberWithShort:8] forKey:@"priority"];
        
        libraryGroup = [NSEntityDescription insertNewObjectForEntityForName:LibraryGroupEntityName
                                                     inManagedObjectContext:[self managedObjectContext]];
        [libraryGroup setValue:InstitutionEntityName forKey:@"itemEntityName"];
        [libraryGroup setValue:NSLocalizedString(@"All Institutions", @"Top level Institution group name") forKey:@"name"];
        [libraryGroup setValue:[NSNumber numberWithShort:7] forKey:@"priority"];
        
        libraryGroup = [NSEntityDescription insertNewObjectForEntityForName:LibraryGroupEntityName
                                                     inManagedObjectContext:[self managedObjectContext]];
        [libraryGroup setValue:VenueEntityName forKey:@"itemEntityName"];
        [libraryGroup setValue:NSLocalizedString(@"All Venues", @"Top level Venue group name") forKey:@"name"];
        [libraryGroup setValue:[NSNumber numberWithShort:6] forKey:@"priority"];
        
        libraryGroup = [NSEntityDescription insertNewObjectForEntityForName:LibraryGroupEntityName
                                                     inManagedObjectContext:[self managedObjectContext]];
        [libraryGroup setValue:NoteEntityName forKey:@"itemEntityName"];
        [libraryGroup setValue:NSLocalizedString(@"All Notes", @"Top level Note group name") forKey:@"name"];
        [libraryGroup setValue:[NSNumber numberWithShort:5] forKey:@"priority"];
        
        libraryGroup = [NSEntityDescription insertNewObjectForEntityForName:LibraryGroupEntityName
                                                     inManagedObjectContext:[self managedObjectContext]];
        [libraryGroup setValue:TagEntityName forKey:@"itemEntityName"];
        [libraryGroup setValue:NSLocalizedString(@"All Tags", @"Top level Tag group name") forKey:@"name"];
        [libraryGroup setValue:[NSNumber numberWithShort:4] forKey:@"priority"];
        
        [context processPendingChanges];
        [[context undoManager] enableUndoRegistration];
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
   
    // temporary data set up
     NSManagedObjectContext *managedObjectContext = [self managedObjectContext];
    
    id pub = [NSEntityDescription insertNewObjectForEntityForName:PublicationEntityName
                                                 inManagedObjectContext:managedObjectContext];
    [pub setValue:@"Test Pub" forKey:@"title"];
    
    id note = [NSEntityDescription insertNewObjectForEntityForName:NoteEntityName
                                           inManagedObjectContext:managedObjectContext];
    [note setValue:@"Note1" forKey:@"name"];
    [note setValue:@"Value of note1" forKey:@"value"];
    [[pub mutableSetValueForKey:@"notes"] addObject:note];
    
    id tag1 = [NSEntityDescription insertNewObjectForEntityForName:TagEntityName
                                           inManagedObjectContext:managedObjectContext];
    [tag1 setValue:@"tagsRCool" forKey:@"name"];
    [[pub mutableSetValueForKey:@"tags"] addObject:tag1];
    
	
    id person1 = [NSEntityDescription insertNewObjectForEntityForName:PersonEntityName
                                              inManagedObjectContext:managedObjectContext];
    [person1 setValue:@"Blow" forKey:@"lastNamePart"];
    [person1 setValue:@"Joe" forKey:@"firstNamePart"];

    id person2 = [NSEntityDescription insertNewObjectForEntityForName:PersonEntityName
                                            inManagedObjectContext:managedObjectContext];
    [person2 setValue:@"Blow" forKey:@"lastNamePart"];
    [person2 setValue:@"John" forKey:@"firstNamePart"];
    
    id tag2 = [NSEntityDescription insertNewObjectForEntityForName:TagEntityName
                                           inManagedObjectContext:managedObjectContext];
    [tag2 setValue:@"JohnBlowGroup" forKey:@"name"];
    [[person2 mutableSetValueForKey:@"tags"] addObject:tag2];
    
    id relationship1 = [NSEntityDescription insertNewObjectForEntityForName:ContributorPublicationRelationshipEntityName
                                              inManagedObjectContext:managedObjectContext];
    [relationship1 setValue:@"author" forKey:@"relationshipType"];
    [relationship1 setValue:[NSNumber numberWithInt:0] forKey:@"index"];
    [relationship1 setValue:person1 forKey:@"contributor"];
    [relationship1 setValue:pub forKey:@"publication"];

    id contributorPublicationRelationships = [pub mutableSetValueForKey:@"contributorRelationships"];
    [contributorPublicationRelationships addObject:relationship1];
    
    id relationship2 = [NSEntityDescription insertNewObjectForEntityForName:ContributorPublicationRelationshipEntityName
                                                 inManagedObjectContext:managedObjectContext];
    [relationship2 setValue:@"author" forKey:@"relationshipType"];
    [relationship2 setValue:[NSNumber numberWithInt:1] forKey:@"index"];
    [relationship2 setValue:person2  forKey:@"contributor"];
    [relationship2 setValue:pub forKey:@"publication"];
    
    [contributorPublicationRelationships addObject:relationship2];
    
    id institution1 = [NSEntityDescription insertNewObjectForEntityForName:@"Institution" inManagedObjectContext:managedObjectContext];
    
    [institution1 setValue:@"Penn State" forKey:@"name"];
    
    id institution2 = [NSEntityDescription insertNewObjectForEntityForName:@"Institution" inManagedObjectContext:managedObjectContext];
    
    [institution2 setValue:@"UC San Diego" forKey:@"name"];
    
    
    id institutionRelationship1 = [NSEntityDescription insertNewObjectForEntityForName:PersonInstitutionRelationshipEntityName
                                                               inManagedObjectContext:managedObjectContext];
    [institutionRelationship1 setValue:@"phd student" forKey:@"relationshipType"];
    [institutionRelationship1 setValue:person1 forKey:@"person"];
    [institutionRelationship1 setValue:institution1 forKey:@"institution"];
    [institutionRelationship1 setValue:[NSDate dateWithNaturalLanguageString:@"8/30/1997"] forKey:@"startDate"];
    [institutionRelationship1 setValue:[NSDate dateWithNaturalLanguageString:@"4/1/2001"] forKey:@"endDate"];
        
    
    id institutionRelationship2 = [NSEntityDescription insertNewObjectForEntityForName:PersonInstitutionRelationshipEntityName
                                                               inManagedObjectContext:managedObjectContext];
    [institutionRelationship2 setValue:@"phd student" forKey:@"relationshipType"];
    [institutionRelationship2 setValue:person2 forKey:@"person"];
    [institutionRelationship2 setValue:institution2 forKey:@"institution"];

    [institutionRelationship2 setValue:[NSDate dateWithNaturalLanguageString:@"9/11/2001"] forKey:@"startDate"];
    
    
    return self;
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
    [inMemoryStore release];
	[super dealloc];
}

- (void)makeWindowControllers{
    BDSKMainWindowController *mwc = [[BDSKMainWindowController alloc] initWithWindowNibName:@"BDSKMainWindow"];
	[mwc setShouldCloseDocument:YES];
    [self addWindowController:[mwc autorelease]];
}


- (void)windowControllerDidLoadNib:(NSWindowController *)windowController{
    [super windowControllerDidLoadNib:windowController];
    // user interface preparation code
}

- (BOOL)configurePersistentStoreCoordinatorForURL:(NSURL *)url ofType:(NSString *)fileType error:(NSError **)error {
    NSPersistentStoreCoordinator *coordinator = [[self managedObjectContext] persistentStoreCoordinator];
    NSString *storeType = [self persistentStoreTypeForFileType:fileType];
    NSError *outError = nil;
    
    [coordinator addPersistentStoreWithType:storeType configuration:@"PersistentConfiguration" URL:url options:nil error:&outError];
    
    if (outError != nil) {
        if (error != NULL) 
            *error = outError; 
        return NO;
    }
    return YES;
}

- (BOOL)readFromURL:(NSURL *)absoluteURL ofType:(NSString *)typeName error:(NSError **)outError {
    if ([typeName isEqualToString:@"BibTeX database"]) {
        NSData *data = [NSData dataWithContentsOfURL:absoluteURL];
        NSError *error = nil;
        
        [BDSKBibTeXParser itemsFromData:data error:&error frontMatter:nil filePath:[self fileName] document:self];
        
        if (error) {
            if (outError) *outError = error;
            return NO;
        }
        return YES;
    } else {
        return [super readFromURL:absoluteURL ofType:typeName error:outError];
    }
}

#pragma mark Default library groups

- (NSManagedObject *)publicationLibraryGroup{
	return [self libraryGroupForEntityName:PublicationEntityName];
}

- (NSManagedObject *)personLibraryGroup{
	return [self libraryGroupForEntityName:PersonEntityName];
}

- (NSManagedObject *)noteLibraryGroup{
	return [self libraryGroupForEntityName:NoteEntityName];
}

- (NSManagedObject *)institutionLibraryGroup{
	return [self libraryGroupForEntityName:InstitutionEntityName];
}

- (NSManagedObject *)venueLibraryGroup{
	return [self libraryGroupForEntityName:VenueEntityName];
}

- (NSManagedObject *)tagLibraryGroup{
	return [self libraryGroupForEntityName:TagEntityName];
}

- (NSManagedObject *)libraryGroupForEntityName:(NSString *)entityName{
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"itemEntityName == %@", entityName];
    NSManagedObjectContext *moc = [self managedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];

    [fetchRequest setPredicate:predicate];
    
    NSError *fetchError = nil;
    NSArray *fetchResults;
    @try {
        NSEntityDescription *entity = [NSEntityDescription entityForName:LibraryGroupEntityName
                                                  inManagedObjectContext:moc];
        [fetchRequest setEntity:entity];
        fetchResults = [moc executeFetchRequest:fetchRequest error:&fetchError];
    } @finally {
        [fetchRequest release];
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

#pragma mark Add new publications from parsed info

- (NSSet *)newPublicationsFromDictionaries:(NSSet *)dictionarySet{
    NSManagedObjectContext *moc = [self managedObjectContext];
    
    NSMutableDictionary *allRelationshipsByName = [NSMutableDictionary dictionary];
    
    NSMutableSet *returnSet = [[NSMutableSet alloc] initWithCapacity:[dictionarySet count]];
    NSEnumerator *dictEnum = [dictionarySet objectEnumerator];
    NSDictionary *dict;
    
    while (dict = [dictEnum nextObject]) {
        
        NSManagedObject *publication = [NSEntityDescription insertNewObjectForEntityForName:@"Publication" inManagedObjectContext:moc];
        
        NSMutableSet *keyValuePairs = [publication mutableSetValueForKey:@"keyValuePairs"];
        NSMutableSet *contributors = [publication mutableSetValueForKey:@"contributorRelationships"];
        NSMutableSet *notes = [publication mutableSetValueForKey:@"notes"];
        
        NSEnumerator *keyEnum = [dict keyEnumerator];
        NSString *key;
        id value;
        
        while (key = [keyEnum nextObject]) {
            
            value = [dict objectForKey:key];
            key = [key capitalizedString];
            
            if ([key isEqualToString:@"Author"] || [key isEqualToString:@"Editor"]) {
                
                NSArray *names = ([value isKindOfClass:[NSArray class]]) ? value : [NSArray arrayWithObject:value];
                NSEnumerator *nameEnum = [names objectEnumerator];
                NSString *name;
                NSManagedObject *relationship;
                while (name = [nameEnum nextObject]) {
                    // create a relationship to link to the publication
                    relationship = [NSEntityDescription insertNewObjectForEntityForName:ContributorPublicationRelationshipEntityName inManagedObjectContext:moc];

                    // add the relationship to a dictionary of sets - to be linked up later.
                    NSString *normalizedName = [BDSKBibTeXParser normalizedNameFromString:name];
                    NSMutableSet *relationshipSet = [allRelationshipsByName objectForKey:normalizedName];
                    
                    if(relationshipSet == nil){
                        relationshipSet = [NSMutableSet set];
                        [allRelationshipsByName setObject:relationshipSet forKey:normalizedName];
                    }
                    [relationshipSet addObject:relationship];
                    
                    [relationship setValue:[key lowercaseString] forKey:@"relationshipType"];
                    [relationship setValue:[NSNumber numberWithInt:[contributors count]] forKey:@"index"];
                    [contributors addObject:relationship];
                }
            } else if ([key isEqualToString:@"Annotation"]) {
                NSManagedObject *note = [NSEntityDescription insertNewObjectForEntityForName:NoteEntityName inManagedObjectContext:moc];
                [notes addObject:note];
            } else if ([key isEqualToString:@"Journal"]) {
                NSManagedObject *venue = [NSEntityDescription insertNewObjectForEntityForName:VenueEntityName inManagedObjectContext:moc];
                [venue setValue:value forKey:@"name"];
                [publication setValue:venue forKey:@"venue"];
            } else if ([key isEqualToString:@"Publication Type"]) {
                [publication setValue:value forKey:@"publicationType"];
            } else if ([key isEqualToString:@"Cite Key"]) {
                [publication setValue:value forKey:@"citeKey"];
            } else if ([key isEqualToString:@"Title"]) {
                [publication setValue:value forKey:@"title"];
            } else if ([key isEqualToString:@"Short-Title"]) {
                [publication setValue:value forKey:@"shortTitle"];
            } else if ([key isEqualToString:@"Date-Added"]) {
                [publication setValue:[NSDate dateWithNaturalLanguageString:value] forKey:@"dateAdded"];
            } else if ([key isEqualToString:@"Date-Modified"]) {
                [publication setValue:[NSDate dateWithNaturalLanguageString:value] forKey:@"dateChanged"];
            } else {
                NSManagedObject *keyValuePair = [NSEntityDescription insertNewObjectForEntityForName:@"KeyValuePair" inManagedObjectContext:moc];
                [keyValuePair setValue:key forKey:@"key"];
                [keyValuePair setValue:value forKey:@"value"];
                [keyValuePairs addObject:keyValuePair];
            }
        }
        
        [returnSet addObject:publication];
    }
    
    // second pass to create people and link up relationships efficiently
    
    NSArray *newPeopleNames = [allRelationshipsByName allKeys];
    NSMutableSet *people = [BDSKPerson findOrCreatePeopleWithNames:newPeopleNames
                                              managedObjectContext:moc];
    NSEnumerator *personE = [people objectEnumerator];
    NSManagedObject *person = nil;
    while(person = [personE nextObject]){
        NSSet *relationships = [allRelationshipsByName objectForKey:[person valueForKey:@"name"]];
        NSEnumerator *relationshipE = [relationships objectEnumerator];
        NSManagedObject *relationship = nil;
        while(relationship = [relationshipE nextObject]){
            [relationship setValue:person forKey:@"contributor"];
        }
    }
    
    
    return [returnSet autorelease];
}

@end
