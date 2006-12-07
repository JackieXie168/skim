//
//  BibItemClassDescription.m
//  BibDesk
//
//  Created by Sven-S. Porst on Sat Jul 10 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "BibItem+Scripting.h"

/* ssp
A Category on BibItem with a few additional methods to enable and enhance its scriptability beyond what comes for free with key value coding.
*/
@implementation BibItem (Scripting)


/* 
 ssp 2004-07-10
 Returns a path to the BibItem for Apple Script
 Needs a properly working -document method to work with multpiple documents.
*/
- (NSScriptObjectSpecifier *) objectSpecifier {
	// NSLog(@"BibItem objectSpecifier");
	NSArray * ar = [[self document] publications];
	unsigned index = [ar indexOfObjectIdenticalTo:self];
    if (index != NSNotFound) {
        NSScriptObjectSpecifier *containerRef = [[self document] objectSpecifier];
        return [[[NSIndexSpecifier allocWithZone:[self zone]] initWithContainerClassDescription:[containerRef keyClassDescription] containerSpecifier:containerRef key:@"publications" index:index] autorelease];
    } else {
        return nil;
    }
}


/* cmh:
 Access to arbitrary fields through 'proxy' objects BibField. 
 These are simply wrappers for the accessors in BibItem. 
*/
- (BibField *)valueInBibFieldsWithName:(NSString *)name
{
	return [[[BibField alloc] initWithName:[name capitalizedString] bibItem:self] autorelease];
}

- (NSArray *)bibFields
{
	NSEnumerator *fEnum = [pubFields keyEnumerator];
	NSString *name = nil;
	BibField *field = nil;
	NSMutableArray *bibFields = [NSMutableArray arrayWithCapacity:5];
	
	while (name = [fEnum nextObject]) {
		field = [[BibField alloc] initWithName:[name capitalizedString] bibItem:self];
		[bibFields addObject:field];
		[field release];
	}
	return bibFields;
}

- (BibAuthor *)valueInAuthorsWithName:(NSString *)name {
    // create a new author so we can use BibAuthor's isEqual: method for comparison
    // instead of trying to do string comparisons
    BibAuthor *newAuth = [BibAuthor authorWithName:name andPub:nil];
	NSEnumerator *authEnum = [[self pubAuthors] objectEnumerator];
	BibAuthor *auth;
	
	while (auth = [authEnum nextObject]) {
		if ([auth isEqual:newAuth]) {
			return auth;
		}
	}
	return nil;
}

/* ssp: 2004-09-21
Extra wrapping of the created and modified date methods to 
- return some value when there is none
- do some NSDate -> NSCalendarDate conversion
*/

- (NSString *)ASType {
	return [self type];
}

- (void)setASType:(NSString *)newType {
	[self setType:(NSString *)newType];
	[[self undoManager] setActionName:NSLocalizedString(@"AppleScript",@"Undo action name for AppleScript")];
}

- (NSString *)ASCiteKey {
	return [self citeKey];
}

- (void)setASCiteKey:(NSString *)newKey {
	[self setCiteKey:(NSString *)newKey];
	[[self undoManager] setActionName:NSLocalizedString(@"AppleScript",@"Undo action name for AppleScript")];
}

- (NSString*)ASTitle {
	return [self valueOfField:BDSKTitleString];
}

- (void)setASTitle:(NSString*)newTitle {
	[self setField:BDSKTitleString toValue:newTitle];
	[[self undoManager] setActionName:NSLocalizedString(@"AppleScript",@"Undo action name for AppleScript")];
}

- (NSString *) month {
	return [self valueOfField:BDSKMonthString];
}

- (void) setMonth:(NSString*) newMonth {
	[self setField:BDSKMonthString toValue:newMonth];
	[[self undoManager] setActionName:NSLocalizedString(@"AppleScript",@"Undo action name for AppleScript")];
}

- (NSString *) year {
	return [self valueOfField:BDSKYearString];
}

- (void) setYear:(NSString*) newYear {
	[self setField:BDSKYearString toValue:newYear];
	[[self undoManager] setActionName:NSLocalizedString(@"AppleScript",@"Undo action name for AppleScript")];
}


- (NSDate*) ASDateCreated {
	NSDate * d = [self dateCreated];
	
	if (!d) return [NSDate dateWithTimeIntervalSince1970:0];
	else return d;
}

- (NSDate*) ASDateModified {
	NSDate * d = [self dateModified];
	
	if (!d) return [NSDate dateWithTimeIntervalSince1970:0];
	else return d;
}





/*
 ssp: 2004-07-11
 Extra key-value-style accessor methods for the local and distant URLs, abstract and notes
 These might be particularly useful for scripting, so having them right in the scripting dictionary rather than hidden in the 'fields' record should be useful.
 I assume the same could be achieved more easily using -valueForUndefinedKey:, but that's X.3 and up 
 I am using generic NSStrings here. NSURLs and NSFileHandles might be nicer but as things are handled as strings both in the BibDesk backend and in AppleScript there wouldn't be much point to it.
 Any policies on whether to rather return copies of the strings in question here?
*/
- (NSString*) remoteURLString {
	return [[self remoteURL] absoluteString];
}

- (void) setRemoteURL:(NSString*) newURL{
	[self setField:BDSKUrlString toValue:newURL];
	[[self undoManager] setActionName:NSLocalizedString(@"AppleScript",@"Undo action name for AppleScript")];
}

- (NSString*) localURL {
	return [self localURLPath];
}

- (void) setLocalURL:(NSString*) newPath {
	if ([newPath hasPrefix:@"file://"])
		[self setField:BDSKLocalUrlString toValue:newPath];
	NSString *newURL = [[NSURL fileURLWithPath:[newPath stringByExpandingTildeInPath]] absoluteString];
	[self setField:BDSKLocalUrlString toValue:newURL];
	[[self undoManager] setActionName:NSLocalizedString(@"AppleScript",@"Undo action name for AppleScript")];
}

- (NSString*) abstract {
	return [self valueOfField:BDSKAbstractString inherit:NO];
}

- (void) setAbstract:(NSString*) newAbstract {
	[self setField:BDSKAbstractString toValue:newAbstract];
	[[self undoManager] setActionName:NSLocalizedString(@"AppleScript",@"Undo action name for AppleScript")];
}

- (NSString*) annotation {
	return [self valueOfField:BDSKAnnoteString inherit:NO];
}

- (void) setAnnotation:(NSString*) newAnnotation {
	[self setField:BDSKAnnoteString toValue:newAnnotation];
	[[self undoManager] setActionName:NSLocalizedString(@"AppleScript",@"Undo action name for AppleScript")];
}

- (NSString*) RSSDescription {
	return [self valueOfField:BDSKRssDescriptionString];
}

- (void) setRSSDescription:(NSString*) newDesc {
	[self setField:BDSKRssDescriptionString toValue:newDesc];
	[[self undoManager] setActionName:NSLocalizedString(@"AppleScript",@"Undo action name for AppleScript")];
}

- (NSString *)keywords{
    return [self valueOfField:BDSKKeywordsString];
}

- (void)setKeywords:(NSString *)keywords{
    [self setField:BDSKKeywordsString toValue:keywords];
	[[self undoManager] setActionName:NSLocalizedString(@"AppleScript",@"Undo action name for AppleScript")];
}

/*
 ssp: 2004-07-11
 Make the bibTeXString settable.
 The only way I could figure out how to initialise a new record with a BibTeX string.
 Mostly stolen from the -paste: method of the document class, i.e. I don't know what I'm doing.
 The error handling is mostly guesswork. No experience with that either.
 This may be a bit of a hack for a few reasons: (a) there seems to be no good way to initialise a BibItem from a BibString when it already exists and (b) I suspect this isn't the way you're supposed to do AS.
*/
- (void) setBibTeXString:(NSString*) btString {
    NSData *data = [btString dataUsingEncoding:NSUTF8StringEncoding];
	NSScriptCommand * cmd = [NSScriptCommand currentCommand];

	// we do not allow setting the bibtex string after an edit, only at initialization
	if([self hasBeenEdited]){
		if (cmd) {
			[cmd setScriptErrorNumber:NSReceiversCantHandleCommandScriptError];
			[cmd setScriptErrorString:[NSString stringWithFormat:NSLocalizedString(@"Cannot set BibTeX string after initialization.",@"Cannot set BibTeX string after initialization.")]];
		}
		return;
	}

	BOOL hadProblems = NO;
    [[BDSKErrorObjectController sharedErrorObjectController] setDocumentForErrors:[self document]];
    NSArray * newPubs = [BibTeXParser itemsFromData:data error:&hadProblems];
	
	// try to do some error handling for AppleScript
	if(hadProblems) {
		if (cmd) {
			[cmd setScriptErrorNumber:NSInternalScriptError];
			[cmd setScriptErrorString:[NSString stringWithFormat:NSLocalizedString(@"BibDesk failed to process the BibTeX entry %@. It may be malformed.",@"BibDesk failed to process the BibTeX entry %@. It may be malformed."), btString]];
		}
		return;
	}
		
	// otherwise use the information of the first publication found in the string.
	BibItem * newPub = [newPubs objectAtIndex:0];
	
	// a parsed pub has no creation date set, so we need to copy first
	NSString *createdDate = [self valueOfField:BDSKDateCreatedString inherit:NO];
	if (![NSString isEmptyString:createdDate])
		[newPub setField:BDSKDateCreatedString toValue:createdDate];
	
	// ... and replace the current record with it.
	// hopefully, I don't understand the whole filetypes/pubtypes stuff	
	[self setType:[newPub type]];
	[self setFileType:[newPub fileType]];
	[self setCiteKey:[newPub citeKey]];
	[self setFields:[newPub pubFields]];
	
	[[self undoManager] setActionName:NSLocalizedString(@"AppleScript",@"Undo action name for AppleScript")];
	// NSLog([newPub description]);
}

/*
 ssp: 2004-07-10
 Return attribute keys corresponding to the fields present in the current BibItem
 DOESNT SEEM TO WORK

- (NSArray *)attributeKeys {
	NSLog(@"BibItem attributeKeys");
	NSMutableArray * ar = [NSMutableArray arrayWithObjects:BibItemBasicObjects, nil];
	NSDictionary * f = [self fields];
	NSEnumerator * keyEnum = [f keyEnumerator];
	NSString * key;
	NSString * value;
	
	while (key = [keyEnum nextObject]) {
		value = [f objectForKey:key];
		if (![value isEqualTo:@""]) {
			[ar addObject:key];
		}
	}
	return ar;
}
*/

/*
 ssp: 2004-07-10
 This catches all the keys that aren't implemented, i.e. those we advertise in -attributeKeys but which actually come from the fields record.
 Not sure about the exception stuff. 
 Apparently this is X.3 and up only.

- (id)valueForUndefinedKey:(NSString *)key {
	NSString * s = (NSString*) [self valueOfField:key];
	if (!s) {
		[NSException raise:NSUndefinedKeyException format:@""];
	}		
	return s;
}
*/

@end
