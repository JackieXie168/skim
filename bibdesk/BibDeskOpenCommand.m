//
//  BibDeskOpenCommand.m
//  Bibdesk
//
//  Created by Sven-S. Porst on 14.09.04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "BibDeskOpenCommand.h"
#import "BibItem+Scripting.h"
#import "BibPersonController.h"

/* Implements the script command 'open'.
It can be used with 
. publications to open their BibEditor and
. authors to open their author window
*/

@implementation BibDeskOpenCommand

- (id)performDefaultImplementation {
	// get direct object 
    id  param = [self directParameter];
	NSArray * ar;
	
	
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
			[[pub document] editPub:pub];
		}
		else if ([dPO isKindOfClass:[BibAuthor class]]) {
			// we want to open an author
			BibAuthor * author = (BibAuthor *) dPO;
		
			// the following is taken from BibEditor's -showPersonDetail: method. This method should probably live in BibAppController or so - which will let us call it from everywhere. It shouldn't depend on a publication or a publication's editor.
			BibPersonController *pc = [author personController];
			if(pc == nil){
                            BibDocument *doc = [[author publication] document];
                            pc = [[BibPersonController alloc] initWithPerson:author document:doc];
                            [doc addWindowController:pc];
                            [pc release];
			}
			[pc show];		
		}
		else {
			// give up
			[self setScriptErrorNumber:NSReceiversCantHandleCommandScriptError];
			[self setScriptErrorString:NSLocalizedString(@"Error message for AppleScript open command when a direct parameter is passed that we can't handle.", @"The 'open' command was used on an object that BibDesk cannot open. BibDesk is able to open (windows for) authors and publications.")];
			return nil;
		}
	} // while
	
	return nil;
}

@end
