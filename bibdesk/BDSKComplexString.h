/* Defines nodes that are used to store either strings or macros or
   raw numbers. These are usually stored as either parts of an array
   or as nodes by themselves. */

#import <Foundation/Foundation.h>
#import "BDSKConverter.h"

typedef enum{
    BSN_STRING,
    BSN_NUMBER,
    BSN_MACRODEF
} bdsk_stringnodetype;

@interface BDSKStringNode : NSObject{
    bdsk_stringnodetype type; 
    NSString *value;
}
+ (BDSKStringNode *)nodeWithBibTeXString:(NSString *)s;
- (id)copyWithZone:(NSZone *)zone;
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


@interface BDSKComplexString : NSString {
  bool isComplex;		/* If we are not complex, nodes is nil. */
  NSArray *nodes;			/* an array of bdsk_stringnodes. */

  NSString *expandedValue;
  id macroResolver;
}

/* A bunch of methods that have to be overridden 
* in a concrete subclass of NSString
*/
- (id)init;
/*
 Docs say we should override this one, but I am not sure how, and it seems to work OK without it.
  + (id)allocWithZone:(NSZone *)aZone;
 
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

    /*" Overridden NSString performance methods "*/
- (void)getCharacters:(unichar *)buffer;
- (void)getCharacters:(unichar *)buffer range:(NSRange)aRange;


+ (BDSKComplexString *)complexStringWithString:(NSString *)s macroResolver:(id<BDSKMacroResolver>)macroResolver;

+ (BDSKComplexString *)complexStringWithArray:(NSArray *)a  macroResolver:(id<BDSKMacroResolver>)macroResolver;

+ (BDSKComplexString *)complexStringWithBibTeXString:(NSString *)btstring macroResolver:(id<BDSKMacroResolver>)theMacroResolver;

- (id)copyWithZone:(NSZone *)zone;

- (BOOL)isComplex;
- (void)setIsComplex:(bool)newIsComplex;

- (NSArray *)nodes;
- (id <BDSKMacroResolver>)macroResolver;
- (NSString *)nodesAsBibTeXString;

/*!
    @method     expandedValueFromArray:
    @abstract   given an array of BDSKStringNodes,
    @discussion (description)
    @param      nodes an array of BDSKStringNodes
    @result     the string with expanded values for nodes that have them
*/
- (NSString *)expandedValueFromArray:(NSArray *)nodes;

@end
