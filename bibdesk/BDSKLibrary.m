//
//  BDSKLibrary.m
//  Bibdesk
//
//  Created by Michael McCracken on 2/11/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "BDSKLibrary.h"


@implementation BDSKLibrary

// init
- (id)init {
    if (self = [super init]) {
		publications = [[BibCollection alloc] initWithParent:self];
		[publications setName:NSLocalizedString(@"Library", @"Library label in source list of bibdocument")];
		[publications setItemClassName:NSStringFromClass([BibItem class])];
		
		authors = [[BibCollection alloc] initWithParent:self];
		[authors setName:NSLocalizedString(@"Authors", @"Authors label in source list of bibdocument")];
		[authors setItemClassName:NSStringFromClass([BibAuthor class])];
		
		notes = [[BibCollection alloc] initWithParent:self];
		[notes setName:NSLocalizedString(@"Notes", @"Notes label in source list of bibdocument")];
		[notes setItemClassName:NSStringFromClass([BibNote class])];
		
		sources = [[BibCollection alloc] initWithParent:self];
		[sources setName:NSLocalizedString(@"Sources", @"External Sources label in source list of bibdocument")];
		[sources setItemClassName:NSStringFromClass([BDSKRemoteSource class])];
    }
    return self;
}

- (void)makeWindowControllers{
	BDSKLibraryController *lc = [[BDSKLibraryController alloc] initWithWindowNibName:@"BDSKLibrary"];
	[self addWindowController:[lc autorelease]];
}

#pragma mark Data Archiving methods

- (NSData *)dataRepresentationOfType:(NSString *)type {
    NSKeyedArchiver *archiver;
    NSMutableData *data = [NSMutableData data];
    
    archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
    [archiver encodeObject:[self publications] forKey:@"publications"];
    [archiver encodeObject:[self authors] forKey:@"authors"];
    [archiver encodeObject:[self notes] forKey:@"notes"];
    [archiver encodeObject:[self sources] forKey:@"sources"];
    
    [archiver finishEncoding];
    [archiver release];
    return data;
}

// type will always be bibdesk library.
- (BOOL)loadDataRepresentation:(NSData *)data ofType:(NSString *)type {
    NSKeyedUnarchiver *unarchiver;
    
    unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
	[self setPublications:[unarchiver decodeObjectForKey:@"publications"]];
    [self setAuthors:[unarchiver decodeObjectForKey:@"authors"]];
    [self setNotes:[unarchiver decodeObjectForKey:@"notes"]];
    [self setSources:[unarchiver decodeObjectForKey:@"sources"]];
    
    [publications setParent:self];
    [publications setItemClassName:NSStringFromClass([BibItem class])];
    
    [authors setParent:self];
    [authors setItemClassName:NSStringFromClass([BibAuthor class])];
    
    [notes setParent:self];
    [notes setItemClassName:NSStringFromClass([BibNote class])];
    
    [sources setParent:self];
    [sources setItemClassName:NSStringFromClass([BDSKRemoteSource class])];

    [unarchiver finishDecoding];
    [unarchiver release];
    return YES;
}

#pragma mark accessors

- (void)addPublicationToLibrary:(BibItem *)pub{

	[publications addItem:pub];
    
	NSDictionary *notifInfo = [NSDictionary dictionaryWithObjectsAndKeys:pub, @"pub", nil];
	[[NSNotificationCenter defaultCenter] postNotificationName:BDSKDocAddItemNotification
														object:self
													  userInfo:notifInfo];
    
}

- (BibCollection *)publications { return [[publications retain] autorelease]; }

- (void)setPublications:(BibCollection *)aPublications {
    //NSLog(@"in -setPublications:, old value of publications: %@, changed to: %@", publications, aPublications);
	
    [publications release];
    publications = [aPublications copy];
}

- (BibCollection *)authors { return [[authors retain] autorelease]; }

- (void)setAuthors:(BibCollection *)anAuthors {
    //NSLog(@"in -setAuthors:, old value of authors: %@, changed to: %@", authors, anAuthors);
	
    [authors release];
    authors = [anAuthors copy];
}

- (BibCollection *)notes { return [[notes retain] autorelease]; }

- (void)setNotes:(BibCollection *)aNotes {
    //NSLog(@"in -setNotes:, old value of notes: %@, changed to: %@", notes, aNotes);
	
    [notes release];
    notes = [aNotes copy];
}

- (BibCollection *)sources { return [[sources retain] autorelease]; }

- (void)setSources:(BibCollection *)aSources {
    //NSLog(@"in -setSources:, old value of sources: %@, changed to: %@", sources, aSources);
	
    [sources release];
    sources = [aSources copy];
}


- (void)dealloc {
    [publications release];
    [authors release];
    [notes release];
    [sources release];
    [super dealloc];
}

@end
