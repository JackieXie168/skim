//
//  BibDocument_Groups.h
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

#import <Cocoa/Cocoa.h>
#import "BibDocument.h"

@class BDSKSmartGroup;
@class BDSKStaticGroup;

@interface BibDocument (Groups)

- (unsigned int)countOfGroups;
- (BDSKGroup *)objectInGroupsAtIndex:(unsigned int)index;

- (NSRange)rangeOfCategoryGroups;
- (NSRange)rangeOfSmartGroups;
- (NSRange)rangeOfSharedGroups;
- (NSRange)rangeOfStaticGroups;
- (unsigned int)numberOfCategoryGroupsAtIndexes:(NSIndexSet *)indexes;
- (unsigned int)numberOfSmartGroupsAtIndexes:(NSIndexSet *)indexes;
- (unsigned int)numberOfSharedGroupsAtIndexes:(NSIndexSet *)indexes;
- (unsigned int)numberOfStaticGroupsAtIndexes:(NSIndexSet *)indexes;
- (BOOL)hasCategoryGroupsAtIndexes:(NSIndexSet *)indexes;
- (BOOL)hasCategoryGroupsSelected;
- (BOOL)hasSmartGroupsAtIndexes:(NSIndexSet *)indexes;
- (BOOL)hasSmartGroupsSelected;
- (BOOL)hasSharedGroupsAtIndexes:(NSIndexSet *)indexes;
- (BOOL)hasSharedGroupsSelected;
- (BOOL)hasStaticGroupsAtIndexes:(NSIndexSet *)indexes;
- (BOOL)hasStaticGroupsSelected;

- (void)addSmartGroup:(BDSKSmartGroup *)group;
- (void)removeSmartGroup:(BDSKSmartGroup *)group;
- (void)removeSmartGroupNamed:(id)name;
- (void)addStaticGroup:(BDSKStaticGroup *)group;
- (void)removeStaticGroup:(BDSKStaticGroup *)group;
- (void)removeStaticGroupNamed:(id)name;
- (void)setCurrentGroupField:(NSString *)field;
- (NSString *)currentGroupField;

- (NSMutableArray *)staticGroups;

- (NSArray *)selectedGroups;
- (NSArray *)selectedSharedPublications;
- (void)updateGroupsPreservingSelection:(BOOL)preserve;
- (void)displaySelectedGroups;
- (void)selectGroup:(BDSKGroup *)aGroup;
- (void)selectGroups:(NSArray *)theGroups;

- (void)updateAllSmartGroups;
- (NSArray *)publicationsInCurrentGroups;
- (BOOL)addPublications:(NSArray *)pubs toGroup:(BDSKGroup *)group;
- (BOOL)removePublications:(NSArray *)pubs fromGroups:(NSArray *)groupArray;
- (BOOL)movePublications:(NSArray *)pubs fromGroup:(BDSKGroup *)group toGroupNamed:(NSString *)newGroupName;
- (NSMenu *)groupFieldsMenu;

- (IBAction)changeGroupFieldAction:(id)sender;
- (IBAction)addGroupFieldAction:(id)sender;
- (IBAction)removeGroupFieldAction:(id)sender;

- (void)handleGroupFieldChangedNotification:(NSNotification *)notification;
- (void)handleGroupAddRemoveNotification:(NSNotification *)notification;
- (void)handleStaticGroupChangedNotification:(NSNotification *)notification;
- (void)handleSharedGroupUpdatedNotification:(NSNotification *)notification;
- (void)handleSharedGroupsChangedNotification:(NSNotification *)notification;
- (void)handleGroupTableSelectionChangedNotification:(NSNotification *)notification;

- (IBAction)sortGroupsByGroup:(id)sender;
- (IBAction)sortGroupsByCount:(id)sender;
- (IBAction)addSmartGroupAction:(id)sender;
- (IBAction)addStaticGroupAction:(id)sender;
- (IBAction)addGroupButtonAction:(id)sender;
- (IBAction)removeSelectedGroups:(id)sender;
- (IBAction)editGroupAction:(id)sender;
- (IBAction)renameGroupAction:(id)sender;
- (IBAction)selectAllPublicationsGroup:(id)sender;
- (IBAction)editNewGroupWithSelection:(id)sender;
- (void)addSmartGroupSheetDidEnd:(NSWindow *)sheet returnCode:(int) returnCode contextInfo:(void *)contextInfo;

- (IBAction)mergeInSharedGroup:(id)sender;
- (IBAction)mergeInSharedPublications:(id)sender;
- (NSArray *)mergeInPublications:(NSArray *)items;

- (void)setSmartGroupsFromSerializedData:(NSData *)data;
- (void)setStaticGroupsFromSerializedData:(NSData *)data;
- (NSData *)serializedSmartGroupsData;
- (NSData *)serializedStaticGroupsData;

- (void)handleFilterChangedNotification:(NSNotification *)notification;
- (void)sortGroupsByKey:(NSString *)key;

- (NSIndexSet *)_indexesOfRowsToHighlightInRange:(NSRange)indexRange tableView:(BDSKGroupTableView *)tview;
- (NSIndexSet *)_tableViewSingleSelectionIndexes:(BDSKGroupTableView *)tview;

@end
