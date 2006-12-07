//
//  BibDeskOpenCommand.m
//  BibDesk
//
//  Created by Sven-S. Porst on 14.09.04.
/*
 This software is Copyright (c) 2004,2005,2006
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

#import "BibDeskOpenCommand.h"
#import "BibDocument_Actions.h"
#import "BibItem+Scripting.h"
#import "BibAuthor.h"

/* Implements the script command 'open'.
It can be used with 
. publications to open their BibEditor and
. authors to open their author window
*/

@implementation BibDeskOpenCommand

- (id)performDefaultImplementation {
	// get direct object 
    id  param = [self directParameter];
	NSArray * ar = nil;
	
	
	if ([param isKindOfClass:[NSArray class]]) {
		// we got an array of items	
		ar = param;
	}
	else if ( [param isKindOfClass:[NSScriptObjectSpecifier class]] ) {
		// it's a SOS -> put it into an array
		ar = [NSArray arrayWithObject:param];
	}
	else {
		// uh-oh! 
	
	}
	
	NSScriptObjectSpecifier * dP = nil;
	NSEnumerator * myEnum = [ar objectEnumerator];
	
	while ( dP = [myEnum nextObject]) {
	
		id dPO = [dP objectsByEvaluatingSpecifier];
		
		if ([dPO isKindOfClass:[BibItem class]]) {
			// we want to open a publication
			BibItem * pub = (BibItem*)dPO;
            // only publications belonging to a BibDocument are scriptable
			[(BibDocument *)[pub owner] editPub:pub];
		}
		else if ([dPO isKindOfClass:[BibAuthor class]]) {
			// we want to open an author
			BibAuthor * author = (BibAuthor *) dPO;
            // only publications belonging to a BibDocument are scriptable
            BibDocument *doc = (BibDocument *)[[author publication] owner];
            [doc showPerson:author];
		}
		else {
			// give up
			[self setScriptErrorNumber:NSReceiversCantHandleCommandScriptError];
			[self setScriptErrorString:NSLocalizedString(@"The 'open' command was used on an object that BibDesk cannot open. BibDesk is able to open (windows for) authors and publications.", @"Error description")];
			return nil;
		}
	} // while
	
	return nil;
}

@end
