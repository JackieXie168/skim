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
#import "AGRegex/AGRegex.h"

@interface PubMedParser : NSObject {

}


+ (NSMutableArray *)itemsFromString:(NSString *)itemString error:(BOOL *)hadProblems;
+ (NSMutableArray *)itemsFromString:(NSString *)itemString error:(BOOL *)hadProblems frontMatter:(NSMutableString *)frontMatter filePath:(NSString *)filePath;

/*!
    @function	addStringToDict
    @abstract   Used to add additional strings to an existing dictionary entry.
    @discussion This is useful for multiple authors and multiple keywords, so we don't wipe them out by overwriting.
    @param      wholeValue String object that we are adding (e.g. <tt>Ann Author</tt>).
    @param	pubDict NSMutableDictionary containing the current publication.
    @param	theKey NSString object with the key that we are adding an item to (e.g. <tt>Author</tt>).
*/
void addStringToDict(NSString *wholeValue, NSMutableDictionary *pubDict, NSString *theKey);
/*!
    @function   isDuplicateAuthor
    @abstract   Check to see if we have a duplicate author in the list
    @discussion Some online databases (Scopus in particular) give us RIS with multiple instances of the same author.
                BibTeX accepts this, and happily prints out duplicate author names.  This isn't a very robust check.
    @param      oldList Existing author list in the dictionary
    @param      newAuthor The author that we want to add
    @result     Returns YES if it's a duplicate
*/
BOOL isDuplicateAuthor(NSString *oldList, NSString *newAuthor);
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
