//
//  BibAppController+Scripting.h
//  Bibdesk
//
//  Created by Sven-S. Porst on Sat Jul 10 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BibAppController.h"
#import <OmniFoundation/OFPreference.h>

@interface BibAppController (Scripting) 

- (NSString*) papersFolder;

- (NSArray *)allTypes;

- (NSArray *)allFieldNames;

- (BOOL)application:(NSApplication *)sender delegateHandlesKey:(NSString *)key;


@end

