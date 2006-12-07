//
//  BibField.h
//  BibDesk
//
//  Created by Christiaan Hofman on 27/11/04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "BibItem.h"

@interface BibField : NSObject {
	NSString *name;
	BibItem *bibItem;
}

- (id)initWithName:(NSString *)newName bibItem:(BibItem *)newBibItem;

- (NSString *)name;

- (NSString *)value;
- (void)setValue:(NSString *)newValue;

- (NSString *)bibTeXString;
- (void)setBibTeXString:(NSString *)newValue;

@end
