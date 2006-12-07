//
//  BDSKBibTeXParser.m
//  bd2xtest
//
//  Created by Christiaan Hofman on 2/6/06.
//  Copyright 200. All rights reserved.
//

#import "BDSKBibTeXParser.h"
#import <BTParse/btparse.h>
#import <BTParse/error.h>
#import <Carbon/Carbon.h>
#import "BDSKDocument.h"

static NSString *BDSKBibTeXParserInternalException = @"BDSKBibTeXParserInternalException";

@interface BDSKBibTeXParser (Private)

+ (NSString *)stringFromBTField:(AST *)field fieldName:(NSString *)fieldName filePath:(NSString *)filePath document:(BDSKDocument *)document;

@end


@implementation BDSKBibTeXParser

+ (NSSet *)itemsFromData:(NSData *)data error:(NSError **)outError document:(BDSKDocument *)document {
    return [self itemsFromData:data error:outError frontMatter:nil filePath:@"Paste/Drag" document:document];
}

+ (NSSet *)itemsFromData:(NSData *)data error:(NSError **)outError frontMatter:(NSMutableString *)frontMatter filePath:(NSString *)filePath document:(BDSKDocument *)document {
	if(![data length]) // btparse chokes on non-BibTeX or empty data, so we'll at least check for zero length
        return [NSSet set];
		
    int ok = 1;
    long cidx = 0; // used to scan through buf for annotes.
    int braceDepth = 0;

    // Strings read from file and added to Dictionary object
    char *fieldname = "\0";
    NSString *sFieldName = nil;
    NSString *complexString = nil;
	
    AST *entry = NULL;
    AST *field = NULL;

    NSString *entryType = nil;
    NSMutableSet *pubSet = [[NSMutableSet alloc] initWithCapacity:1];
    
    const char *buf = NULL;

    //dictionary is the bibtex entry
    NSMutableDictionary *pubDict = [NSMutableDictionary dictionaryWithCapacity:6];
    NSDictionary *tmpDict;
    
    const char * fs_path = NULL;
    FILE *infile = NULL;
    
    // TODO: get encoding from document
    NSStringEncoding parserEncoding = NSUTF8StringEncoding;
    
    if( !([filePath isEqualToString:@"Paste/Drag"]) && [[NSFileManager defaultManager] fileExistsAtPath:filePath]){
        fs_path = [[NSFileManager defaultManager] fileSystemRepresentationWithPath:filePath];
        infile = fopen(fs_path, "r");
    }else{
        infile = [data openReadOnlyStandardIOFile];
        fs_path = NULL; // used for error context in libbtparse
    }    

    NSError *error = nil;

    buf = (const char *) [data bytes];

    bt_initialize();
    bt_set_stringopts(BTE_PREAMBLE, BTO_EXPAND);
    bt_set_stringopts(BTE_REGULAR, BTO_COLLAPSE);
    
    NSSet *returnSet = nil;
    NSString *tmpStr = nil;

    @try {
        while(entry =  bt_parse_entry(infile, (char *)fs_path, 0, &ok)){

            if (ok){
                // Adding a new Publication
                tmpStr = [[NSString alloc] initWithBytes:bt_entry_type(entry) encoding:parserEncoding];
                entryType = [tmpStr lowercaseString];
                [tmpStr release];
                
                if (bt_entry_metatype (entry) != BTE_REGULAR){
                    // put preambles etc. into the frontmatter string so we carry them along.
                    
                    if (frontMatter && [entryType isEqualToString:@"preamble"]){
                        [frontMatter appendString:@"\n@preamble{\""];
                        field = NULL;
                        bt_nodetype type = BTAST_STRING;
                        BOOL paste = NO;
                        // bt_get_text() just gives us \\ne for the field, so we'll manually traverse it and poke around in the AST to get what we want.  This is sort of nasty, so if someone finds a better way, go for it.
                        while(field = bt_next_value(entry, field, &type, NULL)){
                            char *text = field->text;
                            if(text){
                                if(paste) [frontMatter appendString:@"\" #\n   \""];
                                tmpStr = [[NSString alloc] initWithBytes:text encoding:parserEncoding];
                                if(tmpStr) 
                                    [frontMatter appendString:tmpStr];
                                else
                                    NSLog(@"Possible encoding error: unable to create NSString from %s", text);
                                [tmpStr release];
                                paste = YES;
                            }
                        }
                        [frontMatter appendString:@"\"}"];
                    }else if(frontMatter && [entryType isEqualToString:@"string"]){
                        field = bt_next_field (entry, NULL, &fieldname);
                        NSString *macroKey = [[NSString alloc] initWithBytes: field->text encoding:parserEncoding];
                        tmpStr = [[NSString alloc] initWithBytes: field->down->text encoding:parserEncoding];                        
                        /* TODO: macros
                        if(document)
                            [document addMacroDefinitionWithoutUndo:tmpStr
                                                            forMacro:macroKey];
                        */
                        [tmpStr release];
                        [macroKey release];
                    }else if(frontMatter && [entryType isEqualToString:@"comment"]){
                        NSMutableString *commentStr = [[NSMutableString alloc] init];
                        field = NULL;
                        char *text = NULL;
                        
                        while(field = bt_next_value(entry, field, NULL, &text)){
                            if(text){
                                // encoding will be UTF-8 for the plist, so make sure we use it for each line
                                tmpStr = [[NSString alloc] initWithBytes:text encoding:parserEncoding];
                                
                                if(tmpStr) 
                                    [commentStr appendString:tmpStr];
                                else
                                    NSLog(@"Possible encoding error: unable to create NSString from %s", text);
                                [tmpStr release];
                            }
                        }
                        [frontMatter appendString:@"\n@comment{"];
                        [frontMatter appendString:commentStr];
                        [frontMatter appendString:@"}"];
                        [commentStr release];
                    }
                }else{
                    field = NULL;
                    // Special case handling of abstract & annote is to avoid losing newlines in preexisting files.
                    while (field = bt_next_field (entry, field, &fieldname))
                    {
                        //Get fieldname as a capitalized NSString
                        tmpStr = [[NSString alloc] initWithBytes:fieldname encoding:parserEncoding];
                        sFieldName = [tmpStr capitalizedString];
                        [tmpStr release];
                        
                        if([sFieldName isEqualToString:@"Annote"] || 
                           [sFieldName isEqualToString:@"Abstract"] || 
                           [sFieldName isEqualToString:@"Rss-Description"]){
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
                                }else{ 
                                    // no brace and no quote => unknown problem
                                    NSString *errorString = [NSString stringWithFormat:NSLocalizedString(@"Unexpected delimiter \"%@\" encountered at line %d.", @""), [[[NSString alloc] initWithBytes:&buf[cidx-1] length:1 encoding:parserEncoding] autorelease], field->line];
                                    
                                    // free the AST, set up the error, then bail out and return partial data
                                    bt_free_ast(entry);
                                    
                                    NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:errorString, NSLocalizedDescriptionKey, nil];
                                    error = [NSError errorWithDomain:@"net.sourceforge.bibdesk.bd2xtest.ErrorDomain.BDSKParserError" code:0 userInfo:userInfo];
                                    
                                    @throw BDSKBibTeXParserInternalException;
                                }
                                tmpStr = [[NSString alloc] initWithBytes:&buf[field->down->offset] length:(cidx- (field->down->offset)) encoding:parserEncoding];
                                // TODO: deTeXify
                                complexString = [tmpStr autorelease];
                            }else{
                                NSString *errorString = NSLocalizedString(@"Unable to parse string as BibTeX", @"");
                                NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:errorString, NSLocalizedDescriptionKey, nil];
                                error = [NSError errorWithDomain:@"net.sourceforge.bibdesk.bd2xtest.ErrorDomain.BDSKParserError" code:0 userInfo:userInfo];
                            }
                        }else{
                            complexString = [self stringFromBTField:field fieldName:sFieldName filePath:filePath document:document];
                        }
                        
                        if([sFieldName isEqualToString:@"Author"] || [sFieldName isEqualToString:@"Editor"]){
                            [pubDict setObject:[self personNamesFromBibTeXString:complexString] forKey:sFieldName];
                        }else{
                            [pubDict setObject:complexString forKey:sFieldName];
                        }
                        
                    }// end while field - process next bt field                    

                    tmpStr = [[NSString alloc] initWithBytes:bt_entry_key(entry) encoding:parserEncoding];
                    [pubDict setObject:tmpStr forKey:@"Cite Key"];
                    [tmpStr release];
                    
                    [pubDict setObject:[entryType lowercaseString] forKey:@"Publication Type"];
                    
                    if ([filePath isEqualToString:@"Paste/Drag"]) {
                        NSString *dateStr = [[NSCalendarDate date] description];
                        [pubDict setObject:dateStr forKey:@"Date-Added"];
                        [pubDict setObject:dateStr forKey:@"Date-Modified"];
                    }
                    
                    tmpDict = [[NSDictionary alloc] initWithDictionary:pubDict];
                    [pubSet addObject:tmpDict];
                    [tmpDict release];
                    
                    [pubDict removeAllObjects];
                } // end generate BibItem from ENTRY metatype.
            }else{
                NSString *errorString = NSLocalizedString(@"Unable to parse string as BibTeX", @"");
                NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:errorString, NSLocalizedDescriptionKey, nil];
                error = [NSError errorWithDomain:@"net.sourceforge.bibdesk.bd2xtest.ErrorDomain.BDSKParserError" code:0 userInfo:userInfo];
            }
            bt_free_ast(entry);

        } // while (scanning through file) 
        
        // should we set these when there is an error? see also below
        returnSet = [document newPublicationsFromDictionaries:pubSet];
    }
    
    @catch (id exception) {
        if([exception isEqual:BDSKBibTeXParserInternalException] == NO)
            @throw;
    }
    
    @finally {
        // execute this regardless, so the parser isn't left in an inconsistent state
        bt_cleanup();
        fclose(infile);
        [pubSet release];
        
        // docs say to return nil in an error condition, rather than checking the NSError itself, but we may want to return partial data
        if(error  && outError) *outError = error;
    }
        
    return (returnSet == nil) ? [NSSet set] : returnSet;
}

+ (NSArray *)personNamesFromBibTeXString:(NSString *)aString{
    char *str = nil;
	NSMutableArray *namesArray = [[NSMutableArray alloc] initWithCapacity:1];
    
    if (aString == nil || [aString isEqualToString:@""]){
        return [namesArray autorelease];
    }
    
    str = (char *)[aString UTF8String];
    
    // we're supposed to collapse whitespace before using bt_split_name, and author names with surrounding whitespace don't display in the table (probably for that reason)
    bt_postprocess_string(str, BTO_COLLAPSE);
    
    bt_stringlist *sl = nil;
    int i=0;
    
    NSString *s;
    
    // used as an error description
    NSString *shortDescription = [[NSString alloc] initWithFormat:NSLocalizedString(@"reading authors string %@", @"need an string format specifier"), aString];
    
    sl = bt_split_list(str, "and", "BibTeX Name", 0, (char *)[shortDescription UTF8String]);
    
    if (sl != nil) {
        for(i=0; i < sl->num_items; i++){
            if(sl->items[i] != nil){
                s = [[NSString alloc] initWithUTF8String:(sl->items[i])];
				[namesArray addObject:s];
                [s release];
            }
        }
        bt_free_list(sl); // hey! got to free the memory!
    }
    [shortDescription release];
	
	return [namesArray autorelease];
}

+ (NSDictionary *)splitPersonName:(NSString *)newName{
    NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] initWithCapacity:4];
    NSString *namePart;
    
    bt_name *theName;
    int i = 0;
    
    // use this as a buffer for appending separators
    NSMutableString *mutableString = [[NSMutableString alloc] initWithCapacity:14];
    NSString *tmpStr = nil;
    
    // pass the name as a UTF8 string, since btparse doesn't work with UniChars
    theName = bt_split_name((char *)[newName UTF8String],(char *)[newName UTF8String],0,0);
    
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
    namePart = [mutableString copy];
    [dictionary setObject:namePart forKey:@"firstNamePart"];
    [namePart release];
    
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
    namePart = [mutableString copy];
    [dictionary setObject:namePart forKey:@"vonNamePart"];
    [namePart release];
    
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
    namePart = [mutableString copy];
    [dictionary setObject:namePart forKey:@"lastNamePart"];
    [namePart release];
    
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
    namePart = [mutableString copy];
    [dictionary setObject:namePart forKey:@"jrNamePart"];
    [namePart release];
    
    [mutableString release];
    
    bt_free_name(theName);
    
    return [dictionary autorelease];
}

+ (NSString *)normalizedNameFromString:(NSString *)aString{
    NSDictionary *nameDict = [BDSKBibTeXParser splitPersonName:aString];
    // FIXME: is there a decent way to do this without copy n' paste?
    NSString *firstName = [nameDict valueForKey:@"firstNamePart"];
    NSString *vonPart = [nameDict valueForKey:@"vonNamePart"];
    NSString *lastName = [nameDict valueForKey:@"lastNamePart"];
    NSString *jrPart = [nameDict valueForKey:@"jrNamePart"];
    
    BOOL FIRST = (firstName != nil && ![@"" isEqualToString:firstName]);
    BOOL VON = (vonPart != nil && ![@"" isEqualToString:vonPart]);
    BOOL LAST = (lastName != nil && ![@"" isEqualToString:lastName]);
    BOOL JR = (jrPart != nil && ![@"" isEqualToString:jrPart]);
    
    return [NSString stringWithFormat:@"%@%@%@%@%@%@%@", (VON ? vonPart : @""),
        (VON ? @" " : @""),
        (LAST ? lastName : @""),
        (JR ? @", " : @""),
        (JR ? jrPart : @""),
        (FIRST ? @", " : @""),
        (FIRST ? firstName : @"")];
}

@end


@implementation BDSKBibTeXParser (Private)


// TODO: deTeXify
+ (NSString *)stringFromBTField:(AST *)field fieldName:(NSString *)fieldName filePath:(NSString *)filePath document:(BDSKDocument *)document{
    NSMutableString *returnValue = [[NSMutableString alloc] init];
    NSString *s = nil;
    AST *simple_value;
    
    NSStringEncoding parserEncoding = NSUTF8StringEncoding;
    
	if(field->nodetype != BTAST_FIELD){
		NSLog(@"error! expected field here");
	}
	simple_value = field->down;
		
	while(simple_value){
        if (simple_value->text){
            // for now we just expand complex strings without macro dictionary
            s = [[NSString alloc] initWithBytes:simple_value->text encoding:parserEncoding];
            [returnValue appendString:s];
            [s release];
        }
        
        simple_value = simple_value->right;
	} // while simple_value
    
    return returnValue;
}

@end


@implementation NSString (BDSKExtensions)
 
+ (NSString *)stringWithBytes:(const char *)byteString encoding:(NSStringEncoding)encoding{
    return byteString == NULL ? nil : [(NSString *)CFStringCreateWithCString(CFAllocatorGetDefault(), byteString, CFStringConvertNSStringEncodingToEncoding(encoding)) autorelease];
}

- (NSString *)initWithBytes:(const char *)byteString encoding:(NSStringEncoding)encoding{
    return byteString == NULL ? nil : (NSString *)CFStringCreateWithCString(CFAllocatorGetDefault(), byteString, CFStringConvertNSStringEncodingToEncoding(encoding));
}

@end

// copied from OmniFoundation/NSData-OFExtensions.m
@implementation NSData (BDSKExtensions)

/*" Creates a stdio FILE pointer for reading from the receiver via the funopen() BSD facility.  The receiver is automatically retained until the returned FILE is closed. "*/

// Same context used for read and write.
typedef struct _NSDataFileContext {
    NSData *data;
    void   *bytes;
    size_t  length;
    size_t  position;
} NSDataFileContext;

static int _NSData_readfn(void *_ctx, char *buf, int nbytes)
{
    //fprintf(stderr, " read(ctx:%p buf:%p nbytes:%d)\n", _ctx, buf, nbytes);
    NSDataFileContext *ctx = (NSDataFileContext *)_ctx;

    nbytes = MIN((unsigned)nbytes, ctx->length - ctx->position);
    memcpy(buf, ctx->bytes + ctx->position, nbytes);
    ctx->position += nbytes;
    return nbytes;
}

static fpos_t _NSData_seekfn(void *_ctx, off_t offset, int whence)
{
    //fprintf(stderr, " seek(ctx:%p off:%qd whence:%d)\n", _ctx, offset, whence);
    NSDataFileContext *ctx = (NSDataFileContext *)_ctx;

    size_t reference;
    if (whence == SEEK_SET)
        reference = 0;
    else if (whence == SEEK_CUR)
        reference = ctx->position;
    else if (whence == SEEK_END)
        reference = ctx->length;
    else
        return -1;

    if (reference + offset >= 0 && reference + offset <= ctx->length) {
        ctx->position = reference + offset;
        return ctx->position;
    }
    return -1;
}

static int _NSData_closefn(void *_ctx)
{
    //fprintf(stderr, "close(ctx:%p)\n", _ctx);
    NSDataFileContext *ctx = (NSDataFileContext *)_ctx;
    [ctx->data release];
    free(ctx);
    
    return 0;
}


- (FILE *)openReadOnlyStandardIOFile {
    NSDataFileContext *ctx = calloc(1, sizeof(NSDataFileContext));
    ctx->data = [self retain];
    ctx->bytes = (void *)[self bytes];
    ctx->length = [self length];
    //fprintf(stderr, "open read -> ctx:%p\n", ctx);

    FILE *f = funopen(ctx, _NSData_readfn, NULL/*writefn*/, _NSData_seekfn, _NSData_closefn);
    if (f == NULL)
        [self release]; // Don't leak ourselves if funopen fails
    return f;
}

@end

