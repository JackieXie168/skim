//
//  SKFDFParser.m
//  Skim
//
//  Created by Christiaan Hofman on 9/6/07.
/*
 This software is Copyright (c) 2007
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

#import "SKFDFParser.h"
#import <Quartz/Quartz.h>
#import "NSScanner_SKExtensions.h"
#import "NSCharacterSet_SKExtensions.h"

@interface NSScanner (SKFDFParserExtensions)
- (BOOL)scanFDFObject:(id *)object;
- (BOOL)scanFDFArray:(NSArray **)array;
- (BOOL)scanFDFDictionary:(NSDictionary **)dictionary;
- (BOOL)scanFDFString:(NSString **)string;
- (BOOL)scanFDFHexString:(NSString **)string;
- (BOOL)scanFDFName:(NSString **)string;
- (BOOL)scanFDFNumber:(NSNumber **)number;
- (BOOL)scanFDFIndirectObject:(id *)object;
@end

#pragma mark -

@interface SKIndirectObject : NSObject <NSCopying> {
    int objectNumber;
    int generationNumber;
}
+ (id)indirectObjectWithNumber:(int)objNumber generation:(int)genNumber;
- (id)initWithNumber:(int)objNumber generation:(int)genNumber;
- (int)objectNumber;
- (int)generationNumber;
@end

#pragma mark -

@implementation SKFDFParser

+ (id)value:(id)value ofClass:(Class)aClass lookup:(NSDictionary *)lookup {
    while ([value isKindOfClass:[SKIndirectObject class]])
        value = [lookup objectForKey:value];
    return ([value isKindOfClass:aClass]) ? value : nil;
}

+ (NSDictionary *)noteDictionary:(NSDictionary *)dict lookup:(NSDictionary *)lookup {
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    NSEnumerator *keyEnum = [dict keyEnumerator];
    NSString *key;
    BOOL success = YES;
    
    while (success && (key = [keyEnum nextObject])) {
        id value = [dict valueForKey:key];
        
        if ([key isEqualToString:@"Type"]) {
            if (value = [self value:value ofClass:[NSString class] lookup:lookup])
                [dictionary setObject:value forKey:@"type"];
            else
                success = NO;
        } else if ([key isEqualToString:@"Contents"]) {
            if (value = [self value:value ofClass:[NSString class] lookup:lookup])
                [dictionary setObject:value forKey:@"contents"];
            else
                success = NO;
        } else if ([key isEqualToString:@"Rect"]) {
            if ((value = [self value:value ofClass:[NSArray class] lookup:lookup]) && [value count] == 4) {
                NSRect rect;
                rect.origin.x = [[value objectAtIndex:0] floatValue];
                rect.origin.y = [[value objectAtIndex:1] floatValue];
                rect.size.width = [[value objectAtIndex:2] floatValue] - NSMinX(rect);
                rect.size.height = [[value objectAtIndex:3] floatValue] - NSMinY(rect);
                [dictionary setObject:NSStringFromRect(rect) forKey:@"bounds"];
            } else {
                success = NO;
            }
        } else if ([key isEqualToString:@"Page"]) {
            if (value = [self value:value ofClass:[NSNumber class] lookup:lookup])
                [dictionary setObject:value forKey:@"pageIndex"];
            else
                success = NO;
        } else if ([key isEqualToString:@"C"]) {
            if ((value = [self value:value ofClass:[NSArray class] lookup:lookup]) && [value count] == 3) {
                float r, g, b;
                r = [[value objectAtIndex:0] floatValue];
                g = [[value objectAtIndex:1] floatValue];
                b = [[value objectAtIndex:2] floatValue];
                [dictionary setObject:[NSColor colorWithCalibratedRed:r green:g blue:b alpha:1.0] forKey:@"color"];
            } else {
                success = NO;
            }
        } else if ([key isEqualToString:@"BS"]) {
            if (value = [self value:value ofClass:[NSDictionary class] lookup:lookup]) {
                NSNumber *width = [value objectForKey:@"W"];
                NSString *s = [value objectForKey:@"S"];
                NSArray *dashPattern = [value objectForKey:@"D"];
                int style = kPDFBorderStyleSolid;
                if (s && [s isKindOfClass:[NSString class]]) {
                    success = NO;
                    break;
                }
                if (dashPattern && [dashPattern isKindOfClass:[NSArray class]] == NO) {
                    success = NO;
                    break;
                }
                if (width && [width isKindOfClass:[NSNumber class]] == NO) {
                    success = NO;
                    break;
                }
                if ([s isEqualToString:@"S"])
                    style = kPDFBorderStyleSolid;
                else if ([s isEqualToString:@"D"])
                    style = kPDFBorderStyleDashed;
                else if ([s isEqualToString:@"B"])
                    style = kPDFBorderStyleBeveled;
                else if ([s isEqualToString:@"I"])
                    style = kPDFBorderStyleInset;
                else if ([s isEqualToString:@"U"])
                    style = kPDFBorderStyleUnderline;
                if (width && [width floatValue] > 0.0) {
                    [dictionary setObject:width forKey:@"lineWidth"];
                    [dictionary setObject:[NSNumber numberWithInt:style] forKey:@"borderStyle"];
                    if (dashPattern)
                        [dictionary setObject:dashPattern forKey:@"dashPattern"];
                }
            } else {
                success = NO;
            }
        } else if ([key isEqualToString:@"Border"]) {
            if ([value isKindOfClass:[NSArray class]] == NO) {
                success = NO;
                break;
            }
            NSNumber *width = [value count] > 2 ? [value objectAtIndex:2] : nil;
            NSArray *dashPattern = [value count] > 3 ? [value objectAtIndex:3] : nil;
            if (dashPattern && [dashPattern isKindOfClass:[NSArray class]] == NO) {
                success = NO;
                break;
            }
            if (width && [width isKindOfClass:[NSNumber class]] == NO) {
                success = NO;
                break;
            }
            if (width && [width floatValue] > 0.0) {
                [dictionary setObject:width forKey:@"lineWidth"];
                [dictionary setObject:[NSNumber numberWithInt:dashPattern ? kPDFBorderStyleDashed : kPDFBorderStyleSolid] forKey:@"borderStyle"];
                if (dashPattern)
                    [dictionary setObject:dashPattern forKey:@"dashPattern"];
            }
        } else if ([key isEqualToString:@"Name"]) {
            if (value = [self value:value ofClass:[NSString class] lookup:lookup]) {
                int icon = kPDFTextAnnotationIconNote;
                if ([value isEqualToString:@"Comment"])
                    icon = kPDFTextAnnotationIconComment;
                else if ([value isEqualToString:@"Key"])
                    icon = kPDFTextAnnotationIconKey;
                else if ([value isEqualToString:@"Note"])
                    icon = kPDFTextAnnotationIconNote;
                else if ([value isEqualToString:@"NewParagraph"])
                    icon = kPDFTextAnnotationIconNewParagraph;
                else if ([value isEqualToString:@"Paragraph"])
                    icon = kPDFTextAnnotationIconParagraph;
                else if ([value isEqualToString:@"Insert"])
                    icon = kPDFTextAnnotationIconInsert;
                [dictionary setObject:[NSNumber numberWithInt:icon] forKey:@"iconType"];
            } else {
                success = NO;
            }
        } else if ([key isEqualToString:@"IC"]) {
            if ((value = [self value:value ofClass:[NSArray class] lookup:lookup]) && [value count] == 3) {
                float r, g, b;
                r = [[value objectAtIndex:0] floatValue];
                g = [[value objectAtIndex:1] floatValue];
                b = [[value objectAtIndex:2] floatValue];
                [dictionary setObject:[NSColor colorWithCalibratedRed:r green:g blue:b alpha:1.0] forKey:@"interiorColor"];
            } else {
                success = NO;
            }
        } else if ([key isEqualToString:@"LE"]) {
            if ((value = [self value:value ofClass:[NSArray class] lookup:lookup]) && [value count] == 2) {
                NSString *start = [value objectAtIndex:0];
                NSString *end = [value objectAtIndex:1];
                int startStyle = kPDFLineStyleNone;
                int endStyle = kPDFLineStyleNone;
                if (start && [start isKindOfClass:[NSNumber class]] == NO) {
                    success = NO;
                    break;
                }
                if (end && [end isKindOfClass:[NSNumber class]] == NO) {
                    success = NO;
                    break;
                }
                if ([end isEqualToString:@"None"])
                    startStyle = kPDFLineStyleNone;
                else if ([end isEqualToString:@"Square"])
                    startStyle = kPDFLineStyleSquare;
                else if ([end isEqualToString:@"Circle"])
                    startStyle = kPDFLineStyleCircle;
                else if ([end isEqualToString:@"Diamond"])
                    startStyle = kPDFLineStyleDiamond;
                else if ([end isEqualToString:@"OpenArrow"])
                    startStyle = kPDFLineStyleOpenArrow;
                else if ([end isEqualToString:@"ClosedArrow"])
                    startStyle = kPDFLineStyleClosedArrow;
                [dictionary setObject:[NSNumber numberWithInt:startStyle] forKey:@"startLineStyle"];
                [dictionary setObject:[NSNumber numberWithInt:endStyle] forKey:@"endLineStyle"];
            } else {
                success = NO;
            }
        } else if ([key isEqualToString:@"QuadPoints"]) {
            if ((value = [self value:value ofClass:[NSArray class] lookup:lookup]) && [value count] % 8 == 0) {
                NSMutableArray *quadPoints = [NSMutableArray array];
                int i, count = [value count];
                for (i = 0; i < count; i++) {
                    NSPoint point;
                    point.x = [[value objectAtIndex:i] floatValue];
                    point.y = [[value objectAtIndex:++i] floatValue];
                    [quadPoints addObject:NSStringFromPoint(point)];
                }
                [dictionary setObject:quadPoints forKey:@"quadrilateralPoints"];
            } else {
                success = NO;
            }
        }
    }
    return success ? dictionary : nil;
}

+ (NSArray *)notesDictionariesFromFDFString:(NSString *)string {
    NSMutableArray *array = nil;
    NSDictionary *fdfDict;
    NSDictionary *trailer;
    SKIndirectObject *root;
    NSDictionary *rootDict;
    NSArray *annots;
    
    if ((fdfDict = [self fdfObjectsFromFDFString:string]) &&
        (trailer = [fdfDict objectForKey:@"trailer"]) &&
        ([trailer isKindOfClass:[NSDictionary class]]) &&
        (root = [trailer objectForKey:@"Root"]) &&
        (rootDict = [fdfDict objectForKey:root]) &&
        ([rootDict isKindOfClass:[NSDictionary class]]) &&
        (annots = [trailer objectForKey:@"Annots"]) &&
        ([annots isKindOfClass:[NSArray class]])) {
    
        NSEnumerator *annotEnum = [annots objectEnumerator];
        NSDictionary *dict;
        
        array = [NSMutableArray array];
        while (dict = [annotEnum nextObject]) {
            while ([dict isKindOfClass:[SKIndirectObject class]])
                dict = [fdfDict objectForKey:dict];
            if ([dict isKindOfClass:[NSDictionary class]] == NO)
                return nil;
            if (dict = [self noteDictionary:dict lookup:fdfDict])
                [array addObject:dict];
        }
    }
    
    return array;
}

+ (NSDictionary *)fdfObjectsFromFDFString:(NSString *)string {
    NSMutableDictionary *fdfDict = [NSMutableDictionary dictionary];
    
    NSDictionary *dictionary;
    int objNumber, genNumber;
    id object;
    BOOL success = YES;
    
    NSScanner *scanner = [NSScanner scannerWithString:string];
    
    [scanner setCharactersToBeSkipped:nil];
    
    // Scan the FDF header
    [scanner scanString:@"%FDF-1.2" intoString:NULL];
    [scanner scanCharactersFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet] intoString:NULL];
    if ([scanner scanString:@"%" intoString:NULL])
        [scanner scanUpToCharactersFromSet:[NSCharacterSet newlineCharacterSet] intoString:NULL];
    [scanner scanCharactersFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet] intoString:NULL];
    
    // Scan the FDF body
    while (success = success && [scanner scanInt:&objNumber] &&
                    [scanner scanCharactersFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet] intoString:NULL] &&
                    [scanner scanInt:&genNumber] &&
                    [scanner scanCharactersFromSet:[NSCharacterSet whitespaceCharacterSet] intoString:NULL] &&
                    [scanner scanString:@"obj" intoString:NULL]) {
        
        [scanner scanCharactersFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet] intoString:NULL];
        if (success = [scanner scanFDFObject:&object]) {
            [scanner scanCharactersFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet] intoString:NULL];
            
            if ([object isKindOfClass:[NSDictionary class]] && [scanner scanString:@"stream" intoString:NULL]) {
                object = @"";
                [scanner scanString:@"\n" intoString:NULL] || [scanner scanString:@"\r\n" intoString:NULL];
                
                if ([scanner scanUpToString:@"endstream" intoString:&object]) {
                    int end = [object length];
                    unichar ch = end ? [object characterAtIndex:end - 1] : 0;
                    if ([[NSCharacterSet newlineCharacterSet] characterIsMember:ch]) {
                        end--;
                        if (end && ch == '\n' && [object characterAtIndex:end - 1] == '\r')
                            end--;
                        object = [object substringToIndex:end];
                    }
                }
                [scanner scanString:@"endstream" intoString:NULL];
                [scanner scanCharactersFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet] intoString:NULL];
            }
            [fdfDict setObject:object forKey:[SKIndirectObject indirectObjectWithNumber:objNumber generation:genNumber]];
            success = [scanner scanString:@"endobj" intoString:NULL];
            [scanner scanCharactersFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet] intoString:NULL];
        }
    }
    
    // Scan the FDF cross reference table, if present
    while (success && [scanner scanString:@"xref" intoString:NULL]) {
        [scanner scanUpToCharactersFromSet:[NSCharacterSet newlineCharacterSet] intoString:NULL];
        [scanner scanCharactersFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet] intoString:NULL];
        while ([scanner scanInt:NULL]) {
            [scanner scanUpToCharactersFromSet:[NSCharacterSet newlineCharacterSet] intoString:NULL];
            [scanner scanCharactersFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet] intoString:NULL];
        }
    }
    
    // Scan the FDF trailer
    if (success = success && [scanner scanString:@"trailer" intoString:NULL]) {
        [scanner scanCharactersFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet] intoString:NULL];
        if (success = [scanner scanFDFDictionary:&dictionary] && 
                [scanner scanCharactersFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet] intoString:NULL] &&
                [scanner scanString:@"%%EOF" intoString:NULL])
            [fdfDict setObject:dictionary forKey:@"trailer"];
    }
    
    return success ? fdfDict : nil;
}

@end

#pragma mark -

@implementation NSScanner (SKFDFParserExtensions)

- (BOOL)scanFDFObject:(id *)object {
    id tmpObject = nil;
    BOOL success = [self scanFDFName:&tmpObject] || 
        [self scanFDFString:&tmpObject] || 
        [self scanFDFHexString:&tmpObject] || 
        [self scanFDFNumber:&tmpObject] || 
        [self scanFDFArray:&tmpObject] || 
        [self scanFDFDictionary:&tmpObject] || 
        [self scanFDFIndirectObject:&tmpObject] || 
        [self scanString:@"null" intoString:NULL];
    
    if (success && object)
        *object = tmpObject;
    
    return success;
}

- (BOOL)scanFDFArray:(NSArray **)array {
    NSMutableArray *tmpArray = [NSMutableArray array];
    unichar ch;
    id object;
    BOOL success = [self scanString:@"[" intoString:NULL];
    
    while (success) {
        [self scanCharactersFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet] intoString:NULL];
        
        if ([self peekCharacter:&ch] == NO) {
            success = NO;
            break;
        }
        if (ch == ']')
            break;
        else if ((success = [self scanFDFObject:&object]) && object)
            [tmpArray addObject:object];
    }
    
    if (success && array)
        *array = tmpArray;
    
    return success;
}

- (BOOL)scanFDFDictionary:(NSDictionary **)dictionary {
    NSMutableDictionary *tmpDict = [NSMutableDictionary dictionary];
    unichar ch;
    NSString *key;
    id object;
    BOOL success = [self scanString:@"<<" intoString:NULL];
    
    while (success) {
        [self scanCharactersFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet] intoString:NULL];
        
        if ([self peekCharacter:&ch] == NO) {
            success = NO;
            break;
        }
        if ([self scanFDFName:&key]) {
            [self scanCharactersFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet] intoString:NULL];
            if ((success = [self scanFDFObject:&object]) && object)
                [tmpDict setObject:object forKey:key];
        } else if ([self scanString:@">>" intoString:NULL]) {
            break;
        } else {
            success = NO;
        }
    }
    
    if (success && dictionary)
        *dictionary = tmpDict;
    
    return success;
}

- (BOOL)scanFDFString:(NSString **)string {
    static NSCharacterSet *specialCharSet = nil;
    if (specialCharSet == nil)
        specialCharSet = [[NSCharacterSet characterSetWithCharactersInString:@"\\)"] retain];
    
    static NSCharacterSet *octalCharSet = nil;
    if (octalCharSet == nil)
        octalCharSet = [[NSCharacterSet characterSetWithCharactersInString:@"01234567"] retain];
    
    NSMutableString *tmpString = [NSMutableString string];
    NSString *s;
    unichar ch;
    BOOL success = [self scanString:@"(" intoString:NULL];
    
    while (success) {
        if ([self scanUpToCharactersFromSet:specialCharSet intoString:&s])
            [tmpString appendString:s];
        if ([self scanCharacter:&ch]) {
            if (ch == ')') {
                break;
            } else if (ch == '\\') {
                if ([self scanCharacter:&ch]) {
                    if (ch == 'n') {
                        [tmpString appendString:@"\n"];
                    } else if (ch == 'r') {
                        [tmpString appendString:@"\r"];
                    } else if (ch == 't') {
                        [tmpString appendString:@"\r"];
                    } else if (ch == 'b') {
                        [tmpString appendString:@"\b"];
                    } else if (ch == 'f') {
                        [tmpString appendString:@"\f"];
                    } else if (ch == '(') {
                        [tmpString appendString:@"("];
                    } else if (ch == ')') {
                        [tmpString appendString:@")"];
                    } else if (ch == '\\') {
                        [tmpString appendString:@"\\"];
                    } else if ([octalCharSet characterIsMember:ch]) {
                        char octal = ch;
                        if ([self peekCharacter:&ch] && [octalCharSet characterIsMember:ch]) {
                            [self scanCharacter:NULL];
                            octal = 8 * octal + ch;
                            if ([self peekCharacter:&ch] && [octalCharSet characterIsMember:ch]) {
                                [self scanCharacter:NULL];
                                octal = 8 * octal + ch;
                            }
                        }
                        NSString *s = [[NSString alloc] initWithBytes:&octal length:1 encoding:NSISOLatin1StringEncoding];
                        if (success = s != nil)
                            [tmpString appendString:s];
                        [s release];
                    } else
                        success = NO;
                } else {
                    success = NO;
                }
            }
        } else {
            success = NO;
        }
    }
    
    if (success && string)
        *string = tmpString;
    
    return success;
}

static inline int hexCharacterNumber(unichar ch) {
    if (ch >= '0' && ch <= '9')
        return ch - '0';
    if (ch >= 'A' && ch <= 'F')
        return ch - 'A' + 10;
    if (ch >= 'a' && ch <= 'f')
        return ch - 'a' + 10;
    return 0;
}

- (BOOL)scanFDFHexString:(NSString **)string {
    static NSCharacterSet *hexCharSet = nil;
    if (hexCharSet == nil)
        hexCharSet = [[NSCharacterSet characterSetWithCharactersInString:@"0123456789abcdefABCDEF"] retain];
    
    int rewindLoc = [self scanLocation];
    NSString *hexString = nil;
    unichar ch;
    char hexChar;
    char *bytes = NULL;
    int length = 0;
    BOOL isFirst = YES;
    BOOL done = NO;
    BOOL success = [self scanString:@"<" intoString:NULL];

    while (done == NO && success && (success = [self scanCharacter:&ch])) {
        hexChar = 0;
        if ([hexCharSet characterIsMember:ch]) {
            hexChar += hexCharacterNumber(ch);
        } else if ([[NSCharacterSet whitespaceAndNewlineCharacterSet] characterIsMember:ch]) {
            // ignore
        } else if (ch == '>') {
            done = YES;
        } else {
            success = NO;
        }
        if (isFirst) {
            hexChar *= 16;
        } else {
            length++;
            bytes = NSZoneRealloc([self zone], bytes, length * sizeof(char));
            bytes[length - 1] = hexChar;
            hexChar = 0;
        }
        isFirst = !isFirst;
    }
    
    if (success) {
        hexString = length == 0 ? @"" : [[[NSString alloc] initWithBytes:bytes length:length encoding:NSISOLatin1StringEncoding] autorelease];
        success = hexString != nil;
    }
    
    if (bytes)
        NSZoneFree([self zone], bytes);
    
    if (success == NO)
        [self setScanLocation:rewindLoc];
    
    if (success && string)
        *string = hexString;
    
    return success;
}

- (BOOL)scanFDFName:(NSString **)string {
    static NSCharacterSet *whitespaceOrDelimiterCharSet = nil;
    if (whitespaceOrDelimiterCharSet == nil) {
        NSMutableCharacterSet *tmpSet = [[NSCharacterSet whitespaceAndNewlineCharacterSet] mutableCopy];
        [tmpSet addCharactersInString:@"()<>[]{}/%"];
        whitespaceOrDelimiterCharSet = [[tmpSet invertedSet] copy];
        [tmpSet release];
    }
    return [self scanString:@"/" intoString:NULL] && [self scanUpToCharactersFromSet:whitespaceOrDelimiterCharSet intoString:string];
}

- (BOOL)scanFDFNumber:(NSNumber **)number {
    float f;
    BOOL success = [self scanFloat:&f];
    
    if (success && number)
        *number = [NSNumber numberWithFloat:f];
    
    return success;
}

- (BOOL)scanFDFIndirectObject:(id *)object {
    int rewindLoc = [self scanLocation];
    id tmpObject;
    int objNumber, genNumber;
    BOOL success;
    
    if (success = [self scanInt:&objNumber] && [self scanCharactersFromSet:[NSCharacterSet whitespaceCharacterSet] intoString:NULL] &&
        [self scanInt:&genNumber] && [self scanCharactersFromSet:[NSCharacterSet whitespaceCharacterSet] intoString:NULL] &&
        [self scanString:@"R" intoString:NULL])
        tmpObject = [SKIndirectObject indirectObjectWithNumber:objNumber generation:genNumber];
    
    if (success == NO)
        [self setScanLocation:rewindLoc];
    
    if (success && object)
        *object = tmpObject;
    
    return success;
}

@end

#pragma mark -

@implementation SKIndirectObject : NSObject

+ (id)indirectObjectWithNumber:(int)objNumber generation:(int)genNumber {
    return [[[self alloc] initWithNumber:objNumber generation:genNumber] autorelease];
}

- (id)initWithNumber:(int)objNumber generation:(int)genNumber {
    if (self = [super init]) {
        objectNumber = objNumber;
        generationNumber = genNumber;
    }
    return self;
}

- (id)copyWithZone:(NSZone *)aZone {
    return [self retain];
}

- (BOOL)isEqual:(id)other {
    return [self isMemberOfClass:[other class]] && [self objectNumber] == [other objectNumber] && [self generationNumber] == [other generationNumber];
}

- (int)objectNumber {
    return objectNumber;
}

- (int)generationNumber {
    return generationNumber;
}

@end
