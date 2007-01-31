//
//  BDSKWebGroup.h
//  Bibdesk
//
//  Created by Michael McCracken on 1/25/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "BDSKGroup.h"
#import "BDSKOwnerProtocol.h"
#import "BibPrefController.h"

@interface BDSKWebGroup : BDSKMutableGroup <BDSKOwner> {
    BDSKPublicationsArray *publications;
    BDSKMacroResolver *macroResolver;

}
- (id)initWithName:(NSString *)aName;

- (BDSKPublicationsArray *)publications;
- (void)setPublications:(NSArray *)newPublications;
- (void)addPublications:(NSArray *)newPublications;


@end
