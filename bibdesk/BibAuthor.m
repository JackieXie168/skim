//  BibAuthor.m

//  Created by Michael McCracken on Wed Dec 19 2001.
/*
This software is Copyright (c) 2002, Michael O. McCracken
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

- Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
-  Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
-  Neither the name of Michael O. McCracken nor the names of any contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#import "BibAuthor.h"
#import "BibItem.h"

#define emptyStr(x) ([x isEqualToString:@""] || !(x))

static NSMutableArray *_authors;

@implementation BibAuthor

+ (void)initialize{
	static BOOL alreadyInit= NO;
    if ( !alreadyInit ) {
		_authors = [[NSMutableArray alloc] initWithCapacity:10];
		
        alreadyInit = YES;
    }
}

+ (BibAuthor *)authorWithName:(NSString *)newName andPub:(BibItem *)aPub{
	BibAuthor *auth = nil;
	BibAuthor *newAuth = [[[BibAuthor alloc] initWithName:newName andPub:aPub] autorelease];
	
	NSEnumerator *e = [_authors objectEnumerator];
	
	while(auth = [e nextObject]){
		if([auth compare:newAuth] == NSOrderedSame){
			[auth addPub:aPub];
			[[NSNotificationCenter defaultCenter] postNotificationName:BDSKAuthorPubListChangedNotification
																object:auth];
			return auth;
		}
	}
	// no match was found, create a new author:
	
	[_authors addObject:newAuth];
	return newAuth;
}

- (id)initWithName:(NSString *)aName andPub:(BibItem *)aPub{
    [self setName:aName];
    if(aPub)
        pubs = [[NSMutableArray arrayWithObject:aPub] retain];
    else
        pubs = [[NSMutableArray alloc] init];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(handleBibItemChangeNotification:)
												 name:BDSKBibItemChangedNotification
											   object:nil];
	
    return self;
}

- (void)dealloc{
    [name release];
    [pubs release];
	[_firstName release];
	[_vonPart release];
	[_lastName release];
	[_jrPart release];
	[_normalizedName release];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
    // NSLog(@"bibauthor dealloc");
    [super dealloc];
}

- (id)copyWithZone:(NSZone *)zone{
    BibAuthor *copy = [[[self class] allocWithZone: zone] initWithName:[self name]
                                                                andPub:nil];
    [copy setPubs:pubs];
    return copy;
}

- (BOOL)isEqual:(BibAuthor *)otherAuth{
    return [name isEqualToString:[otherAuth name]];
}

- (unsigned)hash{
    return [name hash];
}


- (void)setPubs:(NSArray *)newPubs{
    [pubs autorelease];
    pubs = [newPubs mutableCopy];
}

- (int)numberOfPublications{
    return [pubs count];
}

- (NSArray *)publications{
    return pubs;
}

#pragma mark Comparison

- (NSComparisonResult)compare:(BibAuthor *)otherAuth{
	return [[self normalizedName] compare:[otherAuth normalizedName] options:NSCaseInsensitiveSearch];
}

// fuzzy tries to match despite common omissions.
// currently not all that fuzzy - can't handle spelling errors.
- (NSComparisonResult)fuzzyCompare:(BibAuthor *)otherAuth{
	// if there's a vonPart, append it to 'last'.
	// omitting a von is like misspelling the last name, not like omitting a first name.
	
	NSString *lastStrMe = [NSString stringWithFormat:@"%@%@", _vonPart,_lastName];
	NSString *lastStrOther = [NSString stringWithFormat:@"%@%@", [otherAuth vonPart], [otherAuth lastName]];
	
	// if we both have a first name, compare first lastStr == first lastStr
	if(!emptyStr(_firstName) && !emptyStr([otherAuth firstName])){
		return [ [NSString stringWithFormat:@"%@%@", _firstName, lastStrMe] compare:
	[NSString stringWithFormat:@"%@%@",[otherAuth firstName], lastStrOther] options:NSCaseInsensitiveSearch];
		
	}else{
		// don't both have a first name, so only compare lastStrs, even if one of us has a first.
		return [lastStrMe compare:lastStrOther options:NSCaseInsensitiveSearch];
	}

}


#pragma mark String Representations

- (NSString *)description{
    return [NSString stringWithFormat:@"[%@_%@_%@_%@]", _firstName,_vonPart,_lastName,_jrPart];
}


#pragma mark Component Accessors

// This follows the recommendations from Oren Patashnik's btxdoc.tex:
/*To summarize, BibTEX allows three possible forms for the name: 
"First von Last" 
"von Last, First" 
"von Last, Jr, First" 
You may almost always use the first form; you shouldn’t if either there’s a Jr part, or the Last part has multiple tokens but there’s no von part. 
*/
// Note that if there is only one word/token, it is the _lastName, so that's assumed to always be there.

- (NSString *)normalizedName{
	return _normalizedName;
}

- (void)refreshNormalizedName{
	[_normalizedName release];
	
	BOOL FIRST = !emptyStr(_firstName);
	BOOL VON = !emptyStr(_vonPart);
	BOOL LAST = !emptyStr(_lastName);
	BOOL JR = !emptyStr(_jrPart);
	
	if(JR){
		_normalizedName = [[NSString stringWithFormat:@"%@%@%@%@%@%@%@", (VON ? _vonPart : @""),
			(VON ? @" " : @""),
			(LAST ? _lastName : @""),
			(JR ? @", " : @""),
			(JR ? _jrPart : @""),
			(FIRST ? @", " : @""),
			(FIRST ? _firstName : @"")] retain];
		
	}
	
	_normalizedName = [[NSString stringWithFormat:@"%@%@%@%@%@", (VON ? _vonPart: @""), (VON ? @" " : @""),
		_lastName, 
		(FIRST ? @", " : @""), 
		(FIRST ? _firstName : @"")] retain];
/*
else if(([_lastName rangeOfString:@" "].location != NSNotFound) && VON){
	return [NSString stringWithFormat:@"%@%@%@%@%@",(FIRST ? _firstName : @""),
		(FIRST ? @" " : @""), 
		(VON ? _vonPart : @""),
		(VON ? @" " : @""), _lastName];
*/	
}

- (NSString *)name{
    return name;
}

- (NSString *)firstName{
    return _firstName;
}

- (NSString *)vonPart{
    return _vonPart;
}

- (NSString *)lastName{
    return _lastName;
}

- (NSString *)jrPart{
    return _jrPart;
}


/*
Sets all the different variables for partial names and so on from a given string. 
 
Note: The strings returned by the bt_split_name function seem to be in the wrong encoding – UTF-8 is treated as ASCII. This is manually fixed for the _firstName, _lastName,  _jrPart and _vonPart variables.
*/
- (void)setName:(NSString *)newName{
	NSStringEncoding defaultCStringEncoding = [NSString defaultCStringEncoding];
    bt_name *theName;
    int i = 0;
    NSMutableString *tmpStr = nil;
    
	if(newName == name){
		return;
	}
	[name release];
	name = [newName copy];

	theName = bt_split_name((char *)[name UTF8String],(char *)[name UTF8String],0,0);
    
    // get tokens from first part
    tmpStr = [NSMutableString string];
    for (i = 0; i < theName->part_len[BTN_FIRST]; i++)
    {
        [tmpStr appendString:[NSString stringWithCString:theName->parts[BTN_FIRST][i]]];
        if(i >= 0 && i < theName->part_len[BTN_FIRST]-1)
            [tmpStr appendString:@" "];
    }
    _firstName = [[NSString alloc] initWithData:[tmpStr dataUsingEncoding:defaultCStringEncoding allowLossyConversion:YES]  encoding:NSUTF8StringEncoding]; 
		    
    // get tokens from von part
    tmpStr = [NSMutableString string];
    for (i = 0; i < theName->part_len[BTN_VON]; i++)
    {
        [tmpStr appendString:[NSString stringWithCString:theName->parts[BTN_VON][i]]];
        if(i >= 0 && i < theName->part_len[BTN_VON]-1)
            [tmpStr appendString:@" "];

    }
    _vonPart = [[NSString alloc] initWithData:[tmpStr dataUsingEncoding:defaultCStringEncoding allowLossyConversion:YES]  encoding:NSUTF8StringEncoding]; 
	
	// get tokens from last part
    tmpStr = [NSMutableString string];
    for (i = 0; i < theName->part_len[BTN_LAST]; i++)
    {
        [tmpStr appendString:[NSString stringWithCString:theName->parts[BTN_LAST][i]]];
        if(i >= 0 && i < theName->part_len[BTN_LAST]-1)
            [tmpStr appendString:@" "];
    }
    _lastName = [[NSString alloc] initWithData:[tmpStr dataUsingEncoding:defaultCStringEncoding allowLossyConversion:YES]  encoding:NSUTF8StringEncoding]; 
	
    
    // get tokens from jr part
    tmpStr = [NSMutableString string];    
    for (i = 0; i < theName->part_len[BTN_JR]; i++)
    {
        [tmpStr appendString:[NSString stringWithCString:theName->parts[BTN_JR][i]]];
        if(i >= 0 && i < theName->part_len[BTN_JR]-1)
            [tmpStr appendString:@" "];
    }
    _jrPart = [[NSString alloc] initWithData:[tmpStr dataUsingEncoding:defaultCStringEncoding allowLossyConversion:YES]  encoding:NSUTF8StringEncoding]; 
	
	[self refreshNormalizedName];
	
	bt_free_name(theName);
}

// Accessors for personController - we don't retain it to avoid cycles.
- (BibPersonController *)personController{
    return _personController; 
}

- (void)setPersonController:(BibPersonController *)newPersonController{
	_personController = newPersonController;
}

- (void)handleBibItemChangeNotification:(NSNotification *)notification{
	BibItem *pub = [notification object];

	// if a pub changes and it's in our pubs list, we have to check that we're still an author.
	if([pubs containsObjectIdenticalTo:pub] &&
	   ![[pub pubAuthors] containsObjectIdenticalTo:self]){
		[self removePubFromAuthorList:pub];
	}
	
}




- (BibItem *)pubAtIndex:(int)index{
    return [pubs objectAtIndex: index];
}
- (void)addPub:(BibItem *)pub{
    if(![pubs containsObject:pub]){
        [pubs addObject: pub];
    }
}
- (void)removePubFromAuthorList:(BibItem *)pub{
    [pubs removeObjectIdenticalTo:pub];
	[[NSNotificationCenter defaultCenter] postNotificationName:BDSKAuthorPubListChangedNotification
														object:self];
}
@end
