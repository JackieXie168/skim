// BDSKComplexString.h
/*
 This software is Copyright (c) 2004,2005
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
#import "BibPrefController.h"

typedef enum{
    BSN_STRING = 0,
    BSN_NUMBER = 1,
    BSN_MACRODEF = 2
} bdsk_stringnodetype;

@interface BDSKStringNode : NSObject <NSCopying, NSCoding>{
    bdsk_stringnodetype type; 
    NSString *value;
}

/*!
    @method     nodeWithQuotedString:
    @abstract   Returns a newly allocated and initialized string node for a quoted string. The string is expected to be valid, i.e. it should not contain unbalanced braces. Error checking is not performed. 
    @discussion (description)
    @param		s The string value without the quotes. 
    @result     A newly allocated string node of string type. 
*/
+ (BDSKStringNode *)nodeWithQuotedString:(NSString *)s;

/*!
    @method     nodeWithNumberString:
    @abstract   Returns a newly allocated and initialized string node for a raw number. The string is expected to be valid, i.e. it should contain only numbers. Error checking is not performed. 
    @discussion (description)
    @param		s The number value as a string. 
    @result     A newly allocated string node of number type. 
*/
+ (BDSKStringNode *)nodeWithNumberString:(NSString *)s;

/*!
    @method     nodeWithMacroString:
    @abstract   Returns a newly allocated and initialized string node for a macro string. The string is expected to be valid, i.e. it should not contain special characters. Error checking is not performed. 
    @discussion (description)
    @param		s The macro string. 
    @result     A newly allocated string node of macro type. 
*/
+ (BDSKStringNode *)nodeWithMacroString:(NSString *)s;

/*!
    @method     initWithType:value:
    @abstract   Initializes a new string node with the given type and value. This is the designated initializer.
    @discussion (description)
    @param		aType The type.
    @param		s The value string. 
    @result     An initialized string node. 
*/
- (id)initWithType:(bdsk_stringnodetype)aType value:(NSString *)s;

- (id)copyWithZone:(NSZone *)zone;

/*!
    @method     isEqual:
    @abstract   Returns YES if the receiver and the argument are a string nodes of the same type with equal values.  
    @discussion (description)
    @param		other The string node to compare with.
    @result     -
*/
- (BOOL)isEqual:(BDSKStringNode *)other;
- (NSComparisonResult)compareNode:(BDSKStringNode *)aNode;
- (NSComparisonResult)compareNode:(BDSKStringNode *)aNode options:(unsigned)mask;
- (bdsk_stringnodetype)type;
- (NSString *)value;

@end

@protocol BDSKMacroResolver
- (NSDictionary *)macroDefinitions;
- (void)setMacroDefinitions:(NSDictionary *)newMacroDefinitions;
- (void)addMacroDefinition:(NSString *)macroString forMacro:(NSString *)macroKey;
- (NSString *)valueOfMacro:(NSString *)macro;
- (void)removeMacro:(NSString *)macroKey;
- (void)changeMacroKey:(NSString *)oldKey to:(NSString *)newKey;
- (void)setMacroDefinition:(NSString *)newDefinition forMacro:(NSString *)macroKey;
@end


// BDSKComplexString is a string that may be a concatenation of strings, 
//  some of which are macros.
// It's a concrete subclass of NSString, which means it can be used 
//  anywhere an NSString can.
// The string always has an expandedValue, which is treated as the 
//  actual value if you treat it as an NSString. That value
//  is either the expanded value or the value of the macro itself.


@interface BDSKComplexString : NSString <NSCopying, NSCoding>{
  NSArray *nodes;			/* an array of bdsk_stringnodes. */

  id macroResolver;
  
  BOOL complex;
  BOOL inherited;
}

/* A bunch of methods that have to be overridden 
* in a concrete subclass of NSString
*/
+ (id)allocWithZone:(NSZone *)aZone;
- (id)init;

/*!
    @method     initWithArray:
    @abstract   Initializes a complex string with an array of string nodes and a macroresolver. This is the designated initializer. 
    @discussion (description)
    @param		a An array of BDSKStringNodes
    @param		macroResolver The macro resolver used to resolve macros in the complex string.
    @result     -
*/
- (id)initWithArray:(NSArray *)a macroResolver:(id)theMacroResolver;

/*!
    @method     initWithInheritedValue:
    @abstract   Initializes a string with an inherited value.
    @discussion (description)
    @param		aValue The string value to inherit.
    @result     -
*/
- (id)initWithInheritedValue:(NSString *)aValue;

/*
 The following methods are supposed to be overridden, but since we 
 only want to create BDSKComplexStrings using the convenience constructors,
 we don't need to.

- (id)initWithBytes:(const void *)bytes length:(unsigned)length encoding:(NSStringEncoding)encoding;
- (id)initWithCharacters:(const unichar *)characters length:(unsigned)length;
- (id)initWithCString:(const char *)bytes length:(unsigned)length;
- (id)initWithString:(NSString *)aString;
- (id)initWithFormat:(NSString *)format arguments:(va_list)argList;
- (id)initWithData:(NSData *)data encoding:(NSStringEncoding)encoding;
*/
- (unsigned int)length;
- (unichar)characterAtIndex:(unsigned)index;

/* Overridden NSString performance methods */
- (void)getCharacters:(unichar *)buffer;
- (void)getCharacters:(unichar *)buffer range:(NSRange)aRange;

- (id)copyWithZone:(NSZone *)zone;

/* Overridden BDSKComplexStringExtensions methods */
- (BOOL)isComplex;
- (BOOL)isInherited;
- (BOOL)isEqualAsComplexString:(NSString *)other;
- (NSString *)stringAsBibTeXString;

/* Complex string methods */

/*!
    @method     nodes
    @abstract   The nodes of the complex string
    @discussion (description)
    @result     -
*/
- (NSArray *)nodes;

/*!
    @method     macroResolver
    @abstract   Returns the object used to resolve macros in the complex string
    @discussion (description)
    @result     -
*/
- (id <BDSKMacroResolver>)macroResolver;

/*!
    @method     setMacroResolver:
    @abstract   Sets the object used to resolve macros in the complex string.
    @discussion (description)
	@param		newMacroResolver The new macro resolver, should implement the BDSKMacroResolver protocol.
    @result     -
*/
- (void)setMacroResolver:(id <BDSKMacroResolver>)newMacroResolver;

@end

@interface NSString (BDSKComplexStringExtensions)

/*!
    @method     complexStringWithArray:macroResolver:
    @abstract   Returns a newly allocated and initialized complex string build with an array of BDSKStringNodes as its nodes.
    @discussion -
    @param		a An array of BDSKStringNodes
    @param		macroResolver The macro resolver used to resolve macros in the complex string.
    @result     - 
*/
+ (id)complexStringWithArray:(NSArray *)a  macroResolver:(id<BDSKMacroResolver>)macroResolver;

/*!
    @method     complexStringWithBibTeXString:macroResolver:
    @abstract   Returns a newly allocated and initialized complex or simple string build from the BibTeX string value.
    @discussion -
    @param		btstring A BibTeX string value
    @param		macroResolver The macro resolver used to resolve macros in the complex string.
    @result     - 
*/
+ (id)complexStringWithBibTeXString:(NSString *)btstring macroResolver:(id<BDSKMacroResolver>)theMacroResolver;

/*!
    @method     stringWithInheritedValue:
    @abstract   Returns a newly allocated and initialized string with an inherited value. 
    @discussion -
    @param		aValue The string value to inherit. 
    @result     - 
*/
+ (id)stringWithInheritedValue:(NSString *)aValue;

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
    @method     isEqualAsComplexString:
    @abstract   Returns YES if both are to be considered the same as complex strings
    @discussion Returns YES if the receiver and other are both simple strings (i.e. either an NSString or simple BDSKComplexString, not necessarily the same class) with the same value, or both BDSKComplexStrings with the same nodes. 
    @param      other The string to compare with
    @result     Boolean indicating if the strings are equal as complex strings
*/
- (BOOL)isEqualAsComplexString:(NSString *)other;

- (NSComparisonResult)compareAsComplexString:(NSString *)other;
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
    @discussion When the receiver is not complex and target is complex, or if target is not complex and the receiver is not complex, always returns NO. 
    @result     (description)
*/
- (BOOL)hasSubstring:(NSString *)target options:(unsigned)opts;

/*!
    @method     stringByReplacingOccurrencesOfString:withString:options:replacements:
    @abstract   Returns a string formed by replacing occurrences of target by replacement, using the search options opts. The last argument is set to the number of replacements set.
    @discussion When the receiver is not complex and target is complex, or if target is not complex and the receiver is not complex, returns the receiver. 
When the receiver is complex, only whole node matches are replaced. 
    @result     (description)
*/
- (NSString *)stringByReplacingOccurrencesOfString:(NSString *)target withString:(NSString *)replacement options:(unsigned)opts replacements:(unsigned int *)number;

@end
