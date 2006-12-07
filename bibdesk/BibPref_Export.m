//
//  BibPref_Export.m
//  Bibdesk
//
//  Created by Adam Maxwell on 05/18/06.
/*
 This software is Copyright (c) 2006
 Adam Maxwell. All rights reserved.
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:
 
 - Redistributions of source code must retain the above copyright
 notice, this list of conditions and the following disclaimer.
 
 - Redistributions in binary form must reproduce the above copyright
 notice, this list of conditions and the following disclaimer in
 the documentation and/or other materials provided with the
 distribution.
 
 - Neither the name of Adam Maxwell nor the names of any
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

#import "BibPref_Export.h"
#import "BibTypeManager.h"
#import "BDAlias.h"
#import "NSFileManager_BDSKExtensions.h"
#import "BDSKTemplate.h"
#import "BibAppController.h"
#import "NSMenu_BDSKExtensions.h"

static NSString *BDSKTemplateRowsPboardType = @"BDSKTemplateRowsPboardType";

@implementation BibPref_Export

- (id)initWithTitle:(NSString *)newTitle defaultsArray:(NSArray *)newDefaultsArray controller:(OAPreferenceController *)controller{
	if(self = [super initWithTitle:newTitle defaultsArray:newDefaultsArray controller:controller]){
        
        NSData *data = [defaults objectForKey:BDSKExportTemplateTree];
        if([data length])
            [self setItemNodes:[NSKeyedUnarchiver unarchiveObjectWithData:data]];
        else 
            [self setItemNodes:[BDSKTemplate defaultExportTemplates]];
        
        fileTypes = [[NSArray alloc] initWithObjects:@"html", @"rss", @"csv", @"txt", @"rtf", @"rtfd", @"doc", nil];
        
        roles = [[NSMutableArray alloc] initWithObjects:BDSKTemplateMainPageString, BDSKTemplateDefaultItemString, BDSKTemplateAccessoryString, nil];
        [roles addObjectsFromArray:[[BibTypeManager sharedManager] bibTypesForFileType:BDSKBibtexString]];
        
        templatePrefList = BDSKExportTemplateList;
	}
	return self;
}

- (void)restoreDefaultsNoPrompt;
{
    [super restoreDefaultsNoPrompt];
    if (templatePrefList == BDSKExportTemplateList) {
        [self setItemNodes:[BDSKTemplate defaultExportTemplates]];
    } else {
        [self setItemNodes:[BDSKTemplate defaultServiceTemplates]];
    }
    [self valuesHaveChanged];
}

- (void)awakeFromNib
{    
    [super awakeFromNib];

    [outlineView setAutosaveExpandedItems:YES];
    
    // Default behavior is to expand column 0, which slides column 1 outside the clip view; since we only have one expandable column, this is more annoying than helpful.
    [outlineView setAutoresizesOutlineColumn:NO];
    
    [outlineView registerForDraggedTypes:[NSArray arrayWithObjects:NSFilenamesPboardType, BDSKTemplateRowsPboardType, nil]];
    
    // this will synchronize prefs, as well
    [self valuesHaveChanged];
}

- (void)dealloc
{
    [itemNodes release];
    [roles release];
    [fileTypes release];
    [super dealloc];
}

- (void)synchronizePrefs
{
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:itemNodes];
    if(nil != data)
        [defaults setObject:data forKey:(templatePrefList == BDSKExportTemplateList) ? BDSKExportTemplateTree : BDSKServiceTemplateTree];
    else
        NSLog(@"Unable to archive %@", itemNodes);
}

- (void)updateUI
{
    [prefListRadio selectCellWithTag:templatePrefList];
    [outlineView reloadData];
    [self synchronizePrefs];
    [deleteButton setEnabled:[self canDeleteSelectedItem]];
    [addButton setEnabled:[self canAddItem]];
}

- (void)setItemNodes:(NSArray *)array;
{
    if(array != itemNodes){
        [itemNodes release];
        itemNodes = [array mutableCopy];
    }
}

- (IBAction)changePrefList:(id)sender{
    templatePrefList = [[sender selectedCell] tag];
    NSData *data = [defaults objectForKey:(templatePrefList == BDSKExportTemplateList) ? BDSKExportTemplateTree : BDSKServiceTemplateTree];
    if([data length])
        [self setItemNodes:[NSKeyedUnarchiver unarchiveObjectWithData:data]];
    else if (templatePrefList == BDSKExportTemplateList)
        [self setItemNodes:[BDSKTemplate defaultExportTemplates]];
    else if (BDSKServiceTemplateList == templatePrefList)
        [self setItemNodes:[BDSKTemplate defaultServiceTemplates]];
    else [NSException raise:NSInternalInconsistencyException format:@"Unrecognized templatePrefList parameter"];
    [self valuesHaveChanged];
}

- (void)alertDidEnd:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(void *)contextInfo{
    if (NSAlertDefaultReturn == returnCode)
        [[NSApp delegate] copyAllExportTemplatesToApplicationSupportAndOverwrite:YES];
}

- (IBAction)resetDefaultFiles:(id)sender;
{
	NSAlert *alert = [NSAlert alertWithMessageText:NSLocalizedString(@"Reset default template files to their original value?", @"Message in alert dialog when resetting default template files") 
									 defaultButton:NSLocalizedString(@"OK", @"Button title") 
								   alternateButton:NSLocalizedString(@"Cancel", @"Button title") 
									   otherButton:nil 
						 informativeTextWithFormat:NSLocalizedString(@"Choosing Reset Default Files will restore the original content of all the standard export and service template files.", @"Informative text in alert dialog")];
	[alert beginSheetModalForWindow:[[BDSKPreferenceController sharedPreferenceController] window] 
					  modalDelegate:self
					 didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:) 
						contextInfo:NULL];
}

- (IBAction)addNode:(id)sender;
{
    // may be nil
    BDSKTreeNode *selectedNode = [outlineView selectedItem];
    BDSKTemplate *newNode = [[BDSKTemplate alloc] init];

    if([selectedNode isLeaf]){
        // add as a sibling of the selected node
        // we're already expanded, and newNode won't be expandable
        [[selectedNode parent] addChild:newNode];
    } else if(nil != selectedNode && [outlineView isItemExpanded:selectedNode]){
        // add as a child of the selected node
        // selected node is expanded, so no need to expand
        [selectedNode addChild:newNode];
    } else if(BDSKExportTemplateList == templatePrefList){
        // add as a non-leaf node
        [itemNodes addObject:newNode];
        
        // each style needs at least a Main Page child, and newNode will be recognized as a non-leaf node
        BDSKTemplate *child = [[BDSKTemplate alloc] init];
        [child setValue:BDSKTemplateMainPageString forKey:BDSKTemplateRoleString];
        [newNode addChild:child];
        [child release];
        
        // reload so we can expand this new parent node
        [outlineView reloadData];
        [outlineView expandItem:newNode];
    }
    
    [self valuesHaveChanged];
    [newNode release];
}

- (IBAction)removeNode:(id)sender;
{
    BDSKTreeNode *selectedNode = [outlineView selectedItem];
    if(nil != selectedNode){
        if([selectedNode isLeaf])
            [[selectedNode parent] removeChild:selectedNode];
        else
            [itemNodes removeObject:selectedNode];
    } else {
        NSBeep();
    }
    [self valuesHaveChanged];
}

#pragma mark Outline View

- (BOOL)outlineView:(NSOutlineView *)ov isItemExpandable:(id)item
{
    return item ? (NO == [item isLeaf]) : YES;
}

- (int)outlineView:(NSOutlineView *)ov numberOfChildrenOfItem:(id)item
{ 
    return item ? [item numberOfChildren] : [itemNodes count];
}

- (id)outlineView:(NSOutlineView *)ov objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
    NSString *identifier = [tableColumn identifier];
    id value = [item valueForKey:identifier];
    if (value == nil) {
        // set some placeholder message, this will show up in red
        if ([identifier isEqualToString:BDSKTemplateRoleString])
            value = ([item isLeaf]) ? NSLocalizedString(@"Choose role", @"Default text for template role") : NSLocalizedString(@"Choose file type", @"Default text for template type");
        else if ([identifier isEqualToString:BDSKTemplateNameString])
            value = ([item isLeaf]) ? NSLocalizedString(@"Double-click to choose file", @"Default text for template file") : NSLocalizedString(@"Double-click to change name", @"Default text fo template name");
    }
    return value;
}

- (id)outlineView:(NSOutlineView *)ov child:(int)index ofItem:(id)item
{
    return nil == item ? [itemNodes objectAtIndex:index] : [[item children] objectAtIndex:index];
}

- (id)outlineView:(NSOutlineView *)ov itemForPersistentObject:(id)object
{
    return [NSKeyedUnarchiver unarchiveObjectWithData:object];
}

// return archived item
- (id)outlineView:(NSOutlineView *)ov persistentObjectForItem:(id)item
{
    return [NSKeyedArchiver archivedDataWithRootObject:item];
}

- (void)openPanelDidEnd:(NSOpenPanel *)panel returnCode:(int)returnCode contextInfo:(BDSKTemplate *)aNode
{
    NSURL *fileURL = [[panel URLs] lastObject];
    if(NSOKButton == returnCode && nil != fileURL){
        // this will set the name property
        [aNode setValue:fileURL forKey:BDSKTemplateFileURLString];
    }
    [aNode release];
    [panel orderOut:nil];
    [self valuesHaveChanged];
}

- (BOOL)outlineView:(NSOutlineView *)ov shouldEditTableColumn:(NSTableColumn *)tableColumn item:(id)item;
{
    // leaf items are fully editable, but you can only edit the name of a parent item

    NSString *identifier = [tableColumn identifier];
    if([item isLeaf]){
        // run an open panel for the filename
        if([identifier isEqualToString:BDSKTemplateNameString]){
            NSOpenPanel *openPanel = [NSOpenPanel openPanel];
            [openPanel setCanChooseDirectories:YES];
            [openPanel setCanCreateDirectories:NO];
            [openPanel setPrompt:NSLocalizedString(@"Choose", @"Prompt for Choose panel")];
            
            // start the panel in the same directory as the item's existing path, or fall back to app support
            NSString *dirPath = [[[item representedFileURL] path] stringByDeletingLastPathComponent];
            if(nil == dirPath)
                dirPath = dirPath;
            [openPanel beginSheetForDirectory:dirPath 
                                         file:nil 
                                        types:nil 
                               modalForWindow:[[BDSKPreferenceController sharedPreferenceController] window] 
                                modalDelegate:self didEndSelector:@selector(openPanelDidEnd:returnCode:contextInfo:) 
                                  contextInfo:[item retain]];
            
            // bypass the normal editing mechanism, or it'll reset the value
            return NO;
        } else if([identifier isEqualToString:BDSKTemplateRoleString]){
            if([[item valueForKey:BDSKTemplateRoleString] isEqualToString:BDSKTemplateMainPageString])
                return NO;
        } else [NSException raise:NSInternalInconsistencyException format:@"Unexpected table column identifier %@", identifier];
    }else if(templatePrefList == BDSKServiceTemplateList){
        return NO;
    }
    return YES;
}

// return NO to avoid popping the NSOpenPanel unexpectedly
- (BOOL)tableViewShouldEditNextItemWhenEditingEnds:(NSTableView *)tv { return NO; }

// this seems to be called when editing the NSComboBoxCell as well as the parent name
- (void)outlineView:(NSOutlineView *)ov setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn byItem:(id)item{
    NSString *identifier = [tableColumn identifier];
    if([identifier isEqualToString:BDSKTemplateRoleString] && [item isLeaf] && [object isEqualToString:BDSKTemplateAccessoryString] == NO && [(BDSKTemplate *)[item parent] childForRole:object] != nil) {
        [outlineView reloadData];
    } else if (object != nil) { // object can be nil when a NSComboBoxCell is edited while the options are shown, looks like an AppKit bug
        [item setValue:object forKey:[tableColumn identifier]];
        [self synchronizePrefs];
    }
}

- (void)outlineView:(NSOutlineView *)ov willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn item:(id)item{
    NSString *identifier = [tableColumn identifier];
    if ([cell respondsToSelector:@selector(setTextColor:)])
        [cell setTextColor:[item representedColorForKey:identifier]];
    if([identifier isEqualToString:BDSKTemplateRoleString]) {
        [cell removeAllItems];
        [cell addItemsWithObjectValues:([item isLeaf]) ? roles : fileTypes];
    }
}

- (BOOL)canDeleteSelectedItem
{
    BDSKTreeNode *selItem = [outlineView selectedItem];
    if (selItem == nil)
        return NO;
    return ((templatePrefList == BDSKExportTemplateList && [selItem isLeaf] == NO) || 
            ([selItem isLeaf]  && [[selItem valueForKey:BDSKTemplateRoleString] isEqualToString:BDSKTemplateMainPageString] == NO));
}

// we can't add items to the services outline view
- (BOOL)canAddItem
{
    return ((templatePrefList == BDSKExportTemplateList) || nil != [outlineView selectedItem]);
}

- (void)outlineViewSelectionDidChange:(NSNotification *)notification;
{
    [deleteButton setEnabled:[self canDeleteSelectedItem]];
    [addButton setEnabled:[self canAddItem]];
}

- (void)tableView:(NSTableView *)tableView deleteRows:(NSArray *)rows;
{
    // currently we don't allow multiple selection, so we'll ignore the rows argument
    if([self canDeleteSelectedItem])
        [self removeNode:nil];
    else
        NSBeep();
}

#pragma mark Drag / drop

- (BOOL)outlineView:(NSOutlineView *)ov writeItems:(NSArray *)items toPasteboard:(NSPasteboard *)pboard{
    BDSKTemplate *item = [items lastObject];
    if ([item isLeaf] == NO || [[item valueForKey:BDSKTemplateRoleString] isEqualToString:BDSKTemplateMainPageString] == NO) {
        [pboard declareTypes:[NSArray arrayWithObject:BDSKTemplateRowsPboardType] owner:nil];
        [pboard setData:[NSKeyedArchiver archivedDataWithRootObject:[items lastObject]] forType:BDSKTemplateRowsPboardType];
        return YES;
    }
    return NO;
}

- (NSDragOperation)outlineView:(NSOutlineView *)ov validateDrop:(id <NSDraggingInfo>)info proposedItem:(id)item proposedChildIndex:(int)index{
    NSPasteboard *pboard = [info draggingPasteboard];
    NSString *type = [pboard availableTypeFromArray:[NSArray arrayWithObjects:NSFilenamesPboardType, BDSKTemplateRowsPboardType, nil]];
    
    if ([type isEqualToString:NSFilenamesPboardType]) {
        if ([item isLeaf] && index == NSOutlineViewDropOnItemIndex)
            return NSDragOperationCopy;
        else if (item == nil && index != NSOutlineViewDropOnItemIndex)
            return NSDragOperationCopy;
        else if ([item isLeaf] == NO && index != NSOutlineViewDropOnItemIndex && index > 0)
            return NSDragOperationCopy;
    } else if ([type isEqualToString:BDSKTemplateRowsPboardType]) {
        if (index == NSOutlineViewDropOnItemIndex)
            return NSDragOperationNone;
        id dropItem = [NSKeyedUnarchiver unarchiveObjectWithData:[pboard dataForType:BDSKTemplateRowsPboardType]];
        if ([dropItem isLeaf]) {
            if ([[item children] containsObject:dropItem] && index > 0)
                return NSDragOperationMove;
        } else {
            if (item == nil)
                return NSDragOperationMove;
        }
    }
    return NSDragOperationNone;
}

- (BOOL)outlineView:(NSOutlineView *)ov acceptDrop:(id <NSDraggingInfo>)info item:(id)item childIndex:(int)index{
    NSPasteboard *pboard = [info draggingPasteboard];
    NSString *type = [pboard availableTypeFromArray:[NSArray arrayWithObjects:NSFilenamesPboardType, BDSKTemplateRowsPboardType, nil]];
    
    if ([type isEqualToString:NSFilenamesPboardType]) {
        NSArray *fileNames = [pboard propertyListForType:NSFilenamesPboardType];
        NSString *fileName;
        id newNode = nil;
        
        if ([item isLeaf] && index == NSOutlineViewDropOnItemIndex) {
            fileName = [fileNames objectAtIndex:0];
            [item setValue:[NSURL fileURLWithPath:fileName] forKey:BDSKTemplateFileURLString];
            newNode = item;
        } else if (item == nil && index != NSOutlineViewDropOnItemIndex) {
            NSEnumerator *fileEnum = [fileNames objectEnumerator];
            id childNode = nil;
            while (fileName = [fileEnum nextObject]) {
                newNode = [[[BDSKTemplate alloc] init] autorelease];
                childNode = [[[BDSKTemplate alloc] init] autorelease];
                [itemNodes insertObject:newNode atIndex:index++];
                [newNode addChild:childNode];
                [childNode setValue:BDSKTemplateMainPageString forKey:BDSKTemplateRoleString];
                [childNode setValue:[NSURL fileURLWithPath:fileName] forKey:BDSKTemplateFileURLString];
            }
        } else if ([item isLeaf] == NO && index != NSOutlineViewDropOnItemIndex && index > 0) {
            NSEnumerator *fileEnum = [fileNames objectEnumerator];
            while (fileName = [fileEnum nextObject]) {
                newNode = [[[BDSKTemplate alloc] init] autorelease];
                [item insertChild:newNode atIndex:index++];
                [newNode setValue:[NSURL fileURLWithPath:fileName] forKey:BDSKTemplateFileURLString];
            }
        } else return NO;
        [self valuesHaveChanged];
        [outlineView selectRowIndexes:[NSIndexSet indexSetWithIndex:[outlineView rowForItem:newNode]] byExtendingSelection:NO];
        if ([newNode isLeaf] == NO)
            [outlineView expandItem:newNode];
        return YES;
    } else if ([type isEqualToString:BDSKTemplateRowsPboardType]) {
        id dropItem = [NSKeyedUnarchiver unarchiveObjectWithData:[pboard dataForType:BDSKTemplateRowsPboardType]];
        if ([dropItem isLeaf]) {
            int sourceIndex = [[item children] indexOfObject:dropItem];
            if (sourceIndex == NSNotFound)
                return NO;
            if (sourceIndex < index)
                --index;
            [item removeChild:dropItem];
            [item insertChild:dropItem atIndex:index];
        } else {
            int sourceIndex = [itemNodes indexOfObject:dropItem];
            if (sourceIndex == NSNotFound)
                return NO;
            if (sourceIndex < index)
                --index;
            [[dropItem retain] autorelease];
            [itemNodes removeObjectAtIndex:sourceIndex];
            [itemNodes insertObject:dropItem atIndex:index];
        }
        [self valuesHaveChanged];
        [outlineView selectRowIndexes:[NSIndexSet indexSetWithIndex:[outlineView rowForItem:dropItem]] byExtendingSelection:NO];
        return YES;
    }
    return NO;
}

#pragma mark ToolTips and Context menu

- (NSString *)tableView:(NSTableView *)tv toolTipForTableColumn:(NSTableColumn *)tableColumn row:(int)row;
{
    NSString *tooltip = nil;
    if(row >= 0){
        id item = [outlineView itemAtRow:row];
        if ([[tableColumn identifier] isEqualToString:BDSKTemplateNameString] && [item isLeaf])
            tooltip = [[item representedFileURL] path];
    }
    return tooltip;
}

- (NSMenu *)tableView:(NSOutlineView *)tv contextMenuForRow:(int)row column:(int)column;
{
    NSMenu *menu = nil;
    NSURL *theURL = nil;
    
    if(0 == column && row >= 0 && [[outlineView itemAtRow:row] isLeaf])
        theURL = [[tv itemAtRow:row] representedFileURL];
    
    if(nil != theURL){
        NSMenuItem *item;
        
        menu = [[[NSMenu allocWithZone:[NSMenu menuZone]] init] autorelease];
        
        item = [menu addItemWithTitle:NSLocalizedString(@"Open With", @"Menu item title") andSubmenuOfApplicationsForURL:theURL];
        
        item = [menu addItemWithTitle:NSLocalizedString(@"Reveal in Finder", @"Menu item title") action:@selector(revealInFinder:) keyEquivalent:@""];
        [item setTarget:self];
    }
    return menu;
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem;
{
    SEL action = [menuItem action];
    BOOL validate = NO;
    if(@selector(delete:) == action){
        validate = [self canDeleteSelectedItem];
    } else if(@selector(revealInFinder:) == action){
        int row = [outlineView selectedRow];
        if(row >= 0)
            validate = [[outlineView itemAtRow:row] isLeaf];
    }
    return validate;
}

- (IBAction)revealInFinder:(id)sender;
{
    int row = [outlineView selectedRow];
    if(row >= 0)
        [[NSWorkspace sharedWorkspace] selectFile:[[[outlineView itemAtRow:row] representedFileURL] path] inFileViewerRootedAtPath:@""];
}

#pragma mark Combo box

- (NSCell *)tableView:(NSTableView *)tableView column:(OADataSourceTableColumn *)tableColumn dataCellForRow:(int)row;
{
    static NSComboBoxCell *disabledCell = nil;
    
    id cell = [tableColumn dataCell];
    id item = [(NSOutlineView *)tableView itemAtRow:row];
    
    if(([item isLeaf] && [[item valueForKey:BDSKTemplateRoleString] isEqualToString:BDSKTemplateMainPageString]) || 
       ([item isLeaf] == NO && templatePrefList == BDSKServiceTemplateList)){
        // setting an NSComboBoxCell to disabled in outlineView:willDisplayCell:... results in a non-editable cell with black text instead of disabled text; creating a new cell works around that problem
        if (disabledCell == nil) {
            disabledCell = [[NSComboBoxCell alloc] initTextCell:@""];
            [disabledCell setButtonBordered:NO];
            [disabledCell setBordered:NO];
            [disabledCell setControlSize:NSSmallControlSize];
            [disabledCell setFont:[cell font]];
            [disabledCell setEnabled:NO];
        }
        cell = disabledCell;
    }
    return cell;
}

@end
