//
//  PubMedParser.m
//  Bibdesk
//
//  Created by Michael McCracken on Sun Nov 16 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "PubMedParser.h"
#import "html2tex.h"

@implementation PubMedParser

+ (NSMutableArray *)itemsFromString:(NSString *)itemString
                              error:(BOOL *)hadProblems{
    return [PubMedParser itemsFromString:itemString error:hadProblems frontMatter:nil filePath:@"Paste/Drag"];
}


+ (NSMutableArray *)itemsFromString:(NSString *)itemString
                              error:(BOOL *)hadProblems
                        frontMatter:(NSMutableString *)frontMatter
                           filePath:(NSString *)filePath{

    BibItem *newBI = nil;    

    int itemOrder = 1;
    // BibAppController *appController = (BibAppController *)[NSApp delegate]; // used to add autocomplete entries.

    NSMutableArray *returnArray = [NSMutableArray arrayWithCapacity:1];
    
    //dictionary is the publication entry
    NSMutableDictionary *pubDict = [[NSMutableDictionary alloc] init];
    const char * fs_path = NULL;
    NSString *tempFilePath = nil;
    BOOL usingTempFile = NO;
    
    if( !([filePath isEqualToString:@"Paste/Drag"]) && [[NSFileManager defaultManager] fileExistsAtPath:filePath]){
        fs_path = [[NSFileManager defaultManager] fileSystemRepresentationWithPath:filePath];
        usingTempFile = NO;
    }else{
        tempFilePath = [NSTemporaryDirectory() stringByAppendingPathComponent:[[NSProcessInfo processInfo] globallyUniqueString]];
        [itemString writeToFile:tempFilePath atomically:YES];
        fs_path = [[NSFileManager defaultManager] fileSystemRepresentationWithPath:tempFilePath];
        NSLog(@"using temporary file %@ - was it deleted?",tempFilePath);
        usingTempFile = YES;
    }
    
    // ARM:  This code came from Art Isbell to cocoa-dev on Tue Jul 10 22:13:11 2001.  Comments are his.
    //       We were using componentsSeparatedByString:@"\r", but this is not robust.  Files from ScienceDirect
    //       have \n as newlines, so this code handles those cases as well as PubMed.
    unsigned stringLength = [itemString length];  // start cocoadev
    unsigned startIndex;
    unsigned lineEndIndex = 0;
    unsigned contentsEndIndex;
    NSRange range;
    NSMutableArray *sourceLines = [NSMutableArray array];
    
    // There is more than one way to terminate this loop.  Beware of an
    // invalid termination test which might exist in this untested example :-)
    while (lineEndIndex < stringLength)
    {
	// Include only a single character in range.¬† Not sure whether
	// this will work with empty lines, but if not, try a length of 0.
	range = NSMakeRange(lineEndIndex, 1);
	[itemString getLineStart:&startIndex end:&lineEndIndex 
		     contentsEnd:&contentsEndIndex forRange:range];
	
	// If you want to exclude line terminators...
	[sourceLines addObject:[itemString 
	 substringWithRange:NSMakeRange(startIndex, contentsEndIndex - 
					startIndex)]];
    } // end cocoadev

    
    NSEnumerator *sourceLineE = [sourceLines objectEnumerator];
    NSString *sourceLine = nil;
    NSString *key = nil;
    NSString *bibTeXKey = nil;
    NSMutableString *wholeValue = [NSMutableString string];
    NSString *value = nil;
    BibTypeManager *typeManager = [BibTypeManager sharedManager];
    NSCharacterSet *whitespaceNewlineSet = [NSCharacterSet whitespaceAndNewlineCharacterSet];
    NSCharacterSet *newlineSet = [NSCharacterSet characterSetWithCharactersInString:@"\n"];
    NSCharacterSet *asciiSet = [NSCharacterSet characterSetWithRange:NSMakeRange(0, 127)];
    BOOL haveFAU = NO;
    BOOL usingAU = NO;
    
    NSString *prefix = nil;
    
    // set these up here, so we don't autorelease them every time we parse an entry
    // Some entries from Compendex have spaces in the tags, which is why we match 0-1 spaces between each character.
    AGRegex *findSubscriptLeadingTag = [AGRegex regexWithPattern:@"< ?s ?u ?b ?>"];
    AGRegex *findSubscriptOrSuperscriptTrailingTag = [AGRegex regexWithPattern:@"< ?/ ?s ?u ?[bp] ?>"];
    AGRegex *findSuperscriptLeadingTag = [AGRegex regexWithPattern:@"< ?s ?u ?p ?>"];
    
    // This one might require some explanation.  An entry with TI of "Flapping flight as a bifurcation in Re<sub>&omega;</sub>"
    // was run through the html conversion to give "...Re<sub>$\omega$</sub>", then the find sub/super regex replaced the sub tags to give
    // "...Re$_$omega$$", which LaTeX barfed on.  So, we now search for <sub></sub> tags with matching dollar signs inside, and remove the inner
    // dollar signs, since we'll use the dollar signs from our subsequent regex search and replace; however, we have to
    // reject the case where there is a <sub><\sub> by matching [^<]+ (at least one character which is not <), or else it goes to the next </sub> tag
    // and deletes dollar signs that it shouldn't touch.  Yuck.
    AGRegex *findNestedDollar = [AGRegex regexWithPattern:@"(< ?s ?u ?[bp] ?>[^<]+)(\\$)(.*)(\\$)(.*< ?/ ?s ?u ?[bp] ?>)"];
    
    // This is used for stripping extraneous characters from BibTeX year fields
    AGRegex *findYearString = [AGRegex regexWithPattern:@"(.*)(\\d{4})(.*)"];
    
    while(sourceLine = [sourceLineE nextObject]){
  
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    // NSLog(@"allocating pool at start");        
        sourceLine = [sourceLine stringByTrimmingCharactersInSet:newlineSet];
//        NSLog(@" = [%@]",sourceLine);        
        if([sourceLine length] > 5){

            prefix = [[sourceLine substringWithRange:NSMakeRange(0,4)] stringByTrimmingCharactersInSet:whitespaceNewlineSet];
            
            
            if([[sourceLine substringWithRange:NSMakeRange(4,1)] isEqualToString:@"-"]){
                // this is a "key - value" line
                
                value = [sourceLine substringWithRange:NSMakeRange(6,[sourceLine length]-6)];
                value = [value stringByTrimmingCharactersInSet:whitespaceNewlineSet];

                // Run the value string through the HTML2LaTeX conversion, to clean up &theta; and friends.
                // NB: do this before the regex find/replace on <sub> and <sup> tags, or else your LaTeX math
                // stuff will get munged.  Unfortunately, the C code for HTML2LaTeX will destroy accented characters, so we only send it ASCII, and just keep
                // the accented characters to let BDSKConverter deal with them later.
                
                NSScanner *scanner = [NSScanner scannerWithString:value];
                NSString *asciiAndHTMLChars;
                NSMutableString *fullString = [NSMutableString string];
                unsigned index = 0;
                
                while(![scanner isAtEnd]){
                    if([scanner scanCharactersFromSet:asciiSet intoString:&asciiAndHTMLChars]){
                        index = [scanner scanLocation];
                        [fullString appendString:TeXStringWithHTMLString([asciiAndHTMLChars UTF8String], stdout, NULL, [asciiAndHTMLChars length], NO, NO, NO)];
                    } else {
                        [fullString appendString:[value substringWithRange:NSMakeRange(index, 1)]];
                        [scanner setScanLocation:(index + 1)];
                    }
                }
                value = [[fullString copy] autorelease];
                
                // see if we have nested math modes and try to fix them; see note earlier on findNestedDollar
                if([findNestedDollar findInString:value] != nil){
                    NSLog(@"WARNING: found nested math mode; trying to repair...");
                     // NSLog(@"Original string was %@", value);
                    value = [findNestedDollar replaceWithString:@"$1$3$5"
                                                       inString:value];
                     // NSLog(@"String is now %@", value);
                }
                
                // Do a regex find and replace to put LaTeX subscripts and superscripts in place of the HTML
                // that Compendex (and possibly others) give us.
                value = [findSubscriptLeadingTag replaceWithString:@"\\$_{"
                                                          inString:value];
                value = [findSuperscriptLeadingTag replaceWithString:@"\\$^{"
                                                            inString:value];
                value = [findSubscriptOrSuperscriptTrailingTag replaceWithString:@"}\\$"
                                                                        inString:value];
                
                if([prefix isEqualToString:@"PMID"] || [prefix isEqualToString:@"TY"]){ // ARM:  PMID for Medline, TY for Elsevier-ScienceDirect.  I hope.
                    // we have a new publication
                    if([[pubDict allKeys] count] > 0){
                        // and we've already seen an old one: so save the old one off -
			            newBI = [self bibitemWithPubMedDictionary:pubDict fileOrder:itemOrder];
			            itemOrder ++;
                        [returnArray addObject:newBI];
                    }
                    [pubDict removeAllObjects];
                    [pubDict setObject:value forKey:prefix];
		    // reset these for the next pub
		    haveFAU = NO;
		    usingAU = NO;
                    
                }else{
                    // we just have a new key in the same publication.
                    // key is still the old value. prefix has the new key.
					//    NSLog(@"old key     - [%@]", key);
					//    NSLog(@"new, prefix - [%@]", prefix);
                    if(key){
						//	    NSLog(@"  inserting obj [%@] for key [%@]", wholeValue, key);
						// ARM:  I removed FAU = Author from the dictionary, because we need to discriminate between FAU and AU
						// and handle the case where AU occurs before FAU.  The final setObject: forKey: was blowing away
						// the AU values, otherwise, because it recognized FAU as Author.
						if([key isEqualToString:@"FAU"] && usingAU==NO){
                                                    haveFAU = YES;  // use full author info
                                                    [wholeValue replaceOccurrencesOfString:@"." 
                                                                                withString:@". "
                                                                                   options:NSLiteralSearch
                                                                                     range:NSMakeRange(0, [wholeValue length])];
                                                    addStringToDict([[wholeValue copy] autorelease], pubDict, @"Author");
						}else{
						    // If we didn't get a FAU key (shows up first in PubMed), fall back to AU
						    // AU is not in the dictionary, so we don't get confused with FAU
						    if([key isEqualToString:@"AU"] && haveFAU==NO){
							usingAU = YES;  // use AU info, and put FAU in its own field if it occurred too late
                                                        [wholeValue replaceOccurrencesOfString:@"." 
                                                                                    withString:@". "
                                                                                       options:NSLiteralSearch
                                                                                         range:NSMakeRange(0, [wholeValue length])];
							addStringToDict([[wholeValue copy] autorelease], pubDict, @"Author");
						    }else{
							// If we didn't get a FAU or AU, see if we have A1.  This is yet another variant of RIS.
							if([key isEqualToString:@"A1"] && haveFAU==NO){
							    usingAU = YES;  // use A1 info, and put FAU in its own field if it occurred too late
                                                            [wholeValue replaceOccurrencesOfString:@"." 
                                                                                        withString:@". "
                                                                                           options:NSLiteralSearch
                                                                                             range:NSMakeRange(0, [wholeValue length])];
							    addStringToDict([[wholeValue copy] autorelease], pubDict, @"Author");
							}else{
							    if([key isEqualToString:@"Keywords"]){ // may have multiple keywords, so concatenate them
                                    addStringToDict([[wholeValue copy] autorelease], pubDict, @"Keywords");
							    }else{
                                    if([key isEqualToString:@"Editor"]){ // may have multiple editors, so concatenate them
                                        addStringToDict([[wholeValue copy] autorelease], pubDict, @"Editor");
                                    } else {
                                        [pubDict setObject:[[wholeValue copy] autorelease] forKey:key];
                                    }
							    }
							}
						    }
						}
                    }
                    
                    bibTeXKey = [typeManager fieldNameForPubMedTag:prefix];
                    
                    if([bibTeXKey isEqualToString:@"Year"]){ 
                        // Scopus returns a PY with //// after it.  Others may return a full date, where BibTeX wants a year.  
                        // Use a regex to find a substring with four consecutive digits and use that instead.  Not sure how robust this is.
                        value = [findYearString replaceWithString:@"$2"
                                                         inString:value];
                    }                      

                    [wholeValue setString:value];
                    
                    if(bibTeXKey){
                        key = [bibTeXKey retain];  // retain needed for local autorelease pool
                    }else{
                        key = [prefix retain];     // retain needed for local autorelease pool
                    }
                    
                    key = [key stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                }

            }else{
                [wholeValue appendString:@" "];
                [wholeValue appendString:[sourceLine stringByTrimmingCharactersInSet:whitespaceNewlineSet]];
                // NSLog(@"cont. [%@]", sourceLine);
            }
            
        }
        [pool release]; 
        // NSLog(@"releasing pool");
    }
    

    
    if([[pubDict allKeys] count] > 0){
	newBI = [self bibitemWithPubMedDictionary:pubDict fileOrder:itemOrder];
	itemOrder ++;
	[returnArray addObject:newBI];
    }
    //    NSLog(@"pubDict is %@", pubDict);
    *hadProblems = NO;
    [pubDict release];
    return returnArray;
}

void addStringToDict(NSString *wholeValue, NSMutableDictionary *pubDict, NSString *theKey){
    NSString *oldString = [pubDict objectForKey:theKey];
    if(!oldString){
        [pubDict setObject:wholeValue forKey:theKey];
    } else {
        if( [theKey isEqualToString:@"Author"] && isDuplicateAuthor(oldString, wholeValue)==YES ){
            NSLog(@"Not adding duplicate author %@", wholeValue);
            return;
        }
        NSString *newString = [NSString stringWithFormat:@"%@ and %@", oldString, wholeValue];
        [pubDict setObject:newString forKey:theKey];
    }
}

BOOL isDuplicateAuthor(NSString *oldList, NSString *newAuthor){ // check to see if it's a duplicate; this relies on the whitespace around the " and ", and is basically a hack for Scopus
    NSArray *oldAuthArray = [oldList componentsSeparatedByString:@" and "];
    return [oldAuthArray containsObject:newAuthor];
}

void mergePageNumbers(NSMutableDictionary *dict){
    NSArray *keys = [dict allKeys];
    NSString *merge;
    
    if([keys containsObject:@"SP"] && [keys containsObject:@"EP"]){
	merge = [[[dict objectForKey:@"SP"] stringByAppendingString:@"--"] stringByAppendingString:[dict objectForKey:@"EP"]];
	[dict setObject:merge forKey:@"Pages"];
    }
}

+ (BibItem *)bibitemWithPubMedDictionary:(NSMutableDictionary *)pubDict fileOrder:(int)itemOrder{
    
    BibTypeManager *typeManager = [BibTypeManager sharedManager];
    BibItem *newBI = nil;
    
    // fix up the page numbers if necessary
    mergePageNumbers(pubDict);
    
    newBI = [[BibItem alloc] initWithType:@"misc"
				 fileType:@"BibTeX"
				  authors:[NSMutableArray arrayWithCapacity:0]];

    [newBI setFileOrder:itemOrder];
    [newBI setPubFields:pubDict];
    
    // set the pub type if we know the bibtex equivalent, otherwise leave it as misc
    if([typeManager bibtexTypeForPubMedType:[pubDict objectForKey:@"TY"]] != nil){ // "standard" RIS, if such a thing exists
        [newBI setType:[typeManager bibtexTypeForPubMedType:[pubDict objectForKey:@"TY"]]];
    } else {
        if([typeManager bibtexTypeForPubMedType:[pubDict objectForKey:@"PT"]] != nil){ // Medline RIS
            [newBI setType:[typeManager bibtexTypeForPubMedType:[pubDict objectForKey:@"PT"]]];
        }
    }
    // set the citekey, since RIS/Medline types don't have a citekey field
    [newBI setCiteKeyString:[newBI suggestedCiteKey]];
    
    return [newBI autorelease];
}


NSString* TeXStringWithHTMLString(const char *str, FILE *freport, char *html_fn, int ln,
			   BOOL in_math, BOOL in_verb, BOOL in_alltt)
{  
    
// ARM:  this code was taken directly from HTML2LaTeX.  I modified it to return
// an NSString object, since working with FILE* streams led to really nasty problems
// with NSPipe needing asynchronous reads to avoid blocking.
// The NSMutableString appendFormat method was used to replace all of the calls to
// fputc, fprintf, and fputs.
// The following copyright notice was taken verbatim from the HTML2LaTeX code:
    
/* HTML2LaTeX -- Converting HTML files to LaTeX
Copyright (C) 1995-2003 Frans Faase

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.

GNU General Public License:
http://home.planet.nl/~faase009/GNU.txt
*/
     

    NSMutableString *mString = [NSMutableString string];
    
    BOOL option_warn = YES;
    
	for(; *str; str++)
	{   BOOL special = NO;
		int v = 0;
		char ch = '\0';
		char html_ch[10];
		html_ch[0] = '\0';

            if (*str == '&')
            {   int i = 0;
                BOOL correct = NO;
                
                if (isalpha(str[1]))
                {   for (i = 0; i < 9; i++)
					if (isalpha(str[i+1]))
						html_ch[i] = str[i+1];
					else
						break;
                    html_ch[i] = '\0';
                    for (v = 0; v < NR_CH_TABLE; v++)
                        if (   ch_table[v].html_ch != NULL
                               && !strcmp(html_ch, ch_table[v].html_ch))
                        {   special = YES;
                            correct = YES;
                            ch = ch_table[v].ch;
                            break;
                        }
                }
                    else if (str[1] == '#')
                    {   int code = 0;
                        html_ch[0] = '#';
                        for (i = 1; i < 9; i++)
                            if (isdigit(str[i+1]))
                            {   html_ch[i] = str[i+1];
                                code = code * 10 + str[i+1] - '0';
                            }
                                else
                                    break;
                        if ((code >= ' ' && code < 127) || code == 8)
                        {   correct = YES;
                            ch = code;
                        }
                        else if (code >= 160 && code <= 255)
                        {
                            correct = YES;
                            special = YES;
                            v = code - 160;
                            ch = ch_table[v].ch;
                        }
                    }
                    html_ch[i] = '\0';
                    
                    if (correct)
                    {   str += i;
                        if (str[1] == ';')
                            str++;
                    }
                    else 
                    {   if (freport != NULL && option_warn)
                        if (html_ch[0] == '\0')
                            fprintf(freport,
                                    "%s (%d) : Replace `&' by `&amp;'.\n",
                                    html_fn, ln);
                        else
                            fprintf(freport,
                                    "%s (%d) : Unknown sequence `&%s;'.\n",
                                    html_fn, ln, html_ch);
                        ch = *str;
                    }
            }
                else if (((unsigned char)*str >= ' ' && (unsigned char)*str <= HIGHASCII) || *str == '\t')
                    ch = *str;
                else if (option_warn && freport != NULL)
                    fprintf(freport,
                            "%s (%d) : Unknown character %d (decimal)\n",
                            html_fn, ln, (unsigned char)*str);
                if (mString)
                {   if (in_verb)
                {   
                    [mString appendFormat:@"%c", ch != '\0' ? ch : ' '];
                    if (   special && freport != NULL && option_warn
                           && v < NR_CH_M)
                    {   fprintf(freport, "%s (%d) : ", html_fn, ln);
                        if (html_ch[0] == '\0')
                            fprintf(freport, "character %d (decimal)", 
                                    (unsigned char) *str);
                        else
                            fprintf(freport, "sequence `&%s;'", html_ch);
                        fprintf(freport, " rendered as `%c' in verbatim\n",
                                ch != '\0' ? ch : ' ');
                    }
                }
                    else if (in_alltt)
                    {   if (special)
                    {   char *o = ch_table[v].tex_ch;
                        if (o != NULL)
                            if (*o == '$')
                                [mString appendFormat:@"\\(%s\\)", o + 1];
                            else
                                [mString appendFormat:@"%s", o];
                    }
                        else if (ch == '{' || ch == '}')
                            [mString appendFormat:@"\\%c", ch];
                        else if (ch == '\\')
                            [mString appendFormat:@"\\%c", ch];
                        else if (ch != '\0')
                            [mString appendFormat:@"%c", ch];
                    }
                    else if (special)
                    {   char *o = ch_table[v].tex_ch;
                        if (o == NULL)
                        {   if (freport != NULL && option_warn)
                        {   fprintf(freport,
                                    "%s (%d) : no LaTeX representation for ",
                                    html_fn, ln);
                            if (html_ch[0] == '\0')
                                fprintf(freport, "character %d (decimal)\n", 
                                        (unsigned char) *str);
                            else
                                fprintf(freport, "sequence `&%s;'\n", html_ch);
                        }
                        }
                        else if (*o == '$')
                            if (in_math)
                                [mString appendFormat:@"%s", o+1];
                            else
                                [mString appendFormat:@"{%s$}", o];
                        else
                            [mString appendFormat:@"%s\n", o];
                    }
                    else if (in_math)
                    {   if (ch == '#' || ch == '%')
                            [mString appendFormat:@"\\%c", ch];
                        else
                            [mString appendFormat:@"%c", ch];
                    }
                    else
                    {   switch(ch)
                    {   case '\0' : break;
                                        case '\t': [mString appendString:@"        \n"]; break;
					case '_': case '{': case '}':
					case '#': case '$': case '%':
                       [mString appendFormat:@"{\\%c}", ch]; break;
                                        case '@' : [mString appendFormat:@"{\\char64}\n"]; break;
					case '[' :
					case ']' : [mString appendFormat:@"{$%c$}", ch]; break;
					case '"' : [mString appendString:@"{\\tt{}\"{}}\n"]; break;
					case '~' : [mString appendString:@"\\~{}\n"]; break;
                                        case '^' : [mString appendString:@"\\^{}\n"]; break;
					case '|' : [mString appendString:@"{$|$}\n"]; break;
					case '\\': [mString appendString:@"{$\\backslash$}\n"]; break;
					case '&' : [mString appendString:@"\\&\n"]; break;
                                        default: [mString appendFormat:@"%c", ch]; break;
                    }
                    }
                }
	}
    return mString;
}

@end
