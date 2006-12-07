//
//  BibPersonController.m
//  BibDesk
//
//  Created by Michael McCracken on Thu Mar 18 2004.
/*
 This software is Copyright (c) 2004,2005
 Michael O. McCracken. All rights reserved.

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:

 - Redistributions of source code must retain the above copyright
   notice, this list of conditions and the following disclaimer.

 - Redistributions in binary form must reproduce the above copyright
    notice, this list of conditions and the following disclaimer in
    the documentation and/or other materials provided with the
    distribution.

 - Neither the name of Michael O. McCracken nor the names of any
    contributors may be used to endorse or promote products derived
    from this software without specific prior written permission.

 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

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
    [pubsTableView setDoubleAction:@selector(openSelectedPub)];
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

- (void)openSelectedPub{
    int row = [pubsTableView selectedRow];
    NSAssert(row >= 0, @"Cannot perform double-click action when no row is selected");
    [document editPub:[publications objectAtIndex:row]];
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
