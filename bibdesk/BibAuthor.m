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
#import <OmniFoundation/OmniFoundation.h>
#import "BDSKErrorObjectController.h"
#import "NSString+XMLUtils.h"
#import "BibPrefController.h"

@interface BibAuthor (Private)

- (void)setName:(NSString *)newName;
- (void)setNormalizedName:(NSString *)theName;
- (void)setSortableName:(NSString *)theName;
- (void)refreshNormalizedName;
- (void)setVonPart:(NSString *)newVonPart;
- (void)setLastName:(NSString *)newLastName;
- (void)setFirstName:(NSString *)newFirstName;
- (void)setJrPart:(NSString *)newJrPart;
- (void)refreshSortableName;
   
@end

static BibAuthor *emptyAuthorInstance = nil;

@implementation BibAuthor

+ (void)initialize{
    
    OBINITIALIZE;
    emptyAuthorInstance = [[BibAuthor alloc] initWithName:@"" andPub:nil];
}
    

+ (BOOL)accessInstanceVariablesDirectly{ 
    return NO; 
}

+ (BibAuthor *)authorWithName:(NSString *)newName andPub:(BibItem *)aPub{	
    return [[[BibAuthor alloc] initWithName:newName andPub:aPub] autorelease];
}

+ (BibAuthor *)authorWithVCardRepresentation:(NSData *)vCard andPub:aPub{
    ABPerson *person = [[ABPerson alloc] initWithVCardRepresentation:vCard];
    NSMutableString *name = [[NSMutableString alloc] initWithCapacity:10];
    
    if([person valueForKey:kABFirstNameProperty]){
        [name appendString:[person valueForKey:kABFirstNameProperty]];
        [name appendString:@" "];
    }
    if([person valueForKey:kABLastNameProperty])
        [name appendString:[person valueForKey:kABLastNameProperty]];
    
    [person release];
    
    if([NSString isEmptyString:name])
        return [BibAuthor emptyAuthor];
    
    BibAuthor *author = [BibAuthor authorWithName:name andPub:aPub];
    [name release];
    
    return author;
}
    
    

+ (id)emptyAuthor{
    OBASSERT(emptyAuthorInstance != nil);
    return emptyAuthorInstance;
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
#if DEBUG
    NSLog(@"bibauthor dealloc");
#endif
    [super dealloc];
}

- (id)copyWithZone:(NSZone *)zone{
    
    // authors are immutable, so we can retain
    if(NSShouldRetainWithZone(self, zone))
        return [self retain];
    
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
    if (![otherAuth isKindOfClass:[self class]])
		return NO;
    return otherAuth == self ? YES : [normalizedName isEqualToString:otherAuth->normalizedName];
}

- (unsigned int)hash{
    // @@ assumes that these objects will not be modified while contained in a hashing collection
    return hash;
}

#pragma mark Comparison

// returns an array of first names, assuming that words and initials are separated by whitespace or '.'
- (NSArray *)firstNames{
    OFStringScanner *scanner = [[OFStringScanner alloc] initWithString:firstName];
    static OFCharacterSet *stopSet = nil;
    if(stopSet == nil)
        stopSet = [[OFCharacterSet alloc] initWithString:@" ."];
    
    NSMutableArray *names = [NSMutableArray arrayWithCapacity:3];
    NSString *string;
    
    // get rid of leading space (shouldn't be necessary...)
    scannerScanUpToCharacterNotInOFCharacterSet(scanner, stopSet);
    
    do {
        string = [scanner readFullTokenWithDelimiterOFCharacterSet:stopSet];
        if(string)
            [names addObject:string];
        
        // now scan past the space/dot
        scannerScanUpToCharacterNotInOFCharacterSet(scanner, stopSet);
        
    } while(scannerHasData(scanner));
    
    [scanner release];
    
    return names;
}    

//
// Examples of the various cases we need to handle in comparing first names (for /fuzzy/ matching)
//
// Knuth, D. E.       Knuth, Donald E.
// Knuth, D.          Knuth, D. E.
// Knuth, Don E.      Knuth, Donald
// Knuth, Donald      Knuth, Donald E.
// Knuth, Donald E.   Knuth, Donald Ervin
//

- (NSComparisonResult)compareFirstNames:(BibAuthor *)otherAuth{
    
    NSArray *myFirstNames = [self firstNames];
    NSArray *otherFirstNames = [otherAuth firstNames];
    
    CFIndex i, cnt = MIN([myFirstNames count], [otherFirstNames count]);
    NSString *myName;
    NSString *otherName;
    CFIndex maxLength;
    
    NSComparisonResult result;
    
    for(i = 0; i < cnt; i++){
        myName = [myFirstNames objectAtIndex:i];
        otherName = [otherFirstNames objectAtIndex:i];
        maxLength = MIN([myName length], [otherName length]);
        
        myName = [myName substringToIndex:maxLength];
        otherName = [otherName substringToIndex:maxLength];
        
        result = [myName localizedCaseInsensitiveCompare:otherName];
        if(result != NSOrderedSame)
            return result;
    }
    
    // all prefixes of all first name strings compared the same
    return NSOrderedSame;
}

- (NSComparisonResult)compare:(BibAuthor *)otherAuth{
	return [[self normalizedName] compare:[otherAuth normalizedName] options:NSCaseInsensitiveSearch];
}

// fuzzy tries to match despite common omissions.
// currently can't handle spelling errors.
- (NSComparisonResult)fuzzyCompare:(BibAuthor *)otherAuth{
	
    NSMutableString *myName = [[NSMutableString alloc] initWithCapacity:[normalizedName length]];
    NSMutableString *otherName = [[NSMutableString alloc] initWithCapacity:[[otherAuth normalizedName] length]];
    
    // if these are nil, format strings will give a (null) literal string, which we don't want...
    if(![NSString isEmptyString:vonPart]){
        [myName appendString:vonPart];
        [myName appendString:@" "];
    }
	if(![NSString isEmptyString:lastName])
        [myName appendString:lastName];
    
    if(![NSString isEmptyString:[otherAuth vonPart]]){
        [otherName appendString:[otherAuth vonPart]];
        [otherName appendString:@" "];
    }
    if(![NSString isEmptyString:[otherAuth lastName]])
        [otherName appendString:[otherAuth lastName]];
    
    NSComparisonResult result;
    
    // check to see if last names match; if not, we can return immediately
    result = [myName localizedCaseInsensitiveCompare:otherName];
    
    [myName release];
    [otherName release];
    
    if(result != NSOrderedSame)
        return result;

    // if one of the first names is empty, no point in doing anything more sophisticated (unless we want to force the order here)
    if([NSString isEmptyString:firstName] || [NSString isEmptyString:[otherAuth firstName]])
        return [firstName localizedCaseInsensitiveCompare:[otherAuth firstName]];
    else 
        return [self compareFirstNames:otherAuth];
}

- (NSComparisonResult)sortCompare:(BibAuthor *)otherAuth{ // used for tableview sorts; omits von and jr parts
    if(self == emptyAuthorInstance)
        return (otherAuth == emptyAuthorInstance ? NSOrderedSame : NSOrderedDescending);
    if(otherAuth == emptyAuthorInstance)
        return NSOrderedAscending;
    return [[self sortableName] localizedCaseInsensitiveCompare:[otherAuth sortableName]];
}


#pragma mark String Representations

- (NSString *)description{
    return normalizedName;
}

#pragma mark Component Accessors

- (NSString *)normalizedName{
	return normalizedName;
}

- (NSString *)sortableName{
    return sortableName;
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

- (BibItem *)publication{
    return publication;
}

- (void)setPublication:(BibItem *)newPub{
    if(publication != nil)
        @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:[NSString stringWithFormat:@"Attempt to modify non-nil attribute of immutable object %@", self] userInfo:nil];
    publication = newPub;
}

// Accessors for personController - we don't retain it to avoid cycles.
- (BibPersonController *)personController{
    return personController; 
}

- (void)setPersonController:(BibPersonController *)newPersonController{
	personController = newPersonController;
}

- (ABPerson *)personFromAddressBook{
    ABSearchElement *lastNameSearch = [ABPerson searchElementForProperty:kABLastNameProperty label:nil key:nil value:lastName comparison:kABEqualCaseInsensitive];
    NSArray *firstNames = [self firstNames];
    ABSearchElement *firstNameSearch = [ABPerson searchElementForProperty:kABFirstNameProperty label:nil key:nil value:([firstNames count] ? [firstNames objectAtIndex:0] : @"") comparison:kABPrefixMatch];
    
    ABSearchElement *firstAndLastName = [ABSearchElement searchElementForConjunction:kABSearchAnd children:[NSArray arrayWithObjects:lastNameSearch, firstNameSearch, nil]];
    
    NSArray *matches = [[ABAddressBook sharedAddressBook] recordsMatchingSearchElement:firstAndLastName];
    
    return [matches count] ? [matches objectAtIndex:0] : nil;
}

@end

@implementation BibAuthor (Private)

- (void)setName:(NSString *)newName{
    
    NSParameterAssert(newName != nil);
    // @@ this is necessary because the hash method depends on the internal state of the object (which is itself necessary since we can have multiple author instances of the same author)
    if(name != nil)
        @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:[NSString stringWithFormat:@"Attempt to modify non-nil attribute of immutable object %@", self] userInfo:nil];
    
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

- (void)setNormalizedName:(NSString *)theName{
    if(normalizedName != theName){
        [normalizedName release];
        normalizedName = [theName copy];
    }
}

// This follows the recommendations from Oren Patashnik's btxdoc.tex:
/*To summarize, BibTEX allows three possible forms for the name: 
"First von Last" 
"von Last, First" 
"von Last, Jr, First" 
You may almost always use the first form; you shouldn’t if either there’s a Jr part, or the Last part has multiple tokens but there’s no von part. 
*/
// Note that if there is only one word/token, it is the lastName, so that's assumed to always be there.

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
    
    hash = [normalizedName hash];
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

@end

CFHashCode BibAuthorFuzzyHash(const void *item)
{
    OBASSERT([(id)item isKindOfClass:[BibAuthor class]]);
    return OFCaseInsensitiveStringHash([(BibAuthor *)item lastName]);
}

Boolean BibAuthorFuzzyEqual(const void *value1, const void *value2)
{        
    OBASSERT([(id)value1 isKindOfClass:[BibAuthor class]] && [(id)value2 isKindOfClass:[BibAuthor class]]);
    return [(BibAuthor *)value1 fuzzyCompare:(BibAuthor *)value2] == NSOrderedSame ? TRUE : FALSE;
}

const CFSetCallBacks BDSKAuthorFuzzySetCallbacks = {
    0,    // version
    OFNSObjectRetain,  // retain
    OFNSObjectRelease, // release
    OFNSObjectCopyDescription,
    BibAuthorFuzzyEqual,
    BibAuthorFuzzyHash,
};

const CFDictionaryKeyCallBacks BDSKFuzzyDictionaryKeyCallBacks = {
    0,
    OFNSObjectRetain,
    OFNSObjectRelease,
    OFNSObjectCopyDescription,
    BibAuthorFuzzyEqual,
    BibAuthorFuzzyHash,
};

const CFArrayCallBacks BDSKAuthorFuzzyArrayCallBacks = {
    0,    // version
    OFNSObjectRetain,  // retain
    OFNSObjectRelease, // release
    OFNSObjectCopyDescription,
    BibAuthorFuzzyEqual,
};

NSMutableSet *BDSKCreateFuzzyAuthorCompareMutableSet()
{
    return (NSMutableSet *)CFSetCreateMutable(CFAllocatorGetDefault(), 0, &BDSKAuthorFuzzySetCallbacks);
}

@implementation BDSKCountedSet (BibAuthor)

- (id)initFuzzyAuthorCountedSet
{
    return [self initWithKeyCallBacks:&BDSKFuzzyDictionaryKeyCallBacks];
}

@end

@implementation ABPerson (BibAuthor)

+ (ABPerson *)personWithAuthor:(BibAuthor *)author;
{
    
    ABPerson *person = [author personFromAddressBook];
    if(person == nil){    
        person = [[[ABPerson alloc] init] autorelease];
        [person setValue:[author lastName] forProperty:kABLastNameProperty];
        [person setValue:[author firstName] forProperty:kABFirstNameProperty];
    }
    return person;
}

@end