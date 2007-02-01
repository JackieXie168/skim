//
//  BDSKMacro.h
//  Bibdesk
//
//  Created by Christiaan Hofman on 1/2/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class BibDocument;

@interface BDSKMacro : NSObject {
	NSString *name;
    BibDocument *document;
}

- (id)initWithName:(NSString *)aName document:(BibDocument *)aDocument;

- (NSString *)name;
- (void)setName:(NSString *)newName;

- (id)value;
- (void)setValue:(NSString *)newValue;

- (id)bibTeXString;
- (void)setBibTeXString:(NSString *)newValue;

- (BibDocument *)document;

@end
