//
//  PDFDocument_SKExtensions.m
//  Skim
//
//  Created by Christiaan Hofman on 2/17/08.
/*
 This software is Copyright (c) 2008-2014
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

#import "PDFDocument_SKExtensions.h"
#import "PDFSelection_SKExtensions.h"
#import "NSNumber_SKExtensions.h"
#import "PDFPage_SKExtensions.h"
#import "NSData_SKExtensions.h"


@implementation PDFDocument (SKExtensions)

- (NSArray *)pageLabels {
    NSUInteger pageCount = [self pageCount];
    NSMutableArray *pageLabels = [NSMutableArray array];
    BOOL useSequential = [[self pageClass] usesSequentialPageNumbering];
    if (useSequential == NO) {
        CGPDFDocumentRef doc = [self documentRef];
        CGPDFDictionaryRef catalog = CGPDFDocumentGetCatalog(doc);
        CGPDFDictionaryRef labelsDict = NULL;
        CGPDFArrayRef labelsArray = NULL;
        if (catalog) {
            if(false == CGPDFDictionaryGetDictionary(catalog, "PageLabels", &labelsDict)) {
                useSequential = YES;
            } else if (CGPDFDictionaryGetArray(labelsDict, "Nums", &labelsArray)) {
                size_t i = CGPDFArrayGetCount(labelsArray);
                CGPDFInteger j = pageCount;
                while (i > 0) {
                    CGPDFInteger labelIndex;
                    CGPDFDictionaryRef labelDict = NULL;
                    const char *labelStyle;
                    CGPDFStringRef labelPDFPrefix;
                    NSString *labelPrefix;
                    CGPDFInteger labelStart;
                    if (false == CGPDFArrayGetDictionary(labelsArray, --i, &labelDict) ||
                        false == CGPDFArrayGetInteger(labelsArray, --i, &labelIndex)) {
                        [pageLabels removeAllObjects];
                        break;
                    }
                    if (false == CGPDFDictionaryGetName(labelDict, "S", &labelStyle))
                        labelStyle = NULL;
                    if (CGPDFDictionaryGetString(labelDict, "P", &labelPDFPrefix))
                        labelPrefix = [(NSString *)CGPDFStringCopyTextString(labelPDFPrefix) autorelease];
                    else
                        labelPrefix = nil;
                    if (false == CGPDFDictionaryGetInteger(labelDict, "St", &labelStart))
                        labelStart = 1;
                    while (j > labelIndex) {
                        NSNumber *labelNumber = [NSNumber numberWithInteger:--j - labelIndex + labelStart];
                        NSMutableString *string = [NSMutableString string];
                        if (labelPrefix)
                            [string appendString:labelPrefix];
                        if (labelStyle) {
                            if (0 == strcmp(labelStyle, "D"))
                                [string appendFormat:@"%@", labelNumber];
                            else if (0 == strcmp(labelStyle, "R"))
                                [string appendString:[[labelNumber romanNumeralValue] uppercaseString]];
                            else if (0 == strcmp(labelStyle, "r"))
                                [string appendString:[labelNumber romanNumeralValue]];
                            else if (0 == strcmp(labelStyle, "A"))
                                [string appendString:[[labelNumber alphaCounterValue] uppercaseString]];
                            else if (0 == strcmp(labelStyle, "a"))
                                [string appendString:[labelNumber alphaCounterValue]];
                        }
                        [pageLabels insertObject:string atIndex:0];
                    }
                }
            }
        }
    }
    if ([pageLabels count] != pageCount) {
        NSUInteger i;
        [pageLabels removeAllObjects];
        for (i = 0; i < pageCount; i++)
            [pageLabels addObject:useSequential ? [NSString stringWithFormat:@"%lu", (unsigned long)(i + 1)] : [[self pageAtIndex:i] displayLabel]];
    }
    return pageLabels;
}

- (NSArray *)fileIDStrings:(NSData *)pdfData {
    CGPDFDocumentRef doc = [self documentRef];
    CGPDFArrayRef idArray = CGPDFDocumentGetID(doc);
    
    if (idArray == NULL)
        return nil;
    
    NSMutableArray *fileIDStrings = [NSMutableArray array];
    size_t i, iMax = CGPDFArrayGetCount(idArray);
    
    for (i = 0; i < iMax; i++) {
        CGPDFStringRef idString;
        if (CGPDFArrayGetString(idArray, i, &idString)) {
            size_t j = 0, k = 0, length = CGPDFStringGetLength(idString);
            const unsigned char *inputBuffer = CGPDFStringGetBytePtr(idString);
            unsigned char outputBuffer[length * 2]; // length should be 16 so no need to malloc
            static unsigned char hexEncodeTable[17] = "0123456789abcdef";
            
            for (j = 0; j < length; j++) {
                outputBuffer[k++] = hexEncodeTable[(inputBuffer[j] & 0xF0) >> 4];
                outputBuffer[k++] = hexEncodeTable[(inputBuffer[j] & 0x0F)];
            }
            
            NSString *fileID = [[NSString alloc] initWithBytes:outputBuffer length:k encoding:NSASCIIStringEncoding];
            [fileIDStrings addObject:fileID];
            [fileID release];
        }
    }
    
    return fileIDStrings;
}

- (NSDictionary *)initialSettings {
    CGPDFDocumentRef doc = [self documentRef];
    CGPDFDictionaryRef catalog = CGPDFDocumentGetCatalog(doc);
    const char *pageLayout = NULL;
    CGPDFDictionaryRef viewerPrefs = NULL;
    NSMutableDictionary *settings = [NSMutableDictionary dictionary];
    if (catalog) {
        if (CGPDFDictionaryGetName(catalog, "PageLayout", &pageLayout)) {
            if (0 == strcmp(pageLayout, "SinglePage")) {
                [settings setObject:[NSNumber numberWithInteger:kPDFDisplaySinglePage] forKey:@"displayMode"];
            } else if (0 == strcmp(pageLayout, "OneColumn")) {
                [settings setObject:[NSNumber numberWithInteger:kPDFDisplaySinglePageContinuous] forKey:@"displayMode"];
            } else if (0 == strcmp(pageLayout, "TwoColumnLeft")) {
                [settings setObject:[NSNumber numberWithInteger:kPDFDisplayTwoUpContinuous] forKey:@"displayMode"];
                [settings setObject:[NSNumber numberWithBool:NO] forKey:@"displaysAsBook"];
            } else if (0 == strcmp(pageLayout, "TwoColumnRight")) {
                [settings setObject:[NSNumber numberWithInteger:kPDFDisplayTwoUpContinuous] forKey:@"displayMode"];
                [settings setObject:[NSNumber numberWithBool:YES] forKey:@"displaysAsBook"];
            }
        }
        if (CGPDFDictionaryGetDictionary(catalog, "ViewerPreferences", &viewerPrefs)) {
            const char *viewArea = NULL;
            CGPDFBoolean fitWindow = false;
            if (CGPDFDictionaryGetName(catalog, "ViewArea", &viewArea)) {
                if (0 == strcmp(viewArea, "CropBox"))
                    [settings setObject:[NSNumber numberWithInteger:kPDFDisplayBoxCropBox] forKey:@"displayBox"];
                else if (0 == strcmp(viewArea, "MediaBox"))
                    [settings setObject:[NSNumber numberWithInteger:kPDFDisplayBoxMediaBox] forKey:@"displayBox"];
            }
            if (CGPDFDictionaryGetBoolean(catalog, "FitWindow", &fitWindow))
                [settings setObject:[NSNumber numberWithBool:(BOOL)fitWindow] forKey:@"fitWindow"];
        }
    }
    return [settings count] > 0 ? settings : nil;
}

- (BOOL)hasRightToLeftLanguage {
    CGPDFDocumentRef doc = [self documentRef];
    CGPDFDictionaryRef catalog = CGPDFDocumentGetCatalog(doc);
    BOOL isRTL = NO;
    if (catalog) {
        CGPDFStringRef lang = NULL;
        if (CGPDFDictionaryGetString(catalog, "LANG", &lang)) {
            NSString *language = (NSString *)CGPDFStringCopyTextString(lang);
            isRTL = [NSLocale characterDirectionForLanguage:language] == kCFLocaleLanguageDirectionRightToLeft;
            [language release];
        }
    }
    return isRTL;
}

@end
