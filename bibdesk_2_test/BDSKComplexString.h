// BDSKComplexString.h
/*
 This software is Copyright (c) 2004,2005,2006
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

/* Defines nodes that are used to store either strings or macros or
   raw numbers. These are usually stored as either parts of an array
   or as nodes by themselves. */

#import <Foundation/Foundation.h>

extern NSString *BDSKComplexStringException;

@class BDSKMacroResolver;

@interface NSObject (NSKeyedUnarchiverComplexStringDelegate)
- (BDSKMacroResolver *)unarchiverMacroResolver:(NSKeyedUnarchiver *)unarchiver;
@end

/* BDSKComplexString is a string that may be a concatenation of strings, 
    some of which are macros.
   It's a concrete subclass of NSString, which means it can be used 
    anywhere an NSString can.
   The string always has an expandedValue, which is treated as the 
    actual value if you treat it as an NSString. That value
    is either the expanded value or the value of the macro itself. */


@interface BDSKComplexString : NSString <NSCopying, NSCoding>{
  NSArray *nodes;			/* an array of BDSKStringNodes. */

  BDSKMacroResolver *macroResolver;
  
  BOOL complex;
  BOOL inherited;
}

/*!
    @method     initWithArray:
    @abstract   Initializes a complex string with an array of string nodes and a macroresolver. This is the designated initializer. 
    @discussion Returns a non-complex string when the array contains a single string-type node.
    @param		nodesArray An array of BDSKStringNodes
    @param		macroResolver The macro resolver used to resolve macros in the complex string.
    @result     -
*/
- (id)initWithArray:(NSArray *)nodesArray macroResolver:(BDSKMacroResolver *)theMacroResolver;

/*!
    @method     initWithInheritedValue:
    @abstract   Initializes a string with an inherited value.
    @discussion (description)
    @param		aValue The string value to inherit.
    @result     -
*/
- (id)initWithInheritedValue:(NSString *)aValue;

/*!
    @method     macroResolver
    @abstract   Returns the object used to resolve macros in the complex string
    @discussion (description)
    @result     -
*/
- (BDSKMacroResolver *)macroResolver;

@end

/* These is a category on NSString containing the class factory methods for 
    creating concrete BDSKComplexStrings, as well as a bunch of ceomplex string 
    methods that we want to be able to call on any NSString as well. */

@interface NSString (BDSKComplexStringExtensions)

/*!
    @method     complexStringWithArray:macroResolver:
    @abstract   Returns a newly allocated and initialized complex string build with an array of BDSKStringNodes as its nodes.
    @discussion -
    @param		nodesArray An array of BDSKStringNodes
    @param		macroResolver The macro resolver used to resolve macros in the complex string.
    @result     - 
*/
+ (id)complexStringWithArray:(NSArray *)nodesArray  macroResolver:(BDSKMacroResolver *)macroResolver;

/*!
    @method     complexStringWithBibTeXString:macroResolver:
    @abstract   Returns a newly allocated and initialized complex or simple string build from the BibTeX string value.
    @discussion -
    @param		btstring A BibTeX string value
    @param		macroResolver The macro resolver used to resolve macros in the complex string.
    @result     - 
*/
+ (id)complexStringWithBibTeXString:(NSString *)btstring macroResolver:(BDSKMacroResolver *)theMacroResolver;

/*!
    @method     stringWithInheritedValue:
    @abstract   Returns a newly allocated and initialized string with an inherited value. 
    @discussion -
    @param		aValue The string value to inherit. 
    @result     - 
*/
+ (id)stringWithInheritedValue:(NSString *)aValue;

/*!
    @method     copyUninherited
    @abstract   Copies using copyUninheritedWithZone: with the default zone
    @discussion -
    @result     - 
*/
- (id)copyUninherited;

/*!
    @method     copyUninheritedWithZone:
    @abstract   Copies the string, always returning a non-inherited (complex) string
    @discussion -
    @param		zone The zone to use
    @result     - 
*/
- (id)copyUninheritedWithZone:(NSZone *)zone;

/*!
    @method     isComplex
    @abstract   Boolean indicating whether the receiver is a complex string.
    @discussion -
    @result     - 
*/
- (BOOL)isComplex;

/*!
    @method     isInherited
    @abstract   Boolean indicating whether the receiver is an inherited string.
    @discussion -
    @result     - 
*/
- (BOOL)isInherited;

/*!
    @method     nodes
    @abstract   The string nodes of the string. Returns an array containing a single string-type node when the receiver is not complex.
    @discussion (description)
    @result     -
*/
- (NSArray *)nodes;

/*!
    @method     isEqualAsComplexString:
    @abstract   Returns YES if both are to be considered the same as complex strings
    @discussion Returns YES if the receiver and other are both simple strings (i.e. either an NSString or simple BDSKComplexString, not necessarily the same class) with the same value, or both BDSKComplexStrings with the same nodes. 
    @param      other The string to compare with
    @result     Boolean indicating if the strings are equal as complex strings
*/
- (BOOL)isEqualAsComplexString:(NSString *)other;

/*!
    @method     compareAsComplexString:
    @abstract   Invokes compareAsComplexString:options: with no options. 
    @discussion -
    @param      other The string to compare with
    @result     -
*/
- (NSComparisonResult)compareAsComplexString:(NSString *)other;

/*!
    @method     isEqualAsComplexString:
    @abstract   Compares the receiver with the other string interpreted as a complex string. 
    @discussion Non-complex strings are always considered smaller than complex strings. For complex strings, the nodes are compared rather than the expanded value. 
    @param      other The string to compare with
    @param      mask The search options to use in the comparison. These are the same as for normal string compare methods. 
    @result     -
*/
- (NSComparisonResult)compareAsComplexString:(NSString *)other options:(unsigned)mask;

/*!
    @method     stringAsBibTeXString
    @abstract   Returns the value of the string as a BibTeX string value. 
    @discussion For complex strings this returns the unexpanded bibtex string, while for a simple string it returns the receiver enclosed by quoting braces.
    @result     - 
*/
- (NSString *)stringAsBibTeXString;

/*!
    @method     stringAsExpandedBibTeXString
    @abstract   Returns the value of the string as a BibTeX string value, enclosed in quoting braces.
    @discussion For complex strings this returns the expanded bibtex string; calls stringAsBibTeXString for non-complex strings.
    @result     (description)
*/
- (NSString *)stringAsExpandedBibTeXString;

/*!
    @method     hasSubstring:options:
    @abstract   Boolean, checks whether the receiver has target as a substring. 
    @discussion When the receiver is not complex and target is complex always returns NO. 
    @result     (description)
*/
- (BOOL)hasSubstring:(NSString *)target options:(unsigned)opts;

/*!
    @method     stringByReplacingOccurrencesOfString:withString:options:replacements:
    @abstract   Returns a string formed by replacing occurrences of target by replacement, using the search options opts. The last argument is set to the number of replacements set.
    @discussion When the receiver is not complex and target is complex, or if the receiver is inherited, returns the receiver. 
                When the receiver is complex, only whole node matches are replaced. 
    @result     (description)
*/
- (NSString *)stringByReplacingOccurrencesOfString:(NSString *)target withString:(NSString *)replacement options:(unsigned)opts replacements:(unsigned int *)number;

@end
