//
//  BibItemClassDescription.m
//  Bibdesk
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


/*
 ssp: 2004-07-10
 Seems to be a better naming for pubFields as there also is a setFields method.
 In AppleScript this provides an NSDictionary with all the available fields (including those containing empty strings - perhaps some cleaning should be done there). 
 See BD Test.scpt for instructions on how to actually use this record in AppleScript.
 http://earthlingsoft.net/ssp/blog/2004/07/cocoa_and_applescript#812
 gives insight on what's going on there. Perhaps it's worth to implement some other NSSetCommand to make things easier - but I don't know how to do that right now.
*/
- (NSMutableDictionary *)fields{
    return [self pubFields];
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
	NSString *name;
	NSMutableDictionary *bibFields = [[NSMutableDictionary dictionaryWithCapacity:1] retain];
	
	while (name = [fEnum nextObject]) {
		name = [name capitalizedString];
		if (![@"" isEqualToString:[self valueOfField:name]])
			[bibFields setObject:[[[BibField alloc] initWithName:name bibItem:self] autorelease] forKey:name];
	}
	return [bibFields allValues];
}

/* ssp: 2004-09-21
Extra wrapping of the created and modified date methods to 
- return some value when there is none
- do some NSDate -> NSCalendarDate conversion
*/

- (NSString *) month {
	return [self valueOfField:BibItemMonthKey];
}

- (void) setMonth:(NSString*) newMonth {
	[self setField:BibItemMonthKey toValue:newMonth];
}

- (NSString *) year {
	return [self valueOfField:BibItemYearKey];
}

- (void) setYear:(NSString*) newYear {
	[self setField:BibItemYearKey toValue:newYear];
}


- (NSDate*) ASDateCreated {
	NSDate * d = [self dateCreated];
	
	if (!d) return [NSDate dateWithTimeIntervalSince1970:0];
	else return d;
}

- (void) setASDateCreated:(NSDate*) newDate {
	// if ([newDate isKindOfClass:[NSDate class]]) {
		[self setDateCreated:[newDate dateWithCalendarFormat:nil timeZone:nil]];
	// }
	// do nothing if the object passed isn't a date.
}

- (NSDate*) ASDateModified {
	NSDate * d = [self dateModified];
	
	if (!d) return [NSDate dateWithTimeIntervalSince1970:0];
	else return d;
}

- (void) setASDateModified:(NSDate*) newDate {
	[self setDateModified:[newDate dateWithCalendarFormat:nil timeZone:nil]];
}





/*
 ssp: 2004-07-11
 Extra key-value-style accessor methods for the local and distant URLs, abstract and notes
 These might be particularly useful for scripting, so having them right in the scripting dictionary rather than hidden in the 'fields' record should be useful.
 I assume the same could be achieved more easily using -valueForUndefinedKey:, but that's X.3 and up 
 I am using generic NSStrings here. NSURLs and NSFileHandles might be nicer but as things are handled as strings both in the Bibdesk backend and in AppleScript there wouldn't be much point to it.
 Any policies on whether to rather return copies of the strings in question here?
*/
- (NSString*) remoteURL {
	return [self valueOfField:BibItemRemoteURLKey];
}

- (void) setRemoteURL:(NSString*) newURL{
	[self setField:BibItemRemoteURLKey toValue:newURL];
}

- (NSString*) localURL {
	return [self valueOfField:BibItemLocalURLKey];
}

- (void) setLocalURL:(NSString*) newURL {
	[self setField:BibItemLocalURLKey toValue:newURL];
}

- (NSString*) abstract {
	return [self valueOfField:BibItemAbstractKey];
}

- (void) setAbstract:(NSString*) newAbstract {
	[self setField:BibItemAbstractKey toValue:newAbstract];
}

- (NSString*) annotation {
	return [self valueOfField:BibItemAnnotationKey];
}

- (void) setAnnotation:(NSString*) newAnnotation {
	[self setField:BibItemAnnotationKey toValue:newAnnotation];
}

- (NSString*) RSSDescription {
	return [self valueOfField:BibItemRSSDescriptionKey];
}

- (void) setRSSDescription:(NSString*) newDesc {
	[self setField:BibItemRSSDescriptionKey toValue:newDesc];
}

- (NSString *)keywords{
    return [self valueOfField:BibItemKeywordsKey];
}

- (void)setKeywords:(NSString *)keywords{
    [self setField:BibItemKeywordsKey toValue:keywords];
}

/*
 ssp: 2004-07-11
 THIS IS VERY BROKEN
 (a) It doesn't do the right thing - probably it should return the RTF we get when choosing Copy as RTF. But that is generated at BibDocument level. A method to give this at BibItem level would be nice. (Modifying everything to not have the 'references' heading would be good as well. That way people could automatically build Bibliographies in TextEdit (or even Word ...)
 (b) It doesn't do things very well: We convert NSData to NSTextStorage, wher the NSData is generated from NSAttributedString. 
 (c) Somehow the style information doesn't make it all the way to AppleScript, i.e. I can't paste it into TextEdit, say. This is despite the logs suggesting that the information is passed to AS. Sketch.app seems to have the same problem, so something may be wrong to the appraoch. Q: Which application can handle passing styled text around via AppleScript properly?
*/
- (NSTextStorage*) attributedString {
	NSTextStorage * myString = nil;
	NSData * RTFData = [self RTFValue];
	if (RTFData) {
		NSDictionary * myDict;
		myString = [[[NSTextStorage alloc] initWithRTF:RTFData documentAttributes:&myDict] autorelease];
	}
	return myString;
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
	// "Texify" - whatever that is
    NSString *texstr = [[BDSKConverter sharedConverter] stringByTeXifyingString:btString];
    NSData *data = [texstr dataUsingEncoding:NSUTF8StringEncoding];
	NSScriptCommand * cmd = [NSScriptCommand currentCommand];

	NSEnumerator *fnEnum = [pubFields keyEnumerator];
	NSString *fn;
	while (fn = [fnEnum nextObject]) {
		if (!([[self valueOfField:fn] isEqualToString:@""] || [fn isEqualToString:@"Date-Modified"] || [fn isEqualToString:@"Date-Added"])) {
			if (cmd) {
				[cmd setScriptErrorNumber:NSReceiversCantHandleCommandScriptError];
				[cmd setScriptErrorString:[NSString stringWithFormat:NSLocalizedString(@"Cannot set BibTeX string after initialization.",@"Cannot set BibTeX string after initialization.")]];
			}
			return;
		}
	}

	BOOL hadProblems = NO;
    NSArray * newPubs = [BibTeXParser itemsFromData:data error:&hadProblems];
	
	// try to do some error handling for AppleScript
	if(hadProblems) {
		if (cmd) {
			[cmd setScriptErrorNumber:NSInternalScriptError];
			[cmd setScriptErrorString:[NSString stringWithFormat:NSLocalizedString(@"Bibdesk failed to process the BibTeX entry %@. It may be malformed.",@"Bibdesk failed to process the BibTeX entry %@. It may be malformed."), btString]];
		}
		return;
	}
		
	// otherwise use the information of the first publication found in the string.
	BibItem * newPub = [newPubs objectAtIndex:0];
	
	// ... and replace the current record with it.
	// hopefully, I don't understand the whole filetypes/pubtypes stuff	
	[self setFileType:[newPub fileType]];
	[self setCiteKey:[newPub citeKey]];
	[self setFields:[newPub fields]];
	[self setRequiredFieldNames: [newPub requiredFieldNames]];
	[self makeType:[newPub type]];
	NSLog([newPub description]);
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
