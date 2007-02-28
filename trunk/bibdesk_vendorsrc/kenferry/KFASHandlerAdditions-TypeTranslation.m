//
// KFASHanderAdditions-TypeTranslation.m
// KFAppleScriptHandlerAdditions v. 2.3, 12/31, 2004
//
// Copyright (c) 2003-2004 Ken Ferry. Some rights reserved.
// http://homepage.mac.com/kenferry/software.html
//
// This work is licensed under a Creative Commons license:
// http://creativecommons.org/licenses/by-nc/1.0/
//

// NSDecimal?  Float128? coercion errors? enums?  What to do when types don't match up? NSNull?

#import "KFASHandlerAdditions-TypeTranslation.h"

#ifndef keyASUserRecordFields
#define keyASUserRecordFields 'usrf'
#endif

@interface NSScriptObjectSpecifier (Private)
- (NSAppleEventDescriptor *)_asDescriptor;
@end

@interface NSAppleEventDescriptor (KFAppleScriptHandlerAdditionsPrivate)
+(void)kfSetUpHandlerDict;
@end

@interface NSNumber (KFAppleScriptHandlerAdditionsPrivate)
+ (id) kfNumberWithSignedIntP:(void *)int_p byteCount:(unsigned int)bytes;
+ (id) kfNumberWithUnsignedIntP:(void *)int_p byteCount:(unsigned int)bytes;
+ (id) kfNumberWithFloatP:(void *)float_p byteCount:(unsigned int)bytes;
@end

@implementation NSObject (KFAppleScriptHandlerAdditions)
- (NSAppleEventDescriptor *)aeDescriptorValue
{
    NSAppleEventDescriptor *resultDesc;

    // collections go to lists
    if ([self respondsToSelector:@selector(objectEnumerator)]) 
    {
        id currentObject;
        int i;
        
        resultDesc = [NSAppleEventDescriptor listDescriptor];
        NSEnumerator *objectEnumerator = [(id)self objectEnumerator];
        i = 1; // apple event descriptors are 1-indexed
        while((currentObject = [objectEnumerator nextObject]) != nil)
        {
            [resultDesc insertDescriptor:[currentObject aeDescriptorValue]
                                 atIndex:i++];
        }
    }
    else if ([self respondsToSelector:@selector(objectSpecifier)] &&
             [NSScriptObjectSpecifier instancesRespondToSelector:@selector(_asDescriptor)]) // use the script object specifier
    {
        resultDesc = [[self objectSpecifier] performSelector:@selector(_asDescriptor)];
    }
    else // encode the description as a fallback - this is pretty useless, only helpful for debugging
    {
        resultDesc = [[self description] aeDescriptorValue];
    }
    
    return(resultDesc);
}
@end

@implementation NSArray (KFAppleScriptHandlerAdditions)

// don't need to override aeDescriptorValue, the NSObject will treat the array as a collection

+ (NSArray *)arrayWithAEDesc:(NSAppleEventDescriptor *)desc
{
    NSAppleEventDescriptor *listDesc;
    NSMutableArray *resultArray;
    int i, listCount;
    
    listDesc = [desc coerceToDescriptorType:typeAEList];
    resultArray = [NSMutableArray array];
    
    listCount = [listDesc numberOfItems];
    for (i = 1; i <= listCount; i++) // apple event descriptors are 1-indexed
    {
        [resultArray addObject:[[listDesc descriptorAtIndex:i] objCObjectValue]];
    }
    
    return resultArray;
}

@end

@implementation NSDictionary (KFAppleScriptHandlerAdditions)
- (NSAppleEventDescriptor *)aeDescriptorValue
{
    NSAppleEventDescriptor *resultDesc;
    NSMutableArray *userFields;
    NSArray *keys;
    int keyCount, i;
    
    resultDesc = [NSAppleEventDescriptor recordDescriptor];
    userFields = [NSMutableArray array];
    
    keys = [self allKeys];
    keyCount = [keys count];
    for (i = 0; i < keyCount; i++)
    {
        id key = [keys objectAtIndex:i];
        
        if ([key isKindOfClass:[NSNumber class]])
        {
            [resultDesc setDescriptor:[[self objectForKey:key] aeDescriptorValue]
                           forKeyword:[(NSNumber *)key intValue]];
        }
        else if ([key isKindOfClass:[NSString class]])
        {
            [userFields addObject:key];
            [userFields addObject:[self objectForKey:key]];
        }
        else
        {
            // do nothing
        }
    }
    
    if ([userFields count] > 0)
    {
        [resultDesc setDescriptor:[userFields aeDescriptorValue]
                       forKeyword:keyASUserRecordFields];
    }
        
    return(resultDesc);
}

+ (NSDictionary *)dictionaryWithAEDesc:(NSAppleEventDescriptor *)desc
{
    NSMutableDictionary *resultDict;
    NSAppleEventDescriptor *recDescriptor, *listDescriptor;
    int recordIndex, recordCount, listIndex, listCount, keyword;
    id keyObj, valObj;
        
    recDescriptor = [desc coerceToDescriptorType:typeAERecord];
    resultDict = [NSMutableDictionary dictionary];
    
    recordCount = [recDescriptor numberOfItems];
    for (recordIndex = 1; recordIndex <= recordCount; recordIndex++) // NSAppleEventDescriptor uses 1 indexing
    {
        keyword = [recDescriptor keywordForDescriptorAtIndex:recordIndex];
        
        if( keyword != keyASUserRecordFields)
        {
            keyObj = [NSNumber numberWithInt:keyword];
            valObj = [[recDescriptor descriptorAtIndex:recordIndex] objCObjectValue];
            
            [resultDict setObject:valObj forKey:keyObj];
        }
        else
        {
            listDescriptor = [recDescriptor descriptorAtIndex:recordIndex];
            
            listCount = [listDescriptor numberOfItems];
            for (listIndex = 1; listIndex <= listCount; listIndex += 2) // NSAppleEventDescriptor uses 1 indexing
            {
                keyObj = [[listDescriptor descriptorAtIndex:listIndex] objCObjectValue];
                valObj = [[listDescriptor descriptorAtIndex:listIndex+1] objCObjectValue];
                
                [resultDict setObject:valObj forKey:keyObj];
            }
        }
    }
    
    return resultDict;
}

@end

@implementation NSString (KFAppleScriptHandlerAdditions)
- (NSAppleEventDescriptor *)aeDescriptorValue
{
    NSAppleEventDescriptor *resultDesc;
    
    resultDesc = [NSAppleEventDescriptor descriptorWithString:self];
    
    return(resultDesc);
}

+ (NSString *)stringWithAEDesc:(NSAppleEventDescriptor *)desc
{
    return [desc stringValue];
}
   
@end

@implementation NSNull (KFAppleScriptHandlerAdditions)

- (NSAppleEventDescriptor *)aeDescriptorValue
{
    return [NSAppleEventDescriptor nullDescriptor];
}

+ (NSNull *)nullWithAEDesc:(NSAppleEventDescriptor *)desc
{
    return [NSNull null];
}

@end


@implementation NSDate (KFAppleScriptHandlerAdditions)

- (NSAppleEventDescriptor *)aeDescriptorValue
{
    NSAppleEventDescriptor *resultDesc;
    LongDateTime ldt;
    
    UCConvertCFAbsoluteTimeToLongDateTime(CFDateGetAbsoluteTime((CFDateRef)self), &ldt);
    resultDesc = [NSAppleEventDescriptor descriptorWithLongDateTime:ldt];
    
    return(resultDesc);
}

+ (NSDate *)dateWithAEDesc:(NSAppleEventDescriptor *)desc
{
    NSDate *resultDate;
    CFAbsoluteTime absTime;
    
    UCConvertLongDateTimeToCFAbsoluteTime([desc longDateTimeValue], &absTime);
    resultDate = (NSDate *)CFDateCreate(NULL, absTime);
    [resultDate autorelease];

    return resultDate;
}

@end



static inline int areEqualEncodings(const char *enc1, const char *enc2)
{
    return (strcmp(enc1, enc2) == 0);
}

@implementation NSNumber (KFAppleScriptHandlerAdditions)

-(id)kfDescriptorValueWithFloatP:(void *)float_p byteCount:(unsigned int)bytes
{
    NSAppleEventDescriptor *resultDesc = nil;
    float floatVal;
    double doubleVal;
    
    if (bytes < sizeof(Float32))
    {
        floatVal = [self floatValue];
        float_p = &floatVal;
        bytes = sizeof(floatVal);
    }
    
    if (bytes > sizeof(Float64))
    {
        doubleVal = [self doubleValue];
        float_p = &doubleVal;
        bytes = sizeof(doubleVal);
    }
    
    if (bytes == sizeof(Float32))
    {
        resultDesc = [NSAppleEventDescriptor descriptorWithFloat32:*(Float32 *)float_p];
    }
    else if (bytes == sizeof(Float64))
    {
        resultDesc = [NSAppleEventDescriptor descriptorWithFloat64:*(Float64 *)float_p];
    }
    else
    {
        [NSException raise:NSInvalidArgumentException 
                    format:@"Cannot create an NSAppleEventDescriptor for float with %d bytes of data.",  bytes];
    }
    
    return resultDesc;
}

-(id)kfDescriptorValueWithSignedIntP:(void *)int_p byteCount:(unsigned int)bytes
{
    NSAppleEventDescriptor *resultDesc;
    int intVal;
    
    if (bytes < sizeof(SInt16))
    {
        intVal = [self intValue];
        int_p = &intVal;
        bytes = sizeof(intVal);
    }
    
    if (bytes == sizeof(SInt16))
    {
        resultDesc = [NSAppleEventDescriptor descriptorWithInt16:*(SInt16 *)int_p];
    }
    else if (bytes == sizeof(SInt32))
    {
        resultDesc = [NSAppleEventDescriptor descriptorWithInt32:*(SInt32 *)int_p];
    }
    else
    {
        double val = [self doubleValue];
        resultDesc = [self kfDescriptorValueWithFloatP:&val byteCount:sizeof(val)];
    }
    
    return resultDesc;
}

-(id)kfDescriptorValueWithUnsignedIntP:(void *)int_p byteCount:(unsigned int)bytes
{
    NSAppleEventDescriptor *resultDesc;
    unsigned int uIntVal;
    
    if (bytes < sizeof(UInt32))
    {
        uIntVal = [self unsignedIntValue];
        int_p = &uIntVal;
        bytes = sizeof(uIntVal);
    }
    
    if (bytes == sizeof(UInt32))
    {
        resultDesc = [NSAppleEventDescriptor descriptorWithUnsignedInt32:*(UInt32 *)int_p];
    }
    else
    {
        double val = (double)[self unsignedLongLongValue];
        resultDesc = [self kfDescriptorValueWithFloatP:&val byteCount:sizeof(val)];
    }    
    
    return resultDesc;
}

- (NSAppleEventDescriptor *)aeDescriptorValue
{
    NSAppleEventDescriptor *resultDesc = nil;
    
    // NSNumber is unfortunately complicated, because the applescript 
    // type we should use depends on the c type that our NSNumber corresponds to
        
    const char *type = [self objCType];
            
    // convert
    if (areEqualEncodings(type, @encode(BOOL)))
    {
        resultDesc = [NSAppleEventDescriptor descriptorWithBoolean:[self boolValue]];
    }
    else if (areEqualEncodings(type, @encode(char)))
    {
        char val = [self charValue];
        resultDesc = [self kfDescriptorValueWithSignedIntP:&val byteCount:sizeof(val)];
    }    
    else if (areEqualEncodings(type, @encode(short)))
    {
        short val = [self shortValue];
        resultDesc = [self kfDescriptorValueWithSignedIntP:&val byteCount:sizeof(val)];
    }        
    else if (areEqualEncodings(type, @encode(int)))
    {
        int val = [self intValue];
        resultDesc = [self kfDescriptorValueWithSignedIntP:&val byteCount:sizeof(val)];
    }  
    else if (areEqualEncodings(type, @encode(long)))
    {
        long val = [self longValue];
        resultDesc = [self kfDescriptorValueWithSignedIntP:&val byteCount:sizeof(val)];
    }        
    else if (areEqualEncodings(type, @encode(long long)))
    {
        long long val = [self longLongValue];
        resultDesc = [self kfDescriptorValueWithSignedIntP:&val byteCount:sizeof(val)];
    }
    else if (areEqualEncodings(type, @encode(unsigned char)))
    {
        unsigned char val = [self unsignedCharValue];
        resultDesc = [self kfDescriptorValueWithUnsignedIntP:&val byteCount:sizeof(val)];
    }    
    else if (areEqualEncodings(type, @encode(unsigned short)))
    {
        unsigned short val = [self unsignedShortValue];
        resultDesc = [self kfDescriptorValueWithUnsignedIntP:&val byteCount:sizeof(val)];
    }    
    else if (areEqualEncodings(type, @encode(unsigned int)))
    {
        unsigned int val = [self unsignedIntValue];
        resultDesc = [self kfDescriptorValueWithUnsignedIntP:&val byteCount:sizeof(val)];
    }
    else if (areEqualEncodings(type, @encode(unsigned long)))
    {
        unsigned long val = [self unsignedLongValue];
        resultDesc = [self kfDescriptorValueWithUnsignedIntP:&val byteCount:sizeof(val)];
    }    
    else if (areEqualEncodings(type, @encode(unsigned long long)))
    {
        unsigned long long val = [self unsignedLongLongValue];
        resultDesc = [self kfDescriptorValueWithUnsignedIntP:&val byteCount:sizeof(val)];
    }    
    else if (areEqualEncodings(type, @encode(float)))
    {
        float val = [self floatValue];
        resultDesc = [self kfDescriptorValueWithFloatP:&val byteCount:sizeof(val)];
    }    
    else if (areEqualEncodings(type, @encode(double)))
    {
        double val = [self doubleValue];
        resultDesc = [self kfDescriptorValueWithFloatP:&val byteCount:sizeof(val)];
    }
    else
    {
        [NSException raise:@"KFUnsupportedAEDescriptorConversion"
                    format:@"KFAppleScriptHandlerAdditions: conversion of an NSNumber with objCType '%s' to an aeDescriptor is not supported.", type];
    }
    
    return(resultDesc);
}

+ (id)numberWithAEDesc:(NSAppleEventDescriptor *)desc;
{
    DescType type = [desc descriptorType];
    NSNumber *resultNumber = nil;
            
    if ((type == typeTrue) || (type == typeFalse) || (type == typeBoolean))
    {
        resultNumber = [NSNumber numberWithBool:[desc booleanValue]];
    }
    else if (type == typeSInt16)
    {
        SInt16 val = [desc int16Value];
        resultNumber = [NSNumber kfNumberWithSignedIntP:&val byteCount:sizeof(val)];
    }
    else if (type == typeSInt32)
    {
        SInt32 val = [desc int32Value];
        resultNumber = [NSNumber kfNumberWithSignedIntP:&val byteCount:sizeof(val)];
    }
    else if (type == typeUInt32)
    {
        UInt32 val = [desc unsignedInt32Value];
        resultNumber = [NSNumber kfNumberWithUnsignedIntP:&val byteCount:sizeof(val)];
    }
    else if (type == typeIEEE32BitFloatingPoint)
    {
        Float32 val = [desc float32Value];
        resultNumber = [NSNumber kfNumberWithFloatP:&val byteCount:sizeof(val)];
    }
    else if (type == typeIEEE64BitFloatingPoint)
    {
        Float64 val = [desc float64Value];
        resultNumber = [NSNumber kfNumberWithFloatP:&val byteCount:sizeof(val)];
    }
    else
    {
        // try to coerce to 64bit floating point
        desc = [desc coerceToDescriptorType:typeIEEE64BitFloatingPoint];
        if (desc == nil)
        {
            [NSException raise:@"KFUnsupportedAEDescriptorConversion"
                        format:@"KFAppleScriptHandlerAdditions: conversion of an NSAppleEventDescriptor with objCType '%s' to an aeDescriptor is not supported.", type];

        }
        else
        {
            Float64 val = [desc float64Value];
            resultNumber = [NSNumber kfNumberWithFloatP:&val byteCount:sizeof(val)];
        }
    }
    
    return resultNumber;
}

+ (id) kfNumberWithSignedIntP:(void *)int_p byteCount:(unsigned int)bytes
{
    NSNumber *resultNumber = nil;
    
    if (bytes == sizeof(char))
    {
        resultNumber = [NSNumber numberWithChar:*(char *)int_p];
    }    
    else if (bytes == sizeof(short))
    {
        resultNumber = [NSNumber numberWithShort:*(short *)int_p];
    }
    else if (bytes == sizeof(int))
    {
        resultNumber = [NSNumber numberWithInt:*(int *)int_p];
    }
    else if (bytes == sizeof(long))
    {
        resultNumber = [NSNumber numberWithLong:*(long *)int_p];
    }
    else if (bytes == sizeof(long long))
    {
        resultNumber = [NSNumber numberWithLongLong:*(long long *)int_p];
    }
    else 
    {
        [NSException raise:NSInvalidArgumentException 
                    format:@"NSNumber kfNumberWithSignedIntP:byteCount: number with %i bytes not supported.", bytes];
    }    
    
    return resultNumber;
}

+ (id) kfNumberWithUnsignedIntP:(void *)int_p byteCount:(unsigned int)bytes
{
    NSNumber *resultNumber = nil;
    
    if (bytes == sizeof(unsigned char))
    {
        resultNumber = [NSNumber numberWithUnsignedChar:*(unsigned char *)int_p];
    }    
    else if (bytes == sizeof(unsigned short))
    {
        resultNumber = [NSNumber numberWithUnsignedShort:*(unsigned short *)int_p];
    }
    else if (bytes == sizeof(unsigned int))
    {
        resultNumber = [NSNumber numberWithUnsignedInt:*(unsigned int *)int_p];
    }
    else if (bytes == sizeof(unsigned long))
    {
        resultNumber = [NSNumber numberWithUnsignedLong:*(unsigned long *)int_p];
    }
    else if (bytes == sizeof(unsigned long long))
    {
        resultNumber = [NSNumber numberWithUnsignedLongLong:*(unsigned long long *)int_p];
    }   
    else 
    {
        [NSException raise:NSInvalidArgumentException 
                    format:@"NSNumber numberWithUnsignedInt:byteCount: number with %i bytes not supported.", bytes];
    }
    
    return resultNumber;
}

+ (id) kfNumberWithFloatP:(void *)float_p byteCount:(unsigned int)bytes
{
    NSNumber *resultNumber= nil;
    
    if (bytes == sizeof(float))
    {
        resultNumber = [NSNumber numberWithFloat:*(float *)float_p];
    }
    else if (bytes == sizeof(double))
    {
        resultNumber = [NSNumber numberWithFloat:*(double *)float_p];
    }
    else 
    {
        [NSException raise:NSInvalidArgumentException 
                    format:@"NSNumber numberWithFloat:byteCount: floating point number with %i bytes not supported.", bytes];
    }
    
    return resultNumber;
}    

@end

@implementation NSValue (KFAppleScriptHandlerAdditions)

- (NSAppleEventDescriptor *)aeDescriptorValue
{
    NSAppleEventDescriptor *resultDesc = nil;
        
    const char *type = [self objCType];
    
    // convert
    if (areEqualEncodings(type, @encode(NSSize)))
    {
        NSSize size = [self sizeValue];
        resultDesc = [[NSArray arrayWithObjects:
            [NSNumber numberWithFloat:size.width],
            [NSNumber numberWithFloat:size.height],
            nil] aeDescriptorValue];
    }
    else if (areEqualEncodings(type, @encode(NSPoint)))
    {
        NSPoint point = [self pointValue];
        resultDesc = [[NSArray arrayWithObjects:
            [NSNumber numberWithFloat:point.x],
            [NSNumber numberWithFloat:point.y],
            nil] aeDescriptorValue];
    }    
    else if (areEqualEncodings(type, @encode(NSRange)))
    {
        NSRange range = [self rangeValue];
        resultDesc = [[NSArray arrayWithObjects:
            [NSNumber numberWithUnsignedInt:range.location],
            [NSNumber numberWithUnsignedInt:range.location + range.length],
            nil] aeDescriptorValue];
    }        
    else if (areEqualEncodings(type, @encode(NSRect)))
    {
        NSRect rect = [self rectValue];
        resultDesc = [[NSArray arrayWithObjects:
            [NSNumber numberWithFloat:rect.origin.x],
            [NSNumber numberWithFloat:rect.origin.y],
            [NSNumber numberWithFloat:rect.origin.x + rect.size.width],
            [NSNumber numberWithFloat:rect.origin.y + rect.size.height],
            nil] aeDescriptorValue];
    }  
    else
    {
        [NSException raise:@"KFUnsupportedAEDescriptorConversion"
                    format:@"KFAppleScriptHandlerAdditions: conversion of an NSNumber with objCType '%s' to an aeDescriptor is not supported.", type];
    }
    
    return(resultDesc);
}

@end

@implementation NSAppleEventDescriptor (KFAppleScriptHandlerAdditionsPrivate)

// we're going to leak this.  It doesn't matter much for running apps, but 
// for developers it might be nice to try to dispose of it (so it would not clutter the
// output when testing for leaks)
static NSMutableDictionary *handlerDict = nil;

+ (void)kfSetUpHandlerDict
{
    handlerDict = [[NSMutableDictionary alloc] init];
    
    // register default handlers
    // types are culled from AEDataModel.h and AERegistry.h
   
    // string -> NSStrings
    [NSAppleEventDescriptor registerConversionHandler:[NSString class]
                                             selector:@selector(stringWithAEDesc:)
                                   forDescriptorTypes:
        typeUnicodeText, 
        typeText, 
        typeUTF8Text, 
        typeCString, 
        typeChar, nil];

    // number/bool -> NSNumber
    [NSAppleEventDescriptor registerConversionHandler:[NSNumber class]
                                             selector:@selector(numberWithAEDesc:)
                                   forDescriptorTypes:
        typeBoolean,
        typeTrue,
        typeFalse,
        typeSInt16, 
        typeSInt32, 
        typeUInt32,
        typeSInt64,
        typeIEEE32BitFloatingPoint,
        typeIEEE64BitFloatingPoint,
        type128BitFloatingPoint, nil];
    
    
    // list -> NSArray
    [NSAppleEventDescriptor registerConversionHandler:[NSArray class]
                                             selector:@selector(arrayWithAEDesc:)
                                   forDescriptorTypes:
        typeAEList, nil];
    
    
    // record -> NSDictionary
    [NSAppleEventDescriptor registerConversionHandler:[NSDictionary class]
                                             selector:@selector(dictionaryWithAEDesc:)
                                   forDescriptorTypes:
        typeAERecord, nil];
    
    // date -> NSDate
    [NSAppleEventDescriptor registerConversionHandler:[NSDate class]
                                             selector:@selector(dateWithAEDesc:)
                                   forDescriptorTypes:
        typeLongDateTime, nil];
    
    // null -> NSNull
    [NSAppleEventDescriptor registerConversionHandler:[NSNull class]
                                             selector:@selector(nullWithAEDesc:)
                                   forDescriptorTypes:
        typeNull, nil];
}

@end

@implementation NSAppleEventDescriptor (KFAppleScriptHandlerAdditions)

- (id)objCObjectValue
{    
    id returnObj;
    DescType type;
    NSInvocation *handlerInvocation;
    
    if (handlerDict == nil)
    {
        [NSAppleEventDescriptor kfSetUpHandlerDict];
    }
    
    type = [self descriptorType];
    handlerInvocation = [handlerDict objectForKey:[NSValue valueWithBytes:&type objCType:@encode(DescType)]];
    if (handlerInvocation == nil)
    {
        // return raw apple event descriptor if no handler is registered
        returnObj = self;
    }
    else
    {
        [handlerInvocation setArgument:&self atIndex:2];
        [handlerInvocation invoke];
        [handlerInvocation getReturnValue:&returnObj];
    }
    
    return(returnObj);
}

// FIXME - error checking, non nil handler
+ (void)registerConversionHandler:(id)anObject
                         selector:(SEL)aSelector
               forDescriptorTypes:(DescType)firstType, ...
{
    NSInvocation *handlerInvocation;
    va_list typesList;
    DescType aType;

    if (handlerDict == nil)
    {
        [NSAppleEventDescriptor kfSetUpHandlerDict];
    }
    
    handlerInvocation = [NSInvocation invocationWithMethodSignature:[anObject methodSignatureForSelector:aSelector]];

    [handlerInvocation setTarget:anObject];
    [handlerInvocation setSelector:aSelector];    
    
    aType = firstType;
    va_start(typesList, firstType);
    do {
        [handlerDict setObject:handlerInvocation 
                        forKey:[NSValue valueWithBytes:&aType objCType:@encode(DescType)]];
    } while((aType = va_arg(typesList, DescType)) != nil);
    va_end(typesList);
}


- (NSAppleEventDescriptor *)aeDescriptorValue
{
    return(self);
}

+ (id)descriptorWithInt16:(SInt16)val
{
    return [NSAppleEventDescriptor descriptorWithDescriptorType:typeSInt16
                                                          bytes:&val
                                                         length:sizeof(val)];    
}

- (SInt16)int16Value
{
    SInt16 retValue;
    [[[self coerceToDescriptorType:typeSInt16] data] getBytes:&retValue];
    return retValue;
}

+ (id)descriptorWithUnsignedInt32:(UInt32)val
{
    return [NSAppleEventDescriptor descriptorWithDescriptorType:typeUInt32
                                                          bytes:&val
                                                         length:sizeof(val)];        
}

- (UInt32)unsignedInt32Value
{
    UInt32 retValue;
    [[[self coerceToDescriptorType:typeUInt32] data] getBytes:&retValue];
    return retValue;
}


+ (id)descriptorWithFloat32:(Float32)val
{
    return [NSAppleEventDescriptor descriptorWithDescriptorType:typeIEEE32BitFloatingPoint
                                                          bytes:&val
                                                         length:sizeof(val)];        
}

- (Float32)float32Value
{
    Float32 retValue;
    [[[self coerceToDescriptorType:typeIEEE32BitFloatingPoint] data] getBytes:&retValue];
    return retValue;
}


+ (id)descriptorWithFloat64:(Float64)val
{
    return [NSAppleEventDescriptor descriptorWithDescriptorType:typeIEEE64BitFloatingPoint
                                                          bytes:&val
                                                         length:sizeof(val)];        
}
        
- (Float64)float64Value
{
    Float64 retValue;
    [[[self coerceToDescriptorType:typeIEEE64BitFloatingPoint] data] getBytes:&retValue];
    return retValue;
}

+ (id)descriptorWithLongDateTime:(LongDateTime)val
{
    return [NSAppleEventDescriptor descriptorWithDescriptorType:typeLongDateTime
                                                          bytes:&val
                                                         length:sizeof(val)];        
}

- (LongDateTime)longDateTimeValue
{
    LongDateTime retValue;
    [[[self coerceToDescriptorType:typeLongDateTime] data] getBytes:&retValue];
    return retValue;
}

@end
