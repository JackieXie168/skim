//  BibAuthor.m

//  Created by Michael McCracken on Wed Dec 19 2001.
/*
 This software is Copyright (c) 2001,2002,2003,2004,2005
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

#import "BibAuthor.h"
#import "BibItem.h"


@implementation BibAuthor

+ (BibAuthor *)authorWithName:(NSString *)newName andPub:(BibItem *)aPub{	
    return [[[BibAuthor alloc] initWithName:newName andPub:aPub] autorelease];
}

- (id)initWithName:(NSString *)aName andPub:(BibItem *)aPub{
	if (self = [super init]) {
		[self setName:aName];
		publication = aPub; // don't retain this, since it retains us
	}
    
    return self;
}

- (void)dealloc{
    [name release];
	[firstName release];
	[vonPart release];
	[lastName release];
	[jrPart release];
	[normalizedName release];
    [sortableName release];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
#if DEBUG
    NSLog(@"bibauthor dealloc");
#endif
    [super dealloc];
}

- (id)copyWithZone:(NSZone *)zone{
    BibAuthor *copy = [[[self class] allocWithZone: zone] initWithName:[self name]
																andPub:[self publication]];
    return copy;
}

- (id)initWithCoder:(NSCoder *)coder{
    self = [super init];
    [self setName:[coder decodeObjectForKey:@"name"]]; // this should take care of the rest of the ivars, right?
    publication = [coder decodeObjectForKey:@"publication"];
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder{
    [coder encodeObject:name forKey:@"name"];
    [coder encodeConditionalObject:publication forKey:@"publication"];
}

- (BOOL)isEqual:(BibAuthor *)otherAuth{
    return [[self normalizedName] isEqualToString:[otherAuth normalizedName]];
}

- (unsigned)hash{
    return [[self normalizedName] hash];
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
	
	NSString *lastStrMe = [NSString stringWithFormat:@"%@%@", vonPart,lastName];
	NSString *lastStrOther = [NSString stringWithFormat:@"%@%@", [otherAuth vonPart], [otherAuth lastName]];
	
	// if we both have a first name, compare first lastStr == first lastStr
	if(![NSString isEmptyString:firstName] && ![NSString isEmptyString:[otherAuth firstName]]){
		return [ [NSString stringWithFormat:@"%@%@", firstName, lastStrMe] compare:
	[NSString stringWithFormat:@"%@%@",[otherAuth firstName], lastStrOther] options:NSCaseInsensitiveSearch];
		
	}else{
		// don't both have a first name, so only compare lastStrs, even if one of us has a first.
		return [lastStrMe compare:lastStrOther options:NSCaseInsensitiveSearch];
	}

}

- (NSComparisonResult)sortCompare:(BibAuthor *)otherAuth{ // used for tableview sorts; omits von and jr parts
    return [[self sortableName] compare:[otherAuth sortableName] options:NSCaseInsensitiveSearch];
}


#pragma mark String Representations

- (NSString *)description{
    return [NSString stringWithFormat:@"[%@_%@_%@_%@]", firstName,vonPart,lastName,jrPart];
}


#pragma mark Component Accessors

// This follows the recommendations from Oren Patashnik's btxdoc.tex:
/*To summarize, BibTEX allows three possible forms for the name: 
"First von Last" 
"von Last, First" 
"von Last, Jr, First" 
You may almost always use the first form; you shouldn’t if either there’s a Jr part, or the Last part has multiple tokens but there’s no von part. 
*/
// Note that if there is only one word/token, it is the lastName, so that's assumed to always be there.

- (NSString *)normalizedName{
	return normalizedName;
}

- (void)refreshNormalizedName{
	
	BOOL FIRST = ![NSString isEmptyString:firstName];
	BOOL VON = ![NSString isEmptyString:vonPart];
	BOOL LAST = ![NSString isEmptyString:lastName];
	BOOL JR = ![NSString isEmptyString:jrPart];
	
    NSMutableString *theName = [[NSMutableString alloc] initWithCapacity:14];
    
    [theName appendString:(VON ? vonPart : @"")];
    [theName appendString:(VON ? @" " : @"")];
    [theName appendString:(LAST ? lastName : @"")];
    [theName appendString:(JR ? @", " : @"")];
    [theName appendString:(FIRST ? @", " : @"")];
    [theName appendString:(FIRST ? firstName : @"")];
    
    [self setNormalizedName:theName];
    [theName release];
}

- (void)refreshSortableName{ // "Lastname Firstname" (no comma, von, or jr), with braces removed
    
    BOOL FIRST = ![NSString isEmptyString:firstName];
    BOOL LAST = ![NSString isEmptyString:lastName];
    
    NSMutableString *theName = [[NSMutableString alloc] initWithCapacity:14];
    [theName appendString:(LAST ? lastName : @"")];
    [theName appendString:(FIRST ? @" " : @"")];
    [theName appendString:(FIRST ? firstName : @"")];

    static NSCharacterSet *braceSet = nil;
    if(braceSet == nil)
        braceSet = [[NSCharacterSet characterSetWithCharactersInString:@"}{"] retain];
    [theName replaceAllOccurrencesOfCharactersInSet:braceSet withString:@""];
    
    [self setSortableName:theName];
    [theName release];
}

- (void)setSortableName:(NSString *)theName{
    if(sortableName != theName){
        [sortableName release];
        sortableName = [theName copy];
    }
}

- (void)setNormalizedName:(NSString *)theName{
    if(normalizedName != theName){
        [normalizedName release];
        normalizedName = [theName copy];
    }
}

- (NSString *)sortableName{
    return sortableName;
}

- (void)setVonPart:(NSString *)newVonPart{
    if(vonPart != newVonPart){
        [vonPart release];
        vonPart = [newVonPart copy];
    }
}

- (void)setLastName:(NSString *)newLastName{
    if(lastName != newLastName){
        [lastName release];
        lastName = [newLastName copy];
    }
}

- (void)setFirstName:(NSString *)newFirstName{
    if(firstName != newFirstName){
        [firstName release];
        firstName = [newFirstName copy];
    }
}

- (void)setJrPart:(NSString *)newJrPart{
    if(jrPart != newJrPart){
        [jrPart release];
        jrPart = [newJrPart copy];
    }
}

- (NSString *)name{
    return name;
}

- (NSString *)firstName{
    return firstName;
}

- (NSString *)vonPart{
    return vonPart;
}

- (NSString *)lastName{
    return lastName;
}

- (NSString *)jrPart{
    return jrPart;
}

- (NSString *)MODSStringWithRole:(NSString *)role{
    NSMutableString *s = [NSMutableString stringWithString:@"<name type=\"personal\">"];
    
    if(firstName){
        [s appendFormat:@"<namePart type=\"given\">%@</namePart>", firstName];
    }
    
    if(lastName){
        [s appendFormat:@"<namePart type=\"family\">%@%@</namePart>", (vonPart ? vonPart : @""),
            lastName];
    }
    
    if(role){
        [s appendFormat:@"<role> <roleTerm authority=\"marcrelator\" type=\"text\">%@</roleTerm></role>",
        role];
    }
    
    [s appendString:@"</name>"];
    
    return [[s copy] autorelease];
}

- (void)setName:(NSString *)newName{
    
    if(newName == name)
        return;
    
    if ([[self publication] document])
		[[BDSKErrorObjectController sharedErrorObjectController] setDocumentForErrors:[[self publication] document]];
	
    bt_name *theName;
    int i = 0;
    
    // use this as a buffer for appending separators
    NSMutableString *mutableString = [[NSMutableString alloc] initWithCapacity:14];
    NSString *tmpStr = nil;
    
    [name release];
    name = [newName copy];

    // pass the name as a UTF8 string, since btparse doesn't work with UniChars
    theName = bt_split_name((char *)[name UTF8String],(char *)[name UTF8String],0,0);
    
    [mutableString setString:@""];
    
    // get tokens from first part
    for (i = 0; i < theName->part_len[BTN_FIRST]; i++)
    {
        tmpStr = [[NSString alloc] initWithUTF8String:(theName->parts[BTN_FIRST][i])];
        [mutableString appendString:tmpStr];
        [tmpStr release];

        if(i >= 0 && i < theName->part_len[BTN_FIRST]-1)
            [mutableString appendString:@" "];
    }
    [self setFirstName:mutableString];
    
    [mutableString setString:@""];
    // get tokens from von part
    for (i = 0; i < theName->part_len[BTN_VON]; i++)
    {
        tmpStr = [[NSString alloc] initWithUTF8String:(theName->parts[BTN_VON][i])];
        [mutableString appendString:tmpStr];
        [tmpStr release];

        if(i >= 0 && i < theName->part_len[BTN_VON]-1)
            [mutableString appendString:@" "];

    }
    [self setVonPart:mutableString];
	
    [mutableString setString:@""];
	// get tokens from last part
    for (i = 0; i < theName->part_len[BTN_LAST]; i++)
    {
        tmpStr = [[NSString alloc] initWithUTF8String:(theName->parts[BTN_LAST][i])];
        [mutableString appendString:tmpStr];
        [tmpStr release];

        if(i >= 0 && i < theName->part_len[BTN_LAST]-1)
            [mutableString appendString:@" "];
    }
    [self setLastName:mutableString];
	
    [mutableString setString:@""];
    // get tokens from jr part
    for (i = 0; i < theName->part_len[BTN_JR]; i++)
    {
        tmpStr = [[NSString alloc] initWithUTF8String:(theName->parts[BTN_JR][i])];
        [mutableString appendString:tmpStr];
        [tmpStr release];
        
        if(i >= 0 && i < theName->part_len[BTN_JR]-1)
            [mutableString appendString:@" "];
    }
    [self setJrPart:jrPart];
    
    [mutableString release];
	
    [self refreshNormalizedName];
    [self refreshSortableName];
    
    bt_free_name(theName);
}

- (BibItem *)publication{
    return publication;
}

- (void)setPublication:(BibItem *)newPub{
    publication = newPub;
}

// Accessors for personController - we don't retain it to avoid cycles.
- (BibPersonController *)personController{
    return personController; 
}

- (void)setPersonController:(BibPersonController *)newPersonController{
	personController = newPersonController;
}

@end
