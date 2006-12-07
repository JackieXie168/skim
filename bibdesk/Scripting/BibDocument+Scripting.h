//
//  BibDocument+Scripting.h
//  Bibdesk
//
//  Created by Sven-S. Porst on Thu Jul 08 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//


#import "BibDocument.h"

@interface BibDocument (Scripting) 

- (NSString*) filterField;
- (void)setFilterField:(NSString*) filterterm;

- (NSArray*) displayedPublications;

- (NSArray*) selection;
- (void) setSelection: (NSArray*) newSelection;

- (NSTextStorage*) textStorageForBibString:(NSString*) bibString;
@end



@interface BibDeskBibliographyCommand : NSScriptCommand {
}
@end

/*
@interface BibDeskFilterScriptCommand : NSScriptCommand {
}
@end
*/