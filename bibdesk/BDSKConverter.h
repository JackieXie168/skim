//  BDSKConverter.h

//  Created by Michael McCracken on Thu Mar 07 2002.
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

/*! @header BDSKConverter.h
    @discussion Declares a class that has a shared instance and just does the TeX encoding conversions.
*/

#import <Cocoa/Cocoa.h>
#import <OmniFoundation/NSString-OFExtensions.h>
#import "BibTypeManager.h"

// The filename and keys used in the plist
#define CHARACTER_CONVERSION_FILENAME	@"CharacterConversion.plist"
#define ONE_WAY_CONVERSION_KEY			@"One-Way Conversions"
#define ROMAN_TO_TEX_KEY				@"Roman to TeX"
#define TEX_TO_ROMAN_KEY				@"TeX to Roman"
#define ROMAN_TO_TEX_ACCENTS_KEY		@"Roman to TeX Accents"
#define TEX_TO_ROMAN_ACCENTS_KEY		@"TeX to Roman Accents"

/*!
 @class BDSKConverter
 @abstract converts from UTF-8 <-> TeX
 @discussion This was a pain to write, and more of a pain to link. :)
*/
@interface BDSKConverter : NSObject {
     NSCharacterSet *finalCharSet;
     NSCharacterSet *accentCharSet;
     NSDictionary *detexifyConversions;
     NSDictionary *texifyConversions;
     NSDictionary *texifyAccents;
     NSDictionary *detexifyAccents;
     NSCharacterSet *baseCharacterSetForTeX;
}
/*!
    @method     sharedConverter
    @abstract   Returns a shared instance of the BDSKConverter
    @discussion (comprehensive description)
    @result     (description)
*/
+ (BDSKConverter *)sharedConverter;
/*!
    @method     loadDict
    @abstract   Initialize the converter
    @discussion (comprehensive description)
*/
- (void)loadDict;

/*!
 @method copyStringByTeXifyingString:error:
 @abstract UTF-8 -> TeX
 @discussion Uses a dictionary to find replacements for candidate special characters.  Returns an error with code kBDSKTeXifyError if an error occurred.
 @param s the string to convert into ASCII TeX encoding
 @param error texification error
 @result the retained string converted into ASCI TeX encoding
*/
- (NSString *)copyStringByTeXifyingString:(NSString *)s error:(NSError **)error;

/*!
 @method copyStringByDeTeXifyingString:
 @abstract TeX -> UTF-8
 @discussion Uses a dictionary to find replacements for strings like {\ ... }.
 @param s the string to convert from ASCII TeX encoding
 @result the retained string converted from ASCI TeX encoding
*/
- (NSString *)copyStringByDeTeXifyingString:(NSString *)s;

/*!
    @method     composedStringFromTeXString:
    @abstract   Returns a composed string with canonical mapping (Unicode normalization form C) based on a given TeX accent sequence, if possible.  Used as a fallback
                if CharacterConversion.plist doesn't have a match when deTeXifying a string.
    @discussion (comprehensive description)
    @param      texString A TeX accent fragment as {\u g}.
    @result     (description)
*/
- (NSString *)composedStringFromTeXString:(NSString *)texString;

@end

@interface NSString (BDSKConverter)

- (NSString *)copyTeXifiedStringReturningError:(NSError **)error;
- (NSString *)stringByTeXifyingStringReturningError:(NSError **)error;
- (NSString *)copyDeTeXifiedString;
- (NSString *)stringByDeTeXifyingString;

@end
