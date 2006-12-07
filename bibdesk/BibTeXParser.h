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

#import "BDSKComplexString.h"
#import "BibPrefController.h"

@interface BibTeXParser : NSObject {
    BibDocument *theDocument;
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
    @abstract   Convenience method that returns an array of BibItems from data, using libbtparse; needs a document to act as macro resolver.
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
    @method     itemsFromString:error:frontMatter:filePath:document:
    @abstract   Convenience method that returns an array of BibItems from the input string, using NSString and NSScanner methods to parse the BibTeX.  Ad-hoc.
    @discussion (comprehensive description)
    @param      string (description)
    @param      hadProblems (description)
    @param      frontMatter (description)
    @param      filePath (description)
    @param      document (description)
    @result     (description)
*/
+ (NSMutableArray *)itemsFromString:(NSString *)string error:(BOOL *)hadProblems frontMatter:(NSMutableString *)frontMatter filePath:(NSString *)filePath document:(BibDocument *)document;

    /*!
    @method     itemsFromString:error:
    @abstract   Convenience method that returns an array of BibItems from the input string, using NSString and NSScanner methods; this method should be used for pasteboard ops.
    @discussion (comprehensive description)
    @param      string (description)
    @param      hadProblems (description)
    @result     (description)
*/
+ (NSMutableArray *)itemsFromString:(NSString *)string error:(BOOL *)hadProblems;

/*!
    @method     itemsFromData:error:frontMatter:filePath:document:
    @abstract   The actual parsing work using libbtparse is done in this method.  It returns an array of BibItems.
    @discussion (comprehensive description)
    @param      inData (description)
    @param      hadProblems (description)
    @param      frontMatter (description)
    @param      filePath (description)
    @param      document (description)
    @result     (description)
*/
- (NSMutableArray *)itemsFromData:(NSData *)inData error:(BOOL *)hadProblems frontMatter:(NSMutableString *)frontMatter filePath:(NSString *)filePath document:(BibDocument *)document;

/*!
    @method     parseItemsFromString:addToDocument:frontMatter:
    @abstract   This method is called by the document, in order to parse a BibTeX file from another thread.
    @discussion (comprehensive description)
    @param      fullString (description)
    @param      document (description)
    @param      frontMatter (description)
*/
- (void)parseItemsFromString:(NSString *)fullString addToDocument:(BibDocument *)document frontMatter:(NSMutableString *)frontMatter;

/*!
    @method     document
    @abstract   Returns the document for this instance of the parser.
    @discussion (comprehensive description)
    @result     (description)
*/
- (BibDocument *)document;

/*!
    @method     setDocument:
    @abstract   Sets the document for this instance of the parser.
    @discussion (comprehensive description)
    @param      aDocument (description)
*/
- (void)setDocument:(BibDocument *)aDocument;

@end
