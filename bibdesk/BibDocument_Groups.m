//
//  BibDocument_Groups.m
//  Bibdesk
//
/*
 This software is Copyright (c) 2005
 Michael O. McCracken. All rights reserved.
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:
 
 - Redistributions of source code must retain the above copyright
 notice, this list of conditions and the following disclaimer.
 
 - Redistributions in binary form must reproduce the above copyright
 notice, this list of conditions and the following disclaimer in
 the documentation and/or other materials provided with the
 distribution.
 
 - Neither the name of Michael O. McCracken nor the names of any
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

#import "BibDocument_Groups.h"
#import "BDSKGroupCell.h"
#import "NSImage+Toolbox.h"
#import "BDSKFilterController.h"
#import "BDSKGroupTableView.h"
#import "BDSKHeaderPopUpButtonCell.h"
#import "BibDocument_Search.h"
#import "BDSKGroup.h"
#import "BDSKAlert.h"
#import "BDSKFieldSheetController.h"
#import "BDSKCountedSet.h"
#import "BibAuthor.h"
#import "BibAppController.h"
#import "BibTypeManager.h"
#import "BDSKSharingBrowser.h"
#import "BDSKSharedGroup.h"

@implementation BibDocument (Groups)

#pragma mark Indexed accessors

- (unsigned int)countOfGroups {
    return [smartGroups count] + [sharedGroups count] + [groups count] + 1 ;
}

- (BDSKGroup *)objectInGroupsAtIndex:(unsigned int)index {
	unsigned int smartCount = [smartGroups count];
    unsigned int sharedCount = [sharedGroups count];
	if (index == 0)
		return allPublicationsGroup;
	else if (index <= smartCount)
		return [smartGroups objectAtIndex:index - 1];
	else if (index <= smartCount + sharedCount)
        return [sharedGroups objectAtIndex:index - smartCount - 1];
    else
		return [groups objectAtIndex:index - smartCount - sharedCount - 1];
}

// mutable to-many accessor:  not presently used
- (void)insertObject:(BDSKGroup *)group inGroupsAtIndex:(unsigned int)index {
    // we don't actually put it in the requested place, rather put it at the end of the current array
    NSRange simpleRange = [self rangeOfSimpleGroups];
	
	if ([group isSmart]) // we don't care about the index, as we resort anyway. This activates undo
		[self addSmartGroup:(BDSKSmartGroup *)group];
	else if (NSLocationInRange(index, simpleRange))
        [groups insertObject:group atIndex:(index - simpleRange.location)];
    else
        OBASSERT_NOT_REACHED("invalid insertion index for group");
}

// mutable to-many accessor:  not presently used
- (void)removeObjectFromGroupsAtIndex:(unsigned int)index {
    NSRange simpleRange = [self rangeOfSimpleGroups];
    NSRange smartRange = [self rangeOfSmartGroups];
    
    if (NSLocationInRange(index, smartRange))
        [smartGroups removeObject:[smartGroups objectAtIndex:(index - smartRange.location)]];
    else if (NSLocationInRange(index, simpleRange))
        [groups removeObjectAtIndex:(index - simpleRange.location)];
    else
        OBASSERT_NOT_REACHED("group cannot be removed");

}

- (NSRange)rangeOfSimpleGroups{
    return NSMakeRange([smartGroups count] + [sharedGroups count] + 1, [groups count]);
}

- (NSRange)rangeOfSmartGroups{
    return NSMakeRange(1, [smartGroups count]);
}

- (NSRange)rangeOfSharedGroups{
    return NSMakeRange([smartGroups count] + 1, [sharedGroups count]);
}

- (unsigned int)numberOfSimpleGroupsAtIndexes:(NSIndexSet *)indexes{
    NSRange simpleRange = [self rangeOfSimpleGroups];
    unsigned int maxCount = MIN([indexes count], simpleRange.length);
    unsigned int buffer[maxCount];
    return [indexes getIndexes:buffer maxCount:maxCount inIndexRange:&simpleRange];
}

- (unsigned int)numberOfSmartGroupsAtIndexes:(NSIndexSet *)indexes{
    NSRange smartRange = [self rangeOfSmartGroups];
    unsigned int maxCount = MIN([indexes count], smartRange.length);
    unsigned int buffer[maxCount];
    return [indexes getIndexes:buffer maxCount:maxCount inIndexRange:&smartRange];
}

- (unsigned int)numberOfSharedGroupsAtIndexes:(NSIndexSet *)indexes{
    NSRange sharedRange = [self rangeOfSharedGroups];
    unsigned int maxCount = MIN([indexes count], sharedRange.length);
    unsigned int buffer[maxCount];
    return [indexes getIndexes:buffer maxCount:maxCount inIndexRange:&sharedRange];
}

- (BOOL)hasSharedGroupsAtIndexes:(NSIndexSet *)indexes{
    NSRange sharedRange = [self rangeOfSharedGroups];
    return [indexes intersectsIndexesInRange:sharedRange];
}

#pragma mark Accessors

- (void)addSmartGroup:(BDSKSmartGroup *)group {
	[[[self undoManager] prepareWithInvocationTarget:self] removeSmartGroup:group];
    
    // update the count
	NSArray *array = [publications copy];
	[group filterItems:array];
    [array release];
	
	[smartGroups addObject:group];
	[group setUndoManager:[self undoManager]];
    [groupTableView reloadData];
}

- (void)removeSmartGroup:(BDSKSmartGroup *)group {
	[[[self undoManager] prepareWithInvocationTarget:self] addSmartGroup:group];
	
	[group setUndoManager:nil];
	[smartGroups removeObjectIdenticalTo:group];
    [groupTableView reloadData];
}

// assumes you only have a single smart group with this name; that assumption is not enforced elsewhere
- (void)removeSmartGroupNamed:(id)name {
    NSEnumerator *e = [smartGroups objectEnumerator];
    BDSKSmartGroup *sGroup = nil;
    
    while(sGroup = [e nextObject]){
        if([[sGroup name] isEqual:name]){
            [self removeSmartGroup:sGroup];
            break;
        }
    }
}

/* 
The groupedPublications array is a subset of the publications array, developed by searching the publications array; shownPublications is now a subset of the groupedPublications array, and searches in the searchfield will search only within groupedPublications (which may include all publications).
*/

- (void)setCurrentGroupField:(NSString *)field{
	if (field != currentGroupField) {
		[currentGroupField release];
		currentGroupField = [field copy];
	}
}	

- (NSString *)currentGroupField{
	return currentGroupField;
}

- (NSArray *)selectedGroups {
	NSMutableArray *array = [[NSMutableArray alloc] initWithCapacity:[groupTableView numberOfSelectedRows]];
	NSIndexSet *rowIndexes = [groupTableView selectedRowIndexes];
    unsigned int rowIndex = [rowIndexes firstIndex];
	
	while (rowIndexes != nil && rowIndex != NSNotFound) {
		[array addObject:[self objectInGroupsAtIndex:rowIndex]];
        rowIndex = [rowIndexes indexGreaterThanIndex:rowIndex];
	}
	return [array autorelease];
}

- (NSArray *)selectedSharedPublications
{
    NSMutableArray *array = [NSMutableArray array];
    BDSKGroup *group;
    
    NSIndexSet *rowIndexes = [groupTableView selectedRowIndexes];
    unsigned int rowIndex = [rowIndexes firstIndex];
	
	while(rowIndexes != nil && rowIndex != NSNotFound){
        group = [self objectInGroupsAtIndex:rowIndex];
        if([sharedGroups containsObjectIdenticalTo:group]){
            [array addObjectsFromArray:[(BDSKSharedGroup *)group publications]];
        }
        rowIndex = [rowIndexes indexGreaterThanIndex:rowIndex];
	}
    
    return array;
}

#pragma mark Notification handlers

- (void)handleGroupFieldChangedNotification:(NSNotification *)notification{
    // this is set in all of the action methods
    OBPRECONDITION([[[(BDSKGroupTableHeaderView *)[groupTableView headerView] popUpHeaderCell] titleOfSelectedItem] isEqualToString:[self currentGroupField]]);
    // use the most recently changed group as default for newly opened documents; could also store on a per-document basis
    [[OFPreferenceWrapper sharedPreferenceWrapper] setObject:currentGroupField forKey:BDSKCurrentGroupFieldKey];
	[self updateGroupsPreservingSelection:NO];
}

- (void)handleFilterChangedNotification:(NSNotification *)notification{
	[self updateAllSmartGroups];
}

- (void)handleGroupTableSelectionChangedNotification:(NSNotification *)notification{
    // Mail and iTunes clear search when changing groups; users don't like this, though.  Xcode doesn't clear its search field, so at least there's some precedent for the opposite side.
    [self displaySelectedGroups];
    // could force selection of row 0 in the main table here, so we always display a preview, but that flashes the group table highlights annoyingly and may cause other selection problems
}

- (void)handleSharedGroupUpdatedNotification:(NSNotification *)notification{
    BDSKGroup *group = [notification object];
    BOOL succeeded = [[[notification userInfo] objectForKey:@"succeeded"] boolValue];
    
    if([sortGroupsKey isEqualToString:BDSKGroupCellCountKey]){
        [self sortGroupsByKey:sortGroupsKey];
    }else{
        [groupTableView reloadData];
        if ([[self selectedGroups] containsObject:group] && succeeded == YES)
            [self displaySelectedGroups];
    }
}

- (void)handleSharedGroupsChangedNotification:(NSNotification *)notification{
    // this is a hack to keep us from getting selection change notifications while sorting (which updates the TeX and attributed text previews)
    [groupTableView setDelegate:nil];
	NSArray *selectedGroups = [self selectedGroups];
	
    NSArray *array = [[BDSKSharingBrowser sharedBrowser] sharedGroups];
    
    [sharedGroups release];
    sharedGroups = nil;
    if (array != nil) {
        sharedGroups = [array mutableCopy];
        // now sort using the current column and order
        SEL sortSelector = ([sortGroupsKey isEqualToString:BDSKGroupCellCountKey]) ? @selector(countCompare:) : @selector(nameCompare:);
        [sharedGroups sortUsingSelector:sortSelector ascending:!sortGroupsDescending usingLock:nil];
    }
    
    // rebuild the dictionary of spinners
    if (sharedGroupSpinners == nil) {
        sharedGroupSpinners = [[NSMutableDictionary alloc] initWithCapacity:5];
    } else {
        [[sharedGroupSpinners allValues] makeObjectsPerformSelector:@selector(removeFromSuperview)];
        [sharedGroupSpinners removeAllObjects];
    }
    
    NSEnumerator *groupEnum = [array objectEnumerator];
    BDSKSharedGroup *group;
    
    while(group = [groupEnum nextObject]){
        NSProgressIndicator *spinner = [[NSProgressIndicator alloc] init];
        [spinner setControlSize:NSSmallControlSize];
        [spinner setStyle:NSProgressIndicatorSpinningStyle];
        [spinner setDisplayedWhenStopped:NO];
        [spinner sizeToFit];
        [sharedGroupSpinners setObject:spinner forKey:[group name]];
        [spinner release];
    }
	
    [groupTableView reloadData];
	NSMutableIndexSet *selIndexes = [[NSMutableIndexSet alloc] init];
	
	// select the current groups, if still around. Otherwise select All Publications
	if([selectedGroups count] != 0){
		unsigned int row = [self countOfGroups];
		while(row--){
			if([selectedGroups containsObject:[self objectInGroupsAtIndex:row]])
				[selIndexes addIndex:row];
		}
	}
	if ([selIndexes count] == 0)
		[selIndexes addIndex:0];
	[groupTableView selectRowIndexes:selIndexes byExtendingSelection:NO];
    [selIndexes release];
	
	[self displaySelectedGroups]; // the selection may not have changed, so we won't get this from the notification
    
	// reset ourself as delegate
    [groupTableView setDelegate:self];
}

#pragma mark UI updating

// this method uses counted sets to compute the number of publications per group; each group object is just a name
// and a count, and a group knows how to compare itself with other groups for sorting/equality, but doesn't know 
// which pubs are associated with it
- (void)updateGroupsPreservingSelection:(BOOL)preserve{
    // this is a hack to keep us from getting selection change notifications while sorting (which updates the TeX and attributed text previews)
    [groupTableView setDelegate:nil];
    
	NSArray *selectedGroups = [self selectedGroups];
	
    NSString *groupField = [self currentGroupField];

	BDSKCountedSet *countedSet;
    if([[[BibTypeManager sharedManager] personFieldsSet] containsObject:groupField])
        countedSet = [[BDSKCountedSet alloc] initFuzzyAuthorCountedSet];
    else
        countedSet = [[BDSKCountedSet alloc] initCaseInsensitive:YES withCapacity:[publications count]];
    
    int emptyCount = 0;
    
    NSEnumerator *pubEnum = [publications objectEnumerator];
    BibItem *pub;
    
    NSSet *tmpSet = nil;
    while(pub = [pubEnum nextObject]){
        tmpSet = [pub groupsForField:groupField];
        if([tmpSet count])
            [countedSet unionSet:tmpSet];
        else
            emptyCount++;
    }
    
    NSMutableArray *mutableGroups = [[NSMutableArray alloc] initWithCapacity:[countedSet count] + 1];
    NSEnumerator *groupEnum = [countedSet objectEnumerator];
    id groupName;
    BDSKGroup *group;
            
    // now add the group names that we found from our BibItems, using a generic folder icon
    // use OATextWithIconCell keys
    while(groupName = [groupEnum nextObject]){
        group = [[BDSKGroup alloc] initWithName:groupName key:groupField count:[countedSet countForObject:groupName]];
        [mutableGroups addObject:group];
        [group release];
    }
    
	// now sort using the current column and order
	SEL sortSelector = ([sortGroupsKey isEqualToString:BDSKGroupCellCountKey]) ?
						@selector(countCompare:) : @selector(nameCompare:);
	[mutableGroups sortUsingSelector:sortSelector ascending:!sortGroupsDescending usingLock:nil];
    
	// update the count for the first item, not sure if it should be done here
    [allPublicationsGroup setCount:[publications count]];
    
    // add the "empty" group at index 0; this is a group of pubs whose value is empty for this field, so they
    // will not be contained in any of the other groups for the currently selected group field (hence multiple selection is desirable)
    if(emptyCount > 0){
        group = [[BDSKGroup alloc] initEmptyGroupWithClass:([[[BibTypeManager sharedManager] personFieldsSet] containsObject:groupField]?[BibAuthor class]:[NSString class]) key:groupField count:emptyCount];
        [mutableGroups insertObject:group atIndex:0];
        [group release];
    }
	
    [groups setArray:mutableGroups];
    [countedSet release];
    [mutableGroups release];
	
    [groupTableView reloadData];
	NSMutableIndexSet *selIndexes = [[NSMutableIndexSet alloc] init];
	
	// select the current group, if still around. Otherwise select All Publications
	if(preserve && [selectedGroups count] != 0){
		unsigned int row = [self countOfGroups];
		while(row--){
			if([selectedGroups containsObject:[self objectInGroupsAtIndex:row]])
				[selIndexes addIndex:row];
		}
	}
	if ([selIndexes count] == 0)
		[selIndexes addIndex:0];
	[groupTableView selectRowIndexes:selIndexes byExtendingSelection:NO];
    [selIndexes release];
	
	[self displaySelectedGroups]; // the selection may not have changed, so we won't get this from the notification
    
	// reset ourself as delegate
    [groupTableView setDelegate:self];
}
	
- (void)displaySelectedGroups{
    [groupedPublications setArray:[self publicationsInCurrentGroups]];
    
    [self searchFieldAction:searchField]; // redo the search to update the table
}

- (void)selectGroup:(BDSKGroup *)aGroup{
    [self selectGroups:[NSArray arrayWithObject:aGroup]];
}

- (void)selectGroups:(NSArray *)theGroups{
    unsigned count = [self countOfGroups];
    NSMutableIndexSet *indexes = [NSMutableIndexSet indexSet];
    while(count--){
        if([theGroups containsObject:[self objectInGroupsAtIndex:count]])
            [indexes addIndex:count];
    }

    OBPOSTCONDITION([indexes count]);
    [groupTableView deselectAll:nil];
    [groupTableView selectRowIndexes:indexes byExtendingSelection:NO];
}

// force the smart groups to refilter their items, so the group content and count get redisplayed
// if this becomes slow, we could make filters thread safe and update them in the background
- (void)updateAllSmartGroups{

	NSRange smartRange = [self rangeOfSmartGroups];
    unsigned int row = NSMaxRange(smartRange);
    NSArray *array = [publications copy];
	BOOL shouldUpdate = NO;
    
    while(NSLocationInRange(--row, smartRange)){
		[(BDSKSmartGroup *)[self objectInGroupsAtIndex:row] filterItems:array];
		if([groupTableView isRowSelected:row])
			shouldUpdate = YES;
    }
    
    [array release];
    [groupTableView reloadData];
    
    if(shouldUpdate == YES){
        // fix for bug #1362191: after changing a checkbox that removed an item from a smart group, the table scrolled to the top
        NSPoint scrollPoint = [[tableView enclosingScrollView] scrollPositionAsPercentage];
		[self displaySelectedGroups];
        [[tableView enclosingScrollView] setScrollPositionAsPercentage:scrollPoint];
    }
}

// simplistic search method for static groups; we don't need the features of the standard searching method

- (NSArray *)publicationsInCurrentGroups{
    NSArray *selectedGroups = [self selectedGroups];
    NSMutableArray *filteredArray;
    
    // optimize for a common case
    if ([selectedGroups containsObject:allPublicationsGroup]) {
        filteredArray = [publications copy];
    } else {
        NSArray *array = [publications copy];
        NSEnumerator *pubEnum = [array objectEnumerator];
        BibItem *pub;
        NSEnumerator *groupEnum;
        BDSKGroup *group;
        
        filteredArray = [[NSMutableArray alloc] initWithCapacity:[array count]];
        [array release];
        
        while (pub = [pubEnum nextObject]) {
            groupEnum = [selectedGroups objectEnumerator];
            while (group = [groupEnum nextObject]) {
                if ([group containsItem:pub]) {
                    [filteredArray addObject:pub];
                    break;
                }
            }
        }
    }
    [filteredArray addObjectsFromArray:[self selectedSharedPublications]];
	
	return [filteredArray autorelease];
}

- (NSIndexSet *)_indexesOfRowsToHighlightInRange:(NSRange)indexRange tableView:(BDSKGroupTableView *)tview{
   
    if([tableView numberOfSelectedRows] == 0 || 
       [self hasSharedGroupsAtIndexes:[groupTableView selectedRowIndexes]])
        return [NSIndexSet indexSet];
    
    // This allows us to be slightly lazy, only putting the visible group rows in the dictionary
    NSIndexSet *visibleIndexes = [NSIndexSet indexSetWithIndexesInRange:indexRange];
    unsigned int cnt = [visibleIndexes count];
    NSRange simpleRange = [self rangeOfSimpleGroups];
    
    // Mutable dictionary with fixed capacity using NSObjects for keys with ints for values; this gives us a fast lookup of row name->index.  Dictionaries can use any pointer-size element for a key or value; see /Developer/Examples/CoreFoundation/Dictionary.  Keys are retained rather than copied for efficiency.  Shark says that BibAuthors are created with alloc/init when using the copy callbacks, so NSShouldRetainWithZone() must be returning NO?
    CFMutableDictionaryRef rowDict = CFDictionaryCreateMutable(CFAllocatorGetDefault(), cnt, &OFNSObjectDictionaryKeyCallbacks, &OFIntegerDictionaryValueCallbacks);
    
    cnt = [visibleIndexes firstIndex];
    
    // exclude smart and shared groups
    while(cnt != NSNotFound){
		if(NSLocationInRange(cnt, simpleRange))
			CFDictionaryAddValue(rowDict, (void *)[[groups objectAtIndex:cnt - simpleRange.location] name], (void *)cnt);
        cnt = [visibleIndexes indexGreaterThanIndex:cnt];
    }
    
    // Use this for the indexes we're going to return
    NSMutableIndexSet *indexSet = [NSMutableIndexSet indexSet];
    
    // Unfortunately, we have to check all of the items in the main table, since hidden items may have a visible group
    NSIndexSet *rowIndexes = [tableView selectedRowIndexes];
    unsigned int rowIndex = [rowIndexes firstIndex];
    NSSet *possibleGroups;
    id groupName;
    BOOL rowExists;
    NSEnumerator *groupEnum;
    NSString *groupField = [self currentGroupField];
        
    while(rowIndexes != nil && rowIndex != NSNotFound){ 
        // here are all the groups that this item can be a part of
        possibleGroups = [[shownPublications objectAtIndex:rowIndex] groupsForField:groupField];
        groupEnum = [possibleGroups objectEnumerator];
        
        while(groupName = [groupEnum nextObject]){
            // The dictionary only has visible group rows, so not all of the keys (potential groups) will exist in the dictionary
            rowExists = CFDictionaryGetValueIfPresent(rowDict, (void *)groupName, (const void **)&cnt);
            if(rowExists) [indexSet addIndex:cnt];
        }
        rowIndex = [rowIndexes indexGreaterThanIndex:rowIndex];
    }
    
    CFRelease(rowDict);
    
    return indexSet;
}

- (NSIndexSet *)_tableViewSingleSelectionIndexes:(BDSKGroupTableView *)tview{
    NSMutableIndexSet *indexes = [NSMutableIndexSet indexSetWithIndexesInRange:[self rangeOfSharedGroups]];
    [indexes addIndex:0];
    return indexes;
}

- (NSMenu *)groupFieldsMenu {
	NSMenu *menu = [[NSMenu allocWithZone:[NSMenu menuZone]] init];
	NSMenuItem *menuItem;
	NSEnumerator *fieldEnum = [[[OFPreferenceWrapper sharedPreferenceWrapper] stringArrayForKey:BDSKGroupFieldsKey] objectEnumerator];
	NSString *field;
	
	while (field = [fieldEnum nextObject]) {
		[menu addItemWithTitle:field action:NULL keyEquivalent:@""];
	}
    
    [menu addItem:[NSMenuItem separatorItem]];
	
	menuItem = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:[NSString stringWithFormat:@"%@%@", NSLocalizedString(@"Add Field", @""), [NSString horizontalEllipsisString]]
										  action:@selector(addGroupFieldAction:)
								   keyEquivalent:@""];
	[menuItem setTarget:self];
	[menu addItem:menuItem];
    [menuItem release];
	
	menuItem = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:[NSString stringWithFormat:@"%@%@", NSLocalizedString(@"Remove Field", @""), [NSString horizontalEllipsisString]]
										  action:@selector(removeGroupFieldAction:)
								   keyEquivalent:@""];
	[menuItem setTarget:self];
	[menu addItem:menuItem];
    [menuItem release];
	
	return [menu autorelease];
}

- (NSMenu *)tableView:(BDSKGroupTableView *)aTableView menuForTableHeaderColumn:(NSTableColumn *)tableColumn onPopUp:(BOOL)flag{
	if ([[tableColumn identifier] isEqualToString:@"group"] && flag == NO) {
		return [[[NSApp delegate] groupSortMenuItem] submenu];
	}
	return nil;
}

- (void)sortGroupsByGroup:(id)sender{
	if ([sortGroupsKey isEqualToString:BDSKGroupCellStringKey]) return;
	[self sortGroupsByKey:BDSKGroupCellStringKey];
}

- (void)sortGroupsByCount:(id)sender{
	if ([sortGroupsKey isEqualToString:BDSKGroupCellCountKey]) return;
	[self sortGroupsByKey:BDSKGroupCellCountKey];
}

- (void)changeGroupFieldAction:(id)sender{
	BDSKGroupTableHeaderView *headerView = (BDSKGroupTableHeaderView *)[groupTableView headerView];
	NSPopUpButtonCell *headerCell = [headerView popUpHeaderCell];
	NSString *field = [headerCell titleOfSelectedItem];
    
	if(![field isEqualToString:currentGroupField]){
		[self setCurrentGroupField:field];
		
		[[NSNotificationCenter defaultCenter] postNotificationName:BDSKGroupFieldChangedNotification
															object:self
														  userInfo:[NSDictionary dictionary]];
	}
}

// for adding/removing groups, we use the searchfield sheets

- (void)addGroupFieldAction:(id)sender{
	BDSKGroupTableHeaderView *headerView = (BDSKGroupTableHeaderView *)[groupTableView headerView];
	NSPopUpButtonCell *headerCell = [headerView popUpHeaderCell];
	
	[headerCell selectItemWithTitle:currentGroupField];
    
	BibTypeManager *typeMan = [BibTypeManager sharedManager];
	NSArray *groupFields = [[OFPreferenceWrapper sharedPreferenceWrapper] stringArrayForKey:BDSKGroupFieldsKey];
    NSArray *colNames = [typeMan allFieldNamesIncluding:[NSArray arrayWithObjects:BDSKTypeString, BDSKCrossrefString, nil]
                                              excluding:[[[typeMan invalidGroupFields] allObjects] arrayByAddingObjectsFromArray:groupFields]];
    
    BDSKAddFieldSheetController *addFieldController = [[BDSKAddFieldSheetController alloc] initWithPrompt:NSLocalizedString(@"Name of group field:",@"")
                                                                                              fieldsArray:colNames];
	NSString *newGroupField = [addFieldController runSheetModalForWindow:documentWindow];
    [addFieldController release];
    
    if(newGroupField == nil)
        return;
    
	if([[[BibTypeManager sharedManager] invalidGroupFields] containsObject:newGroupField]){
        NSBeginAlertSheet(NSLocalizedString(@"Invalid Field", @"Invalid Field"),
                          nil, nil, nil, documentWindow, nil, nil, nil, nil,
                          [NSString stringWithFormat:NSLocalizedString(@"The field \"%@\" can not be used for groups.", @""), newGroupField] );
		return;
	}
	
	NSMutableArray *array = [groupFields mutableCopy];
	[array addObject:newGroupField];
	[[OFPreferenceWrapper sharedPreferenceWrapper] setObject:array forKey:BDSKGroupFieldsKey];	
    
    [[NSNotificationCenter defaultCenter] postNotificationName:BDSKGroupAddRemoveNotification
                                                        object:self
                                                      userInfo:[NSDictionary dictionaryWithObjectsAndKeys:newGroupField, NSKeyValueChangeNewKey, [NSNumber numberWithInt:NSKeyValueChangeInsertion], NSKeyValueChangeKindKey, nil]];        
    
	[headerCell insertItemWithTitle:newGroupField atIndex:[groupFields count]];
	[self setCurrentGroupField:newGroupField];
	[headerCell selectItemWithTitle:currentGroupField];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:BDSKGroupFieldChangedNotification
														object:self
													  userInfo:[NSDictionary dictionary]];
    [array release];
}    

- (void)removeGroupFieldAction:(id)sender{
	BDSKGroupTableHeaderView *headerView = (BDSKGroupTableHeaderView *)[groupTableView headerView];
	NSPopUpButtonCell *headerCell = [headerView popUpHeaderCell];
	
	[headerCell selectItemWithTitle:currentGroupField];
    
    BDSKAddFieldSheetController *removeFieldController = [[BDSKRemoveFieldSheetController alloc] initWithPrompt:NSLocalizedString(@"Group field to remove:",@"")
                                                            fieldsArray:[[OFPreferenceWrapper sharedPreferenceWrapper] stringArrayForKey:BDSKGroupFieldsKey]];
	NSString *oldGroupField = [removeFieldController runSheetModalForWindow:documentWindow];
    [removeFieldController release];
    
    if(oldGroupField == nil)
        return;
    
    NSMutableArray *array = [[[OFPreferenceWrapper sharedPreferenceWrapper] stringArrayForKey:BDSKGroupFieldsKey] mutableCopy];
    [array removeObject:oldGroupField];
    [[OFPreferenceWrapper sharedPreferenceWrapper] setObject:array forKey:BDSKGroupFieldsKey];
    [array release];
    
    [headerCell removeItemWithTitle:oldGroupField];
    if([oldGroupField isEqualToString:currentGroupField]){
        [self setCurrentGroupField:[[headerCell itemAtIndex:0] title]];
        [headerCell selectItemWithTitle:currentGroupField];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:BDSKGroupFieldChangedNotification
                                                            object:self
                                                          userInfo:[NSDictionary dictionary]];
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:BDSKGroupAddRemoveNotification
                                                        object:self
                                                      userInfo:[NSDictionary dictionaryWithObjectsAndKeys:oldGroupField, NSKeyValueChangeNewKey, [NSNumber numberWithInt:NSKeyValueChangeRemoval], NSKeyValueChangeKindKey, nil]];        
}

- (void)handleGroupAddRemoveNotification:(NSNotification *)notification{
    // Handle changes to the popup from other documents.  The userInfo for this notification uses key-value observing keys: NSKeyValueChangeNewKey is the affected field (whether add/remove), and NSKeyValueChangeKindKey will be either insert/remove
    if([notification object] != self){
        BDSKGroupTableHeaderView *headerView = (BDSKGroupTableHeaderView *)[groupTableView headerView];
        NSPopUpButtonCell *headerCell = [headerView popUpHeaderCell];
        
        id userInfo = [notification userInfo];
        NSParameterAssert(userInfo && [userInfo valueForKey:NSKeyValueChangeKindKey]);

        NSString *field = [userInfo valueForKey:NSKeyValueChangeNewKey];
        NSParameterAssert(field);
        
        // Ignore this change if we already have that field (shouldn't happen), or are removing the current group field; in the latter case, it's already removed in prefs, so it'll be gone next time the document is opened.  Removing all fields means we have to deal with the add/remove menu items and separator, so avoid that.
        if([[headerCell titleOfSelectedItem] isEqualToString:field] == NO){
            int changeType = [[userInfo valueForKey:NSKeyValueChangeKindKey] intValue];
            
            if(changeType == NSKeyValueChangeInsertion)
                [headerCell insertItemWithTitle:field atIndex:0];
            else if(changeType == NSKeyValueChangeRemoval)
                [headerCell removeItemWithTitle:field];
            else [NSException raise:NSInvalidArgumentException format:@"Unrecognized change type %d", changeType];
        }
    }
}

- (void)addSmartGroupAction:(id)sender {
	BDSKFilterController *filterController = [[BDSKFilterController alloc] init];
	[NSApp beginSheet:[filterController window]
       modalForWindow:documentWindow
        modalDelegate:self
       didEndSelector:@selector(addSmartGroupSheetDidEnd:returnCode:contextInfo:)
          contextInfo:filterController];
}

- (void)addSmartGroupSheetDidEnd:(NSWindow *)sheet returnCode:(int) returnCode contextInfo:(void *)contextInfo{
	BDSKFilterController *filterController = (BDSKFilterController *)contextInfo;
	
	if(returnCode == NSOKButton){
		BDSKSmartGroup *group = [[BDSKSmartGroup alloc] initWithFilter:[filterController filter]];
        unsigned int insertIndex = NSMaxRange([self rangeOfSmartGroups]);
		[self addSmartGroup:group];
		[group release];
		
		[groupTableView reloadData];
		[groupTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:insertIndex] byExtendingSelection:NO];
		[groupTableView editColumn:0 row:insertIndex withEvent:nil select:YES];
		[[self undoManager] setActionName:NSLocalizedString(@"Add Smart Group",@"Add smart group")];
		// updating of the tables is done when finishing the edit of the name
	}
	
	[filterController release];
}

- (void)removeSmartGroupAction:(id)sender {
	NSIndexSet *rowIndexes = [groupTableView selectedRowIndexes];
    unsigned int rowIndex = [rowIndexes firstIndex];
	BDSKGroup *group;
	unsigned int count = 0;
	
	while (rowIndexes != nil && rowIndex != NSNotFound) {
		group = [self objectInGroupsAtIndex:rowIndex];
		if ([group isSmart] == YES) {
			[self removeSmartGroup:(BDSKSmartGroup *)group];
			count++;
        }
		rowIndex = [rowIndexes indexGreaterThanIndex:rowIndex];
	}
	if (count == 0) {
		NSBeep();
	} else {
		[[self undoManager] setActionName:NSLocalizedString(@"Remove Smart Group",@"Remove smart group")];
		[self sortGroupsByKey:sortGroupsKey];
	}
}

- (void)editGroupAction:(id)sender {
	if ([groupTableView numberOfSelectedRows] != 1) {
		NSBeep();
		return;
	} 
	
	int row = [groupTableView selectedRow];
	OBASSERT(row != -1);
	if(row <= 0) return;
	BDSKGroup *group = [self objectInGroupsAtIndex:row];
	
	if ([group isSmart]) {
        if (group == lastImportGroup) {
            NSBeep();
            return;
        }
		BDSKFilter *filter = [(BDSKSmartGroup *)[smartGroups objectAtIndex:row - 1] filter];
		BDSKFilterController *filterController = [[BDSKFilterController alloc] initWithFilter:filter];
		
		[NSApp beginSheet:[filterController window]
		   modalForWindow:documentWindow
			modalDelegate:nil
		   didEndSelector:NULL
			  contextInfo:nil];
		[filterController release];
	} else if ([group isShared] == NO && [[[BibTypeManager sharedManager] personFieldsSet] containsObject:currentGroupField]) {
		[self showPerson:(BibAuthor *)[group name]];
	}
}

- (void)renameGroupAction:(id)sender {
	if ([groupTableView numberOfSelectedRows] != 1) {
		NSBeep();
		return;
	} 
	
	int row = [groupTableView selectedRow];
	OBASSERT(row != -1);
	if (row <= 0) return;
    
    if([self tableView:groupTableView shouldEditTableColumn:[[groupTableView tableColumns] objectAtIndex:0] row:row])
		[groupTableView editColumn:0 row:row withEvent:nil select:YES];
	
}

- (IBAction)selectAllPublicationsGroup:(id)sender {
	[groupTableView deselectAll:sender];
}

- (IBAction)editNewGroupWithSelection:(id)sender{
    
    NSArray *pubs = [self selectedPublications];
    NSString *name = NSLocalizedString(@"Untitled", @"");
    BDSKGroup *group = [[[BDSKGroup alloc] initWithName:name key:currentGroupField count:[pubs count]] autorelease];
    unsigned int i = 1;
    while([groups containsObject:group]){
        group = [[[BDSKGroup alloc] initWithName:[NSString stringWithFormat:@"%@%d", name, i++] key:currentGroupField count:[pubs count]] autorelease];
    }
    
    [self addPublications:pubs toGroup:group];    
    [groupTableView deselectAll:nil];
    
    i = [groups indexOfObject:group];
    OBASSERT(i != NSNotFound);
    
    if(i != NSNotFound){
        i += [self rangeOfSimpleGroups].location;
        [groupTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:i] byExtendingSelection:NO];
        [groupTableView scrollRowToVisible:i];
        
        // don't show the warning sheet, since presumably the user wants to change the group name
        [groupTableView editColumn:0 row:i withEvent:nil select:YES];
    }
}

- (BOOL)addPublications:(NSArray *)pubs toGroup:(BDSKGroup *)group{
	OBASSERT([group isSmart] == NO && group != allPublicationsGroup);
    NSEnumerator *pubEnum = [pubs objectEnumerator];
    BibItem *pub;
	int count = 0;
	int handleInherited = BDSKOperationAsk;
	int rv;
    
    while(pub = [pubEnum nextObject]){
        OBASSERT([pub isKindOfClass:[BibItem class]]);        
        
		rv = [pub addToGroup:group handleInherited:handleInherited];
		
		if(rv == BDSKOperationSet || rv == BDSKOperationAppend){
			count++;
		}else if(rv == BDSKOperationAsk){
			NSString *otherButton = nil;
			if([[[BibTypeManager sharedManager] singleValuedGroupFields] containsObject:[self currentGroupField]] == NO)
				otherButton = NSLocalizedString(@"Append", @"Append");
			
			BDSKAlert *alert = [BDSKAlert alertWithMessageText:NSLocalizedString(@"Inherited Value", @"alert title")
												 defaultButton:NSLocalizedString(@"Don't Change", @"Don't change")
											   alternateButton:NSLocalizedString(@"Set", @"Set")
												   otherButton:otherButton
									 informativeTextWithFormat:NSLocalizedString(@"One or more items have a value that was inherited from an item linked to by the Crossref field. This operation would break the inheritance for this value. What do you want me to do with inherited values?", @"")];
			rv = [alert runSheetModalForWindow:documentWindow
								 modalDelegate:nil
								didEndSelector:NULL 
							didDismissSelector:NULL 
								   contextInfo:NULL];
			handleInherited = rv;
			if(handleInherited != BDSKOperationIgnore){
				[pub addToGroup:group handleInherited:handleInherited];
			}
		}
    }
	
	if(count > 0)
		[[self undoManager] setActionName:NSLocalizedString(@"Add To Group", @"Add to group")];
    
    return YES;
}

- (BOOL)removePublications:(NSArray *)pubs fromGroups:(NSArray *)groupArray{
    NSEnumerator *groupEnum = [groupArray objectEnumerator];
	BDSKGroup *group;
	int count = 0;
	int handleInherited = BDSKOperationAsk;
	NSString *groupName = nil;
    
    while(group = [groupEnum nextObject]){
		if([group isSmart] == YES || group == allPublicationsGroup)
			continue;
		
		if (groupName == nil)
			groupName = [NSString stringWithFormat:@"group %@", [group name]];
		else
			groupName = @"selected groups";
		
		NSEnumerator *pubEnum = [pubs objectEnumerator];
		BibItem *pub;
		int rv;
		
		while(pub = [pubEnum nextObject]){
			OBASSERT([pub isKindOfClass:[BibItem class]]);        
			
			rv = [pub removeFromGroup:group handleInherited:handleInherited];
			
			if(rv == BDSKOperationSet || rv == BDSKOperationAppend){
				count++;
			}else if(rv == BDSKOperationAsk){
				BDSKAlert *alert = [BDSKAlert alertWithMessageText:NSLocalizedString(@"Inherited Value", @"alert title")
													 defaultButton:NSLocalizedString(@"Don't Change", @"Don't change")
												   alternateButton:nil
													   otherButton:NSLocalizedString(@"Remove", @"Remove")
										 informativeTextWithFormat:NSLocalizedString(@"One or more items have a value that was inherited from an item linked to by the Crossref field. This operation would break the inheritance for this value. What do you want me to do with inherited values?", @"")];
				rv = [alert runSheetModalForWindow:documentWindow
									 modalDelegate:nil
									didEndSelector:NULL 
								didDismissSelector:NULL 
									   contextInfo:NULL];
				handleInherited = rv;
				if(handleInherited != BDSKOperationIgnore){
					[pub removeFromGroup:group handleInherited:handleInherited];
				}
			}
		}
	}
	
	if(count > 0){
		[[self undoManager] setActionName:NSLocalizedString(@"Remove from Group", @"Remove from group")];
		NSString * pubSingularPlural;
		if (count == 1)
			pubSingularPlural = NSLocalizedString(@"publication", @"publication");
		else
			pubSingularPlural = NSLocalizedString(@"publications", @"publications");
		[self setStatus:[NSString stringWithFormat:NSLocalizedString(@"Removed %i %@ from %@",@"Removed [number] publications(s) from selected group(s)"), count, pubSingularPlural, groupName] immediate:NO];
	}
    
    return YES;
}

- (BOOL)movePublications:(NSArray *)pubs fromGroup:(BDSKGroup *)group toGroupNamed:(NSString *)newGroupName{
	int count = 0;
	int handleInherited = BDSKOperationAsk;
	NSEnumerator *pubEnum = [pubs objectEnumerator];
	BibItem *pub;
	int rv;
	
	if([group isSmart] || [group hasEditableName] == NO)
		return NO;
	
	while(pub = [pubEnum nextObject]){
		OBASSERT([pub isKindOfClass:[BibItem class]]);        
		
		rv = [pub replaceGroup:group withGroupNamed:newGroupName handleInherited:handleInherited];
		
		if(rv == BDSKOperationSet || rv == BDSKOperationAppend){
			count++;
		}else if(rv == BDSKOperationAsk){
			BDSKAlert *alert = [BDSKAlert alertWithMessageText:NSLocalizedString(@"Inherited Value", @"alert title")
												 defaultButton:NSLocalizedString(@"Don't Change", @"Don't change")
											   alternateButton:nil
												   otherButton:NSLocalizedString(@"Remove", @"Remove")
									 informativeTextWithFormat:NSLocalizedString(@"One or more items have a value that was inherited from an item linked to by the Crossref field. This operation would break the inheritance for this value. What do you want me to do with inherited values?", @"")];
			rv = [alert runSheetModalForWindow:documentWindow
								 modalDelegate:nil
								didEndSelector:NULL 
							didDismissSelector:NULL 
								   contextInfo:NULL];
			handleInherited = rv;
			if(handleInherited != BDSKOperationIgnore){
				[pub replaceGroup:group withGroupNamed:newGroupName handleInherited:handleInherited];
			}
		}
	}
	
	if(count > 0)
		[[self undoManager] setActionName:NSLocalizedString(@"Rename Group", @"Rename group")];
    
    return YES;
}

- (void)sortGroupsByKey:(NSString *)key{
    if (key == nil) {
        // clicked the sort arrow in the table header, change sort order
        sortGroupsDescending = !sortGroupsDescending;
    } else if ([key isEqualToString:sortGroupsKey]) {
		// same key, resort
    } else {
        // change key
        // save new sorting selector, and re-sort the array.
        if ([key isEqualToString:BDSKGroupCellStringKey])
			sortGroupsDescending = NO;
		else
			sortGroupsDescending = YES; // more appropriate for default count sort
		[sortGroupsKey release];
        sortGroupsKey = [key retain];
	}
    
    // this is a hack to keep us from getting selection change notifications while sorting (which updates the TeX and attributed text previews)
    [groupTableView setDelegate:nil];
	
    // cache the selection
	NSArray *selectedGroups = [self selectedGroups];
    
	NSSortDescriptor *countSort = [[NSSortDescriptor alloc] initWithKey:@"numberValue" ascending:!sortGroupsDescending  selector:@selector(compare:)];
    [countSort autorelease];

    // could use "name" as key path, but then we'd still have to deal with names that are not NSStrings
    NSSortDescriptor *nameSort = [[NSSortDescriptor alloc] initWithKey:@"self" ascending:!sortGroupsDescending  selector:@selector(nameCompare:)];
    [nameSort autorelease];

    NSArray *sortDescriptors;
    
    if([sortGroupsKey isEqualToString:BDSKGroupCellCountKey]){
        if(sortGroupsDescending)
            // doc bug: this is supposed to return a copy of the receiver, but sending -release results in a zombie error
            nameSort = [countSort reversedSortDescriptor];
        sortDescriptors = [NSArray arrayWithObjects:countSort, nameSort, nil];
    } else {
        if(sortGroupsDescending)
            countSort = [countSort reversedSortDescriptor];
        sortDescriptors = [NSArray arrayWithObjects:nameSort, countSort, nil];
    }
    
    BDSKGroup *emptyGroup = nil;
    
    if ([groups count] > 0) {
        id firstName = [[groups objectAtIndex:0] name];
        if ([firstName isEqual:@""] || [firstName isEqual:[BibAuthor emptyAuthor]]) {
            emptyGroup = [[groups objectAtIndex:0] retain];
            [groups removeObjectAtIndex:0];
        }
    }
    
    if (lastImportGroup != nil)
        [smartGroups removeObject:lastImportGroup];
    
    [groups sortUsingDescriptors:sortDescriptors];
    [smartGroups sortUsingDescriptors:sortDescriptors];
    [sharedGroups sortUsingDescriptors:sortDescriptors];
	
    if (emptyGroup != nil) {
        [groups insertObject:emptyGroup atIndex:0];
        [emptyGroup release];
    }
    
    if (lastImportGroup != nil)
        [smartGroups insertObject:lastImportGroup atIndex:0];
    
    // Set the graphic for the new column header
	BDSKHeaderPopUpButtonCell *headerPopup = (BDSKHeaderPopUpButtonCell *)[(BDSKGroupTableHeaderView *)[groupTableView headerView] popUpHeaderCell];
	[headerPopup setIndicatorImage:[NSImage imageNamed:sortGroupsDescending ? @"NSDescendingSortIndicator" : @"NSAscendingSortIndicator"]];

    [groupTableView reloadData];
	NSMutableIndexSet *selIndexes = [[NSMutableIndexSet alloc] init];
	
	// select the current groups. Otherwise select All Publications
	if([selectedGroups count] != 0){
		unsigned int groupsCount = [self countOfGroups];
		unsigned int row = -1;
		while(++row < groupsCount){
			if([selectedGroups containsObject:[self objectInGroupsAtIndex:row]])
				[selIndexes addIndex:row];
		}
	}
	if ([selIndexes count] == 0)
		[selIndexes addIndex:0];
	[groupTableView selectRowIndexes:selIndexes byExtendingSelection:NO];
	[self displaySelectedGroups];
	
    // reset ourself as delegate
    [groupTableView setDelegate:self];
}

- (void)updateLastImportGroupForDate:(NSDate *)date {
    // we use a +/- 1 second time interval to determine which pubs belong in this group
    // any pubs added in the next second after the paste will also be in this group, but that's not likely
    NSDate *startDate = [[[NSDate alloc] initWithTimeInterval:-1.0 sinceDate:date] autorelease];
    NSDate *endDate = [[[NSDate alloc] initWithTimeInterval:1.0 sinceDate:date] autorelease];
    
    NSMutableArray *conditions = [NSMutableArray array];
    BDSKCondition *condition = nil;
    condition = [[[BDSKCondition alloc] init] autorelease];
    [condition setComparison:BDSKLarger];
    [condition setKey:BDSKDateCreatedString];
    [condition setValue:[startDate description]];
    [conditions addObject:condition];
    
    condition = [[[BDSKCondition alloc] init] autorelease];
    [condition setComparison:BDSKSmaller];
    [condition setKey:BDSKDateCreatedString];
    [condition setValue:[endDate description]];
    [conditions addObject:condition];
    
    if (lastImportGroup == nil) {
        BDSKFilter *filter = [[[BDSKFilter alloc] initWithConditions:conditions] autorelease];
		lastImportGroup = [[BDSKSmartGroup alloc] initWithName:NSLocalizedString(@"Last Import", @"Last Import") count:0 filter:filter];
        [lastImportGroup setEditableName:NO];
        [smartGroups insertObject:lastImportGroup atIndex:0];
    } else {
        [[lastImportGroup filter] setConditions:conditions];
    }
    
    NSArray *array = [[self publications] copy];
	[lastImportGroup filterItems:array]; // update the count
    [array release];
    [groupTableView reloadData];
}

- (NSData *)serializedSmartGroupsData {
	NSMutableArray *array = [NSMutableArray arrayWithCapacity:[smartGroups count]];
	NSMutableDictionary *dict;
	NSEnumerator *groupEnum = [smartGroups objectEnumerator];
	BDSKSmartGroup *group;
	
	while (group = [groupEnum nextObject]) {
        if (group == lastImportGroup) continue;
		dict = [[[group filter] dictionaryValue] mutableCopy];
		[dict setObject:[group stringValue] forKey:@"group name"];
		[array addObject:dict];
		[dict release];
	}
	
	NSString *error = nil;
	NSPropertyListFormat format = NSPropertyListXMLFormat_v1_0;
	NSData *data = [NSPropertyListSerialization dataFromPropertyList:array
															  format:format 
													errorDescription:&error];
    	
	if (error) {
		NSLog(@"Error serializing: %@", error);
        [error release];
		return nil;
	}
	return data;
}

- (void)addSmartGroupsFromSerializedData:(NSData *)data {
	NSString *error = nil;
	NSPropertyListFormat format = NSPropertyListXMLFormat_v1_0;
	id plist = [NSPropertyListSerialization propertyListFromData:data
												mutabilityOption:NSPropertyListImmutable
														  format:&format 
												errorDescription:&error];
	
	if (error) {
		NSLog(@"Error deserializing: %@", error);
        [error release];
		return;
	}
	if ([plist isKindOfClass:[NSArray class]] == NO) {
		NSLog(@"Serialized smart groups was no array.");
		return;
	}
	
	NSEnumerator *groupEnum = [plist objectEnumerator];
	NSDictionary *groupDict;
	NSMutableArray *array = [NSMutableArray arrayWithCapacity:[(NSArray *)plist count]];
	BDSKSmartGroup *group;
	BDSKFilter *filter;
	
	while (groupDict = [groupEnum nextObject]) {
		filter = [[BDSKFilter alloc] initWithDictionary:groupDict];
		group = [[BDSKSmartGroup alloc] initWithName:[groupDict objectForKey:@"group name"] count:0 filter:filter];
		[group setUndoManager:[self undoManager]];
		[array addObject:group];
		[group release];
		[filter release];
	}
	
	[smartGroups addObjectsFromArray:array];
}


@end
