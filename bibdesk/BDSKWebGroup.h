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

@class BDSKPublicationsArray, BDSKMacroResolver;

@interface BDSKWebGroup : BDSKMutableGroup <BDSKOwner> {
    BDSKPublicationsArray *publications;
    BDSKMacroResolver *macroResolver;
    BOOL isRetrieving;
}

- (id)initWithName:(NSString *)aName;

- (BDSKPublicationsArray *)publications;
- (void)setPublications:(NSArray *)newPublications;
- (void)addPublications:(NSArray *)newPublications;

- (void)setRetrieving:(BOOL)flag;

@end
