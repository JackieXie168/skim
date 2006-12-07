//
//  BibDocument+Validation.h
//  Bibdesk
//
//  Created by Sven-S. Porst on Fri Jul 30 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "BibDocument.h"


@interface BibDocument (Menus)


- (BOOL) validateMenuItem:(NSMenuItem*)menuItem;

- (BOOL) validateCopyAsTeXMenuItem:(NSMenuItem*) menuItem;
- (BOOL) validateCopyAsBibTeXMenuItem:(NSMenuItem*) menuItem;
- (BOOL) validateCopyAsPDFMenuItem:(NSMenuItem*) menuItem;
- (BOOL) validateCopyAsRTFMenuItem:(NSMenuItem*) menuItem;
- (BOOL) validateEditSelectionMenuItem:(NSMenuItem*) menuItem;
- (BOOL) validateGenerateCiteKeyMenuItem:(NSMenuItem*) menuItem;
- (BOOL) validateConsolidateLinkedFilesMenuItem:(NSMenuItem*) menuItem;
- (BOOL) validateDeleteSelectionMenuItem:(NSMenuItem*) menuItem;
- (BOOL) validatePrintDocumentMenuItem:(NSMenuItem*) menuItem;


- (IBAction) clear:(id) sender;
@end
