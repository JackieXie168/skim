//  BibAuthor.m

//  Created by Michael McCracken on Wed Dec 19 2001.
/*
 This software is Copyright (c) 2001,2002,2003,2004,2005,2006
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
#import "BibPrefController.h"
#import "BibTeXParser.h"
#import <BTParse/btparse.h>
#import "BDSKErrorObjectController.h"

@interface BibAuthor (Private)

- (void)splitName:(NSString *)newName;
- (void)setNormalizedName:(NSString *)theName;
- (void)setFullLastName:(NSString *)theName;
- (void)setSortableName:(NSString *)theName;
- (void)cacheNames;
- (void)setVonPart:(NSString *)newVonPart;
- (void)setLastName:(NSString *)newLastName;
- (void)setFirstName:(NSString *)newFirstName;
- (void)setJrPart:(NSString *)newJrPart;
- (void)setFuzzyName:(NSString *)theName;
- (NSString *)fuzzyName; // this is an implementation detail, so other classes mustn't rely on it
- (void)setupAbbreviatedNames;

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
    
    BibAuthor *author = [NSString isEmptyString:name] ? [BibAuthor emptyAuthor] : [BibAuthor authorWithName:name andPub:aPub];
    [name release];
    
    return author;
}
    
    

+ (id)emptyAuthor{
    OBASSERT(emptyAuthorInstance != nil);
    return emptyAuthorInstance;
}

- (id)initWithName:(NSString *)aName andPub:(BibItem *)aPub{
	if (self = [super init]) {
        // zero the flags
        memset(&flags, (BOOL)0, sizeof(BibAuthorFlags));

		// set this first so we have the document for parser errors
        publication = aPub; // don't retain this, since it retains us
        
        originalName = [aName retain];
        // this does all the name parsing
		[self splitName:aName];
	}
    
    return self;
}

- (void)dealloc{
    [firstNames release];
    [name release];
	[firstName release];
	[vonPart release];
	[lastName release];
	[jrPart release];
	[normalizedName release];
    [sortableName release];
    [abbreviatedName release];
    [abbreviatedNormalizedName release];
    [fuzzyName release];
    [super dealloc];
}

- (id)copyWithZone:(NSZone *)zone{
    // authors are immutable
    return [self retain];
}

- (id)initWithCoder:(NSCoder *)coder{
    if([coder allowsKeyedCoding]){
        self = [super init];
        memset(&flags, (BOOL)0, sizeof(BibAuthorFlags));
        publication = [coder decodeObjectForKey:@"publication"];
        // this should take care of the rest of the ivars
        [self splitName:[coder decodeObjectForKey:@"name"]];
    } else {
        [[super init] release];
        self = [[NSKeyedUnarchiver unarchiveObjectWithData:[coder decodeDataObject]] retain];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder{
    if([coder allowsKeyedCoding]){
        [coder encodeObject:name forKey:@"name"];
        [coder encodeConditionalObject:publication forKey:@"publication"];
    } else {
        [coder encodeDataObject:[NSKeyedArchiver archivedDataWithRootObject:self]];
    }  
}

- (id)replacementObjectForPortCoder:(NSPortCoder *)encoder
{
    return [encoder isByref] ? (id)[NSDistantObject proxyWithLocal:self connection:[encoder connection]] : self;
}

- (BOOL)isEqual:(id)obj{
    if (![obj isKindOfClass:[self class]])
		return NO;
    return obj == self ? YES : [normalizedName isEqualToString:[obj normalizedName]];
}

- (unsigned int)hash{
    // @@ assumes that these objects will not be modified while contained in a hashing collection
    return hash;
}

#pragma mark Comparison

// returns an array of first names, assuming that words and initials are separated by whitespace or '.'
- (NSArray *)firstNames{
    return firstNames;
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

static inline BOOL
__BibAuthorsHaveEqualFirstNames(CFArrayRef myFirstNames, CFArrayRef otherFirstNames)
{
    OBASSERT(myFirstNames);
    OBASSERT(otherFirstNames);
    
    CFIndex i, cnt = MIN(CFArrayGetCount(myFirstNames), CFArrayGetCount(otherFirstNames));
    CFStringRef myName;
    CFStringRef otherName;
    CFRange range = CFRangeMake(0, 0);
    
    NSComparisonResult result;
    CFAllocatorRef allocator = CFAllocatorGetDefault();
    
    for(i = 0; i < cnt; i++){
        myName = CFArrayGetValueAtIndex(myFirstNames, i);
        otherName = CFArrayGetValueAtIndex(otherFirstNames, i);
        
        range.length = MIN(CFStringGetLength(myName), CFStringGetLength(otherName));
        
        // CFStringCompareWithOptions only applies the range argument to the first string, so make sure they're the same length
        otherName = CFStringCreateWithSubstring(allocator, otherName, range);
        
        result = CFStringCompareWithOptions(myName, otherName, range, kCFCompareCaseInsensitive|kCFCompareLocalized);
        CFRelease(otherName);
        
        // all it takes is one false match
        if(result != kCFCompareEqualTo)
            return NO;
    }
    
    // all prefixes of all first name strings compared the same
    return YES;
}

- (NSComparisonResult)compare:(BibAuthor *)otherAuth{
	return [normalizedName compare:[otherAuth normalizedName] options:NSCaseInsensitiveSearch];
}

// fuzzy tries to match despite common omissions.
// currently can't handle spelling errors.
- (BOOL)fuzzyEqual:(BibAuthor *)otherAuth{
    
    // required for access to flags; could also raise an exception
    OBASSERT([otherAuth isKindOfClass:[self class]]); 
        
    // check to see if last names match; if not, we can return immediately
    if(CFStringCompare((CFStringRef)fuzzyName, (CFStringRef)otherAuth->fuzzyName, kCFCompareCaseInsensitive|kCFCompareLocalized) != kCFCompareEqualTo)
        return NO;
    
    // if one of the first names is empty, no point in doing anything more sophisticated (unless we want to force the order here)
    if(flags.hasFirst == NO && otherAuth->flags.hasFirst == NO)
        return YES;
    else 
        return __BibAuthorsHaveEqualFirstNames((CFArrayRef)firstNames, (CFArrayRef)otherAuth->firstNames);
}

- (NSComparisonResult)sortCompare:(BibAuthor *)otherAuth{ // used for tableview sorts; omits von and jr parts
    if(self == emptyAuthorInstance)
        return (otherAuth == emptyAuthorInstance ? NSOrderedSame : NSOrderedDescending);
    if(otherAuth == emptyAuthorInstance)
        return NSOrderedAscending;
    return [sortableName localizedCaseInsensitiveCompare:[otherAuth sortableName]];
}


#pragma mark String Representations

- (NSString *)description{
    return [self displayName];
}

- (NSString *)displayName{
    int mask = [[OFPreferenceWrapper sharedPreferenceWrapper] integerForKey:BDSKAuthorNameDisplayKey];

    NSString *theName = nil;

    if((mask & BDSKAuthorDisplayFirstNameMask) == NO)
        theName = fullLastName; // and then ignore the other options
    else if(mask & BDSKAuthorLastNameFirstMask)
        theName = mask & BDSKAuthorAbbreviateFirstNameMask ? [self abbreviatedNormalizedName] : normalizedName;
    else
        theName = mask & BDSKAuthorAbbreviateFirstNameMask ? [self abbreviatedName] : name;
    return theName;
}


#pragma mark Component Accessors

- (NSString *)normalizedName{
	return normalizedName;
}

- (NSString *)fullLastName{
    return fullLastName;
}

- (NSString *)sortableName{
    return sortableName;
}

- (NSString *)originalName{
    return originalName;
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

// Given a normalized name of "von Last, Jr, First Middle", this will return "F. M. von Last, Jr"
- (NSString *)abbreviatedName{
    if(abbreviatedName == nil)
        [self setupAbbreviatedNames];
    return abbreviatedName;
}

// Given a normalized name of "von Last, Jr, First Middle", this will return "von Last, Jr, F. M."
- (NSString *)abbreviatedNormalizedName{
    if(abbreviatedNormalizedName == nil)
        [self setupAbbreviatedNames];
    return abbreviatedNormalizedName;
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
    ABSearchElement *firstNameSearch = [ABPerson searchElementForProperty:kABFirstNameProperty label:nil key:nil value:([firstNames count] ? [firstNames objectAtIndex:0] : @"") comparison:kABPrefixMatch];
    
    ABSearchElement *firstAndLastName = [ABSearchElement searchElementForConjunction:kABSearchAnd children:[NSArray arrayWithObjects:lastNameSearch, firstNameSearch, nil]];
    
    NSArray *matches = [[ABAddressBook sharedAddressBook] recordsMatchingSearchElement:firstAndLastName];
    
    return [matches count] ? [matches objectAtIndex:0] : nil;
}

@end

@implementation BibAuthor (Private)

// creates an NSString from the given bt_name and bt_namepart, which were parsed with the given encoding; returns nil if no such name component exists
static NSString *createNameStringForComponent(CFAllocatorRef alloc, bt_name *theName, bt_namepart thePart, CFStringEncoding encoding)
{
    int i, numberOfTokens = theName->part_len[thePart];
    CFStringRef theString = NULL;
 
    // typical for some parts; let's not bother with a mutable string in this case
    if (numberOfTokens == 1){
        theString = CFStringCreateWithCString(alloc, theName->parts[thePart][0], encoding);
    } else if (numberOfTokens > 1){
        CFMutableStringRef mutableString = CFStringCreateMutable(alloc, 0);
        int stopTokenIndex = numberOfTokens - 1;
        
        for (i = 0; i < numberOfTokens; i++){
            theString = CFStringCreateWithCString(alloc, theName->parts[thePart][i], encoding);
            CFStringAppend(mutableString, theString);
            CFRelease(theString);
    
            if (i < stopTokenIndex)
                CFStringAppend(mutableString, CFSTR(" "));
        }
        theString = mutableString;
    }
    return (NSString *)theString;
}

- (void)splitName:(NSString *)newName{
    
    NSParameterAssert(newName != nil);
    // @@ this is necessary because the hash method depends on the internal state of the object (which is itself necessary since we can have multiple author instances of the same author)
    if(name != nil)
        @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:[NSString stringWithFormat:@"Attempt to modify non-nil attribute of immutable object %@", self] userInfo:nil];
        
    CFAllocatorRef alloc = CFAllocatorGetDefault();
    
    // we need to remove newlines and collapse whitespace before using bt_split_name 
    newName = (NSString *)BDStringCreateByCollapsingAndTrimmingWhitespaceAndNewlines(alloc, (CFStringRef)newName);
    
    // get the fastest encoding, since it usually allows us to get a pointer to the contents
    // the main reason for using CFString here is that it offers cString create/get for any encoding
    CFStringEncoding encoding = CFStringGetFastestEncoding((CFStringRef)newName);   
    
    // if it's Unicode, switch to UTF-8 to avoid data loss (btparse doesn't like unichars)
    if(encoding >= kCFStringEncodingUnicode)
        encoding = kCFStringEncodingUTF8;
    
    const char *name_cstring = NULL;
    name_cstring = CFStringGetCStringPtr((CFStringRef)newName, encoding);
    BOOL shouldFree = NO;
    CFIndex fullLength = CFStringGetLength((CFStringRef)newName);
    
    // CFStringGetCStringPtr will probably always fail for UTF-8, but it may fail regardless
    if(NULL == name_cstring){
        shouldFree = YES;
        
        // this length is probably excessive, but it's returned quickly
        CFIndex requiredLength = CFStringGetMaximumSizeForEncoding(fullLength, encoding);
        
        // malloc a buffer, then set our const pointer to it if the conversion succeeds; this may be slightly more efficient than -[NSString UTF8String] because it's not adding an NSData to the autorelease pool
        char *buffer = (char *)CFAllocatorAllocate(alloc, (requiredLength + 1) * sizeof(char), 0);
        if(FALSE == CFStringGetCString((CFStringRef)newName, buffer, requiredLength, encoding)){
            CFAllocatorDeallocate(alloc, buffer);
            shouldFree = NO;
        } else {
            name_cstring = buffer;
        }
    }
    
    bt_name *theName;
    
    [[BDSKErrorObjectController sharedErrorObjectController] startObservingErrors];
    // pass the name as a C string; note that btparse will not work with unichars
    theName = bt_split_name((char *)name_cstring, NULL, 0, 0);
    [[BDSKErrorObjectController sharedErrorObjectController] endObservingErrorsForPublication:publication];

    [newName release];
    if(shouldFree)
        CFAllocatorDeallocate(alloc, (void *)name_cstring);
    
    NSString *nameString = nil;
    
    nameString = createNameStringForComponent(alloc, theName, BTN_FIRST, encoding);
    if (nameString) {
        [self setFirstName:nameString];
        [nameString release];
        flags.hasFirst = YES;
    }
    
    nameString = createNameStringForComponent(alloc, theName, BTN_VON, encoding);
    if (nameString) {
        [self setVonPart:nameString];
        [nameString release];
        flags.hasVon = YES;
    }
    
    nameString = createNameStringForComponent(alloc, theName, BTN_LAST, encoding);
    if (nameString) {
        [self setLastName:nameString];
        [nameString release];
        flags.hasLast = YES;
    }
    
    nameString = createNameStringForComponent(alloc, theName, BTN_JR, encoding);
    if (nameString) {
        [self setJrPart:nameString];
        [nameString release];
        flags.hasJr = YES;
    }
    
    bt_free_name(theName);
        
    [self cacheNames];    
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

- (void)setFullLastName:(NSString *)theName{
    if(fullLastName != theName){
        [fullLastName release];
        fullLastName = [theName copy];
    }
}

// This follows the recommendations from Oren Patashnik's btxdoc.tex:
/*To summarize, BibTeX allows three possible forms for the name: 
"First von Last" 
"von Last, First" 
"von Last, Jr, First" 
You may almost always use the first form; you shouldn't if either there's a Jr part, or the Last part has multiple tokens but there's no von part. 
*/
// Note that if there is only one word/token, it is the lastName, so that's assumed to always be there.

- (void)cacheNames{
	
	// temporary string storage
    NSMutableString *theName = [[NSMutableString alloc] initWithCapacity:14];
    
    // create the name ivar as "First Middle von Last, Jr", which is more readable and less sortable
    // @@ This will potentially alter data if BibItem ever saves based on -[BibAuthor name] instead of the original string it keeps in pubFields    

    // first and middle are associated
    if(flags.hasFirst){
        [theName appendString:firstName];
        [theName appendString:@" "];
    }
    
    if(flags.hasVon){
        [theName appendString:vonPart];
        [theName appendString:@" "];
    }
    
    if(flags.hasLast) [theName appendString:lastName];
    
    if(flags.hasJr){
        [theName appendString:@", "];
        [theName appendString:jrPart];
    }
    
    name = [theName copy];
    
    // create the normalized name (see comment above method)

    [theName replaceCharactersInRange:NSMakeRange(0, [theName length]) withString:@""];

    if(flags.hasVon){
        [theName appendString:vonPart];
        [theName appendString:@" "];
    }
    
    if(flags.hasLast) [theName appendString:lastName];
    
    if(flags.hasJr){
        [theName appendString:@", "];
        [theName appendString:jrPart];
    }
    
    [self setFullLastName:theName];
    
    if(flags.hasFirst){
        [theName appendString:@", "];
        [theName appendString:firstName];
    }
    
    [self setNormalizedName:theName];
    
    // our hash is based upon the normalized name, so isEqual: must also be based upon the normalized name
    hash = [normalizedName hash];

    // create the sortable name
    // "Lastname Firstname" (no comma, von, or jr), with braces removed
        
    [theName replaceCharactersInRange:NSMakeRange(0, [theName length]) withString:@""];

    [theName appendString:(flags.hasLast ? lastName : @"")];
    [theName appendString:(flags.hasFirst ? @" " : @"")];
    [theName appendString:(flags.hasFirst ? firstName : @"")];
    [theName deleteCharactersInCharacterSet:[NSCharacterSet curlyBraceCharacterSet]];
    [self setSortableName:theName];
    
    // components of the first name used in fuzzy comparisons
    
    static CFCharacterSetRef separatorSet = NULL;
    if(separatorSet == NULL)
        separatorSet = CFCharacterSetCreateWithCharactersInString(CFAllocatorGetDefault(), CFSTR(" ."));
    
    // @@ see note on firstLetterCharacterString() function for possible issues with this
    firstNames = flags.hasFirst ? (id)BDStringCreateComponentsSeparatedByCharacterSetTrimWhitespace(CFAllocatorGetDefault(), (CFStringRef)firstName, separatorSet, FALSE) : [[NSArray alloc] init];

    // fuzzy comparison  name
    // don't bother with spaces for this comparison (and whitespace is already collapsed)
    
    [theName replaceCharactersInRange:NSMakeRange(0, [theName length]) withString:@""];

    if(flags.hasVon) [theName appendString:vonPart];
	if(flags.hasLast) [theName appendString:lastName];
    [self setFuzzyName:theName];
    
    // dispose of the temporary mutable string
    [theName release];
}

- (void)setFuzzyName:(NSString *)theName{
    if(fuzzyName != theName){
        [fuzzyName release];
        fuzzyName = [theName copy];
    }
}

- (NSString *)fuzzyName{
    return fuzzyName;
}

- (void)setSortableName:(NSString *)theName{
    if(sortableName != theName){
        [sortableName release];
        sortableName = [theName copy];
    }
}

- (void)setAbbreviatedName:(NSString *)aName{
    if(aName != abbreviatedName){
        [abbreviatedName release];
        abbreviatedName = [aName copy];
    }
}

- (void)setAbbreviatedNormalizedName:(NSString *)aName{
    if(aName != abbreviatedNormalizedName){
        [abbreviatedNormalizedName release];
        abbreviatedNormalizedName = [aName copy];
    }
}

// Bug #1436631 indicates that "Pomies, M.-P." was displayed as "M. -. Pomies", so we'll grab the first letter character instead of substringToIndex:1.  The technically correct solution may be to use "M. Pomies" in this case, but we split the first name at "." boundaries to generate the firstNames array.
static inline CFStringRef copyFirstLetterCharacterString(CFAllocatorRef alloc, CFStringRef string)
{
    CFRange letterRange;
    Boolean hasChar = CFStringFindCharacterFromSet(string, (CFCharacterSetRef)[NSCharacterSet letterCharacterSet], CFRangeMake(0, CFStringGetLength(string)), 0, &letterRange);
    return hasChar ? CFStringCreateWithSubstring(alloc, string, letterRange) : NULL;
}

- (void)setupAbbreviatedNames
{
    CFArrayRef theFirstNames = (CFArrayRef)firstNames;
    CFIndex idx, firstNameCount = CFArrayGetCount(theFirstNames);
    CFStringRef fragment = nil;
    CFStringRef firstLetter = nil;
    
    CFAllocatorRef alloc = CFAllocatorGetDefault();
    CFIndex nameLength = CFStringGetLength((CFStringRef)name);
    CFIndex firstNameMaxLength = 3 * firstNameCount;
    
    // use fixed-size mutable strings; allow for extra ". "
    CFMutableStringRef abbrevName = CFStringCreateMutable(alloc, nameLength + firstNameMaxLength);
    CFMutableStringRef abbrevFirstName = NULL;
    
    if(flags.hasFirst){
        
        // allow for ". " around each character
        abbrevFirstName = CFStringCreateMutable(alloc, firstNameMaxLength);
        
        // loop through the first name parts (which includes middle names)
        CFIndex lastIdx = firstNameCount - 1;
        for(idx = 0; idx <= lastIdx; idx++){
            fragment = CFArrayGetValueAtIndex(theFirstNames, idx);
            firstLetter = copyFirstLetterCharacterString(alloc, fragment);
            if (firstLetter != nil) {
                CFStringAppend(abbrevFirstName, firstLetter);
                CFStringAppend(abbrevFirstName, (idx < lastIdx ? CFSTR(". ") : CFSTR(".")) );
                CFRelease(firstLetter);
            }
        }
    }
    
    // abbrevName is now empty; set it to the first name
    if(flags.hasFirst){
        CFStringAppend(abbrevName, abbrevFirstName);
        CFStringAppend(abbrevName, CFSTR(" "));
    }
    
    CFStringAppend(abbrevName, (CFStringRef)fullLastName);
    
    [self setAbbreviatedName:(NSString *)abbrevName];
    
    // now for the normalized abbreviated form; start with only the last name
    CFStringReplaceAll(abbrevName, (CFStringRef)fullLastName);
    
    if(flags.hasFirst){
        CFStringAppend(abbrevName, CFSTR(", "));
        CFStringAppend(abbrevName, abbrevFirstName);
        
        // first name was non-NULL, and we're done with it
        CFRelease(abbrevFirstName);
    }
    
    [self setAbbreviatedNormalizedName:(NSString *)abbrevName];
    CFRelease(abbrevName);
}

@end

#pragma mark Specialized collections

// fuzzy equality requires that last names be equal case-insensitively, so equal objects are guaranteed the same hash
CFHashCode BibAuthorFuzzyHash(const void *item)
{
    OBASSERT([(id)item isKindOfClass:[BibAuthor class]]);
    return BDCaseInsensitiveStringHash([(BibAuthor *)item lastName]);
}

Boolean BibAuthorFuzzyEqual(const void *value1, const void *value2)
{        
    OBASSERT([(id)value1 isKindOfClass:[BibAuthor class]] && [(id)value2 isKindOfClass:[BibAuthor class]]);
    return [(BibAuthor *)value1 fuzzyEqual:(BibAuthor *)value2];
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