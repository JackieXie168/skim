//
//  SKFDFParser.m
//  Skim
//
//  Created by Christiaan Hofman on 9/6/07.
/*
 This software is Copyright (c) 2007-2014
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
#import <ApplicationServices/ApplicationServices.h>
#import "NSScanner_SKExtensions.h"
#import "NSGeometry_SKExtensions.h"
#import "SKStringConstants.h"
#import <SkimNotes/SkimNotes.h>
#import "SKNPDFAnnotationNote_SKExtensions.h"

SKFDFString SKFDFFDFKey = "FDF";
SKFDFString SKFDFAnnotationsKey = "Annots";
SKFDFString SKFDFFileKey = "F";
SKFDFString SKFDFFileIDKey = "ID";
SKFDFString SKFDFRootKey = "Root";

SKFDFString SKFDFTypeKey = "Type";

SKFDFString SKFDFAnnotationFlagsKey = "F";
SKFDFString SKFDFAnnotationTypeKey = "Subtype";
SKFDFString SKFDFAnnotationBoundsKey = "Rect";
SKFDFString SKFDFAnnotationPageIndexKey = "Page";
SKFDFString SKFDFAnnotationContentsKey = "Contents";
SKFDFString SKFDFAnnotationColorKey = "C";
SKFDFString SKFDFAnnotationInteriorColorKey = "IC";
SKFDFString SKFDFAnnotationBorderStylesKey = "BS";
SKFDFString SKFDFAnnotationLineWidthKey = "W";
SKFDFString SKFDFAnnotationDashPatternKey = "D";
SKFDFString SKFDFAnnotationBorderStyleKey = "S";
SKFDFString SKFDFAnnotationBorderKey = "Border";
SKFDFString SKFDFAnnotationModificationDateKey = "M";
SKFDFString SKFDFAnnotationUserNameKey = "T";
SKFDFString SKFDFAnnotationAlignmentKey = "Q";
SKFDFString SKFDFAnnotationIconTypeKey = "Name";
SKFDFString SKFDFAnnotationLineStylesKey = "LE";
SKFDFString SKFDFAnnotationLinePointsKey = "L";
SKFDFString SKFDFAnnotationInkListKey = "InkList";
SKFDFString SKFDFAnnotationQuadrilateralPointsKey = "QuadPoints";
SKFDFString SKFDFDefaultAppearanceKey = "DA";
SKFDFString SKFDFDefaultStyleKey = "DS";

SKFDFString SKFDFAnnotation = "Annot";

SKFDFString SKFDFBorderStyleSolid = "S";
SKFDFString SKFDFBorderStyleDashed = "D";
SKFDFString SKFDFBorderStyleBeveled = "B";
SKFDFString SKFDFBorderStyleInset = "I";
SKFDFString SKFDFBorderStyleUnderline = "U";

SKFDFString SKFDFTextAnnotationIconComment = "Comment";
SKFDFString SKFDFTextAnnotationIconKey = "Key";
SKFDFString SKFDFTextAnnotationIconNote = "Note";
SKFDFString SKFDFTextAnnotationIconNewParagraph = "NewParagraph";
SKFDFString SKFDFTextAnnotationIconParagraph = "Paragraph";
SKFDFString SKFDFTextAnnotationIconInsert = "Insert";

SKFDFString SKFDFLineStyleNone = "None";
SKFDFString SKFDFLineStyleSquare = "Square";
SKFDFString SKFDFLineStyleCircle = "Circle";
SKFDFString SKFDFLineStyleDiamond = "Diamond";
SKFDFString SKFDFLineStyleOpenArrow = "OpenArrow";
SKFDFString SKFDFLineStyleClosedArrow = "ClosedArrow";

static BOOL SKFDFEqualStrings(SKFDFString string1, SKFDFString string2) {
    return strcmp(string1, string2) == 0;
}

PDFBorderStyle SKPDFBorderStyleFromFDFBorderStyle(SKFDFString name) {
    if (SKFDFEqualStrings(name, SKFDFBorderStyleSolid))
        return kPDFBorderStyleSolid;
    else if (SKFDFEqualStrings(name, SKFDFBorderStyleDashed))
        return kPDFBorderStyleDashed;
    else if (SKFDFEqualStrings(name, SKFDFBorderStyleBeveled))
        return kPDFBorderStyleBeveled;
    else if (SKFDFEqualStrings(name, SKFDFBorderStyleInset))
        return kPDFBorderStyleInset;
    else if (SKFDFEqualStrings(name, SKFDFBorderStyleUnderline))
        return kPDFBorderStyleUnderline;
    else
        return kPDFBorderStyleSolid;
}

SKFDFString SKFDFBorderStyleFromPDFBorderStyle(PDFBorderStyle borderStyle) {
    switch (borderStyle) {
        case kPDFBorderStyleSolid: return SKFDFBorderStyleSolid;
        case kPDFBorderStyleDashed: return SKFDFBorderStyleDashed;
        case kPDFBorderStyleBeveled: return SKFDFBorderStyleBeveled;
        case kPDFBorderStyleInset: return SKFDFBorderStyleInset;
        case kPDFBorderStyleUnderline: return SKFDFBorderStyleUnderline;
        default: return SKFDFBorderStyleSolid;
    }
}

NSTextAlignment SKPDFFreeTextAnnotationAlignmentFromFDFFreeTextAnnotationAlignment(NSInteger anInt) {
    switch (anInt) {
        case 0: return NSLeftTextAlignment;
        case 1: return NSCenterTextAlignment;
        case 2: return NSRightTextAlignment;
        default: return NSLeftTextAlignment;
    }
}

NSInteger SKFDFFreeTextAnnotationAlignmentFromPDFFreeTextAnnotationAlignment(NSTextAlignment alignment) {
    switch (alignment) {
        case NSLeftTextAlignment: return 0;
        case NSRightTextAlignment: return 2;
        case NSCenterTextAlignment: return 1;
        default: return 0;
    }
}

PDFTextAnnotationIconType SKPDFTextAnnotationIconTypeFromFDFTextAnnotationIconType(SKFDFString name) {
    if (SKFDFEqualStrings(name, SKFDFTextAnnotationIconComment))
        return kPDFTextAnnotationIconComment;
    else if (SKFDFEqualStrings(name, SKFDFTextAnnotationIconKey))
        return kPDFTextAnnotationIconKey;
    else if (SKFDFEqualStrings(name, SKFDFTextAnnotationIconNote))
        return kPDFTextAnnotationIconNote;
    else if (SKFDFEqualStrings(name, SKFDFTextAnnotationIconNewParagraph))
        return kPDFTextAnnotationIconNewParagraph;
    else if (SKFDFEqualStrings(name, SKFDFTextAnnotationIconParagraph))
        return kPDFTextAnnotationIconParagraph;
    else if (SKFDFEqualStrings(name, SKFDFTextAnnotationIconInsert))
        return kPDFTextAnnotationIconInsert;
    else
        return kPDFTextAnnotationIconNote;
}

SKFDFString SKFDFTextAnnotationIconTypeFromPDFTextAnnotationIconType(PDFTextAnnotationIconType iconType) {
    switch (iconType) {
        case kPDFTextAnnotationIconComment: return SKFDFTextAnnotationIconComment;
        case kPDFTextAnnotationIconKey: return SKFDFTextAnnotationIconKey;
        case kPDFTextAnnotationIconNote: return SKFDFTextAnnotationIconNote;
        case kPDFTextAnnotationIconNewParagraph: return SKFDFTextAnnotationIconNewParagraph;
        case kPDFTextAnnotationIconParagraph: return SKFDFTextAnnotationIconParagraph;
        case kPDFTextAnnotationIconInsert: return SKFDFTextAnnotationIconInsert;
        default: return SKFDFTextAnnotationIconNote;
    }
}

PDFLineStyle SKPDFLineStyleFromFDFLineStyle(SKFDFString name) {
    if (SKFDFEqualStrings(name, SKFDFLineStyleNone))
        return kPDFLineStyleNone;
    else if (SKFDFEqualStrings(name, SKFDFLineStyleSquare))
        return kPDFLineStyleSquare;
    else if (SKFDFEqualStrings(name, SKFDFLineStyleCircle))
        return kPDFLineStyleCircle;
    else if (SKFDFEqualStrings(name, SKFDFLineStyleDiamond))
        return kPDFLineStyleDiamond;
    else if (SKFDFEqualStrings(name, SKFDFLineStyleOpenArrow))
        return kPDFLineStyleOpenArrow;
    else if (SKFDFEqualStrings(name, SKFDFLineStyleClosedArrow))
        return kPDFLineStyleClosedArrow;
    else
        return kPDFLineStyleNone;
}

SKFDFString SKFDFLineStyleFromPDFLineStyle(PDFLineStyle lineStyle) {
    switch (lineStyle) {
        case kPDFLineStyleNone: return SKFDFLineStyleNone;
        case kPDFLineStyleSquare: return SKFDFLineStyleSquare;
        case kPDFLineStyleCircle: return SKFDFLineStyleCircle;
        case kPDFLineStyleDiamond: return SKFDFLineStyleDiamond;
        case kPDFLineStyleOpenArrow: return SKFDFLineStyleOpenArrow;
        case kPDFLineStyleClosedArrow: return SKFDFLineStyleClosedArrow;
        default: return SKFDFLineStyleNone;
    }
}

NSString *SKFDFStringFromDate(NSDate *date) {
    if (date == nil) return nil;
    static NSDateFormatter *formatter = nil;
    if (formatter == nil) {
        formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"yyyyMMddHHmmssZZ"];
    }
    NSMutableString *dateString = [NSMutableString stringWithString:@"D:"];
    [dateString appendString:[formatter stringFromDate:date]];
    if ([dateString hasSuffix:@"+0000"]) {
        [dateString replaceCharactersInRange:NSMakeRange([dateString length] - 5, 5) withString:@"Z00'00'"];
    } else {
        [dateString insertString:@"'" atIndex:[dateString length] - 2];
        [dateString insertString:@"'" atIndex:[dateString length]];
    }
    return dateString;
}

@implementation SKFDFParser

+ (NSDictionary *)noteDictionaryFromPDFDictionary:(CGPDFDictionaryRef)annot {
    if (annot == NULL)
        return nil;
    
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    CGPDFDictionaryRef dict;
    CGPDFArrayRef array;
    CGPDFStringRef string;
    SKFDFString name;
    CGPDFReal real;
    CGPDFInteger integer;
    BOOL success = YES;
    NSRect bounds = NSZeroRect;
    
    if (CGPDFDictionaryGetName(annot, SKFDFTypeKey, &name) == NO || SKFDFEqualStrings(name, SKFDFAnnotation) == NO) {
        success = NO;
    }
    
    if (success && CGPDFDictionaryGetName(annot, SKFDFAnnotationTypeKey, &name)) {
        [dictionary setObject:[NSString stringWithFormat:@"%s", name] forKey:SKNPDFAnnotationTypeKey];
    } else {
        success = NO;
    }
    
    if (success && CGPDFDictionaryGetString(annot, SKFDFAnnotationContentsKey, &string)) {
        NSString *contents = (NSString *)CGPDFStringCopyTextString(string);
        if (contents)
            [dictionary setObject:contents forKey:SKNPDFAnnotationContentsKey];
        [contents release];
    }
    
    if (success && CGPDFDictionaryGetArray(annot, SKFDFAnnotationBoundsKey, &array)) {
        CGPDFReal l, b, r, t;
        if (CGPDFArrayGetCount(array) == 4 && CGPDFArrayGetNumber(array, 0, &l) && CGPDFArrayGetNumber(array, 1, &b) && CGPDFArrayGetNumber(array, 2, &r) && CGPDFArrayGetNumber(array, 3, &t)) {
            bounds = NSMakeRect(l, b, r - l, t - b);
            [dictionary setObject:NSStringFromRect(bounds) forKey:SKNPDFAnnotationBoundsKey];
        }
    } else {
        success = NO;
    }
    
    if (success) {
        NSSet *validTypes = [NSSet setWithObjects:SKNFreeTextString, SKNNoteString, SKNCircleString, SKNSquareString, SKNHighlightString, SKNUnderlineString, SKNStrikeOutString, SKNLineString, SKNInkString, nil];
        NSString *type = [dictionary objectForKey:SKNPDFAnnotationTypeKey];
        if ([type isEqualToString:SKNTextString]) {
            [dictionary setDictionary:[SKNPDFAnnotationNote textToNoteSkimNoteProperties:dictionary]];
        } else if ([validTypes containsObject:type] == NO) {
            success = NO;
        }
    }
    
    if (success && CGPDFDictionaryGetInteger(annot, SKFDFAnnotationPageIndexKey, &integer)) {
        [dictionary setObject:[NSNumber numberWithInteger:integer] forKey:SKNPDFAnnotationPageIndexKey];
    } else {
        success = NO;
    }
    
    if (success) {
        if (CGPDFDictionaryGetDictionary(annot, SKFDFAnnotationBorderStylesKey, &dict)) {
            if (CGPDFDictionaryGetNumber(dict, SKFDFAnnotationLineWidthKey, &real)) {
                if (real > 0.0) {
                    [dictionary setObject:[NSNumber numberWithDouble:real] forKey:SKNPDFAnnotationLineWidthKey];
                    if (CGPDFDictionaryGetName(dict, SKFDFAnnotationBorderStyleKey, &name)) {
                        [dictionary setObject:[NSNumber numberWithInteger:SKPDFBorderStyleFromFDFBorderStyle(name)] forKey:SKNPDFAnnotationBorderStyleKey];
                    }
                    if (CGPDFDictionaryGetArray(annot, SKFDFAnnotationDashPatternKey, &array)) {
                        size_t i, count = CGPDFArrayGetCount(array);
                        NSMutableArray *dp = [NSMutableArray array];
                        for (i = 0; i < count; i++) {
                            if (CGPDFArrayGetNumber(array, i, &real))
                                [dp addObject:[NSNumber numberWithDouble:real]];
                        }
                        [dictionary setObject:dp forKey:SKNPDFAnnotationDashPatternKey];
                    }
                }
            }
        } else if (CGPDFDictionaryGetArray(annot, SKFDFAnnotationBorderKey, &array)) {
            size_t i, count = CGPDFArrayGetCount(array);
            if (count > 2 && CGPDFArrayGetNumber(array, 2, &real) && real > 0.0) {
                [dictionary setObject:[NSNumber numberWithDouble:real] forKey:SKNPDFAnnotationLineWidthKey];
                CGPDFArrayRef dp;
                if (count > 3 && CGPDFArrayGetArray(array, 3, &dp)) {
                    count = CGPDFArrayGetCount(dp);
                    NSMutableArray *dashPattern = [NSMutableArray arrayWithCapacity:count];
                    for (i = 0; i < count; i++) {
                        if (CGPDFArrayGetNumber(dp, i, &real))
                            [dashPattern addObject:[NSNumber numberWithDouble:real]];
                    }
                    [dictionary setObject:dashPattern forKey:SKNPDFAnnotationDashPatternKey];
                    [dictionary setObject:[NSNumber numberWithInteger:kPDFBorderStyleDashed] forKey:SKNPDFAnnotationBorderStyleKey];
                } else {
                     [dictionary setObject:[NSNumber numberWithInteger:kPDFBorderStyleSolid] forKey:SKNPDFAnnotationBorderStyleKey];
                }
            }
        } else {
            [dictionary setObject:[NSNumber numberWithDouble:1.0] forKey:SKNPDFAnnotationLineWidthKey];
            [dictionary setObject:[NSNumber numberWithInteger:kPDFBorderStyleSolid] forKey:SKNPDFAnnotationBorderStyleKey];
        }
    }
    
    if (success && CGPDFDictionaryGetArray(annot, SKFDFAnnotationColorKey, &array)) {
        CGPDFReal r, g, b;
        if (CGPDFArrayGetCount(array) == 3 && CGPDFArrayGetNumber(array, 0, &r) && CGPDFArrayGetNumber(array, 1, &g) && CGPDFArrayGetNumber(array, 2, &b)) {
            [dictionary setObject:[NSColor colorWithCalibratedRed:r green:g blue:b alpha:1.0] forKey:SKNPDFAnnotationColorKey];
        }
    }
    
    if (success && CGPDFDictionaryGetArray(annot, SKFDFAnnotationInteriorColorKey, &array)) {
        CGPDFReal r, g, b;
        if (CGPDFArrayGetCount(array) == 3 && CGPDFArrayGetNumber(array, 0, &r) && CGPDFArrayGetNumber(array, 1, &g) && CGPDFArrayGetNumber(array, 2, &b)) {
            [dictionary setObject:[NSColor colorWithCalibratedRed:r green:g blue:b alpha:1.0] forKey:SKNPDFAnnotationInteriorColorKey];
        }
    }
    
    if (success && CGPDFDictionaryGetString(annot, SKFDFAnnotationModificationDateKey, &string)) {
        NSDate *date = (NSDate *)CGPDFStringCopyDate(string);
        if (date)
            [dictionary setObject:date forKey:SKNPDFAnnotationModificationDateKey];
        [date release];
    }
    
    if (success && CGPDFDictionaryGetString(annot, SKFDFAnnotationUserNameKey, &string)) {
        NSString *userName = (NSString *)CGPDFStringCopyTextString(string);
        if (userName)
            [dictionary setObject:userName forKey:SKNPDFAnnotationUserNameKey];
        [userName release];
    }
    
    if (success && CGPDFDictionaryGetInteger(annot, SKFDFAnnotationPageIndexKey, &integer)) {
        [dictionary setObject:[NSNumber numberWithInteger:SKPDFFreeTextAnnotationAlignmentFromFDFFreeTextAnnotationAlignment(integer)] forKey:SKNPDFAnnotationAlignmentKey];
    }
    
    if (success && CGPDFDictionaryGetName(annot, SKFDFAnnotationIconTypeKey, &name)) {
        [dictionary setObject:[NSNumber numberWithInteger:SKPDFTextAnnotationIconTypeFromFDFTextAnnotationIconType(name)] forKey:SKNPDFAnnotationIconTypeKey];
    }
    
    if (success && CGPDFDictionaryGetArray(annot, SKFDFAnnotationLineStylesKey, &array)) {
        NSInteger startStyle = kPDFLineStyleNone;
        NSInteger endStyle = kPDFLineStyleNone;
        if (CGPDFArrayGetCount(array) == 2) {
            if (CGPDFArrayGetName(array, 0, &name)) {
                startStyle = SKPDFLineStyleFromFDFLineStyle(name);
            }
            if (CGPDFArrayGetName(array, 1, &name)) {
                endStyle = SKPDFLineStyleFromFDFLineStyle(name);
            }
        }
        [dictionary setObject:[NSNumber numberWithInteger:endStyle] forKey:SKNPDFAnnotationEndLineStyleKey];
        [dictionary setObject:[NSNumber numberWithInteger:startStyle] forKey:SKNPDFAnnotationStartLineStyleKey];
    }
    
    if (success && CGPDFDictionaryGetArray(annot, SKFDFAnnotationLinePointsKey, &array)) {
        NSPoint p1, p2;
        if (CGPDFArrayGetCount(array) == 4 && CGPDFArrayGetNumber(array, 0, &p1.x) && CGPDFArrayGetNumber(array, 1, &p1.y) && CGPDFArrayGetNumber(array, 2, &p2.x) && CGPDFArrayGetNumber(array, 3, &p2.y)) {
            [dictionary setObject:NSStringFromPoint(SKSubstractPoints(p1, bounds.origin)) forKey:SKNPDFAnnotationStartPointKey];
            [dictionary setObject:NSStringFromPoint(SKSubstractPoints(p2, bounds.origin)) forKey:SKNPDFAnnotationEndPointKey];
        }
    }
    
    if (success && CGPDFDictionaryGetArray(annot, SKFDFAnnotationQuadrilateralPointsKey, &array)) {
        size_t i, count = CGPDFArrayGetCount(array);
        if (count % 8 == 0) {
            NSMutableArray *quadPoints = [NSMutableArray arrayWithCapacity:count / 2];
            for (i = 0; i < count; i++) {
                NSPoint point;
                if (CGPDFArrayGetNumber(array, i, &point.x) && CGPDFArrayGetNumber(array, ++i, &point.y))
                    [quadPoints addObject:NSStringFromPoint(SKSubstractPoints(point, bounds.origin))];
            }
            [dictionary setObject:quadPoints forKey:SKNPDFAnnotationQuadrilateralPointsKey];
        }
    }
    
    if (success && CGPDFDictionaryGetArray(annot, SKFDFAnnotationInkListKey, &array)) {
        size_t i, iMax = CGPDFArrayGetCount(array);
        NSMutableArray *pointLists = [NSMutableArray arrayWithCapacity:iMax];
        for (i = 0; i < iMax; i++) {
            CGPDFArrayRef subarray;
            if (CGPDFArrayGetArray(array, i, &subarray)) {
                size_t j, jMax = CGPDFArrayGetCount(subarray);
                if (jMax % 2 == 0) {
                    NSMutableArray *points = [NSMutableArray arrayWithCapacity:jMax / 2];
                    for (j = 0; j < jMax; j++) {
                        NSPoint point;
                        if (CGPDFArrayGetNumber(subarray, j, &point.x) && CGPDFArrayGetNumber(subarray, ++j, &point.y))
                            [points addObject:NSStringFromPoint(SKSubstractPoints(point, bounds.origin))];
                    }
                    [pointLists addObject:points];
                }
            }
        }
        [dictionary setObject:pointLists forKey:SKNPDFAnnotationPointListsKey];
    }
    
    if (success && CGPDFDictionaryGetString(annot, SKFDFDefaultAppearanceKey, &string)) {
        NSString *da = (NSString *)CGPDFStringCopyTextString(string);
        if (da) {
            NSScanner *scanner = [NSScanner scannerWithString:da];
            NSString *fontName;
            double fontSize;
            if ([scanner scanUpToString:@"Tf" intoString:NULL] && [scanner isAtEnd] == NO) {
                NSUInteger location = [scanner scanLocation];
                NSRange r = [da rangeOfString:@"/" options:NSBackwardsSearch range:NSMakeRange(0, location)];
                if (r.location != NSNotFound) {
                    [scanner setScanLocation:NSMaxRange(r)];
                    if ([scanner scanUpToCharactersFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet] intoString:&fontName] &&
                        [scanner scanDouble:&fontSize] &&
                        [scanner scanString:@"Tf" intoString:NULL] &&
                        [scanner scanLocation] == location + 2) {
                        NSFont *font = [NSFont fontWithName:fontName size:fontSize];
                        if (font == nil) {
                            fontName = [[NSUserDefaults standardUserDefaults] stringForKey:SKFreeTextNoteFontNameKey];
                            font = [NSFont fontWithName:fontName size:fontSize];
                        }
                        if (font)
                            [dictionary setObject:font forKey:SKNPDFAnnotationFontKey];
                   }
               }
           }
           [da release];
       }
    }
    
    return success ? dictionary : nil;
}

+ (NSArray *)noteDictionariesFromFDFData:(NSData *)data {
    const char *pdfHeader = "%PDF";
    NSUInteger pdfHeaderLength = strlen(pdfHeader);
    NSMutableArray *notes = nil;
    
    if ([data length] > pdfHeaderLength) {
        
        NSMutableData *pdfData = [data mutableCopy];
        
        [pdfData replaceBytesInRange:NSMakeRange(0, pdfHeaderLength) withBytes:pdfHeader length:pdfHeaderLength];

        CGDataProviderRef provider = CGDataProviderCreateWithCFData((CFDataRef)pdfData);
        CGPDFDocumentRef document = CGPDFDocumentCreateWithProvider(provider);
        
        if (document) {
            CGPDFDictionaryRef catalog = CGPDFDocumentGetCatalog(document);
            CGPDFDictionaryRef fdfDict;
            CGPDFArrayRef annots;
            
            if (catalog &&
                CGPDFDictionaryGetDictionary(catalog, SKFDFFDFKey, &fdfDict) &&
                CGPDFDictionaryGetArray(fdfDict, SKFDFAnnotationsKey, &annots)) {
                
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
        
        CGDataProviderRelease(provider);
        [pdfData release];
    }
    
    return notes;
}

@end


@implementation NSMutableString (SKFDFExtensions)
- (void)appendFDFName:(SKFDFString)name {
    [self appendFormat:@"/%s", name];
}
@end
