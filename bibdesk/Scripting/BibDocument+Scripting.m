//
//  BibDocument+Scripting.m
//  BibDesk
//
//  Created by Sven-S. Porst on Thu Jul 08 2004.
/*
 This software is Copyright (c) 2004,2005,2006,2007
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
#import "BDSKItemPasteboardHelper.h"
#import "BDSKOwnerProtocol.h"
#import "BDSKPublicationsArray.h"
#import "NSObject_BDSKExtensions.h"
#import "NSArray_BDSKExtensions.h"

@implementation BibDocument (Scripting)

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
	NSMutableSet *auths = [NSMutableSet set];
	
    [auths performSelector:@selector(addObjectsFromArray:) withObjectsByMakingObjectsFromArray:publications performSelector:@selector(pubAuthors)];
	
	if (index < [auths count]) 
		return [[auths allObjects] objectAtIndex:index];
	return nil;
}

- (NSArray*) displayedPublications {
	return shownPublications;
}

- (NSArray*) selection { 
    NSMutableArray *selection = [NSMutableArray arrayWithCapacity:[self numberOfSelectedPubs]];
    NSEnumerator *pubE = [[self selectedPublications] objectEnumerator];
    BibItem *pub;
    
    // only items belonging to the document can be accessed through AppleScript
    // items from external groups have no scriptable container, and AppleScript accesses properties of the document
    while ((pub = [pubE nextObject]) && ([[pub owner] isEqual:self])) 
        [selection addObject:pub];
    return selection;
}

- (void) setSelection: (NSArray *) newSelection {
	// debugging revealed that we get an array of NSIndexSpecifiers and not of BibItem
    // the index is relative to all the publications the document (AS container), not the shownPublications
	NSArray *pubsToSelect = [publications objectsAtIndexSpecifiers:newSelection];
	[self selectPublications:pubsToSelect];
}

- (NSTextStorage*) textStorageForPublications:(NSArray *)pubs {
    NSPasteboard *pboard = [NSPasteboard pasteboardWithUniqueName];
    [pboardHelper declareType:NSRTFPboardType dragCopyType:BDSKRTFDragCopyType forItems:pubs forPasteboard:pboard];
    NSData *data = [pboard dataForType:NSRTFPboardType];
    [pboardHelper clearPromisedTypesForPasteboard:pboard];
    
    if(data == nil) return [[[NSTextStorage alloc] init] autorelease];
    	
	return [[[NSTextStorage alloc] initWithRTF:data documentAttributes:NULL] autorelease];
}

@end
