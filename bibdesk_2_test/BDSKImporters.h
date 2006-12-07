/*
 *  BDSKImporters.h
 *  bd2xtest
 *
 *  Created by Michael McCracken on 5/16/06.
 *  Copyright 2006 Michael McCracken. All rights reserved.
 *  See the LICENSE file for license information.
 *
 */

/* A single header file for all importers */

@class BDSKDocument;

@protocol BDSKImporter <NSObject>
+ (id<BDSKImporter>)sharedImporter;
+ (NSDictionary *)defaultSettings;
- (id)initWithSettings:(NSDictionary *)newSettings;
- (NSDictionary *)settings;
- (NSView *)view;
- (BOOL)importIntoDocument:(BDSKDocument *)document userInfo:(NSDictionary *)userInfo error:(NSError **)error;
@end

#include "BDSKBibTexImporter.h"
