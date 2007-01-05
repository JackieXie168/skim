//
//  BibAuthorScripting.m
//  BibDesk
//
//  Created by Sven-S. Porst on Sat Jul 10 2004.
/*
 This software is Copyright (c) 2004,2005,2006,2007
 Sven-S. Porst. All rights reserved.
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:
 
 - Redistributions of source code must retain the above copyright
 notice, this list of conditions and the following disclaimer.
 
 - Redistributions in binary form must reproduce the above copyright
 notice, this list of conditions and the following disclaimer in
 the documentation and/or other materials provided with the
 distribution.
 
 - Neither the name of Sven-S. Porst nor the names of any
 contributors may be used to endorse or promote products derived
 from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */
#import "BibAuthor+Scripting.h"
#import "BibDocument.h"
#import "BDSKPublicationsArray.h"

@implementation BibAuthor (Scripting)
/* 
ssp 2004-07-10
 Returns a path to a BibItem for a BibAuthor for Apple Script
 It isn't clear to me what status these objects have. Perhaps there should be a list of authors at the level of the document or application objects instead. 
 This tries to find _some_ instance of this class and return something along the lines of "author 4 of BibItem xxx"
*/
- (NSScriptObjectSpecifier *) objectSpecifier {
	// NSLog(@"BibAuthor objectSpecifier");
    // only publications belonging to a BibDocument are scriptable
	BibDocument * myDoc = (BibDocument *)[[self publication] owner];
	NSScriptObjectSpecifier *containerRef = [myDoc objectSpecifier];
		
	return [[[NSNameSpecifier allocWithZone:[self zone]] initWithContainerClassDescription:[containerRef keyClassDescription] containerSpecifier:containerRef key:@"authors" name:[self normalizedName]] autorelease];
/*	unsigned index = [ar indexOfObjectIdenticalTo:self];
    if (index != NSNotFound) {
        NSScriptObjectSpecifier *containerRef = [[self document] objectSpecifier];
        return [[[NSIndexSpecifier allocWithZone:[self zone]] initWithContainerClassDescription:[containerRef keyClassDescription] containerSpecifier:containerRef key:@"publications" index:index] autorelease];
    } else {
        return nil;
    }
*/	
}

- (NSArray *)publications {
    // only publications belonging to a BibDocument are scriptable
	BibDocument * myDoc = (BibDocument *)[[self publication] owner];
	if (myDoc)
		return [[myDoc publications] itemsForAuthor:self];
	return [NSArray array];
}

@end
