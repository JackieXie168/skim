//
//  PubMedParser.h
//  Bibdesk
//
//  Created by Michael McCracken on Sun Nov 16 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BibItem.h"
#import "BibAppController.h"

@interface PubMedParser : NSObject {

}


+ (NSMutableArray *)itemsFromString:(NSString *)itemString error:(BOOL *)hadProblems;
+ (NSMutableArray *)itemsFromString:(NSString *)itemString error:(BOOL *)hadProblems frontMatter:(NSMutableString *)frontMatter filePath:(NSString *)filePath;

void addAuthorName_toDict(NSString *wholeValue, NSMutableDictionary *pubDict);
void addKeywordString_toDict(NSString *wholeValue, NSMutableDictionary *pubDict);
/*!
    @function   mergePageNumbers
    @abstract   Elsevier/ScienceDirect RIS output has SP for start page and EP for end page.  If we find
                both of those in the entry, we merge them and add them back into the dictionary as
                SP--EP forKey:Pages.
    @param      dict NSMutableDictionary containing a single RIS bibliography entry
*/
void mergePageNumbers(NSMutableDictionary *dict);
/*!
    @method     bibitemWithPubMedDictionary:fileOrder:
    @abstract   Convenience method which returns an autoreleased BibItem when given a pubDict object which
		may represent PubMed or other RIS information.
    @discussion (comprehensive description)
    @param      pubDict Dictionary containing an RIS representation of a bib item.
    @param      itemOrder (description)
    @result     A new, autoreleased BibItem, of type BibTeX.
*/
+ (BibItem *)bibitemWithPubMedDictionary:(NSMutableDictionary *)pubDict fileOrder:(int)itemOrder;


@end
