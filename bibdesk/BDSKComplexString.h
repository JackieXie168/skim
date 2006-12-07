/* Defines nodes that are used to store either strings or macros or
   raw numbers. These are usually stored as either parts of an array
   or as nodes by themselves. */

#import <Foundation/Foundation.h>
#import "BDSKConverter.h"
#import "AGRegex/AGRegex.h"

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
    @method     nodeWithBibTeXString:
    @abstract   Returns a newly allocated and initialized string node for a BibTeX string. The BibTeX string is checked for errors. 
    @discussion (description)
    @param		s The raw BibTeX string value for the node. 
    @result     A newly allocated string node. 
*/
+ (BDSKStringNode *)nodeWithBibTeXString:(NSString *)s;

- (id)copyWithZone:(NSZone *)zone;

/*!
    @method     isEqual:
    @abstract   Returns YES if the receiver and the argument are a string nodes of the same type with equal values.  
    @discussion (description)
    @param		other The string node to compare with.
    @result     -
*/
- (BOOL)isEqual:(BDSKStringNode *)other;
- (bdsk_stringnodetype)type;
- (void)setType:(bdsk_stringnodetype)newType;
- (NSString *)value;
- (void)setValue:(NSString *)newValue;

@end

@protocol BDSKMacroResolver
- (NSMutableDictionary *)macroDefinitions;
- (void)setMacroDefinitions:(NSMutableDictionary *)newMacroDefinitions;
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

  NSString *expandedValue;
  id macroResolver;
}

/* A bunch of methods that have to be overridden 
* in a concrete subclass of NSString
*/
+ (id)allocWithZone:(NSZone *)aZone;
- (id)init;
/*!
    @method     initWithArray
    @abstract   Initializes a complex string with an array of string nodes and a macroresolver. This is the designated initializer. 
    @discussion (description)
    @param		a An array of BDSKStringNodes
    @param		macroResolver The macro resolver used to resolve macros in the complex string.
    @result     -
*/
- (id)initWithArray:(NSArray *)a macroResolver:(id)theMacroResolver;

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
    @method     expandedValueFromArray:
    @abstract   given an array of BDSKStringNodes,
    @discussion (description)
    @param      nodes an array of BDSKStringNodes
    @result     the string with expanded values for nodes that have them
*/
- (NSString *)expandedValueFromArray:(NSArray *)nodes;

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

- (void)handleMacroKeyChangedNotification:(NSNotification *)notification;
- (void)handleMacroDefinitionChangedNotification:(NSNotification *)notification;

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
+ (NSString *)complexStringWithArray:(NSArray *)a  macroResolver:(id<BDSKMacroResolver>)macroResolver;

/*!
    @method     complexStringWithBibTeXString:macroResolver:
    @abstract   Returns a newly allocated and initialized complex or simple string build from the BibTeX string value.
    @discussion -
    @param		btstring A BibTeX string value
    @param		macroResolver The macro resolver used to resolve macros in the complex string.
    @result     - 
*/
+ (NSString *)complexStringWithBibTeXString:(NSString *)btstring macroResolver:(id<BDSKMacroResolver>)theMacroResolver;

/*!
    @method     isComplex
    @abstract   Boolean indicating whether the receiver is a complex string.
    @discussion -
    @result     - 
*/
- (BOOL)isComplex;

/*!
    @method     isEqualAsComplexString:
    @abstract   Returns YES if both are to be considered the same as complex strings
    @discussion Returns YES if the receiver and other are both simple strings (i.e. either an NSString or simple BDSKComplexString, not necessarily the same class) with the same value, or both BDSKComplexStrings with the same nodes. 
    @param      other The string to compare with
    @result     Boolean indicating if the strings are equal as complex strings
*/
- (BOOL)isEqualAsComplexString:(NSString *)other;

/*!
    @method     stringAsBibTeXString
    @abstract   Returns the value of the string as a BibTeX string value. 
    @discussion For complex strings this returns the unexpanded bibtex string, while for a simple string it returns the receiver enclosed by quoting braces.
    @result     - 
*/
- (NSString *)stringAsBibTeXString;

@end
