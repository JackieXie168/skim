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
#import "NSGeometry_SKExtensions.h"
#import "SKStringConstants.h"


@interface SKFDFParser (SKPrivate)
+ (NSDictionary *)noteDictionaryFromPDFDictionary:(CGPDFDictionaryRef)annot;
@end


@implementation SKFDFParser

static const void *getNSDataBytePointer(void *info) { return [(NSData *)info bytes]; }

+ (NSArray *)noteDictionariesFromFDFData:(NSData *)data {
    const char *pdfHeader = "%PDF";
    unsigned pdfHeaderLength = strlen(pdfHeader);
    
    if ([data length] < pdfHeaderLength)
        return NO;
    
    NSMutableData *pdfData = [data mutableCopy];
    
    [pdfData replaceBytesInRange:NSMakeRange(0, pdfHeaderLength) withBytes:pdfHeader length:pdfHeaderLength];

    static const CGDataProviderDirectAccessCallbacks callbacks = {&getNSDataBytePointer, NULL, NULL, NULL};
    CGDataProviderRef provider = CGDataProviderCreateDirectAccess((void *)pdfData, [pdfData length], &callbacks);
    CGPDFDocumentRef document = CGPDFDocumentCreateWithProvider(provider);
    NSMutableArray *notes = nil;
    
    if (document) {
        CGPDFDictionaryRef catalog = CGPDFDocumentGetCatalog(document);
        CGPDFDictionaryRef fdfDict;
        CGPDFArrayRef annots;
        
        if (catalog &&
            CGPDFDictionaryGetDictionary(catalog, "FDF", &fdfDict) &&
            CGPDFDictionaryGetArray(fdfDict, "Annots", &annots)) {
            
            size_t i, count = CGPDFArrayGetCount(annots);
            notes = [NSMutableArray arrayWithCapacity:count];
            for (i = 0; i < count; i++) {
                CGPDFDictionaryRef annot;
                NSDictionary *note;
                if (CGPDFArrayGetDictionary(annots, i, &annot) && 
                    (note = [self noteDictionaryFromPDFDictionary:annot])) {
                    [notes addObject:note];
                }
            }
        }
        
        CGPDFDocumentRelease(document);
    }
    
    if (provider)
        CGDataProviderRelease(provider);
    [pdfData release];
    
    return notes;
}

+ (NSDictionary *)noteDictionaryFromPDFDictionary:(CGPDFDictionaryRef)annot {
    if (annot == NULL)
        return nil;
    
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    CGPDFDictionaryRef dict;
    CGPDFArrayRef array;
    CGPDFStringRef string;
    const char *name;
    CGPDFReal real;
    CGPDFInteger integer;
    BOOL success = YES;
    NSRect bounds = NSZeroRect;
    
    if (CGPDFDictionaryGetName(annot, "Type", &name) == NO || strcmp(name, "Annot") != 0) {
        success = NO;
    }
    
    if (CGPDFDictionaryGetName(annot, "Subtype", &name)) {
        [dictionary setObject:[NSString stringWithFormat:@"%s", name] forKey:@"type"];
    } else {
        success = NO;
    }
    
    if (CGPDFDictionaryGetArray(annot, "Rect", &array)) {
        CGPDFReal l, b, r, t;
        if (CGPDFArrayGetCount(array) == 4 && CGPDFArrayGetNumber(array, 0, &l) && CGPDFArrayGetNumber(array, 1, &b) && CGPDFArrayGetNumber(array, 2, &r) && CGPDFArrayGetNumber(array, 3, &t)) {
            bounds = NSMakeRect(l, b, r - l, t - b);
            [dictionary setObject:NSStringFromRect(bounds) forKey:@"bounds"];
        }
    } else {
        success = NO;
    }
    
    if (CGPDFDictionaryGetInteger(annot, "Page", &integer)) {
        [dictionary setObject:[NSNumber numberWithInt:integer] forKey:@"pageIndex"];
    } else {
        success = NO;
    }
    
    if (CGPDFDictionaryGetString(annot, "Contents", &string)) {
        NSString *contents = (NSString *)CGPDFStringCopyTextString(string);
        if (contents)
            [dictionary setObject:contents forKey:@"contents"];
        [contents release];
    }
    
    if (CGPDFDictionaryGetArray(annot, "C", &array)) {
        CGPDFReal r, g, b;
        if (CGPDFArrayGetCount(array) == 3 && CGPDFArrayGetNumber(array, 0, &r) && CGPDFArrayGetNumber(array, 1, &g) && CGPDFArrayGetNumber(array, 2, &b)) {
            [dictionary setObject:[NSColor colorWithCalibratedRed:r green:g blue:b alpha:1.0] forKey:@"color"];
        }
    }
    
    if (CGPDFDictionaryGetArray(annot, "IC", &array)) {
        CGPDFReal r, g, b;
        if (CGPDFArrayGetCount(array) == 3 && CGPDFArrayGetNumber(array, 0, &r) && CGPDFArrayGetNumber(array, 1, &g) && CGPDFArrayGetNumber(array, 2, &b)) {
            [dictionary setObject:[NSColor colorWithCalibratedRed:r green:g blue:b alpha:1.0] forKey:@"interiorColor"];
        }
    }
    
    if (CGPDFDictionaryGetDictionary(annot, "BS", &dict)) {
        if (CGPDFDictionaryGetNumber(dict, "W", &real)) {
            if (real > 0.0) {
                [dictionary setObject:[NSNumber numberWithFloat:real] forKey:@"lineWidth"];
                if (CGPDFDictionaryGetName(dict, "S", &name)) {
                    int style = kPDFBorderStyleSolid;
                    if (strcmp(name, "S") == 0)
                        style = kPDFBorderStyleSolid;
                    else if (strcmp(name, "D") == 0)
                        style = kPDFBorderStyleDashed;
                    else if (strcmp(name, "B") == 0)
                        style = kPDFBorderStyleBeveled;
                    else if (strcmp(name, "I") == 0)
                        style = kPDFBorderStyleInset;
                    else if (strcmp(name, "U") == 0)
                        style = kPDFBorderStyleUnderline;
                    [dictionary setObject:[NSNumber numberWithInt:style] forKey:@"borderStyle"];
                }
                if (CGPDFDictionaryGetArray(annot, "D", &array)) {
                    size_t i, count = CGPDFArrayGetCount(array);
                    NSMutableArray *dp = [NSMutableArray array];
                    for (i = 0; i < count; i++) {
                        if (CGPDFArrayGetNumber(array, i, &real))
                            [dp addObject:[NSNumber numberWithFloat:real]];
                    }
                    [dictionary setObject:dp forKey:@"dashPattern"];
                }
            }
        }
    } else if (CGPDFDictionaryGetArray(annot, "Border", &array)) {
        size_t i, count = CGPDFArrayGetCount(array);
        if (count > 2 && CGPDFArrayGetNumber(array, 2, &real) && real > 0.0) {
            [dictionary setObject:[NSNumber numberWithFloat:real] forKey:@"lineWidth"];
            CGPDFArrayRef dp;
            if (count > 3 && CGPDFArrayGetArray(array, 3, &dp)) {
                count = CGPDFArrayGetCount(dp);
                NSMutableArray *dashPattern = [NSMutableArray arrayWithCapacity:count];
                for (i = 0; i < count; i++) {
                    if (CGPDFArrayGetNumber(dp, i, &real))
                        [dashPattern addObject:[NSNumber numberWithFloat:real]];
                }
                [dictionary setObject:dashPattern forKey:@"dashPattern"];
                [dictionary setObject:[NSNumber numberWithInt:kPDFBorderStyleDashed] forKey:@"borderStyle"];
            } else {
                 [dictionary setObject:[NSNumber numberWithInt:kPDFBorderStyleSolid] forKey:@"borderStyle"];
            }
        }
    } else {
        [dictionary setObject:[NSNumber numberWithFloat:1.0] forKey:@"lineWidth"];
        [dictionary setObject:[NSNumber numberWithInt:kPDFBorderStyleSolid] forKey:@"borderStyle"];
    }
    
    if (CGPDFDictionaryGetName(annot, "Name", &name)) {
        int icon = kPDFTextAnnotationIconNote;
        if (strcmp(name, "Comment") == 0)
            icon = kPDFTextAnnotationIconComment;
        else if (strcmp(name, "Key") == 0)
            icon = kPDFTextAnnotationIconKey;
        else if (strcmp(name, "Note") == 0)
            icon = kPDFTextAnnotationIconNote;
        else if (strcmp(name, "NewParagraph") == 0)
            icon = kPDFTextAnnotationIconNewParagraph;
        else if (strcmp(name, "Paragraph") == 0)
            icon = kPDFTextAnnotationIconParagraph;
        else if (strcmp(name, "Insert") == 0)
            icon = kPDFTextAnnotationIconInsert;
        [dictionary setObject:[NSNumber numberWithInt:icon] forKey:@"iconType"];
    }
    
    if (CGPDFDictionaryGetArray(annot, "LE", &array)) {
        int startStyle = kPDFLineStyleNone;
        int endStyle = kPDFLineStyleNone;
        if (CGPDFArrayGetCount(array) == 2) {
            if (CGPDFArrayGetName(array, 0, &name)) {
                if (strcmp(name, "None") == 0)
                    startStyle = kPDFLineStyleNone;
                else if (strcmp(name, "Square") == 0)
                    startStyle = kPDFLineStyleSquare;
                else if (strcmp(name, "Circle") == 0)
                    startStyle = kPDFLineStyleCircle;
                else if (strcmp(name, "Diamond") == 0)
                    startStyle = kPDFLineStyleDiamond;
                else if (strcmp(name, "OpenArrow") == 0)
                    startStyle = kPDFLineStyleOpenArrow;
                else if (strcmp(name, "ClosedArrow") == 0)
                    startStyle = kPDFLineStyleClosedArrow;
            }
            if (CGPDFArrayGetName(array, 1, &name)) {
                if (strcmp(name, "None") == 0)
                    startStyle = kPDFLineStyleNone;
                else if (strcmp(name, "Square") == 0)
                    endStyle = kPDFLineStyleSquare;
                else if (strcmp(name, "Circle") == 0)
                    endStyle = kPDFLineStyleCircle;
                else if (strcmp(name, "Diamond") == 0)
                    endStyle = kPDFLineStyleDiamond;
                else if (strcmp(name, "OpenArrow") == 0)
                    endStyle = kPDFLineStyleOpenArrow;
                else if (strcmp(name, "ClosedArrow") == 0)
                    endStyle = kPDFLineStyleClosedArrow;
            }
        }
        [dictionary setObject:[NSNumber numberWithInt:endStyle] forKey:@"endLineStyle"];
        [dictionary setObject:[NSNumber numberWithInt:startStyle] forKey:@"startLineStyle"];
    }
    
    if (CGPDFDictionaryGetArray(annot, "QuadPoints", &array)) {
        size_t i, count = CGPDFArrayGetCount(array);
        if (count % 8 == 0) {
            NSMutableArray *quadPoints = [NSMutableArray arrayWithCapacity:count / 2];
            for (i = 0; i < count; i++) {
                NSPoint point;
                if (CGPDFArrayGetNumber(array, i, &point.x) && CGPDFArrayGetNumber(array, ++i, &point.y))
                    [quadPoints addObject:NSStringFromPoint(SKSubstractPoints(point, bounds.origin))];
            }
            [dictionary setObject:quadPoints forKey:@"quadrilateralPoints"];
        }
    }
    
    if (CGPDFDictionaryGetString(annot, "DA", &string)) {
        NSString *da = (NSString *)CGPDFStringCopyTextString(string);
        if (da) {
            NSScanner *scanner = [NSScanner scannerWithString:da];
            NSString *fontName;
            float fontSize;
            if ([scanner scanUpToString:@"Tf" intoString:NULL] && [scanner isAtEnd] == NO) {
                unsigned location = [scanner scanLocation];
                NSRange r = [da rangeOfString:@"/" options:NSBackwardsSearch range:NSMakeRange(0, location)];
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
           [da release];
       }
    }
    
    NSSet *validTypes = [NSSet setWithObjects:@"FreeText", @"Note", @"Circle", @"Square", @"Highlight", @"Underline", @"StrikeOut", @"Line", nil];
    NSString *type = [dictionary objectForKey:@"type"];
    NSString *contents;
    if ([type isEqualToString:@"Text"]) {
        [dictionary setObject:@"Note" forKey:@"type"];
        if (contents = [dictionary objectForKey:@"contents"]) {
            unsigned contentsEnd, end;
            [contents getLineStart:NULL end:&end contentsEnd:&contentsEnd forRange:NSMakeRange(0, 0)];
            if (contentsEnd < end) {
                [dictionary setObject:[contents substringToIndex:contentsEnd] forKey:@"contents"];
                if (end < [contents length])
                    [dictionary setObject:[[[NSAttributedString alloc] initWithString:[contents substringFromIndex:end]] autorelease] forKey:@"text"];
            }
        }
    } else if ([validTypes containsObject:type] == NO) {
        success = NO;
    }
    
    return success ? dictionary : nil;
}

@end
