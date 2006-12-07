//
//  BibTeXParser.h
//  Bibdesk
//
//  Created by Michael McCracken on Thu Nov 28 2002.
//  Copyright (c) 2002 __MyCompanyName__. All rights reserved.
//

#include <stdio.h>
#import <Cocoa/Cocoa.h>
#import "btparse.h"
#import "BibAppController.h"
@class BibItem;
#import "BibItem.h"
#import "BDSKConverter.h"

@interface BibTeXParser : NSObject {

}

/*!
     @method itemsFromString:
 @abstract creates bibitems.
 @discussion builds and returns the BibItems that correspond to the text in entry.

 @param itemString A string of bibtex entries
 @result An array where each entry is anautoreleased bibItem (or null if the parsing failed.)

 */

+ (NSMutableArray *)itemsFromData:(NSData *)inData error:(BOOL *)hadProblems;
+ (NSMutableArray *)itemsFromData:(NSData *)inData error:(BOOL *)hadProblems frontMatter:(NSMutableString *)frontMatter filePath:(NSString *)filePath;
+ (NSMutableArray *)itemsFromString:(NSString *)fullString error:(BOOL *)hadProblems frontMatter:(NSMutableString *)frontMatter filePath:(NSString *)filePath;
+ (NSMutableArray *)itemsFromString:(NSString *)string error:(BOOL *)hadProblems;

- (NSDictionary *)macroStringFromScanner:(NSScanner *)scanner endingRange:(NSRange)range string:(NSString *)fullString;
- (NSMutableArray *)itemsFromString:(NSString *)fullString error:(BOOL *)hadProblems frontMatter:(NSMutableString *)frontMatter filePath:(NSString *)filePath addToDocument:(BibDocument *)document;
- (NSMutableArray *)itemsFromData:(NSData *)inData error:(BOOL *)hadProblems frontMatter:(NSMutableString *)frontMatter filePath:(NSString *)filePath;
- (void)parseItemsFromString:(NSString *)fullString addToDocument:(BibDocument *)document;

@end
