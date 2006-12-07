//
//  BibDocument_DataSource.h
//  Bibdesk
//
//  Created by Michael McCracken on Tue Mar 26 2002.
//  Copyright (c) 2001 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "BibDocument.h"

/*! @category  BibDocument(DataSource)
@discussion Additions to BibDocument for handling outline & table views.
*/
@interface BibDocument (DataSource)

@end

@interface NSPasteboard (JCRDragWellExtensions)

- (BOOL) hasType:aType; /*"Returns TRUE if aType is one of the types
available from the receiving pastebaord."*/

- (BOOL) containsFiles; /*"Returns TRUE if there are filenames available
    in the receiving pasteboard."*/

- (BOOL) containsURL;

@end
