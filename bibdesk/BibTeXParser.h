//
//  BibTeXParser.h
//  BibDesk
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

#import "BDSKComplexString.h"
#import "BibPrefController.h"
#import <OmniFoundation/NSString-OFExtensions.h>

@interface BibTeXParser : NSObject {
}

/*!
    @method     itemsFromData:error:
    @abstract   Convenience method that returns an array of BibItems from the input NSData; used by the pasteboard.  Uses libbtparse to parse the data.
    @discussion (comprehensive description)
    @param      inData (description)
    @param      hadProblems (description)
    @result     (description)
*/
+ (NSMutableArray *)itemsFromData:(NSData *)inData error:(BOOL *)hadProblems;

/*!
    @method     itemsFromData:error:frontMatter:filePath:document:
    @abstract   Parsing method that returns an array of BibItems from data, using libbtparse; needs a document to act as macro resolver.
    @discussion (comprehensive description)
    @param      inData (description)
    @param      hadProblems (description)
    @param      frontMatter (description)
    @param      filePath (description)
    @param      aDocument (description)
    @result     (description)
*/
+ (NSMutableArray *)itemsFromData:(NSData *)inData
                            error:(BOOL *)hadProblems
                      frontMatter:(NSMutableString *)frontMatter
                         filePath:(NSString *)filePath
                 document:(BibDocument *)aDocument;

/*!
    @method     macrosFromBibTeXString:hadProblems:
    @abstract   Parses a BibTeX string as @string{} declarations, and returns an array of dictionary objects describing each one.
    @discussion Access the objects with @"mkey" for the macro key and @"mstring" for the string definition.
    @param      aString BibTeX as NSString
    @param      hadProblems (description)
    @result     (description)
*/
+ (NSArray *)macrosFromBibTeXString:(NSString *)aString hadProblems:(BOOL *)hadProblems;
    
/*!
    @method     stringFromBibTeXValue:error:frontMatter:document:
    @abstract   Parsing method that returns a complex nor simple string for a value entered as BibTeX string, using libbtparse; needs a document to act as macro resolver.
    @discussion (comprehensive description)
    @param      value (description)
    @param      hadProblems (description)
    @param      aDocument (description)
    @result     (description)
*/
+ (NSString *)stringFromBibTeXValue:(NSString *)value error:(BOOL *)hadProblems document:(BibDocument *)aDocument;

@end
