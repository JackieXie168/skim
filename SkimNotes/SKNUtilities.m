//
//  SKNUtilities.m
//  SkimNotes
//
//  Created by Christiaan Hofman on 7/17/08.
/*
 This software is Copyright (c) 2008-2020
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

#import "SKNUtilities.h"
#import <AppKit/AppKit.h>

#define NOTE_PAGE_INDEX_KEY @"pageIndex"
#define NOTE_TYPE_KEY @"type"
#define NOTE_CONTENTS_KEY @"contents"
#define NOTE_COLOR_KEY @"color"
#define NOTE_INTERIOR_COLOR_KEY @"interiorColor"
#define NOTE_FONT_COLOR_KEY @"fontColor"
#define NOTE_FONT_KEY @"font"
#define NOTE_FONT_NAME_KEY @"fontName"
#define NOTE_FONT_SIZE_KEY @"fontSize"
#define NOTE_TEXT_KEY @"text"
#define NOTE_IMAGE_KEY @"image"

#define NOTE_WIDGET_TYPE @"Widget"

NSString *SKNSkimTextNotes(NSArray *noteDicts) {
    NSMutableString *textString = [NSMutableString string];
    NSEnumerator *dictEnum = [noteDicts objectEnumerator];
    NSDictionary *dict;
    
    while (dict = [dictEnum nextObject]) {
        NSString *type = [dict objectForKey:NOTE_TYPE_KEY];
        
        if ([type isEqualToString:NOTE_WIDGET_TYPE])
            continue;
        
        NSUInteger pageIndex = [[dict objectForKey:NOTE_PAGE_INDEX_KEY] unsignedIntegerValue];
        NSString *string = [dict objectForKey:NOTE_CONTENTS_KEY];
        NSAttributedString *text = [dict objectForKey:NOTE_TEXT_KEY];
        
        if (pageIndex == NSNotFound || pageIndex == INT_MAX)
            pageIndex = 0;
        
        if ([text isKindOfClass:[NSData class]])
            text = [[[NSAttributedString alloc] initWithData:(NSData *)text options:[NSDictionary dictionary] documentAttributes:NULL error:NULL] autorelease];
        
        [textString appendFormat:@"* %@, page %lu\n\n", type, (long)pageIndex + 1];
        if ([string length]) {
            [textString appendString:string];
            [textString appendString:@" \n\n"];
        }
        if ([text length]) {
            [textString appendString:[text string]];
            [textString appendString:@" \n\n"];
        }
    }
    return textString;
}

NSData *SKNSkimRTFNotes(NSArray *noteDicts) {
    NSMutableAttributedString *attrString = [[[NSMutableAttributedString alloc] init] autorelease];
    NSEnumerator *dictEnum = [noteDicts objectEnumerator];
    NSDictionary *dict;
    
    while (dict = [dictEnum nextObject]) {
        NSString *type = [dict objectForKey:NOTE_TYPE_KEY];
        
        if ([type isEqualToString:NOTE_WIDGET_TYPE])
            continue;
        
        NSUInteger pageIndex = [[dict objectForKey:NOTE_PAGE_INDEX_KEY] unsignedIntegerValue];
        NSString *string = [dict objectForKey:NOTE_CONTENTS_KEY];
        NSAttributedString *text = [dict objectForKey:NOTE_TEXT_KEY];
        
        if (pageIndex == NSNotFound || pageIndex == INT_MAX)
            pageIndex = 0;
        
        if ([text isKindOfClass:[NSData class]])
            text = [[[NSAttributedString alloc] initWithData:(NSData *)text options:[NSDictionary dictionary] documentAttributes:NULL error:NULL] autorelease];
        
        [attrString replaceCharactersInRange:NSMakeRange([attrString length], 0) withString:[NSString stringWithFormat:@"* %@, page %lu\n\n", type, (long)pageIndex + 1]];
        if ([string length]) {
            [attrString replaceCharactersInRange:NSMakeRange([attrString length], 0) withString:string];
            [attrString replaceCharactersInRange:NSMakeRange([attrString length], 0) withString:@" \n\n"];
        }
        if ([text length]) {
            [attrString appendAttributedString:text];
            [attrString replaceCharactersInRange:NSMakeRange([attrString length], 0) withString:@" \n\n"];
            
        }
    }
    [attrString fixAttributesInRange:NSMakeRange(0, [attrString length])];
    return [attrString RTFFromRange:NSMakeRange(0, [attrString length]) documentAttributes:[NSDictionary dictionaryWithObjectsAndKeys:NSRTFTextDocumentType, NSDocumentTypeDocumentAttribute, nil]];
}

#pragma mark -

static inline BOOL SKNIsNumberArray(id array) {
    if ([array isKindOfClass:[NSArray class]] == NO)
        return NO;
    for (id object in array) {
        if ([object isKindOfClass:[NSNumber class]] == NO)
            return NO;
    }
    return YES;
}

static NSArray *SKNCreateArrayFromColor(NSColor *color, NSMapTable **colors) {
    if ([color isKindOfClass:[NSColor class]]) {
        NSArray *array = [*colors objectForKey:color];
        if (array == nil) {
            CGFloat r = 0.0, g = 0.0, b = 0.0, a = 1.0;
            [[color colorUsingColorSpace:[NSColorSpace sRGBColorSpace]] getRed:&r green:&g blue:&b alpha:&a];
            array = [[NSArray alloc] initWithObjects:[NSNumber numberWithDouble:r], [NSNumber numberWithDouble:g], [NSNumber numberWithDouble:b], [NSNumber numberWithDouble:a], nil];
            if (colors == NULL)
                *colors = [[NSMapTable alloc] initWithKeyOptions:NSPointerFunctionsStrongMemory | NSPointerFunctionsObjectPersonality valueOptions:NSPointerFunctionsStrongMemory | NSPointerFunctionsObjectPersonality capacity:0];
            [*colors setObject:array forKey:color];
        } else {
            [array retain];
        }
        return array;
    } else if (SKNIsNumberArray(color)) {
        return [(NSArray *)color retain];
    } else {
        return nil;
    }
}

static NSColor *SKNColorFromArray(NSArray *array) {
    if (SKNIsNumberArray(array)) {
        CGFloat c[4] = {0.0, 0.0, 0.0, 1.0};
        if ([array count] > 2) {
            NSUInteger i;
            for (i = 0; i < MAX([array count], 4); i++)
                c[i] = [[array objectAtIndex:i] doubleValue];
        } else if ([array count] > 0) {
            c[0] = c[1] = c[2] = [[array objectAtIndex:0] doubleValue];
            if ([array count] == 2)
                c[3] = [[array objectAtIndex:1] doubleValue];
        }
        return [NSColor colorWithColorSpace:[NSColorSpace sRGBColorSpace] components:c count:4];
    } else if ([array isKindOfClass:[NSColor class]]) {
        return (NSColor *)array;
    } else {
        return nil;
    }
}

NSArray *SKNSkimNotesFromData(NSData *data) {
    NSArray *noteDicts = nil;
    
    if ([data length]) {
        @try { noteDicts = [NSKeyedUnarchiver unarchiveObjectWithData:data]; }
        @catch (id e) {}
        if (noteDicts == nil) {
            noteDicts = [NSPropertyListSerialization propertyListFromData:data mutabilityOption:NSPropertyListMutableContainers format:NULL errorDescription:NULL];
            if ([noteDicts isKindOfClass:[NSArray class]]) {
                for (NSMutableDictionary *dict in noteDicts) {
                    id value;
                    if ((value = [dict objectForKey:NOTE_COLOR_KEY])) {
                        value = SKNColorFromArray(value);
                        [dict setObject:value forKey:NOTE_COLOR_KEY];
                    }
                    if ((value = [dict objectForKey:NOTE_INTERIOR_COLOR_KEY])) {
                        value = SKNColorFromArray(value);
                        [dict setObject:value forKey:NOTE_INTERIOR_COLOR_KEY];
                    }
                    if ((value = [dict objectForKey:NOTE_FONT_COLOR_KEY])) {
                        value = SKNColorFromArray(value);
                        [dict setObject:value forKey:NOTE_FONT_COLOR_KEY];
                    }
                    if ((value = [dict objectForKey:NOTE_FONT_NAME_KEY])) {
                        NSNumber *fontSize = [dict objectForKey:NOTE_FONT_SIZE_KEY];
                        if ([value isKindOfClass:[NSString class]]) {
                            CGFloat pointSize = [fontSize isKindOfClass:[NSNumber class]] ? [fontSize doubleValue] : 0.0;
                            value = [NSFont fontWithName:value size:pointSize] ?: [NSFont userFontOfSize:pointSize];
                            [dict setObject:value forKey:NOTE_FONT_KEY];
                        }
                        [dict removeObjectForKey:NOTE_FONT_NAME_KEY];
                        [dict removeObjectForKey:NOTE_FONT_SIZE_KEY];
                    }
                    if ((value = [dict objectForKey:NOTE_TEXT_KEY])) {
                        if ([value isKindOfClass:[NSData class]]) {
                            value = [[NSAttributedString alloc] initWithData:value options:[NSDictionary dictionary] documentAttributes:NULL error:NULL];
                            if (value) {
                                [dict setObject:value forKey:NOTE_TEXT_KEY];
                                [value release];
                            } else {
                                [dict removeObjectForKey:NOTE_TEXT_KEY];
                            }
                        } else if ([value isKindOfClass:[NSAttributedString class]] == NO) {
                            [dict removeObjectForKey:NOTE_TEXT_KEY];
                        }
                    }
                    if ((value = [dict objectForKey:NOTE_IMAGE_KEY])) {
                        if ([value isKindOfClass:[NSData class]]) {
                            value = [[NSImage alloc] initWithData:value];
                            [dict setObject:value forKey:NOTE_IMAGE_KEY];
                            [value release];
                        } else if ([value isKindOfClass:[NSImage class]] == NO) {
                            [dict removeObjectForKey:NOTE_IMAGE_KEY];
                        }
                    }
                }
            }
        }
        if ([noteDicts isKindOfClass:[NSArray class]] == NO) {
            noteDicts = nil;
        }
    } else if (data) {
        noteDicts = [NSArray array];
    }
    return noteDicts;
}

NSData *SKNDataFromSkimNotes(NSArray *noteDicts, BOOL asPlist) {
    NSData *data = nil;
    if (noteDicts) {
        if (asPlist) {
            NSMutableArray *array = [[NSMutableArray alloc] init];
            NSMapTable *colors = nil;
            for (NSDictionary *noteDict in noteDicts) {
                NSMutableDictionary *dict = [noteDict mutableCopy];
                id value;
                if ((value = [dict objectForKey:NOTE_COLOR_KEY])) {
                    value = SKNCreateArrayFromColor(value, &colors);
                    [dict setObject:value forKey:NOTE_COLOR_KEY];
                    [value release];
                }
                if ((value = [dict objectForKey:NOTE_INTERIOR_COLOR_KEY])) {
                    value = SKNCreateArrayFromColor(value, &colors);
                    [dict setObject:value forKey:NOTE_INTERIOR_COLOR_KEY];
                    [value release];
                }
                if ((value = [dict objectForKey:NOTE_FONT_COLOR_KEY])) {
                    value = SKNCreateArrayFromColor(value, &colors);
                    [dict setObject:value forKey:NOTE_FONT_COLOR_KEY];
                    [value release];
                }
                if ((value = [dict objectForKey:NOTE_FONT_KEY])) {
                    if ([value isKindOfClass:[NSFont class]]) {
                        [dict setObject:[value fontName] forKey:NOTE_FONT_NAME_KEY];
                        [dict setObject:[NSNumber numberWithDouble:[value pointSize]] forKey:NOTE_FONT_SIZE_KEY];
                    }
                    [dict removeObjectForKey:NOTE_FONT_KEY];
                }
                if ((value = [dict objectForKey:NOTE_TEXT_KEY])) {
                    if ([value isKindOfClass:[NSAttributedString class]]) {
                        if ([value containsAttachments]) {
                            value = [value RTFDFromRange:NSMakeRange(0, [value length]) documentAttributes:[NSDictionary dictionary]];
                        } else {
                            value = [value RTFFromRange:NSMakeRange(0, [value length]) documentAttributes:[NSDictionary dictionary]];
                        }
                        [dict setObject:value forKey:NOTE_TEXT_KEY];
                    } else if ([value isKindOfClass:[NSData class]] == NO) {
                        [dict removeObjectForKey:NOTE_TEXT_KEY];
                    }
                }
                if ((value = [dict objectForKey:NOTE_IMAGE_KEY])) {
                    if ([value isKindOfClass:[NSImage class]]) {
                        id imageRep = [[value representations] count] == 1 ? [[value representations] objectAtIndex:0] : nil;
                        if ([imageRep isKindOfClass:[NSPDFImageRep class]]) {
                            value = [imageRep PDFRepresentation];
                        } else if ([imageRep isKindOfClass:[NSEPSImageRep class]]) {
                            value = [imageRep EPSRepresentation];
                        } else {
                            value = [value TIFFRepresentation];
                        }
                        [dict setObject:value forKey:NOTE_IMAGE_KEY];
                        [value release];
                    } else if ([value isKindOfClass:[NSData class]] == NO) {
                        [dict removeObjectForKey:NOTE_IMAGE_KEY];
                    }
                }
                [array addObject:dict];
                [dict release];
            }
            data = [NSPropertyListSerialization dataFromPropertyList:array format:NSPropertyListBinaryFormat_v1_0 errorDescription:NULL];
            [array release];
            [colors release];
        } else {
            data = [NSKeyedArchiver archivedDataWithRootObject:noteDicts];
        }
    }
    return data;
}
