//
//  BibDocument+Scripting.m
//  BibDesk
//
//  Created by Sven-S. Porst on Thu Jul 08 2004.
/*
 This software is Copyright (c) 2004,2005,2006
 Sven-S. Porst. All rights reserved.
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:
 
 - Redistributions of source code must retain the above copyright
 notice, this list of conditions and the following disclaimer.
 
 - Redistributions in binary form must reproduce the above copyright
 notice, this list of conditions and the following disclaimer in
 the documentation and/or other materials provided with the
 distribution.
 
 - Neither the name of Sven-S. Porst nor the names of any
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
#import "BibDocument+Scripting.h"
#import "BibAuthor.h"
#import "BibItem.h"
#import "BDSKTeXTask.h"
#import "BDSKGroup.h"
#import "BDSKSharedGroup.h"

/* ssp
Category on BibDocument to implement a few additional functions needed for scripting
*/
@implementation BibDocument (Scripting)

/* cmh: 2004-1-28
Scripting Key-Value coding methods to access publications
*/
- (BibItem *)valueInPublicationsAtIndex:(unsigned int)index {
    return [publications objectAtIndex:index];
}

- (void)insertInPublications:(BibItem *)pub  atIndex:(unsigned int)index {
	[self insertPublication:pub atIndex:index];
	[[self undoManager] setActionName:NSLocalizedString(@"AppleScript",@"Undo action name for AppleScript")];
}

- (void)insertInPublications:(BibItem *)pub {
	[self addPublication:pub];
	[[self undoManager] setActionName:NSLocalizedString(@"AppleScript",@"Undo action name for AppleScript")];
}

- (void)removeFromPublicationsAtIndex:(unsigned int)index {
	[self removePublicationsAtIndexes:[NSIndexSet indexSetWithIndex:index]];
	[[self undoManager] setActionName:NSLocalizedString(@"AppleScript",@"Undo action name for AppleScript")];
}


/* ssp: 2004-08-03
Scripting Key-Value coding method to access an author by his name
*/
- (BibAuthor*) valueInAuthorsWithName:(NSString*) name {
    // create a new author so we can use BibAuthor's isEqual: method for comparison
    // instead of trying to do string comparisons
    BibAuthor *newAuth = [BibAuthor authorWithName:name andPub:nil];
    
	NSEnumerator *pubEnum = [publications objectEnumerator];
	NSEnumerator *authEnum;
	BibItem *pub;
	BibAuthor *auth;

	while (pub = [pubEnum nextObject]) {
		authEnum = [[pub pubAuthors] objectEnumerator];
		while (auth = [authEnum nextObject]) {
			if ([auth isEqual:newAuth]) {
				return auth;
			}
		}
	}
	return nil;
}

- (BibAuthor*) valueInAuthorsAtIndex:(unsigned int)index {
	NSEnumerator *pubEnum = [publications objectEnumerator];
	BibItem *pub;
	NSMutableSet *auths = [NSMutableSet set];
	
	while (pub = [pubEnum nextObject]) {
		[auths addObjectsFromArray:[pub pubAuthors]];
	}
	
	if (index < [auths count]) 
		return [[auths allObjects] objectAtIndex:index];
	return nil;
}



/* ssp: 2004-07-22
Getting the displayed publications.
*/
- (NSArray*) displayedPublications {
	return shownPublications;
}




/* ssp: 2004-07-11
Getting and setting the selection of the table
*/
- (NSArray*) selection { 
    NSMutableArray *selection = [NSMutableArray arrayWithCapacity:[self numberOfSelectedPubs]];
    NSEnumerator *pubE = [[self selectedPublications] objectEnumerator];
    BibItem *pub;
    
    while (pub = [pubE nextObject]) 
        if ([pub document] != nil) [selection addObject:pub];
    return selection;
}


- (void) setSelection: (NSArray *) newSelection {
	//NSLog(@"setSelection:");
	NSEnumerator *itemEnum = [newSelection objectEnumerator];
	// debugging revealed that we get an array of NSIndexspecifiers and not of BibItem
	NSIndexSpecifier *item;
	NSMutableArray *pubsToSelect = [NSMutableArray arrayWithCapacity:[newSelection count]];
	
	while (item = [itemEnum nextObject])
		[pubsToSelect addObject:[publications objectAtIndex:[item index]]];
	[self highlightBibs:pubsToSelect];
}


- (NSTextStorage*) textStorageForBibString:(NSString*) bibString {
    NSData *data = nil;
    if([texTask runWithBibTeXString:bibString] && [texTask hasRTFData])
        data = [texTask RTFData];
    
    if(!data) return [[[NSTextStorage alloc] init] autorelease];
    	
	return [[[NSTextStorage alloc] initWithRTF:data documentAttributes:NULL] autorelease];
}

@end
