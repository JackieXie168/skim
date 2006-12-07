//
//  BibAuthorScripting.m
//  Bibdesk
//
//  Created by Sven-S. Porst on Sat Jul 10 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "BibAuthor+Scripting.h"


@implementation BibAuthor (Scripting)
/* 
ssp 2004-07-10
 Returns a path to a BibItem for a BibAuthor for Apple Script
 It isn't clear to me what status these objects have. Perhaps there should be a list of authors at the level of the document or application objects instead. 
 This tries to find _some_ instance of this class and return something along the lines of "author 4 of BibItem xxx"
*/

- (NSScriptObjectSpecifier *) objectSpecifier {
	// NSLog(@"BibAuthor objectSpecifier");
	NSArray * bars = [self publications];
	// just use the first one here for the time being
	BibItem * myPub = (BibItem*)[bars objectAtIndex:0];
	BibDocument * myDoc = [myPub document];
	NSScriptObjectSpecifier *containerRef = [myDoc objectSpecifier];
		
	return [[[NSNameSpecifier allocWithZone:[self zone]] initWithContainerClassDescription:[containerRef keyClassDescription] containerSpecifier:containerRef key:@"authors" name:[self name]] autorelease];
/*	unsigned index = [ar indexOfObjectIdenticalTo:self];
    if (index != NSNotFound) {
        NSScriptObjectSpecifier *containerRef = [[self document] objectSpecifier];
        return [[[NSIndexSpecifier allocWithZone:[self zone]] initWithContainerClassDescription:[containerRef keyClassDescription] containerSpecifier:containerRef key:@"publications" index:index] autorelease];
    } else {
        return nil;
    }
*/	
}


@end
