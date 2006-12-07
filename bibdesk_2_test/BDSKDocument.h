//  BDSKDocument.h
//  bd2
//
//  Created by Michael McCracken on 5/14/05.
//  Copyright Michael McCracken 2005 . All rights reserved.

#import <Cocoa/Cocoa.h>
#import "BDSKDataModelNames.h"
#import "BDSKMainWindowController.h"

@interface BDSKDocument : NSPersistentDocument {
}

- (NSManagedObject *)rootPubGroup;
- (NSManagedObject *)rootPersonGroup;

@end
