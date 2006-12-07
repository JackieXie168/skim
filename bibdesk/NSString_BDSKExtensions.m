//  NSString_BDSKExtensions.m

//  Created by Michael McCracken on Sun Jul 21 2002.
/*
 This software is Copyright (c) 2002,2003,2004,2005
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

@implementation NSString (BDSKExtensions)

- (NSString *)uniquePathByAddingNumber{
    NSFileManager *dfm = [NSFileManager defaultManager];
    NSMutableString *result = nil;
    NSString *extension = nil;
    NSCharacterSet *numbers = [NSCharacterSet characterSetWithCharactersInString:@"0123456789"];
    unichar c;
    
    extension = [self pathExtension];
    result = [[[self stringByDeletingPathExtension] mutableCopy] autorelease];
    
    c = [[[result copy] autorelease] lastCharacter];
    
    if ([numbers characterIsMember:c]) {
        switch(c){
            case '0':
                [result replaceCharactersInRange:NSMakeRange([result length]-1, 1)
                                      withString:@"1"];
                break;
            case '1':
                [result replaceCharactersInRange:NSMakeRange([result length]-1, 1)
                                      withString:@"2"];
                break;
            case '2':
                [result replaceCharactersInRange:NSMakeRange([result length]-1, 1)
                                      withString:@"3"];
                break;
            case '3':
                [result replaceCharactersInRange:NSMakeRange([result length]-1, 1)
                                      withString:@"4"];
                break;
            case '4':
                [result replaceCharactersInRange:NSMakeRange([result length]-1, 1)
                                      withString:@"5"];
                break;
            case '5':
                [result replaceCharactersInRange:NSMakeRange([result length]-1, 1)
                                      withString:@"6"];
                break;
            case '6':
                [result replaceCharactersInRange:NSMakeRange([result length]-1, 1)
                                      withString:@"7"];
                break;
            case '7':
                [result replaceCharactersInRange:NSMakeRange([result length]-1, 1)
                                      withString:@"8"];
                break;
            case '8':
                [result replaceCharactersInRange:NSMakeRange([result length]-1, 1)
                                      withString:@"9"];
                break;
            case '9':
                [result replaceCharactersInRange:NSMakeRange([result length]-1, 1)
                                      withString:@""];
                result = [[[result uniquePathByAddingNumber] mutableCopy] autorelease];
                [result replaceCharactersInRange:NSMakeRange([result length]-1, 1)
                                      withString:@"0"];
                break;
        }
    }else{
        [result appendString:@"1"];
    }

    if ([dfm fileExistsAtPath:[[result stringByAppendingPathExtension:extension] stringByExpandingTildeInPath]]) {
        return [[result stringByAppendingPathExtension:extension] uniquePathByAddingNumber];
    }
    return [result stringByAppendingPathExtension:extension];
}

// Stolen and modified from the OmniFoundation -htmlString.
- (NSString *)xmlString;
{
    unichar *ptr, *begin, *end;
    NSMutableString *result;
    NSString *string;
    int length;

#define APPEND_PREVIOUS() \
    string = [[NSString alloc] initWithCharacters:begin length:(ptr - begin)]; \
        [result appendString:string]; \
            [string release]; \
                begin = ptr + 1;

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

- (NSString *)stringByConvertingHTMLLineBreaks{
    NSMutableString *rv = [self mutableCopy];
    [rv replaceOccurrencesOfString:@"\n" 
                        withString:@"<br>"
                           options:NSCaseInsensitiveSearch
                             range:NSMakeRange(0,[self length])];
    return [rv autorelease];
}

+ (NSString *)lossyASCIIStringWithString:(NSString *)aString{
    return [[[NSString alloc] initWithData:[aString dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES] 
                                  encoding:NSASCIIStringEncoding] autorelease];
}

- (NSString *)stringByRemovingCurlyBraces{
    static OFCharacterSet *braceSet = nil;
    
    if(braceSet == nil)
        braceSet = [[OFCharacterSet alloc] initWithString:@"{}"];
    
    //NSAssert(braceSet != nil, @"OFCharacterSet must not be nil.");
    
    return [self stringByRemovingCharactersInOFCharacterSet:braceSet];
}
 
+ (NSString *)stringWithBytes:(const char *)byteString encoding:(NSStringEncoding)encoding{
    return [[[NSString alloc] initWithBytes:byteString length:strlen(byteString) encoding:encoding] autorelease];
}

- (NSString *)initWithBytes:(const char *)byteString encoding:(NSStringEncoding)encoding{
    return [self initWithBytes:byteString length:strlen(byteString) encoding:encoding];
}

- (BOOL)isStringTeXQuotingBalancedWithBraces:(BOOL)braces connected:(BOOL)connected{
	return [self isStringTeXQuotingBalancedWithBraces:braces connected:connected range:NSMakeRange(0,[self length])];
}

- (BOOL)isStringTeXQuotingBalancedWithBraces:(BOOL)braces connected:(BOOL)connected range:(NSRange)range{
	int nesting = 0;
	NSCharacterSet *delimCharSet;
	unichar rightDelim;
	
	if (braces) {
		delimCharSet = [NSCharacterSet characterSetWithCharactersInString:@"{}"];
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

- (BOOL)isRISString{ // sniff the string to see if it's or RIS
    NSScanner *scanner = [[NSScanner alloc] initWithString:self];
    [scanner setCharactersToBeSkipped:nil];
    BOOL isRIS = NO;
    if([scanner scanString:@"PMID-" intoString:nil] &&
       [scanner scanCharactersFromSet:[NSCharacterSet whitespaceCharacterSet] intoString:nil]) // for Medline
        isRIS = YES;
    else {
        [scanner setScanLocation:0];
        if([scanner scanString:@"TY" intoString:nil] &&
           [scanner scanCharactersFromSet:[NSCharacterSet whitespaceCharacterSet] intoString:nil] &&
           [scanner scanString:@"-" intoString:nil]) // for RIS
            isRIS = YES;
    }
    [scanner release];
    return isRIS;
}

- (BOOL)isBibTeXString{
    static AGRegex *btRegex = nil;
    if(!btRegex)
        btRegex = [[AGRegex alloc] initWithPattern:@"^@[[:alpha:]]+{.*,$" options:AGRegexMultiline];
    
    return ([[btRegex findAllInString:self] count] > 0);
}

- (NSString *)stringByRemovingTeX{
    static AGRegex *command = nil;
    static OFCharacterSet *braceSet = nil;
    
    if(command == nil)
        command = [[AGRegex alloc] initWithPattern:@"\\\\[a-z].+\\{" options:AGRegexLazy];
    
    //NSAssert(command != nil, @"AGRegex must not be nil.");
    
    if(braceSet == nil)
        braceSet = [[OFCharacterSet alloc] initWithString:@"{}"];

    //NSAssert(braceSet != nil, @"OFCharacterSet must not be nil.");

    self = [command replaceWithString:@"" inString:self];
    return [self stringByRemovingCharactersInOFCharacterSet:braceSet];

}

- (NSComparisonResult)localizedCaseInsensitiveNumericCompare:(NSString *)aStr{
    return [self compare:aStr
                 options:NSCaseInsensitiveSearch | NSNumericSearch
                   range:NSMakeRange(0, [self length])
                  locale:[[NSUserDefaults standardUserDefaults] dictionaryRepresentation]];
}


- (NSString *)fastStringByCollapsingWhitespaceAndRemovingSurroundingWhitespace;
{
    return (NSString *)__BDCollapseAndTrimWhitespace((CFStringRef)self);
}

- (NSRange)rangeOfTeXCommandInRange:(NSRange)searchRange;
{
    
    CFRange cmdStartRange;
    CFIndex maxLen = [self length];    
    CFIndex cmdStopIndex = 0;
    
    if(!CFStringFindWithOptions((CFStringRef)self, CFSTR("\\"), CFRangeMake(0, maxLen), 0, &cmdStartRange))
        return NSMakeRange(NSNotFound, 0);
        
    CFRange lbraceRange;
    CFRange spaceRange;
    CFRange cmdSearchRange = CFRangeMake(cmdStartRange.location, maxLen - cmdStartRange.location);
                
    if(CFStringFindWithOptions((CFStringRef)self, CFSTR("{"), cmdSearchRange, 0, &lbraceRange) == FALSE ||
       CFStringFindWithOptions((CFStringRef)self, CFSTR(" "), cmdSearchRange, 0, &spaceRange) == FALSE)
        return NSMakeRange(NSNotFound, 0);
    
    CFRange rbraceRange;
    Boolean foundRBrace = CFStringFindWithOptions((CFStringRef)self, CFSTR("}"), cmdSearchRange, 0, &rbraceRange);
    
    // check for an immediate right brace after the left brace, as in \LaTeX{}, since we
    // don't want to remove those, either
    if(spaceRange.location < lbraceRange.location || 
       (foundRBrace && (rbraceRange.location == lbraceRange.location + 1)) ){
        // if we want to consider \LaTeX a command to be removed, cmdStop = spaceLoc; this can mess
        // up sorting, though, since \LaTeX is a word /and/ a command.
        return NSMakeRange(NSNotFound, 0);
    } else {
        cmdStopIndex = lbraceRange.location;
    }

    return NSMakeRange(cmdStartRange.location, (cmdStopIndex - cmdStartRange.location));
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

- (NSComparisonResult)localizedCaseInsensitiveNonTeXNonArticleCompare:(NSString *)otherString;
{
    NSMutableString *modifiedSelf = [self mutableCopy];
    NSMutableString *modifiedOther = [otherString mutableCopy];
    
    __BDDeleteTeXForSorting(modifiedSelf);
    __BDDeleteTeXForSorting(modifiedOther);
    __BDDeleteArticlesForSorting((CFMutableStringRef)modifiedSelf);
    __BDDeleteArticlesForSorting((CFMutableStringRef)modifiedOther);
    
    CFComparisonResult result = CFStringCompare((CFStringRef)modifiedSelf,
                                                (CFStringRef)modifiedOther,
                                                kCFCompareCaseInsensitive | kCFCompareNonliteral);
    [modifiedSelf release];
    [modifiedOther release];
    
    return result;
}

- (NSString *)stringByNormalizingSpacesAndLineBreaks;
{
    return (NSString *)__BDNormalizeWhitespaceAndNewlines((CFStringRef)self);
}
    
@end

@implementation NSString (PrivateMethods)

static inline
BOOL __BDCharacterIsWhitespace(UniChar c)
{
    static CFCharacterSetRef csref = NULL;
    if(csref == NULL)
        csref = CFCharacterSetGetPredefined(kCFCharacterSetWhitespace);
    // minor optimization: check for an ASCII character, since those are most common in TeX
    return ( (c <= 0x007E && c >= 0x0021) ? NO : CFCharacterSetIsCharacterMember(csref, c) );
}

static inline
BOOL __BDCharacterIsNewline(UniChar c)
{
    static CFMutableCharacterSetRef newlineCharacterSet = NULL;
    if(newlineCharacterSet == NULL){
        newlineCharacterSet = CFCharacterSetCreateMutableCopy(CFAllocatorGetDefault(), CFCharacterSetGetPredefined(kCFCharacterSetWhitespace));
        CFCharacterSetInvert(newlineCharacterSet); // no whitespace in this one, but it also has all letters...
        CFCharacterSetIntersect(newlineCharacterSet, CFCharacterSetGetPredefined(kCFCharacterSetWhitespaceAndNewline));
    }
    // minor optimization: check for an ASCII character, since those are most common in TeX
    return ( (c <= 0x007E && c >= 0x0021) ? NO : CFCharacterSetIsCharacterMember(newlineCharacterSet, c) );
}

CFStringRef __BDCollapseAndTrimWhitespace(CFStringRef aString)
{
    
    CFIndex length = CFStringGetLength(aString);
    
    if(length == 0)
        return CFSTR("");
    
    // set up the buffer to fetch the characters
    CFIndex cnt = 0;
    CFStringInlineBuffer inlineBuffer;
    CFStringInitInlineBuffer(aString, &inlineBuffer, CFRangeMake(0, length));
    UniChar ch;
    UniChar *buffer;
    CFStringRef retStr;
    
    BOOL isLarge = NO;
    // see if we can allocate it on the stack (faster)
    buffer = alloca(sizeof(UniChar) * (length + 1));
    
    if(buffer == NULL){
        buffer = NSZoneMalloc(NULL, sizeof(UniChar) * (length + 1));
        isLarge = YES; // too large for the stack
    }
    
    NSCAssert1(buffer != NULL, @"failed to allocate memory for string of length %d", length);
    
    BOOL isFirst = NO;
    int bufCnt = 0;
    for(cnt = 0; cnt < length; cnt++){
        ch = CFStringGetCharacterFromInlineBuffer(&inlineBuffer, cnt);
        if(!__BDCharacterIsWhitespace(ch)){
            isFirst = YES;
            buffer[bufCnt++] = ch; // not whitespace, so we want to keep it
        } else {
            if(isFirst){
                buffer[bufCnt++] = ' '; // if it's the first whitespace, we add a single space
                isFirst = NO;
            }
        }
    }
    
    if(buffer[(bufCnt-1)] == ' ') // we've collapsed any trailing whitespace, so disregard it
        bufCnt--;
    
    retStr = CFStringCreateWithCharacters(CFAllocatorGetDefault(), buffer, bufCnt);
    if(isLarge) NSZoneFree(NULL, buffer);
    return (CFStringRef)[(NSString *)retStr autorelease];
}

#define SHOULD_REMOVE_CHAR( c ) \
(c == '{' || c == '`' || c == '$' || c == '\\' || c == '(')

// private function for removing some tex special characters from a string
// (only those I consider relevant to sorting)
void __BDDeleteTeXCharactersForSorting(CFMutableStringRef texString)
{
    CFStringEncoding fastEncoding = CFStringGetFastestEncoding(texString);
    // Optimization: this is the fastest way to get characters from a string, and we won't have to
    // resize strings if we use this method.  CFStringGetCStringPtr will sometimes return NULL, and
    // for our strings, CFStringGetCharactersPtr() always returns NULL, probably since they're not stored as UniChars.
    const char *cStringPtr = CFStringGetCStringPtr(texString, fastEncoding);
    if(cStringPtr != NULL){
        CFIndex len = strlen(cStringPtr);
        Boolean isLarge = FALSE;
        
        char *buffer = alloca(sizeof(char) * (len + 1));
        if(buffer == NULL){
            isLarge = TRUE;
            buffer = (char *)malloc(sizeof(char) * (len + 1));
            NSCAssert(buffer != NULL, @"Unable to allocate memory");
        }
        
        char c;
        CFIndex idx = 0;
        while((c = *cStringPtr++) != '\0')
            if(!SHOULD_REMOVE_CHAR(c))
                buffer[idx++] = c;
        
        buffer[idx++] = '\0'; // make it a proper C string

        CFStringRef newString = CFStringCreateWithCString(CFAllocatorGetDefault(), buffer, fastEncoding);
        CFStringReplaceAll(texString, newString);
        CFRelease(newString);
                
        if(isLarge)
            free(buffer);
        
        return;
    }
    
    CFStringInlineBuffer inlineBuffer;
    CFIndex length = CFStringGetLength(texString);
    CFIndex cnt = 0;
    
    // create an immutable copy to use with the inline buffer
    CFStringRef myCopy = CFStringCreateCopy(kCFAllocatorDefault, texString);
    CFStringInitInlineBuffer(myCopy, &inlineBuffer, CFRangeMake(0, length));
    UniChar ch;
    
    // delete the {`$\\( characters, since they're irrelevant to sorting, and typically
    // appear at the beginning of a word
    CFIndex delCnt = 0;
    while(cnt < length){
        ch = CFStringGetCharacterFromInlineBuffer(&inlineBuffer, cnt);
        if(SHOULD_REMOVE_CHAR(ch)){
            // remove from the mutable string; we have to keep track of our index in the copy and the original
            CFStringDelete(texString, CFRangeMake(delCnt, 1));
        } else {
            delCnt++;
        }
        cnt++;
    }
    CFRelease(myCopy); // dispose of our temporary copy
}

void __BDDeleteArticlesForSorting(CFMutableStringRef mutableString)
{
    // remove certain terms for sorting, according to preferences
    // each one is typically an article, and we only look
    // for these at the beginning of a string   
    CFArrayRef articlesToRemove = CFPreferencesCopyAppValue((CFStringRef)BDSKIgnoredSortTermsKey, kCFPreferencesCurrentApplication);
    if(!articlesToRemove)
        return;
    
    CFIndex count = CFArrayGetCount(articlesToRemove);
    if(!count){
        CFRelease(articlesToRemove);
        return;
    }
    
    // get the max string length of any of the strings in the plist; we don't want to search any farther than necessary
    CFIndex maxRemoveLength = 0; 
    CFIndex index = count;
    while(index--)
        maxRemoveLength = MAX(CFStringGetLength(CFArrayGetValueAtIndex(articlesToRemove, index)), maxRemoveLength);
    
    index = count;
    CFRange articleRange;
    Boolean found;
    CFIndex length;

    while(index--){
        length = CFStringGetLength(mutableString);
        found = CFStringFindWithOptions(mutableString, CFArrayGetValueAtIndex(articlesToRemove, index), CFRangeMake(0, MIN(length, maxRemoveLength)), 0, &articleRange);
        
        // make sure the next character is whitespace before deleting, after checking bounds
        if(found && length > articleRange.length && 
           __BDCharacterIsWhitespace(CFStringGetCharacterAtIndex(mutableString, articleRange.length++)))
            CFStringDelete(mutableString, articleRange);
    }
        
    CFRelease(articlesToRemove);
}

void __BDDeleteTeXForSorting(NSMutableString *mutableString)
{
    NSRange searchRange = NSMakeRange(0, [mutableString length]);
    NSRange cmdRange;
    unsigned startLoc;
    
    // This will find and remove the commands such as \textit{some word} that can confuse the sort order;
    // unfortunately, we can't remove things like {\textit some word}, since it could also be something
    // like {\LaTeX is great}, so this is a compromise
    while( (cmdRange = [mutableString rangeOfTeXCommandInRange:searchRange]).location != NSNotFound){
        
        // delete the command
        [mutableString deleteCharactersInRange:cmdRange];
        startLoc = cmdRange.location;
        searchRange.location = startLoc;
        searchRange.length = [mutableString length] - startLoc;
    }
    // get rid of braces and such...
    __BDDeleteTeXCharactersForSorting((CFMutableStringRef)mutableString);
}

CFStringRef __BDNormalizeWhitespaceAndNewlines(CFStringRef aString)
{
    
    CFIndex length = CFStringGetLength(aString);
    
    if(length == 0)
        return CFSTR("");
    
    // set up the buffer to fetch the characters
    CFIndex cnt = 0;
    CFStringInlineBuffer inlineBuffer;
    CFStringInitInlineBuffer(aString, &inlineBuffer, CFRangeMake(0, length));
    UniChar ch;
    UniChar *buffer;
    CFStringRef retStr;
    
    BOOL isLarge = NO;
    
    // see if we can allocate it on the stack (faster)
    buffer = alloca(sizeof(UniChar) * (length + 1));
    
    if(buffer == NULL){
        buffer = NSZoneMalloc(NULL, sizeof(UniChar) * (length + 1));
        isLarge = YES; // too large for the stack
    }
    
    NSCAssert1(buffer != NULL, @"failed to allocate memory for string of length %d", length);
    
    int bufCnt = 0;
    for(cnt = 0; cnt < length; cnt++){
        ch = CFStringGetCharacterFromInlineBuffer(&inlineBuffer, cnt);
        if(__BDCharacterIsWhitespace(ch)){
            buffer[bufCnt++] = ' '; // not whitespace, so we want to keep it
        } else if(__BDCharacterIsNewline(ch)){
            buffer[bufCnt++] = '\n'; // any newline would work here
        } else buffer[bufCnt++] = ch;
    }
    
    retStr = CFStringCreateWithCharacters(CFAllocatorGetDefault(), buffer, bufCnt);
    if(isLarge) NSZoneFree(NULL, buffer);
    return (CFStringRef)[(NSString *)retStr autorelease];
}

@end
