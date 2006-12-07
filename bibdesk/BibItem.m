//  BibItem.m
//  Created by Michael McCracken on Tue Dec 18 2001.
/*
 This software is Copyright (c) 2001,2002, Michael O. McCracken
 All rights reserved.

 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 -  Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 -  Neither the name of Michael O. McCracken nor the names of any contributors may be used to endorse or promote products derived from this software without specific prior written permission.

 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "BibItem.h"
#import "BibEditor.h"
#import "btparse.h"

#define addokey(s) if([pubFields objectForKey: s] == nil){[pubFields setObject:@"" forKey: s];} [removeKeys removeObject: s];
#define addrkey(s) if([pubFields objectForKey: s] == nil){[pubFields setObject:@"" forKey: s];} [requiredFieldNames addObject: s]; [removeKeys removeObject: s];


@implementation BibItem

- (id)init{
    return [self initWithType: INPROCEEDINGS
                      authors:[NSMutableArray arrayWithCapacity:3]
                defaultFields:[NSArray arrayWithObjects:@"Keywords", nil]];
    // The capacity is zero by default for no good reason.
    // default is inproceedings.
    // while the other defaults are arbitrary, defaultFields is at least responsible.
    // I think this shouldn't ever get called. don't know why i wrote it.
}

- (id)initWithType: (BibType)type authors:(NSMutableArray *)authArray defaultFields:(NSMutableArray *)defaultFields{ // this is the designated initializer.
    if (self = [super init]){
        pubFields = [[NSMutableDictionary alloc] init]; // do i need a retain];
        requiredFieldNames = [[NSMutableArray alloc] init];
        defaultFieldsArray = [defaultFields mutableCopy];    // copy.
        pubAuthors = [authArray mutableCopy];     // copy, it's mutable
        editorObj = nil;

        [self setTitle:[[NSString stringWithString:@"BibTeX Publication"] retain]];
        [self makeType:type];
        [self setCiteKey:@""];
        [self setDate: nil];
        [self setFileOrder:-1]; 
    }
    //NSLog(@"bibitem init");
    return self;
}

- (id)copyWithZone:(NSZone *)zone{
    BibItem *theCopy = [[[self class] allocWithZone: zone] initWithType:pubType
                                                                authors:[pubAuthors mutableCopy]
                                                          defaultFields:[defaultFieldsArray retain]];
    [theCopy setCiteKey: [citeKey copy]];
    [theCopy setDate: [pubDate copy]];
    [theCopy setTitle: [title copy]];
    [theCopy setFields: [pubFields mutableCopy]];
    [theCopy setRequiredFieldNames: [requiredFieldNames mutableCopy]];
    return theCopy;
}

- (void)makeType:(BibType)type{
    NSEnumerator *defFieldsE;
    NSString *defFieldString;
    NSEnumerator *e;
    NSString *tmp;
    NSMutableArray *removeKeys = [NSMutableArray arrayWithObjects: @"Address", @"Author", @"Booktitle", @"Chapter", @"Edition", @"Editor", @"Howpublished", @"Institution", @"Journal", @"Month", @"Number", @"Organization", @"Pages", @"Publisher", @"School", @"Series", @"Title", @"Type", @"Volume", @"Year", @"Note", @"Code",  @"Crossref", nil];
    //@"Url", @"Local-Url",, @"Annote", @"Abstract"
    defFieldsE = [defaultFieldsArray objectEnumerator];
    while(defFieldString = [defFieldsE nextObject]){
        addokey(defFieldString)
    }
    //I don't enforce Keywords, but since there's GUI depending on them, I will enforce these others:
    addokey(@"Url") addokey(@"Local-Url") addokey(@"Annote") addokey(@"Abstract") addokey(@"Rss-Description")
        // yeah, i know it's skanky to let the GUI influence the model class like this, but whatever.
    switch(type){
        case ARTICLE:
            addrkey(@"Author") addrkey(@"Title") addrkey(@"Journal") addrkey(@"Year")
            addokey(@"Volume") addokey(@"Number") addokey(@"Pages") addokey(@"Month")
            break;
        case BOOK:
            addrkey(@"Author") addrkey(@"Title") addrkey(@"Publisher") addrkey(@"Year")
            addokey(@"Editor") addokey(@"Volume") addokey(@"Number") addokey(@"Series")
            addokey(@"Address") addokey(@"Edition") addokey(@"Month")
            break;
        case BOOKLET:
            addrkey(@"Title")
            addokey(@"Author") addokey(@"Howpublished") addokey(@"Address") addokey(@"Month") addokey(@"Year")
            break;
        case INBOOK:
            addrkey(@"Author") addrkey(@"Title") addrkey(@"Chapter") addrkey(@"Pages") addrkey(@"Publisher") addrkey(@"Year")
            addokey(@"Editor") addokey(@"Volume") addokey(@"Series")
            addokey(@"Address") addokey(@"Edition")
            break;
        case INCOLLECTION:
            addrkey(@"Author") addrkey(@"Title") addrkey(@"Booktitle") addrkey(@"Publisher") addrkey(@"Year")
            addokey(@"Editor") addokey(@"Volume") addokey(@"Number") addokey(@"Series") addokey(@"Type") addokey(@"Chapter")
            addokey(@"Pages") addokey(@"Address") addokey(@"Edition") addokey(@"Month")
            break;
        case INPROCEEDINGS:
            addrkey(@"Author") addrkey(@"Title") addrkey(@"Booktitle") addrkey(@"Year")
            addokey(@"Editor") addokey(@"Pages") addokey(@"Organization") addokey(@"Publisher") addokey(@"Address") addokey(@"Month")
            break;
        case MANUAL:
            addrkey(@"Title")
            addokey(@"Author") addokey(@"Organization") addokey(@"Address") addokey(@"Edition") addokey(@"Month") addokey(@"Year")
            break;
        case MISC:
            addokey(@"Title") addokey(@"Author") addokey(@"Organization") addokey(@"Address") addokey(@"Edition")
            addokey(@"Month") addokey(@"Year")
            break;
        case MASTERSTHESIS:
            addrkey(@"Author") addrkey(@"Title") addrkey(@"School") addrkey(@"Year")
            addokey(@"Address") addokey(@"Month") addokey(@"Type")
            break;
        case PHDTHESIS:
            addrkey(@"Author") addrkey(@"Title") addrkey(@"School") addrkey(@"Year")
            addokey(@"Address") addokey(@"Month") addokey(@"Type")
            break;
        case PROCEEDINGS:
            addrkey(@"Title") addrkey(@"Year")
            addokey(@"Editor") addokey(@"Publisher") addokey(@"Organization") addokey(@"Address")  addokey(@"Month")
            break;
        case TECHREPORT:
            addrkey(@"Author") addrkey(@"Title") addrkey(@"Institution") addrkey(@"Year")
            addokey(@"Type") addokey(@"Number") addokey(@"Address")
            break;
        case UNPUBLISHED:
            addrkey(@"Author") addrkey(@"Title")
            addokey(@"Month") addokey(@"Year")
            break;
    }
    // remove from removeKeys things that aren't == @"" in pubFields
    // this includes things left over from the previous bibtype - that's good.
    e = [[pubFields allKeys] objectEnumerator];
    
    while (tmp = [e nextObject]) {
        if (![[pubFields objectForKey:tmp] isEqualToString:@""]) {
            [removeKeys removeObject:tmp];
        }
    }
    // now remove everything that's left in remove keys from pubfields
    [pubFields removeObjectsForKeys:removeKeys];
    // and don't forget to set what we say our type is:
    pubType = type;
}
- (BOOL)isRequired:(NSString *)rString{
    if([requiredFieldNames indexOfObject:rString] == NSNotFound)
        return NO;
    else
        return YES;
}

+ (BibItem *)itemFromString:(NSString *)itemString{

    AST *entry, *field;
    int ok = 0;
    long cidx = 0; // used to scan through buf for annotes.
    char annoteDelim = '\0';
    int braceDepth = 0;    

    BibItem *newBI;
    char *fieldname;
    NSString *s;
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionaryWithCapacity:6];
    char *buf = (char *) malloc(sizeof(char) * [itemString cStringLength]);
    [itemString getCString:buf];
    
    bt_initialize();
    entry =  bt_parse_entry_s ([itemString cString],
                            "input from paste or drag",
                            47,
                            0,
                            &ok);

    if (ok && (bt_entry_metatype(entry) == BTE_REGULAR)) {
        newBI = [[BibItem alloc] initWithType:
            [BibItem typeFromString:[[NSString stringWithCString:bt_entry_type(entry)] lowercaseString]]
                                   authors:[NSMutableArray arrayWithCapacity:0]
                                defaultFields:[[[OFPreferenceWrapper sharedPreferenceWrapper] stringArrayForKey:BDSKDefaultFieldsKey] mutableCopy]];
        // above, yet another unhealthy mixing of model and view (or is it?)
        field = NULL;
        while (field = bt_next_field (entry, field, &fieldname))
        {
            if(!strcmp(fieldname, "annote") || !strcmp(fieldname, "abstract")){
                if(field->down){
                    cidx = field->down->offset;
                    // the delimiter is at cidx-1
                    if(buf[cidx-1] == '{'){
                        // scan up to the balanced brace
                        for(braceDepth = 1; braceDepth > 0; cidx++){
                            if(buf[cidx] == '{') braceDepth++;
                            if(buf[cidx] == '}') braceDepth--;
                        }
                        cidx--;     // just advanced cidx one past the end of the field.
                    }else if(buf[cidx-1] == '"'){
                        // scan up to the next quote.
                        for(; buf[cidx] != '"'; cidx++);
                    }
                    annoteDelim = buf[cidx];
                    buf[cidx] = '\0';
                    s = [NSString stringWithCString:&buf[field->down->offset]];
                    buf[cidx] = annoteDelim;
                }else{
                    // field->down was null (shouldn't happen)
                    return NULL;
                }
            }else{
                // fieldname wasn't annote or abstract, just get bt's version:
                s = [NSString stringWithCString:bt_get_text(field)];
            }

            [dictionary setObject:[NSString stringWithString:s]
                           forKey:[[NSString stringWithCString: fieldname] capitalizedString]];
        }// end while field = bt next field
        [newBI setCiteKey:[NSString stringWithCString:bt_entry_key(entry)]];
        [newBI setFields:dictionary];
    }else{
        // wasn't regular
        bt_parse_entry_s (NULL, "cleanup", 47, 0, &ok);
        bt_cleanup();
               
        return NULL;
    }
    bt_parse_entry_s (NULL, "cleanup", 47, 0, &ok);
    bt_cleanup();
    return [newBI autorelease];
}

+ (NSArray *)itemsFromString:(NSString *)itemString{

    AST *entry, *field;
    int ok = 1;
    long cidx = 0; // used to scan through buf for annotes.
    char annoteDelim = '\0';
    int braceDepth = 0;
    NSMutableArray *returnArray = [NSMutableArray arrayWithCapacity:1];
    BibItem *newBI;
    char *fieldname;
    NSString *s;
    int cursor = 0; // used to keep the index so we can start the parsing after the previous entry.
    int readOffset = 0; // same as above. cursor keeps track within entries, readOffset keeps track within the string overall.
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionaryWithCapacity:6];
    char *buf = (char *) malloc(sizeof(char) * [itemString cStringLength]);
    NS_DURING
        [itemString getCString:buf];
    NS_HANDLER
        // if we couldn't convert it, we won't be able to read it: just give up.
        if ([[localException name] isEqualToString:NSCharacterConversionException]) {
            NSLog(@"Exception %@ raised in BibItem itemsFromString:, handled by giving up.", [localException name]);
            itemString = @"";
            NSBeep();
        }else{
            [localException raise];
        }
    NS_ENDHANDLER
        
    bt_initialize();

    while(ok){


        entry =  bt_parse_entry_s (buf+readOffset,
                                   "input from paste or drag",
                                   47,
                                   0,
                                   &ok);

        if (ok && (bt_entry_metatype(entry) == BTE_REGULAR)) {
            newBI = [[BibItem alloc] initWithType:
                [BibItem typeFromString:[[NSString stringWithCString:bt_entry_type(entry)] lowercaseString]]
                                          authors:
                [NSMutableArray arrayWithCapacity:0]
                                    defaultFields:
                [[[OFPreferenceWrapper sharedPreferenceWrapper] stringArrayForKey:BDSKDefaultFieldsKey] mutableCopy]];
            // above, yet another unhealthy mixing of model and view (or is it?)
            
            field = NULL;
            while (field = bt_next_field (entry, field, &fieldname))
            {
                if(!strcmp(fieldname, "annote") || !strcmp(fieldname, "abstract")){
                    if(field->down){
                        cidx = field->down->offset;
                        
                        // the delimiter is at cidx-1
                        if(buf[cidx-1] == '{'){
                            // scan up to the balanced brace
                            for(braceDepth = 1; braceDepth > 0; cidx++){
                                if(buf[cidx] == '{') braceDepth++;
                                if(buf[cidx] == '}') braceDepth--;
                            }
                            cidx--;     // just advanced cidx one past the end of the field.
                        }else if(buf[cidx-1] == '"'){
                            // scan up to the next quote.
                            for(; buf[cidx] != '"'; cidx++);
                        }
                        annoteDelim = buf[cidx];
                        buf[cidx] = '\0';
                        s = [NSString stringWithCString:&buf[field->down->offset]];
                        buf[cidx] = annoteDelim;
                       
                    }else{
                        // field->down was null (shouldn't happen)
                        return NULL;
                    }
                }else{
                    // fieldname wasn't annote or abstract, just get bt's version:
                    s = [NSString stringWithCString:bt_get_text(field)];
                }
                if(field->down){
                    cursor = field->down->offset;
                    // we find the beginning of each entry, then if it's the last, we will scan ahead to the next pub later
                }
                [dictionary setObject:[NSString stringWithString:s]
                               forKey:[[NSString stringWithCString: fieldname] capitalizedString]];
                
            }// end while field = bt next field
             // Got all the fields, now we insert it and scan cursor up to the next one
            [newBI setCiteKey:[NSString stringWithCString:bt_entry_key(entry)]];
            [newBI setFields:dictionary];
            [dictionary removeAllObjects];
            
            [returnArray addObject:newBI];
            
            while(buf[cursor] && buf[cursor] != '@'){
                cursor++;
            }
            readOffset += cursor - 1; // back up one
        }else{
            // wasn't ok or wasn't regular
            /* here's what we do in itemfromstring:
            bt_parse_entry_s (NULL, "cleanup", 47, 0, &ok);
            bt_cleanup();
            return NULL;*/
        }
        
    } // while scanning through string
    bt_parse_entry_s (NULL, "cleanup", 47, 0, &ok);
    bt_cleanup();
    return [NSArray arrayWithArray:returnArray];
}

+ (NSString *)stringFromType:(BibType)type{
    switch(type){
        case ARTICLE:
            return @"article";
            break;
        case BOOK:
            return @"book";
            break;
        case BOOKLET:
            return @"booklet";
            break;
        case INBOOK:
            return @"inbook";
            break;
        case INCOLLECTION:
            return @"incollection";
            break;
        case INPROCEEDINGS:
            return @"inproceedings";
            break;
        case MANUAL:
            return @"manual";
            break;
        case MISC:
            return @"misc";
            break;
        case MASTERSTHESIS:
            return @"mastersthesis";
            break;
        case PHDTHESIS:
            return @"phdthesis";
            break;
        case PROCEEDINGS:
            return @"proceedings";
            break;
        case TECHREPORT:
            return @"techreport";
            break;
        case UNPUBLISHED:
            return @"unpublished";
            break;
        case NOTYPE:
            return @"no type";
            break;
    }
}
// This is written with the constants so that it works with btparse's bt_entry_type() output.
// That means all lowercase.
+ (BibType)typeFromString:(NSString *)typeString{
    if ([[typeString lowercaseString] isEqualToString:@"article"]) {
    	return ARTICLE;
    }
    if ([[typeString lowercaseString] isEqualToString:@"book"]) {
        return BOOK;
    }
    if ([[typeString lowercaseString] isEqualToString:@"booklet"]) {
        return BOOKLET;
    }
    if ([[typeString lowercaseString] isEqualToString:@"inbook"]) {
        return INBOOK;
    }
    if ([[typeString lowercaseString] isEqualToString:@"incollection"]) {
        return INCOLLECTION;
    }
    if ([[typeString lowercaseString] isEqualToString:@"inproceedings"]) {
        return INPROCEEDINGS;
    }
    if ([[typeString lowercaseString] isEqualToString:@"manual"]) {
        return MANUAL;
    }
    if ([[typeString lowercaseString] isEqualToString:@"misc"]) {
        return MISC;
    }
    if ([[typeString lowercaseString] isEqualToString:@"mastersthesis"]) {
        return MASTERSTHESIS;
    }
    if ([[typeString lowercaseString] isEqualToString:@"phdthesis"]) {
        return PHDTHESIS;
    }
    if ([[typeString lowercaseString] isEqualToString:@"proceedings"]) {
        return PROCEEDINGS;
    }
    if ([[typeString lowercaseString] isEqualToString:@"techreport"]) {
        return TECHREPORT;
    }
    if ([[typeString lowercaseString] isEqualToString:@"unpublished"]) {
        return UNPUBLISHED;
    }
    else return NOTYPE;
}

- (void)dealloc{
   // NSLog(@"bibitem Dealloc");
    [pubDate release];
    [requiredFieldNames release];
    //[pubFields release]; //why does this cause a problem?
    [super dealloc];
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

#warning doesn't always seem to work? specifically when changing updatecounts from changing the pubtype
- (BOOL)isEqual:(BibItem *)aBI{
    return (pubType == [aBI type]) && ([citeKey isEqualToString:[aBI citeKey]]) &&
    ([pubFields isEqual:[aBI dict]]);
}

- (NSComparisonResult)keyCompare:(BibItem *)aBI{
    return [citeKey caseInsensitiveCompare:[aBI citeKey]];
}
- (NSComparisonResult)titleCompare:(BibItem *)aBI{
    return [title caseInsensitiveCompare:[aBI title]];
}
- (NSComparisonResult)dateCompare:(BibItem *)aBI{
    // compare using year first, so Nov 1951 is lower than Dec 2000 . 
    return [[pubDate descriptionWithCalendarFormat:@"%Y %b"] caseInsensitiveCompare:[[aBI date] descriptionWithCalendarFormat:@"%Y %b"]];
}
- (NSComparisonResult)auth1Compare:(BibItem *)aBI{
    if([pubAuthors count] > 0){
        if([aBI numberOfAuthors] > 0){
            return [[self authorAtIndex:0] caseInsensitiveCompare:[aBI authorAtIndex:0]];
        }
        return NSOrderedAscending;
    }else{
        return NSOrderedDescending;
    }
}
- (NSComparisonResult)auth2Compare:(BibItem *)aBI{
    if([pubAuthors count] > 1){
        if([aBI numberOfAuthors] > 1){
            return [[self authorAtIndex:1] caseInsensitiveCompare:[aBI authorAtIndex:1]];
        }
        return NSOrderedAscending;
    }else{
        return NSOrderedDescending;
    }
}
- (NSComparisonResult)auth3Compare:(BibItem *)aBI{
    if([pubAuthors count] > 2){
        if([aBI numberOfAuthors] > 2){
            return [[self authorAtIndex:2] caseInsensitiveCompare:[aBI authorAtIndex:2]];
        }
        return NSOrderedAscending;
    }else{
        return NSOrderedDescending;
    }
}

- (NSComparisonResult)fileOrderCompare:(BibItem *)aBI{
    int aBIOrd = [aBI fileOrder];
    if (_fileOrder == -1) return NSOrderedDescending;
    if (_fileOrder < aBIOrd) {
        return NSOrderedAscending;
    }
    if (_fileOrder > aBIOrd){
        return NSOrderedDescending;
    }else{
        return NSOrderedSame;
    }
}

// accessors for fileorder
- (int)fileOrder{
    return _fileOrder;
}

- (void)setFileOrder:(int)ord{
    _fileOrder = ord;
}

- (int)numberOfAuthors{
    return [pubAuthors count];
}

// for the outlineview. (yeah, it's wack - I'm lazy.)
- (int)numberOfChildren{
    return 0;     // for now. Later, we might have it tell us how many x-ref's it has
}

- (void)addAuthor:(NSString *)newAuthor{
    [pubAuthors addObject:newAuthor];
}

- (NSArray *)pubAuthors{
    return pubAuthors;
}

- (NSString *)authorAtIndex:(int)index{
    if ([pubAuthors count] > index)
        return [pubAuthors objectAtIndex:index];
    else
        return nil;
}

- (void)setAuthorsFromString:(NSString *)aString{
    char *str = [aString cString]; // str will be autoreleased. (freed?)
    bt_stringlist *sl = nil;
    int i=0;
#warning - Exception - might want to add an exception handler that notifies the user of the warning...
    [pubAuthors removeAllObjects];
    sl = bt_split_list(str, "and", "BibTex Name", 1, "inside setAuthorsFromString");
    if (sl != nil) {
        for(i=0; i < sl->num_items; i++){
            if(sl->items[i] != nil)
                [self addAuthor:[NSString stringWithCString: sl->items[i]]];
        }
        bt_free_list(sl); // hey! got to free the memory!
    }
    //    NSLog(@"%@", pubAuthors);
}

- (NSString *)authorString{
    NSEnumerator *en = [pubAuthors objectEnumerator];
    NSString *rs;
    NSString *tmp;
    if([pubAuthors count] == 0) return @"";
    if([pubAuthors count] == 1){
        return [pubAuthors objectAtIndex:0];
    }else{
        rs = [[NSString alloc] initWithString:[en nextObject]];
        while(tmp = [en nextObject]){
            rs = [rs stringByAppendingString:@" and "];
            rs = [rs stringByAppendingString:tmp];
        }
        return rs;
    }
        
}

- (NSString *)title{
    return title;
}

- (void)setTitle:(NSString *)aTitle{
    [title autorelease];
    title = [aTitle copy];
}

- (void)setDate: (NSCalendarDate *)newDate{
    [pubDate autorelease];
    pubDate = [newDate copy];
    
}
- (NSCalendarDate *)date{
    return pubDate;
}

- (void)setType: (BibType)newType{
    pubType = newType;
}
- (BibType)type{
    return pubType;
}

- (void)setCiteKeyFormat: (NSString *)newKeyFormat{
    // in the future, this will allow us to set how we want the citeKey computed
}

- (void)setCiteKey:(NSString *)newCiteKey{
    [citeKey autorelease];
    citeKey = [newCiteKey retain];
}

- (NSString *)citeKey{
    //[citeKey retain];
    return citeKey;
    // this is left over from a temporary auto-generation of keys.
    //return [NSString stringWithFormat:@"%@:%@",[[self authorAtIndex:0] substringToIndex:3],[[self date] descriptionWithCalendarFormat:@"%y"]];
}

- (void)setFields: (NSMutableDictionary *)newFields{
    NSMutableString *tmp = [NSMutableString string];
    // this is what gets called when we make changes, so it has to keep the metadata intact.
    [pubFields autorelease];
    pubFields = [newFields mutableCopy];
    if([pubFields objectForKey: @"Title"] == nil)
        [self setTitle: @"Empty Title"];
    else
        [self setTitle: [pubFields objectForKey: @"Title"]];

    if((![@"" isEqualToString:[pubFields objectForKey: @"Author"]]) && ([pubFields objectForKey: @"Author"] != nil))
    {
        [self setAuthorsFromString:[pubFields objectForKey: @"Author"]];
        if ([[self citeKey] isEqualToString:@""]) {
            [self setCiteKey:[NSString stringWithFormat:@"%@:%@",[[self authorAtIndex:0] substringToIndex:3],[[self date] descriptionWithCalendarFormat:@"%y"]]];
        }
    }else{
        [self setAuthorsFromString:[pubFields objectForKey: @"Editor"]]; // or what else?
        if ([[self citeKey] isEqualToString:@""]) {[self setCiteKey:@"fixme:01"];}
    }// FIXME: set new citeKeys to something more reasonable (make it a user default?)
    // re-call make type to make sure we still have all the appropriate bibtex defined fields...
    [self makeType:[self type]];

    if (([pubFields objectForKey:@"Year"] != nil) && (![[pubFields objectForKey:@"Year"] isEqualToString:@""] )) {
        if (([pubFields objectForKey:@"Month"] != nil) && (![[pubFields objectForKey:@"Month"] isEqualToString:@""] )) {
            [tmp appendString:[pubFields objectForKey:@"Month"]];
            [tmp appendString:@" "];
    	}
        [tmp appendString:[pubFields objectForKey:@"Year"]];
        [self setDate:[NSCalendarDate dateWithNaturalLanguageString:tmp]];
                                      //calendarFormat:@"%B %Y"]];
    }else{
        [self setDate:nil];    // nil means we don't have a good date.
    }
}

- (void)setRequiredFieldNames: (NSMutableArray *)newRequiredFieldNames{
    [requiredFieldNames autorelease];
    requiredFieldNames = [newRequiredFieldNames mutableCopy];
}

- (void)setField: (NSString *)key toValue: (NSString *)value{
    [pubFields setObject: value forKey: key];
    // to allow autocomplete:
    [[NSApp delegate] addString:value forCompletionEntry:key];
}

- (NSString *)valueOfField: (NSString *)key{
    [pubFields retain];
    return [pubFields objectForKey:key];
}

- (void)removeField: (NSString *)key{
    [pubFields removeObjectForKey:key];
}

- (NSMutableDictionary *)dict{
    [pubFields retain];
    return pubFields;
}

- (NSData *)PDFValue{
    // Obtain the PDF of a bibtex formatted version of the bibtex entry as is.
    //* we won't be doing this on a per-item basis. this is deprecated. */
    return [title dataUsingEncoding:NSUnicodeStringEncoding allowLossyConversion:YES];
}

- (NSData *)RTFValue{
    NSString *key;
    NSEnumerator *e = [[[pubFields allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)] objectEnumerator];
    NSDictionary *titleAttributes = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:[NSNumber numberWithInt:1], nil]
                                                              forKeys:[NSArray arrayWithObjects:NSUnderlineStyleAttributeName,  nil]];
//,[NSFont fontWithName:@"Helvetica-Bold" size:14.0] for NSFontAttributeName,

    
   // NSDictionary *keyAttributes = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:[NSFont fontWithName:@"Helvetica-Bold" size:12.0],nil]
// forKeys:[NSArray arrayWithObjects:NSFontAttributeName,nil]];
    
    NSDictionary *bodyAttributes = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:[NSColor colorWithCalibratedWhite:0.9 alpha:0.0], nil]
                                                               forKeys:[NSArray arrayWithObjects:NSBackgroundColorAttributeName, nil]];

    NSMutableAttributedString* aStr = [[[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@\n\n",[self title]] attributes:titleAttributes] autorelease];
    NSMutableArray *nonReqKeys = [NSMutableArray arrayWithCapacity:5]; // yep, arbitrary


    [aStr appendAttributedString:[[[NSMutableAttributedString alloc] initWithString:
    [NSString stringWithFormat:@"%@\n",[BibItem stringFromType:[self type]]]
                                                                     attributes:nil]
    autorelease]];

    while(key = [e nextObject]){
        if(![[pubFields objectForKey:key] isEqualToString:@""] &&
           ![key isEqualToString:@"Title"]){
            if([self isRequired:key]){
                [aStr appendAttributedString:[[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@\n",key]
                                                                              attributes:nil] autorelease]]; // nil was keyAttributes

                [aStr appendAttributedString:[[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"\t%@\n",[pubFields objectForKey:key]]
                                                                              attributes:bodyAttributes] autorelease]];
            }else{
                [nonReqKeys addObject:key];
            }
        }
    }// end required keys
    
    e = [nonReqKeys objectEnumerator];
    while(key = [e nextObject]){
        if(![[pubFields objectForKey:key] isEqualToString:@""]){
            [aStr appendAttributedString:[[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@\n",key]
                                                                          attributes:nil] autorelease]]; // nil was keyAttributes

            [aStr appendAttributedString:[[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"\t%@\n",[pubFields objectForKey:key]]
                                                                          attributes:bodyAttributes] autorelease]];

        }
    }

    [aStr appendAttributedString:[[[NSAttributedString alloc] initWithString:@" "
                                                                  attributes:nil] autorelease]];

    
    return [aStr RTFFromRange:NSMakeRange(0,[aStr length]) documentAttributes:nil];
}

- (NSString *)textValue{
    NSString *k;
    NSString *v;
    NSMutableString *s = [[[NSMutableString alloc] init] autorelease];
    NSEnumerator *e = [pubFields keyEnumerator];
    NSArray *types = [NSArray arrayWithObjects:@"article", @"book", @"booklet", @"inbook", @"incollection", @"inproceedings", @"manual", @"mastersthesis", @"misc", @"phdthesis", @"proceedings", @"techreport", @"unpublished", nil];
    //build BibTeX entry:
    [s appendString:@"@"];
#warning this breaks non-standard publication types...
    [s appendString:[types objectAtIndex:pubType]];
    [s appendString:@"{"];
    [s appendString:[self citeKey]];
    while(k = [e nextObject]){
        v = [pubFields objectForKey:k];
        if(![v isEqualToString:@""]){
            [s appendString:@",\n\t"];
            [s appendFormat:@"%@ = {%@}",k,v];
        }
    }
    [s appendString:@"}"];
    return s;
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
[s appendString:[self valueOfField:@"Url"]];
[s appendString:@"</link>\n"];
//[s appendString:@"<bt:source><![CDATA[\n"];
//    [s appendString:[[self textValue] xmlString]];
//    [s appendString:@"]]></bt:source>\n"];
    [s appendString:@"</item>\n"];
    return [[s copy] autorelease];
}

- (NSString *)allFieldsString{
    NSMutableString *result = [[[NSMutableString alloc] init] autorelease];
    NSEnumerator *pubFieldsE = [pubFields objectEnumerator];
    NSString *field = nil;
    
    while(field = [pubFieldsE nextObject]){
        [result appendFormat:@" %@ ", field];
    }
    return [[result copy] autorelease];
}
@end
