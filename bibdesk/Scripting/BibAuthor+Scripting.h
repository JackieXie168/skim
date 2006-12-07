//
//  BibAuthorScripting.h
//  Bibdesk
//
//  Created by Sven-S. Porst on Sat Jul 10 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BibAuthor.h"
#import "BibItem+Scripting.h"

@interface BibAuthor (Scripting)

- (NSArray *)publications;

@end
