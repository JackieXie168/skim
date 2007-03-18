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
#import "BDSKMainTableView.h"
#import "BDSKGroupTableView.h"
#import "BibItem.h"
#import "BibTypeManager.h"
#import "BDSKTemplate.h"

@implementation BibDocument (Menus)

- (BOOL) validateCutMenuItem:(NSMenuItem*) menuItem {
    if ([documentWindow isKeyWindow] == NO)
        return NO;
	if ([documentWindow firstResponder] != tableView ||
		[self numberOfSelectedPubs] == 0 ||
        [self hasSharedGroupsSelected] == YES) {
		// no selection or selection includes shared groups
		return NO;
	}
	else {
		// multiple selection
		return YES;
	}
}	

- (BOOL) validateAlternateCutMenuItem:(NSMenuItem*) menuItem {
    if ([documentWindow isKeyWindow] == NO)
        return NO;
	if ([documentWindow firstResponder] != tableView ||
		[self numberOfSelectedPubs] == 0 ||
        [self hasSharedGroupsSelected] == YES) {
		// no selection
		return NO;
	}
	else {
		// multiple selection
		return YES;
	}
}	

- (BOOL) validateCopyMenuItem:(NSMenuItem*) menuItem {
    if ([documentWindow isKeyWindow] == NO)
        return NO;
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
    OFPreferenceWrapper *sud = [OFPreferenceWrapper sharedPreferenceWrapper];
    BOOL usesTeX = [sud boolForKey:BDSKUsesTeXKey];
	int copyType = [menuItem tag];
	NSString *s = nil;
	NSString *copyString = NSLocalizedString(@"Copy", @"Copy");
	int n = [self numberOfSelectedPubs];
	
	switch (copyType) {
		case BDSKBibTeXDragCopyType:
			if (n <= 1)
				s = NSLocalizedString(@"BibTeX Record", @"BibTeX Record");
			else
				s = [NSString stringWithFormat:NSLocalizedString(@"%i BibTeX Records", @"%i BibTeX Records"), n];
			break;
		case BDSKCiteDragCopyType:
			do {
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
            if (usesTeX == NO)
                n = 0;
			if (n <= 1)
				s = NSLocalizedString(@"PDF", @"PDF");
			else
				s = [NSString stringWithFormat:NSLocalizedString(@"PDF for %i Items", @"PDF for %i Items"), n];
			break;
		case BDSKRTFDragCopyType:
            if (usesTeX == NO)
                n = 0;
			if (n <= 1)
				s = NSLocalizedString(@"Text", @"Text");
			else
				s = [NSString stringWithFormat:NSLocalizedString(@"Text for %i Items", @"Text for %i Items"), n];
			break;
		case BDSKLaTeXDragCopyType:
            if (usesTeX == NO)
                n = 0;
			if (n <= 1)
				s = NSLocalizedString(@"LaTeX", @"LaTeX");
			else
				s = [NSString stringWithFormat:NSLocalizedString(@"LaTeX for %i Items", @"LaTeX for %i Items"), n];
			break;
		case BDSKLTBDragCopyType:
            if (usesTeX == NO)
                n = 0;
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
        default:
            return (n > 0);
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
	return ([documentWindow isKeyWindow] == YES && [documentWindow firstResponder] == tableView);
}

- (BOOL)validateExportMenuItem:(NSMenuItem *)menuItem{
    switch ([menuItem tag]) {
        case BDSKTemplateExportFileType:
            return ([[BDSKTemplate allStyleNames] count] != 0);
        case BDSKHTMLExportFileType:
            return ([[BDSKTemplate allStyleNamesForFileType:@"html"] count] != 0);
        case BDSKRSSExportFileType:
            return ([[BDSKTemplate allStyleNamesForFileType:@"rss"] count] != 0);
        case BDSKRTFExportFileType:
            return ([[BDSKTemplate allStyleNamesForFileType:@"rtf"] count] != 0);
        case BDSKRTFDExportFileType:
            return ([[BDSKTemplate allStyleNamesForFileType:@"rtfd"] count] != 0);
        case BDSKDocExportFileType:
            return ([[BDSKTemplate allStyleNamesForFileType:@"doc"] count] != 0);
        default:
            return YES;
    }
}

- (BOOL)validateExportSelectionMenuItem:(NSMenuItem *)menuItem{
    if ([self numberOfSelectedPubs] == 0)
        return NO;
    else
        return [self validateExportMenuItem:menuItem];
}

- (BOOL)validateDuplicateMenuItem:(NSMenuItem *)menuItem{
    if ([documentWindow isKeyWindow] == NO)
        return NO;
	if ([documentWindow firstResponder] != tableView ||
		[self numberOfSelectedPubs] == 0 ||
        [self hasSharedGroupsSelected] == YES)
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
	
	if (n == 0 ||
        [self hasSharedGroupsSelected] == YES) {
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
    NSIndexSet *selIndexes = [groupTableView selectedRowIndexes];
    
    // don't remove from single valued group field, as that will clear the field, which is most probably a mistake. See bug # 1435344
	if([selIndexes firstIndex] == 0) {
        return [self validateDeleteSelectionMenuItem:menuItem];
    } else {
        m = [self numberOfStaticGroupsAtIndexes:selIndexes];
        if ([[[BibTypeManager sharedManager] singleValuedGroupFields] containsObject:[self currentGroupField]] == NO)
            m += [self numberOfCategoryGroupsAtIndexes:selIndexes];
    }
	
	if (n == 0 || m == 0) {
		// no selection
		if (![[menuItem menu] supermenu]) {
			s = NSLocalizedString(@"Remove from Group", @"Remove from group");
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
	
	if ([self numberOfSelectedPubs] == 0 || 
        [documentWindow isKeyWindow] == NO || 
        [self hasSharedGroupsSelected] == YES) {
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
	
	if ([self numberOfSelectedPubs] == 0 || 
        [documentWindow isKeyWindow] == NO || 
        [self hasSharedGroupsSelected] == YES) {
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
	
	if ([self numberOfSelectedPubs] == 0 || 
        [documentWindow isKeyWindow] == NO || 
        [self hasSharedGroupsSelected] == YES) {
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
    if ([self numberOfSelectedPubs] == 0 || 
        [documentWindow isKeyWindow] == NO){
		// no selection => no printing
		return NO;
	}
	else {
		return YES;
	}
}

- (BOOL) validateToggleCustomCiteDrawerMenuItem:(NSMenuItem*) menuItem {
    NSString *s;
	if([customCiteDrawer state] == NSDrawerOpenState || [customCiteDrawer state] == NSDrawerOpeningState)
		s = NSLocalizedString(@"Hide Custom \\cite Commands",@"");
	else
		s = NSLocalizedString(@"Show Custom \\cite Commands",@"should be the same as in the nib");
    [menuItem setTitle:s];
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

- (BOOL)validateSortForCrossrefsMenuItem:(NSMenuItem *)menuItem{
    return ([self hasSharedGroupsSelected] == NO);
}

- (BOOL)validateSelectCrossrefParentMenuItem:(NSMenuItem *)menuItem{
    if([self numberOfSelectedPubs] == 1 && [self hasSharedGroupsSelected] == NO){
        BibItem *selectedBI = [[self selectedPublications] objectAtIndex:0];
        if(![NSString isEmptyString:[selectedBI valueOfField:BDSKCrossrefString inherit:NO]])
            return YES;
    }
	return NO;
}

- (BOOL)validateCreateNewPubUsingCrossrefMenuItem:(NSMenuItem *)menuItem{
    if([self numberOfSelectedPubs] == 1 && [self hasSharedGroupsSelected] == NO){
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

- (BOOL) validateRemoveSelectedGroupsMenuItem:(NSMenuItem *)menuItem{
    int n = [self numberOfSmartGroupsAtIndexes:[groupTableView selectedRowIndexes]];
    n += [self numberOfStaticGroupsAtIndexes:[groupTableView selectedRowIndexes]];
	
	NSString *s = @"";
	
	if (n == 0) {
		// no smart group selected
		if (![[menuItem menu] supermenu]) {
			s = NSLocalizedString(@"Remove Group", @"Remove group");
			[menuItem setTitle:s];
		}
		return NO;
	} else if (n == 1) {
		// single smart group selected
		if (![[menuItem menu] supermenu]) {
			s = NSLocalizedString(@"Remove Group", @"Remove group");
			[menuItem setTitle:s];
		}
		return YES;
	} else {
		// multiple smart groups selected
		if (![[menuItem menu] supermenu]) {
			s = NSLocalizedString(@"Remove %i Groups", @"Remove %i groups");
			[menuItem setTitle:[NSString stringWithFormat:s, n]];
		}
		return YES;
	}
} 

- (BOOL) validateRenameGroupMenuItem:(NSMenuItem *)menuItem{
	int row = [groupTableView selectedRow];
	if ([groupTableView numberOfSelectedRows] == 1 &&
		row > 0 &&
        [[self objectInGroupsAtIndex:row] hasEditableName]) {
		// single group selection
		return YES;
	} else {
		// multiple selection or no group selected
		return NO;
	}
} 

- (BOOL) validateEditGroupMenuItem:(NSMenuItem *)menuItem{
    if ([documentWindow isKeyWindow] == NO)
        return NO;
	int row = [groupTableView selectedRow];
	if ([groupTableView numberOfSelectedRows] == 1 && row > 0) {
		// single group selection
        return [[self objectInGroupsAtIndex:row] isEditable];
	} else {
		// multiple selection or no smart group selected
		return NO;
	}
} 

- (BOOL) validateEditActionMenuItem:(NSMenuItem *)menuItem{
    if ([documentWindow isKeyWindow] == NO) {
        [menuItem setTitle:NSLocalizedString(@"Get Info", @"Get Info")];
        return NO;
	}
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
    if ([documentWindow isKeyWindow] == NO)
        return NO;
    id firstResponder = [documentWindow firstResponder];
	if (firstResponder == tableView) {
		return [self validateRemoveSelectionMenuItem:menuItem];
	} else if (firstResponder == groupTableView) {
		return [self validateRemoveSelectedGroupsMenuItem:menuItem];
	} else {
		return NO;
	}
}

- (BOOL) validateAlternateDeleteMenuItem:(NSMenuItem*) menuItem {
    if ([documentWindow isKeyWindow] == NO)
        return NO;
	id firstResponder = [documentWindow firstResponder];
	if (firstResponder == tableView) {
		return [self validateDeleteSelectionMenuItem:menuItem];
	} else if (firstResponder == groupTableView) {
		return [self validateRemoveSelectedGroupsMenuItem:menuItem];
	} else {
		return NO;
	}
}

- (BOOL)validateSelectAllPublicationsMenuItem:(NSMenuItem *)menuItem{
    return ([documentWindow isKeyWindow] == YES);
}

- (BOOL)validateDeselectAllPublicationsMenuItem:(NSMenuItem *)menuItem{
    return ([documentWindow isKeyWindow] == YES);
}

- (BOOL)validateSelectAllPublicationsGroupMenuItem:(NSMenuItem *)menuItem{
    return ([documentWindow isKeyWindow] == YES);
}

- (BOOL) validateSelectDuplicatesMenuItem:(NSMenuItem *)menuItem{
    return ([self hasSharedGroupsSelected] == NO);
}

- (BOOL) validateSelectPossibleDuplicatesMenuItem:(NSMenuItem *)menuItem{
    [menuItem setTitle:[NSLocalizedString(@"Select Duplicates by ", @"for selecting duplicate publications; requires a single trailing space") stringByAppendingString:[lastSelectedColumnForSort identifier]]];
    return ([self hasSharedGroupsSelected] == NO);
}

- (BOOL)validateFindPanelActionMenuItem:(NSMenuItem *)menuItem {
	switch ([menuItem tag]) {
		case NSFindPanelActionShowFindPanel:
		case NSFindPanelActionSetFindString:
			return YES;
		default:
			return NO;
	}
}

- (BOOL)validateEditNewGroupWithSelectionMenuItem:(NSMenuItem *)menuItem {
    NSString *s;
    if ([self hasSharedGroupsSelected])
        s = NSLocalizedString(@"New Group With Merged Selection", @"New group with merged selection");
    else
        s = NSLocalizedString(@"New Group With Selection", @"New group with selection");
    [menuItem setTitle:s];
    return ([self numberOfSelectedPubs] > 0);
}

- (BOOL)validateRevertDocumentToSavedMenuItem:(NSMenuItem *)menuItem {
    return [self isDocumentEdited];
}

- (BOOL)validateChangePreviewDisplayMenuItem:(NSMenuItem *)menuItem {
    [menuItem setState:([menuItem tag] == [[OFPreferenceWrapper sharedPreferenceWrapper] integerForKey:BDSKPreviewDisplayKey]) ? NSOnState : NSOffState];
    if ([menuItem tag] == 3 && [[BDSKTemplate allStyleNamesForFileType:@"rtf"] count] == 0)
        return NO;
    return YES;
}

- (BOOL)validateChangeIntersectGroupsMenuItem:(NSMenuItem *)menuItem {
    [menuItem setState: ((BOOL)[menuItem tag] == [[OFPreferenceWrapper sharedPreferenceWrapper] integerForKey:BDSKIntersectGroupsKey]) ? NSOnState : NSOffState];
    return YES;
}

- (BOOL)validateMergeInSharedGroupMenuItem:(NSMenuItem *)menuItem {
    return ([self hasSharedGroupsSelected]);
}

- (BOOL)validateMergeInSharedPublicationsMenuItem:(NSMenuItem *)menuItem {
    return ([self hasSharedGroupsSelected] && [self numberOfSelectedPubs] > 0);
}

- (BOOL)validateRefreshSharingMenuItem:(NSMenuItem *)menuItem {
    OFPreferenceWrapper *pw = [OFPreferenceWrapper sharedPreferenceWrapper];
    return ([pw boolForKey:BDSKShouldShareFilesKey]);
}

- (BOOL)validateRefreshSharedBrowsingMenuItem:(NSMenuItem *)menuItem {
    OFPreferenceWrapper *pw = [OFPreferenceWrapper sharedPreferenceWrapper];
    return ([pw boolForKey:BDSKShouldLookForSharedFilesKey]);
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
	else if (act == @selector(exportAsAction:)) {
		return [self validateExportMenuItem:menuItem];
	}
	else if (act == @selector(exportSelectionAsAction:)) {
		return [self validateExportSelectionMenuItem:menuItem];
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
		return [self validateToggleCustomCiteDrawerMenuItem:menuItem];
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
	else if (act == @selector(sortForCrossrefs:)) {
        return [self validateSortForCrossrefsMenuItem:menuItem];
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
	else if (act == @selector(removeSelectedGroups:)) {
        return [self validateRemoveSelectedGroupsMenuItem:menuItem];
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
	else if (act == @selector(selectAllPublications:)){
        return [self validateSelectAllPublicationsMenuItem:menuItem];
    }
	else if (act == @selector(deselectAllPublications:)){
        return [self validateDeselectAllPublicationsMenuItem:menuItem];
    }
	else if (act == @selector(selectAllPublicationsGroup:)){
        return [self validateSelectAllPublicationsGroupMenuItem:menuItem];
    }
	else if (act == @selector(selectDuplicates:)){
        return [self validateSelectDuplicatesMenuItem:menuItem];
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
    else if (act == @selector(revertDocumentToSaved:)){
        return [self validateRevertDocumentToSavedMenuItem:menuItem];
    }
    else if (act == @selector(changePreviewDisplay:)){
        return [self validateChangePreviewDisplayMenuItem:menuItem];
    }
    else if (act == @selector(changeIntersectGroupsAction:)){
        return [self validateChangeIntersectGroupsMenuItem:menuItem];
    }
    else if (act == @selector(mergeInSharedGroup:)){
        return [self validateMergeInSharedGroupMenuItem:menuItem];
    }
    else if (act == @selector(mergeInSharedPublications:)){
        return [self validateMergeInSharedPublicationsMenuItem:menuItem];
    }
    else if (act == @selector(refreshSharing:)){
        return [self validateRefreshSharingMenuItem:menuItem];
    }
    else if (act == @selector(refreshSharedBrowsing:)){
        return [self validateRefreshSharedBrowsingMenuItem:menuItem];
    }
    else {
		return [super validateMenuItem:menuItem];
    }
}

@end
