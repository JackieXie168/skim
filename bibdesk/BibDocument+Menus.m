//
//  BibDocument+Menus.m
//  BibDesk
//
//  Created by Sven-S. Porst on Fri Jul 30 2004.
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

#import "BibDocument+Menus.h"
#import "BDSKGroupCell.h"
#import "BDSKGroup.h"
#import "BibDocument_Groups.h"
#import "BDSKDragTableView.h"
#import "BDSKGroupTableView.h"
#import "BibItem.h"
#import "BibTypeManager.h"

@implementation BibDocument (Menus)

- (BOOL) validateCutMenuItem:(NSMenuItem*) menuItem {
	if ([documentWindow firstResponder] != tableView ||
		[self numberOfSelectedPubs] == 0) {
		// no selection
		return NO;
	}
	else {
		// multiple selection
		return YES;
	}
}	

- (BOOL) validateAlternateCutMenuItem:(NSMenuItem*) menuItem {
	if ([documentWindow firstResponder] != tableView ||
		[self numberOfSelectedPubs] == 0) {
		// no selection
		return NO;
	}
	else {
		// multiple selection
		return YES;
	}
}	

- (BOOL) validateCopyMenuItem:(NSMenuItem*) menuItem {
	if ([documentWindow firstResponder] != tableView ||
		[self numberOfSelectedPubs] == 0) {
		// no selection
		return NO;
	}
	else {
		// multiple selection
		return YES;
	}
}	

- (BOOL) validateCopyAsMenuItem:(NSMenuItem*) menuItem {
	int copyType = [menuItem tag];
	NSString *s = nil;
	NSString *copyString = NSLocalizedString(@"Copy", @"Copy");
	int n = [self numberOfSelectedPubs];
	
	switch (copyType) {
		case BDSKBibTeXDragCopyType:
			if (n <= 1)
				s = NSLocalizedString(@"BibTeX Record", @"BibTeX Record");
			else
				s = NSLocalizedString(@"BibTeX Records", @"BibTeX Records");
			break;
		case BDSKCiteDragCopyType:
			do {
				OFPreferenceWrapper *sud = [OFPreferenceWrapper sharedPreferenceWrapper];
				// figure out correct name for TeX as chosen in prefs
				NSString *startCiteBracket = [sud stringForKey:BDSKCiteStartBracketKey]; 
				NSString *TeXName = (![startCiteBracket isEqualToString:@"["]) ? @"TeX" : @"ConTeXt";
				if (n <= 1)
					s = [NSString stringWithFormat:NSLocalizedString(@"%@ \\cite Command", @"%@ \\cite Command"), TeXName];
				else if ([sud boolForKey:BDSKSeparateCiteKey]) 
					s = [NSString stringWithFormat:NSLocalizedString(@"%i %@ \\cite Commands", @"%i %@ \\cite Commands"), n, TeXName];
				else
					s = [NSString stringWithFormat:NSLocalizedString(@"%@ \\cite Command for %i Items", @"%@ \\cite Command for %i Items"), TeXName, n];
			} while (0);
			break;
		case BDSKPDFDragCopyType:
			if (n <= 1)
				s = NSLocalizedString(@"PDF", @"PDF");
			else
				s = [NSString stringWithFormat:NSLocalizedString(@"PDF for %i Items", @"PDF for %i Items"), n];
			break;
		case BDSKRTFDragCopyType:
			if (n <= 1)
				s = NSLocalizedString(@"Text", @"Text");
			else
				s = [NSString stringWithFormat:NSLocalizedString(@"Text for %i Items", @"Text for %i Items"), n];
			break;
		case BDSKLaTeXDragCopyType:
			if (n <= 1)
				s = NSLocalizedString(@"LaTeX", @"LaTeX");
			else
				s = [NSString stringWithFormat:NSLocalizedString(@"LaTeX for %i Items", @"LaTeX for %i Items"), n];
			break;
		case BDSKLTBDragCopyType:
			if (n <= 1)
				s = NSLocalizedString(@"Amsrefs LaTeX", @"Amsrefs LaTeX");
			else
				s = [NSString stringWithFormat:NSLocalizedString(@"Amsrefs LaTeX for %i Items", @"Amsrefs LaTeX for %i Items"), n];
			break;
		case BDSKMinimalBibTeXDragCopyType:
			if (n <= 1)
				s = NSLocalizedString(@"Minimal BibTeX Record", @"Minimal BibTeX Record");
			else
				s = [NSString stringWithFormat:NSLocalizedString(@"%i Minimal BibTeX Records", @"%i Minimal BibTeX Records"), n];
			break;
		case BDSKRISDragCopyType:
			if (n <= 1)
				s = NSLocalizedString(@"RIS Record", @"RIS Record");
			else
				s = [NSString stringWithFormat:NSLocalizedString(@"%i RIS Records", @"%i RIS Records"), n];
			break;
	}
	
	if (n == 0) {
		// no selection
		if (![[menuItem menu] supermenu]) {
			s = [NSString stringWithFormat:@"%@ %@", copyString, s];
		}
		[menuItem setTitle:s];
		return NO;
	}
	else if (n == 1) {
		// single selection
		NSString *forString = NSLocalizedString(@"for", @"for");
		NSString *citeKey = [(BibItem*)[[self selectedPublications] objectAtIndex:0] citeKey];
		if ([[menuItem menu] supermenu]) {
			s = [NSString stringWithFormat:@"%@ %@ %@", s, forString, citeKey];
		}
		else {
			s = [NSString stringWithFormat:@"%@ %@ %@ %@", copyString, s, forString, citeKey];
		}
		[menuItem setTitle:s];
		return YES;
	}
	else {
		// multiple selection
		if (![[menuItem menu] supermenu]) {
			s = [NSString stringWithFormat:@"%@ %@", copyString, s];
		}
		[menuItem setTitle:s];
		return YES;
	}
}

- (BOOL)validatePasteMenuItem:(NSMenuItem *)menuItem{
	return ([documentWindow firstResponder] != tableView ? NO : YES);
}

- (BOOL)validateDuplicateMenuItem:(NSMenuItem *)menuItem{
	if ([documentWindow firstResponder] != tableView ||
		[self numberOfSelectedPubs] == 0)
		return NO;
	return YES;
}

- (BOOL) validateEditSelectionMenuItem:(NSMenuItem*) menuItem {
	NSString * s;
	
	if ([self numberOfSelectedPubs] == 0) {
		// no selection
		if (![[menuItem menu] supermenu]) {
			s = NSLocalizedString(@"Get Info", @"Get Info");
			[menuItem setTitle:s];
		}
		return NO;
	}
	else if ([self numberOfSelectedPubs] == 1) {
		// single selection
		if (![[menuItem menu] supermenu]) {
			s = NSLocalizedString(@"Get Info for Publication", @"Get Info for Publication");
			[menuItem setTitle:s];
		}
		return YES;
	}
	else {
		if (![[menuItem menu] supermenu]) {
			s = NSLocalizedString(@"Get Info for %i Publications", @"Get Info for %i Publications");
			[menuItem setTitle:[NSString stringWithFormat:s, [self numberOfSelectedPubs]]];
		}
		return YES;
	}
}

- (BOOL) validateDeleteSelectionMenuItem:(NSMenuItem*) menuItem {
	NSString * s;
	int n = [self numberOfSelectedPubs];
	
	if (n == 0) {
		// no selection
		if (![[menuItem menu] supermenu]) {
			s = NSLocalizedString(@"Delete", @"Delete");
			[menuItem setTitle:s];
		}
		return NO;
	}
	else if (n == 1) {
		// single selection
		if (![[menuItem menu] supermenu]) {
			s = NSLocalizedString(@"Delete Publication", @"Delete Publication");
			[menuItem setTitle:s];
		}
		return YES;
	}
	else {
		// multiple selection
		if (![[menuItem menu] supermenu]) {
			s = NSLocalizedString(@"Delete %i Publications", @"Delete %i Publications");
			[menuItem setTitle:[NSString stringWithFormat:s, n]];
		}
		return YES;
	}
}	
		
- (BOOL) validateRemoveSelectionMenuItem:(NSMenuItem*) menuItem {
	NSString * s;
	int n = [self numberOfSelectedPubs];
	int m = 0; // number of non-smart groups
	NSArray *selectedGroups = [self selectedGroups];
    
    // don't remove from single valued group field, as that will clear the field, which is most probably a mistake. See bug # 1435344
	if([selectedGroups containsObject:allPublicationsGroup]) {
        return [self validateDeleteSelectionMenuItem:menuItem];
    } else if ([[[BibTypeManager sharedManager] singleValuedGroupFields] containsObject:[self currentGroupField]] == NO) {
        NSEnumerator *groupEnum = [selectedGroups objectEnumerator];
        BDSKGroup *group;
        while (group = [groupEnum nextObject]) {
             if([group isSmart] == NO)
                m++;
        }
    }
	
	if (n == 0 || m == 0) {
		// no selection
		if (![[menuItem menu] supermenu]) {
			s = NSLocalizedString(@"Remove from Group", @"Remove from Group");
			[menuItem setTitle:s];
		}
		return NO;
	}
	else if (n == 1) {
		// single selection
		if (![[menuItem menu] supermenu]) {
			if (m == 1)
				s = NSLocalizedString(@"Remove Publication from Group", @"Remove Publication from Groups");
			else
				s = NSLocalizedString(@"Remove Publication from Groups", @"Remove Publication from Groups");
			[menuItem setTitle:s];
		}
		return YES;
	}
	else {
		// multiple selection
		if (![[menuItem menu] supermenu]) {
			if (m == 1)
				s = NSLocalizedString(@"Remove %i Publications from Group", @"Remove %i Publications from Group");
			else
				s = NSLocalizedString(@"Remove %i Publications from Groups", @"Remove %i Publications from Groups");
			[menuItem setTitle:[NSString stringWithFormat:s, n]];
		}
		return YES;
	}
}	

- (BOOL) validateOpenLinkedFileMenuItem:(NSMenuItem*) menuItem {
	NSString * s;
	NSString *field = [menuItem representedObject];
	BibItem *selectedBI = nil;
	NSString *lurl = nil;
    if (field == nil)
		field = BDSKLocalUrlString;
	
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
		selectedBI = [[self selectedPublications] objectAtIndex:0];
		lurl = [selectedBI localFilePathForField:field];
		return (lurl && [[NSFileManager defaultManager] fileExistsAtPath:lurl]);
	}
	else {
		s = NSLocalizedString(@"Open %i Linked Files", @"Open %i Linked Files");
		[menuItem setTitle:[NSString stringWithFormat:s, [self numberOfSelectedPubs]]];
		NSEnumerator *e = [[self selectedPublications] objectEnumerator];
		while(selectedBI = [e nextObject]){
			lurl = [selectedBI localFilePathForField:field];
			if (lurl && [[NSFileManager defaultManager] fileExistsAtPath:lurl])
				return YES;
		}
		return NO;
	}
}	

- (BOOL) validateRevealLinkedFileMenuItem:(NSMenuItem*) menuItem {
	NSString * s;
	NSString *field = [menuItem representedObject];
	BibItem *selectedBI = nil;
	NSString *lurl = nil;
    if (field == nil)
		field = BDSKLocalUrlString;
	
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
		selectedBI = [[self selectedPublications] objectAtIndex:0];
		lurl = [selectedBI localFilePathForField:field];
		return (lurl && [[NSFileManager defaultManager] fileExistsAtPath:lurl]);
	}
	else {
		s = NSLocalizedString(@"Reveal %i Linked Files in Finder", @"Reveal %i Linked Files in Finder");
		[menuItem setTitle:[NSString stringWithFormat:s, [self numberOfSelectedPubs]]];
		NSEnumerator *e = [[self selectedPublications] objectEnumerator];
		while(selectedBI = [e nextObject]){
			lurl = [selectedBI localFilePathForField:field];
			if (lurl && [[NSFileManager defaultManager] fileExistsAtPath:lurl])
				return YES;
		}
		return NO;
	}
}	
- (BOOL) validateOpenRemoteURLMenuItem:(NSMenuItem*) menuItem {
	NSString * s;
	NSString *field = [menuItem representedObject];
	BibItem *selectedBI = nil;
	NSURL *url = nil;
    if (field == nil)
		field = BDSKUrlString;
	
	if ([self numberOfSelectedPubs] == 0) {
		// no selection
		s = NSLocalizedString(@"Open URL in Browser", @"Open URL in Browser");
		[menuItem setTitle:s];
		return NO;
	}
	else if ([self numberOfSelectedPubs] == 1) {
		// single selection
		s = NSLocalizedString(@"Open URL in Browser", @"Open URL in Browser");
		[menuItem setTitle:s];
		selectedBI = [[self selectedPublications] objectAtIndex:0];
		url = [selectedBI remoteURLForField:field];
		return (url != nil);
	}
	else {
		s = NSLocalizedString(@"Open %i URLs in Browser", @"Open %i URLs in Browser");
		[menuItem setTitle:[NSString stringWithFormat:s, [self numberOfSelectedPubs]]];
		NSEnumerator *e = [[self selectedPublications] objectEnumerator];
		while(selectedBI = [e nextObject]){
			url = [selectedBI remoteURLForField:field];
			if (url != nil)
				return YES;
		}
		return NO;
	}
}	
- (BOOL) validateDuplicateTitleToBooktitleMenuItem:(NSMenuItem*) menuItem {
	NSString * s;
	
	if ([self numberOfSelectedPubs] == 0) {
		// no selection
		s = NSLocalizedString(@"Duplicate Title to Booktitle", @"Duplicate Title to Booktitle");
		[menuItem setTitle:s];
		return NO;
	}
	else if ([self numberOfSelectedPubs] == 1) {
		// single selection
		s = NSLocalizedString(@"Duplicate Title to Booktitle", @"Duplicate Title to Booktitle");
		[menuItem setTitle:[NSString stringWithFormat:s]];
		return YES;
	}
	else {
		s = NSLocalizedString(@"Duplicate %i Titles to Booktitles", @"Duplicate %i Titles to Booktitles");
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
		s = [NSString stringWithFormat:@"%@%C",NSLocalizedString(@"Consolidate Linked Files", @"Consolidate Linked Files..."),0x2026];
		[menuItem setTitle:s];
		return NO;
	}
	else if ([self numberOfSelectedPubs] == 1) {
		// single selection
		NSString * citeKey = [(BibItem*)[[self selectedPublications] objectAtIndex:0] citeKey];
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

- (BOOL) validateToggleToggleCustomCiteDrawerMenuItem:(NSMenuItem*) menuItem {
    NSString *s;
	if(showingCustomCiteDrawer){
		s = NSLocalizedString(@"Hide Custom \\cite Commands",@"");
		[menuItem setTitle:s];
	}else{
		s = NSLocalizedString(@"Show Custom \\cite Commands",@"should be the same as in the nib");
		[menuItem setTitle:s];
	}
	return YES;
}

- (BOOL) validateToggleStatusBarMenuItem:(NSMenuItem*) menuItem {
    NSString *s;
	if ([statusBar isVisible]){
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
    NSString *s = [NSString stringWithFormat:@"%@%C", NSLocalizedString(@"New Publications from Clipboard",@"New Publications from Clipboard"),0x2026];
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
        BibItem *selectedBI = [[self selectedPublications] objectAtIndex:0];
        if(![NSString isEmptyString:[selectedBI valueOfField:BDSKCrossrefString inherit:NO]])
            return YES;
    }
	return NO;
}

- (BOOL)validateCreateNewPubUsingCrossrefMenuItem:(NSMenuItem *)menuItem{
    NSString *s = NSLocalizedString(@"New Publication With Crossref", @"New publication with this pub as parent");
    [menuItem setTitle:s];
    if([self numberOfSelectedPubs] == 1){
        BibItem *selectedBI = [[self selectedPublications] objectAtIndex:0];
        
        // only valid if the selected pub (parent-to-be) doesn't have a crossref field
        if([NSString isEmptyString:[selectedBI valueOfField:BDSKCrossrefString inherit:NO]])
            return YES;
    }
	return NO;
}

- (BOOL) validateSortGroupsByGroupMenuItem:(NSMenuItem *)menuItem{
	if([sortGroupsKey isEqualToString:BDSKGroupCellStringKey]){
		[menuItem setState:NSOnState];
	}else{
		[menuItem setState:NSOffState];
	}
	return YES;
} 

- (BOOL) validateSortGroupsByCountMenuItem:(NSMenuItem *)menuItem{
	if([sortGroupsKey isEqualToString:BDSKGroupCellCountKey]){
		[menuItem setState:NSOnState];
	}else{
		[menuItem setState:NSOffState];
	}
	return YES;
} 

- (BOOL) validateChangeGroupFieldMenuItem:(NSMenuItem *)menuItem{
	if([[menuItem title] isEqualToString:[self currentGroupField]])
		[menuItem setState:NSOnState];
	else
		[menuItem setState:NSOffState];
	return YES;
} 

- (BOOL) validateRemoveSmartGroupMenuItem:(NSMenuItem *)menuItem{
	int row = [smartGroups count] + 1;
	int n = 0;
	while (--row) {
		if ([groupTableView isRowSelected:row])
			n++;
	}
	
	NSString *s = @"";
	
	if (n == 0) {
		// no smart group selected
		if (![[menuItem menu] supermenu]) {
			s = NSLocalizedString(@"Remove Smart Group", @"Remove smart group");
			[menuItem setTitle:s];
		}
		return NO;
	} else if (n == 1) {
		// single smart group selected
		if (![[menuItem menu] supermenu]) {
			s = NSLocalizedString(@"Remove Smart Group", @"Remove smart group");
			[menuItem setTitle:s];
		}
		return YES;
	} else {
		// multiple smart groups selected
		if (![[menuItem menu] supermenu]) {
			s = NSLocalizedString(@"Remove %i Smart Groups", @"Remove %i smart groups");
			[menuItem setTitle:[NSString stringWithFormat:s, n]];
		}
		return YES;
	}
} 

- (BOOL) validateRenameGroupMenuItem:(NSMenuItem *)menuItem{
	
	if ([groupTableView numberOfSelectedRows] == 1 &&
		[groupTableView selectedRow] > 0) {
		// single group selection
		return YES;
	} else {
		// multiple selection or no group selected
		return NO;
	}
} 

- (BOOL) validateEditGroupMenuItem:(NSMenuItem *)menuItem{
	int row = [groupTableView selectedRow];
	if ([groupTableView numberOfSelectedRows] == 1 && row > 0) {
		// single smart group selection
		if (row <= [smartGroups count] || [currentGroupField isEqualToString:BDSKAuthorString] || [currentGroupField isEqualToString:BDSKEditorString])
			return YES;
		else
			return NO;
	} else {
		// multiple selection or no smart group selected
		return NO;
	}
} 

- (BOOL) validateEditActionMenuItem:(NSMenuItem *)menuItem{
	id firstResponder = [documentWindow firstResponder];
	if (firstResponder == tableView) {
		return [self validateEditSelectionMenuItem:menuItem];
	} else if (firstResponder == groupTableView) {
		return [self validateEditGroupMenuItem:menuItem];
	} else {
		return NO;
	}
} 

- (BOOL) validateDeleteMenuItem:(NSMenuItem*) menuItem {
	id firstResponder = [documentWindow firstResponder];
	if (firstResponder == tableView) {
		return [self validateRemoveSelectionMenuItem:menuItem];
	} else if (firstResponder == groupTableView) {
		return [self validateRemoveSmartGroupMenuItem:menuItem];
	} else {
		return NO;
	}
}

- (BOOL) validateAlternateDeleteMenuItem:(NSMenuItem*) menuItem {
	id firstResponder = [documentWindow firstResponder];
	if (firstResponder == tableView) {
		return [self validateDeleteSelectionMenuItem:menuItem];
	} else if (firstResponder == groupTableView) {
		return [self validateRemoveSmartGroupMenuItem:menuItem];
	} else {
		return NO;
	}
}

- (BOOL) validateSelectPossibleDuplicatesMenuItem:(NSMenuItem *)menuItem{
    [menuItem setTitle:[NSLocalizedString(@"Select Duplicates by ", @"for selecting duplicate publications; requires a single trailing space") stringByAppendingString:[lastSelectedColumnForSort identifier]]];
    return YES;
}

- (BOOL)validateFindPanelActionMenuItem:(NSMenuItem *)menuItem {
	switch ([menuItem tag]) {
		case NSFindPanelActionSetFindString:
			return YES;
		default:
			return NO;
	}
}

- (BOOL)validateEditNewGroupWithSelectionMenuItem:(NSMenuItem *)menuItem {
    return ([self numberOfSelectedPubs] > 0 && [[[BibTypeManager sharedManager] singleValuedGroupFields] containsObject:[self currentGroupField]]  == NO && [[[BibTypeManager sharedManager] personFieldsSet] containsObject:[self currentGroupField]] == NO);
}

- (BOOL) validateMenuItem:(NSMenuItem*)menuItem{
	SEL act = [menuItem action];

	if (act == @selector(cut:)) {
		return [self validateCutMenuItem:menuItem];
	}
	else if (act == @selector(alternateCut:)) {
		return [self validateAlternateCutMenuItem:menuItem];
	}
	else if (act == @selector(copy:)) {
		return [self validateCopyMenuItem:menuItem];
	}
	else if (act == @selector(copyAsAction:)) {
		return [self validateCopyAsMenuItem:menuItem];
	}
    else if (act == @selector(paste:)) {
		// called through NSTableView_BDSKExtensions
        return [self validatePasteMenuItem:menuItem];
	}
    else if (act == @selector(duplicate:)) {
        return [self validateDuplicateMenuItem:menuItem];
	}
	else if (act == @selector(editPubCmd:)) {
		return [self validateEditSelectionMenuItem:menuItem];
	}
	else if (act == @selector(duplicateTitleToBooktitle:)) {
		return [self validateDuplicateTitleToBooktitleMenuItem:menuItem];
	}
	else if (act == @selector(generateCiteKey:)) {
		return [self validateGenerateCiteKeyMenuItem:menuItem];
	}
	else if (act == @selector(consolidateLinkedFiles:)) {
		return [self validateConsolidateLinkedFilesMenuItem:menuItem];
	}
	else if (act == @selector(removeSelectedPubs:)) {
		return [self validateRemoveSelectionMenuItem:menuItem];
	}
	else if (act == @selector(deleteSelectedPubs:)) {
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
	else if(act == @selector(openRemoteURL:)) {
		return [self validateOpenRemoteURLMenuItem:menuItem];
	}
	else if(act == @selector(toggleShowingCustomCiteDrawer:)) {
		return [self validateToggleToggleCustomCiteDrawerMenuItem:menuItem];
	}
	else if (act == @selector(printDocument:)) {
		return [self validatePrintDocumentMenuItem:menuItem];
	}
	else if (act == @selector(columnsMenuSelectTableColumn:)) {
		return ([[menuItem menu] numberOfItems] > 3);
	}
	else if (act == @selector(toggleStatusBar:)) {
		return [self validateToggleStatusBarMenuItem:menuItem];
	}
	else if (act == @selector(importFromPasteboardAction:)) {
		return [self validateNewPubFromPasteboardMenuItem:menuItem];
	}
	else if (act == @selector(importFromFileAction:)) {
		return [self validateNewPubFromFileMenuItem:menuItem];
	}
	else if (act == @selector(importFromWebAction:)) {
		return [self validateNewPubFromWebMenuItem:menuItem];
	}
	else if (act == @selector(selectCrossrefParentAction:)) {
        return [self validateSelectCrossrefParentMenuItem:menuItem];
	}
	else if (act == @selector(createNewPubUsingCrossrefAction:)) {
        return [self validateCreateNewPubUsingCrossrefMenuItem:menuItem];
	}
	else if (act == @selector(sortGroupsByGroup:)) {
        return [self validateSortGroupsByGroupMenuItem:menuItem];
	}
	else if (act == @selector(sortGroupsByCount:)) {
        return [self validateSortGroupsByCountMenuItem:menuItem];
	}
	else if (act == @selector(changeGroupFieldAction:)) {
        return [self validateChangeGroupFieldMenuItem:menuItem];
	}
	else if (act == @selector(removeSmartGroupAction:)) {
        return [self validateRemoveSmartGroupMenuItem:menuItem];
	}
	else if (act == @selector(editGroupAction:)) {
        return [self validateEditGroupMenuItem:menuItem];
	}
	else if (act == @selector(renameGroupAction:)) {
        return [self validateRenameGroupMenuItem:menuItem];
	}
	else if (act == @selector(removeGroupFieldAction:)) {
		// don't allow the removal of the last item
        return ([[menuItem menu] numberOfItems] > 4);
	}
	else if (act == @selector(editAction:)) {
        return [self validateEditActionMenuItem:menuItem];
	}
	else if (act == @selector(delete:)) {
		// called through NSTableView_BDSKExtensions
		return [self validateDeleteMenuItem:menuItem];
    }
	else if (act == @selector(alternateDelete:)) {
		return [self validateAlternateDeleteMenuItem:menuItem];
    }
	else if (act == @selector(selectPossibleDuplicates:)){
        return [self validateSelectPossibleDuplicatesMenuItem:menuItem];
    }
	else if (act == @selector(performFindPanelAction:)){
        return [self validateFindPanelActionMenuItem:menuItem];
    }
    else if (act == @selector(editNewGroupWithSelection:)){
        return [self validateEditNewGroupWithSelectionMenuItem:menuItem];
    }
    else {
		return [super validateMenuItem:menuItem];
    }
}

@end
