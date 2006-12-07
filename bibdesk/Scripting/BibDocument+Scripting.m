//
//  BibDocument+Scripting.m
//  BibDesk
//
//  Created by Sven-S. Porst on Thu Jul 08 2004.
/*
 This software is Copyright (c) 2004,2005
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
	[self removePublication:[publications objectAtIndex:index]];
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
	NSEnumerator *authEnum;
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
	// enumerator of row numbers	
	NSEnumerator * myEnum = [self selectedPubEnumerator];
	NSMutableArray * myPubs = [NSMutableArray arrayWithCapacity:10];
	
	NSNumber * row;
	BibItem * aPub;
	
	while (row = [myEnum nextObject]) {
		aPub = [shownPublications objectAtIndex:[row intValue]];
		[myPubs addObject:aPub];
	}
	
	return myPubs;
}


- (void) setSelection: (NSArray*) newSelection {
	//NSLog(@"setSelection:");
	NSEnumerator * myEnum = [newSelection objectEnumerator];
	// debugging revealed that we get an array of NSIndexspecifiers and not of BibItem
	NSIndexSpecifier * aPub;
	
	// first deselect all pubs
	[tableView deselectAll:nil];
	
	while (aPub = [myEnum nextObject]){
		
		[self highlightBib:[publications objectAtIndex:[aPub index]] byExtendingSelection:YES];
	}	
}


- (NSTextStorage*) textStorageForBibString:(NSString*) bibString {
    NSData *data = nil;
    if([texTask runWithBibTeXString:bibString] && [texTask hasRTFData])
        data = [texTask RTFData];
    
    if(!data) return nil;
    	
	return [[[NSTextStorage alloc] initWithRTF:data documentAttributes:NULL] autorelease];
}

@end



/* 
ssp: 2004-07-11
 NSScriptCommand for the "bibliography for" command.
 This is sent to the BibDocument.
*/
@implementation BibDeskBibliographyCommand


/*
 ssp: 2004-07-11
 Takes an array of items as given by AppleScript in the formt of NSIndexSpecifiers, runs the items through BibTeX and RTF conversion and returns an attributed string.
 BDSKPreviewer being able to return NSAttributedStrings instead of NSData for RTF might save a few conversions. For the time being I implemented a little function in BibDocument+Scripting. This could be merged into Bibdocument.
 As the BibItem's 'text' attribute, somehow the styling is lost somewhere in the process. Hints?!
*/
- (id) performDefaultImplementation {
    id param = [self directParameter];
	
	//	This should be an NSArray of NSIndexSpecifiers. Perhaps do some error checking
	if (![param isKindOfClass:[NSArray class]]) return nil;
	
	// Determine the document responsible for this
	NSIndexSpecifier * index = [param objectAtIndex:0];
	NSScriptObjectSpecifier * parent = [index containerSpecifier];
	BibDocument * myBib = [parent objectsByEvaluatingSpecifier];
	NSLog([myBib description]);
	if (!myBib) return nil;
	
	// run through the array
	NSEnumerator *e = [(NSArray*)param objectEnumerator];
	NSArray * thePubs = [myBib publications];
    NSIndexSpecifier *i;
	int  n ;
	NSMutableString *bibString = [NSMutableString string];
	
	while (i = [e nextObject]) {
		n = [i index];
		[bibString appendString:[[thePubs objectAtIndex:n] bibTeXString]];
	}
	
	// make RTF and return it.
	NSTextStorage * ts = [myBib textStorageForBibString:bibString];
	
	return ts;
}


@end



/*
ssp: 2004-07-22
This command has been dropped in favour of simply having 'filter field' as a property of the document class.
 
 
 ssp: 2004-04-03
 NSScriptCommand for the "find" command.


@implementation BibDeskFilterScriptCommand

ssp: 2004-04-03 first version
ssp: 2004-07-21 improved version that will set all filter fields if sent to the application and, if sent to a document, just the filter field of that document. Also makes proper use of direct parameter and parameters now.

- (id)performDefaultImplementation {
	// NSLog(@"******** BibDeskFilterForCommand **********");
	
	// figure out parameters first
	NSDictionary * params = [self evaluatedArguments];
	if (!params) {
		[self setScriptErrorNumber:NSRequiredArgumentsMissingScriptError]; 
		// [self setScriptErrorString:NSLocalizedString(@"Please specify the string you want to search for. E.g.: \"search for search_term\".", @"Please specify the string you want to search for. E.g.: \"search for search_term\".", )];
		// I don't think everybody would ever see the message about. ScriptEditor/AppleScript seem to catch those errors earlier on, seeing that the command is malformed and simply give a NSCannotCreateScriptCommand error message. Those are the error messages that sometimes make AppleScript nearly unusuable. But it seems we can't do any better :(
		return nil;
	}
	
	// the 'for' parameters gives the term to search for
	NSString * searchterm = [params objectForKey:@"for"];
	// make sure we get something
	if (!searchterm) {
		[self setScriptErrorNumber:NSRequiredArgumentsMissingScriptError]; 
		return nil;
	}
	// make sure we get the right thing
	if (![searchterm isKindOfClass:[NSString class]] ) {
		[self setScriptErrorNumber:NSArgumentsWrongScriptError]; 
		[self setScriptErrorString:NSLocalizedString(@"Please pass a string as a search term.", Please pass a string as a search term.)];
		return nil;
	}
		
	
	// now let's do the work
	id receiver = [self evaluatedReceivers];
	// the receiver could be the application object or a document object
	//	While [self description] will give 	"Receivers: (null)" in case we are dealing with the application object, this is wrong information and in fact receiver won't be nil in that case.

	if ([receiver isKindOfClass:[NSApplication class]] ) {
		// it's the application, so run through all the open documents
		NSEnumerator * myEnum = [[NSApp orderedDocuments] objectEnumerator];
		BibDocument * bd = nil;
		while (bd = [myEnum nextObject]) {
			[bd setFilterField:searchterm];
		}
	}
	else if ([receiver isKindOfClass:[BibDocument class]]) {
		// it's a document, just set the filter here
		[(BibDocument*)receiver setFilterField:searchterm];
	}
	else {
		// we were sent to something other than a document or the application
		[self setScriptErrorNumber:NSReceiversCantHandleCommandScriptError];
		[self setScriptErrorString:NSLocalizedString(@"The search command can only be sent to the application itself or to documents. Usually it is used in the form \"search for search_term\".", @"The search command can only be sent to the application itself or to documents. Usually it is used in the form \"search for search_term\".")];
		return nil;
	}
	
    return nil;
}
@end
*/
