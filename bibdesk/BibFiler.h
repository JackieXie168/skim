//
//  BibFiler.h
//  Bibdesk
//
//  Created by Michael McCracken on Fri Apr 30 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BibPrefController.h"
#import "BibItem.h"
@class BibDocument;

@interface BibFiler : NSObject {

}

+ (BibFiler *)sharedFiler;
- (void)filePapers:(NSArray *)papers fromDocument:(BibDocument *)doc;

@end
