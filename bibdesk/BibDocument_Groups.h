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

@interface BibDocument (Groups)

- (unsigned int)countOfGroups;
- (BDSKGroup *)objectInGroupsAtIndex:(unsigned int)index;
- (void)addSmartGroup:(BDSKSmartGroup *)group;
- (void)removeSmartGroup:(BDSKSmartGroup *)group;
- (void)setCurrentGroupField:(NSString *)field;
- (NSString *)currentGroupField;
- (NSArray *)selectedGroups;
- (void)updateGroupsPreservingSelection:(BOOL)preserve;
- (void)displaySelectedGroups;
- (void)updateAllSmartGroups;
- (NSArray *)publicationsInCurrentGroups;
- (BOOL)addPublications:(NSArray *)pubs toGroup:(BDSKGroup *)group;
- (BOOL)removePublications:(NSArray *)pubs fromGroups:(NSArray *)groupArray;
- (BOOL)movePublications:(NSArray *)pubs fromGroup:(BDSKGroup *)group toGroupNamed:(NSString *)newGroupName;
- (NSMenu *)groupFieldsMenu;
- (void)changeGroupFieldAction:(id)sender;
- (void)addGroupFieldAction:(id)sender;
- (void)removeGroupFieldAction:(id)sender;
- (IBAction)sortGroupsByGroup:(id)sender;
- (IBAction)sortGroupsByCount:(id)sender;
- (void)addSmartGroupAction:(id)sender;
- (void)removeSmartGroupAction:(id)sender;
- (void)editGroupAction:(id)sender;
- (void)renameGroupAction:(id)sender;
- (IBAction)selectAllPublicationsGroup:(id)sender;
- (IBAction)editNewGroupWithSelection:(id)sender;
- (NSData *)serializedSmartGroupsData;
- (void)setSmartGroupsFromSerializedData:(NSData *)data;
- (void)addGroupFieldSheetDidEnd:(NSWindow *)sheet returnCode:(int) returnCode contextInfo:(void *)contextInfo;
- (void)addSmartGroupSheetDidEnd:(NSWindow *)sheet returnCode:(int) returnCode contextInfo:(void *)contextInfo;

- (void)removeGroupFieldSheetDidEnd:(NSWindow *)sheet returnCode:(int) returnCode contextInfo:(void *)contextInfo;
- (void)handleGroupFieldChangedNotification:(NSNotification *)notification;
- (void)handleFilterChangedNotification:(NSNotification *)notification;
- (void)sortGroupsByKey:(NSString *)key;

- (NSIndexSet *)_indexesOfRowsToHighlightInRange:(NSRange)indexRange tableView:(BDSKGroupTableView *)tview;

@end
