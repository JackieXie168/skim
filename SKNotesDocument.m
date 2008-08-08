//
//  SKNotesDocument.m
//  Skim
//
//  Created by Christiaan Hofman on 4/10/07.
/*
 This software is Copyright (c) 2007-2008
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
#import <SkimNotes/PDFAnnotation_SKNExtensions.h>
#import <SkimNotes/SKNPDFAnnotationNote.h>
#import "SKNPDFAnnotationNote_SKExtensions.h"
#import "SKStringConstants.h"
#import "SKFDFParser.h"
#import "SKStatusBar.h"
#import "NSWindowController_SKExtensions.h"
#import "NSDocument_SKExtensions.h"
#import "NSMenu_SKExtensions.h"
#import "NSView_SKExtensions.h"
#import "Files_SKExtensions.h"

static NSString *SKNotesDocumentWindowFrameAutosaveName = @"SKNotesDocumentWindow";

static NSString *SKLastExportedNotesTypeKey = @"SKLastExportedNotesType";

static NSString *SKNotesDocumentRowHeightKey = @"rowHeight";
static NSString *SKNotesDocumentChildKey = @"child";

static NSString *SKNotesDocumentNotesKey = @"notes";

static NSString *SKNotesDocumentNoteColumnIdentifier = @"note";
static NSString *SKNotesDocumentTypeColumnIdentifier = @"type";
static NSString *SKNotesDocumentPageColumnIdentifier = @"page";

@implementation SKNotesDocument

- (id)init {
    if (self = [super init]) {
        notes = [[NSMutableArray alloc] initWithCapacity:10];
    }
    return self;
}

- (void)dealloc {
    [notes release];
    [super dealloc];
}

- (NSString *)windowNibName {
    return @"NotesDocument";
}

- (void)windowControllerDidLoadNib:(NSWindowController *)aController {
    [aController setShouldCloseDocument:YES];
    
    [aController setWindowFrameAutosaveNameOrCascade:SKNotesDocumentWindowFrameAutosaveName];
    
    NSSortDescriptor *indexSortDescriptor = [[[NSSortDescriptor alloc] initWithKey:SKNPDFAnnotationPageIndexKey ascending:YES] autorelease];
    NSSortDescriptor *stringSortDescriptor = [[[NSSortDescriptor alloc] initWithKey:SKNPDFAnnotationStringKey ascending:YES selector:@selector(localizedCaseInsensitiveNumericCompare:)] autorelease];
    [arrayController setSortDescriptors:[NSArray arrayWithObjects:indexSortDescriptor, stringSortDescriptor, nil]];
    [outlineView reloadData];
    
    SKTypeSelectHelper *typeSelectHelper = [[[SKTypeSelectHelper alloc] init] autorelease];
    [typeSelectHelper setMatchOption:SKSubstringMatch];
    [typeSelectHelper setDataSource:self];
    [outlineView setTypeSelectHelper:typeSelectHelper];
}

- (NSArray *)writableTypesForSaveOperation:(NSSaveOperationType)saveOperation {
    NSMutableArray *writableTypes = [[[super writableTypesForSaveOperation:saveOperation] mutableCopy] autorelease];
    if (saveOperation == NSSaveToOperation) {
        [[NSDocumentController sharedDocumentController] resetCustomExportTemplateFiles];
        NSEnumerator *fileEnum = [[[NSDocumentController sharedDocumentController] customExportTemplateFiles] objectEnumerator];
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
    if ([[SKNotesDocument superclass] instancesRespondToSelector:_cmd]) {
        fileExtension = [super fileNameExtensionForType:typeName saveOperation:saveOperation];
        if (fileExtension == nil && [[[NSDocumentController sharedDocumentController] customExportTemplateFiles] containsObject:typeName])
            fileExtension = [typeName pathExtension];
    } else {
        NSArray *fileExtensions = [[NSDocumentController sharedDocumentController] fileExtensionsFromType:typeName];
        if ([fileExtensions count])
            fileExtension = [fileExtensions objectAtIndex:0];
    }
    return fileExtension;
}

- (BOOL)prepareSavePanel:(NSSavePanel *)savePanel {
    BOOL success = [super prepareSavePanel:savePanel];
    if (success && exportUsingPanel) {
        NSPopUpButton *formatPopup = [[savePanel accessoryView] subviewOfClass:[NSPopUpButton class]];
        if (formatPopup) {
            NSString *lastExportedType = [[NSUserDefaults standardUserDefaults] stringForKey:SKLastExportedNotesTypeKey];
            if (lastExportedType) {
                int idx = [formatPopup indexOfItemWithRepresentedObject:lastExportedType];
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
        NSMutableArray *array = [NSMutableArray arrayWithCapacity:[notes count]];
        NSEnumerator *noteEnum = [notes objectEnumerator];
        NSMutableDictionary *note;
        while (note = [noteEnum nextObject]) {
            note = [note mutableCopy];
            [note removeObjectForKey:SKNotesDocumentRowHeightKey];
            [note removeObjectForKey:SKNotesDocumentChildKey];
            [array addObject:note];
            [note release];
        }
        data = [NSKeyedArchiver archivedDataWithRootObject:array];
    } else if (SKIsNotesRTFDocumentType(typeName)) {
        data = [self notesRTFData];
    } else if (SKIsNotesTextDocumentType(typeName)) {
        data = [[self notesString] dataUsingEncoding:NSUTF8StringEncoding];
    } else {
        data = [self notesDataUsingTemplateFile:typeName];
    }
    
    if (data == nil && outError != NULL)
        *outError = [NSError errorWithDomain:SKDocumentErrorDomain code:0 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Unable to write notes", @"Error description"), NSLocalizedDescriptionKey, nil]];
    
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
            NSMutableDictionary *note = [dict mutableCopy];
            
            [note setValue:[dict valueForKey:SKNPDFAnnotationContentsKey] forKey:SKNPDFAnnotationStringKey];
            if ([[note valueForKey:SKNPDFAnnotationTypeKey] isEqualToString:SKNTextString])
                [note setValue:SKNNoteString forKey:SKNPDFAnnotationTypeKey];
            if ([[note valueForKey:SKNPDFAnnotationTypeKey] isEqualToString:SKNNoteString]) {
                [note setObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithFloat:85.0], SKNotesDocumentRowHeightKey, [dict valueForKey:SKNPDFAnnotationTextKey], SKNPDFAnnotationTextKey, [[dict valueForKey:SKNPDFAnnotationTextKey] string], SKNPDFAnnotationStringKey, nil] forKey:SKNotesDocumentChildKey];
                NSMutableString *contents = [[NSMutableString alloc] init];
                if ([[dict valueForKey:SKNPDFAnnotationContentsKey] length])
                    [contents appendString:[dict valueForKey:SKNPDFAnnotationContentsKey]];
                if ([[dict valueForKey:SKNPDFAnnotationTextKey] length]) {
                    [contents appendString:@"  "];
                    [contents appendString:[[dict valueForKey:SKNPDFAnnotationTextKey] string]];
                }
                [note setValue:contents forKey:SKNPDFAnnotationContentsKey];
                [contents release];
            }
            
            [newNotes addObject:note];
            [note release];
        }
        [[self mutableArrayValueForKey:SKNotesDocumentNotesKey] setArray:newNotes];
        [outlineView reloadData];
        didRead = YES;
    }
    
    if (didRead == NO && outError != NULL)
        *outError = [NSError errorWithDomain:SKDocumentErrorDomain code:0 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Unable to load file", @"Error description"), NSLocalizedDescriptionKey, nil]];
    
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
    NSString *fileName = [self fileName];
    
    if (fileName) {
        NSData *data = [[BDAlias aliasWithPath:fileName] aliasData];
        
        [setup setObject:fileName forKey:SKDocumentSetupFileNameKey];
        if(data)
            [setup setObject:data forKey:SKDocumentSetupAliasKey];
    }
    
    return setup;
}

#pragma mark Actions

- (IBAction)openPDF:(id)sender {
    NSString *path = [[self fileName] stringByReplacingPathExtension:@"pdf"];
    NSError *error = nil;
    if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
        if (nil == [[NSDocumentController sharedDocumentController] openDocumentWithContentsOfURL:SKResolvedURLFromPath(path) display:YES error:&error])
            [NSApp presentError:error];
    } else NSBeep();
}

- (void)copyNote:(id)sender {
    NSDictionary *item = [sender representedObject];
    [self outlineView:outlineView copyItems:[NSArray arrayWithObjects:item, nil]];
}

- (void)autoSizeNoteRows:(id)sender {
    float rowHeight = [outlineView rowHeight];
    NSTableColumn *tableColumn = [outlineView tableColumnWithIdentifier:SKNotesDocumentNoteColumnIdentifier];
    id cell = [tableColumn dataCell];
    float indentation = [outlineView indentationPerLevel];
    float width = NSWidth([cell drawingRectForBounds:NSMakeRect(0.0, 0.0, [tableColumn width] - indentation, rowHeight)]);
    NSSize size = NSMakeSize(width, FLT_MAX);
    NSSize smallSize = NSMakeSize(width - indentation, FLT_MAX);
    
    NSMutableArray *items = [NSMutableArray array];
    id item = [sender representedObject];
    
    if (item) {
        [items addObject:item];
    } else {
        [items addObjectsFromArray:[self notes]];
        [items addObjectsFromArray:[[self notes] valueForKey:SKNotesDocumentChildKey]];
    }
    
    int i, count = [items count];
    NSMutableIndexSet *rowIndexes = [NSMutableIndexSet indexSet];
    int row;
    
    for (i = 0; i < count; i++) {
        item = [items objectAtIndex:i];
        [cell setObjectValue:[item valueForKey:SKNPDFAnnotationTypeKey] ? [item valueForKey:SKNPDFAnnotationStringKey] : [item valueForKey:SKNPDFAnnotationTextKey]];
        NSAttributedString *attrString = [cell attributedStringValue];
        NSRect rect = [attrString boundingRectWithSize:[item type] ? size : smallSize options:NSStringDrawingUsesLineFragmentOrigin];
        [item setValue:[NSNumber numberWithFloat:fmaxf(NSHeight(rect) + 3.0, rowHeight + 2.0)] forKey:SKNotesDocumentRowHeightKey];
        row = [outlineView rowForItem:item];
        if (row != -1)
            [rowIndexes addIndex:row];
    }
    [outlineView noteHeightOfRowsWithIndexesChanged:rowIndexes];
}

#pragma mark Accessors

- (NSArray *)notes {
    return notes;
}

- (void)setNotes:(NSArray *)newNotes {
    [notes setArray:notes];
}

- (unsigned)countOfNotes {
    return [notes count];
}

- (id)objectInNotesAtIndex:(unsigned)theIndex {
    return [notes objectAtIndex:theIndex];
}

- (void)insertObject:(id)obj inNotesAtIndex:(unsigned)theIndex {
    [notes insertObject:obj atIndex:theIndex];
}

- (void)removeObjectFromNotesAtIndex:(unsigned)theIndex {
    [notes removeObjectAtIndex:theIndex];
}

#pragma mark NSOutlineView datasource and delegate methods

- (int)outlineView:(NSOutlineView *)ov numberOfChildrenOfItem:(id)item {
    if (item == nil)
        return [[arrayController arrangedObjects] count];
    else if ([[item valueForKey:SKNPDFAnnotationTypeKey] isEqualToString:SKNNoteString])
        return 1;
    return 0;
}

- (BOOL)outlineView:(NSOutlineView *)ov isItemExpandable:(id)item {
    return [[item valueForKey:SKNPDFAnnotationTypeKey] isEqualToString:SKNNoteString];
}

- (id)outlineView:(NSOutlineView *)ov child:(int)anIndex ofItem:(id)item {
    if (item == nil) {
        return [[arrayController arrangedObjects] objectAtIndex:anIndex];
    } else {
        return [item valueForKey:SKNotesDocumentChildKey];
    }
}

- (id)outlineView:(NSOutlineView *)ov objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item {
    NSString *tcID = [tableColumn identifier];
    if ([tcID isEqualToString:SKNotesDocumentNoteColumnIdentifier]) {
        return [item valueForKey:SKNPDFAnnotationTypeKey] ? [item valueForKey:SKNPDFAnnotationStringKey] : [item valueForKey:SKNPDFAnnotationTextKey];
    } else if([tcID isEqualToString:SKNotesDocumentTypeColumnIdentifier]) {
        return [NSDictionary dictionaryWithObjectsAndKeys:[item valueForKey:SKNPDFAnnotationTypeKey], SKNPDFAnnotationTypeKey, nil];
    } else if ([tcID isEqualToString:SKNotesDocumentPageColumnIdentifier]) {
        NSNumber *pageNumber = [item valueForKey:SKNPDFAnnotationPageIndexKey];
        return pageNumber ? [NSString stringWithFormat:@"%i", [pageNumber intValue] + 1] : nil;
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
        if ([tcID isEqualToString:SKNotesDocumentTypeColumnIdentifier]) {
            [sds insertObject:[[[NSSortDescriptor alloc] initWithKey:SKNPDFAnnotationTypeKey ascending:YES selector:@selector(noteTypeCompare:)] autorelease] atIndex:0];
        } else if ([tcID isEqualToString:SKNotesDocumentNoteColumnIdentifier]) {
            [sds insertObject:[[[NSSortDescriptor alloc] initWithKey:SKNPDFAnnotationStringKey ascending:YES selector:@selector(localizedCaseInsensitiveNumericCompare:)] autorelease] atIndex:0];
        } else if ([tcID isEqualToString:SKNotesDocumentPageColumnIdentifier]) {
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
    NSArray *types = [outlineView noteTypes];
    if ([types count] == 8) {
        [arrayController setFilterPredicate:nil];
    } else {
        NSExpression *lhs = [NSExpression expressionForKeyPath:SKNPDFAnnotationTypeKey];
        NSMutableArray *predicateArray = [NSMutableArray array];
        NSEnumerator *typeEnum = [types objectEnumerator];
        NSString *type;
        
        while (type = [typeEnum nextObject]) {
            NSExpression *rhs = [NSExpression expressionForConstantValue:type];
            NSPredicate *predicate = [NSComparisonPredicate predicateWithLeftExpression:lhs rightExpression:rhs modifier:NSDirectPredicateModifier type:NSEqualToPredicateOperatorType options:0];
            [predicateArray addObject:predicate];
        }
        [arrayController setFilterPredicate:[NSCompoundPredicate orPredicateWithSubpredicates:predicateArray]];
    }
    [outlineView reloadData];
}

- (void)outlineView:(NSOutlineView *)ov copyItems:(NSArray *)items  {
    NSPasteboard *pboard = [NSPasteboard generalPasteboard];
    NSMutableArray *types = [NSMutableArray array];
    NSMutableAttributedString *attrString = [[items valueForKey:SKNPDFAnnotationTypeKey] containsObject:[NSNull null]] ? [[[NSMutableAttributedString alloc] init] autorelease] : nil;
    NSMutableString *string = [NSMutableString string];
    NSEnumerator *itemEnum = [items objectEnumerator];
    NSDictionary *item;
    
    while (item = [itemEnum nextObject]) {
        if ([string length])
            [string appendString:@"\n\n"];
        if ([attrString length])
            [attrString replaceCharactersInRange:NSMakeRange([attrString length], 0) withString:@"\n\n"];
        if ([item valueForKey:SKNPDFAnnotationTypeKey]) {
            [string appendString:[item valueForKey:SKNPDFAnnotationStringKey]];
            [attrString replaceCharactersInRange:NSMakeRange([attrString length], 0) withString:[item valueForKey:SKNPDFAnnotationStringKey]];
        } else {
            [string appendString:[item valueForKey:SKNPDFAnnotationStringKey]];
            [attrString appendAttributedString:[item valueForKey:SKNPDFAnnotationTextKey]];
        }
    }
    
    if (string)
        [types addObject:NSStringPboardType];
    if (attrString)
        [types addObject:NSRTFPboardType];
    if ([types count])
        [pboard declareTypes:types owner:nil];
    if (string)
        [pboard setString:string forType:NSStringPboardType];
    if (attrString)
        [pboard setData:[attrString RTFFromRange:NSMakeRange(0, [string length]) documentAttributes:nil] forType:NSRTFPboardType];
}

- (BOOL)outlineView:(NSOutlineView *)ov canCopyItems:(NSArray *)items  {
    return [items count] > 0;
}

- (float)outlineView:(NSOutlineView *)ov heightOfRowByItem:(id)item {
    NSNumber *heightNumber = [item valueForKey:SKNotesDocumentRowHeightKey];
    return heightNumber ? [heightNumber floatValue] : [ov rowHeight] + 2.0;
}

- (void)outlineView:(NSOutlineView *)ov setHeightOfRow:(int)newHeight byItem:(id)item {
    [item setObject:[NSNumber numberWithFloat:newHeight] forKey:SKNotesDocumentRowHeightKey];
}

- (BOOL)outlineView:(NSOutlineView *)ov canResizeRowByItem:(id)item {
    return nil != [item valueForKey:SKNotesDocumentRowHeightKey];
}

- (NSString *)outlineView:(NSOutlineView *)ov toolTipForCell:(NSCell *)cell rect:(NSRectPointer)rect tableColumn:(NSTableColumn *)tableColumn item:(id)item mouseLocation:(NSPoint)mouseLocation {
    return [item valueForKey:SKNPDFAnnotationStringKey];
}

- (NSMenu *)outlineView:(NSOutlineView *)ov menuForTableColumn:(NSTableColumn *)tableColumn item:(id)item {
    NSMenu *menu = nil;
    NSMenuItem *menuItem;
    
    [outlineView selectRowIndexes:[NSIndexSet indexSetWithIndex:[outlineView rowForItem:item]] byExtendingSelection:NO];
    
    menu = [[[NSMenu allocWithZone:[NSMenu menuZone]] init] autorelease];
    if ([self outlineView:ov canCopyItems:[NSArray arrayWithObjects:item, nil]]) {
        menuItem = [menu addItemWithTitle:NSLocalizedString(@"Copy", @"Menu item title") action:@selector(copyNote:) target:self];
        [menuItem setRepresentedObject:item];
        [menu addItem:[NSMenuItem separatorItem]];
    }
    menuItem = [menu addItemWithTitle:NSLocalizedString(@"Auto Size Row", @"Menu item title") action:@selector(autoSizeNoteRows:) target:self];
    [menuItem setRepresentedObject:item];
    menuItem = [menu addItemWithTitle:NSLocalizedString(@"Auto Size All", @"Menu item title") action:@selector(autoSizeNoteRows:) target:self];
    
    return menu;
}

#pragma mark SKTypeSelectHelper datasource protocol

- (NSArray *)typeSelectHelperSelectionItems:(SKTypeSelectHelper *)typeSelectHelper {
    int i, count = [outlineView numberOfRows];
    NSMutableArray *texts = [NSMutableArray arrayWithCapacity:count];
    for (i = 0; i < count; i++) {
        id item = [outlineView itemAtRow:i];
        NSString *string = [item valueForKey:SKNPDFAnnotationStringKey];
        [texts addObject:string ? string : @""];
    }
    return texts;
}

- (unsigned int)typeSelectHelperCurrentlySelectedIndex:(SKTypeSelectHelper *)typeSelectHelper {
    int row = [outlineView selectedRow];
    return row == -1 ? NSNotFound : row;
}

- (void)typeSelectHelper:(SKTypeSelectHelper *)typeSelectHelper selectItemAtIndex:(unsigned int)itemIndex {
    [outlineView selectRowIndexes:[NSIndexSet indexSetWithIndex:itemIndex] byExtendingSelection:NO];
    [outlineView scrollRowToVisible:itemIndex];
}

- (void)typeSelectHelper:(SKTypeSelectHelper *)typeSelectHelper didFailToFindMatchForSearchString:(NSString *)searchString {
    [statusBar setLeftStringValue:[NSString stringWithFormat:NSLocalizedString(@"No match: \"%@\"", @"Status message"), searchString]];
}

- (void)typeSelectHelper:(SKTypeSelectHelper *)typeSelectHelper updateSearchString:(NSString *)searchString {
    if (searchString)
        [statusBar setLeftStringValue:[NSString stringWithFormat:NSLocalizedString(@"Finding note: \"%@\"", @"Status message"), searchString]];
    else
        [statusBar setLeftStringValue:@""];
}

@end
