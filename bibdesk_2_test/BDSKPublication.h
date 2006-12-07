//
//  BDSKPublication.h
//  bd2xtest
//
//  Created by Michael McCracken on 7/17/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface BDSKPublication : NSManagedObject {

}

- (NSString *)name;
- (void)setName:(NSString *)value;

- (NSSet *)authors;
- (NSSet *)editors;
- (NSSet *)institutions;
- (NSSet *)contributorsOfType:(NSString *)type;

@end
