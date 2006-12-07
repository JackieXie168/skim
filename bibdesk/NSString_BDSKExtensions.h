//  NSString_BDSKExtensions.h

//  Created by Michael McCracken on Sun Jul 21 2002.
/*
This software is Copyright (c) 2002, Michael O. McCracken
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

- Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
-  Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
-  Neither the name of Michael O. McCracken nor the names of any contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#import <Foundation/Foundation.h>


@interface NSString (BDSKExtensions)

- (NSString *)uniquePathByAddingNumber;
- (NSString *)xmlString;
- (NSString *)stringByConvertingHTMLLineBreaks;
/*!
    @method     lossyASCIIStringWithString:
    @abstract   Returns a lossy ASCII version of the input string.
    @discussion Useful for stripping accents from accented characters.  Returns an autoreleased string.
    @param      aString (description)
*/
+ (NSString *)lossyASCIIStringWithString:(NSString *)aString;

/*!
    @method     stringByRemovingCurlyBraces
    @abstract   Removes curly braces from a string
    @discussion Used for searching; removes curly braces from search results, so that a search for "Kynch theory" works even if the title has "{K}ynch theory"
    @result     (description)
*/
- (NSString *)stringByRemovingCurlyBraces;

/*!
    @method     stringWithBytes:encoding:
    @abstract   Returns an autoreleased string allocated and initialized with the contents of the input characters (assumes a NULL terminated string).
    @discussion Used to create Unicode string instances from C strings, based on the given string encoding.
    @param      byteString (description)
    @param      encoding (description)
    @result     (description)
*/
+ (NSString *)stringWithBytes:(const char *)byteString encoding:(NSStringEncoding)encoding;

/*!
    @method     initWithBytes:encoding:
    @abstract   Initializes the receiver with the input string of (NULL terminated) bytes.
    @discussion Used to create Unicode string instances from C strings, based on the given string encoding.
    @param      byteString (description)
    @param      encoding (description)
    @result     (description)
*/
- (NSString *)initWithBytes:(const char *)byteString encoding:(NSStringEncoding)encoding;

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
    @method     stringByRemovingTeX
    @abstract   Removes TeX commands and curly braces from the receiver.
    @discussion May return a different instance.  A TeX command is considered to match a regex of the form "\\[a-z].+\{", with the AGRegexLazy option.
    @result     (description)
*/
- (NSString *)stringByRemovingTeX;


/*!
    @method     stringByRemovingTeXForSorting
    @abstract   Removes TeX commands and leading curly braces from the receiver, as well as single backquotes and backslashes.
    @discussion Tries to make a TeX string suitable for sorting commands.
    @result     (description)
*/
- (NSString *)stringByRemovingTeXForSorting;

/*!
    @method     localizedCaseInsensitiveNumericCompare:
    @abstract   Returns a case insensitve, numeric comparison in the user's default locale.
    @discussion (comprehensive description)
    @param      aStr (description)
    @result     (description)
*/
- (NSComparisonResult)localizedCaseInsensitiveNumericCompare:(NSString *)aStr;

@end
