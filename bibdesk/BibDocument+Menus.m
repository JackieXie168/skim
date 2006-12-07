//
//  BibDocument+Validation.m
//  Bibdesk
//
//  Created by Sven-S. Porst on Fri Jul 30 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "BibDocument+Menus.h"

/* ssp: 2004-07-30
Broken out of BibDocument and split up into smaller parts to make things more managable.
*/



@implementation BibDocument (Menus)

- (BOOL) validateMenuItem:(NSMenuItem*)menuItem{
	SEL act = [menuItem action];

	// handle copy menu items
	// go through hell
	if (act == @selector(copyAsTex:)) {
		return [self validateCopyAsTeXMenuItem:menuItem];
	}
	else if (act == @selector(copyAsBibTex:)) {
		return [self validateCopyAsBibTeXMenuItem:menuItem];
	}
	else if (act == @selector(copyAsPDF:)) {
		return [self validateCopyAsPDFMenuItem:menuItem];
	}
	else if (act == @selector(copyAsRTF:)) {
		return [self validateCopyAsRTFMenuItem:menuItem];
	}
	else if (act == @selector(editPubCmd:)) {
		return [self validateEditSelectionMenuItem:menuItem];
	}
	else if (act == @selector(generateCiteKey:)) {
		return [self validateGenerateCiteKeyMenuItem:menuItem];
	}
	else if (act == @selector(consolidateLinkedFiles:)) {
		return [self validateConsolidateLinkedFilesMenuItem:menuItem];
	}
	else if (act == @selector(delPub:)) {
		return [self validateDeleteSelectionMenuItem:menuItem];
	}
	else if(act == @selector(emailPubCmd:)) {
		return ([self numberOfSelectedPubs] != 0);
	}
	else if([[menuItem representedObject] isEqualToString:@"showHideCustomCiteMenuItem"] ){		
		if(showingCustomCiteDrawer){
			[menuItem setTitle:NSLocalizedString(@"Hide Custom \\cite Commands",@"")];
		}else{
			[menuItem setTitle:NSLocalizedString(@"Show Custom \\cite Commands",@"should be the same as in the nib")];
		}
		return YES;
	}
	else if ( act == @selector(clear:)) {
		return ([self numberOfSelectedPubs] != 0);
	}
	else if (act == @selector(printDocument:)) {
		return [self validatePrintDocumentMenuItem:menuItem];
	}
//	else if ([[menuItem representedObject] isEqualToString:@"displayMenuItem"]) {
//		// update the display menu. Is this smart enough?
//		[menuItem setSubmenu:contextualMenu];
//		return YES;
//	}
    
    else if (act == @selector(makeNewEmptyCollection:)){
        return [[self fileType] isEqualToString:@"BibDesk Library"];        
    }else if (act == @selector(makeNewExternalSource:)){
        return [[self fileType] isEqualToString:@"BibDesk Library"];        
    }else if (act == @selector(makeNewNotepad:)){
        return [[self fileType] isEqualToString:@"BibDesk Library"];        
    }else if (act == @selector(editExportSettingsAction:)){ 
        
        // and selection is a collection:
        return [[self fileType] isEqualToString:@"BibDesk Library"];        
    }else{
		return [super validateMenuItem:menuItem];
    }
	/*   if([@@ [menuItem title] isEqualToString:@"the one for blogging the item"]){
		if(BDSK_USING_JAGUAR){return NO}; @@@@@ -- even better, get IBOutlet to that item, then in awakeFromNib, remove it if BDSK_USING_JAGUAR.
    } */
}



- (BOOL) validateCopyAsTeXMenuItem:(NSMenuItem*) menuItem {
	NSString * s;
	OFPreferenceWrapper * sud = [OFPreferenceWrapper sharedPreferenceWrapper];
	// figure out correct name for TeX as chosen in prefs
	NSString *startCiteBracket = [sud stringForKey:BDSKCiteStartBracketKey]; 
	NSString * TeXName;
	if (![startCiteBracket isEqualToString:@"["]) {
		TeXName = @"TeX";
	}
	else {
		TeXName = @"ConTeXt";
	}
	
	if ([self numberOfSelectedPubs] == 0) {
		// no selection
		s = NSLocalizedString(@"%@ \\cite command", @"%@ \\cite command");
		[menuItem setTitle:[NSString stringWithFormat:s, TeXName]];
		return NO;
	}
	else if ([self numberOfSelectedPubs] == 1) {
		// single selection
		if ([[menuItem menu] supermenu]) {
			s = NSLocalizedString(@"%@ cite command %@", @"%@ cite command %@");
		}
		else {
			s = NSLocalizedString(@"Copy %@ cite command %@", @"Copy %@ cite command %@");
		}
		[menuItem setTitle:[NSString stringWithFormat:s, TeXName, [self citeStringForSelection]]];
		return YES;
	}
	else {
		// multiple selection
		// figure out whether we're dealing with a single or multiple commands
		BOOL sep = ([sud integerForKey:BDSKSeparateCiteKey] == NSOnState);

		if (!sep) {
			// single command
			if ([[menuItem menu] supermenu]) {
				// menu bar/Copy As submenu
				s = NSLocalizedString(@"%@ \\cite command for %i publications", @"%@ \\cite command for %i publications");
			}
			else {
				// action menu
				s = NSLocalizedString(@"Copy %@ \\cite command for %i publications", @"Copy %@ \\cite command for %i publications");
			}
		}
		else {
			// multiple commands
			if ([[menuItem menu] supermenu]) {
				// menu bar/Copy As submenu
				s = NSLocalizedString(@"%2$i %1$@ \\cite commands", @"%2$i %1$@ \\cite commands");
			}
			else {
				// action menu
				s = NSLocalizedString(@"Copy %2$i %1$@ \\cite commands", @"Copy %2$i %1$@ \\cite commands");
			}
		}
		
		[menuItem setTitle:[NSString stringWithFormat:s, TeXName, [self numberOfSelectedPubs]]];
		return YES;
	}
}	



- (BOOL) validateCopyAsBibTeXMenuItem:(NSMenuItem*) menuItem {
	NSString * s;
	
	if ([self numberOfSelectedPubs] == 0) {
		// no selection
		s = NSLocalizedString(@"BibTeX Record", @"BibTeX Record");
		[menuItem setTitle:s];
		return NO;
	}
	else if ([self numberOfSelectedPubs] == 1) {
		// single selection
		if ([[menuItem menu] supermenu]) {
			s = NSLocalizedString(@"BibTeX Record for %@", @"BibTeX Record for %@");
		}
		else {
			s = NSLocalizedString(@"Copy BibTeX Record for %@", @"Copy BibTeX Record for %@");
		}
		NSString * citeKey = [(BibItem*)[shownPublications objectAtIndex:[[[self selectedPubEnumerator] nextObject] intValue]] citeKey];
		[menuItem setTitle:[NSString stringWithFormat:s, citeKey]];
		return YES;
	}
	else {
		// multiple selection
		if ([[menuItem menu] supermenu]) {
			s = NSLocalizedString(@"%i BibTeX Records", @"%i BibTeX Records");
		}
		else {
			s = NSLocalizedString(@"Copy %i BibTeX Records", @"Copy %i BibTeX Records");
		}
		[menuItem setTitle:[NSString stringWithFormat:s, [self numberOfSelectedPubs]]];
		return YES;
	}
}	


- (BOOL) validateCopyAsPDFMenuItem:(NSMenuItem*) menuItem {
	NSString * s;
	
	// check whether we are doing previews at all
	if([[OFPreferenceWrapper sharedPreferenceWrapper] integerForKey:BDSKUsesTeXKey] != NSOnState){
		return NO;
	}
	
	if ([[menuItem menu] supermenu]) {
		return ([self numberOfSelectedPubs] != 0);
	}
	else {
		// action menu, case of no selection doesn't happen here
		if ([self numberOfSelectedPubs] == 1) {
			s = NSLocalizedString(@"Copy Bibliography Entry as Image", @"Copy Bibliography Entry as Image"); 
			[menuItem setTitle:s];
		}
		else {
			// multiple selection
			s = NSLocalizedString(@"Copy %i Bibliography Entries as Image", @"Copy %i Bibliography Entries as Image"); 
			[menuItem setTitle:[NSString stringWithFormat:s, [self numberOfSelectedPubs]]];
		}
		return YES;	
	}	
}


- (BOOL) validateCopyAsRTFMenuItem:(NSMenuItem*) menuItem {
	NSString * s;
	
	// check whether we are doing previews at all
	if([[OFPreferenceWrapper sharedPreferenceWrapper] integerForKey:BDSKUsesTeXKey] != NSOnState){
		return NO;
	}
	
	if ([[menuItem menu] supermenu]) {
		return ([self numberOfSelectedPubs] != 0);
	}
	else {
		// action menu, case of no selection doesn't happen here
		if ([self numberOfSelectedPubs] == 1) {
			s = NSLocalizedString(@"Copy Bibliography Entry as Text", @"Copy Bibliography Entry as Text"); 
			[menuItem setTitle:s];
		}
		else {
			// multiple selection
			s = NSLocalizedString(@"Copy %i Bibliography Entries as Text", @"Copy %i Bibliography Entries as Text"); 
			[menuItem setTitle:[NSString stringWithFormat:s, [self numberOfSelectedPubs]]];
		}
		return YES;	
	}	
}



- (BOOL) validateEditSelectionMenuItem:(NSMenuItem*) menuItem {
	NSString * s;
	
	if ([self numberOfSelectedPubs] == 0) {
		// no selection
		s = NSLocalizedString(@"Edit Publication", @"Edit Publication");
		[menuItem setTitle:s];
		return NO;
	}
	else if ([self numberOfSelectedPubs] == 1) {
		// single selection
		if ([[menuItem menu] supermenu]) {
			s = NSLocalizedString(@"Edit Publication %@", @"Edit Publication %@");
		}
		else {
			s = NSLocalizedString(@"Edit", @"Edit");
		}
		NSString * citeKey = [(BibItem*)[shownPublications objectAtIndex:[[[self selectedPubEnumerator] nextObject] intValue]] citeKey];
		[menuItem setTitle:[NSString stringWithFormat:s, citeKey]];
		return YES;
	}
	else {
		s = NSLocalizedString(@"Edit %i Publications", @"Edit %i Publications");
		[menuItem setTitle:[NSString stringWithFormat:s, [self numberOfSelectedPubs]]];
		return YES;
	}
}	



- (BOOL) validateGenerateCiteKeyMenuItem:(NSMenuItem*) menuItem {
	NSString * s;
	
	if ([self numberOfSelectedPubs] == 0) {
		// no selection
		s = NSLocalizedString(@"Generate Cite Key", @"Generate Cite Key");
		[menuItem setTitle:s];
		return NO;
	}
	else if ([self numberOfSelectedPubs] == 1) {
		// single selection
		s = NSLocalizedString(@"Generate Cite Key", @"Generate Cite Key");
		[menuItem setTitle:[NSString stringWithFormat:s]];
		return YES;
	}
	else {
		s = NSLocalizedString(@"Generate %i Cite Keys", @"Generate %i Cite Keys");
		[menuItem setTitle:[NSString stringWithFormat:s, [self numberOfSelectedPubs]]];
		return YES;
	}
}	



- (BOOL) validateConsolidateLinkedFilesMenuItem:(NSMenuItem*) menuItem {
	NSString * s;
	
	if ([self numberOfSelectedPubs] == 0) {
		// no selection
		s = NSLocalizedString(@"Consolidate Linked Files…", @"Consolidate Linked Files… (needs proper ellipsis)");
		[menuItem setTitle:s];
		return NO;
	}
	else if ([self numberOfSelectedPubs] == 1) {
		// single selection
		NSString * citeKey = [(BibItem*)[shownPublications objectAtIndex:[[[self selectedPubEnumerator] nextObject] intValue]] citeKey];
		s = NSLocalizedString(@"Consolidate Linked File for %@…", @"Consolidate Linked File for %@… (needs proper ellipsis)");
		[menuItem setTitle:[NSString stringWithFormat:s, citeKey]];
		return YES;
	}
	else {
		s = NSLocalizedString(@"Consolidate %i Linked Files…", @"Consolidate %i Linked Files… (needs proper ellipsis)");
		[menuItem setTitle:[NSString stringWithFormat:s, [self numberOfSelectedPubs]]];
		return YES;
	}
}	


- (BOOL) validateDeleteSelectionMenuItem:(NSMenuItem*) menuItem {
	NSString * s;
	int n = [self numberOfSelectedPubs];
	
	if (n <= 1) {
		// no selection or single selection
		s = NSLocalizedString(@"Delete…", @"Delete… (needs proper ellipsis)");
		[menuItem setTitle:s];
		return (n==1);
	}
	else {
		// multiple selection
		s = NSLocalizedString(@"Delete %i Publications…", @"Delete %i Publications… (needs proper ellipsis)");
		[menuItem setTitle:[NSString stringWithFormat:s, n]];
		return YES;
	}
}	



- (BOOL) validatePrintDocumentMenuItem:(NSMenuItem*) menuItem {
	// change name of menu item to indicate that we are only printing the selection?
	if ([self numberOfSelectedPubs] == 0 || [[OFPreferenceWrapper sharedPreferenceWrapper] integerForKey:BDSKUsesTeXKey] != NSOnState){
		// no selection => no printing, no preview generation => no printing
		return NO;
	}
	else {
		return YES;
	}
}



/* respond to the clear: action, so we can validate the Delete item in the edit menu.
*/
- (IBAction) clear:(id) sender {
	[self delPub:sender];
}


@end
