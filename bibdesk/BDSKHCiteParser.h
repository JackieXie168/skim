//
//  BDSKHCiteParser.h
//
//  Created by Michael McCracken on 11/1/06.
//  Copyright 2006 Michael McCracken. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "BibItem.h"
#import "BibTypeManager.h"

@interface BDSKHCiteParser : NSObject {

}

+ (NSArray *)itemsFromXHTMLString:(NSString *)XHTMLString error:(NSError **)error;

@end


