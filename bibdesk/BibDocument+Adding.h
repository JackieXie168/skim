//
//  BibDocument+Adding.h
//  Bibdesk
//
//  Created by Sven-S. Porst on Mon Jul 19 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BibDocument.h"
#import "BibDocument_DataSource.h"
#import "BibAppController.h"
#import "BibItem.h"
#import "BDSKPreviewer.h"

@interface BibDocument (Adding)
- (BOOL) addPublicationsFromPasteboard:(NSPasteboard*) pb error:(NSString**) error;
- (BOOL) addPublicationsForString:(NSString*) string error:(NSString**) error;
- (BOOL) addPublicationsForData:(NSData*) data error:(NSString**) error;
- (BOOL) addPublicationsForFiles:(NSArray*) filenames error:(NSString**) error;

- (BOOL)tableView:(NSTableView*)tv acceptDrop:(id <NSDraggingInfo>)info row:(int)row dropOperation:(NSTableViewDropOperation)op;
- (IBAction)paste:(id)sender;

	
@end


@interface BibAppController (BibImportService)
- (void)addPublicationsFromSelection:(NSPasteboard *)pboard
						   userData:(NSString *)userData
							  error:(NSString **)error;
	
@end