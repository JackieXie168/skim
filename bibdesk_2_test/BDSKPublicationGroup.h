//
//  BDSKPublicationGroup.h
//  bd2
//
//  Created by Michael McCracken on 7/12/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface BDSKPublicationGroup : NSManagedObject {

}

- (NSSet *)publicationsInSelfOrChildren;

- (NSImage *)icon;

@end
