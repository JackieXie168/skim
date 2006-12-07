//
//  BibPersonController.m
//  Bibdesk
//
//  Created by Michael McCracken on Thu Mar 18 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "BibPersonController.h"


@implementation BibPersonController

#pragma mark initialization


- (NSString *)windowNibName{return @"BibPersonView";}

- (id)initWithPerson:(BibAuthor *)aPerson document:(BibDocument *)doc{
   //  NSLog(@"personcontroller init");
    self = [super initWithWindowNibName:@"BibPersonView"];
	if(self){
            [self setPerson:aPerson];
            publications = [[doc publicationsForAuthor:aPerson] copy];
            
            [person setPersonController:self];
            
			document = doc;
			
            [[self window] setTitle:[[self person] name]];
            [[self window] setDelegate:self];
	}
	return self;

}

- (void)dealloc{
#if DEBUG
    NSLog(@"personcontroller dealloc");
#endif
    [pubsTableView setDelegate:nil];
    [pubsTableView setDataSource:nil];
    [person setPersonController:nil];
    [person release];
    [publications release];
    [super dealloc];
}

- (void)awakeFromNib{
	if ([[self superclass] instancesRespondToSelector:@selector(awakeFromNib)]){
        [super awakeFromNib];
	}
	
	[[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handlePubListChanged:)
                                                     name:BDSKAuthorPubListChangedNotification
						object:nil]; 
	[self updateUI];
}

#pragma mark accessors

- (BibAuthor *)person {
    return person;
}

- (void)setPerson:(BibAuthor *)newPerson {
	person = [newPerson retain];
}

#pragma mark actions

- (void)show{
    [self showWindow:self];
}

- (void)updateUI{
	[nameTextField setStringValue:[person name]];
	[pubsTableView reloadData];
	// TODO: get picture from AB
}

- (void)handlePubListChanged:(NSNotification *)notification{
	[self updateUI]; 
}

- (void)windowWillClose:(NSNotification *)notification{
	[document removeWindowController:self];
}

#pragma mark  table view datasource methods
- (int)numberOfRowsInTableView:(NSTableView *)tableView{
	return [publications count]; 
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn 
			row:(int)row{
	NSString *tcid = [tableColumn identifier];
	BibItem *pub = [publications objectAtIndex:row];

	return [pub valueOfField:tcid];
}

@end
