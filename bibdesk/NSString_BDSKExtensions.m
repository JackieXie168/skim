//  NSString_BDSKExtensions.m

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

#import "NSString_BDSKExtensions.h"
#import <OmniFoundation/NSString-OFExtensions.h>
#import <Cocoa/Cocoa.h>


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
    NSMutableString *mStr = [self mutableCopy];
    
    [mStr replaceOccurrencesOfString:@"{" withString:@"" options:nil range:NSMakeRange(0, [mStr length])];
    [mStr replaceOccurrencesOfString:@"}" withString:@"" options:nil range:NSMakeRange(0, [mStr length])];
    
    return [mStr autorelease];
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
    BOOL isRIS = NO;
    if([scanner scanString:@"PMID- " intoString:nil]) // for Medline
    isRIS = YES;
    else {
        [scanner setScanLocation:0];
        if([scanner scanString:@"TY  - " intoString:nil]) // for RIS
            isRIS = YES;
    }
    [scanner release];
    return isRIS;
}


@end
