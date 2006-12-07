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

@end
