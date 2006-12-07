//
//  BibAppController+Scripting.m
//  Bibdesk
//
//  Created by Sven-S. Porst on Sat Jul 10 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "BibAppController+Scripting.h"

/* ssp
Category on BibAppController making the papers folder readable for scripting
*/
@implementation BibAppController (Scripting)

/*
 ssp: 2004-07-12
 these two methods make the papers folder preference available to AppleScript
 -papersFolder accessor method
 -application:delegateHandlesKey: advertises the accesor method
*/
- (NSString*) papersFolder {
	return [[OFPreferenceWrapper sharedPreferenceWrapper] stringForKey:BDSKPapersFolderPathKey];
}

- (BOOL)application:(NSApplication *)sender delegateHandlesKey:(NSString *)key {
	if ([key isEqualToString:@"papersFolder"]) 
		return YES;
	return NO;
}

@end

