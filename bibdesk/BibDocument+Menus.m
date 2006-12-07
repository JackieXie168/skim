//
//  BibDocument+Menus.m
//  BibDesk
//
//  Created by Sven-S. Porst on Fri Jul 30 2004.
/*
 This software is Copyright (c) 2004,2005
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

#import "BibDocument+Menus.h"

/* ssp: 2004-07-30
Broken out of BibDocument and split up into smaller parts to make things more managable.
*/



@implementation BibDocument (Menus)

- (BOOL) validateMenuItem:(NSMenuItem*)menuItem{
	SEL act = [menuItem action];

	// handle copy menu items
	// go through hell
	if (act == @selector(cut:)) {
		return [self validateCutMenuItem:menuItem];
	}
	else if (act == @selector(copy:)) {
		return [self validateCopyMenuItem:menuItem];
	}
	else if (act == @selector(copyAsTex:)) {
		return [self validateCopyAsTeXMenuItem:menuItem];
	}
	else if (act == @selector(copyAsBibTex:)) {
		return [self validateCopyAsBibTeXMenuItem:menuItem];
	}
	else if (act == @selector(copyAsPublicBibTex:)) {
		return [self validateCopyAsPublicBibTeXMenuItem:menuItem];
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
	else if(act == @selector(openLinkedFile:)) {
		return [self validateOpenLinkedFileMenuItem:menuItem];
	}
	else if(act == @selector(revealLinkedFile:)) {
		return [self validateRevealLinkedFileMenuItem:menuItem];
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
	else if (act == @selector(columnsMenuSelectTableColumn:)) {
		return ([columnsMenu numberOfItems] > 3);
	}
	else if (act == @selector(toggleStatusBar:)) {
		return [self validateToggleStatusBarMenuItem:menuItem];
	} else if ([menuItem action] == @selector(importFromPasteboardAction:)) {
		return [self validateNewPubFromPasteboardMenuItem:menuItem];
	} else if ([menuItem action] == @selector(importFromFileAction:)) {
		return [self validateNewPubFromFileMenuItem:menuItem];
	} else if ([menuItem action] == @selector(importFromWebAction:)) {
		return [self validateNewPubFromWebMenuItem:menuItem];
	} else if ([menuItem action] == @selector(selectCrossrefParentAction:)) {
        return [self validateSelectCrossrefParentMenuItem:menuItem];
    } else if ([menuItem action] == @selector(createNewPubUsingCrossrefAction:)) {
        return [self validateCreateNewPubUsingCrossrefMenuItem:menuItem];
    } else if ([menuItem action] == @selector(copyAsRIS:)) {
        return [self validateCopyAsRISMenuItem:menuItem];
    } else if ([menuItem action] == @selector(duplicate:)) {
        return [self validateDuplicateMenuItem:menuItem];
    } else {
		return [super validateMenuItem:menuItem];
    }
}



- (BOOL) validateCutMenuItem:(NSMenuItem*) menuItem {
	if ([self numberOfSelectedPubs] == 0) {
		// no selection
		return NO;
	}
	else {
		// multiple selection
		return YES;
	}
}	



- (BOOL) validateCopyMenuItem:(NSMenuItem*) menuItem {
	if ([self numberOfSelectedPubs] == 0) {
		// no selection
		return NO;
	}
	else {
		// multiple selection
		return YES;
	}
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
		BOOL sep = [sud boolForKey:BDSKSeparateCiteKey];

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



- (BOOL) validateCopyAsPublicBibTeXMenuItem:(NSMenuItem*) menuItem {
	NSString * s;
	
	if ([self numberOfSelectedPubs] == 0) {
		// no selection
		s = NSLocalizedString(@"Minimal BibTeX Record", @"Minimal BibTeX Record");
		[menuItem setTitle:s];
		return NO;
	}
	else if ([self numberOfSelectedPubs] == 1) {
		// single selection
		if ([[menuItem menu] supermenu]) {
			s = NSLocalizedString(@"Minimal BibTeX Record for %@", @"Minimal BibTeX Record for %@");
		}
		else {
			s = NSLocalizedString(@"Copy Minimal BibTeX Record for %@", @"Copy Minimal BibTeX Record for %@");
		}
		NSString * citeKey = [(BibItem*)[shownPublications objectAtIndex:[[[self selectedPubEnumerator] nextObject] intValue]] citeKey];
		[menuItem setTitle:[NSString stringWithFormat:s, citeKey]];
		return YES;
	}
	else {
		// multiple selection
		if ([[menuItem menu] supermenu]) {
			s = NSLocalizedString(@"%i Minimal BibTeX Records", @"%i Minimal BibTeX Records");
		}
		else {
			s = NSLocalizedString(@"Copy %i Minimal BibTeX Records", @"Copy %i Minimal BibTeX Records");
		}
		[menuItem setTitle:[NSString stringWithFormat:s, [self numberOfSelectedPubs]]];
		return YES;
	}
}	


- (BOOL) validateCopyAsPDFMenuItem:(NSMenuItem*) menuItem {
	NSString * s;
	
	// check whether we are doing previews at all
	if(![[OFPreferenceWrapper sharedPreferenceWrapper] boolForKey:BDSKUsesTeXKey]){
		return NO;
	}
	
	if ([[menuItem menu] supermenu]) {
		return ([self numberOfSelectedPubs] != 0);
	}
	else {
		// action menu
		if ([self numberOfSelectedPubs] == 0) {
			// no selection
			s = NSLocalizedString(@"Copy Bibliography Entry as Image", @"Copy Bibliography Entry as Image"); 
			[menuItem setTitle:s];
			return NO;
		}
		else if ([self numberOfSelectedPubs] == 1) {
			// single selection
			s = NSLocalizedString(@"Copy Bibliography Entry as Image", @"Copy Bibliography Entry as Image"); 
			[menuItem setTitle:s];
			return YES;	
		}
		else {
			// multiple selection
			s = NSLocalizedString(@"Copy %i Bibliography Entries as Image", @"Copy %i Bibliography Entries as Image"); 
			[menuItem setTitle:[NSString stringWithFormat:s, [self numberOfSelectedPubs]]];
			return YES;	
		}
	}	
}


- (BOOL) validateCopyAsRTFMenuItem:(NSMenuItem*) menuItem {
	NSString * s;
	
	// check whether we are doing previews at all
	if(![[OFPreferenceWrapper sharedPreferenceWrapper] boolForKey:BDSKUsesTeXKey]){
		return NO;
	}
	
	if ([[menuItem menu] supermenu]) {
		return ([self numberOfSelectedPubs] != 0);
	}
	else {
		// action menu
		if ([self numberOfSelectedPubs] == 0) {
			// no selection
			s = NSLocalizedString(@"Copy Bibliography Entry as Text", @"Copy Bibliography Entry as Text"); 
			[menuItem setTitle:s];
			return NO;
		}
		else if ([self numberOfSelectedPubs] == 1) {
			// single selection
			s = NSLocalizedString(@"Copy Bibliography Entry as Text", @"Copy Bibliography Entry as Text"); 
			[menuItem setTitle:s];
			return YES;	
		}
		else {
			// multiple selection
			s = NSLocalizedString(@"Copy %i Bibliography Entries as Text", @"Copy %i Bibliography Entries as Text"); 
			[menuItem setTitle:[NSString stringWithFormat:s, [self numberOfSelectedPubs]]];
			return YES;	
		}
	}	
}

- (BOOL)validateCopyAsRISMenuItem:(NSMenuItem *)menuItem{
	NSString * s;
	
	if ([self numberOfSelectedPubs] == 0) {
		// no selection
		s = NSLocalizedString(@"RIS Record", @"RIS Record");
		[menuItem setTitle:s];
		return NO;
	}
	else if ([self numberOfSelectedPubs] == 1) {
		// single selection
		if ([[menuItem menu] supermenu]) {
			s = NSLocalizedString(@"RIS Record for %@", @"RIS Record for %@");
		}
		else {
			s = NSLocalizedString(@"Copy RIS Record for %@", @"Copy RIS Record for %@");
		}
		NSString * citeKey = [(BibItem*)[shownPublications objectAtIndex:[[[self selectedPubEnumerator] nextObject] intValue]] citeKey];
		[menuItem setTitle:[NSString stringWithFormat:s, citeKey]];
		return YES;
	}
	else {
		// multiple selection
		if ([[menuItem menu] supermenu]) {
			s = NSLocalizedString(@"%i RIS Records", @"%i RIS Records");
		}
		else {
			s = NSLocalizedString(@"Copy %i RIS Records", @"Copy %i RIS Records");
		}
		[menuItem setTitle:[NSString stringWithFormat:s, [self numberOfSelectedPubs]]];
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


- (BOOL) validateOpenLinkedFileMenuItem:(NSMenuItem*) menuItem {
	NSString * s;
	BibItem *selectedBI = nil;
	NSString *lurl = nil;
	
	if ([self numberOfSelectedPubs] == 0) {
		// no selection
		s = NSLocalizedString(@"Open Linked File", @"Open Linked File");
		[menuItem setTitle:s];
		return NO;
	}
	else if ([self numberOfSelectedPubs] == 1) {
		// single selection
		s = NSLocalizedString(@"Open Linked File", @"Open Linked File");
		[menuItem setTitle:s];
		selectedBI = [shownPublications objectAtIndex:[[[self selectedPublications] objectAtIndex:0] intValue] usingLock:pubsLock];
		lurl = [selectedBI localURLPath];
		return (lurl && [[NSFileManager defaultManager] fileExistsAtPath:lurl]);
	}
	else {
		s = NSLocalizedString(@"Open %i Linked Files", @"Open %i Linked Files");
		[menuItem setTitle:[NSString stringWithFormat:s, [self numberOfSelectedPubs]]];
		NSEnumerator *e = [self selectedPubEnumerator];
		NSNumber *i;
		while(i = [e nextObject]){
			selectedBI = [shownPublications objectAtIndex:[[[self selectedPublications] objectAtIndex:0] intValue] usingLock:pubsLock];
			lurl = [selectedBI localURLPath];
			if (lurl && [[NSFileManager defaultManager] fileExistsAtPath:lurl])
				return YES;
		}
		return NO;
	}
}	

- (BOOL) validateRevealLinkedFileMenuItem:(NSMenuItem*) menuItem {
	NSString * s;
	BibItem *selectedBI = nil;
	NSString *lurl = nil;
	
	if ([self numberOfSelectedPubs] == 0) {
		// no selection
		s = NSLocalizedString(@"Reveal Linked File in Finder", @"Reveal Linked File in Finder");
		[menuItem setTitle:s];
		return NO;
	}
	else if ([self numberOfSelectedPubs] == 1) {
		// single selection
		s = NSLocalizedString(@"Reveal Linked File in Finder", @"Reveal Linked File in Finder");
		[menuItem setTitle:s];
		selectedBI = [shownPublications objectAtIndex:[[[self selectedPublications] objectAtIndex:0] intValue] usingLock:pubsLock];
		lurl = [selectedBI localURLPath];
		return (lurl && [[NSFileManager defaultManager] fileExistsAtPath:lurl]);
	}
	else {
		s = NSLocalizedString(@"Reveal %i Linked Files in Finder", @"Reveal %i Linked Files in Finder");
		[menuItem setTitle:[NSString stringWithFormat:s, [self numberOfSelectedPubs]]];
		NSEnumerator *e = [self selectedPubEnumerator];
		NSNumber *i;
		while(i = [e nextObject]){
			selectedBI = [shownPublications objectAtIndex:[[[self selectedPublications] objectAtIndex:0] intValue] usingLock:pubsLock];
			lurl = [selectedBI localURLPath];
			if (lurl && [[NSFileManager defaultManager] fileExistsAtPath:lurl])
				return YES;
		}
		return NO;
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
		s = [NSString stringWithFormat:@"%@%C",NSLocalizedString(@"Consolidate Linked Files", @"Consolidate Linked Files..."),0x2026];
		[menuItem setTitle:s];
		return NO;
	}
	else if ([self numberOfSelectedPubs] == 1) {
		// single selection
		NSString * citeKey = [(BibItem*)[shownPublications objectAtIndex:[[[self selectedPubEnumerator] nextObject] intValue]] citeKey];
		s = [NSString stringWithFormat:@"%@%C",NSLocalizedString(@"Consolidate Linked File for %@", @"Consolidate Linked File for %@..."),0x2026];
		[menuItem setTitle:[NSString stringWithFormat:s, citeKey]];
		return YES;
	}
	else {
		s = [NSString stringWithFormat:@"%@%C",NSLocalizedString(@"Consolidate %i Linked Files", @"Consolidate %i Linked Files..."),0x2026];
		[menuItem setTitle:[NSString stringWithFormat:s, [self numberOfSelectedPubs]]];
		return YES;
	}
}	


- (BOOL) validateDeleteSelectionMenuItem:(NSMenuItem*) menuItem {
	NSString * s;
	int n = [self numberOfSelectedPubs];
	
	if (n <= 1) {
		// no selection or single selection
		s = NSLocalizedString(@"Delete", @"Delete");
		[menuItem setTitle:s];
		return (n==1);
	}
	else {
		// multiple selection
		s = NSLocalizedString(@"Delete %i Publications", @"Delete %i Publications");
		[menuItem setTitle:[NSString stringWithFormat:s, n]];
		return YES;
	}
}	



- (BOOL) validatePrintDocumentMenuItem:(NSMenuItem*) menuItem {
	// change name of menu item to indicate that we are only printing the selection?
    if ([self numberOfSelectedPubs] == 0){
		// no selection => no printing
		return NO;
	}
	else {
		return YES;
	}
}



- (BOOL) validateToggleStatusBarMenuItem:(NSMenuItem*) menuItem {
    NSString *s;
	if (showStatus){
		s = NSLocalizedString(@"Hide Status Bar", @"Hide Status Bar");
		[menuItem setTitle:s];
	}
	else {
		s = NSLocalizedString(@"Show Status Bar", @"Show Status Bar");
		[menuItem setTitle:s];
	}
	return YES;
}



- (BOOL) validateNewPubFromPasteboardMenuItem:(NSMenuItem*) menuItem {
    NSString *s = [NSString stringWithFormat:@"%@%C", NSLocalizedString(@"New Publications from Pasteboard",@"New Publications from Pasteboard"),0x2026];
	[menuItem setTitle:s];
	return YES;
}



- (BOOL) validateNewPubFromFileMenuItem:(NSMenuItem*) menuItem {
    NSString *s = [NSString stringWithFormat:@"%@%C", NSLocalizedString(@"New Publications from File",@"New Publications from File"),0x2026];
	[menuItem setTitle:s];
	return YES;
}



- (BOOL) validateNewPubFromWebMenuItem:(NSMenuItem*) menuItem {
    NSString *s = [NSString stringWithFormat:@"%@%C", NSLocalizedString(@"New Publications from Web",@"New Publications from Web"),0x2026];
	[menuItem setTitle:s];
	return YES;
}


- (BOOL)validateSelectCrossrefParentMenuItem:(NSMenuItem *)menuItem{
    NSString *s = NSLocalizedString(@"Select Parent Publication", @"Select the crossref parent of this pub");
    [menuItem setTitle:s];
    if([self numberOfSelectedPubs] == 1){
        BibItem *selectedBI = [shownPublications objectAtIndex:[[[self selectedPublications] lastObject] intValue]];
        
        if([selectedBI valueOfField:BDSKCrossrefString inherit:NO] &&
           ![[selectedBI valueOfField:BDSKCrossrefString inherit:NO] isEqualToString:@""])
                return YES;
    }
	return NO;
}

- (BOOL)validateCreateNewPubUsingCrossrefMenuItem:(NSMenuItem *)menuItem{
    NSString *s = NSLocalizedString(@"New Publication With Crossref", @"New publication with this pub as parent");
    [menuItem setTitle:s];
    if([self numberOfSelectedPubs] == 1){
        BibItem *selectedBI = [shownPublications objectAtIndex:[[[self selectedPublications] lastObject] intValue]];
        
        // only valid if the selected pub (parent-to-be) doesn't have a crossref field
        if([selectedBI valueOfField:BDSKCrossrefString inherit:NO] == nil ||
           [[selectedBI valueOfField:BDSKCrossrefString inherit:NO] isEqualToString:@""])
                return YES;
    }
	return NO;
}

- (BOOL)validateDuplicateMenuItem:(NSMenuItem *)menuItem{
	if ([self numberOfSelectedPubs] == 0) {
		// no selection
		return NO;
	}
	else {
		// multiple selection
		return YES;
	}
} 

/* respond to the clear: action, so we can validate the Delete item in the edit menu.
*/
- (IBAction) clear:(id) sender {
	[self delPub:sender];
}


@end
