//
//  BibDeskSearchForCommand.h
//  Bibdesk
//
//  Created by Sven-S. Porst on Wed Jul 21 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BibDocument.h"
#import "BibItem.h"
#import "BibItem+Scripting.h"


@interface BibDeskSearchForCommand : NSScriptCommand {

}

@end



@interface BibDocument (Finding)
- (NSArray*) findMatchesFor:(NSString*) searchterm;
@end

@interface BibItem (Finding)
- (BOOL) matchesString:(NSString*) searchterm;
- (id) objectForCompletion;
@end