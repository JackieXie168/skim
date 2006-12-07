/*
 *  BDSKItemSource.h
 *  Bibdesk
 *
 *  Created by Michael McCracken on 3/8/05.
 *  Copyright 2005 Michael McCracken. All rights reserved.
 *
 */

#include <Cocoa/Cocoa.h>

@protocol BDSKItemSource

- (NSArray *)selectedItems;

- (NSArray *)allItems;

@end