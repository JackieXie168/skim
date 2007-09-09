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
#import "SKStringConstants.h"


@interface SKFDFParser (SKPrivate)
- (id)initWithString:(NSString *)aString;
- (BOOL)parseFDFString;
- (NSArray *)noteDictionaries;
- (NSDictionary *)noteDictionary:(NSDictionary *)dict;
- (id)value:(id)value ofClass:(Class)aClass;
- (NSString *)stringValue:(id)value;
- (NSNumber *)numberValue:(id)value;
- (NSArray *)arrayValue:(id)value;
- (NSDictionary *)dictionaryValue:(id)value;
@end


@interface NSScanner (SKFDFParserExtensions)
- (BOOL)scanFDFObject:(id *)object;
- (BOOL)scanFDFArray:(NSArray **)array;
- (BOOL)scanFDFDictionary:(NSDictionary **)dictionary;
- (BOOL)scanFDFString:(NSString **)string;
- (BOOL)scanFDFHexString:(NSString **)string;
- (BOOL)scanFDFName:(NSString **)string;
- (BOOL)scanFDFNumber:(NSNumber **)number;
- (BOOL)scanFDFBoolean:(id *)boolNumber;
- (BOOL)scanFDFIndirectObject:(id *)object;
- (BOOL)scanFDFComment:(NSString **)comment;
@end

#pragma mark -

@interface SKIndirectObject : NSObject <NSCopying> {
    unsigned int objectNumber;
    unsigned int generationNumber;
}
+ (id)indirectObjectWithNumber:(unsigned int)objNumber generation:(unsigned int)genNumber;
- (id)initWithNumber:(unsigned int)objNumber generation:(unsigned int)genNumber;
- (unsigned int)objectNumber;
- (unsigned int)generationNumber;
@end

#pragma mark -

@implementation SKFDFParser

+ (NSArray *)noteDictionariesFromFDFString:(NSString *)string {
    NSArray *notes = nil;
    SKFDFParser *parser = [[self alloc] initWithString:string];
    
    if ([parser parseFDFString])
        notes = [parser noteDictionaries];
    [parser release];
    
    return notes;
}

- (id)initWithString:(NSString *)string {
    if (self = [super init]) {
        fdfString = [string retain];
        fdfDictionary = nil;
    }
    return self;
}

- (void)dealloc {
    [fdfString release];
    [fdfDictionary release];
    [super dealloc];
}

- (BOOL)parseFDFString {
    NSMutableDictionary *fdfDict = [[NSMutableDictionary alloc] init];
    
    NSDictionary *dictionary;
    int objNumber, genNumber;
    id object;
    BOOL success = YES;
    
    NSScanner *scanner = [[NSScanner alloc] initWithString:fdfString];
    
    // Scan the FDF header
    [scanner scanString:@"%FDF-1.2" intoString:NULL];
    while ([scanner scanFDFComment:NULL]);
    
    // Scan the FDF body
    while (success && [scanner scanInt:&objNumber]) {
        while ([scanner scanFDFComment:NULL]);
        if (success = [scanner scanInt:&genNumber]) {
            while ([scanner scanFDFComment:NULL]);
            if (success = [scanner scanString:@"obj" intoString:NULL]) {
                if (success = [scanner scanFDFObject:&object]) {
                    if ([object isKindOfClass:[NSDictionary class]]) {
                        while ([scanner scanFDFComment:NULL]);
                        if ([scanner scanString:@"stream" intoString:NULL]) {
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
                        }
                        [fdfDict setObject:object forKey:[SKIndirectObject indirectObjectWithNumber:objNumber generation:genNumber]];
                        while ([scanner scanFDFComment:NULL]);
                        success = [scanner scanString:@"endobj" intoString:NULL];
                        while ([scanner scanFDFComment:NULL]);
                    }
                }
            }
        }
    }
    
    // Scan the FDF cross reference table, if present
    if (success) {
        while ([scanner scanString:@"xref" intoString:NULL]) {
            while ([scanner scanFDFComment:NULL]);
            while ([scanner scanInt:NULL]) {
                while ([scanner scanFDFComment:NULL]);
            }
        }
    }
    
    // Scan the FDF trailer
    if (success = success && [scanner scanString:@"trailer" intoString:NULL]) {
        while ([scanner scanFDFComment:NULL]);
        if (success = [scanner scanFDFDictionary:&dictionary]) {
            while ([scanner scanFDFComment:NULL]);
            [fdfDict setObject:dictionary forKey:@"trailer"];
            [scanner scanString:@"%%EOF" intoString:NULL];
        }
    }
    
    [scanner release];
    
    if (success)
        fdfDictionary = fdfDict;
    else
        [fdfDict release];
    
    return success;
}

- (NSArray *)noteDictionaries {
    NSMutableArray *array = nil;
    NSDictionary *trailer;
    SKIndirectObject *root;
    NSDictionary *rootDict;
    NSDictionary *fdfDict;
    NSArray *annots;
    
    if ((trailer = [fdfDictionary objectForKey:@"trailer"]) &&
        ([trailer isKindOfClass:[NSDictionary class]]) &&
        (root = [trailer objectForKey:@"Root"]) &&
        ([root isKindOfClass:[SKIndirectObject class]]) &&
        (rootDict = [fdfDictionary objectForKey:root]) &&
        ([rootDict isKindOfClass:[NSDictionary class]]) &&
        (fdfDict = [rootDict objectForKey:@"FDF"]) &&
        ([fdfDict isKindOfClass:[NSDictionary class]]) &&
        (annots = [fdfDict objectForKey:@"Annots"]) &&
        ([annots isKindOfClass:[NSArray class]])) {
    
        NSEnumerator *annotEnum = [annots objectEnumerator];
        NSDictionary *dict;
        
        array = [NSMutableArray array];
        while (dict = [annotEnum nextObject]) {
            if ((dict = [self dictionaryValue:dict]) &&
                (dict = [self noteDictionary:dict]))
                [array addObject:dict];
        }
    }
    
    return array;
}

- (id)value:(id)value ofClass:(Class)aClass {
    while ([value isKindOfClass:[SKIndirectObject class]])
        value = [fdfDictionary objectForKey:value];
    return (aClass == Nil || [value isKindOfClass:aClass]) ? value : nil;
}

- (NSString *)stringValue:(id)value {
    return [self value:value ofClass:[NSString class]];
}

- (NSNumber *)numberValue:(id)value {
    return [self value:value ofClass:[NSNumber class]];
}

- (NSArray *)arrayValue:(id)value {
    return [self value:value ofClass:[NSArray class]];
}

- (NSDictionary *)dictionaryValue:(id)value {
    return [self value:value ofClass:[NSDictionary class]];
}

- (NSDictionary *)noteDictionary:(NSDictionary *)dict {
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    NSSet *validTypes = [NSSet setWithObjects:@"FreeText", @"Note", @"Circle", @"Square", @"Highlight", @"Underline", @"StrikeOut", @"Line", nil];
    NSEnumerator *keyEnum = [dict keyEnumerator];
    NSString *key;
    BOOL success = YES;
    
    while (success && (key = [keyEnum nextObject])) {
        id value = [dict valueForKey:key];
        
        if ([key isEqualToString:@"Type"]) {
            if (value = [self stringValue:value]) {
                if ([value isEqualToString:@"Annot"] == NO) {
                    success = NO;
                }
            } else {
                success = NO;
            }
        } else if ([key isEqualToString:@"Subtype"]) {
            if (value = [self stringValue:value]) {
                if ([value isEqualToString:@"Text"])
                    value = @"Note";
                if ([validTypes containsObject:value]) {
                    [dictionary setObject:value forKey:@"type"];
                } else {
                    success = NO;
                }
            } else {
                success = NO;
            }
        } else if ([key isEqualToString:@"Contents"]) {
            if (value = [self stringValue:value]) {
                [dictionary setObject:value forKey:@"contents"];
            } else {
                success = NO;
            }
        } else if ([key isEqualToString:@"Rect"]) {
            if ((value = [self arrayValue:value]) && [value count] == 4) {
                NSNumber *l = [self numberValue:[value objectAtIndex:0]];
                NSNumber *b = [self numberValue:[value objectAtIndex:1]];
                NSNumber *r = [self numberValue:[value objectAtIndex:2]];
                NSNumber *t = [self numberValue:[value objectAtIndex:3]];
                if (l && b && r && t) {
                    NSRect rect;
                    rect.origin.x = [l floatValue];
                    rect.origin.y = [b floatValue];
                    rect.size.width = [r floatValue] - NSMinX(rect);
                    rect.size.height = [t floatValue] - NSMinY(rect);
                    [dictionary setObject:NSStringFromRect(rect) forKey:@"bounds"];
                } else {
                    success = NO;
                }
            } else {
                success = NO;
            }
        } else if ([key isEqualToString:@"Page"]) {
            if (value = [self numberValue:value]) {
                [dictionary setObject:value forKey:@"pageIndex"];
            } else {
                success = NO;
            }
        } else if ([key isEqualToString:@"C"]) {
            if ((value = [self arrayValue:value]) && [value count] == 3) {
                NSNumber *r = [self numberValue:[value objectAtIndex:0]];
                NSNumber *g = [self numberValue:[value objectAtIndex:1]];
                NSNumber *b = [self numberValue:[value objectAtIndex:2]];
                if (r && g && b) {
                    [dictionary setObject:[NSColor colorWithCalibratedRed:[r floatValue] green:[g floatValue] blue:[b floatValue] alpha:1.0] forKey:@"color"];
                } else {
                    success = NO;
                }
            } else {
                success = NO;
            }
        } else if ([key isEqualToString:@"BS"]) {
            if (value = [self dictionaryValue:value]) {
                NSNumber *width = [self numberValue:[value objectForKey:@"W"]];
                NSString *s = [self stringValue:[value objectForKey:@"S"]];
                NSArray *dashPattern = [self arrayValue:[value objectForKey:@"D"]];
                int style = kPDFBorderStyleSolid;
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
            NSNumber *width = [value count] > 2 ?  [self numberValue:[value objectAtIndex:2]] : nil;
            NSArray *dashPattern = [value count] > 3 ? [self arrayValue:[value objectAtIndex:2]] : nil;
            if (width && [width floatValue] > 0.0) {
                [dictionary setObject:width forKey:@"lineWidth"];
                [dictionary setObject:[NSNumber numberWithInt:dashPattern ? kPDFBorderStyleDashed : kPDFBorderStyleSolid] forKey:@"borderStyle"];
                if (dashPattern)
                    [dictionary setObject:dashPattern forKey:@"dashPattern"];
            }
        } else if ([key isEqualToString:@"Name"]) {
            if (value = [self stringValue:value]) {
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
            if ((value = [self arrayValue:value]) && [value count] == 3) {
                NSNumber *r = [self numberValue:[value objectAtIndex:0]];
                NSNumber *g = [self numberValue:[value objectAtIndex:1]];
                NSNumber *b = [self numberValue:[value objectAtIndex:2]];
                if (r && g && b) {
                    [dictionary setObject:[NSColor colorWithCalibratedRed:[r floatValue] green:[g floatValue] blue:[b floatValue] alpha:1.0] forKey:@"interiorColor"];
                } else {
                    success = NO;
                }
            } else {
                success = NO;
            }
        } else if ([key isEqualToString:@"LE"]) {
            if ((value = [self arrayValue:value]) && [value count] == 2) {
                NSString *start = [self stringValue:[value objectAtIndex:0]];
                NSString *end = [self stringValue:[value objectAtIndex:1]];
                int startStyle = kPDFLineStyleNone;
                int endStyle = kPDFLineStyleNone;
                if ([start isEqualToString:@"None"])
                    startStyle = kPDFLineStyleNone;
                else if ([start isEqualToString:@"Square"])
                    startStyle = kPDFLineStyleSquare;
                else if ([start isEqualToString:@"Circle"])
                    startStyle = kPDFLineStyleCircle;
                else if ([start isEqualToString:@"Diamond"])
                    startStyle = kPDFLineStyleDiamond;
                else if ([start isEqualToString:@"OpenArrow"])
                    startStyle = kPDFLineStyleOpenArrow;
                else if ([start isEqualToString:@"ClosedArrow"])
                    startStyle = kPDFLineStyleClosedArrow;
                if ([end isEqualToString:@"None"])
                    startStyle = kPDFLineStyleNone;
                else if ([end isEqualToString:@"Square"])
                    endStyle = kPDFLineStyleSquare;
                else if ([end isEqualToString:@"Circle"])
                    endStyle = kPDFLineStyleCircle;
                else if ([end isEqualToString:@"Diamond"])
                    endStyle = kPDFLineStyleDiamond;
                else if ([end isEqualToString:@"OpenArrow"])
                    endStyle = kPDFLineStyleOpenArrow;
                else if ([end isEqualToString:@"ClosedArrow"])
                    endStyle = kPDFLineStyleClosedArrow;
                [dictionary setObject:[NSNumber numberWithInt:startStyle] forKey:@"startLineStyle"];
                [dictionary setObject:[NSNumber numberWithInt:endStyle] forKey:@"endLineStyle"];
            } else {
                success = NO;
            }
        } else if ([key isEqualToString:@"QuadPoints"]) {
            if ((value = [self arrayValue:value]) && [value count] % 8 == 0) {
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
        } else if ([key isEqualToString:@"DA"]) {
            if (value = [self stringValue:value]) {
                NSScanner *scanner = [NSScanner scannerWithString:value];
                NSString *fontName;
                float fontSize;
                if ([scanner scanUpToString:@"Tf" intoString:NULL] && [scanner isAtEnd] == NO) {
                    unsigned location = [scanner scanLocation];
                    NSRange r = [value rangeOfString:@"/" options:NSBackwardsSearch range:NSMakeRange(0, location)];
                    if (r.location != NSNotFound) {
                        [scanner setScanLocation:NSMaxRange(r)];
                        if ([scanner scanCharactersFromSet:[NSCharacterSet nonWhitespaceAndNewlineCharacterSet] intoString:&fontName] && 
                            [scanner scanFloat:&fontSize] && 
                            [scanner scanString:@"Tf" intoString:NULL] && 
                            [scanner scanLocation] == location + 2) {
                            NSFont *font = [NSFont fontWithName:fontName size:fontSize];
                            if (font == nil) {
                                fontName = [[NSUserDefaults standardUserDefaults] stringForKey:SKTextNoteFontNameKey];
                                font = [NSFont fontWithName:fontName size:fontSize];
                            }
                            if (font)
                                [dictionary setObject:font forKey:@"font"];
                        }
                    }
                }
            }
        }
    }
    
    NSString *type = [dictionary objectForKey:@"type"];
    NSString *contents;
    if ([type isEqualToString:@"Note"]) {
        if (contents = [dictionary objectForKey:@"contents"]) {
            unsigned contentsEnd, end;
            [contents getLineStart:NULL end:&end contentsEnd:&contentsEnd forRange:NSMakeRange(0, 0)];
            if (end < [contents length]) {
                [dictionary setObject:[contents substringToIndex:contentsEnd] forKey:@"contents"];
                [dictionary setObject:[[[NSAttributedString alloc] initWithString:[contents substringFromIndex:end]] autorelease] forKey:@"text"];
            }
        }
    }
    
    return success ? dictionary : nil;
}

@end

#pragma mark -

@implementation NSScanner (SKFDFParserExtensions)

- (BOOL)scanFDFObject:(id *)object {
    id tmpObject = nil;
    BOOL success = YES;
    
    do {
        success = [self scanFDFName:&tmpObject] || 
                  [self scanFDFArray:&tmpObject] || 
                  [self scanFDFDictionary:&tmpObject] || 
                  [self scanFDFString:&tmpObject] || 
                  [self scanFDFHexString:&tmpObject] || 
                  [self scanFDFIndirectObject:&tmpObject] || 
                  [self scanFDFNumber:&tmpObject] || 
                  [self scanFDFBoolean:&tmpObject] || 
                  [self scanString:@"null" intoString:NULL];
    } while (success == NO && [self isAtEnd] == NO && [self scanFDFComment:NULL]);
    
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
        while ([self scanFDFComment:NULL]);
        if ([self peekCharacter:&ch] == NO) {
            success = NO;
            break;
        }
        if (ch == ']') {
            [self scanCharacter:NULL];
            break;
        } else if (success = [self scanFDFObject:&object]) {
           if (object)
                [tmpArray addObject:object];
        }
    }
    
    if (success && array)
        *array = tmpArray;
    
    return success;
}

- (BOOL)scanFDFDictionary:(NSDictionary **)dictionary {
    NSMutableDictionary *tmpDict = [NSMutableDictionary dictionary];
    NSString *key;
    id object;
    BOOL success = [self scanString:@"<<" intoString:NULL];
    
    while (success) {
        while ([self scanFDFComment:NULL]);
        if ([self scanFDFName:&key]) {
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
    BOOL success;
    
    if (success = [self scanString:@"(" intoString:NULL]) {
        NSCharacterSet *skipChars = [[self charactersToBeSkipped] retain];
        [self setCharactersToBeSkipped:nil];
        
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
        
        [self setCharactersToBeSkipped:skipChars];
        [skipChars release];
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
        whitespaceOrDelimiterCharSet = [tmpSet copy];
        [tmpSet release];
    }
    
    BOOL success;
    
    if (success = [self scanString:@"/" intoString:NULL]) {
        NSCharacterSet *skipChars = [[self charactersToBeSkipped] retain];
        [self setCharactersToBeSkipped:nil];
        success =  [self scanUpToCharactersFromSet:whitespaceOrDelimiterCharSet intoString:string];
        [self setCharactersToBeSkipped:skipChars];
        [skipChars release];
    }
    
    return  success;
}

- (BOOL)scanFDFNumber:(NSNumber **)number {
    float f;
    BOOL success = [self scanFloat:&f];
    
    if (success && number)
        *number = [NSNumber numberWithFloat:f];
    
    return success;
}

- (BOOL)scanFDFBoolean:(id *)boolNumber {
    NSNumber *tmpBoolNumber = nil;
    BOOL success;
    
    if (success = [self scanString:@"true" intoString:NULL])
        tmpBoolNumber = [NSNumber numberWithBool:YES];
    else if (success = [self scanString:@"false" intoString:NULL])
        tmpBoolNumber = [NSNumber numberWithBool:NO];
    
    if (success && boolNumber)
        *boolNumber = tmpBoolNumber;
    
    return success;
}

- (BOOL)scanFDFIndirectObject:(id *)object {
    int rewindLoc = [self scanLocation];
    id tmpObject;
    int objNumber, genNumber;
    BOOL success;
    
    if (success = [self scanInt:&objNumber] && [self scanInt:&genNumber] && [self scanString:@"R" intoString:NULL]) {
        tmpObject = [SKIndirectObject indirectObjectWithNumber:objNumber generation:genNumber];
    } else {
        [self setScanLocation:rewindLoc];
    }
    
    if (success && object)
        *object = tmpObject;
    
    return success;
}

- (BOOL)scanFDFComment:(NSString **)comment {
    NSString *tmpComment = @"";
    BOOL success;
    
    if (success = [self scanString:@"%" intoString:NULL]) {
        NSCharacterSet *skipChars = [[self charactersToBeSkipped] retain];
        [self setCharactersToBeSkipped:[NSCharacterSet whitespaceCharacterSet]];
        [self scanUpToCharactersFromSet:[NSCharacterSet newlineCharacterSet] intoString:&tmpComment];
        [self setCharactersToBeSkipped:skipChars];
        [skipChars release];
    }
    
    if (success && comment)
        *comment = tmpComment;
        
    return  success;
}

@end

#pragma mark -

@implementation SKIndirectObject : NSObject

+ (id)indirectObjectWithNumber:(unsigned int)objNumber generation:(unsigned int)genNumber {
    return [[[self alloc] initWithNumber:objNumber generation:genNumber] autorelease];
}

- (id)initWithNumber:(unsigned int)objNumber generation:(unsigned int)genNumber {
    if (self = [super init]) {
        objectNumber = objNumber;
        generationNumber = genNumber;
    }
    return self;
}

- (id)copyWithZone:(NSZone *)aZone {
    return [self retain];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: %i %i>",[self class], objectNumber, generationNumber];
}

- (BOOL)isEqual:(id)other {
    return [self isMemberOfClass:[other class]] && [self objectNumber] == [other objectNumber] && [self generationNumber] == [other generationNumber];
}

- (unsigned int)hash {
    return (objectNumber << 16) | generationNumber;
}

- (unsigned int)objectNumber {
    return objectNumber;
}

- (unsigned int)generationNumber {
    return generationNumber;
}

@end
