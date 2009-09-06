//
//  SKNotesDocument.m
//  Skim
//
//  Created by Christiaan Hofman on 4/10/07.
/*
 This software is Copyright (c) 2007-2009
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

#import "SKNotesDocument.h"
#import "SKNoteOutlineView.h"
#import "BDAlias.h"
#import "SKDocumentController.h"
#import "SKTemplateParser.h"
#import "SKApplicationController.h"
#import "NSValue_SKExtensions.h"
#import "NSString_SKExtensions.h"
#import "SKTypeSelectHelper.h"
#import <SkimNotes/SkimNotes.h>
#import "SKNote.h"
#import "SKNoteText.h"
#import "SKStringConstants.h"
#import "SKFDFParser.h"
#import "SKStatusBar.h"
#import "NSWindowController_SKExtensions.h"
#import "NSDocument_SKExtensions.h"
#import "NSMenu_SKExtensions.h"
#import "NSView_SKExtensions.h"
#import "NSFileManager_SKExtensions.h"
#import "SKToolbarItem.h"
#import "SKCFCallbacks.h"
#import "SKAnnotationTypeImageCell.h"
#import "SKPrintableView.h"
#import "SKPDFView.h"

#define SKNotesDocumentWindowFrameAutosaveName @"SKNotesDocumentWindow"

#define SKNotesDocumentToolbarIdentifier @"SKNotesDocumentToolbarIdentifier"
#define SKNotesDocumentSearchToolbarItemIdentifier @"SKNotesDocumentSearchToolbarItemIdentifier"
#define SKNotesDocumentOpenPDFToolbarItemIdentifier @"SKNotesDocumentOpenPDFToolbarItemIdentifier"

#define SKLastExportedNotesTypeKey @"SKLastExportedNotesType"

#define NOTES_KEY @"notes"

#define NOTE_COLUMNID @"note"
#define TYPE_COLUMNID @"type"
#define PAGE_COLUMNID @"page"

@implementation SKNotesDocument

- (id)init {
    if (self = [super init]) {
        notes = [[NSMutableArray alloc] initWithCapacity:10];
        rowHeights = CFDictionaryCreateMutable(NULL, 0, &kSKPointerEqualObjectDictionaryKeyCallBacks, &kSKFloatDictionaryValueCallBacks);
        caseInsensitiveSearch = YES;
    }
    return self;
}

- (void)dealloc {
    [notes release];
	CFRelease(rowHeights);
    [toolbarItems release];
    [statusBar release];
    [super dealloc];
}

- (NSString *)windowNibName {
    return @"NotesDocument";
}

- (void)showWindows{
    [super showWindows];
    [[NSNotificationCenter defaultCenter] postNotificationName:SKDocumentDidShowNotification object:self];
}

- (void)windowControllerDidLoadNib:(NSWindowController *)aController {
    [aController setShouldCloseDocument:YES];
    
    [self setupToolbar:aController];
    
    [aController setWindowFrameAutosaveNameOrCascade:SKNotesDocumentWindowFrameAutosaveName];
    
    [statusBar retain];
    if ([[NSUserDefaults standardUserDefaults] boolForKey:SKShowNotesStatusBarKey])
        [self toggleStatusBar:nil];
    
    NSMenu *menu = [[[NSMenu allocWithZone:[NSMenu menuZone]] init] autorelease];
    [menu addItemWithTitle:NSLocalizedString(@"Ignore Case", @"Menu item title") action:@selector(toggleCaseInsensitiveSearch:) target:self];
    [[searchField cell] setSearchMenuTemplate:menu];
    [[searchField cell] setPlaceholderString:NSLocalizedString(@"Search", @"placeholder")];
    
    [[[outlineView tableColumnWithIdentifier:NOTE_COLUMNID] headerCell] setTitle:NSLocalizedString(@"Note", @"Table header title")];
    [[[outlineView tableColumnWithIdentifier:PAGE_COLUMNID] headerCell] setTitle:NSLocalizedString(@"Page", @"Table header title")];
    
    [outlineView setAutoresizesOutlineColumn: NO];
    
    NSSortDescriptor *indexSortDescriptor = [[[NSSortDescriptor alloc] initWithKey:SKNPDFAnnotationPageIndexKey ascending:YES] autorelease];
    NSSortDescriptor *stringSortDescriptor = [[[NSSortDescriptor alloc] initWithKey:SKNPDFAnnotationStringKey ascending:YES selector:@selector(localizedCaseInsensitiveNumericCompare:)] autorelease];
    [arrayController setSortDescriptors:[NSArray arrayWithObjects:indexSortDescriptor, stringSortDescriptor, nil]];
    [outlineView reloadData];
    
    [outlineView setTypeSelectHelper:[SKTypeSelectHelper typeSelectHelperWithMatchOption:SKSubstringMatch]];
}

- (NSArray *)writableTypesForSaveOperation:(NSSaveOperationType)saveOperation {
    NSMutableArray *writableTypes = [[[super writableTypesForSaveOperation:saveOperation] mutableCopy] autorelease];
    if (saveOperation == NSSaveToOperation) {
        NSEnumerator *fileEnum = [[[NSDocumentController sharedDocumentController] customExportTemplateFilesResetting] objectEnumerator];
        NSString *file;
        while (file = [fileEnum nextObject]) {
            if ([[file pathExtension] caseInsensitiveCompare:@"rtfd"] != NSOrderedSame)
                [writableTypes addObject:file];
        }
    }
    return writableTypes;
}

- (NSString *)fileNameExtensionForType:(NSString *)typeName saveOperation:(NSSaveOperationType)saveOperation {
    NSString *fileExtension = nil;
    fileExtension = [super fileNameExtensionForType:typeName saveOperation:saveOperation];
    if (fileExtension == nil && [[[NSDocumentController sharedDocumentController] customExportTemplateFiles] containsObject:typeName])
        fileExtension = [typeName pathExtension];
    return fileExtension;
}

- (BOOL)prepareSavePanel:(NSSavePanel *)savePanel {
    BOOL success = [super prepareSavePanel:savePanel];
    if (success && exportUsingPanel) {
        NSPopUpButton *formatPopup = [[savePanel accessoryView] subviewOfClass:[NSPopUpButton class]];
        if (formatPopup) {
            NSString *lastExportedType = [[NSUserDefaults standardUserDefaults] stringForKey:SKLastExportedNotesTypeKey];
            if (lastExportedType) {
                NSInteger idx = [formatPopup indexOfItemWithRepresentedObject:lastExportedType];
                if (idx != -1 && idx != [formatPopup indexOfSelectedItem]) {
                    [formatPopup selectItemAtIndex:idx];
                    [formatPopup sendAction:[formatPopup action] to:[formatPopup target]];
                    [savePanel setAllowedFileTypes:[NSArray arrayWithObjects:[self fileNameExtensionForType:lastExportedType saveOperation:NSSaveToOperation], nil]];
                }
            }
        }
    }
    return success;
}

- (void)document:(NSDocument *)doc didSave:(BOOL)didSave contextInfo:(void *)contextInfo { 
    exportUsingPanel = NO;
}

- (void)runModalSavePanelForSaveOperation:(NSSaveOperationType)saveOperation delegate:(id)delegate didSaveSelector:(SEL)didSaveSelector contextInfo:(void *)contextInfo {
    // Override so we can determine if this is a save, saveAs or export operation, so we can prepare the correct accessory view
    exportUsingPanel = (saveOperation == NSSaveToOperation);
    [super runModalSavePanelForSaveOperation:saveOperation delegate:self didSaveSelector:@selector(document:didSave:contextInfo:) contextInfo:NULL];
}

- (BOOL)saveToURL:(NSURL *)absoluteURL ofType:(NSString *)typeName forSaveOperation:(NSSaveOperationType)saveOperation error:(NSError **)outError{
    if (saveOperation == NSSaveToOperation && exportUsingPanel)
        [[NSUserDefaults standardUserDefaults] setObject:typeName forKey:SKLastExportedNotesTypeKey];
    return [super saveToURL:absoluteURL ofType:typeName forSaveOperation:saveOperation error:outError];
}

- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError {
    NSData *data = nil;
    
    if (SKIsNotesDocumentType(typeName)) {
        data = [NSKeyedArchiver archivedDataWithRootObject:[notes valueForKey:@"SkimNoteProperties"]];
    } else if (SKIsNotesRTFDocumentType(typeName)) {
        data = [self notesRTFData];
    } else if (SKIsNotesTextDocumentType(typeName)) {
        data = [[self notesString] dataUsingEncoding:NSUTF8StringEncoding];
    } else {
        data = [self notesDataUsingTemplateFile:typeName];
    }
    
    if (data == nil && outError != NULL)
        *outError = [NSError errorWithDomain:SKDocumentErrorDomain code:SKWriteFileError userInfo:[NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Unable to write notes", @"Error description"), NSLocalizedDescriptionKey, nil]];
    
    return data;
}

- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError {
    BOOL didRead = NO;
    NSArray *array = nil;
    
    if (SKIsNotesDocumentType(typeName)) {
        array = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    } else if (SKIsNotesFDFDocumentType(typeName)) {
        array = [SKFDFParser noteDictionariesFromFDFData:data];
    }
    if (array) {
        NSEnumerator *dictEnum = [array objectEnumerator];
        NSDictionary *dict;
        NSMutableArray *newNotes = [NSMutableArray arrayWithCapacity:[array count]];
        
        while (dict = [dictEnum nextObject]) {
            SKNote *note = [[SKNote alloc] initWithSkimNoteProperties:dict];
            [newNotes addObject:note];
            [note release];
        }
        [[self mutableArrayValueForKey:NOTES_KEY] setArray:newNotes];
        [outlineView reloadData];
        didRead = YES;
    }
    
    if (didRead == NO && outError != NULL)
        *outError = [NSError errorWithDomain:SKDocumentErrorDomain code:SKReadFileError userInfo:[NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Unable to load file", @"Error description"), NSLocalizedDescriptionKey, nil]];
    
    return didRead;
}

- (NSDictionary *)fileAttributesToWriteToURL:(NSURL *)absoluteURL ofType:(NSString *)typeName forSaveOperation:(NSSaveOperationType)saveOperation originalContentsURL:(NSURL *)absoluteOriginalContentsURL error:(NSError **)outError {
    NSMutableDictionary *dict = [[[super fileAttributesToWriteToURL:absoluteURL ofType:typeName forSaveOperation:saveOperation originalContentsURL:absoluteOriginalContentsURL error:outError] mutableCopy] autorelease];
    
    // only set the creator code for our native types
    if ([[NSUserDefaults standardUserDefaults] boolForKey:SKShouldSetCreatorCodeKey] && SKIsNotesDocumentType(typeName))
        [dict setObject:[NSNumber numberWithUnsignedLong:'SKim'] forKey:NSFileHFSCreatorCode];
    
    if ([[[absoluteURL path] pathExtension] isEqualToString:@"skim"] || SKIsNotesDocumentType(typeName))
        [dict setObject:[NSNumber numberWithUnsignedLong:'SKNT'] forKey:NSFileHFSTypeCode];
    else if ([[[absoluteURL path] pathExtension] isEqualToString:@"rtf"] || SKIsNotesRTFDocumentType(typeName))
        [dict setObject:[NSNumber numberWithUnsignedLong:'RTF '] forKey:NSFileHFSTypeCode];
    else if ([[[absoluteURL path] pathExtension] isEqualToString:@"txt"] || SKIsNotesTextDocumentType(typeName))
        [dict setObject:[NSNumber numberWithUnsignedLong:'TEXT'] forKey:NSFileHFSTypeCode];
    
    return dict;
}

// these are necessary for the app controller, we may change it there
- (NSDictionary *)currentDocumentSetup {
    NSMutableDictionary *setup = [NSMutableDictionary dictionary];
    NSString *fileName = [[self fileURL] path];
    
    if (fileName) {
        NSData *data = [[BDAlias aliasWithPath:fileName] aliasData];
        
        [setup setObject:fileName forKey:SKDocumentSetupFileNameKey];
        if(data)
            [setup setObject:data forKey:SKDocumentSetupAliasKey];
    }
    
    return setup;
}

- (void)updateNoteFilterPredicate {
    [arrayController setFilterPredicate:[outlineView filterPredicateForSearchString:[searchField stringValue] caseInsensitive:caseInsensitiveSearch]];
    [outlineView reloadData];
}

#pragma mark Printing

- (NSPrintOperation *)printOperationWithSettings:(NSDictionary *)printSettings error:(NSError **)outError {
    NSPrintInfo *printInfo = [[self printInfo] copy];
    [[printInfo dictionary] addEntriesFromDictionary:printSettings];
    [printInfo setHorizontalPagination:NSFitPagination];
    [printInfo setHorizontallyCentered:NO];
    [printInfo setVerticallyCentered:NO];
    
    NSAttributedString *attrString = [[NSAttributedString alloc] initWithRTF:[self notesRTFData] documentAttributes:NULL];
    NSView *printableView = [[SKPrintableView alloc] initWithAttributedString:attrString printInfo:printInfo];
    
    NSPrintOperation *printOperation = [NSPrintOperation printOperationWithView:printableView printInfo:printInfo];
    
    [attrString release];
    [printableView release];
    [printInfo release];
    [[printOperation printPanel] setOptions:NSPrintPanelShowsCopies | NSPrintPanelShowsPageRange | NSPrintPanelShowsPaperSize | NSPrintPanelShowsOrientation | NSPrintPanelShowsScaling | NSPrintPanelShowsPreview];
    
    return printOperation;
}

#pragma mark Actions

- (IBAction)openPDF:(id)sender {
    NSString *path = [[[self fileURL] path] stringByReplacingPathExtension:@"pdf"];
    NSError *error = nil;
    if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
        // resolve symlinks and aliases
        NSURL *url = nil;
        FSRef fileRef;
        Boolean isFolder, isAlias;
        if (noErr == FSPathMakeRef((const unsigned char *)[[path stringByResolvingSymlinksInPath] fileSystemRepresentation], &fileRef, NULL)) {
            CFStringRef theUTI = NULL;
            if (noErr == LSCopyItemAttribute(&fileRef, kLSRolesAll, kLSItemContentType, (CFTypeRef *)&theUTI) && theUTI && UTTypeConformsTo(theUTI, kUTTypeResolvable))
                FSResolveAliasFileWithMountFlags(&fileRef, TRUE, &isFolder, &isAlias, kARMNoUI);
           url = [(NSURL *)CFURLCreateFromFSRef(NULL, &fileRef) autorelease];
        }
        if (url == nil)
            url = [NSURL fileURLWithPath:path];
        if (nil == [[NSDocumentController sharedDocumentController] openDocumentWithContentsOfURL:url display:YES error:&error])
            [NSApp presentError:error];
    } else NSBeep();
}

- (IBAction)searchNotes:(id)sender {
    [self updateNoteFilterPredicate];
    if ([[sender stringValue] length]) {
        NSPasteboard *findPboard = [NSPasteboard pasteboardWithName:NSFindPboard];
        [findPboard declareTypes:[NSArray arrayWithObject:NSStringPboardType] owner:nil];
        [findPboard setString:[sender stringValue] forType:NSStringPboardType];
    }
}

- (IBAction)toggleStatusBar:(id)sender {
    if (statusBar == nil) {
        statusBar = [[SKStatusBar alloc] initWithFrame:NSMakeRect(0.0, 0.0, NSWidth([[outlineView enclosingScrollView] frame]), 22.0)];
        [statusBar setAutoresizingMask:NSViewWidthSizable | NSViewMaxYMargin];
    }
    [statusBar toggleBelowView:[outlineView enclosingScrollView] offset:1.0];
    [[NSUserDefaults standardUserDefaults] setBool:[statusBar isVisible] forKey:SKShowNotesStatusBarKey];
}

- (void)copyNotes:(id)sender {
    [self outlineView:outlineView copyItems:[sender representedObject]];
}

- (void)autoSizeNoteRows:(id)sender {
    CGFloat rowHeight = [outlineView rowHeight];
    NSTableColumn *tableColumn = [outlineView tableColumnWithIdentifier:NOTE_COLUMNID];
    id cell = [tableColumn dataCell];
    CGFloat indentation = [outlineView indentationPerLevel];
    CGFloat width = NSWidth([cell drawingRectForBounds:NSMakeRect(0.0, 0.0, [tableColumn width] - indentation, rowHeight)]);
    NSSize size = NSMakeSize(width, CGFLOAT_MAX);
    NSSize smallSize = NSMakeSize(width - indentation, CGFLOAT_MAX);
    
    NSArray *items = [sender representedObject];
    
    if (items == nil) {
        items = [NSMutableArray array];
        [(NSMutableArray *)items addObjectsFromArray:[self notes]];
        [(NSMutableArray *)items addObjectsFromArray:[[self notes] valueForKeyPath:@"@unionOfArrays.texts"]];
        [(NSMutableArray *)items removeObject:[NSNull null]];
    }
    
    NSInteger i, count = [items count];
    
    for (i = 0; i < count; i++) {
        id item = [items objectAtIndex:i];
        [cell setObjectValue:[item type] ? (id)[item string] : (id)[item text]];
        NSAttributedString *attrString = [cell attributedStringValue];
        NSRect rect = [attrString boundingRectWithSize:[item type] ? size : smallSize options:NSStringDrawingUsesLineFragmentOrigin];
        CGFloat height = SKMax(NSHeight(rect) + 3.0, rowHeight + 2.0);
        CFDictionarySetValue(rowHeights, (const void *)item, &height);
    }
    // don't use noteHeightOfRowsWithIndexesChanged: as this only updates the visible rows and the scrollers
    [outlineView reloadData];
}

- (IBAction)toggleCaseInsensitiveSearch:(id)sender {
    caseInsensitiveSearch = NO == caseInsensitiveSearch;
    if ([[searchField stringValue] length])
        [self searchNotes:searchField];
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem {
    SEL action = [menuItem action];
    if (action == @selector(toggleStatusBar:)) {
        if ([statusBar isVisible])
            [menuItem setTitle:NSLocalizedString(@"Hide Status Bar", @"Menu item title")];
        else
            [menuItem setTitle:NSLocalizedString(@"Show Status Bar", @"Menu item title")];
        return YES;
    } else if (action == @selector(toggleCaseInsensitiveSearch:)) {
        [menuItem setState:caseInsensitiveSearch ? NSOnState : NSOffState];
        return YES;
    }
    return YES;
}

#pragma mark Accessors

- (NSArray *)notes {
    return [[notes copy] autorelease];
}

- (NSUInteger)countOfNotes {
    return [notes count];
}

- (NSDictionary *)objectInNotesAtIndex:(NSUInteger)theIndex {
    return [notes objectAtIndex:theIndex];
}

- (void)insertObject:(NSDictionary *)note inNotesAtIndex:(NSUInteger)theIndex {
    [notes insertObject:note atIndex:theIndex];
}

- (void)removeObjectFromNotesAtIndex:(NSUInteger)theIndex {
    [notes removeObjectAtIndex:theIndex];
}

#pragma mark NSOutlineView datasource and delegate methods

- (NSInteger)outlineView:(NSOutlineView *)ov numberOfChildrenOfItem:(id)item {
    if (item == nil)
        return [[arrayController arrangedObjects] count];
    else
        return [[item texts] count];
}

- (BOOL)outlineView:(NSOutlineView *)ov isItemExpandable:(id)item {
    return [[item texts] count] > 0;
}

- (id)outlineView:(NSOutlineView *)ov child:(NSInteger)anIndex ofItem:(id)item {
    if (item == nil) {
        return [[arrayController arrangedObjects] objectAtIndex:anIndex];
    } else {
        return [[item texts] lastObject];
    }
}

- (id)outlineView:(NSOutlineView *)ov objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item {
    NSString *tcID = [tableColumn identifier];
    if ([tcID isEqualToString:NOTE_COLUMNID]) {
        return [item type] ? (id)[item string] : (id)[item text];
    } else if([tcID isEqualToString:TYPE_COLUMNID]) {
        return [NSDictionary dictionaryWithObjectsAndKeys:[item type], SKAnnotationTypeImageCellTypeKey, nil];
    } else if ([tcID isEqualToString:PAGE_COLUMNID]) {
        return [item type] ? [NSString stringWithFormat:@"%lu", (unsigned long)([item pageIndex] + 1)] : nil;
    }
    return nil;
}

- (void)outlineView:(NSOutlineView *)ov didClickTableColumn:(NSTableColumn *)tableColumn {
    NSTableColumn *oldTableColumn = [ov highlightedTableColumn];
    NSArray *sortDescriptors = nil;
    BOOL ascending = YES;
    if ([oldTableColumn isEqual:tableColumn]) {
        sortDescriptors = [[arrayController sortDescriptors] valueForKey:@"reversedSortDescriptor"];
        ascending = [[sortDescriptors lastObject] ascending];
    } else {
        NSString *tcID = [tableColumn identifier];
        NSSortDescriptor *pageIndexSortDescriptor = [[[NSSortDescriptor alloc] initWithKey:SKNPDFAnnotationPageIndexKey ascending:ascending] autorelease];
        NSSortDescriptor *boundsSortDescriptor = [[[NSSortDescriptor alloc] initWithKey:SKNPDFAnnotationBoundsKey ascending:ascending selector:@selector(boundsCompare:)] autorelease];
        NSMutableArray *sds = [NSMutableArray arrayWithObjects:pageIndexSortDescriptor, boundsSortDescriptor, nil];
        if ([tcID isEqualToString:TYPE_COLUMNID]) {
            [sds insertObject:[[[NSSortDescriptor alloc] initWithKey:SKNPDFAnnotationTypeKey ascending:YES selector:@selector(noteTypeCompare:)] autorelease] atIndex:0];
        } else if ([tcID isEqualToString:NOTE_COLUMNID]) {
            [sds insertObject:[[[NSSortDescriptor alloc] initWithKey:SKNPDFAnnotationStringKey ascending:YES selector:@selector(localizedCaseInsensitiveNumericCompare:)] autorelease] atIndex:0];
        } else if ([tcID isEqualToString:PAGE_COLUMNID]) {
            if (oldTableColumn == nil)
                ascending = NO;
        }
        sortDescriptors = sds;
        if (oldTableColumn)
            [ov setIndicatorImage:nil inTableColumn:oldTableColumn];
        [ov setHighlightedTableColumn:tableColumn]; 
    }
    [arrayController setSortDescriptors:sortDescriptors];
    [ov setIndicatorImage:[NSImage imageNamed:ascending ? @"NSAscendingSortIndicator" : @"NSDescendingSortIndicator"]
            inTableColumn:tableColumn];
    [ov reloadData];
}

- (void)outlineViewNoteTypesDidChange:(NSOutlineView *)ov {
    [self updateNoteFilterPredicate];
}

- (void)outlineView:(NSOutlineView *)ov copyItems:(NSArray *)items  {
    NSPasteboard *pboard = [NSPasteboard generalPasteboard];
    NSMutableArray *types = [NSMutableArray array];
    NSData *noteData = nil;
    NSMutableAttributedString *attrString = [[items valueForKey:SKNPDFAnnotationTypeKey] containsObject:[NSNull null]] ? [[[NSMutableAttributedString alloc] init] autorelease] : nil;
    NSMutableString *string = [NSMutableString string];
    NSEnumerator *itemEnum;
    id item;
    
    itemEnum = [items objectEnumerator];
    while (item = [itemEnum nextObject]) {
        if ([item type] == nil || ([[item type] isEqualToString:SKNHighlightString] == NO && [[item type] isEqualToString:SKNUnderlineString] == NO && [[item type] isEqualToString:SKNStrikeOutString] == NO)) {
            noteData = [NSKeyedArchiver archivedDataWithRootObject:[([item type] ? item : [item note]) SkimNoteProperties]];
            [types addObject:SKSkimNotePboardType];
            break;
        }
    }
    itemEnum = [items objectEnumerator];
    while (item = [itemEnum nextObject]) {
        if ([string length])
            [string appendString:@"\n\n"];
        if ([attrString length])
            [attrString replaceCharactersInRange:NSMakeRange([attrString length], 0) withString:@"\n\n"];
        [string appendString:[item string]];
        if ([item type])
            [attrString replaceCharactersInRange:NSMakeRange([attrString length], 0) withString:[item string]];
        else
            [attrString appendAttributedString:[(SKNoteText *)item text]];
    }
    
    if ([string length])
        [types addObject:NSStringPboardType];
    if (noteData)
        [pboard setData:noteData forType:SKSkimNotePboardType];
    if ([attrString length])
        [types addObject:NSRTFPboardType];
    if ([types count])
        [pboard declareTypes:types owner:nil];
    if ([string length])
        [pboard setString:string forType:NSStringPboardType];
    if ([attrString length])
        [pboard setData:[attrString RTFFromRange:NSMakeRange(0, [attrString length]) documentAttributes:nil] forType:NSRTFPboardType];
}

- (BOOL)outlineView:(NSOutlineView *)ov canCopyItems:(NSArray *)items  {
    return [items count] > 0;
}

- (CGFloat)outlineView:(NSOutlineView *)ov heightOfRowByItem:(id)item {
    CGFloat rowHeight = 0.0;
    if (CFDictionaryContainsKey(rowHeights, (const void *)item))
        rowHeight = *(CGFloat *)CFDictionaryGetValue(rowHeights, (const void *)item);
    else if ([item type] == nil)
        rowHeight = 85.0;
    return rowHeight > 0.0 ? rowHeight : [ov rowHeight] + 2.0;
}

- (BOOL)outlineView:(NSOutlineView *)ov canResizeRowByItem:(id)item {
    return YES;
}

- (void)outlineView:(NSOutlineView *)ov setHeightOfRow:(CGFloat)newHeight byItem:(id)item {
    CFDictionarySetValue(rowHeights, (const void *)item, &newHeight);
}

- (NSString *)outlineView:(NSOutlineView *)ov toolTipForCell:(NSCell *)cell rect:(NSRectPointer)rect tableColumn:(NSTableColumn *)tableColumn item:(id)item mouseLocation:(NSPoint)mouseLocation {
    return [item string];
}

- (NSMenu *)outlineView:(NSOutlineView *)ov menuForTableColumn:(NSTableColumn *)tableColumn item:(id)item {
    if ([outlineView isRowSelected:[outlineView rowForItem:item]] == NO)
        [outlineView selectRowIndexes:[NSIndexSet indexSetWithIndex:[outlineView rowForItem:item]] byExtendingSelection:NO];
    
    NSMenu *menu = nil;
    NSMenuItem *menuItem;
    NSMutableArray *items = [NSMutableArray array];
    NSIndexSet *rowIndexes = [outlineView selectedRowIndexes];
    NSUInteger row = [rowIndexes firstIndex];
    while (row != NSNotFound) {
        [items addObject:[outlineView itemAtRow:row]];
        row = [rowIndexes indexGreaterThanIndex:row];
    }
    
    [outlineView selectRowIndexes:[NSIndexSet indexSetWithIndex:[outlineView rowForItem:item]] byExtendingSelection:NO];
    
    menu = [[[NSMenu allocWithZone:[NSMenu menuZone]] init] autorelease];
    if ([self outlineView:ov canCopyItems:[NSArray arrayWithObjects:item, nil]]) {
        menuItem = [menu addItemWithTitle:NSLocalizedString(@"Copy", @"Menu item title") action:@selector(copyNotes:) target:self];
        [menuItem setRepresentedObject:items];
        [menu addItem:[NSMenuItem separatorItem]];
    }
    menuItem = [menu addItemWithTitle:[items count] == 1 ? NSLocalizedString(@"Auto Size Row", @"Menu item title") : NSLocalizedString(@"Auto Size Rows", @"Menu item title") action:@selector(autoSizeNoteRows:) target:self];
    [menuItem setRepresentedObject:items];
    menuItem = [menu addItemWithTitle:NSLocalizedString(@"Auto Size All", @"Menu item title") action:@selector(autoSizeNoteRows:) target:self];
    
    return menu;
}

- (NSArray *)outlineView:(NSOutlineView *)ov typeSelectHelperSelectionItems:(SKTypeSelectHelper *)typeSelectHelper {
    NSInteger i, count = [outlineView numberOfRows];
    NSMutableArray *texts = [NSMutableArray arrayWithCapacity:count];
    for (i = 0; i < count; i++) {
        id item = [outlineView itemAtRow:i];
        NSString *string = [item string];
        [texts addObject:string ?: @""];
    }
    return texts;
}

- (void)outlineView:(NSOutlineView *)ov typeSelectHelper:(SKTypeSelectHelper *)typeSelectHelper didFailToFindMatchForSearchString:(NSString *)searchString {
    [statusBar setLeftStringValue:[NSString stringWithFormat:NSLocalizedString(@"No match: \"%@\"", @"Status message"), searchString]];
}

- (void)outlineView:(NSOutlineView *)ov typeSelectHelper:(SKTypeSelectHelper *)typeSelectHelper updateSearchString:(NSString *)searchString {
    if (searchString)
        [statusBar setLeftStringValue:[NSString stringWithFormat:NSLocalizedString(@"Finding note: \"%@\"", @"Status message"), searchString]];
    else
        [statusBar setLeftStringValue:@""];
}

#pragma mark Toolbar

- (void)setupToolbar:(NSWindowController *)aController {
    // Create a new toolbar instance, and attach it to our document window
    NSToolbar *toolbar = [[[NSToolbar alloc] initWithIdentifier:SKNotesDocumentToolbarIdentifier] autorelease];
    SKToolbarItem *item;
    
    toolbarItems = [[NSMutableDictionary alloc] initWithCapacity:1];
    
    // Set up toolbar properties: Allow customization, give a default display mode, and remember state in user defaults
    [toolbar setAllowsUserCustomization:YES];
    [toolbar setAutosavesConfiguration:YES];
    [toolbar setDisplayMode: NSToolbarDisplayModeDefault];
    
    // We are the delegate
    [toolbar setDelegate:self];
    
    // Add template toolbar items
    
    item = [[SKToolbarItem alloc] initWithItemIdentifier:SKNotesDocumentSearchToolbarItemIdentifier];
    [item setLabels:NSLocalizedString(@"Search", @"Toolbar item label")];
    [item setToolTip:NSLocalizedString(@"Search Notes", @"Tool tip message")];
    [item setView:searchField];
    NSSize size = [searchField frame].size;
    [item setMinSize:size];
    size.width = 1000.0;
    [item setMaxSize:size];
    [toolbarItems setObject:item forKey:SKNotesDocumentSearchToolbarItemIdentifier];
    [item release];
    
    item = [[SKToolbarItem alloc] initWithItemIdentifier:SKNotesDocumentOpenPDFToolbarItemIdentifier];
    [item setLabels:NSLocalizedString(@"Open PDF", @"Toolbar item label")];
    [item setToolTip:NSLocalizedString(@"Open Associated PDF File", @"Tool tip message")];
    [item setImageNamed:@"PDFDocument"];
    [item setTarget:self];
    [item setAction:@selector(openPDF:)];
    [toolbarItems setObject:item forKey:SKNotesDocumentOpenPDFToolbarItemIdentifier];
    [item release];
    
    // Attach the toolbar to the window
    [[aController window] setToolbar:toolbar];
}

- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdent willBeInsertedIntoToolbar:(BOOL)willBeInserted {
    NSToolbarItem *item = [toolbarItems objectForKey:itemIdent];
    if (willBeInserted == NO)
        item = [[item copy] autorelease];
    return item;
}

- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar *)toolbar {
    return [NSArray arrayWithObjects:
        SKNotesDocumentSearchToolbarItemIdentifier, 
        NSToolbarFlexibleSpaceItemIdentifier, 
        SKNotesDocumentOpenPDFToolbarItemIdentifier, nil];
}

- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar *)toolbar {
    return [NSArray arrayWithObjects: 
        SKNotesDocumentSearchToolbarItemIdentifier, 
        SKNotesDocumentOpenPDFToolbarItemIdentifier, 
        NSToolbarPrintItemIdentifier, 
        NSToolbarFlexibleSpaceItemIdentifier, 
		NSToolbarSpaceItemIdentifier, 
		NSToolbarSeparatorItemIdentifier, 
		NSToolbarCustomizeToolbarItemIdentifier, nil];
}

- (BOOL)validateToolbarItem:(NSToolbarItem *)toolbarItem {
    if ([[[[[self windowControllers] objectAtIndex:0] window] toolbar] customizationPaletteIsRunning])
        return NO;
    else if ([[toolbarItem itemIdentifier] isEqualToString:SKNotesDocumentOpenPDFToolbarItemIdentifier])
        return [[NSFileManager defaultManager] fileExistsAtPath:[[[self fileURL] path] stringByReplacingPathExtension:@"pdf"]];
    return YES;
}

@end
