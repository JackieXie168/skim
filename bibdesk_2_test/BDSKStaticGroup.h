//
//  BDSKStaticGroup.h
//  bd2xtest
//
//  Created by Christiaan Hofman on 2/15/06.
//  Copyright 2006. All rights reserved.
//

#import <CoreData/CoreData.h>
#import "BDSKGroup.h"


@interface BDSKStaticGroup :  BDSKGroup {
}

@end


@interface BDSKFolderGroup :  BDSKGroup {
}

- (NSSet *)items;

@end
