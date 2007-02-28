//
//  NSTableView_BDSKExtensions.h
//  bd2xtest
//
//  Created by Christiaan Hofman on 2/5/06.
//  Copyright 2006. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSTableView (BDSKExtensions)

- (BOOL)setValidDropRow:(int *)row dropOperation:(NSTableViewDropOperation)operation;

@end
