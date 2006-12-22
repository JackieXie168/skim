//  NSString_BDSKExtensions.m

//  Created by Michael McCracken on Sun Jul 21 2002.
/*
 This software is Copyright (c) 2002,2003,2004,2005,2006
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

#import "NSString_BDSKExtensions.h"
#import <OmniFoundation/NSString-OFExtensions.h>
#import <Cocoa/Cocoa.h>
#import <AGRegex/AGRegex.h>
#import <OmniFoundation/OFCharacterSet.h>
#import <OmniFoundation/OFStringScanner.h>
#import "BibPrefController.h"
#import "CFString_BDSKExtensions.h"
#import "OFCharacterSet_BDSKExtensions.h"
#import "NSURL_BDSKExtensions.h"
#import "NSScanner_BDSKExtensions.h"
#import "html2tex.h"
#import "NSDictionary_BDSKExtensions.h"
#import "NSWorkspace_BDSKExtensions.h"
#import "BDSKStringEncodingManager.h"

static NSString *yesString = nil;
static NSString *noString = nil;
static NSString *mixedString = nil;

@implementation NSString (BDSKExtensions)

+ (void)didLoad
{
    yesString = [NSLocalizedString(@"Yes", @"") copy];
    noString = [NSLocalizedString(@"No", @"") copy];
    mixedString = [NSLocalizedString(@"-", @"indeterminate or mixed value indicator") copy];
    
}

+ (NSString *)hexStringForCharacter:(unichar)ch{
    NSMutableString *string = [NSMutableString stringWithCapacity:4];
    [string appendFormat:@"%X", ch];
    while([string length] < 4)
        [string insertString:@"0" atIndex:0];
    [string insertString:@"0x" atIndex:0];
    return string;
}

+ (NSString *)lossyASCIIStringWithString:(NSString *)aString{
    return [[[NSString alloc] initWithData:[aString dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES] encoding:NSASCIIStringEncoding] autorelease];
}

static int MAX_RATING = 5;
+ (NSString *)ratingStringWithInteger:(int)rating;
{
    NSParameterAssert(rating <= MAX_RATING);
    static CFMutableDictionaryRef ratings = NULL;
    if(ratings == NULL){
        ratings = CFDictionaryCreateMutable(CFAllocatorGetDefault(), MAX_RATING + 1, &OFIntegerDictionaryKeyCallbacks, &OFNSObjectDictionaryValueCallbacks);
        int i = 0;
        NSMutableString *ratingString = [NSMutableString string];
        do {
            CFDictionaryAddValue(ratings, (const void *)i, (const void *)[[ratingString copy] autorelease]);
            [ratingString appendCharacter:(0x278A + i)];
        } while(i++ < MAX_RATING);
        OBPOSTCONDITION((int)[(id)ratings count] == MAX_RATING + 1);
    }
    return (NSString *)CFDictionaryGetValue(ratings, (const void *)rating);
}

+ (NSString *)stringWithBool:(BOOL)boolValue {
	return boolValue ? yesString : noString;
}

+ (NSString *)stringWithContentsOfFile:(NSString *)path encoding:(NSStringEncoding)encoding guessEncoding:(BOOL)try;
{
    return [[self alloc] initWithContentsOfFile:path encoding:encoding guessEncoding:try];
}

+ (NSString *)stringWithTriStateValue:(NSCellStateValue)triStateValue {
    switch (triStateValue) {
        case NSOffState:
            return noString;
            break;
        case NSOnState:
            return yesString;
            break;
        case NSMixedState:
        default:
            return mixedString;
            break;
    }
}

+ (NSString *)unicodeNameOfCharacter:(unichar)ch;
{
    CFMutableStringRef charString = CFStringCreateMutable(CFAllocatorGetDefault(), 0);
    CFStringAppendCharacters(charString, &ch, 1);
    
    // ignore failures for now
    CFStringTransform(charString, NULL, kCFStringTransformToUnicodeName, FALSE);
    
    return [(id)charString autorelease];
} 
 
static inline BOOL dataHasUnicodeByteOrderMark(NSData *data)
{
    unsigned len = [data length];
    size_t size = sizeof(UniChar);
    BOOL rv = NO;
    if(len >= size){
        const UniChar bigEndianBOM = 0xfeff;
        const UniChar littleEndianBOM = 0xfffe;
        
        UniChar possibleBOM = 0;
        [data getBytes:&possibleBOM length:size];
        rv = (possibleBOM == bigEndianBOM || possibleBOM == littleEndianBOM);
    }
    return rv;
}

- (NSString *)initWithContentsOfFile:(NSString *)path encoding:(NSStringEncoding)encoding guessEncoding:(BOOL)try;
{
    if(self = [self init]){
        NSData *data = [[NSData alloc] initWithContentsOfFile:path];

        NSString *string = nil;
        if(encoding > 0)
            string = [[NSString alloc] initWithData:data encoding:encoding];
        if(nil == string && try && dataHasUnicodeByteOrderMark(data) && encoding != NSUnicodeStringEncoding)
            string = [[NSString alloc] initWithData:data encoding:NSUnicodeStringEncoding];
        if(nil == string && try && encoding != NSUTF8StringEncoding)
            string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        if(nil == string && try && encoding != [NSString defaultCStringEncoding])
            string = [[NSString alloc] initWithData:data encoding:[NSString defaultCStringEncoding]];
        if(nil == string && try && encoding != [BDSKStringEncodingManager defaultEncoding])
            string = [[NSString alloc] initWithData:data encoding:[BDSKStringEncodingManager defaultEncoding]];
        if(nil == string && try && encoding != NSISOLatin1StringEncoding)
            string = [[NSString alloc] initWithData:data encoding:NSISOLatin1StringEncoding];

        [data release];
        [self release];
        self = string;
    }
    return self;
}


#pragma mark TeX cleaning

- (NSString *)stringByConvertingDoubleHyphenToEndash{
    NSMutableString *string = nil;
    NSRange range = [self rangeOfString:@"--"];
    if(range.length){
        string = [NSMutableString stringWithString:self];
        [string replaceCharactersInRange:range withString:[NSString endashString]];
    }
    return string ? string : self;
}

- (NSString *)stringByRemovingCurlyBraces{
    return [self stringByRemovingCharactersInOFCharacterSet:[OFCharacterSet curlyBraceCharacterSet]];
}

- (NSString *)stringByRemovingTeX{
    NSMutableString *mutableString = [[self mutableCopy] autorelease];
    NSRange searchRange = NSMakeRange(0, [self length]);
    NSRange foundRange = [mutableString rangeOfTeXCommandInRange:searchRange];
    while(foundRange.length){
        [mutableString replaceCharactersInRange:foundRange withString:@""];
        searchRange.location = foundRange.location;
        searchRange.length -= foundRange.length;
        foundRange = [mutableString rangeOfTeXCommandInRange:searchRange];
    }
    [mutableString deleteCharactersInCharacterSet:[NSCharacterSet curlyBraceCharacterSet]];
    return mutableString;
}

#pragma mark TeX parsing

- (NSString *)entryType;
{
    // we could save a little memory by using a case-insensitive dictionary, but this is faster (and these strings are small)
    static NSMutableDictionary *entryDictionary = nil;
    if (nil == entryDictionary)
        entryDictionary = [[NSMutableDictionary alloc] initWithCapacity:100];
    
    NSString *entryType = [entryDictionary objectForKey:self];
    if (nil == entryType) {
        entryType = [self lowercaseString];
        [entryDictionary setObject:entryType forKey:self];
    }
    return entryType;
}

- (NSString *)fieldName;
{
    // we could save a little memory by using a case-insensitive dictionary, but this is faster (and these strings are small)
    static NSMutableDictionary *fieldDictionary = nil;
    if (nil == fieldDictionary)
        fieldDictionary = [[NSMutableDictionary alloc] initWithCapacity:100];
    
    NSString *fieldName = [fieldDictionary objectForKey:self];
    if (nil == fieldName) {
        fieldName = [self capitalizedString];
        [fieldDictionary setObject:fieldName forKey:self];
    }
    return fieldName;
}

- (unsigned)indexOfRightBraceMatchingLeftBraceAtIndex:(unsigned)startLoc
{
    
    CFStringInlineBuffer inlineBuffer;
    CFIndex length = CFStringGetLength((CFStringRef)self);
    CFIndex cnt;
    BOOL matchFound = NO;
    
    CFStringInitInlineBuffer((CFStringRef)self, &inlineBuffer, CFRangeMake(0, length));
    UniChar ch;
    int rb = 0, lb = 0;
    
    if(CFStringGetCharacterFromInlineBuffer(&inlineBuffer, startLoc) != '{')
        [NSException raise:NSInternalInconsistencyException format:@"character at index %i is not a brace", startLoc];
    
    // we don't consider escaped braces yet
    for(cnt = startLoc; cnt < length; cnt++){
        ch = CFStringGetCharacterFromInlineBuffer(&inlineBuffer, cnt);
        if(ch == '{')
            rb++;
        if(ch == '}')
            lb++;
        if(rb == lb){
            //NSLog(@"match found at index %i", cnt);
            matchFound = YES;
            break;
        }
    }
    
    return (matchFound == YES) ? cnt : NSNotFound;    
}

- (BOOL)isStringTeXQuotingBalancedWithBraces:(BOOL)braces connected:(BOOL)connected{
	return [self isStringTeXQuotingBalancedWithBraces:braces connected:connected range:NSMakeRange(0,[self length])];
}

- (BOOL)isStringTeXQuotingBalancedWithBraces:(BOOL)braces connected:(BOOL)connected range:(NSRange)range{
	int nesting = 0;
	NSCharacterSet *delimCharSet;
	unichar rightDelim;
	
	if (braces) {
		delimCharSet = [NSCharacterSet curlyBraceCharacterSet];
		rightDelim = '}';
	} else {
		delimCharSet = [NSCharacterSet characterSetWithCharactersInString:@"\""];
		rightDelim = '"';
	}
	
	NSRange delimRange = [self rangeOfCharacterFromSet:delimCharSet options:NSLiteralSearch range:range];
	int delimLoc = delimRange.location;
	
	while (delimLoc != NSNotFound) {
		if (delimLoc == 0 || [self characterAtIndex:delimLoc - 1] != '\\') {
			// we found an unescaped delimiter
			if (connected && nesting == 0) // connected quotes cannot have a nesting of 0 in the middle
				return NO;
			if ([self characterAtIndex:delimLoc] == rightDelim) {
				--nesting;
			} else {
				++nesting;
			}
			if (nesting < 0) // we should never get a negative nesting
				return NO;
		}
		// set the range to the part of the range after the last found brace
		range = NSMakeRange(delimLoc + 1, range.length - delimLoc + range.location - 1);
		// search for the next brace
		delimRange = [self rangeOfCharacterFromSet:delimCharSet options:NSLiteralSearch range:range];
		delimLoc = delimRange.location;
	}
	
	return (nesting == 0);
}

// transforms a bibtex string to have temp cite keys, using the method in openWithPhoneyKeys.
- (NSString *)stringWithPhoneyCiteKeys:(NSString *)tmpKey{
		// ^(@[[:alpha:]]+{),?$ will grab either "@type{,eol" or "@type{eol", which is what we get
		// from Bookends and EndNote, respectively.
		AGRegex *theRegex = [AGRegex regexWithPattern:@"^(@[[:alpha:]]+[ \\t]*{)[ \\t]*,?$" options:AGRegexCaseInsensitive];

		// should assert that the noKeysString matches theRegex
		//NSAssert([theRegex findInString:self] != nil, @"stringWithPhoneyCiteKeys called on non-matching string");

		// replace with "@type{FixMe,eol" (add the comma in, since we remove it if present)
		NSCharacterSet *newlineCharacterSet = [NSCharacterSet newlineCharacterSet];
		
		// do not use NSCharacterSets with OFStringScanners!
		OFCharacterSet *newlineOFCharset = [[[OFCharacterSet alloc] initWithCharacterSet:newlineCharacterSet] autorelease];
		
		OFStringScanner *scanner = [[[OFStringScanner alloc] initWithString:self] autorelease];
		NSMutableString *mutableFileString = [NSMutableString stringWithCapacity:[self length]];
		NSString *tmp = nil;
		int scanLocation = 0;
        NSString *replaceRegex = [NSString stringWithFormat:@"$1%@,", tmpKey];
		
		// we scan up to an (newline@) sequence, then to a newline; we then replace only in that line using theRegex, which is much more efficient than using AGRegex to find/replace in the entire string
		do {
			// append the previous part to the mutable string
			tmp = [scanner readFullTokenWithDelimiterCharacter:'@'];
			if(tmp) [mutableFileString appendString:tmp];
			
			scanLocation = scannerScanLocation(scanner);
			if(scanLocation == 0 || [newlineCharacterSet characterIsMember:[self characterAtIndex:scanLocation - 1]]){
				
				tmp = [scanner readFullTokenWithDelimiterOFCharacterSet:newlineOFCharset];
				
				// if we read something between the @ and newline, see if we can do the regex find/replace
				if(tmp){
					// this should be a noop if the pattern isn't matched
					tmp = [theRegex replaceWithString:replaceRegex inString:tmp];
					[mutableFileString appendString:tmp]; // guaranteed non-nil result from AGRegex
				}
			} else
				scannerReadCharacter(scanner);
                        
		} while(scannerHasData(scanner));
		
		NSString *toReturn = [NSString stringWithString:mutableFileString];
		
		return toReturn;
}

- (NSRange)rangeOfTeXCommandInRange:(NSRange)searchRange;
{
    CFRange cmdStartRange;
    CFIndex maxLen = CFStringGetLength((CFStringRef)self);    
    
    if(BDStringFindCharacter((CFStringRef)self, '\\', CFRangeMake(0, maxLen), &cmdStartRange) == FALSE)
        return NSMakeRange(NSNotFound, 0);
    
    CFRange lbraceRange;
    CFRange cmdSearchRange = CFRangeMake(cmdStartRange.location, maxLen - cmdStartRange.location);
    
    // find the nearest left brace, but return NSNotFound if there's a space between the command start and the left brace
    if(BDStringFindCharacter((CFStringRef)self, '{', cmdSearchRange, &lbraceRange) == FALSE ||
       BDStringFindCharacter((CFStringRef)self, ' ', CFRangeMake(cmdSearchRange.location, lbraceRange.location - cmdSearchRange.location), NULL) == TRUE)
        return NSMakeRange(NSNotFound, 0);
    
    // search for the next right brace matching our left brace
    CFRange rbraceRange;
    Boolean foundRBrace = BDStringFindCharacter((CFStringRef)self, '}', CFRangeMake(lbraceRange.location, maxLen - lbraceRange.location), &rbraceRange);
    
    // check for an immediate right brace after the left brace, as in \LaTeX{}, since we
    // don't want to remove those, either
    if(foundRBrace && (rbraceRange.location == lbraceRange.location + 1)){
        // if we want to consider \LaTeX a command to be removed, cmdStop = spaceLoc; this can mess
        // up sorting, though, since \LaTeX is a word /and/ a command.
        return NSMakeRange(NSNotFound, 0);
    } else {
        return NSMakeRange(cmdStartRange.location, (lbraceRange.location - cmdStartRange.location));
    }
    
}

- (NSString *)stringByConvertingHTMLToTeX;
{
    static NSCharacterSet *asciiSet = nil;
    if(asciiSet == nil)
        asciiSet = [[NSCharacterSet characterSetWithRange:NSMakeRange(0, 127)] retain];
    
    // set these up here, so we don't autorelease them every time we parse an entry
    // Some entries from Compendex have spaces in the tags, which is why we match 0-1 spaces between each character.
    static AGRegex *findSubscriptLeadingTag = nil;
    if(findSubscriptLeadingTag == nil)
        findSubscriptLeadingTag = [[AGRegex alloc] initWithPattern:@"< ?s ?u ?b ?>"];
    static AGRegex *findSubscriptOrSuperscriptTrailingTag = nil;
    if(findSubscriptOrSuperscriptTrailingTag == nil)
        findSubscriptOrSuperscriptTrailingTag = [[AGRegex alloc] initWithPattern:@"< ?/ ?s ?u ?[bp] ?>"];
    static AGRegex *findSuperscriptLeadingTag = nil;
    if(findSuperscriptLeadingTag == nil)
        findSuperscriptLeadingTag = [[AGRegex alloc] initWithPattern:@"< ?s ?u ?p ?>"];
    
    // This one might require some explanation.  An entry with TI of "Flapping flight as a bifurcation in Re<sub>&omega;</sub>"
    // was run through the html conversion to give "...Re<sub>$\omega$</sub>", then the find sub/super regex replaced the sub tags to give
    // "...Re$_$omega$$", which LaTeX barfed on.  So, we now search for <sub></sub> tags with matching dollar signs inside, and remove the inner
    // dollar signs, since we'll use the dollar signs from our subsequent regex search and replace; however, we have to
    // reject the case where there is a <sub><\sub> by matching [^<]+ (at least one character which is not <), or else it goes to the next </sub> tag
    // and deletes dollar signs that it shouldn't touch.  Yuck.
    static AGRegex *findNestedDollar = nil;
    if(findNestedDollar == nil)
        findNestedDollar = [[AGRegex alloc] initWithPattern:@"(< ?s ?u ?[bp] ?>[^<]+)(\\$)(.*)(\\$)(.*< ?/ ?s ?u ?[bp] ?>)"];
    
    // Run the value string through the HTML2LaTeX conversion, to clean up &theta; and friends.
    // NB: do this before the regex find/replace on <sub> and <sup> tags, or else your LaTeX math
    // stuff will get munged.  Unfortunately, the C code for HTML2LaTeX will destroy accented characters, so we only send it ASCII, and just keep
    // the accented characters to let BDSKConverter deal with them later.
    
    NSScanner *scanner = [[NSScanner alloc] initWithString:self];
    NSString *asciiAndHTMLChars, *nonAsciiAndHTMLChars;
    NSMutableString *fullString = [[NSMutableString alloc] initWithCapacity:[self length]];
    
    while(![scanner isAtEnd]){
        if([scanner scanCharactersFromSet:asciiSet intoString:&asciiAndHTMLChars])
            [fullString appendString:[NSString TeXStringWithHTMLString:asciiAndHTMLChars ]];
		if([scanner scanUpToCharactersFromSet:asciiSet intoString:&nonAsciiAndHTMLChars])
			[fullString appendString:nonAsciiAndHTMLChars];
    }
    [scanner release];
    
    NSString *newValue = [[fullString copy] autorelease];
    [fullString release];
    
    // see if we have nested math modes and try to fix them; see note earlier on findNestedDollar
    if([findNestedDollar findInString:newValue] != nil){
        NSLog(@"WARNING: found nested math mode; trying to repair...");
        newValue = [findNestedDollar replaceWithString:@"$1$3$5"
                                              inString:newValue];
    }
    
    // Do a regex find and replace to put LaTeX subscripts and superscripts in place of the HTML
    // that Compendex (and possibly others) give us.
    newValue = [findSubscriptLeadingTag replaceWithString:@"\\$_{" inString:newValue];
    newValue = [findSuperscriptLeadingTag replaceWithString:@"\\$^{" inString:newValue];
    newValue = [findSubscriptOrSuperscriptTrailingTag replaceWithString:@"}\\$" inString:newValue];
    
    return newValue;
}

+ (NSString *)TeXStringWithHTMLString:(NSString *)htmlString;
{
    const char *str = [htmlString UTF8String];
    int ln = strlen(str);
    FILE *freport = stdout;
    char *html_fn = NULL;
    BOOL in_math = NO;
    BOOL in_verb = NO;
    BOOL in_alltt = NO;
    
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
     

    NSMutableString *mString = [NSMutableString stringWithCapacity:ln];
    
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
                            [mString appendFormat:@"%s", o];
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
                                        case '\t': [mString appendString:@"        "]; break;
					case '_': case '{': case '}':
					case '#': case '$': case '%':
                       [mString appendFormat:@"{\\%c}", ch]; break;
                                        case '@' : [mString appendFormat:@"{\\char64}"]; break;
					case '[' :
					case ']' : [mString appendFormat:@"{$%c$}", ch]; break;
					case '"' : [mString appendString:@"{\\tt{}\"{}}"]; break;
					case '~' : [mString appendString:@"\\~{}"]; break;
                                        case '^' : [mString appendString:@"\\^{}"]; break;
					case '|' : [mString appendString:@"{$|$}"]; break;
					case '\\': [mString appendString:@"{$\\backslash$}"]; break;
					case '&' : [mString appendString:@"\\&"]; break;
                                        default: [mString appendFormat:@"%c", ch]; break;
                    }
                    }
                }
	}
    return mString;
}

- (NSArray *)sourceLinesBySplittingString;
{
    // ARM:  This code came from Art Isbell to cocoa-dev on Tue Jul 10 22:13:11 2001.  Comments are his.
    //       We were using componentsSeparatedByString:@"\r", but this is not robust.  Files from ScienceDirect
    //       have \n as newlines, so this code handles those cases as well as PubMed.
    unsigned stringLength = [self length];
    unsigned startIndex;
    unsigned lineEndIndex = 0;
    unsigned contentsEndIndex;
    NSRange range;
    NSMutableArray *sourceLines = [NSMutableArray array];
    
    // There is more than one way to terminate this loop.  Beware of an
    // invalid termination test which might exist in this untested example :-)
    while (lineEndIndex < stringLength)
    {
        // Include only a single character in range.  Not sure whether
        // this will work with empty lines, but if not, try a length of 0.
        range = NSMakeRange(lineEndIndex, 1);
        [self getLineStart:&startIndex 
                          end:&lineEndIndex 
                  contentsEnd:&contentsEndIndex 
                     forRange:range];
        
        // If you want to exclude line terminators...
        [sourceLines addObject:[self substringWithRange:NSMakeRange(startIndex, contentsEndIndex - startIndex)]];
    }
    return sourceLines;
}

- (NSString *)stringByEscapingGroupPlistEntities{
	NSMutableString *escapedValue = [self mutableCopy];
	// escape braces as they can give problems with btparse
	[escapedValue replaceAllOccurrencesOfString:@"%" withString:@"%25"]; // this should come first
	[escapedValue replaceAllOccurrencesOfString:@"{" withString:@"%7B"];
	[escapedValue replaceAllOccurrencesOfString:@"}" withString:@"%7D"];
	[escapedValue replaceAllOccurrencesOfString:@"<" withString:@"%3C"];
	[escapedValue replaceAllOccurrencesOfString:@">" withString:@"%3E"];
	return [escapedValue autorelease];
}

- (NSString *)stringByUnescapingGroupPlistEntities{
	NSMutableString *escapedValue = [self mutableCopy];
	// escape braces as they can give problems with btparse, and angles as they can give problems with the plist xml
	[escapedValue replaceAllOccurrencesOfString:@"%7B" withString:@"{"];
	[escapedValue replaceAllOccurrencesOfString:@"%7D" withString:@"}"];
	[escapedValue replaceAllOccurrencesOfString:@"%3C" withString:@"<"];
	[escapedValue replaceAllOccurrencesOfString:@"%3E" withString:@">"];
	[escapedValue replaceAllOccurrencesOfString:@"%25" withString:@"%"]; // this should come last
	return [escapedValue autorelease];
}

#pragma mark Comparisons

- (NSComparisonResult)localizedCaseInsensitiveNumericCompare:(NSString *)aStr{
    return [self compare:aStr
                 options:NSCaseInsensitiveSearch | NSNumericSearch
                   range:NSMakeRange(0, [self length])
                  locale:[[NSUserDefaults standardUserDefaults] dictionaryRepresentation]];
}

// -[NSString compare: options:NSNumericSearch] is buggy for string literals (tested on 10.4.3), but CFStringCompare() works and returns the same comparison constants
- (NSComparisonResult)numericCompare:(NSString *)otherString{
    return CFStringCompare((CFStringRef)self, (CFStringRef)otherString, kCFCompareNumerically);
}

- (NSString *)stringByRemovingTeXAndStopWords;
{
    CFMutableStringRef modifiedSelf = CFStringCreateMutableCopy(CFAllocatorGetDefault(), CFStringGetLength((CFStringRef)self), (CFStringRef)self);
    BDDeleteTeXForSorting(modifiedSelf);
    BDDeleteArticlesForSorting(modifiedSelf);
    return [(id)modifiedSelf autorelease];
}
    
- (NSComparisonResult)localizedCaseInsensitiveNonTeXNonArticleCompare:(NSString *)otherString;
{
    
    // Check before passing to CFStringCompare, as a nil argument causes a crash.  The caller has to handle nil comparisons.
    NSParameterAssert(otherString != nil);
    
    CFAllocatorRef allocator = CFAllocatorGetDefault();
    CFMutableStringRef modifiedSelf = CFStringCreateMutableCopy(allocator, CFStringGetLength((CFStringRef)self), (CFStringRef)self);
    CFMutableStringRef modifiedOther = CFStringCreateMutableCopy(allocator, CFStringGetLength((CFStringRef)otherString), (CFStringRef)otherString);
    
    BDDeleteTeXForSorting(modifiedSelf);
    BDDeleteTeXForSorting(modifiedOther);
    BDDeleteArticlesForSorting(modifiedSelf);
    BDDeleteArticlesForSorting(modifiedOther);
    
    // the mutating functions above should only create an empty string, not a nil string
    OBASSERT(modifiedSelf != nil);
    OBASSERT(modifiedOther != nil);
    
    // CFComparisonResult returns same values as NSComparisonResult
    CFComparisonResult result = CFStringCompare(modifiedSelf, modifiedOther, kCFCompareCaseInsensitive | kCFCompareLocalized);
    CFRelease(modifiedSelf);
    CFRelease(modifiedOther);
    
    return result;
}

- (NSComparisonResult)sortCompare:(NSString *)other{
    BOOL otherIsEmpty = [NSString isEmptyString:other];
	if ([self isEqualToString:@""]) {
		return (otherIsEmpty)? NSOrderedSame : NSOrderedDescending;
	} else if (otherIsEmpty) {
		return NSOrderedAscending;
	}
	return [self localizedCaseInsensitiveNumericCompare:other];
}    

- (NSComparisonResult)extensionCompare:(NSString *)other{
    NSString *myExtension = [self pathExtension];
    NSString *otherExtension = [other pathExtension];
    BOOL otherIsEmpty = [NSString isEmptyString:otherExtension];
	if ([myExtension isEqualToString:@""])
		return otherIsEmpty ? NSOrderedSame : NSOrderedDescending;
    if (otherIsEmpty)
		return NSOrderedAscending;
	return [myExtension localizedCaseInsensitiveCompare:otherExtension];
}    

- (NSComparisonResult)triStateCompare:(NSString *)other{
    // we order increasingly as 0, -1, 1
    int myValue = [self triStateValue];
    int otherValue = [other triStateValue];
    if (myValue == otherValue)
        return NSOrderedSame;
    else if (myValue == 0 || otherValue == 1)
        return NSOrderedAscending;
    else 
        return NSOrderedDescending;
}    

static BOOL canCreateFileURL(NSString *aString, BOOL *isURLString)
{
    // default return values
    BOOL canCreate = NO;
    *isURLString = NO;

    if ([aString hasPrefix:@"file://"]) {
        *isURLString = YES;
        canCreate = YES;
    } else if ([aString length]) {
        unichar ch = [aString characterAtIndex:0];
        if ('/' == ch || '~' == ch)
            canCreate = YES;
    }
    return canCreate;
}

static NSString *UTIForPath(NSString *aPath)
{
    BOOL isURLString;
    NSString *theUTI = nil;
    // !!! We return nil when a file doesn't exist if it's a properly resolvable path/URL, but we have no way of checking existence with a relative path.  Returning nil is preferable, since then nonexistent files will be sorted to the top or bottom and they're easy to find.
    if (canCreateFileURL(aPath, &isURLString)) {
        NSURL *fileURL = (isURLString ? [[NSURL alloc] initWithString:aPath] : [[NSURL alloc] initFileURLWithPath:[aPath stringByStandardizingPath]]);
        
        // UTI will be nil for a file that doesn't exist, yet had an absolute/resolvable path
        if (fileURL) {
            theUTI = [[NSWorkspace sharedWorkspace] UTIForURL:fileURL error:NULL];
            [fileURL release];
        }
        
    } else {
        
        // fall back to extension; this is probably a relative path, so we'll assume it exists
        NSString *extension = [aPath pathExtension];
        if ([extension isEqualToString:@""] == NO)
            theUTI = [[NSWorkspace sharedWorkspace] UTIForPathExtension:extension];
    }
    return theUTI;
}

- (NSComparisonResult)UTICompare:(NSString *)other{
    NSString *otherUTI = UTIForPath(other);
    NSString *selfUTI = UTIForPath(self);
    if (nil == selfUTI)
        return (nil == otherUTI ? NSOrderedSame : NSOrderedDescending);
    if (nil == otherUTI)
        return NSOrderedAscending;
    return [selfUTI caseInsensitiveCompare:otherUTI];
}

#pragma mark -

- (BOOL)booleanValue{
    // Omni's boolValue method uses YES, Y, yes, y and 1 with isEqualToString
    if([self compare:[NSString stringWithBool:YES] options:NSCaseInsensitiveSearch] == NSOrderedSame ||
       [self compare:@"y" options:NSCaseInsensitiveSearch] == NSOrderedSame ||
       [self isEqualToString:@"1"])
        return YES;
    else
        return NO;
}

- (NSCellStateValue)triStateValue{
    if([self booleanValue] == YES){
        return NSOnState;
    }else if([self isEqualToString:@""] ||
             [self compare:[NSString stringWithBool:NO] options:NSCaseInsensitiveSearch] == NSOrderedSame ||
             [self compare:@"n" options:NSCaseInsensitiveSearch] == NSOrderedSame ||
             [self isEqualToString:@"0"]){
        return NSOffState;
    }else{
        return NSMixedState;
    }
}

- (NSString *)acronymValueIgnoringWordLength:(unsigned int)ignoreLength{
    NSMutableString *result = [NSMutableString string];
    NSArray *allComponents = [self componentsSeparatedByString:@" "]; // single whitespace
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

#pragma mark -

- (BOOL)containsString:(NSString *)searchString options:(unsigned int)mask range:(NSRange)aRange{
    return !searchString || [searchString length] == 0 || [self rangeOfString:searchString options:mask range:aRange].length > 0;
}

- (BOOL)containsWord:(NSString *)aWord{
    
    NSRange subRange = [self rangeOfString:aWord];
    
    if(subRange.location == NSNotFound)
        return NO;
    
    CFIndex wordLength = [aWord length];
    CFIndex myLength = [self length];
    
    // trivial case; we contain the word, and have the same length
    if(myLength == wordLength)
        return YES;
    
    CFIndex beforeIndex, afterIndex;
    
    beforeIndex = subRange.location - 1;
    afterIndex = NSMaxRange(subRange);
    
    UniChar beforeChar = '\0', afterChar = '\0';
    
    if(beforeIndex >= 0)
        beforeChar = [self characterAtIndex:beforeIndex];
    
    if(afterIndex < myLength)
        afterChar = [self characterAtIndex:afterIndex];
    
    static NSCharacterSet *wordTestSet = nil;
    if(wordTestSet == nil){
        NSMutableCharacterSet *set = [[NSCharacterSet punctuationCharacterSet] mutableCopy];
        [set formUnionWithCharacterSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        wordTestSet = [set copy];
        [set release];
    }
    
    // if a character appears before the start of the substring match, see if it is punctuation or whitespace
    if(beforeChar && [wordTestSet characterIsMember:beforeChar] == NO)
        return NO;
    
    // now check after the substring match
    if(afterChar && [wordTestSet characterIsMember:afterChar] == NO)
        return NO;
    
    return YES;
}

- (BOOL)hasCaseInsensitivePrefix:(NSString *)prefix;
{
    unsigned int length = [prefix length];
    if(prefix == nil || length > [self length])
        return NO;
    
    return (CFStringCompareWithOptions((CFStringRef)self,(CFStringRef)prefix, CFRangeMake(0, length), kCFCompareCaseInsensitive) == kCFCompareEqualTo ? YES : NO);
}

#pragma mark -

- (NSArray *)componentsSeparatedByCharactersInSet:(NSCharacterSet *)charSet trimWhitespace:(BOOL)trim;
{
    return [(id)BDStringCreateComponentsSeparatedByCharacterSetTrimWhitespace(CFAllocatorGetDefault(), (CFStringRef)self, (CFCharacterSetRef)charSet, trim) autorelease];
}

- (NSArray *)componentsSeparatedByStringCaseInsensitive:(NSString *)separator;
{
    return [(id)BDStringCreateArrayBySeparatingStringsWithOptions(CFAllocatorGetDefault(), (CFStringRef)self, (CFStringRef)separator, kCFCompareCaseInsensitive) autorelease];
}

- (NSString *)fastStringByCollapsingWhitespaceAndRemovingSurroundingWhitespace;
{
    return [(id)BDStringCreateByCollapsingAndTrimmingWhitespace(CFAllocatorGetDefault(), (CFStringRef)self) autorelease];
}

- (NSString *)fastStringByCollapsingWhitespaceAndNewlinesAndRemovingSurroundingWhitespaceAndNewlines;
{
    return [(id)BDStringCreateByCollapsingAndTrimmingWhitespaceAndNewlines(CFAllocatorGetDefault(), (CFStringRef)self) autorelease];
}

- (NSString *)stringByNormalizingSpacesAndLineBreaks;
{
    return [(id)BDStringCreateByNormalizingWhitespaceAndNewlines(CFAllocatorGetDefault(), (CFStringRef)self) autorelease];
}

- (NSString *)stringByTrimmingFromLastPunctuation{
    NSRange range = [self rangeOfCharacterFromSet:[NSCharacterSet punctuationCharacterSet] options:NSBackwardsSearch];
    
    if(range.location != NSNotFound && (range.location += 1) < [self length])
        return [self substringWithRange:NSMakeRange(range.location, [self length] - range.location)];
    else
        return self;
}

- (NSString *)stringByTrimmingPrefixCharactersFromSet:(NSCharacterSet *)characterSet;
{
    NSString *string = nil;
    NSScanner *scanner = [[NSScanner alloc] initWithString:self];
    [scanner setCharactersToBeSkipped:nil];
    [scanner scanCharactersFromSet:characterSet intoString:nil];
    NSRange range = NSMakeRange(0, [scanner scanLocation]);
    [scanner release];
    
    if(range.length){
        NSMutableString *mutableCopy = [self mutableCopy];
        [mutableCopy deleteCharactersInRange:range];
        string = [mutableCopy autorelease];
    }
    return string ? string : self;
}

- (NSString *)stringByAppendingEllipsis{
    return [self stringByAppendingString:[NSString horizontalEllipsisString]];
}

#pragma mark HTML/XML

- (NSString *)stringByConvertingHTMLLineBreaks{
    NSMutableString *rv = [self mutableCopy];
    [rv replaceOccurrencesOfString:@"\n" 
                        withString:@"<br>"
                           options:NSCaseInsensitiveSearch
                             range:NSMakeRange(0,[self length])];
    return [rv autorelease];
}

- (NSString *)stringByEscapingBasicXMLEntitiesUsingUTF8;
{
    return [OFXMLCreateStringWithEntityReferencesInCFEncoding(self, OFXMLBasicEntityMask, nil, kCFStringEncodingUTF8) autorelease];
}
    
#define APPEND_PREVIOUS() \
    string = [[NSString alloc] initWithCharacters:begin length:(ptr - begin)]; \
        [result appendString:string]; \
            [string release]; \
                begin = ptr + 1;

// Stolen and modified from the OmniFoundation -htmlString.
- (NSString *)xmlString;
{
    unichar *ptr, *begin, *end;
    NSMutableString *result;
    NSString *string;
    int length;
    
    length = [self length];
    ptr = alloca(length * sizeof(unichar));
    end = ptr + length;
    [self getCharacters:ptr];
    result = [NSMutableString stringWithCapacity:length];
    
    begin = ptr;
    while (ptr < end) {
        if (*ptr > 127) {
            APPEND_PREVIOUS();
            [result appendFormat:@"&#%d;", (int)*ptr];
        } else if (*ptr == '&') {
            APPEND_PREVIOUS();
            [result appendString:@"&amp;"];
        } else if (*ptr == '\"') {
            APPEND_PREVIOUS();
            [result appendString:@"&quot;"];
        } else if (*ptr == '<') {
            APPEND_PREVIOUS();
            [result appendString:@"&lt;"];
        } else if (*ptr == '>') {
            APPEND_PREVIOUS();
            [result appendString:@"&gt;"];
        } else if (*ptr == '\n') {
            APPEND_PREVIOUS();
            if (ptr + 1 != end && *(ptr + 1) == '\n') {
                [result appendString:@"&lt;p&gt;"];
                ptr++;
            } else
                [result appendString:@"&lt;br&gt;"];
        }
        ptr++;
    }
    APPEND_PREVIOUS();
    return result;
}

- (NSString *)csvString;
{
    unichar *ptr, *begin, *end;
    NSMutableString *result;
    NSString *string;
    int length;
    BOOL isQuoted, needsSpace;
    
    length = [self length];
    ptr = alloca(length * sizeof(unichar));
    end = ptr + length;
    [self getCharacters:ptr];
    result = [NSMutableString stringWithCapacity:length];
    isQuoted = length > 0 && (*ptr == ' ' || *(end-1) == ' ');
    needsSpace = NO;
    
    if(isQuoted == NO && [self containsCharacterInSet:[NSCharacterSet characterSetWithCharactersInString:@"\n\r\t\","]] == NO)
        return self;
    
    begin = ptr;
    while (ptr < end) {
        switch (*ptr) {
            case '\n':
            case '\r':
                APPEND_PREVIOUS();
                if (needsSpace)
                    [result appendString:@" "];
            case ' ':
            case '\t':
                needsSpace = NO;
                break;
            case '"':
                APPEND_PREVIOUS();
                [result appendString:@"\"\""];
            case ',':
                isQuoted = YES;
            default:
                needsSpace = YES;
                break;
        }
        ptr++;
    }
    APPEND_PREVIOUS();
    if (isQuoted) {
        [result insertString:@"\"" atIndex:0];
        [result appendString:@"\""];
    }
    return result;
}

- (NSString *)tsvString;
{
    if([self containsCharacterInSet:[NSCharacterSet characterSetWithCharactersInString:@"\t\n\r"]] == NO)
        return self;
    
    unichar *ptr, *begin, *end;
    NSMutableString *result;
    NSString *string;
    int length;
    BOOL needsSpace;
    
    length = [self length];
    ptr = alloca(length * sizeof(unichar));
    end = ptr + length;
    [self getCharacters:ptr];
    result = [NSMutableString stringWithCapacity:length];
    needsSpace = NO;
    
    begin = ptr;
    while (ptr < end) {
        switch (*ptr) {
            case '\t':
                needsSpace = YES;
            case '\n':
            case '\r':
                APPEND_PREVIOUS();
                if (needsSpace)
                    [result appendString:@" "];
            case ' ':
                needsSpace = NO;
                break;
            default:
                needsSpace = YES;
                break;
        }
        ptr++;
    }
    APPEND_PREVIOUS();
    return result;
}

#pragma mark -
#pragma mark Search string splitting

// splits a search string into nested arrays, split by '|' and '+', with '+' taking precedence over '|'
// e.g. a|b+c will be split as ((a),(b,c))
- (NSArray *)searchComponents;
{
    NSEnumerator *andEnum, *orEnum = [[self componentsSeparatedByString:@"|"] objectEnumerator];
    NSString *s;
    NSMutableArray *andArray, *orArray = [NSMutableArray array];
    
    while(s = [orEnum nextObject]){
        andEnum = [[s componentsSeparatedByString:@"+"] objectEnumerator];
        andArray = [NSMutableArray array];
        while(s = [andEnum nextObject]){
            s = [s stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            if([NSString isEmptyString:s] == NO)
               [andArray addObject:s];
        }
        if([andArray count] > 0)
            [orArray addObject:andArray];
    }
    return orArray;
}

#pragma mark Script arguments

// parses a space separated list of shell script argments
// allows quoting parts of an argument and escaped characters outside quotes, according to shell rules
- (NSArray *)shellScriptArgumentsArray {
    static NSCharacterSet *specialChars = nil;
    static NSCharacterSet *quoteChars = nil;
    
    if (specialChars == nil) {
        NSMutableCharacterSet *tmpSet = [[NSCharacterSet whitespaceAndNewlineCharacterSet] mutableCopy];
        [tmpSet addCharactersInString:@"\\\"'`"];
        specialChars = [tmpSet copy];
        [tmpSet release];
        quoteChars = [[NSCharacterSet characterSetWithCharactersInString:@"\"'`"] retain];
    }
    
    NSScanner *scanner = [NSScanner scannerWithString:self];
    NSString *s = nil;
    unichar ch = 0;
    NSMutableString *currArg = [scanner isAtEnd] ? nil : [NSMutableString string];
    NSMutableArray *arguments = [NSMutableArray array];
    
    [scanner setCharactersToBeSkipped:nil];
    [scanner scanCharactersFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet] intoString:NULL];
    
    while ([scanner isAtEnd] == NO) {
        if ([scanner scanUpToCharactersFromSet:specialChars intoString:&s])
            [currArg appendString:s];
        if ([scanner scanCharacter:&ch] == NO)
            break;
        if ([[NSCharacterSet whitespaceAndNewlineCharacterSet] characterIsMember:ch]) {
            // argument separator, add the last one we found and ignore more whitespaces
            [scanner scanCharactersFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet] intoString:NULL];
            [arguments addObject:currArg];
            currArg = [scanner isAtEnd] ? nil : [NSMutableString string];
        } else if (ch == '\\') {
            // escaped character
            if ([scanner scanCharacter:&ch] == NO)
                [NSException raise:NSInternalInconsistencyException format:@"Missing character"];
            if ([currArg length] == 0 && [[NSCharacterSet newlineCharacterSet] characterIsMember:ch])
                // ignore escaped newlines between arguments, as they should be considered whitespace
                [scanner scanCharactersFromSet:[NSCharacterSet newlineCharacterSet] intoString:NULL];
            else // real escaped character, just add the character, so we can ignore it if it is a special character
                [currArg appendFormat:@"%C", ch];
        } else if ([quoteChars characterIsMember:ch]) {
            // quoted part of an argument, scan up to the matching quote
            if ([scanner scanUpToCharactersFromSet:[NSCharacterSet characterSetWithRange:NSMakeRange(ch, 1)] intoString:&s])
                [currArg appendString:s];
            if ([scanner scanCharacter:NULL] == NO)
                [NSException raise:NSInternalInconsistencyException format:@"Unmatched %C", ch];
        }
    }
    if (currArg)
        [arguments addObject:currArg];
    return arguments;
}

// parses a comma separated list of AppleScript type arguments
- (NSArray *)appleScriptArgumentsArray {
    static NSCharacterSet *commaChars = nil;
    if (commaChars == nil)
        commaChars = [[NSCharacterSet characterSetWithCharactersInString:@","] retain];
    
    NSMutableArray *arguments = [NSMutableArray array];
    NSScanner *scanner = [NSScanner scannerWithString:self];
    unichar ch = 0;
    id object;
    
    [scanner setCharactersToBeSkipped:nil];
    
    while ([scanner isAtEnd] == NO) {
        if ([scanner scanAppleScriptValueUpToCharactersInSet:commaChars intoObject:&object])
            [arguments addObject:object];
        if ([scanner scanCharacter:&ch] == NO)
            break;
        if (ch != ',')
            [NSException raise:NSInternalInconsistencyException format:@"Missing ,"];
    }
    return arguments;
}

#pragma mark Empty lines

// whitespace at the beginning of the string up to the end or until (and including) a newline
- (NSRange)rangeOfLeadingEmptyLine {
    return [self rangeOfLeadingEmptyLineInRange:NSMakeRange(0, [self length])];
}

- (NSRange)rangeOfLeadingEmptyLineInRange:(NSRange)range {
    NSRange firstCharRange = [self rangeOfCharacterFromSet:[NSCharacterSet nonWhitespaceCharacterSet] options:0 range:range];
    NSRange wsRange = NSMakeRange(NSNotFound, 0);
    unsigned int start = range.location;
    if (firstCharRange.location == NSNotFound) {
        wsRange = range;
    } else {
        unichar firstChar = [self characterAtIndex:firstCharRange.location];
        unsigned int rangeEnd = NSMaxRange(firstCharRange);
        if([[NSCharacterSet newlineCharacterSet] characterIsMember:firstChar]) {
            if (firstChar == '\r' && rangeEnd < NSMaxRange(range) && [self characterAtIndex:rangeEnd] == '\n')
                wsRange = NSMakeRange(start, rangeEnd + 1 - start);
            else 
                wsRange = NSMakeRange(start, rangeEnd - start);
        }
    }
    return wsRange;
}

// whitespace at the end of the string from the beginning or after a newline
- (NSRange)rangeOfTrailingEmptyLine {
    return [self rangeOfTrailingEmptyLineInRange:NSMakeRange(0, [self length])];
}

- (NSRange)rangeOfTrailingEmptyLineInRange:(NSRange)range {
    NSRange lastCharRange = [self rangeOfCharacterFromSet:[NSCharacterSet nonWhitespaceCharacterSet] options:NSBackwardsSearch range:range];
    NSRange wsRange = NSMakeRange(NSNotFound, 0);
    unsigned int end = NSMaxRange(range);
    if (lastCharRange.location == NSNotFound) {
        wsRange = range;
    } else {
        unichar lastChar = [self characterAtIndex:lastCharRange.location];
        unsigned int rangeEnd = NSMaxRange(lastCharRange);
        if (rangeEnd < end && [[NSCharacterSet newlineCharacterSet] characterIsMember:lastChar]) 
            wsRange = NSMakeRange(rangeEnd, end - rangeEnd);
    }
    return wsRange;
}

#pragma mark Some convenience keys for templates

- (NSURL *)url {
    NSURL *url = nil;
    if ([self rangeOfString:@"://"].location != NSNotFound)
        url = [NSURL URLWithStringByNormalizingPercentEscapes:self];
    else
        url = [NSURL fileURLWithPath:[self stringByExpandingTildeInPath]];
    return url;
}

- (NSAttributedString *)linkedText {
    return [[[NSAttributedString alloc] initWithString:self attributeName:NSLinkAttributeName attributeValue:[self url]] autorelease];
}

- (NSAttributedString *)icon {
    return [[self url] icon];
}

- (NSAttributedString *)smallIcon {
    return [[self url] smallIcon];
}

- (NSAttributedString *)linkedIcon {
    return [[self url] linkedIcon];
}

- (NSAttributedString *)linkedSmallIcon {
    return [[self url] linkedSmallIcon];
}

- (NSString *)titleCapitalizedString {
    NSScanner *scanner = [[NSScanner alloc] initWithString:self];
    NSString *s = nil;
    NSMutableString *returnString = [NSMutableString stringWithCapacity:[self length]];
    [NSCharacterSet curlyBraceCharacterSet];
    int nesting = 0;
    unichar ch;
    unsigned location;
    NSRange range;
    
    [scanner setCharactersToBeSkipped:nil];
    
    while([scanner isAtEnd] == NO){
        if([scanner scanUpToCharactersFromSet:[NSCharacterSet curlyBraceCharacterSet] intoString:&s])
            [returnString appendString:nesting == 0 ? [s lowercaseString] : s];
        if([scanner scanCharacter:&ch] == NO)
            continue;
        [returnString appendFormat:@"%C", ch];
        location = [scanner scanLocation];
        if(location > 0 && [self characterAtIndex:location - 1] == '\\')
            continue;
        if(ch == '{')
            nesting++;
        else
            nesting--;
    }
    
    range = [returnString rangeOfCharacterFromSet:[NSCharacterSet letterCharacterSet]];
    if(range.location != NSNotFound)
        [returnString replaceCharactersInRange:range withString:[[returnString substringWithRange:range] uppercaseString]];
    
    [scanner release];
    
    return returnString;
}

@end


@implementation NSMutableString (BDSKExtensions)

- (BOOL)isMutableString;
{
    @try{
        [self appendCharacter:'X'];
    }
    @catch(id localException){
        if([localException respondsToSelector:@selector(name)] && [[localException name] isEqual:NSInvalidArgumentException])
            return NO;
        else
            @throw;
    }
    
    [self deleteCharactersInRange:NSMakeRange([self length] - 1, 1)];
    return YES;
}

- (void)deleteCharactersInCharacterSet:(NSCharacterSet *)characterSet;
{
    BDDeleteCharactersInCharacterSet((CFMutableStringRef)self, (CFCharacterSetRef)characterSet);
}

@end
