//  BibItem.m
//  Created by Michael McCracken on Tue Dec 18 2001.
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


#import "BibItem.h"
#import "NSDate_BDSKExtensions.h"

#define addkey(s) if([pubFields objectForKey: s] == nil){[pubFields setObject:@"" forKey: s];} [removeKeys removeObject: s];

OFSimpleLockType authorSimpleLock;

CFHashCode BibItemCaseInsensitiveTitleHash(const void *item)
{
    OBASSERT([(id)item isKindOfClass:[BibItem class]]);
    return ([[[[(BibItem *)item title] stringByRemovingTeX] lowercaseString] hash]);
}

Boolean BibItemAuthorsEqualityTest(const void *value1, const void *value2)
{        
    return ([[(BibItem *)value1 pubAuthors] isEqualToArray:[(BibItem *)value2 pubAuthors]]);
}

// Values are BibItems; used to determine if pubs are duplicates.  Items must not be edited while contained in a set using these callbacks, so dispose of the set before any editing operations.
const CFSetCallBacks BDSKBibItemDuplicationTestCallbacks = {
    0,    // version
    OFNSObjectRetain,  // retain
    OFNSObjectRelease, // release
    OFNSObjectCopyDescription,
    BibItemAuthorsEqualityTest,
    BibItemCaseInsensitiveTitleHash,
};

/* Fonts and paragraph styles cached for efficiency. */
static NSParagraphStyle* keyParagraphStyle = nil;
static NSParagraphStyle* bodyParagraphStyle = nil;
static BOOL paragraphStyleIsSetup = NO;

setupParagraphStyle()
{
    if(paragraphStyleIsSetup == NO){
        NSMutableParagraphStyle *defaultStyle = [[NSMutableParagraphStyle alloc] init];
        [defaultStyle setParagraphStyle:[NSParagraphStyle defaultParagraphStyle]];
        // ?        [defaultStyle setAlignment:NSLeftTextAlignment];
        keyParagraphStyle = [defaultStyle copy];
        [defaultStyle setHeadIndent:50];
        [defaultStyle setFirstLineHeadIndent:50];
        [defaultStyle setTailIndent:-30];
        bodyParagraphStyle = [defaultStyle copy];
        paragraphStyleIsSetup = YES;
    }
}

@implementation BibItem

- (id)init
{
	OFPreferenceWrapper *pw = [OFPreferenceWrapper sharedPreferenceWrapper];
	self = [self initWithType:[pw stringForKey:BDSKPubTypeStringKey]
									  fileType:BDSKBibtexString // Not Sure if this is good.
									 pubFields:nil
									   authors:nil
								   createdDate:[NSCalendarDate calendarDate]];
	if (self) {
        [self setHasBeenEdited:NO]; // for new, empty bibs:  set this here, since makeType: and updateMetadataForKey set it to YES in our call to initWithType: above
	}
	return self;
}

- (id)initWithType:(NSString *)type fileType:(NSString *)inFileType pubFields:(NSDictionary *)fieldsDict authors:(NSMutableArray *)authArray createdDate:(NSCalendarDate *)date{ // this is the designated initializer.
    if (self = [super init]){
		bibLock = [[NSLock alloc] init];
		[bibLock lock];
		if(fieldsDict){
			pubFields = [fieldsDict mutableCopy];
		}else{
			pubFields = [[NSMutableDictionary alloc] initWithCapacity:7];
		}
		if (date){
			NSString *nowStr = [date description];
			[pubFields setObject:nowStr forKey:BDSKDateCreatedString];
			[pubFields setObject:nowStr forKey:BDSKDateModifiedString];
        }
		if(authArray){
			pubAuthors = [authArray mutableCopy];     // copy, it's mutable
		}else{
			pubAuthors = [[NSMutableArray alloc] initWithCapacity:1];
		}
        document = nil;
        editorObj = nil;
        [bibLock unlock];
        [self setFileType:inFileType];
        [self setPubType:type];
        [self setCiteKeyString: @"cite-key"];
        [self setDate: nil];
        
        // this date will be nil when loading from a file or it will be the current date when pasting
        [self setDateCreated: date];
        [self setDateModified: date];
        
		[self setNeedsToBeFiled:NO];
		
		groups = [[NSMutableDictionary alloc] initWithCapacity:5];
		
        // updateMetadataForKey with a nil argument will set the dates properly if we read them from a file
        [self updateMetadataForKey:nil];
        setupParagraphStyle();
		OFSimpleLockInit(&authorSimpleLock);
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(typeInfoDidChange:)
													 name:BDSKBibTypeInfoChangedNotification
												   object:[BibTypeManager sharedManager]];

		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(customFieldsDidChange:)
													 name:BDSKCustomFieldsChangedNotification
												   object:nil];
    }

    //NSLog(@"bibitem init");
    return self;
}

- (id)copyWithZone:(NSZone *)zone{
    BibItem *theCopy = [[[self class] allocWithZone: zone] initWithType:pubType
                                                               fileType:fileType
															  pubFields:pubFields
                                                                authors:pubAuthors
															createdDate:[NSCalendarDate calendarDate]];
    [theCopy setCiteKeyString: citeKey];
    [theCopy setDate: pubDate];
	
	[theCopy copyComplexStringValues];
	
    return theCopy;
}

- (id)initWithCoder:(NSCoder *)coder{
    self = [super init];
    [self setFileType:[coder decodeObjectForKey:@"fileType"]];
    [self setCiteKeyString:[coder decodeObjectForKey:@"citeKey"]];
    [self setDate:[coder decodeObjectForKey:@"pubDate"]];
    [self setDateCreated:[coder decodeObjectForKey:@"dateCreated"]];
    [self setPubType:[coder decodeObjectForKey:@"pubType"]];
    [self setDateModified:[coder decodeObjectForKey:@"dateModified"]];
    pubFields = [[coder decodeObjectForKey:@"pubFields"] retain];
    pubAuthors = [[coder decodeObjectForKey:@"pubAuthors"] retain];
	groups = [[NSMutableDictionary alloc] initWithCapacity:5];
    // set by the document, which we don't archive
    document = nil;
    editorObj = nil;
    setupParagraphStyle();
    hasBeenEdited = [coder decodeBoolForKey:@"hasBeenEdited"];
    bibLock = [[NSLock alloc] init]; // not encoded
    OFSimpleLockInit(&authorSimpleLock);

	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(typeInfoDidChange:)
												 name:BDSKBibTypeInfoChangedNotification
											   object:[BibTypeManager sharedManager]];

	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(customFieldsDidChange:)
												 name:BDSKCustomFieldsChangedNotification
											   object:nil];
    
	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder{
    [coder encodeObject:fileType forKey:@"fileType"];
    [coder encodeObject:citeKey forKey:@"citeKey"];
    [coder encodeObject:pubDate forKey:@"pubDate"];
    [coder encodeObject:dateCreated forKey:@"dateCreated"];
    [coder encodeObject:dateModified forKey:@"dateModified"];
    [coder encodeObject:pubType forKey:@"pubType"];
    [coder encodeObject:pubFields forKey:@"pubFields"];
    [coder encodeObject:pubAuthors forKey:@"pubAuthors"];
    [coder encodeBool:hasBeenEdited forKey:@"hasBeenEdited"];
}

- (void)makeType{
    NSString *fieldString;
    NSEnumerator *e;
    NSString *tmp;
    BibTypeManager *typeMan = [BibTypeManager sharedManager];
    NSEnumerator *reqFieldsE = [[typeMan requiredFieldsForType:pubType] objectEnumerator];
    NSEnumerator *optFieldsE = [[typeMan optionalFieldsForType:pubType] objectEnumerator];
    NSEnumerator *defFieldsE = [[typeMan userDefaultFieldsForType:pubType] objectEnumerator];
    NSMutableArray *removeKeys = [[pubFields allKeysForObject:@""] mutableCopy];
  
    while(fieldString = [reqFieldsE nextObject]){
        addkey(fieldString)
    }
    while(fieldString = [optFieldsE nextObject]){
        addkey(fieldString)
    }
    while(fieldString = [defFieldsE nextObject]){
        addkey(fieldString)
    }    
    
    //I don't enforce Keywords, but since there's GUI depending on them, I will enforce these others:
    addkey(BDSKLocalUrlString) addkey(BDSKUrlString) addkey(BDSKAnnoteString) addkey(BDSKAbstractString) addkey(BDSKRssDescriptionString)

    // now remove everything that's left in remove keys from pubfields
    [pubFields removeObjectsForKeys:removeKeys usingLock:bibLock];
    [removeKeys release];
}

- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
#ifdef DEBUG
    NSLog([NSString stringWithFormat:@"bibitem Dealloc, rt: %d", [self retainCount]]);
#endif
    [[self undoManager] removeAllActionsWithTarget:self];
    [pubFields release];
    [pubAuthors release];
	[groups release];

    [pubType release];
    [fileType release];
    [citeKey release];
    [pubDate release];
    [dateCreated release];
    [dateModified release];
    [bibLock release];
    OFSimpleLockFree(&authorSimpleLock);
    [super dealloc];
}

- (BibDocument *)document {
    return document;
}

- (void)setDocument:(BibDocument *)newDocument {
    if (document != newDocument) {
		document = newDocument;
		[self updateComplexStringValues];
	}
}

- (NSUndoManager *)undoManager { // this may be nil
    return [document undoManager];
}

- (BibEditor *)editorObj{
    return editorObj; // if we haven't been given an editor object yet this should be nil.
}

- (void)setEditorObj:(BibEditor *)editor{
    editorObj = editor; // don't retain it- that will create a cycle!
}

- (NSString *)description{
    return [NSString stringWithFormat:@"%@ %@", [self citeKey], [pubFields description]];
}

- (BOOL)isEqual:(BibItem *)aBI{
    // @@ see discussions on dev-list of 13 May 2005 and 21 October 2005 for why we're dropping internal fields for this comparison
    return [[self bibTeXStringUnexpandedAndDeTeXifiedWithoutInternalFields] isEqualToString:[aBI bibTeXStringUnexpandedAndDeTeXifiedWithoutInternalFields]];
}

- (unsigned int)hash{
    // http://www.mulle-kybernetik.com/artikel/Optimization/opti-7.html has a discussion on hashing; apparently using [citeKey hash] will cause serious problems if this object is in a hashing collection (NSSet, NSDictionary) and the hash changes.
    return( ((unsigned int) self >> 4) | 
            (unsigned int) self << (32 - 4));
}

#pragma mark Comparison functions

// General remark: 
// We handle empty or nil strings seperately by making them bigger than any other value. 
// This is different from the default handling of string compare methods, but makes that empty values 
// are sorted after set values, which is nicer. 

- (NSComparisonResult)pubTypeCompare:(BibItem *)aBI{
	// type cannot be empty
	return [[self type] localizedCaseInsensitiveCompare:[aBI type]];
}

- (NSComparisonResult)keyCompare:(BibItem *)aBI{
	NSString *myCiteKey = [self citeKey];
	NSString *otherCiteKey = [aBI citeKey];
	
    if ([NSString isEmptyString:myCiteKey] || [myCiteKey isEqualToString:@"cite-key"]) {
		return ([NSString isEmptyString:otherCiteKey] || [otherCiteKey isEqualToString:@"cite-key"]) ? NSOrderedSame : NSOrderedDescending;
	} else if ([NSString isEmptyString:otherCiteKey] || [otherCiteKey isEqualToString:@"cite-key"]) {
		return NSOrderedAscending;
	}    
	return [citeKey localizedCaseInsensitiveNumericCompare:[aBI citeKey]];
}

- (NSComparisonResult)titleCompare:(BibItem *)aBI{
	NSString *myTitle = [self title];
	NSString *otherTitle = [aBI title];
	
    if ([NSString isEmptyString:myTitle]) {
		return ([NSString isEmptyString:otherTitle]) ? NSOrderedSame : NSOrderedDescending;
	} else if ([NSString isEmptyString:otherTitle]) {
		return NSOrderedAscending;
	}
	return [myTitle localizedCaseInsensitiveCompare:otherTitle];
}

- (NSComparisonResult)titleWithoutTeXCompare:(BibItem *)aBI{
	NSString *myTitle = [self title];
	NSString *otherTitle = [aBI title];
	
    if ([NSString isEmptyString:myTitle]) {
		return ([NSString isEmptyString:otherTitle]) ? NSOrderedSame : NSOrderedDescending;
	} else if ([NSString isEmptyString:otherTitle]) {
		return NSOrderedAscending;
	}
	return [myTitle localizedCaseInsensitiveNonTeXNonArticleCompare:otherTitle];
}

- (NSComparisonResult)booktitleWithoutTeXCompare:(BibItem *)aBI{
	NSString *myBooktitle = [self valueOfField:BDSKBooktitleString inherit:YES];
	NSString *otherBooktitle = [aBI valueOfField:BDSKBooktitleString inherit:YES];
	
    if ([NSString isEmptyString:myBooktitle]) {
		return ([NSString isEmptyString:otherBooktitle]) ? NSOrderedSame : NSOrderedDescending;
	} else if ([NSString isEmptyString:otherBooktitle]) {
		return NSOrderedAscending;
	}
	return [myBooktitle localizedCaseInsensitiveNonTeXNonArticleCompare:otherBooktitle];
}

- (NSComparisonResult)containerWithoutTeXCompare:(BibItem *)aBI{
	NSString *myContainer = [self container];
	NSString *otherContainer = [aBI container];
	
    if ([NSString isEmptyString:myContainer]) {
		return ([NSString isEmptyString:otherContainer]) ? NSOrderedSame : NSOrderedDescending;
	} else if ([NSString isEmptyString:otherContainer]) {
		return NSOrderedAscending;
	}
    return [myContainer localizedCaseInsensitiveNonTeXNonArticleCompare:otherContainer];
}

/* Helper method that treats all the special cases of nil values properly, by making them bigger than all other dates.	It is used by the comparison methods for creation, modification and publication date.
*/	
- (NSComparisonResult) compareCalendarDate:(NSCalendarDate*) myDate with:(NSCalendarDate*) otherDate {
	if (myDate == nil) {
		return (otherDate == nil) ? NSOrderedSame : NSOrderedDescending;
	} else if (otherDate == nil) {
		return NSOrderedAscending;
	}
	return [myDate compare:otherDate];
}

- (NSComparisonResult)dateCompare:(BibItem *)aBI{
	return [self compareCalendarDate:[self date] with:[aBI date]];
}

- (NSComparisonResult)createdDateCompare:(BibItem *)aBI{
	return [self compareCalendarDate:dateCreated with:[aBI dateCreated]];
}

- (NSComparisonResult)modDateCompare:(BibItem *)aBI{
	return [self compareCalendarDate:dateModified with:[aBI dateModified]];
}

/* Helper method that treats all the special cases of nil values properly, by making them bigger than all other dates.	It is used by the comparison methods for creation, modification and publication date.
*/	
- (NSComparisonResult)authorCompare:(BibItem *)aBI atIndex:(int)index{
    if ([[self pubAuthors] count] <= index) {
		return ([aBI numberOfAuthors] <= index) ? NSOrderedSame : NSOrderedDescending;
	} else if ([aBI numberOfAuthors] <= index) {
		return NSOrderedAscending;
	}
	// author's can't be empty strings, right?
	return [[self authorAtIndex:index] sortCompare:[aBI authorAtIndex:index]];
}

- (NSComparisonResult)auth1Compare:(BibItem *)aBI{
	return [self authorCompare:aBI atIndex:0];
}

- (NSComparisonResult)auth2Compare:(BibItem *)aBI{
	return [self authorCompare:aBI atIndex:1];
}

- (NSComparisonResult)auth3Compare:(BibItem *)aBI{
	return [self authorCompare:aBI atIndex:2];
}

- (NSComparisonResult)authorCompare:(BibItem *)aBI{
	NSString *myAuthor = [self bibTeXAuthorStringNormalized:YES];
	NSString *otherAuthor = [aBI bibTeXAuthorStringNormalized:YES];
	
    if ([NSString isEmptyString:myAuthor]) {
		return ([NSString isEmptyString:otherAuthor]) ? NSOrderedSame : NSOrderedDescending;
	} else if ([NSString isEmptyString:otherAuthor]) {
		return NSOrderedAscending;
	}
    return [myAuthor compare:otherAuthor];
}

- (NSComparisonResult)fileOrderCompare:(BibItem *)aBI{
    int aBIOrd = [aBI fileOrder];
    int myFileOrder = [self fileOrder];
    if (myFileOrder == 0) return NSOrderedDescending; //@@ file order for crossrefs - here is where we would change to accommodate new pubs in crossrefs...
    if (myFileOrder < aBIOrd) {
        return NSOrderedAscending;
    }
    if (myFileOrder > aBIOrd){
        return NSOrderedDescending;
    }else{
        return NSOrderedSame;
    }
}

// accessors for fileorder
- (int)fileOrder{
    return [[document publications] indexOfObjectIdenticalTo:self] + 1;
}

- (NSString *)fileType { return fileType; }

- (void)setFileType:(NSString *)someFileType {
    [bibLock lock];
    [someFileType retain];
    [fileType release];
    fileType = someFileType;
    [bibLock unlock];
}

#pragma mark Author Handling code

- (int)numberOfAuthors{
	return [self numberOfAuthorsInheriting:YES];
}

- (int)numberOfAuthorsInheriting:(BOOL)inherit{
    return [[self pubAuthorsInheriting:inherit] count];
}

- (void)addAuthorWithName:(NSString *)newAuthorName{
    NSEnumerator *presentAuthE = nil;
    BibAuthor *bibAuthor = nil;
    
    OFSimpleLock(&authorSimpleLock);
    presentAuthE = [pubAuthors objectEnumerator];
    while(bibAuthor = [presentAuthE nextObject]){
        if([[bibAuthor name] isEqualToString:newAuthorName]){ // @@ TODO: fuzzy author handling
            OFSimpleUnlock(&authorSimpleLock);
            return;
        }
    }
    [pubAuthors addObject:[BibAuthor authorWithName:newAuthorName andPub:self] usingLock:bibLock];
    OFSimpleUnlock(&authorSimpleLock);
}

- (NSArray *)pubAuthors{
	return [self pubAuthorsInheriting:YES];
}

- (NSArray *)pubAuthorsInheriting:(BOOL)inherit{
	BibItem *parent;
	
	if (inherit && [pubAuthors count] == 0 && 
		(parent = [self crossrefParent])) {
		return [parent pubAuthorsInheriting:NO];
	}
    return pubAuthors;
}

- (NSArray *)pubAuthorsAsStrings{
    OFSimpleLock(&authorSimpleLock);
    NSArray *pubAuthorArray = [self pubAuthors];
    NSEnumerator *authE = [pubAuthorArray objectEnumerator];
    NSMutableArray *array = [NSMutableArray arrayWithCapacity:[pubAuthorArray count]];
    BibAuthor *anAuthor;
    
    while(anAuthor = [authE nextObject])
        [array addObject:[anAuthor normalizedName]];
    OFSimpleUnlock(&authorSimpleLock);
    return array;
}

- (BibAuthor *)authorAtIndex:(int)index{ 
    return [self authorAtIndex:index inherit:YES];
}

- (BibAuthor *)authorAtIndex:(int)index inherit:(BOOL)inherit{ 
	NSMutableArray *auths = (NSMutableArray *)[self pubAuthorsInheriting:inherit];
	if ([auths count] > index)
        return [auths objectAtIndex:index usingLock:bibLock]; // not too nice. Is the lock necessary?
    else
        return nil;
}

- (void)setAuthorsFromBibtexString:(NSString *)aString{
    if ([self document])
		[[BDSKErrorObjectController sharedErrorObjectController] setDocumentForErrors:[self document]];
                
    char *str = nil;

    if ([NSString isEmptyString:aString]){
        [pubAuthors removeAllObjects];
        return;
    }
    
    // we're supposed to collapse whitespace before using bt_split_name, and author names with surrounding whitespace don't display in the table (probably for that reason)
    aString = [aString fastStringByCollapsingWhitespaceAndRemovingSurroundingWhitespace];

    str = (char *)[aString UTF8String];
    
    bt_stringlist *sl = nil;
    int i=0;
    [pubAuthors removeAllObjects];

    NSString *s;
    
    // used as an error description
    NSString *shortDescription = [[NSString alloc] initWithFormat:NSLocalizedString(@"reading authors string %@", @"need an string format specifier"), aString];
    
    sl = bt_split_list(str, "and", "BibTex Name", 0, (char *)[shortDescription UTF8String]);
    
    if (sl != nil) {
        for(i=0; i < sl->num_items; i++){
            if(sl->items[i] != nil){
                s = [[NSString alloc] initWithUTF8String:(sl->items[i])];
                [self addAuthorWithName:s];
                [s release];
            }
        }
        bt_free_list(sl); // hey! got to free the memory!
    }
    [shortDescription release];
      //  NSLog(@"%@", pubAuthors);
}

- (NSString *)bibTeXAuthorString{
    return [self bibTeXAuthorStringNormalized:NO inherit:YES];
}

- (NSString *)bibTeXAuthorStringNormalized:(BOOL)normalized{ // used for save operations; returns names as "von Last, Jr., First" if normalized is YES
	return [self bibTeXAuthorStringNormalized:normalized inherit:YES];
}

- (NSString *)bibTeXAuthorStringNormalized:(BOOL)normalized inherit:(BOOL)inherit{ // used for save operations; returns names as "von Last, Jr., First" if normalized is YES
	NSArray *auths = [self pubAuthorsInheriting:inherit];
    
	if([auths count] == 0)
        return @"";
	OFSimpleLock(&authorSimpleLock);
	NSEnumerator *authE = [auths objectEnumerator];
    BibAuthor *author;
	NSMutableArray *authNames = [NSMutableArray arrayWithCapacity:[auths count]];
	
	while(author = [authE nextObject]){
		[authNames addObject:(normalized ? [author normalizedName] : [author name])];
	}
	OFSimpleUnlock(&authorSimpleLock);
	return [authNames componentsJoinedByString:@" and "];
}

- (BibItem *)crossrefParent{
	NSString *key = [pubFields objectForKey:BDSKCrossrefString usingLock:bibLock];
	
	if ([NSString isEmptyString:key])
		return nil;
	
	return [document publicationForCiteKey:key];
}

// Container is an aspect of the BibItem that depends on the type of the item
// It is used only to have one column to show all these containers.
- (NSString *)container{
	NSString *c;
    NSString *type = [self type];
	
	if ( [type isEqualToString:@"inbook"]) {
	    c = [self valueOfField:BDSKTitleString];
	} else if ( [type isEqualToString:@"article"] ) {
		c = [self valueOfField:BDSKJournalString];
	} else if ( [type isEqualToString:@"incollection"] || 
				[type isEqualToString:@"inproceedings"] ||
				[type isEqualToString:@"conference"] ) {
		c = [self valueOfField:BDSKBooktitleString];
	} else if ( [type isEqualToString:@"commented"] ){
		c = [self valueOfField:BDSKVolumetitleString];
	} else if ( [type isEqualToString:@"book"] ){
		c = [self valueOfField:BDSKSeriesString];
	} else {
		c = @""; //Container is empty for non-container types
	}
	// Check to see if the field for Container was empty
	// They are optional for some types
	if (c == nil) {
		c = @"";
	}
    OBPOSTCONDITION(c != nil);
	return c;
}

// this is used for the main table and lower pane and for various window titles
- (NSString *)title{
    NSString *title = [self valueOfField:BDSKTitleString];
	if (title == nil) 
		title = @"";
	if ([[self type] isEqualToString:@"inbook"]) {
		NSString *chapter = [self valueOfField:BDSKChapterString];
		if (![NSString isEmptyString:chapter]) {
			title = [NSString stringWithFormat:NSLocalizedString(@"%@ (chapter of %@)", @"Chapter of inbook (chapter of Title)"), chapter, title];
		}
		NSString *pages = [self valueOfField:BDSKPagesString];
		if (![NSString isEmptyString:pages]) {
			title = [NSString stringWithFormat:NSLocalizedString(@"%@ (pp %@)", @"Title of inbook (pp Pages)"), title, pages];
		}
	}
    OBPOSTCONDITION(title != nil);
	return title;
}

- (NSString *)displayTitle{
	NSString *title = [self title];
	static NSString	*emptyTitle = nil;
	
	if ([NSString isEmptyString:title]) {
		if (emptyTitle == nil)
			emptyTitle = [NSLocalizedString(@"Empty Title", @"Empty Title") retain];
		title = emptyTitle;
	}
    OBPOSTCONDITION([NSString isEmptyString:title] == NO);
	return [title stringByRemovingTeX];
}

- (void)setDate: (NSCalendarDate *)newDate{
    [bibLock lock];
    [pubDate autorelease];
    pubDate = [newDate copy];
    [bibLock unlock];
    
}

- (NSCalendarDate *)date{
    return [self dateInheriting:YES];
}

- (NSCalendarDate *)dateInheriting:(BOOL)inherit{
    BibItem *parent;
	
	if(inherit && pubDate == nil && (parent = [self crossrefParent])) {
		return [parent dateInheriting:NO];
	}
	return pubDate;
}

- (NSCalendarDate *)dateCreated {
    return dateCreated;
}

- (void)setDateCreated:(NSCalendarDate *)newDateCreated {
    [bibLock lock];
    if (dateCreated != newDateCreated) {
        [dateCreated release];
        dateCreated = [newDateCreated copy];
    }
    [bibLock unlock];
}

- (NSCalendarDate *)dateModified {
    return dateModified;
}

- (void)setDateModified:(NSCalendarDate *)newDateModified {
    [bibLock lock];
    if (dateModified != newDateModified) {
        [dateModified release];
        dateModified = [newDateModified copy];
    }
    [bibLock unlock];
}

- (NSString *)calendarDateDescription{
	return [[self date] descriptionWithCalendarFormat:@"%B %Y"];
}

- (NSString *)calendarDateModifiedDescription{
	NSString *shortDateFormatString = [[NSUserDefaults standardUserDefaults] stringForKey:NSShortDateFormatString];
    return [[self dateModified] descriptionWithCalendarFormat:shortDateFormatString];
}

- (NSString *)calendarDateCreatedDescription{
	NSString *shortDateFormatString = [[NSUserDefaults standardUserDefaults] stringForKey:NSShortDateFormatString];
	return [[self dateCreated] descriptionWithCalendarFormat:shortDateFormatString];
}

- (void)setPubType: (NSString *)newType{
    newType = [newType lowercaseString];
    OBASSERT(![NSString isEmptyString:newType]);
	if(![pubType isEqualToString:newType]){
		[bibLock lock];
		[pubType release];
		pubType = [newType copy];
		[bibLock unlock];
		
		[self makeType];
	}
}

- (void)setType:(NSString *)newType{
    [self setType:newType withModDate:[NSCalendarDate date]];
}

- (void)setType:(NSString *)newType withModDate:(NSCalendarDate *)date{
    if (pubType && [pubType isEqualToString:newType])
		return;
	
	if ([self undoManager]) {
		[[[self undoManager] prepareWithInvocationTarget:self] setType:pubType 
															  withModDate:[self dateModified]];
    }
	
	[self setPubType:newType];
	
	if (date != nil) {
		[pubFields setObject:[date description] forKey:BDSKDateModifiedString usingLock:bibLock];
	} else {
		[pubFields removeObjectForKey:BDSKDateModifiedString usingLock:bibLock];
	}
	[self updateMetadataForKey:BDSKTypeString];
		
    NSDictionary *notifInfo = [NSDictionary dictionaryWithObjectsAndKeys:pubType, @"value", BDSKTypeString, @"key", @"Change", @"type", document, @"document", nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:BDSKBibItemChangedNotification
														object:self
													  userInfo:notifInfo];
}

- (NSString *)type{
    return pubType;
}

- (unsigned int)rating{
	return [self ratingValueOfField:BDSKRatingString];
}

- (void)setRead:(BOOL)read{
    [self setBooleanField:BDSKReadString toValue:read];
}

- (void)setRating:(unsigned int)rating{
    [self setRatingField:BDSKRatingString toValue:rating];
}

- (void)setRatingField:(NSString *)field toValue:(unsigned int)rating{
	if (rating > 5)
		rating = 5;
	if(![[pubFields allKeys] containsObject:field])
		[self addField:field];
	[self setField:field toValue:[NSString stringWithFormat:@"%i", rating]];
}

- (int)ratingValueOfField:(NSString *)field{
    return [[pubFields objectForKey:field usingLock:bibLock] intValue];
}

- (BOOL)read{
    return [self boolValueOfField:BDSKReadString];
}

- (BOOL)boolValueOfField:(NSString *)field{
    // stored as a string
	return [(NSString *)[pubFields objectForKey:field usingLock:bibLock] booleanValue];
}

- (void)setBooleanField:(NSString *)field toValue:(BOOL)boolValue{
	if(![[pubFields allKeys] containsObject:field])
		[self addField:field];
	[self setField:field toValue:[NSString stringWithBool:boolValue]];
}

- (NSString *)valueOfGenericField:(NSString *)field {
	return [self valueOfGenericField:field inherit:YES];
}

- (NSString *)valueOfGenericField:(NSString *)field inherit:(BOOL)inherit {
	OFPreferenceWrapper *pw = [OFPreferenceWrapper sharedPreferenceWrapper];
		
	if([[pw stringArrayForKey:BDSKRatingFieldsKey] containsObject:field]){
		return [NSString stringWithFormat:@"%i", [self ratingValueOfField:field]];
	}else if([[pw stringArrayForKey:BDSKBooleanFieldsKey] containsObject:field]){
		return [NSString stringWithBool:[self boolValueOfField:field]];
	}else if([field isEqualToString:BDSKTypeString]){
		return [self type];
	}else if([field isEqualToString:BDSKCiteKeyString]){
		return [self citeKey];
	}else{
		return [self valueOfField:field inherit:inherit];
    }
}

- (void)setGenericField:(NSString *)field toValue:(NSString *)value{
	OFPreferenceWrapper *pw = [OFPreferenceWrapper sharedPreferenceWrapper];
	
	if([[pw stringArrayForKey:BDSKBooleanFieldsKey] containsObject:field]){
		[self setRatingField:field toValue:[value intValue]];
	}else if([[pw stringArrayForKey:BDSKRatingFieldsKey] containsObject:field]){
		[self setBooleanField:field toValue:[value booleanValue]];
	}else if([field isEqualToString:BDSKTypeString]){
		[self setType:value];
	}else if([field isEqualToString:BDSKCiteKeyString]){
		[self setCiteKey:value];
	}else{
		if(![[pubFields allKeys] containsObject:field])
			[self addField:field];
		[self setField:field toValue:value];
	}
}

- (void)setHasBeenEdited:(BOOL)yn{
    //NSLog(@"set has been edited %@", (yn)?@"YES":@"NO");
    hasBeenEdited = yn;
}

- (BOOL)hasBeenEdited{
    return hasBeenEdited;
}

- (NSString *)suggestedCiteKey
{
	NSString *citeKeyFormat = [[OFPreferenceWrapper sharedPreferenceWrapper] objectForKey:BDSKCiteKeyFormatKey];
	NSString *ck = [[BDSKFormatParser sharedParser] parseFormat:citeKeyFormat forField:BDSKCiteKeyString ofItem:self];
	if ([[OFPreferenceWrapper sharedPreferenceWrapper] boolForKey:BDSKCiteKeyLowercaseKey]) {
		ck = [ck lowercaseString];
	}
	return ck;
}

- (BOOL)canSetCiteKey
{
	if ([[NSApp delegate] requiredFieldsForCiteKey] == nil)
		return NO;
	
	NSEnumerator *fEnum = [[[NSApp delegate] requiredFieldsForCiteKey] objectEnumerator];
	NSString *fieldName;
	NSString *fieldValue = [self citeKey];
	
	if (![NSString isEmptyString:fieldValue] && ![fieldValue isEqualToString:@"cite-key"]) {
		return NO;
	}
	while (fieldName = [fEnum nextObject]) {
		fieldValue = [self valueOfField:fieldName];
		if ([NSString isEmptyString:fieldValue]) {
			return NO;
		}
	}
	return YES;
}

- (void)setCiteKey:(NSString *)newCiteKey{
    [self setCiteKey:newCiteKey withModDate:[NSCalendarDate date]];
}

- (void)setCiteKey:(NSString *)newCiteKey withModDate:(NSCalendarDate *)date{
    if ([self undoManager]) {
		[[[self undoManager] prepareWithInvocationTarget:self] setCiteKey:citeKey 
															  withModDate:[self dateModified]];
    }
    NSString *oldCiteKey = [citeKey retain];
	
    [self setCiteKeyString:newCiteKey];
	if (date != nil) {
		[pubFields setObject:[date description] forKey:BDSKDateModifiedString usingLock:bibLock];
	} else {
		[pubFields removeObjectForKey:BDSKDateModifiedString usingLock:bibLock];
	}
	[self updateMetadataForKey:BDSKCiteKeyString];
		
    NSDictionary *notifInfo = [NSDictionary dictionaryWithObjectsAndKeys:citeKey, @"value", BDSKCiteKeyString, @"key", @"Change", @"type", document, @"document", oldCiteKey, @"oldCiteKey", nil];

    if(floor(NSAppKitVersionNumber) <= NSAppKitVersionNumber10_3){}
    else
        [[NSFileManager defaultManager] removeSpotlightCacheForItemNamed:oldCiteKey];
    
    [oldCiteKey release];
    [[NSNotificationCenter defaultCenter] postNotificationName:BDSKBibItemChangedNotification
														object:self
													  userInfo:notifInfo];
}

- (void)setCiteKeyString:(NSString *)newCiteKey{
    [bibLock lock];
    [citeKey autorelease];
    citeKey = [newCiteKey copy];
    [bibLock unlock];
}

- (NSString *)citeKey{
    return (citeKey != nil ? citeKey : @"");
}

- (void)setPubFields: (NSDictionary *)newFields{
    if(newFields != pubFields){
        [bibLock lock];
        [pubFields release];
        pubFields = [newFields mutableCopy];
        [bibLock unlock];
        [self updateMetadataForKey:@"All Fields"];
    }
}

- (void)setFields: (NSDictionary *)newFields{
	if(![newFields isEqualToDictionary:pubFields]){
		if ([self undoManager]) {
			[[[self undoManager] prepareWithInvocationTarget:self] setFields:pubFields];
		}
		
		[self setPubFields:newFields];
		
		NSDictionary *notifInfo = [NSDictionary dictionaryWithObjectsAndKeys:@"Add/Del Fields", @"type", document, @"document", nil]; // cmh: maybe not the best info, but handled correctly
		[[NSNotificationCenter defaultCenter] postNotificationName:BDSKBibItemChangedNotification
															object:self
														  userInfo:notifInfo];
    }
}

- (void)copyComplexStringValues{
	NSEnumerator *fEnum = [pubFields keyEnumerator];
	NSString *field;
	NSString *value;
	BDSKComplexString *complexValue;
	
	while (field = [fEnum nextObject]) {
		value = [pubFields objectForKey:field usingLock:bibLock];
		if ([value isComplex]) {
			complexValue = [(BDSKComplexString*)value copy];
			[complexValue setMacroResolver:[self document]];
			[pubFields setObject:complexValue forKey:field usingLock:bibLock];
            [complexValue release];
		}
	}
}

- (void)updateComplexStringValues{
	NSEnumerator *fEnum = [pubFields keyEnumerator];
	NSString *field;
	NSString *value;
	
	while (field = [fEnum nextObject]) {
		value = [pubFields objectForKey:field usingLock:bibLock];
		if ([value isComplex]) {
			[(BDSKComplexString*)value setMacroResolver:[self document]];
		}
	}
}

- (void)updateMetadataForKey:(NSString *)key{
    
	[self setHasBeenEdited:YES];

    if (key == nil || [@"All Fields" isEqualToString:key] || [BDSKAuthorString isEqualToString:key] || [BDSKEditorString isEqualToString:key]) {
		if(![NSString isEmptyString:[pubFields objectForKey: BDSKAuthorString usingLock:bibLock]])
		{
			[self setAuthorsFromBibtexString:[pubFields objectForKey: BDSKAuthorString usingLock:bibLock]];
		}else{
			[self setAuthorsFromBibtexString:[pubFields objectForKey: BDSKEditorString usingLock:bibLock]]; // or what else?
		}
	}
	
	if([BDSKLocalUrlString isEqualToString:key]){
		[self setNeedsToBeFiled:NO];
        // If the Finder comment from this file has a useful URL and our BibItem has an empty remote URL field, use the Finder comment as remote URL.  Do this before autofiling the paper, since we know the path to the file now.
        if(MDItemCreate != NULL){
            MDItemRef mdItem = NULL;
            if(mdItem = MDItemCreate(kCFAllocatorDefault, (CFStringRef)[self localFilePathForField:key])){
                NSString *remoteURLString = (NSString *)MDItemCopyAttribute(mdItem, kMDItemFinderComment);
                CFRelease(mdItem);
                if(remoteURLString && [NSURL URLWithString:remoteURLString]!= nil && [self remoteURL] == nil)
                    [self setField:BDSKUrlString toValue:remoteURLString];
                [remoteURLString release];
            }
        }
	}
	
	if([BDSKTitleString isEqualToString:key] &&
	   [[OFPreferenceWrapper sharedPreferenceWrapper] boolForKey:BDSKDuplicateBooktitleKey] &&
	   [[[OFPreferenceWrapper sharedPreferenceWrapper] arrayForKey:BDSKTypesForDuplicateBooktitleKey] containsObject:[self type]]){
		[self duplicateTitleToBooktitleOverwriting:[[OFPreferenceWrapper sharedPreferenceWrapper] boolForKey:BDSKForceDuplicateBooktitleKey]];
	}
 	
	// invalidate the cached groups; they are rebuild when needed
	if([@"All Fields" isEqualToString:key]){
		[groups removeAllObjects];
	}else if(key != nil){
		[groups removeObjectForKey:key];
	}
	
     // re-call make type to make sure we still have all the appropriate bibtex defined fields...
     // but only if we have set the full pubFields array, as we should not be able to remove necessary fields.
 	if([@"All Fields" isEqualToString:key]){
 		[self makeType];
 	}
     
    NSCalendarDate *theDate = nil;
    
    if (key == nil || [@"All Fields" isEqualToString:key] || [BDSKYearString isEqualToString:key] || [BDSKMonthString isEqualToString:key]) {
		NSString *yearValue = [pubFields objectForKey:BDSKYearString usingLock:bibLock];
		if (![NSString isEmptyString:yearValue]) {
			NSString *monthValue = [pubFields objectForKey:BDSKMonthString usingLock:bibLock];
			if([monthValue isComplex])
				monthValue = [(BDSKStringNode *)[[(BDSKComplexString *)monthValue nodes] objectAtIndex:0] value];
			if (!monthValue) monthValue = @"";
			NSString *dateStr = [NSString stringWithFormat:@"%@-15-%@", monthValue, yearValue];
            NSDate *date = [[NSDate alloc] initWithMonthDayYearString:dateStr];
            theDate = [[NSCalendarDate alloc] initWithString:[date description]];
            [date release];
			[self setDate:theDate];
            [theDate release];
		}else{
			[self setDate:nil];    // nil means we don't have a good date.
		}
	}
	
    if (key == nil || [@"All Fields" isEqualToString:key] || [BDSKDateCreatedString isEqualToString:key]) {
		NSString *dateCreatedValue = [pubFields objectForKey:BDSKDateCreatedString usingLock:bibLock];
		if (![NSString isEmptyString:dateCreatedValue]) {
            theDate = [[NSCalendarDate alloc] initWithNaturalLanguageString:dateCreatedValue];
			[self setDateCreated:theDate];
            [theDate release];
		}else{
			[self setDateCreated:nil];
		}
	}
	
    // we shouldn't check for the key here, as the DateModified can be set with any key
    NSString *dateModValue = [pubFields objectForKey:BDSKDateModifiedString usingLock:bibLock];
    if (![NSString isEmptyString:dateModValue]) {
        // NSLog(@"updating date %@", dateModValue);
        theDate = [[NSCalendarDate alloc] initWithNaturalLanguageString:dateModValue];
        [self setDateModified:theDate];
        [theDate release];
    }else{
        [self setDateModified:nil];
    }
}

- (void)setField: (NSString *)key toValue: (NSString *)value{
	[self setField:key toValue:value withModDate:[NSCalendarDate date]];
}

- (void)setField:(NSString *)key toValue:(NSString *)value withModDate:(NSCalendarDate *)date{

    OBPRECONDITION(value != nil);
    OBPRECONDITION(key != nil);
    id oldValue = nil;
    
    // @@ The old value may be nil, indicating that this field doesn't exist yet.  Should we use addField: first in that case?
    // use a copy of the old value, since this may be a mutable value
    oldValue = [[pubFields objectForKey:key usingLock:bibLock] copy];
	if ([self undoManager] && oldValue != nil) {
        OBPRECONDITION(oldValue != nil);
		NSCalendarDate *oldModDate = [self dateModified];
		
		[[[self undoManager] prepareWithInvocationTarget:self] setField:key 
														 toValue:oldValue
													 withModDate:oldModDate];
	}
    	
    [pubFields setObject:value forKey:key usingLock:bibLock];
	if (date != nil) {
		[pubFields setObject:[date description] forKey:BDSKDateModifiedString usingLock:bibLock];
	} else {
		[pubFields removeObjectForKey:BDSKDateModifiedString usingLock:bibLock];
	}
	[self updateMetadataForKey:key];
	
	NSMutableDictionary *notifInfo = [NSMutableDictionary dictionaryWithObjectsAndKeys:value, @"value", key, @"key", @"Change", @"type",document, @"document",nil];
    if(oldValue) [notifInfo setObject:oldValue forKey:@"oldValue"];
    [oldValue release];
    
	[[NSNotificationCenter defaultCenter] postNotificationName:BDSKBibItemChangedNotification
														object:self
													  userInfo:notifInfo];
    // to allow autocomplete:
	[[NSApp delegate] addString:value forCompletionEntry:key];
}

// for 10.2
- (id)handleQueryWithUnboundKey:(NSString *)key{
    return [self valueForUndefinedKey:key];
}

- (id)valueForUndefinedKey:(NSString *)key{
    id obj = [pubFields objectForKey:key usingLock:bibLock];
    if (obj != nil){
        return obj;
    }else{
        // handle 10.2
        if ([super respondsToSelector:@selector(valueForUndefinedKey:)]){
            return [super valueForUndefinedKey:key];
        }else{
            return [super handleQueryWithUnboundKey:key];
        }
    }
}

- (NSString *)valueOfField: (NSString *)key{
	return [self valueOfField:key inherit:YES];
}

- (NSString *)valueOfField: (NSString *)key inherit: (BOOL)inherit{
    NSString* value = [pubFields objectForKey:key usingLock:bibLock];
	
	if (inherit && [NSString isEmptyString:value]) {
		BibItem *parent = [self crossrefParent];
		if (parent) {
			NSString *parentValue = [parent valueOfField:key inherit:NO];
			if (![NSString isEmptyString:parentValue])
				return [NSString stringWithInheritedValue:parentValue];
		}
	}
	
	return value;
}

- (NSString *)acronymValueOfField:(NSString *)key ignore:(unsigned int)ignoreLength{
    NSMutableString *result = [NSMutableString string];
    NSArray *allComponents = [[self valueOfField:key] componentsSeparatedByString:@" "]; // single whitespace
    NSEnumerator *e = [allComponents objectEnumerator];
    NSString *component = nil;
	unsigned int currentIgnoreLength;
    
    while(component = [e nextObject]){
		currentIgnoreLength = ignoreLength;
        if(![component isEqualToString:@""]) // stringByTrimmingCharactersInSet will choke on an empty string
            component = [component stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
		if([component length] > 1 && [component characterAtIndex:[component length] - 1] == '.')
			currentIgnoreLength = 0;
		if(![component isEqualToString:@""])
            component = [component stringByTrimmingCharactersInSet:[[NSCharacterSet alphanumericCharacterSet] invertedSet]];
		if([component length] > currentIgnoreLength){
            [result appendString:[[component substringToIndex:1] uppercaseString]];
        }
    }
    return result;
}

- (void)addField:(NSString *)key{
	[self addField:key withModDate:[NSCalendarDate date]];
}

- (void)addField:(NSString *)key withModDate:(NSCalendarDate *)date{
	if ([self undoManager]) {
		[[[self undoManager] prepareWithInvocationTarget:self] removeField:key
														withModDate:[self dateModified]];
	}
	
	NSString *msg = [NSString stringWithFormat:@"%@ %@",
		NSLocalizedString(@"Add data for field:", @""), key];
	[self setField:key toValue:msg];
	
	if (date != nil) {
		[pubFields setObject:[date description] forKey:BDSKDateModifiedString usingLock:bibLock];
	} else {
		[pubFields removeObjectForKey:BDSKDateModifiedString usingLock:bibLock];
	}
	[self updateMetadataForKey:key];
	
	NSDictionary *notifInfo = [NSDictionary dictionaryWithObjectsAndKeys:@"Add/Del Field", @"type",document, @"document", nil];
	[[NSNotificationCenter defaultCenter] postNotificationName:BDSKBibItemChangedNotification
														object:self
													  userInfo:notifInfo];

}

- (void)removeField: (NSString *)key{
	[self removeField:key withModDate:[NSCalendarDate date]];
}

- (void)removeField: (NSString *)key withModDate:(NSCalendarDate *)date{
	
    OBPRECONDITION(key != nil);
    
	if ([self undoManager]) {
        if(![NSString isEmptyString:[pubFields objectForKey:key]])
            // this will ensure that the current value can be restored when the user deletes a non-empty field
            [self setField:key toValue:@""];
        
		[[[self undoManager] prepareWithInvocationTarget:self] addField:key
                                                            withModDate:[self dateModified]];
	}
	
    [pubFields removeObjectForKey:key usingLock:bibLock];
	
	if (date != nil) {
		[pubFields setObject:[date description] forKey:BDSKDateModifiedString usingLock:bibLock];
	} else {
		[pubFields removeObjectForKey:BDSKDateModifiedString usingLock:bibLock];
	}
	[self updateMetadataForKey:key];

	NSDictionary *notifInfo = [NSDictionary dictionaryWithObjectsAndKeys:@"Add/Del Field", @"type",document, @"document", nil];
	[[NSNotificationCenter defaultCenter] postNotificationName:BDSKBibItemChangedNotification
														object:self
													  userInfo:notifInfo];
	
}

- (NSMutableDictionary *)pubFields{
    return pubFields;
}

- (NSData *)RTFValue{
    NSAttributedString *aStr = [self attributedStringValue];
    return [aStr RTFFromRange:NSMakeRange(0,[aStr length]) documentAttributes:nil];
}

- (NSAttributedString *)attributedStringValue{
    NSString *key;
    NSEnumerator *e = [[[pubFields allKeysUsingLock:bibLock] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)] objectEnumerator];
    NSDictionary *cachedFonts = [(BDSKFontManager *)[BDSKFontManager sharedFontManager] cachedFontsForPreviewPane];

    NSDictionary *titleAttributes =
        [[NSDictionary alloc]  initWithObjectsAndKeys:[cachedFonts objectForKey:@"Title"], NSFontAttributeName, 
												      keyParagraphStyle, NSParagraphStyleAttributeName, nil];

    NSDictionary *typeAttributes =
        [[NSDictionary alloc]  initWithObjectsAndKeys:[cachedFonts objectForKey:@"Type"], NSFontAttributeName, 
		                                              [NSColor colorWithCalibratedWhite:0.4 alpha:1.0], NSForegroundColorAttributeName, nil];

    NSDictionary *keyAttributes =
        [[NSDictionary alloc]  initWithObjectsAndKeys:[cachedFonts objectForKey:@"Key"], NSFontAttributeName, 
												      keyParagraphStyle, NSParagraphStyleAttributeName, nil];

    NSDictionary *bodyAttributes =
        [[NSDictionary alloc]  initWithObjectsAndKeys:[cachedFonts objectForKey:@"Body"], NSFontAttributeName, 
												      bodyParagraphStyle, NSParagraphStyleAttributeName, nil];

    NSMutableAttributedString* reqStr = [[NSMutableAttributedString alloc] init];
    NSMutableAttributedString* nonReqStr = [[NSMutableAttributedString alloc] init];
	NSAttributedString *valueStr;

	NSSet *reqKeys = [[NSSet alloc] initWithArray:[[BibTypeManager sharedManager] requiredFieldsForType:[self type]]];

    static NSDateFormatter *dateFormatter = nil;
    if(dateFormatter == nil)
        dateFormatter = [[NSDateFormatter alloc] initWithDateFormat:[[NSUserDefaults standardUserDefaults] objectForKey:NSDateFormatString]
															 allowNaturalLanguage:NO];
    
    [reqStr appendAttributedString:[[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@\n",[self citeKey]]
                                                                    attributes:typeAttributes] autorelease]];

    [reqStr appendAttributedString:[self attributedStringByParsingTeX:[self title] inField:@"Title" defaultStyle:keyParagraphStyle collapse:YES]];
    

    [reqStr appendAttributedString:[[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@" (%@)\n",[self type]] 
																	attributes:typeAttributes] autorelease]];

    NSCalendarDate *date = nil;
    
    while(key = [e nextObject]){
        if(![[self valueOfField:key] isEqualToString:@""] &&
           ![key isEqualToString:BDSKTitleString]){
			
			valueStr = nil;
			
			if([key isEqualToString:BDSKDateCreatedString] && (date = [self dateCreated])){
                valueStr = [[NSAttributedString alloc] initWithString:[dateFormatter stringForObjectValue:date]
                                                           attributes:bodyAttributes];
                
            }else if([key isEqualToString:BDSKDateModifiedString] && (date = [self dateModified])){                
                valueStr = [[NSAttributedString alloc] initWithString:[dateFormatter stringForObjectValue:date]
                                                           attributes:bodyAttributes];
                
			}else if([key isEqualToString:BDSKAuthorString]){
				NSString *authors = [[self bibTeXAuthorString] stringByRemovingCurlyBraces];
                
				valueStr = [[NSAttributedString alloc] initWithString:authors
														   attributes:bodyAttributes];
                
			}else if([[[OFPreferenceWrapper sharedPreferenceWrapper] stringArrayForKey:BDSKLocalFileFieldsKey] containsObject:key]){
				NSString *path = [[self localFilePathForField:key] stringByAbbreviatingWithTildeInPath];
                
				valueStr = [[NSAttributedString alloc] initWithString:path
														   attributes:bodyAttributes];
			
			}else if([key isEqualToString:BDSKRatingString]){
				int rating = [[self valueOfField:BDSKRatingString inherit:NO] intValue];
                NSMutableString *ratingString = [[NSMutableString alloc] init];
				int i = 0;
				
				while (i++ < rating)
					[ratingString appendFormat:@"%C", 0x2789 + i];
				
				valueStr = [[NSAttributedString alloc] initWithString:ratingString
														   attributes:bodyAttributes];
                
			}else{
				BOOL notAnnoteOrAbstract = !([key isEqualToString:BDSKAnnoteString] || [key isEqualToString:BDSKAbstractString]);
				
				valueStr = [[self attributedStringByParsingTeX:[self valueOfField:key inherit:notAnnoteOrAbstract] inField:@"Body" defaultStyle:bodyParagraphStyle collapse:notAnnoteOrAbstract] retain];
			}
			
			if(valueStr){
				if([reqKeys containsObject:key]){
					
					[reqStr appendAttributedString:[[[NSAttributedString alloc] initWithString:key
																					attributes:keyAttributes] autorelease]];
					[reqStr appendString:@"\n"];
					[reqStr appendAttributedString:valueStr];
					[reqStr appendString:@"\n"];
					
				}else{
					
					[nonReqStr appendAttributedString:[[[NSAttributedString alloc] initWithString:key
																					   attributes:keyAttributes] autorelease]];
					[nonReqStr appendString:@"\n"];
					[nonReqStr appendAttributedString:valueStr];
					[nonReqStr appendString:@"\n"];
					
					
				}
				[valueStr release];
			}
        }
    }

    // now put them together
	[reqStr appendAttributedString:nonReqStr];
	[reqStr appendAttributedString:[[[NSAttributedString alloc] initWithString:@" "
                                                                  attributes:nil] autorelease]];
	[nonReqStr release];
    [titleAttributes release];
    [typeAttributes release];
    [keyAttributes release];
    [bodyAttributes release];
    [reqKeys release];
    return 	[reqStr autorelease];
}

- (NSAttributedString *)attributedStringByParsingTeX:(NSString *)texStr inField:(NSString *)field defaultStyle:(NSParagraphStyle *)defaultStyle collapse:(BOOL)collapse{
    
    // get rid of whitespace if we have to; we can't use this on the attributed string's content store, though
    if(collapse){
        if([texStr isComplex])
            texStr = [NSString stringWithString:texStr];
        texStr = [texStr fastStringByCollapsingWhitespaceAndRemovingSurroundingWhitespace];
    }
    
    NSString *texStyle = nil;    
    BDSKFontManager *fontManager = (BDSKFontManager *)[BDSKFontManager sharedFontManager];
    NSFont *font = [[fontManager cachedFontsForPreviewPane] objectForKey:field];
    
    // set up the attributed string now, so we can start working with its character contents
    NSDictionary *attrs = [[NSDictionary alloc] initWithObjectsAndKeys:font, NSFontAttributeName, defaultStyle, NSParagraphStyleAttributeName, nil];
    NSMutableAttributedString *mas = [[NSMutableAttributedString alloc] initWithString:texStr attributes:attrs]; // set the whole thing up with default attrs
    [attrs release];

    NSMutableString *mutableString = [mas mutableString];
        
    NSRange searchRange = NSMakeRange(0, [mutableString length]); // starting value; changes as we change the string
    NSRange cmdRange;
    NSRange styleRange;
    unsigned startLoc; // starting character index to apply tex attributes
    unsigned endLoc;   // ending index to apply tex attributes
    
    while( (cmdRange = [mutableString rangeOfTeXCommandInRange:searchRange]).location != NSNotFound){
        
        // find the command
        texStyle = [mutableString substringWithRange:cmdRange];
        //NSLog(@"cmd is %@", texStyle);
        font = [fontManager convertFont:font
                            toHaveTrait:([fontManager fontTraitMaskForTeXStyle:texStyle])];
        //NSLog(@"using font %@", font);
        attrs = [[NSDictionary alloc] initWithObjectsAndKeys:font, NSFontAttributeName, defaultStyle, NSParagraphStyleAttributeName, nil];
        
        // delete the command, now that we know what it was
        [mutableString deleteCharactersInRange:cmdRange];
        
        // what does the command affect?
        startLoc = cmdRange.location;  // remember, we deleted our command, but not the brace
        if([mutableString characterAtIndex:startLoc] == '{' && (endLoc = [mutableString indexOfRightBraceMatchingLeftBraceAtIndex:startLoc]) != NSNotFound){
            styleRange = NSMakeRange(startLoc + 1, (endLoc - startLoc - 1));
            //NSLog(@"applying to %@", [mutableString substringWithRange:styleRange]);
            [mas setAttributes:attrs range:styleRange];
        }
        // new range, since we've altered the string
        searchRange = NSMakeRange(startLoc, [mutableString length] - startLoc);
        [attrs release];
    }
    
    static NSCharacterSet *braceSet = nil;
    if(braceSet == nil)
        braceSet = [[NSCharacterSet characterSetWithCharactersInString:@"}{"] retain];

    [mutableString deleteCharactersInCharacterSet:braceSet];
        
    return [mas autorelease];
}

- (NSString *)RISStringValue{
    NSString *k;
    NSString *v;
    NSMutableString *s = [[[NSMutableString alloc] init] autorelease];
    NSMutableArray *keys = [[pubFields allKeysUsingLock:bibLock] mutableCopy];
	BOOL hasAU = [keys containsObject:@"AU"];
    [keys sortUsingSelector:@selector(caseInsensitiveCompare:)];
    [keys removeObject:BDSKDateCreatedString];
    [keys removeObject:BDSKDateModifiedString];
    [keys removeObject:BDSKLocalUrlString];

    BibTypeManager *btm = [BibTypeManager sharedManager];
    
    // get the type, which may exist in pubFields if this was originally an RIS import; we must have only _one_ TY field,
    // since they mark the beginning of each entry
    NSString *risType = nil;
    if(risType = [pubFields objectForKey:@"TY" usingLock:bibLock])
        [keys removeObject:@"TY"];
    else if(risType = [pubFields objectForKey:@"PT" usingLock:bibLock]) // Medline RIS
        [keys removeObject:@"PT"];
    else
        risType = [btm RISTypeForBibTeXType:[self type]];
    
    // enumerate the remaining keys
    NSEnumerator *e = [keys objectEnumerator];
	NSString *tag;
	NSArray *auths;
	[keys release];
    
	if([keys containsObject:@"PMID"]){
		[s appendFormat:@"PMID- %@\n", risType];
        [keys removeObject:@"PMID"];
	}
	
    [s appendFormat:@"TY  - %@\n", risType];
    
    while(k = [e nextObject]){
		tag = [btm RISTagForBibTeXFieldName:k];
        v = [pubFields objectForKey:k usingLock:bibLock];
        NSString *valString;
        
        if([k isEqualToString:BDSKAuthorString]){
			// if we also have an AU field, we use the FAU tag, otherwise we use AU
			tag = (hasAU ? @"FAU" : @"AU ");
            auths = [v componentsSeparatedByString:@" and "];
			v = [auths componentsJoinedByString:[NSString stringWithFormat:@"\n%@ - ", tag]];
        }else if([k isEqualToString:@"AU"] || [k isEqualToString:BDSKEditorString]){
            auths = [v componentsSeparatedByString:@" and "];
			v = [auths componentsJoinedByString:[NSString stringWithFormat:@"\n%@  - ", tag]];
        }else if([k isEqualToString:BDSKKeywordsString]){
			NSMutableArray *arr = [NSMutableArray arrayWithCapacity:1];
			if([v rangeOfCharacterFromSet:[[NSApp delegate] autoCompletePunctuationCharacterSet]].location != NSNotFound) {
				NSScanner *wordScanner = [NSScanner scannerWithString:v];
				[wordScanner setCharactersToBeSkipped:nil];
				
				while(![wordScanner isAtEnd]) {
					if([wordScanner scanUpToCharactersFromSet:[[NSApp delegate] autoCompletePunctuationCharacterSet] intoString:&v])
						[arr addObject:v];
					[wordScanner scanCharactersFromSet:[[NSApp delegate] autoCompletePunctuationCharacterSet] intoString:nil];
				}
				v = [arr componentsJoinedByString:[NSString stringWithFormat:@"\n%@  - ", tag]];
			}
        }
        
		if(![v isEqualToString:@""]){
			[s appendString:tag];
			if([tag length] == 2)
				[s appendString:@"  - "];
			else if([tag length] == 3)
				[s appendString:@" - "];
			else
				[s appendString:@"- "];
            [s appendString:[v stringByRemovingTeX]]; // this won't help with math, but removing $^_ is probably not a good idea
			[s appendString:@"\n"];
		}
    }
    [s appendString:@"ER  - \n"];
    return s;
}

#pragma mark BibTeX strings

- (NSString *)bibTeXStringByExpandingMacros:(BOOL)expand dropInternal:(BOOL)drop texify:(BOOL)shouldTeXify{
	OFPreferenceWrapper *pw = [OFPreferenceWrapper sharedPreferenceWrapper];
	NSMutableSet *knownKeys = nil;
	NSMutableSet *urlKeys = nil;
	NSString *k;
    NSString *v;
    NSMutableString *s = [[[NSMutableString alloc] init] autorelease];
    NSMutableArray *keys = [[pubFields allKeysUsingLock:bibLock] mutableCopy];
	NSEnumerator *e;
    
    NSString *type = [self type];
    NSAssert1(type != nil, @"Tried to use a nil pubtype in %@.  You will need to quit and relaunch BibDesk after fixing the error manually.", self );
	[keys sortUsingSelector:@selector(caseInsensitiveCompare:)];
	if ([pw boolForKey:BDSKSaveAnnoteAndAbstractAtEndOfItemKey]) {
		NSArray *finalKeys = [NSArray arrayWithObjects:BDSKAbstractString, BDSKAnnoteString, nil];
		[keys removeObjectsInArray:finalKeys]; // make sure these fields are at the end, as they can be long
		[keys addObjectsFromArray:finalKeys];
	}
	if (drop) {
		BibTypeManager *btm = [BibTypeManager sharedManager];
        knownKeys = [[NSMutableSet alloc] initWithCapacity:14];
		[knownKeys addObjectsFromArray:[btm requiredFieldsForType:type]];
		[knownKeys addObjectsFromArray:[btm optionalFieldsForType:type]];

        // @@ @other types can end up with no keys, so -[BibItem isEqual:] ends up comparing [@"@other{citekey}" isEqualToString:@"@other{citekey}"]; we may want to change the equality test at some point, but we'll disallow empty items, since they are essentially meaningless
        if([knownKeys count] == 0)
            drop = NO;
	}
	if(shouldTeXify){
        urlKeys = [[NSMutableSet alloc] initWithCapacity:6];
		[urlKeys addObjectsFromArray:[pw stringArrayForKey:BDSKLocalFileFieldsKey]];
		[urlKeys addObjectsFromArray:[pw stringArrayForKey:BDSKRemoteURLFieldsKey]];
	}
	e = [keys objectEnumerator];
	[keys release];

    //build BibTeX entry:
    [s appendString:@"@"];
    
    [s appendString:type];
    [s appendString:@"{"];
    [s appendString:[self citeKey]];
    while(k = [e nextObject]){
		if (drop && ![knownKeys containsObject:k])
			continue;
		
        v = [pubFields objectForKey:k usingLock:bibLock];
        NSString *valString;
        
		if([k isEqualToString:BDSKAuthorString] && 
		   [pw boolForKey:BDSKShouldSaveNormalizedAuthorNamesKey] && 
		   ![v isComplex]){ // only if it's not complex, use the normalized author name
		    if(![v isEqualToString:@""]) // pubAuthors will have an editor if no authors exist, but editors can't be written out as authors
			v = [self bibTeXAuthorStringNormalized:YES inherit:NO];
		}
		
		if(shouldTeXify && ![urlKeys containsObject:k]){
			
			NS_DURING
				v = [[BDSKConverter sharedConverter] stringByTeXifyingString:v];
			NS_HANDLER
				if([[localException name] isEqualToString:BDSKTeXifyException]){
					int i = NSRunAlertPanel(NSLocalizedString(@"Character Conversion Error", @"Title of alert when an error happens"),
											[NSString stringWithFormat: NSLocalizedString(@"An unrecognized character in the \"%@\" field of \"%@\" could not be converted to TeX.", @"Informative alert text when the error happens."), k, [self citeKey]],
											nil, nil, nil, nil);
				}
				[localException raise]; // re-raise; we localized the error, but the sender needs to know we failed
			NS_ENDHANDLER
							
		}                
		
        if(expand == YES)
            valString = [v stringAsExpandedBibTeXString];
        else
            valString = [v stringAsBibTeXString];
        
        if(![v isEqualToString:@""]){
            [s appendString:@",\n\t"];
            [s appendString:k];
            [s appendString:@" = "];
            [s appendString:valString];
        }
    }
    [s appendString:@"}"];
    [knownKeys release];
    [urlKeys release];
    return s;
}

- (NSString *)bibTeXStringByExpandingMacros:(BOOL)expand dropInternal:(BOOL)drop{
    BOOL shouldTeXify = [[OFPreferenceWrapper sharedPreferenceWrapper] boolForKey:BDSKShouldTeXifyWhenSavingAndCopyingKey];
    return [self bibTeXStringByExpandingMacros:expand dropInternal:drop texify:shouldTeXify];
}

- (NSString *)bibTeXString{
	return [self bibTeXStringByExpandingMacros:NO dropInternal:NO];
}

- (NSString *)bibTeXStringDroppingInternal:(BOOL)drop{
	return [self bibTeXStringByExpandingMacros:NO dropInternal:drop];
}

- (NSString *)bibTeXStringByExpandingMacros{
    return [self bibTeXStringByExpandingMacros:YES dropInternal:NO];
}

- (NSString *)bibTeXStringUnexpandedAndDeTeXifiedWithoutInternalFields{
    return [self bibTeXStringByExpandingMacros:NO dropInternal:YES texify:NO];
}

#warning not currently XML entity-escaped !!
- (NSString *)MODSString{
    NSDictionary *genreForTypeDict = [[BibTypeManager sharedManager] MODSGenresForBibTeXType:[self type]];
    NSMutableString *s = [NSMutableString stringWithString:@"<mods>"];
    unsigned i = 0;
    
    [s appendFormat:@"<titleInfo> <title>%@ </title>", [self valueOfField:BDSKTitleString]];
    
    // note: may in the future want to output subtitles.

    [s appendString:@"</titleInfo>\n"];
    
    foreach (author, pubAuthors){
        [s appendString:[author MODSStringWithRole:BDSKAuthorString]];
        [s appendString:@"\n"];
    }

    // NOTE: this isn't always text. what are the special case pubtypes?
    [s appendString:@"<typeOfResource>text</typeOfResource>"];
    
    NSArray *genresForSelf = [genreForTypeDict objectForKey:@"self"];
    if(genresForSelf){
        for(i = 0; i < [genresForSelf count]; i++){
            [s appendFormat:@"<genre>%@</genre>", [genresForSelf objectAtIndex:i]];
        }
    }

    // HOST INFO
    NSArray *genresForHost = [genreForTypeDict objectForKey:@"host"];
    if(genresForHost){
        [s appendString:@"<relatedItem type=\"host\">"];
        
        NSString *hostTitle = nil;
        
        if([[self type] isEqualToString:@"inproceedings"] || 
           [[self type] isEqualToString:@"incollection"]){
            hostTitle = [self valueOfField:BDSKBooktitleString];
        }else if([[self type] isEqualToString:@"article"]){
            hostTitle = [self valueOfField:BDSKJournalString];
        }
        [s appendFormat:@"<titleInfo><title>%@</title></titleInfo>", (hostTitle ? hostTitle : @"unknown")];
        
        [s appendString:@"</relatedItem>"];
    }

    [s appendFormat:@"<identifier type=\"citekey\">%@</identifier>", [self citeKey]];
    
    [s appendString:@"</mods>"];
    return [[s copy] autorelease];
}

- (NSString *)RSSValue{
    NSMutableString *s = [[[NSMutableString alloc] init] autorelease];

    NSString *descField = [[OFPreferenceWrapper sharedPreferenceWrapper] objectForKey:BDSKRSSDescriptionFieldKey];

    [s appendString:@"<item>\n"];
    [s appendString:@"<description>\n"];
    if([self valueOfField:descField]){
        [s appendString:[[self valueOfField:descField] xmlString]];
    }
    [s appendString:@"</description>\n"];
    [s appendString:@"<link>"];
    [s appendString:[self valueOfField:BDSKUrlString]];
    [s appendString:@"</link>\n"];
    //[s appendString:@"<bt:source><![CDATA[\n"];
    //    [s appendString:[[self bibTeXString] xmlString]];
    //    [s appendString:@"]]></bt:source>\n"];
    [s appendString:@"</item>\n"];
    return s;
}

- (NSString *)HTMLValueUsingTemplateString:(NSString *)templateString{
    return [templateString stringByParsingTagsWithStartDelimeter:@"<$" endDelimeter:@"/>" usingObject:self];
}

- (NSString *)allFieldsString{
    NSMutableString *result = [[[NSMutableString alloc] initWithCapacity:([pubFields count] * 10)] autorelease];
    
    [result appendString:[self citeKey]];
    [result appendString:@" "];
    
    BibItem *parent = [self crossrefParent];

    // if it has a parent, find all the available keys, and use valueOfField: to get either the
    // child object or parent object value. Inherit only the fields of the parent relevant for the item.
    if(parent){
        NSEnumerator *keyEnum = [pubFields keyEnumerator];
        NSString *key = nil;
        
        while(key = [keyEnum nextObject]){
            [result appendString:[self valueOfField:key inherit:YES]];
            [result appendString:@" "];
        }
                
    } else {
        NSEnumerator *pubFieldsE = [pubFields objectEnumerator];
        NSString *field = nil;
        
        while(field = [pubFieldsE nextObject]){
            [result appendString:field];
            [result appendString:@" "];
        }
    }       
    
    return result;
}

- (NSURL *)remoteURL{
	return [self remoteURLForField:BDSKUrlString];
}

- (NSURL *)URLForField:(NSString *)field{
    if([[[OFPreferenceWrapper sharedPreferenceWrapper] stringArrayForKey:BDSKLocalFileFieldsKey] containsObject:field]){
        NSString *path = [self localFilePathForField:field];
        return path == nil ? nil : [NSURL fileURLWithPath:path];
    } else if([[[OFPreferenceWrapper sharedPreferenceWrapper] stringArrayForKey:BDSKRemoteURLFieldsKey] containsObject:field])
        return [self remoteURLForField:field];
    else 
        [NSException raise:NSInvalidArgumentException format:@"Field \"%@\" is not a valid URL field.", field];
}

- (NSURL *)remoteURLForField:(NSString *)field{
    CFStringRef urlString = (CFStringRef)[pubFields objectForKey:field usingLock:bibLock];
    
    if(urlString == nil || CFStringCompare(urlString, CFSTR(""), 0) == kCFCompareEqualTo) return nil;
    
    // normalize the URL string; CFURLCreateStringByAddingPercentEscapes appears to have a bug where it replaces some existing percent escapes with a %25, which is the percent character escape, rather than ignoring them as it should
    CFStringRef unescapedString = CFURLCreateStringByReplacingPercentEscapes(CFAllocatorGetDefault(), urlString, CFSTR(""));
    if(unescapedString == NULL) return nil;
    
    // we need to validate URL strings, as some doi URL's contain characters that need to be escaped
    urlString = CFURLCreateStringByAddingPercentEscapes(CFAllocatorGetDefault(), unescapedString, NULL, NULL, kCFStringEncodingUTF8);
    CFRelease(unescapedString);
    
    // could try adding base URLs to resolve against, if theURL is not valid?
    CFURLRef theURL = CFURLCreateWithString(CFAllocatorGetDefault(), urlString, NULL);
    CFRelease(urlString);
    
    return [(NSURL *)theURL autorelease];
}

- (NSString *)localURLPath{
	return [self localURLPathInheriting:YES];
}

- (NSString *)localURLPathInheriting:(BOOL)inherit{
	return [self localFilePathForField:BDSKLocalUrlString relativeTo:[[document fileName] stringByDeletingLastPathComponent] inherit:inherit];
}

- (NSString *)localFilePathForField:(NSString *)field{
	return [self localFilePathForField:field relativeTo:[[document fileName] stringByDeletingLastPathComponent] inherit:YES];
}

- (NSString *)localFilePathForField:(NSString *)field relativeTo:(NSString *)base inherit:(BOOL)inherit{
    NSURL *localURL = nil;
    NSString *localURLFieldValue = [self valueOfField:field inherit:inherit];
    
    if ([NSString isEmptyString:localURLFieldValue]) return nil;
        
    if(![localURLFieldValue containsString:@"file://"]){
        // the local-url isn't already a file: url.
        if(base && 
           ![[localURLFieldValue substringWithRange:NSMakeRange(0,1)] isEqualToString:@"/"] &&
           ![[localURLFieldValue substringWithRange:NSMakeRange(0,1)] isEqualToString:@"~"]){
            
            // it's a relative path and we can prepend base to it.
            localURLFieldValue = [base stringByAppendingPathComponent:localURLFieldValue];

        }else{
            // Ignore base if we had a full path to begin with.
            // make sure we remove ~. If the string started with /, this is still OK.
            localURLFieldValue = [localURLFieldValue stringByExpandingTildeInPath];
        }

        localURL = [NSURL fileURLWithPath:localURLFieldValue];
    }else{
        // it's already a file: url and we can just build it 
        localURL = [NSURL URLWithString:localURLFieldValue];
    }

    return [[localURL path] stringByExpandingTildeInPath];
}

- (NSString *)suggestedLocalUrl{
	OFPreferenceWrapper *prefs = [OFPreferenceWrapper sharedPreferenceWrapper];
	NSString *localUrlFormat = [prefs objectForKey:BDSKLocalUrlFormatKey];
	NSString *papersFolderPath = [[prefs stringForKey:BDSKPapersFolderPathKey] stringByExpandingTildeInPath];
	NSString *relativeFile = [[BDSKFormatParser sharedParser] parseFormat:localUrlFormat forField:BDSKLocalUrlString ofItem:self];
	if ([[OFPreferenceWrapper sharedPreferenceWrapper] boolForKey:BDSKCiteKeyLowercaseKey]) {
		relativeFile = [relativeFile lowercaseString];
	}
	NSURL *url = [NSURL fileURLWithPath:[papersFolderPath stringByAppendingPathComponent:relativeFile]];
	
	return [url absoluteString];
}

- (BOOL)canSetLocalUrl
{
	if ([[NSApp delegate] requiredFieldsForLocalUrl] == nil) 
		return NO;
	
	NSEnumerator *fEnum = [[[NSApp delegate] requiredFieldsForLocalUrl] objectEnumerator];
	NSString *fieldName;
	NSString *fieldValue;
	
	while (fieldName = [fEnum nextObject]) {
		if ([fieldName isEqualToString:BDSKCiteKeyString]) {
			fieldValue = [self citeKey];
			if ([fieldValue isEqualToString:@""] || [fieldValue isEqualToString:@"cite-key"]) 
				return NO;
		} else {
			if ([NSString isEmptyString:[self valueOfField:fieldName]]) 
				return NO;
		}
	}
	return YES;
}

- (BOOL)needsToBeFiled { 
	return needsToBeFiled; 
}

- (void)setNeedsToBeFiled:(BOOL)flag {
	needsToBeFiled = flag;
	
	if (editorObj) {
		NSString *message = NSLocalizedString(@"Linked file needs to be filed.",@"Linked file needs to be filed.");
		if (flag) {
			[editorObj setStatus:message];
		} else if ([message isEqualToString:[editorObj status]]) {
			[editorObj setStatus:@""];
		}
	}
}

- (void)autoFilePaper
{
	if (![[OFPreferenceWrapper sharedPreferenceWrapper] boolForKey:BDSKFilePapersAutomaticallyKey])
		return;
	
	if ([self canSetLocalUrl]) {
		[[BibFiler sharedFiler] filePapers:[NSArray arrayWithObject:self]
							  fromDocument:[self document] 
									   ask:NO]; 
		if (editorObj) {
			[editorObj setStatus:NSLocalizedString(@"Autofiled linked file.",@"Autofiled linked file.")];
		}
	} else {
		[self setNeedsToBeFiled:YES];
	}
}

- (void)typeInfoDidChange:(NSNotification *)aNotification{
	[self makeType];
}

- (void)customFieldsDidChange:(NSNotification *)aNotification{
	[self makeType];
	[groups removeAllObjects];
}

- (void)duplicateTitleToBooktitleOverwriting:(BOOL)overwrite{
	NSString *title = [pubFields objectForKey:BDSKTitleString usingLock:bibLock];
	
	if([NSString isEmptyString:title])
		return;
	
	NSString *booktitle = [pubFields objectForKey:BDSKBooktitleString usingLock:bibLock];
	if(![NSString isEmptyString:booktitle] && !overwrite)
		return;
	if(booktitle == nil)
		[self addField:BDSKBooktitleString];
	[self setField:BDSKBooktitleString toValue:title];
}

- (NSSet *)groupsForField:(NSString *)field{
	// first see if we had it cached
	NSSet *groupSet = [groups objectForKey:field];
	if(groupSet)
		return groupSet;

	// otherwise build it if we have a value
    NSString *value = [self valueOfGenericField:field];
	if([value isComplex] || [value isInherited])
		value = [NSString stringWithString:value];
    if([NSString isEmptyString:value])
        return [NSSet set];
	
    static OFCharacterSet *delimiterCharSet = nil;
    static OFCharacterSet *whitespaceCharSet = nil;
    
    if(delimiterCharSet == nil){
        delimiterCharSet = [[OFCharacterSet alloc] initWithCharacterSet:[[NSApp delegate] autoCompletePunctuationCharacterSet]];
        whitespaceCharSet = [[OFCharacterSet alloc] initWithCharacterSet:[NSCharacterSet whitespaceCharacterSet]];
    }
    OBASSERT(delimiterCharSet);
    OBASSERT(whitespaceCharSet);
	
    if([[[BibTypeManager sharedManager] singleValuedGroupFields] containsObject:field]){
		// types and journals should be added as a whole
		[groups setObject:[NSSet setWithObject:value] forKey:field];
	}else{
		BOOL useDelimiters = NO;
		if([field isEqualToString:BDSKAuthorString] == NO && [field isEqualToString:BDSKEditorString] == NO && 
		   [value containsCharacterInSet:[[NSApp delegate] autoCompletePunctuationCharacterSet]])
			useDelimiters = YES;
        
		NSMutableSet *mutableGroupSet = [[NSMutableSet alloc] initWithCapacity:5];
		OFStringScanner *scanner = [[OFStringScanner alloc] initWithString:value];
        NSString *token;
        
        scannerScanUpToCharacterNotInOFCharacterSet(scanner, whitespaceCharSet);

        do {
			if(useDelimiters)
				token = [scanner readFullTokenWithDelimiterOFCharacterSet:delimiterCharSet];
			else
				token = [scanner readFullTokenUpToString:@" and "];
            if(token){
				token = [token stringByRemovingSurroundingWhitespace];
				if(![NSString isEmptyString:token])
					[mutableGroupSet addObject:token];
            }
            // skip the delimiter or " and ", and any whitespace following it
			if(useDelimiters)
				scannerScanUpToCharacterNotInOFCharacterSet(scanner, delimiterCharSet);
			else if(scannerHasData(scanner))
				[scanner setScanLocation:scannerScanLocation(scanner) + 5];
            scannerScanUpToCharacterNotInOFCharacterSet(scanner, whitespaceCharSet);
                    
        } while(scannerHasData(scanner));
        
        [scanner release];
		
		[groups setObject:mutableGroupSet forKey:field];
		[mutableGroupSet release];
    }
	
    return [groups objectForKey:field];
}

- (int)addToGroupNamed:(NSString *)group usingField:(NSString *)field handleInherited:(int)operation{
    // don't add it twice
    if([[self groupsForField:field] containsObject:group])
        return BDSKOperationIgnore;
	
	// otherwise build it if we have a value
	BOOL isInherited = NO;
    NSString *oldString = [self valueOfGenericField:field];
	if([oldString isComplex] || [oldString isInherited]){
		isInherited = [oldString isInherited];
		oldString = [NSString stringWithString:oldString];
	}
	
	if(isInherited){
		if(operation ==  BDSKOperationAsk || operation == BDSKOperationIgnore)
			return operation;
	}else{
		if([[[BibTypeManager sharedManager] singleValuedGroupFields] containsObject:field] || 
		   [NSString isEmptyString:oldString])
			operation = BDSKOperationSet;
		else
			operation = BDSKOperationAppend;
	}
    
	NSMutableString *string = [[NSMutableString alloc] initWithCapacity:[group length] + [oldString length] + 1];

    // we set the type and journal field, add to other fields if needed
	if(operation == BDSKOperationAppend){
        [string appendString:oldString];
        
		// Use default separator string, unless this is an author/editor field
        if([field isEqualToString:BDSKAuthorString] == NO && [field isEqualToString:BDSKEditorString] == NO)
            [string appendString:[[OFPreferenceWrapper sharedPreferenceWrapper] objectForKey:BDSKDefaultGroupFieldSeparatorKey]];
        else
            [string appendString:@" and "];
    }
    
    [string appendString:group];
	[self setGenericField:field toValue:string];
    [string release];
	
	return operation;
}

@end
