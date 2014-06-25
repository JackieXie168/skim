//
//  NSString_SKExtensions.h
//  Skim
//
//  Created by Christiaan Hofman on 2/12/07.
/*
 This software is Copyright (c) 2007-2014
 Christiaan Hofman. All rights reserved.

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:

 - Redistributions of source code must retain the above copyright
   notice, this list of conditions and the following disclaimer.

 - Redistributions in binary form must reproduce the above copyright
    notice, this list of conditions and the following disclaimer in
    the documentation and/or other materials provided with the
    distribution.

 - Neither the name of Christiaan Hofman nor the names of any
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

#import <Cocoa/Cocoa.h>


@interface NSString (SKExtensions)

- (NSComparisonResult)noteTypeCompare:(id)other;
- (NSComparisonResult)boundsCompare:(NSString *)aString;
- (NSComparisonResult)mirroredBoundsCompare:(NSString *)aString;

- (NSString *)stringByCollapsingWhitespaceAndNewlinesAndRemovingSurroundingWhitespaceAndNewlines;
- (NSString *)stringByRemovingAliens;

- (NSString *)stringByAppendingEllipsis;

- (NSString *)stringByBackslashEscapingCharactersFromSet:(NSCharacterSet *)charSet;
- (NSString *)stringByEscapingShellChars;
- (NSString *)stringByEscapingParenthesis;

- (NSComparisonResult)localizedCaseInsensitiveNumericCompare:(NSString *)aStr;

- (BOOL)isCaseInsensitiveEqual:(NSString *)aString;

- (NSString *)lossyASCIIString;
- (NSString *)lossyISOLatin1String;

- (NSString *)typeName;

- (NSString *)rectString;
- (NSString *)pointString;
- (NSString *)originString;
- (NSString *)sizeString;
- (NSString *)midPointString;
- (CGFloat)rectX;
- (CGFloat)rectY;
- (CGFloat)rectWidth;
- (CGFloat)rectHeight;
- (CGFloat)pointX;
- (CGFloat)pointY;

- (NSString *)stringBySurroundingWithSpacesIfNotEmpty;
- (NSString *)stringByAppendingSpaceIfNotEmpty;
- (NSString *)stringByAppendingDoubleSpaceIfNotEmpty;
- (NSString *)stringByPrependingSpaceIfNotEmpty;
- (NSString *)stringByAppendingCommaIfNotEmpty;
- (NSString *)stringByAppendingFullStopIfNotEmpty;
- (NSString *)stringByAppendingCommaAndSpaceIfNotEmpty;
- (NSString *)stringByAppendingFullStopAndSpaceIfNotEmpty;
- (NSString *)stringByPrependingCommaAndSpaceIfNotEmpty;
- (NSString *)stringByPrependingFullStopAndSpaceIfNotEmpty;
- (NSString *)parenthesizedStringIfNotEmpty;

- (NSURL *)url;
- (NSAttributedString *)icon;
- (NSAttributedString *)smallIcon;

- (NSAttributedString *)typeIcon;

- (NSString *)xmlString;

@end
