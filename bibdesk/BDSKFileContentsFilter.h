//
//  BDSKFileContentsFilter.h
//  Bibdesk
//
//  Created by Michael McCracken on Tue May 04 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreServices/CoreServices.h>
#import "BibItem.h"
#import "BibDocument.h"
#import "BibPrefController.h"


@interface BDSKFileContentsFilter : NSObject {
	SKIndexRef index;
}

+ (BDSKFileContentsFilter *)sharedFileContentsFilter;

- (void)setupIndex;

- (void)indexFilesFromDocument:(BibDocument *)doc;
- (void)indexFileAtURL:(NSURL *)url fromPub:(BibItem *)pub inDocument:(BibDocument *)doc;

- (NSArray *)filesMatchingQuery:(NSString *)query inDocument:(BibDocument *)doc;
@end
