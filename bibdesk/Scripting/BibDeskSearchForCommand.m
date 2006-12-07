//
//  BibDeskSearchForCommand.m
//  Bibdesk
//
//  Created by Sven-S. Porst on Wed Jul 21 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//
/* ssp: 2004-07-21
This file provides support for the search command.
It sets up the AppleScript command and implements categories on some other classes with the functionality needed to implement that commad.
*/


#import "BibDeskSearchForCommand.h"




/* ssp: 2004-07-20
To be used for finding bibliography information from a keyword with AppleScript.
The command should have the form
	search (document|application) for (searchterm) [for autocompletion (yes|no)]

A further improvement could extend this work on lists as well. But would anybody use that? Certainly not for completion.
*/
@implementation BibDeskSearchForCommand

- (id)performDefaultImplementation {
	// NSLog(@"******** BibDeskSearchForCommand **********");

	// figure out parameters first
	NSDictionary * params = [self evaluatedArguments];
	if (!params) {
		[self setScriptErrorNumber:NSRequiredArgumentsMissingScriptError]; 
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
		return nil;
	}
	
	// the 'forCompletion' parameter can modify what we return
	BOOL forCompletion = NO;
	id fC = [params objectForKey:@"forCompletion"];
	if (fC) {
		// the parameter is present
		if (![fC isKindOfClass:[NSNumber class]]) {
			// wrong kind of argument
			[self setScriptErrorNumber:NSArgumentsWrongScriptError];
			[self setScriptErrorString:NSLocalizedString(@"The 'for completion' option needs to be specified as yes or no. E.g.: search for search_term for completion yes",@"The 'for completion' option needs to be specified as yes or no. E.g.: search for search_term for completion yes")];
			return nil;
		}
		
		forCompletion = [(NSNumber*)fC boolValue];
	}
	
	
	// now let's get some results
	
	NSMutableArray * results = [NSMutableArray array];
	id receiver = [self evaluatedReceivers];
    NSScriptObjectSpecifier * dP = [self directParameter];
	id dPO = [dP objectsByEvaluatingSpecifier];

	if ([receiver isKindOfClass:[NSApplication class]] && dP == nil) {
		// we are sent to the application and there is no direct paramter that might redirect the command
		NSEnumerator * myEnum = [[NSApp orderedDocuments] objectEnumerator];
		BibDocument * bd = nil;
		while (bd = [myEnum nextObject]) {
			[results addObjectsFromArray:[bd findMatchesFor:searchterm]];
		}
	}
	else if ([receiver isKindOfClass:[BibDocument class]] || [dPO isKindOfClass:[BibDocument class]]) {
		// the condition above might not be good enough
		// we are sent or addressed to a document
		[results addObjectsFromArray:[(BibDocument*)dPO findMatchesFor:searchterm]];
	}
	else {
		// give up
		[self setScriptErrorNumber:NSReceiversCantHandleCommandScriptError];
		[self setScriptErrorString:NSLocalizedString(@"The search command can only be sent to the application itself or to documents. Usually it is used in the form \"search for search_term\".", @"The search command can only be sent to the application itself or to documents. Usually it is used in the form \"search for search_term\".")];
		return nil;
	}

	
	if (forCompletion) {
		/* we're doing this for completion, so return a different array. Instead of an array of publications (BibItems) this will simply be an array of strings containing the cite key, the authors' surnames and the title for the publication. This could be sufficient for completion and allows the application possibly integrating with Bibdesk to remain ignorant of the inner workings of BibItems.
		*/
		int i = 0;
		int n = [results count];
		BibItem * result;
		id  resultObject;
		while (i < n) {
			result = [results objectAtIndex:i];
			resultObject = [result objectForCompletion];
			[results replaceObjectAtIndex:i withObject:resultObject];
			i++;
		}
		// sort alphabetically
		[results sortUsingSelector:@selector(caseInsensitiveCompare:)];
	}
	
	
	return results;
}

@end







/* ssp: 2004-07-21
Category on BibDocument to aid finding
*/
@implementation BibDocument (Finding)


/* ssp: 2004-07-21
This method returns an array of BibItems matching a given searchterm
Currently we match a publication if the searchterm is completely found in either the cite key, any author's surname or the publication's title.
This could be made more flexible (but who'd want more preferences?)
There could be other extensions, like matching for every word with conjunction or disjunction. Again that would make things less obvious (and wouldn't be useful for supporting completion, which I have in mind when writing this)
*/
- (NSArray*) findMatchesFor:(NSString*) searchterm {
	NSMutableArray * found = [NSMutableArray array];
	
	// run through all publications
	NSEnumerator * pubEnum = [publications objectEnumerator];
	BibItem * pub = nil;
	
	while (pub = [pubEnum nextObject]) {
		if ([pub matchesString:searchterm]) {
			// we've got a match, so add
			[found addObject:pub];
		}
	}

	return found;
}

@end



/* ssp: 2004-07-21
Lets a BibItem decide when it is matched by a given string
*/
@implementation BibItem (Finding)

/* ssp: 2004-07-21
Take a searchterm and determine whether or not we are matched by it. Return the result.
We are a bit rough here, so simply concatenate all the relevant strings and search only once. If this is to be refined all three searches could be done after one another. That way people could choose not to search the title, say. Or matching BibItems could be ordered giving priority to those whose citeKey matches. But I suspect this simplistic approach is good enough.
*/
- (BOOL) matchesString:(NSString*) searchterm {
	NSEnumerator * authEnum = [pubAuthors objectEnumerator];
	BibAuthor * auth = nil;
	NSMutableString * authorlastnames = [NSMutableString string];	

	// compile author surname string
	while (auth = [authEnum nextObject]) {
		[authorlastnames appendFormat:@"%@ ", [auth lastName]];
	}
	
	// compile concatenated string
	NSString * s = [citeKey stringByAppendingFormat:@" %@ %@ %@", authorlastnames,  [self title], [self keywords]];
	
	// look for searchterm
	return([s rangeOfString:searchterm options:NSCaseInsensitiveSearch].location != NSNotFound);
}



/* ssp: 2004-07-21 
Returns a string with information that should be useful and sufficient for completion.
The string is of the form citeKey % author1surname-author2surname, title.
*/
- (id) objectForCompletion {
	// concatenate author surnames first
	NSEnumerator * authEnum = [pubAuthors objectEnumerator];
	BibAuthor * auth = nil;
	NSMutableString * surnames = [NSMutableString string];
	auth = [authEnum nextObject];
	if (auth) {
		[surnames appendString:[auth lastName]];	
		while (auth = [authEnum nextObject]) {
			[surnames appendFormat:@"-%@", [auth lastName]];
		}
	}
	
	return [[self citeKey] stringByAppendingFormat: @" %% %@, %@", surnames, [self title]];
	// return [NSDictionary dictionaryWithObjectsAndKeys:[self citeKey], @"citeKey", surnames, @"surnames", [self title], @"title",nil];	
}
@end