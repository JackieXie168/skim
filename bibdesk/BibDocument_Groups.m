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
#import "NSArray_BDSKExtensions.h"

@implementation BibDocument (Groups)

#pragma mark Indexed accessors

- (unsigned int)countOfGroups {
    return [smartGroups count] + [sharedGroups count] + [[self staticGroups] count] + [categoryGroups count] + (lastImportGroup ? 1 : 0) + 1 /* add 1 for all publications group */ ;
}

- (BDSKGroup *)objectInGroupsAtIndex:(unsigned int)index {
    unsigned int count;
    
    if (index == 0)
		return allPublicationsGroup;
    index -= 1;
    
    if (lastImportGroup != nil) {
        if (index == 0)
            return lastImportGroup;
        index -= 1;
    }
    
    count = [sharedGroups count];
    if (index < count)
        return [sharedGroups objectAtIndex:index];
    index -= count;
    
	count = [smartGroups count];
    if (index < count)
		return [smartGroups objectAtIndex:index];
    index -= count;
    
    count = [[self staticGroups] count];
    if (index < count)
        return [[self staticGroups] objectAtIndex:index];
    index -= count;
    
    return [categoryGroups objectAtIndex:index];
}

// mutable to-many accessor:  not presently used
- (void)insertObject:(BDSKGroup *)group inGroupsAtIndex:(unsigned int)index {
    // we don't actually put it in the requested place, rather put it at the end of the current array
	if ([group isSmart]) 
		[self addSmartGroup:(BDSKSmartGroup *)group];
	else if ([group isStatic])
		[self addStaticGroup:(BDSKStaticGroup *)group];
    else
        OBASSERT_NOT_REACHED("invalid insertion index for group");
}

// mutable to-many accessor:  not presently used
- (void)removeObjectFromGroupsAtIndex:(unsigned int)index {
    NSRange smartRange = [self rangeOfSmartGroups];
    NSRange staticRange = [self rangeOfStaticGroups];
    
    if (NSLocationInRange(index, smartRange))
        [smartGroups removeObject:[smartGroups objectAtIndex:(index - smartRange.location)]];
    else if (NSLocationInRange(index, staticRange))
        [staticGroups removeObjectAtIndex:(index - staticRange.location)];
    else
        OBASSERT_NOT_REACHED("group cannot be removed");

}

#pragma mark Index ranges of groups

- (NSRange)rangeOfSharedGroups{
    return NSMakeRange((lastImportGroup == nil) ? 1 : 2, [sharedGroups count]);
}

- (NSRange)rangeOfSmartGroups{
    return NSMakeRange(NSMaxRange([self rangeOfSharedGroups]), [smartGroups count]);
}

- (NSRange)rangeOfStaticGroups{
    return NSMakeRange(NSMaxRange([self rangeOfSmartGroups]), [[self staticGroups] count]);
}

- (NSRange)rangeOfCategoryGroups{
    return NSMakeRange(NSMaxRange([self rangeOfStaticGroups]), [categoryGroups count]);
}

- (unsigned int)numberOfCategoryGroupsAtIndexes:(NSIndexSet *)indexes{
    NSRange categoryRange = [self rangeOfCategoryGroups];
    unsigned int maxCount = MIN([indexes count], categoryRange.length);
    unsigned int buffer[maxCount];
    return [indexes getIndexes:buffer maxCount:maxCount inIndexRange:&categoryRange];
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

- (unsigned int)numberOfStaticGroupsAtIndexes:(NSIndexSet *)indexes{
    NSRange staticRange = [self rangeOfStaticGroups];
    unsigned int maxCount = MIN([indexes count], staticRange.length);
    unsigned int buffer[maxCount];
    return [indexes getIndexes:buffer maxCount:maxCount inIndexRange:&staticRange];
}

- (BOOL)hasCategoryGroupsAtIndexes:(NSIndexSet *)indexes{
    NSRange categoryRange = [self rangeOfCategoryGroups];
    return [indexes intersectsIndexesInRange:categoryRange];
}

- (BOOL)hasCategoryGroupsSelected{
    return [self hasCategoryGroupsAtIndexes:[groupTableView selectedRowIndexes]];
}

- (BOOL)hasSmartGroupsAtIndexes:(NSIndexSet *)indexes{
    NSRange smartRange = [self rangeOfSmartGroups];
    return [indexes intersectsIndexesInRange:smartRange];
}

- (BOOL)hasSmartGroupsSelected{
    return [self hasSmartGroupsAtIndexes:[groupTableView selectedRowIndexes]];
}

- (BOOL)hasSharedGroupsAtIndexes:(NSIndexSet *)indexes{
    NSRange sharedRange = [self rangeOfSharedGroups];
    return [indexes intersectsIndexesInRange:sharedRange];
}

- (BOOL)hasSharedGroupsSelected{
    return [self hasSharedGroupsAtIndexes:[groupTableView selectedRowIndexes]];
}

- (BOOL)hasStaticGroupsAtIndexes:(NSIndexSet *)indexes{
    NSRange staticRange = [self rangeOfStaticGroups];
    return [indexes intersectsIndexesInRange:staticRange];
}

- (BOOL)hasStaticGroupsSelected{
    return [self hasStaticGroupsAtIndexes:[groupTableView selectedRowIndexes]];
}

#pragma mark Accessors

- (NSMutableArray *)staticGroups{
    if (staticGroups == nil) {
        staticGroups = [[NSMutableArray alloc] init];
        
        NSEnumerator *groupEnum = [tmpStaticGroups objectEnumerator];
        NSDictionary *groupDict;
        BDSKStaticGroup *group = nil;
        NSMutableArray *pubArray = nil;
        NSArray *keys;
        NSEnumerator *keyEnum;
        NSString *key;
        
        while (groupDict = [groupEnum nextObject]) {
            @try {
                keys = [[groupDict objectForKey:@"keys"] componentsSeparatedByString:@","];
                keyEnum = [keys objectEnumerator];
                pubArray = [[NSMutableArray alloc] initWithCapacity:[keys count]];
                while (key = [keyEnum nextObject]) 
                    [pubArray addObjectsFromArray:[self allPublicationsForCiteKey:key]];
                group = [[BDSKStaticGroup alloc] initWithName:[groupDict objectForKey:@"group name"] publications:pubArray];
                [group setUndoManager:[self undoManager]];
                [staticGroups addObject:group];
            }
            @catch(id exception) {
                NSLog(@"Ignoring exception \"%@\" while parsing static groups data.", exception);
            }
            @finally {
                [group release];
                group = nil;
                [pubArray release];
                pubArray = nil;
            }
        }
        
        [tmpStaticGroups release];
        tmpStaticGroups = nil;
    }
    return staticGroups;
}

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

- (void)addStaticGroup:(BDSKStaticGroup *)group {
	[[[self undoManager] prepareWithInvocationTarget:self] removeStaticGroup:group];
	
	[group setUndoManager:[self undoManager]];
	[[self staticGroups] addObject:group];
    [groupTableView reloadData];
}

- (void)removeStaticGroup:(BDSKStaticGroup *)group {
	[[[self undoManager] prepareWithInvocationTarget:self] addStaticGroup:group];
	
	[group setUndoManager:nil];
	[[self staticGroups] removeObjectIdenticalTo:group];
    [groupTableView reloadData];
}

// assumes you only have a single static group with this name; that assumption is not enforced elsewhere
- (void)removeStaticGroupNamed:(id)name {
    NSEnumerator *e = [[self staticGroups] objectEnumerator];
    BDSKStaticGroup *sGroup = nil;
    
    while(sGroup = [e nextObject]){
        if([[sGroup name] isEqual:name]){
            [self removeStaticGroup:sGroup];
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

#pragma mark Notification handlers

- (void)handleGroupFieldChangedNotification:(NSNotification *)notification{
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

- (void)handleStaticGroupChangedNotification:(NSNotification *)notification{
    BDSKGroup *group = [notification object];
    [groupTableView reloadData];
    if ([[self selectedGroups] containsObject:group])
        [self displaySelectedGroups];
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
        [sharedGroups sortUsingSelector:sortSelector ascending:!sortGroupsDescending];
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
    
    if ([NSString isEmptyString:groupField]) {
        
        [categoryGroups removeAllObjects];
        
    } else {
        
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
            group = [[BDSKCategoryGroup alloc] initWithName:groupName key:groupField count:[countedSet countForObject:groupName]];
            [mutableGroups addObject:group];
            [group release];
        }
        
        // now sort using the current column and order
        SEL sortSelector = ([sortGroupsKey isEqualToString:BDSKGroupCellCountKey]) ?
                            @selector(countCompare:) : @selector(nameCompare:);
        [mutableGroups sortUsingSelector:sortSelector ascending:!sortGroupsDescending];
        
        // add the "empty" group at index 0; this is a group of pubs whose value is empty for this field, so they
        // will not be contained in any of the other groups for the currently selected group field (hence multiple selection is desirable)
        if(emptyCount > 0){
            group = [[BDSKCategoryGroup alloc] initEmptyGroupWithKey:groupField count:emptyCount];
            [mutableGroups insertObject:group atIndex:0];
            [group release];
        }
        
        [categoryGroups setArray:mutableGroups];
        [countedSet release];
        [mutableGroups release];
        
    }
    
    // update the count for the first item, not sure if it should be done here
    [allPublicationsGroup setCount:[publications count]];
	
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
	BOOL shouldUpdate = NO;
    
    while(NSLocationInRange(--row, smartRange)){
		[(BDSKSmartGroup *)[self objectInGroupsAtIndex:row] filterItems:publications];
		if([groupTableView isRowSelected:row])
			shouldUpdate = YES;
    }
    
    if([sortGroupsKey isEqualToString:BDSKGroupCellCountKey]){
        NSPoint scrollPoint = [[tableView enclosingScrollView] scrollPositionAsPercentage];
        [self sortGroupsByKey:sortGroupsKey];
        [[tableView enclosingScrollView] setScrollPositionAsPercentage:scrollPoint];
    }else{
        [groupTableView reloadData];
        if(shouldUpdate == YES){
            // fix for bug #1362191: after changing a checkbox that removed an item from a smart group, the table scrolled to the top
            NSPoint scrollPoint = [[tableView enclosingScrollView] scrollPositionAsPercentage];
            [self displaySelectedGroups];
            [[tableView enclosingScrollView] setScrollPositionAsPercentage:scrollPoint];
        }
    }
}

// simplistic search method for static groups; we don't need the features of the standard searching method

- (NSArray *)publicationsInCurrentGroups{
    NSArray *selectedGroups = [self selectedGroups];
    NSArray *array;
    
    // optimize for single selections
    if ([selectedGroups count] == 1 && [selectedGroups containsObject:allPublicationsGroup]) {
        array = publications;
    } else if ([selectedGroups count] == 1 && ([self hasSharedGroupsSelected] || [self hasStaticGroupsSelected])) {
        unsigned int rowIndex = [[groupTableView selectedRowIndexes] firstIndex];
        BDSKGroup *group = [self objectInGroupsAtIndex:rowIndex];
        array = [(id)group publications];
    } else {
        // multiple selections are never shared groups, so they are contained in the publications
        array = [publications copy];
        
        NSEnumerator *pubEnum = [array objectEnumerator];
        BibItem *pub;
        NSEnumerator *groupEnum;
        BDSKGroup *group;
        NSMutableArray *filteredArray = [NSMutableArray arrayWithCapacity:[array count]];
        BOOL intersectGroups = [[OFPreferenceWrapper sharedPreferenceWrapper] boolForKey:BDSKIntersectGroupsKey];
        
        // to take union, we add the items contained in a selected group
        // to intersect, we remove the items not contained in a selected group
        if (intersectGroups)
            [filteredArray setArray:array];
        
        while (pub = [pubEnum nextObject]) {
            groupEnum = [selectedGroups objectEnumerator];
            while (group = [groupEnum nextObject]) {
                if ([group containsItem:pub] == !intersectGroups) {
                    if (intersectGroups)
                        [filteredArray removeObject:pub];
                    else
                        [filteredArray addObject:pub];
                    break;
                }
            }
        }
        
        [array release];
        array = filteredArray;
    }
	
	return array;
}

- (NSIndexSet *)_indexesOfRowsToHighlightInRange:(NSRange)indexRange tableView:(BDSKGroupTableView *)tview{
   
    if([tableView numberOfSelectedRows] == 0 || 
       [self hasSharedGroupsSelected] == YES)
        return [NSIndexSet indexSet];
    
    // This allows us to be slightly lazy, only putting the visible group rows in the dictionary
    NSIndexSet *visibleIndexes = [NSIndexSet indexSetWithIndexesInRange:indexRange];
    unsigned int cnt = [visibleIndexes count];
    NSRange categoryRange = [self rangeOfCategoryGroups];
    NSString *groupField = [self currentGroupField];

    // Mutable dictionary with fixed capacity using NSObjects for keys with ints for values; this gives us a fast lookup of row name->index.  Dictionaries can use any pointer-size element for a key or value; see /Developer/Examples/CoreFoundation/Dictionary.  Keys are retained rather than copied for efficiency.  Shark says that BibAuthors are created with alloc/init when using the copy callbacks, so NSShouldRetainWithZone() must be returning NO?
    CFMutableDictionaryRef rowDict;
    
    // group objects are either BibAuthors or NSStrings; we need to use case-insensitive or fuzzy author matching, since that's the way groups are checked for containment
    if([[[BibTypeManager sharedManager] personFieldsSet] containsObject:groupField]){
        rowDict = CFDictionaryCreateMutable(CFAllocatorGetDefault(), cnt, &BDSKFuzzyDictionaryKeyCallBacks, &OFIntegerDictionaryValueCallbacks);
    } else {
        rowDict = CFDictionaryCreateMutable(CFAllocatorGetDefault(), cnt, &BDSKCaseInsensitiveStringKeyDictionaryCallBacks, &OFIntegerDictionaryValueCallbacks);
    }
    
    cnt = [visibleIndexes firstIndex];
    
    // exclude smart and shared groups
    while(cnt != NSNotFound){
		if(NSLocationInRange(cnt, categoryRange))
			CFDictionaryAddValue(rowDict, (void *)[[categoryGroups objectAtIndex:cnt - categoryRange.location] name], (void *)cnt);
        cnt = [visibleIndexes indexGreaterThanIndex:cnt];
    }
    
    // Use this for the indexes we're going to return
    NSMutableIndexSet *indexSet = [NSMutableIndexSet indexSet];
    
    // Unfortunately, we have to check all of the items in the main table, since hidden items may have a visible group
    NSIndexSet *rowIndexes = [tableView selectedRowIndexes];
    unsigned int rowIndex = [rowIndexes firstIndex];
    CFSetRef possibleGroups;
        
    id *groupNamePtr;
    
    // use a static pointer to a buffer, with initial size of 10
    static id *groupValues = NULL;
    static int groupValueMaxSize = 10;
    if(NULL == groupValues)
        groupValues = (id *)NSZoneMalloc(NSDefaultMallocZone(), groupValueMaxSize * sizeof(id));
    int groupCount = 0;
    
    // we could iterate the dictionary in the outer loop and publications in the inner loop, but there are generally more publications than groups (and we only check visible groups), so this should be more efficient
    while(rowIndexes != nil && rowIndex != NSNotFound){ 
        
        // here are all the groups that this item can be a part of
        possibleGroups = (CFSetRef)[[shownPublications objectAtIndex:rowIndex] groupsForField:groupField];
        
        groupCount = CFSetGetCount(possibleGroups);
        if(groupCount > groupValueMaxSize){
            NSAssert1(groupCount < 1024, @"insane number of groups for %@", [[shownPublications objectAtIndex:rowIndex] citeKey]);
            groupValues = NSZoneRealloc(NSDefaultMallocZone(), groupValues, sizeof(id) * groupCount);
            groupValueMaxSize = groupCount;
        }
        
        // get all the groups (authors or strings)
        if(groupCount > 0){
            
            // this is the only way to enumerate a set with CF, apparently
            CFSetGetValues(possibleGroups, (const void **)groupValues);
            groupNamePtr = groupValues;
            
            while(groupCount--){
                // The dictionary only has visible group rows, so not all of the keys (potential groups) will exist in the dictionary
                if(CFDictionaryGetValueIfPresent(rowDict, (void *)*groupNamePtr++, (const void **)&cnt))
                    [indexSet addIndex:cnt];
            }
        }
        
        rowIndex = [rowIndexes indexGreaterThanIndex:rowIndex];
    }
    
    CFRelease(rowDict);
    
    // handle smart and static groups separately, since they have a different approach to containment
    NSMutableIndexSet *staticAndSmartIndexes = [NSMutableIndexSet indexSetWithIndexesInRange:[self rangeOfSmartGroups]];
    [staticAndSmartIndexes addIndexesInRange:[self rangeOfStaticGroups]];
    
    if([staticAndSmartIndexes count]){
        rowIndexes = [tableView selectedRowIndexes];
        rowIndex = [rowIndexes firstIndex];
        
        int groupIndex;
        id aGroup;
        
        // enumerate selected publication indexes once, since it should be a much longer array than static + smart groups
        while(rowIndex != NSNotFound){
            
            BibItem *pub = [shownPublications objectAtIndex:rowIndex];
            groupIndex = [staticAndSmartIndexes firstIndex];
            
            // may not be worth it to check for visibility...
            while(groupIndex != NSNotFound && [visibleIndexes containsIndex:groupIndex]){
                aGroup = [self objectInGroupsAtIndex:groupIndex];
                if([aGroup containsItem:pub])
                    [indexSet addIndex:groupIndex];
                groupIndex = [staticAndSmartIndexes indexGreaterThanIndex:groupIndex];
            }
            rowIndex = [rowIndexes indexGreaterThanIndex:rowIndex];
        }
    }
    
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
	
    [menu addItemWithTitle:NSLocalizedString(@"No Field", @"No Field") action:NULL keyEquivalent:@""];
	
	while (field = [fieldEnum nextObject]) {
		[menu addItemWithTitle:field action:NULL keyEquivalent:@""];
	}
    
    [menu addItem:[NSMenuItem separatorItem]];
	
	menuItem = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:[NSLocalizedString(@"Add Field", @"") stringByAppendingEllipsis]
										  action:@selector(addGroupFieldAction:)
								   keyEquivalent:@""];
	[menuItem setTarget:self];
	[menu addItem:menuItem];
    [menuItem release];
	
	menuItem = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:[NSLocalizedString(@"Remove Field", @"") stringByAppendingEllipsis]
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

#pragma mark Actions

- (IBAction)sortGroupsByGroup:(id)sender{
	if ([sortGroupsKey isEqualToString:BDSKGroupCellStringKey]) return;
	[self sortGroupsByKey:BDSKGroupCellStringKey];
}

- (IBAction)sortGroupsByCount:(id)sender{
	if ([sortGroupsKey isEqualToString:BDSKGroupCellCountKey]) return;
	[self sortGroupsByKey:BDSKGroupCellCountKey];
}

- (IBAction)changeGroupFieldAction:(id)sender{
	NSPopUpButtonCell *headerCell = [groupTableView popUpHeaderCell];
	NSString *field = ([headerCell indexOfSelectedItem] == 0) ? @"" : [headerCell titleOfSelectedItem];
    
	if(![field isEqualToString:currentGroupField]){
		[self setCurrentGroupField:field];
        [headerCell setTitle:field];
		
		[[NSNotificationCenter defaultCenter] postNotificationName:BDSKGroupFieldChangedNotification
															object:self
														  userInfo:[NSDictionary dictionary]];
	}
}

// for adding/removing groups, we use the searchfield sheets
    
- (void)addGroupFieldSheetDidEnd:(BDSKAddFieldSheetController *)addFieldController returnCode:(int)returnCode contextInfo:(void *)contextInfo{
	NSString *newGroupField = [addFieldController field];
    if(returnCode == NSCancelButton || newGroupField == nil)
        return; // the user canceled
    
	if([[[BibTypeManager sharedManager] invalidGroupFields] containsObject:newGroupField] || [newGroupField isEqualToString:@""]){
        NSAlert *alert = [NSAlert alertWithMessageText:NSLocalizedString(@"Invalid Field", @"Invalid Field")
                                         defaultButton:nil
                                       alternateButton:nil
                                           otherButton:nil
                            informativeTextWithFormat:[NSString stringWithFormat:NSLocalizedString(@"The field \"%@\" can not be used for groups.", @""), newGroupField]];
        [alert beginSheetModalForWindow:documentWindow modalDelegate:self didEndSelector:NULL contextInfo:NULL];
		return;
	}
	
	NSMutableArray *array = [[[OFPreferenceWrapper sharedPreferenceWrapper] stringArrayForKey:BDSKGroupFieldsKey] mutableCopy];
	[array addObject:newGroupField];
	[[OFPreferenceWrapper sharedPreferenceWrapper] setObject:array forKey:BDSKGroupFieldsKey];	
    
    [[NSNotificationCenter defaultCenter] postNotificationName:BDSKGroupAddRemoveNotification
                                                        object:self
                                                      userInfo:[NSDictionary dictionaryWithObjectsAndKeys:newGroupField, NSKeyValueChangeNewKey, [NSNumber numberWithInt:NSKeyValueChangeInsertion], NSKeyValueChangeKindKey, nil]];        
    
	NSPopUpButtonCell *headerCell = [groupTableView popUpHeaderCell];
	
	[headerCell insertItemWithTitle:newGroupField atIndex:[array count]];
	[self setCurrentGroupField:newGroupField];
	[headerCell selectItemWithTitle:currentGroupField];
	[headerCell setTitle:currentGroupField];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:BDSKGroupFieldChangedNotification
														object:self
													  userInfo:[NSDictionary dictionary]];
    [array release];
}    

- (IBAction)addGroupFieldAction:(id)sender{
	NSPopUpButtonCell *headerCell = [groupTableView popUpHeaderCell];
	
	[headerCell setTitle:currentGroupField];
    if ([currentGroupField isEqualToString:@""])
        [headerCell selectItemAtIndex:0];
    else 
        [headerCell selectItemWithTitle:currentGroupField];
    
	BibTypeManager *typeMan = [BibTypeManager sharedManager];
	NSArray *groupFields = [[OFPreferenceWrapper sharedPreferenceWrapper] stringArrayForKey:BDSKGroupFieldsKey];
    NSArray *colNames = [typeMan allFieldNamesIncluding:[NSArray arrayWithObjects:BDSKPubTypeString, BDSKCrossrefString, nil]
                                              excluding:[[[typeMan invalidGroupFields] allObjects] arrayByAddingObjectsFromArray:groupFields]];
    
    BDSKAddFieldSheetController *addFieldController = [[BDSKAddFieldSheetController alloc] initWithPrompt:NSLocalizedString(@"Name of group field:",@"")
                                                                                              fieldsArray:colNames];
	[addFieldController beginSheetModalForWindow:documentWindow
                                   modalDelegate:self
                                  didEndSelector:NULL
                              didDismissSelector:@selector(addGroupFieldSheetDidEnd:returnCode:contextInfo:)
                                     contextInfo:NULL];
    [addFieldController release];
}

- (void)removeGroupFieldSheetDidEnd:(BDSKRemoveFieldSheetController *)removeFieldController returnCode:(int)returnCode contextInfo:(void *)contextInfo{
	NSString *oldGroupField = [removeFieldController field];
    if(returnCode == NSCancelButton || [NSString isEmptyString:oldGroupField])
        return;
    
    NSMutableArray *array = [[[OFPreferenceWrapper sharedPreferenceWrapper] stringArrayForKey:BDSKGroupFieldsKey] mutableCopy];
    [array removeObject:oldGroupField];
    [[OFPreferenceWrapper sharedPreferenceWrapper] setObject:array forKey:BDSKGroupFieldsKey];
    [array release];
    
	NSPopUpButtonCell *headerCell = [groupTableView popUpHeaderCell];
	
    [headerCell removeItemWithTitle:oldGroupField];
    if([oldGroupField isEqualToString:currentGroupField]){
        [self setCurrentGroupField:@""];
        [headerCell selectItemAtIndex:0];
        [headerCell setTitle:@""];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:BDSKGroupFieldChangedNotification
                                                            object:self
                                                          userInfo:[NSDictionary dictionary]];
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:BDSKGroupAddRemoveNotification
                                                        object:self
                                                      userInfo:[NSDictionary dictionaryWithObjectsAndKeys:oldGroupField, NSKeyValueChangeNewKey, [NSNumber numberWithInt:NSKeyValueChangeRemoval], NSKeyValueChangeKindKey, nil]];        
}

- (IBAction)removeGroupFieldAction:(id)sender{
	NSPopUpButtonCell *headerCell = [groupTableView popUpHeaderCell];
	
	[headerCell setTitle:currentGroupField];
    if ([currentGroupField isEqualToString:@""])
        [headerCell selectItemAtIndex:0];
    else 
        [headerCell selectItemWithTitle:currentGroupField];
    
    BDSKRemoveFieldSheetController *removeFieldController = [[BDSKRemoveFieldSheetController alloc] initWithPrompt:NSLocalizedString(@"Group field to remove:",@"")
                                                                                                       fieldsArray:[[OFPreferenceWrapper sharedPreferenceWrapper] stringArrayForKey:BDSKGroupFieldsKey]];
	[removeFieldController beginSheetModalForWindow:documentWindow
                                      modalDelegate:self
                                     didEndSelector:@selector(removeGroupFieldSheetDidEnd:returnCode:contextInfo:)
                                        contextInfo:NULL];
    [removeFieldController release];
}    

- (void)handleGroupAddRemoveNotification:(NSNotification *)notification{
    // Handle changes to the popup from other documents.  The userInfo for this notification uses key-value observing keys: NSKeyValueChangeNewKey is the affected field (whether add/remove), and NSKeyValueChangeKindKey will be either insert/remove
    if([notification object] != self){
        NSPopUpButtonCell *headerCell = [groupTableView popUpHeaderCell];
        
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

- (IBAction)addSmartGroupAction:(id)sender {
	BDSKFilterController *filterController = [[BDSKFilterController alloc] init];
    [filterController beginSheetModalForWindow:documentWindow
                                 modalDelegate:self
                                didEndSelector:@selector(addSmartGroupSheetDidEnd:returnCode:contextInfo:)
                                   contextInfo:NULL];
	[filterController release];
}

- (IBAction)addSmartGroupSheetDidEnd:(BDSKFilterController *)filterController returnCode:(int) returnCode contextInfo:(void *)contextInfo{
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
	
}

- (IBAction)addStaticGroupAction:(id)sender {
    BDSKStaticGroup *group = [[BDSKStaticGroup alloc] init];
    unsigned int insertIndex = NSMaxRange([self rangeOfStaticGroups]);
    [self addStaticGroup:group];
    [group release];
    
    [groupTableView reloadData];
    [groupTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:insertIndex] byExtendingSelection:NO];
    [groupTableView editColumn:0 row:insertIndex withEvent:nil select:YES];
    [[self undoManager] setActionName:NSLocalizedString(@"Add Static Group",@"Add static group")];
    // updating of the tables is done when finishing the edit of the name
}

- (IBAction)addGroupButtonAction:(id)sender {
    if ([[NSApp currentEvent] modifierFlags] & NSAlternateKeyMask)
        [self addSmartGroupAction:sender];
    else
        [self addStaticGroupAction:sender];
}

- (IBAction)removeSelectedGroups:(id)sender {
	NSIndexSet *rowIndexes = [groupTableView selectedRowIndexes];
    unsigned int rowIndex = [rowIndexes lastIndex];
	BDSKGroup *group;
	unsigned int count = 0;
	
	while (rowIndexes != nil && rowIndex != NSNotFound) {
		group = [self objectInGroupsAtIndex:rowIndex];
		if ([group isSmart] == YES) {
			[self removeSmartGroup:(BDSKSmartGroup *)group];
			count++;
		} else if ([group isStatic] == YES && group != lastImportGroup) {
			[self removeStaticGroup:(BDSKStaticGroup *)group];
			count++;
        }
		rowIndex = [rowIndexes indexLessThanIndex:rowIndex];
	}
	if (count == 0) {
		NSBeep();
	} else {
		[[self undoManager] setActionName:NSLocalizedString(@"Remove Groups",@"Remove groups")];
        [groupTableView reloadData];
        [self displaySelectedGroups];
	}
}

- (IBAction)editGroupAction:(id)sender {
	if ([groupTableView numberOfSelectedRows] != 1) {
		NSBeep();
		return;
	} 
	
	int row = [groupTableView selectedRow];
	OBASSERT(row != -1);
	if(row <= 0) return;
	BDSKGroup *group = [self objectInGroupsAtIndex:row];
	
    if ([group isEditable] == NO) {
		NSBeep();
        return;
    }
    
	if ([group isSmart]) {
		BDSKFilter *filter = [(BDSKSmartGroup *)group filter];
		BDSKFilterController *filterController = [[BDSKFilterController alloc] initWithFilter:filter];
        
        [filterController beginSheetModalForWindow:documentWindow];
        [filterController release];
	} else if ([group isCategory]) {
        // this must be a person field
        OBASSERT([[group name] isKindOfClass:[BibAuthor class]]);
		[self showPerson:(BibAuthor *)[group name]];
	}
}

- (IBAction)renameGroupAction:(id)sender {
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

- (IBAction)changeIntersectGroupsAction:(id)sender {
    BOOL flag = (BOOL)[sender tag];
    if ([[OFPreferenceWrapper sharedPreferenceWrapper] boolForKey:BDSKIntersectGroupsKey] != flag) {
        [[OFPreferenceWrapper sharedPreferenceWrapper] setBool:flag forKey:BDSKIntersectGroupsKey];
        [[NSNotificationCenter defaultCenter] postNotificationName:BDSKGroupTableSelectionChangedNotification object:self];
    }
}

- (IBAction)editNewGroupWithSelection:(id)sender{
    NSArray *names = [[self staticGroups] valueForKeyPath:@"@distinctUnionOfObjects.name"];
    NSArray *pubs = [self selectedPublications];
    NSString *baseName = NSLocalizedString(@"Untitled", @"");
    NSString *name = baseName;
    BDSKStaticGroup *group;
    unsigned int i = 1;
    while([names containsObject:name]){
        name = [NSString stringWithFormat:@"%@%d", baseName, i++];
    }
    
    // first merge in shared groups
    if ([self hasSharedGroupsSelected] == YES)
        pubs = [self mergeInPublications:pubs];
    
    group = [[[BDSKStaticGroup alloc] initWithName:name publications:pubs] autorelease];
    
    [self addStaticGroup:group];    
    [groupTableView deselectAll:nil];
    
    i = [[self staticGroups] indexOfObject:group];
    OBASSERT(i != NSNotFound);
    
    if(i != NSNotFound){
        i += [self rangeOfStaticGroups].location;
        [groupTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:i] byExtendingSelection:NO];
        [groupTableView scrollRowToVisible:i];
        
        [groupTableView editColumn:0 row:i withEvent:nil select:YES];
    }
}

- (IBAction)mergeInSharedGroup:(id)sender{
    if ([self hasSharedGroupsSelected] == NO) {
        NSBeep();
        return;
    }
    // we should have a single shared group selected
    [self mergeInPublications:[self publicationsInCurrentGroups]];
}

- (IBAction)mergeInSharedPublications:(id)sender{
    if ([self hasSharedGroupsSelected] == NO || [self numberOfSelectedPubs] == 0) {
        NSBeep();
        return;
    }
    [self mergeInPublications:[self selectedPublications]];
}

#pragma mark Add or remove items

- (NSArray *)mergeInPublications:(NSArray *)items{
    // first construct a set of current items to compare based on BibItem equality callbacks
    CFIndex countOfItems = [publications count];
    BibItem **pubs = (BibItem **)NSZoneMalloc([self zone], sizeof(BibItem *) * countOfItems);
    [publications getObjects:pubs];
    NSSet *currentPubs = (NSSet *)CFSetCreate(CFAllocatorGetDefault(), (const void **)pubs, countOfItems, &BDSKBibItemEqualityCallBacks);
    NSZoneFree([self zone], pubs);
    
    NSMutableArray *array = [NSMutableArray arrayWithCapacity:[items count]];
    NSEnumerator *pubEnum = [items objectEnumerator];
    BibItem *pub;
    
    while (pub = [pubEnum nextObject]) {
        if ([currentPubs containsObject:pub] == NO)
            [array addObject:pub];
    }
    
    if ([array count] == 0)
        return [NSArray array];
    
    // archive and unarchive mainly to get complex strings with the correct macroResolver
    NSMutableData *data = [NSMutableData data];
    NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
    NSArray *newPubs;
    
    [archiver encodeObject:array forKey:@"publications"];
    [archiver finishEncoding];
    [archiver release];
    
    newPubs = [self newPublicationsFromArchivedData:data];
    
    [groupTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];    
	[self addPublications:newPubs];
	[self highlightBibs:newPubs];
    
    if(lastImportGroup == nil)
        lastImportGroup = [[BDSKStaticGroup alloc] initWithLastImport:newPubs];
    else 
        [lastImportGroup setPublications:newPubs];
	
	[[self undoManager] setActionName:NSLocalizedString(@"Merge Shared Publications",@"")];
    
    return newPubs;
}

- (BOOL)addPublications:(NSArray *)pubs toGroup:(BDSKGroup *)group{
	OBASSERT([group isSmart] == NO && [group isShared] == NO && group != allPublicationsGroup && group != lastImportGroup);
    
    if ([group isStatic]) {
        [(BDSKStaticGroup *)group addPublicationsFromArray:pubs];
		[[self undoManager] setActionName:NSLocalizedString(@"Add To Group", @"Add to group")];
        return YES;
    }
    
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
			rv = [alert runSheetModalForWindow:documentWindow];
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
		if([group isSmart] == YES || [group isShared] == YES || group == allPublicationsGroup || group == lastImportGroup)
			continue;
		
		if (groupName == nil)
			groupName = [NSString stringWithFormat:@"group %@", [group name]];
		else
			groupName = @"selected groups";
		
        if ([group isStatic]) {
            [(BDSKStaticGroup *)group removePublicationsInArray:pubs];
            [[self undoManager] setActionName:NSLocalizedString(@"Remove From Group", @"Remove from group")];
            count = [pubs count];
            continue;
        } else if ([group isCategory] && [[[BibTypeManager sharedManager] singleValuedGroupFields] containsObject:[(BDSKCategoryGroup *)group key]]) {
            continue;
        }
		
		NSEnumerator *pubEnum = [pubs objectEnumerator];
		BibItem *pub;
		int rv;
        int tmpCount = 0;
		
		while(pub = [pubEnum nextObject]){
			OBASSERT([pub isKindOfClass:[BibItem class]]);        
			
			rv = [pub removeFromGroup:group handleInherited:handleInherited];
			
			if(rv == BDSKOperationSet || rv == BDSKOperationAppend){
				tmpCount++;
			}else if(rv == BDSKOperationAsk){
				BDSKAlert *alert = [BDSKAlert alertWithMessageText:NSLocalizedString(@"Inherited Value", @"alert title")
													 defaultButton:NSLocalizedString(@"Don't Change", @"Don't change")
												   alternateButton:nil
													   otherButton:NSLocalizedString(@"Remove", @"Remove")
										 informativeTextWithFormat:NSLocalizedString(@"One or more items have a value that was inherited from an item linked to by the Crossref field. This operation would break the inheritance for this value. What do you want me to do with inherited values?", @"")];
				rv = [alert runSheetModalForWindow:documentWindow];
				handleInherited = rv;
				if(handleInherited != BDSKOperationIgnore){
					[pub removeFromGroup:group handleInherited:handleInherited];
				}
			}
		}
        
        count = MAX(count, tmpCount);
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
	
	if([group isCategory] == NO)
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
			rv = [alert runSheetModalForWindow:documentWindow];
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

#pragma mark Sorting

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
        if(sortGroupsDescending == NO)
            countSort = [countSort reversedSortDescriptor];
        sortDescriptors = [NSArray arrayWithObjects:nameSort, countSort, nil];
    }
    
    BDSKGroup *emptyGroup = nil;
    
    if ([categoryGroups count] > 0) {
        id firstName = [[categoryGroups objectAtIndex:0] name];
        if ([firstName isEqual:@""] || [firstName isEqual:[BibAuthor emptyAuthor]]) {
            emptyGroup = [[categoryGroups objectAtIndex:0] retain];
            [categoryGroups removeObjectAtIndex:0];
        }
    }
    
    [categoryGroups sortUsingDescriptors:sortDescriptors];
    [smartGroups sortUsingDescriptors:sortDescriptors];
    [sharedGroups sortUsingDescriptors:sortDescriptors];
    [[self staticGroups] sortUsingDescriptors:sortDescriptors];
	
    if (emptyGroup != nil) {
        [categoryGroups insertObject:emptyGroup atIndex:0];
        [emptyGroup release];
    }
    
    // Set the graphic for the new column header
	BDSKHeaderPopUpButtonCell *headerPopup = (BDSKHeaderPopUpButtonCell *)[groupTableView popUpHeaderCell];
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

#pragma mark Serializing

- (void)setSmartGroupsFromSerializedData:(NSData *)data {
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
    BDSKSmartGroup *group = nil;
    BDSKFilter *filter = nil;
    
    while (groupDict = [groupEnum nextObject]) {
        @try {
            filter = [[BDSKFilter alloc] initWithDictionary:groupDict];
            group = [[BDSKSmartGroup alloc] initWithName:[groupDict objectForKey:@"group name"] count:0 filter:filter];
            [group setUndoManager:[self undoManager]];
            [array addObject:group];
        }
        @catch(id exception) {
            NSLog(@"Ignoring exception \"%@\" while parsing smart groups data.", exception);
        }
        @finally {
            [group release];
            group = nil;
            [filter release];
            filter = nil;
        }
    }
	
	[smartGroups setArray:array];
}

- (void)setStaticGroupsFromSerializedData:(NSData *)data {
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
		NSLog(@"Serialized static groups was no array.");
		return;
	}
	
    tmpStaticGroups = [plist retain];
}

- (NSData *)serializedSmartGroupsData {
	NSMutableArray *array = [NSMutableArray arrayWithCapacity:[smartGroups count]];
    NSDictionary *groupDict;
	NSEnumerator *groupEnum = [smartGroups objectEnumerator];
	BDSKSmartGroup *group;
	
	while (group = [groupEnum nextObject]) {
		groupDict = [[[group filter] dictionaryValue] mutableCopy];
		[(NSMutableDictionary *)groupDict setObject:[group stringValue] forKey:@"group name"];
		[array addObject:groupDict];
		[groupDict release];
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

- (NSData *)serializedStaticGroupsData {
	NSMutableArray *array = [NSMutableArray arrayWithCapacity:[[self staticGroups] count]];
	NSString *keys;
    NSDictionary *groupDict;
	NSEnumerator *groupEnum = [[self staticGroups] objectEnumerator];
	BDSKStaticGroup *group;
	
	while (group = [groupEnum nextObject]) {
		keys = [[[group publications] valueForKeyPath:@"@distinctUnionOfObjects.citeKey"] componentsJoinedByString:@","];
        groupDict = [[NSDictionary alloc] initWithObjectsAndKeys:[group stringValue], @"group name", keys, @"keys", nil];
		[array addObject:groupDict];
		[groupDict release];
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

@end
