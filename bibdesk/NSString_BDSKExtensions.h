//  NSString_BDSKExtensions.h

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

#import <Foundation/Foundation.h>
#import <OmniFoundation/NSMutableString-OFExtensions.h>
#import <CoreFoundation/CoreFoundation.h>
#import "NSCharacterSet_BDSKExtensions.h"
#import "CFString_BDSKExtensions.h"

enum {
	BDSKUnknownStringType = -1, 
	BDSKBibTeXStringType, 
	BDSKRISStringType, 
	BDSKJSTORStringType, 
	BDSKWOSStringType
};

@interface NSString (BDSKExtensions)

/*!
    @method     hexStringForCharacter:
    @abstract   Returns the hex value of a unichar (useful for lookups in the character palette)
    @discussion (comprehensive description)
    @param      ch (description)
    @result     (description)
*/
+ (NSString *)hexStringForCharacter:(unichar)ch;

/*!
    @method     lossyASCIIStringWithString:
    @abstract   Returns a lossy ASCII version of the input string.
    @discussion Useful for stripping accents from accented characters.  Returns an autoreleased string.
    @param      aString (description)
*/
+ (NSString *)lossyASCIIStringWithString:(NSString *)aString;

/*!
    @method     ratingStringWithInteger:
    @abstract   Returns a sequence of digits as bubbles surrounding each character
    @discussion Requires a font with characters 0x278A-278E
    @param      rating (description)
    @result     (description)
*/
+ (NSString *)ratingStringWithInteger:(int)rating;

/*!
 @method     stringWithBool:
 @abstract   Returns a localized string describing the boolean value. 
 @discussion (comprehensive description)
 @param      boolValue The value of the boolean.
 @result     (description)
 */
+ (NSString *)stringWithBool:(BOOL)boolValue;

/*!
@method     stringWithTriStateValue:
 @abstract   Returns a localized string describing the value as one of {NO, YES, -}
 @discussion (comprehensive description)
 @param      triStateValue The value of the checkBox.
 @result     (description)
 */
+ (NSString *)stringWithTriStateValue:(NSCellStateValue)triStateValue;

/*!
    @method     stringWithCString:usingEncoding:
    @abstract   Returns an autoreleased string allocated and initialized with the contents of the input characters (assumes a NULL terminated string).
    @discussion Used to create Unicode string instances from C strings, based on the given string encoding.
    @param      byteString (description)
    @param      encoding (description)
    @result     (description)
*/
+ (NSString *)stringWithCString:(const char *)byteString usingEncoding:(NSStringEncoding)encoding;

    /*!
    @method     unicodeNameOfCharacter:
     @abstract   Returns the unicode name of a character via CFStringTransform on 10.4, or else returns the character as a string;
     @discussion (comprehensive description)
     @param      ch (description)
     @result     (description)
     */
+ (NSString *)unicodeNameOfCharacter:(unichar)ch;
    
    /*!
    @method     initWithCString:usingEncoding:
    @abstract   Initializes the receiver with the input string of (NULL terminated) bytes.
    @discussion Used to create Unicode string instances from C strings, based on the given string encoding.
    @param      byteString (description)
    @param      encoding (description)
    @result     (description)
*/

- (NSString *)initWithCString:(const char *)byteString usingEncoding:(NSStringEncoding)encoding;

#pragma mark TeX cleaning

/*!
    @method     stringByConvertingDoubleHyphenToEndash
    @abstract   Converts "--" to en dash.  See http://en.wikipedia.org/wiki/Dash for info on dashes.
    @discussion (comprehensive description)
    @result     (description)
*/
- (NSString *)stringByConvertingDoubleHyphenToEndash;

    /*!
    @method     stringByRemovingCurlyBraces
     @abstract   Removes curly braces from a string
     @discussion Used for searching; removes curly braces from search results, so that a search for "Kynch theory" works even if the title has "{K}ynch theory"
     @result     (description)
     */
- (NSString *)stringByRemovingCurlyBraces;

/*!
 @method     stringByRemovingTeX
 @abstract   Removes TeX commands and curly braces from the receiver.
 @discussion May return a different instance.  A TeX command is considered to match a regex of the form "\\[a-z].+\{", with the AGRegexLazy option.
 @result     (description)
 */
- (NSString *)stringByRemovingTeX;

#pragma mark TeX parsing


/*!
@method     indexOfRightBraceMatchingLeftBraceAtIndex:
@abstract   Counts curly braces from left-to-right, in order to find a match for a left brace <tt>{</tt>.
@discussion Raises an exception if the character at <tt>startLoc</tt> is not a brace, and escaped braces are not (yet?) considered.
An inline buffer is used for speed in accessing each character.
@param      startLoc The index of the starting brace character.
@result     The index of the matching brace character.
*/
- (unsigned)indexOfRightBraceMatchingLeftBraceAtIndex:(unsigned)startLoc;
    
    /*!
    @method     isStringTeXQuotingBalancedWithBraces:connected:
    @abstract   Invoces isStringTeXQuotingBalancedWithBraces:connected:range: with the full range of the receiver. 
    @discussion (discussion)
    @result     (description)
*/
- (BOOL)isStringTeXQuotingBalancedWithBraces:(BOOL)braces connected:(BOOL)connected;

/*!
    @method     isStringTeXQuotingBalancedWithBraces:connected:range:
    @abstract   Checks if the receiver has balanced braces or doublequotes in range. 
    @discussion Used in parsing a bibtex string to see if a substring has balanced quotes. Ignores TeX-escaped delimiters, and checks for correct order of delimiters. 
    @param      braces Boolean, determines whether to use braces (or double-quotes) for quoting. 
    @param      connected Boolean, determines whether curly braces have to quote a connected range. 
    @param      range The range of the receiver in which to check for balanced braces.
    @result     Boolean
*/
- (BOOL)isStringTeXQuotingBalancedWithBraces:(BOOL)braces connected:(BOOL)connected range:(NSRange)range;

/*!
    @method     isRISString
    @abstract   Check to see if the string is RIS by scanning for "PMID- " or "TY  - ", which should appear in an RIS string.
    @discussion See the <a href="http://www.refman.com/support/risformat_intro.asp">RIS specification</a> for details on the format.  The heuristics here could be improved,
                but this is mainly intended to be a quick check of the pasteboard, not a full parser.
    @result     A Boolean.
*/
- (BOOL)isRISString;

/*!
    @method     isBibTeXString
    @abstract   Tries to determine if a string is BibTeX or not, based on the regular expression ^@[[:alpha:]]+{.*,$
    @discussion (comprehensive description)
    @result     (description)
*/
- (BOOL)isBibTeXString;

/*!
    @method     isJSTORString
    @abstract   Tries to determine if a string is JSTOR or not, based on the first line
    @discussion (comprehensive description)
    @result     (description)
*/
- (BOOL)isJSTORString;

/*!
    @method     isWebOfScienceString
    @abstract   Tries to determine if a string is Web of Science export format, based on the first line
    @discussion (comprehensive description)
    @result     (description)
*/
- (BOOL)isWebOfScienceString;

- (int)contentStringType;

/*!
@method     rangeOfTeXCommandInRange:
@abstract   Returns the range of a TeX command, considered simplistically as <tt>\command</tt> followed by a space or curly brace.
@discussion (comprehensive description)
@param      searchRange (description)
@result     (description)
*/
- (NSRange)rangeOfTeXCommandInRange:(NSRange)searchRange;

/*!
@method     stringByAddingRISEndTagsToPubMedString
@abstract   Adds ER tags to a stream of PubMed records, so it's (more) valid RIS
@discussion (comprehensive description)
@result     (description)
*/
- (NSString *)stringByAddingRISEndTagsToPubMedString;

#pragma mark Comparisons

/*!
@method     localizedCaseInsensitiveNumericCompare:
@abstract   Returns a case insensitve, numeric comparison in the user's default locale.
@discussion (comprehensive description)
@param      aStr (description)
@result     (description)
*/
- (NSComparisonResult)localizedCaseInsensitiveNumericCompare:(NSString *)aStr;
    
/*!
@method     caseInsensitiveNonTeXCompare:
@abstract   (brief description)
@discussion (comprehensive description)
@param      otherString (description)
@result     (description)
*/
- (NSComparisonResult)localizedCaseInsensitiveNonTeXNonArticleCompare:(NSString *)otherString;

/*!
@method     numericCompare:
@abstract   Compares strings as numbers, using NSNumericSearch
@discussion (comprehensive description)
@param      otherString (description)
@result     (description)
*/
- (NSComparisonResult)numericCompare:(NSString *)otherString;

/*!
    @method     sortCompare:
    @abstract   For sorting collections containing empty strings, which are handled in reverse order from compare:
    @discussion (comprehensive description)
    @param      other (description)
    @result     (description)
*/
- (NSComparisonResult)sortCompare:(NSString *)other;

/*!
    @method     triStateCompare:
    @abstract   For sorting triState string values
    @discussion (comprehensive description)
    @param      other (description)
    @result     (description)
*/
- (NSComparisonResult)triStateCompare:(NSString *)other;

#pragma mark -

/*!
@method     booleanValue
@abstract   Compares with Yes, y, or 1 using case insensitive search to return YES.
@discussion (comprehensive description)
@result     (description)
*/
- (BOOL)booleanValue;

/*!
     @method     triStateValue
     @abstract   Translates from string value to an NSCellStateValue
     @discussion For compatibility with booleanValue, we accept {Yes,y,1} = checked and {No,n,0,""} = unchecked. Anything else is treated as indeterminate, or "mixed".
     @result     (description)
 */
- (NSCellStateValue)triStateValue;

- (NSString *)acronymValueIgnoringWordLength:(unsigned int)ignoreLength;

#pragma mark -

/*!
    @method     componentsSeparatedByCharactersInSet:trimWhitespace:
    @abstract   Returns an array composed by splitting the string at any of the characters in charSet, optionally trimming whitespace from each component.
    @discussion (comprehensive description)
    @param      charSet (description)
    @param      trim (description)
    @result     (description)
*/
- (NSArray *)componentsSeparatedByCharactersInSet:(NSCharacterSet *)charSet trimWhitespace:(BOOL)trim;

/*!
    @method     componentsSeparatedByStringCaseInsensitive:
    @abstract   Same as componentsSeparatedByString:, but uses case-insensitive comparison
    @discussion (comprehensive description)
    @param      separator (description)
    @result     (description)
*/
- (NSArray *)componentsSeparatedByStringCaseInsensitive:(NSString *)separator;

/*!
    @method     containsString:options:range:
    @abstract   Determine whether a string contains searchString in aRange using mask as search options.
    @discussion (comprehensive description)
    @param      searchString (description)
    @param      mask (description)
    @param      aRange (description)
    @result     (description)
*/
- (BOOL)containsString:(NSString *)searchString options:(unsigned int)mask range:(NSRange)aRange;

/*!
@method     containsWord:
@abstract   Determine whether a string contains the argument aWord; if it contains aWord as a substring, it then tests to see if it is bounded by null, punctuation, or whitespace.
@discussion (comprehensive description)
@param      aWord (description)
@result     (description)
*/
- (BOOL)containsWord:(NSString *)aWord;

/*!
@method     fastStringByCollapsingWhitespaceAndRemovingSurroundingWhitespace
@abstract   Copy of one of the OmniFoundation methods, with CF calls to create and append to the mutable string instead of Cocoa methods.
            Faster and more memory efficient than the OF equivalent.
@discussion (comprehensive description)
@result     (description)
*/
- (NSString *)fastStringByCollapsingWhitespaceAndRemovingSurroundingWhitespace;

/*!
@method     fastStringByCollapsingWhitespaceAndNewlinesAndRemovingSurroundingWhitespaceAndNewlines
@abstract   Similar to fastStringByCollapsingWhitespaceAndRemovingSurroundingWhitespace, but treats newlines the same as whitespace characters.
            All newline characters will be replaced by a single whitespace. 
@discussion (comprehensive description)
@result     (description)
*/
- (NSString *)fastStringByCollapsingWhitespaceAndNewlinesAndRemovingSurroundingWhitespaceAndNewlines;

- (BOOL)hasCaseInsensitivePrefix:(NSString *)prefix;

/*!
    @method     stringByNormalizingSpacesAndLineBreaks
    @abstract   Converts all whitespace characters to a single space, and all newline characters to a \n
    @discussion (comprehensive description)
    @result     (description)
*/
- (NSString *)stringByNormalizingSpacesAndLineBreaks;

/*!
@method     stringByTrimmingFromLastPunctuation
@abstract   Returns the portion of a string following the last punctuation character.
@discussion (comprehensive description)
@result     (description)
*/
- (NSString *)stringByTrimmingFromLastPunctuation;

/*!
    @method     stringByTrimmingPrefixCharactersFromSet:
    @abstract   Trims leading characters in characterSet from the string.
    @discussion (comprehensive description)
    @param      characterSet (description)
    @result     (description)
*/
- (NSString *)stringByTrimmingPrefixCharactersFromSet:(NSCharacterSet *)characterSet;

- (NSString *)stringByAppendingEllipsis;

#pragma mark HTML/XML

- (NSString *)stringByConvertingHTMLLineBreaks;
- (NSString *)stringByEscapingBasicXMLEntitiesUsingUTF8;
- (NSString *)xmlString;

- (NSArray *)allSearchComponents;
- (NSArray *)andSearchComponents;
- (NSArray *)orSearchComponents;

#pragma mark Empty lines

- (NSRange)rangeOfLeadingEmptyLine;
- (NSRange)rangeOfLeadingEmptyLineInRange:(NSRange)range;
- (NSRange)rangeOfTrailingEmptyLine;
- (NSRange)rangeOfTrailingEmptyLineInRange:(NSRange)range;

#pragma mark Some convenience keys for templates

- (NSURL *)url;
- (NSAttributedString *)linkedText;
- (NSAttributedString *)icon;
- (NSAttributedString *)smallIcon;
- (NSAttributedString *)linkedIcon;
- (NSAttributedString *)linkedSmallIcon;

@end

@interface NSMutableString (BDSKExtensions)

- (BOOL)isMutableString;
- (void)deleteCharactersInCharacterSet:(NSCharacterSet *)characterSet;

@end
