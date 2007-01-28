//
//  BDSKSearchField.m
//  Bibdesk
//
//  Created by Christiaan Hofman on 11/14/06.
/*
 This software is Copyright (c) 2006,2007
 Christiaan Hofman. All rights reserved.

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:

 - Redistributions of source code must retain the above copyright
   notice, this list of conditions and the following disclaimer.

 - Redistributions in binary form must reproduce the above copyright
    notice, this list of conditions and the following disclaimer in
    the documentation and/or other materials provided with the
    distribution.

 - Neither the name of Christiaan Hofman nor the names of any
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

#import "BDSKSearchField.h"
#import "BibPrefController.h"
#import "BDSKFieldSheetController.h"
#import "BibTypeManager.h"

NSString *BDSKFileContentLocalizedString = nil;

@interface BDSKSearchField (Private)
- (NSMenu *)searchFieldMenu;
- (void)searchFieldChangeKey:(id)sender;
- (void)quickSearchAddField:(id)sender;
- (void)quickSearchRemoveField:(id)sender;
- (void)addSearchFieldSheetDidEnd:(BDSKAddFieldSheetController *)addFieldController returnCode:(int)returnCode contextInfo:(void *)contextInfo;
- (void)removeSearchFieldSheetDidEnd:(BDSKRemoveFieldSheetController *)removeFieldController returnCode:(int)returnCode contextInfo:(void *)contextInfo;
@end

@implementation BDSKSearchField

+ (void)didLoad{
    BDSKFileContentLocalizedString = [NSLocalizedString(@"File Content", @"Search menu item title") copy];
}

- (id)initWithFrame:(NSRect)frame {
    if (self = [super initWithFrame:frame]) {
        searchKey = nil;
        [[self cell] setSearchMenuTemplate:[self searchFieldMenu]];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)decoder {
    if (self = [super initWithCoder:decoder]) {
        searchKey = [[decoder decodeObjectForKey:@"searchKey"] retain];
        NSMenu *templateMenu = [self searchFieldMenu];
        if(searchKey)
            [[templateMenu itemWithTitle:searchKey] setState:NSOnState];
        [[self cell] setSearchMenuTemplate:templateMenu];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
	[super encodeWithCoder:encoder];
	[encoder encodeObject:searchKey forKey:@"searchKey"];
}

- (void)dealloc{
    [searchKey release];
    [super dealloc];
}

- (NSString *)searchKey {
    return searchKey;
}

- (void)setSearchKey:(NSString *)newKey {
    [[OFPreferenceWrapper sharedPreferenceWrapper] setObject:newKey
                                                      forKey:BDSKCurrentQuickSearchKey];
	
	NSSearchFieldCell *searchCell = [self cell];
	[searchCell setPlaceholderString:[NSString stringWithFormat:NSLocalizedString(@"Search by %@", @"Search placeholder string"), newKey]];

	NSMenu *templateMenu = [searchCell searchMenuTemplate];
	if([searchKey isEqualToString:newKey] == NO){
        if(searchKey != nil)
            [[templateMenu itemWithTitle:searchKey] setState:NSOffState];
        [searchKey release];
		searchKey = [newKey copy];
	}
	
	// set new key's menuitem to NSOnState
	NSMenuItem *newItem = [templateMenu itemWithTitle:searchKey];
	[newItem setState:NSOnState];
    
    // reset the template, since we can't modify the actual menu directly
	[searchCell setSearchMenuTemplate:templateMenu];
}

// assert some assumptions that are made at various places

- (void)setTarget:(id)obj {
    if (obj) NSParameterAssert([obj respondsToSelector:[self action]]);
    [super setTarget:obj];
}

- (void)setAction:(SEL)anAction {
    NSParameterAssert(@selector(search:) == anAction);
    [super setAction:anAction];
}

- (SEL)action { return @selector(search:); }

@end


@implementation BDSKSearchField (Private)

- (NSMenu *)searchFieldMenu{
	NSMenu *cellMenu = [[[NSMenu allocWithZone:[NSMenu menuZone]] initWithTitle:@"Search Menu"] autorelease];
	NSMenuItem *anItem;
	
	anItem = [cellMenu addItemWithTitle:NSLocalizedString(@"Recent Searches", @"Menu item title") action:NULL keyEquivalent:@""];
    [anItem setTag:NSSearchFieldRecentsTitleMenuItemTag];
	
    anItem = [cellMenu addItemWithTitle:@"" action:NULL keyEquivalent:@""];
	[anItem setTag:NSSearchFieldRecentsMenuItemTag];
    
	anItem = [cellMenu addItemWithTitle:NSLocalizedString(@"Clear Recent Searches", @"Menu item title") action:NULL keyEquivalent:@""];
	[anItem setTag:NSSearchFieldClearRecentsMenuItemTag];
    
    // this tag conditionally inserts a separator if there are recent searches (is it safe to set a tag on the separator item?)
    anItem = [NSMenuItem separatorItem];
	[anItem setTag:NSSearchFieldRecentsTitleMenuItemTag];
	[cellMenu addItem:anItem];
    
	[cellMenu addItemWithTitle:NSLocalizedString(@"Search Types", @"Menu item title") action:NULL keyEquivalent:@""];
    [cellMenu addItemWithTitle:BDSKAllFieldsString action:@selector(searchFieldChangeKey:) keyEquivalent:@""];
    
    // add a separator; "File Content" and "Any Field" are special (and "File Content" looks out of place between "Any Field" and "Author")
    [cellMenu addItemWithTitle:BDSKFileContentLocalizedString action:@selector(searchFieldChangeKey:) keyEquivalent:@""];
	[anItem setTarget:self];
    [cellMenu addItem:[NSMenuItem separatorItem]];
        
	NSMutableArray *searchKeys = [[NSMutableArray alloc] initWithObjects:BDSKAuthorString, BDSKPubDateString, BDSKTitleString, nil];
    [searchKeys addObjectsFromArray:[[OFPreferenceWrapper sharedPreferenceWrapper] stringArrayForKey:BDSKQuickSearchKeys]];
    [searchKeys sortUsingSelector:@selector(compare:)];
    
    NSString *aKey = nil;
    NSEnumerator *searchKeyE = [searchKeys objectEnumerator];
	
    while(aKey = [searchKeyE nextObject]){
		[cellMenu addItemWithTitle:aKey action:@selector(searchFieldChangeKey:) keyEquivalent:@""]; 
        [anItem setTarget:self];
    }
    [searchKeys release];
	
	[cellMenu addItem:[NSMenuItem separatorItem]];
	
	[cellMenu addItemWithTitle:[NSLocalizedString(@"Add Field", @"Menu item title") stringByAppendingEllipsis] action:@selector(quickSearchAddField:) keyEquivalent:@""];
	[anItem setTarget:self];
	[cellMenu addItemWithTitle:[NSLocalizedString(@"Remove Field", @"Menu item title") stringByAppendingEllipsis] action:@selector(quickSearchRemoveField:) keyEquivalent:@""];
	[anItem setTarget:self];
    
	return cellMenu;
}

- (void)searchFieldChangeKey:(id)sender{
    [self setSearchKey:[sender title]];
    [self sendAction:[self action] to:[self target]];
}

- (void)addSearchFieldSheetDidEnd:(BDSKAddFieldSheetController *)addFieldController returnCode:(int)returnCode contextInfo:(void *)contextInfo{
	NSString *newSearchKey = [addFieldController field];
    if(returnCode == NSCancelButton || [NSString isEmptyString:newSearchKey])
        return;
    
    newSearchKey = [newSearchKey fieldName];
    NSMutableArray *newSearchKeys = [NSMutableArray arrayWithCapacity:10];
    [newSearchKeys addObjectsFromArray:[[OFPreferenceWrapper sharedPreferenceWrapper] arrayForKey:BDSKQuickSearchKeys]];
    [newSearchKeys addObject:newSearchKey];
    [[OFPreferenceWrapper sharedPreferenceWrapper] setObject:newSearchKeys
                                                      forKey:BDSKQuickSearchKeys];
    
    // this will sort the menu items for us
    [[self cell] setSearchMenuTemplate:[self searchFieldMenu]];
    [self setSearchKey:newSearchKey];
    [self sendAction:[self action] to:[self target]];
}

- (void)quickSearchAddField:(id)sender{
    // first we fill the popup
    NSArray *searchKeys = [[BibTypeManager sharedManager] allFieldNamesIncluding:[NSArray arrayWithObjects:BDSKPubTypeString, BDSKCiteKeyString, BDSKPubDateString, BDSKDateAddedString, BDSKDateModifiedString, nil]
                                                                       excluding:[[OFPreferenceWrapper sharedPreferenceWrapper] arrayForKey:BDSKQuickSearchKeys]];
    
    BDSKAddFieldSheetController *addFieldController = [[BDSKAddFieldSheetController alloc] initWithPrompt:NSLocalizedString(@"Field to search:", @"Label for adding field")
                                                                                              fieldsArray:searchKeys];
	[addFieldController beginSheetModalForWindow:[self window]
                                   modalDelegate:self
                                  didEndSelector:@selector(addSearchFieldSheetDidEnd:returnCode:contextInfo:)
                                     contextInfo:NULL];
    [addFieldController release];
}

- (void)removeSearchFieldSheetDidEnd:(BDSKRemoveFieldSheetController *)removeFieldController returnCode:(int)returnCode contextInfo:(void *)contextInfo{
    NSMutableArray *searchKeys = [NSMutableArray arrayWithCapacity:10];
    [searchKeys addObjectsFromArray:[[OFPreferenceWrapper sharedPreferenceWrapper] arrayForKey:BDSKQuickSearchKeys]];

	NSString *oldSearchKey = [removeFieldController field];
    if(returnCode == NSCancelButton || oldSearchKey == nil || [searchKeys count] == 0)
        return;
    
    [searchKeys removeObject:oldSearchKey];
    [[OFPreferenceWrapper sharedPreferenceWrapper] setObject:searchKeys
                                                      forKey:BDSKQuickSearchKeys];

    [[self cell] setSearchMenuTemplate:[self searchFieldMenu]];
    if([searchKey isEqualToString:oldSearchKey]){
        [self setSearchKey:BDSKAllFieldsString];
        [self sendAction:[self action] to:[self target]];
    }
}

- (void)quickSearchRemoveField:(id)sender{
    NSMutableArray *searchKeys = [NSMutableArray arrayWithCapacity:10];
    [searchKeys addObjectsFromArray:[[OFPreferenceWrapper sharedPreferenceWrapper] arrayForKey:BDSKQuickSearchKeys]];
    [searchKeys sortUsingSelector:@selector(caseInsensitiveCompare:)];

    NSString *prompt = NSLocalizedString(@"Search field to remove:", @"Label for removing field");
	if ([searchKeys count]) {
		[searchKeys sortUsingSelector:@selector(caseInsensitiveCompare:)];
	} else {
		prompt = NSLocalizedString(@"No search fields to remove", @"Label when no field to remove");
	}
    
    BDSKRemoveFieldSheetController *removeFieldController = [[BDSKRemoveFieldSheetController alloc] initWithPrompt:prompt
                                                                                                       fieldsArray:searchKeys];
	[removeFieldController beginSheetModalForWindow:[self window]
                                      modalDelegate:self
                                     didEndSelector:@selector(removeSearchFieldSheetDidEnd:returnCode:contextInfo:)
                                        contextInfo:NULL];
    [removeFieldController release];
}

@end
