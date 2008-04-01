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
#import "SKDocument.h"
#import "SKNoteOutlineView.h"
#import "BDAlias.h"
#import "SKDocumentController.h"
#import "SKTemplateParser.h"
#import "SKApplicationController.h"
#import "NSValue_SKExtensions.h"
#import "NSString_SKExtensions.h"
#import "SKTypeSelectHelper.h"
#import "PDFAnnotation_SKExtensions.h"
#import "SKStringConstants.h"
#import "SKFDFParser.h"
#import "SKStatusBar.h"
#import "NSWindowController_SKExtensions.h"

static NSString *SKNotesDocumentWindowFrameAutosaveName = @"SKNotesDocumentWindow";

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
    
    NSSortDescriptor *indexSortDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"pageIndex" ascending:YES] autorelease];
    NSSortDescriptor *stringSortDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"string" ascending:YES selector:@selector(localizedCaseInsensitiveNumericCompare:)] autorelease];
    [arrayController setSortDescriptors:[NSArray arrayWithObjects:indexSortDescriptor, stringSortDescriptor, nil]];
    [outlineView reloadData];
    
    SKTypeSelectHelper *typeSelectHelper = [[[SKTypeSelectHelper alloc] init] autorelease];
    [typeSelectHelper setMatchOption:SKSubstringMatch];
    [typeSelectHelper setDataSource:self];
    [outlineView setTypeSelectHelper:typeSelectHelper];
}

- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError {
    NSData *data = nil;
    
    if (SKIsNotesDocumentType(typeName)) {
        NSMutableArray *array = [NSMutableArray arrayWithCapacity:[notes count]];
        NSEnumerator *noteEnum = [notes objectEnumerator];
        NSMutableDictionary *note;
        while (note = [noteEnum nextObject]) {
            note = [note mutableCopy];
            [note removeObjectForKey:@"rowHeight"];
            [note removeObjectForKey:@"child"];
            [array addObject:note];
            [note release];
        }
        data = [NSKeyedArchiver archivedDataWithRootObject:array];
    } else if (SKIsNotesRTFDocumentType(typeName)) {
        data = [self notesRTFData];
    } else if (SKIsNotesTextDocumentType(typeName)) {
        data = [[self notesString] dataUsingEncoding:NSUTF8StringEncoding];
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
            
            [note setValue:[dict valueForKey:@"contents"] forKey:@"string"];
            if ([[note valueForKey:@"type"] isEqualToString:SKTextString])
                [note setValue:SKNoteString forKey:@"type"];
            if ([[note valueForKey:@"type"] isEqualToString:SKNoteString]) {
                [note setObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithFloat:85.0], @"rowHeight", [dict valueForKey:@"text"], @"string", nil] forKey:@"child"];
                NSMutableString *contents = [[NSMutableString alloc] init];
                if ([[dict valueForKey:@"contents"] length])
                    [contents appendString:[dict valueForKey:@"contents"]];
                if ([[dict valueForKey:@"text"] length]) {
                    [contents appendString:@"  "];
                    [contents appendString:[[dict valueForKey:@"text"] string]];
                }
                [note setValue:contents forKey:@"contents"];
                [contents release];
            }
            
            [newNotes addObject:note];
            [note release];
        }
        [[self mutableArrayValueForKey:@"notes"] setArray:newNotes];
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

- (NSString *)notesString {
    NSString *templatePath = [[NSApp delegate] pathForApplicationSupportFile:@"notesTemplate" ofType:@"txt"];
    NSString *templateString = [[NSString alloc] initWithContentsOfFile:templatePath encoding:NSUTF8StringEncoding error:NULL];
    NSString *string = [SKTemplateParser stringByParsingTemplate:templateString usingObject:self];
    return string;
}

- (NSData *)notesRTFData {
    NSString *templatePath = [[NSApp delegate] pathForApplicationSupportFile:@"notesTemplate" ofType:@"rtf"];
    NSDictionary *docAttributes = nil;
    NSAttributedString *templateAttrString = [[NSAttributedString alloc] initWithPath:templatePath documentAttributes:&docAttributes];
    NSAttributedString *attrString = [SKTemplateParser attributedStringByParsingTemplate:templateAttrString usingObject:self];
    NSData *data = [attrString RTFFromRange:NSMakeRange(0, [attrString length]) documentAttributes:docAttributes];
    [templateAttrString release];
    return data;
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
        FSRef ref;
        NSURL *url = nil;
        if (noErr == FSPathMakeRef((const unsigned char *)[[path stringByResolvingSymlinksInPath] fileSystemRepresentation], &ref, NULL))
            url = [(NSURL *)CFURLCreateFromFSRef(NULL, &ref) autorelease];
        if (url == nil)
            url = [NSURL fileURLWithPath:path];
        if (nil == [[NSDocumentController sharedDocumentController] openDocumentWithContentsOfURL:url display:YES error:&error])
            [NSApp presentError:error];
    } else NSBeep();
}

- (void)copyNote:(id)sender {
    NSDictionary *item = [sender representedObject];
    [self outlineView:outlineView copyItems:[NSArray arrayWithObjects:item, nil]];
}

- (void)autoSizeNoteRows:(id)sender {
    float rowHeight = [outlineView rowHeight];
    NSTableColumn *tableColumn = [outlineView tableColumnWithIdentifier:@"note"];
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
        [items addObjectsFromArray:[[self notes] valueForKey:@"child"]];
    }
    
    int i, count = [items count];
    NSMutableIndexSet *rowIndexes = [NSMutableIndexSet indexSet];
    int row;
    
    for (i = 0; i < count; i++) {
        item = [items objectAtIndex:i];
        [cell setObjectValue:[item valueForKey:@"string"]];
        NSAttributedString *attrString = [cell attributedStringValue];
        NSRect rect = [attrString boundingRectWithSize:[item type] ? size : smallSize options:NSStringDrawingUsesLineFragmentOrigin];
        [item setValue:[NSNumber numberWithFloat:fmaxf(NSHeight(rect) + 3.0, rowHeight + 2.0)] forKey:@"rowHeight"];
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
    else if ([[item valueForKey:@"type"] isEqualToString:SKNoteString])
        return 1;
    return 0;
}

- (BOOL)outlineView:(NSOutlineView *)ov isItemExpandable:(id)item {
    return [[item valueForKey:@"type"] isEqualToString:SKNoteString];
}

- (id)outlineView:(NSOutlineView *)ov child:(int)anIndex ofItem:(id)item {
    if (item == nil) {
        return [[arrayController arrangedObjects] objectAtIndex:anIndex];
    } else {
        return [item valueForKey:@"child"];
    }
}

- (id)outlineView:(NSOutlineView *)ov objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item {
    NSString *tcID = [tableColumn identifier];
    if ([tcID isEqualToString:@"note"]) {
        return [item valueForKey:@"string"];
    } else if([tcID isEqualToString:@"type"]) {
        return [NSDictionary dictionaryWithObjectsAndKeys:[item valueForKey:@"type"], @"type", nil];
    } else if ([tcID isEqualToString:@"page"]) {
        NSNumber *pageNumber = [item valueForKey:@"pageIndex"];
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
        NSSortDescriptor *pageIndexSortDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"pageIndex" ascending:ascending] autorelease];
        NSSortDescriptor *boundsSortDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"bounds" ascending:ascending selector:@selector(boundsCompare:)] autorelease];
        NSMutableArray *sds = [NSMutableArray arrayWithObjects:pageIndexSortDescriptor, boundsSortDescriptor, nil];
        if ([tcID isEqualToString:@"type"]) {
            [sds insertObject:[[[NSSortDescriptor alloc] initWithKey:@"type" ascending:YES selector:@selector(noteTypeCompare:)] autorelease] atIndex:0];
        } else if ([tcID isEqualToString:@"note"]) {
            [sds insertObject:[[[NSSortDescriptor alloc] initWithKey:@"string" ascending:YES selector:@selector(localizedCaseInsensitiveNumericCompare:)] autorelease] atIndex:0];
        } else if ([tcID isEqualToString:@"page"]) {
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
        NSExpression *lhs = [NSExpression expressionForKeyPath:@"type"];
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
    NSDictionary *firstItem = [items objectAtIndex:0];
    NSPasteboard *pboard = [NSPasteboard generalPasteboard];
    NSMutableArray *types = [NSMutableArray array];
    NSAttributedString *attrString = [firstItem valueForKey:@"type"] ? nil : [firstItem valueForKey:@"string"];
    NSString *string = [firstItem valueForKey:@"type"] ? [firstItem valueForKey:@"string"] : [attrString string];
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
    NSNumber *heightNumber = [item valueForKey:@"rowHeight"];
    return heightNumber ? [heightNumber floatValue] : [ov rowHeight] + 2.0;
}

- (void)outlineView:(NSOutlineView *)ov setHeightOfRow:(int)newHeight byItem:(id)item {
    [item setObject:[NSNumber numberWithFloat:newHeight] forKey:@"rowHeight"];
}

- (BOOL)outlineView:(NSOutlineView *)ov canResizeRowByItem:(id)item {
    return nil != [item valueForKey:@"rowHeight"];
}

- (NSString *)outlineView:(NSOutlineView *)ov toolTipForCell:(NSCell *)cell rect:(NSRectPointer)rect tableColumn:(NSTableColumn *)tableColumn item:(id)item mouseLocation:(NSPoint)mouseLocation {
    return [item valueForKey:@"type"] ? [item valueForKey:@"string"] : [[item valueForKey:@"string"] string];
}

- (NSMenu *)outlineView:(NSOutlineView *)ov menuForTableColumn:(NSTableColumn *)tableColumn item:(id)item {
    NSMenu *menu = nil;
    NSMenuItem *menuItem;
    
    [outlineView selectRowIndexes:[NSIndexSet indexSetWithIndex:[outlineView rowForItem:item]] byExtendingSelection:NO];
    
    menu = [[[NSMenu allocWithZone:[NSMenu menuZone]] init] autorelease];
    if ([self outlineView:ov canCopyItems:[NSArray arrayWithObjects:item, nil]]) {
        menuItem = [menu addItemWithTitle:NSLocalizedString(@"Copy", @"Menu item title") action:@selector(copyNote:) keyEquivalent:@""];
        [menuItem setTarget:self];
        [menuItem setRepresentedObject:item];
        [menu addItem:[NSMenuItem separatorItem]];
    }
    menuItem = [menu addItemWithTitle:NSLocalizedString(@"Auto Size Row", @"Menu item title") action:@selector(autoSizeNoteRows:) keyEquivalent:@""];
    [menuItem setTarget:self];
    [menuItem setRepresentedObject:item];
    menuItem = [menu addItemWithTitle:NSLocalizedString(@"Auto Size All", @"Menu item title") action:@selector(autoSizeNoteRows:) keyEquivalent:@""];
    [menuItem setTarget:self];
    
    return menu;
}

#pragma mark SKTypeSelectHelper datasource protocol

- (NSArray *)typeSelectHelperSelectionItems:(SKTypeSelectHelper *)typeSelectHelper {
    int i, count = [outlineView numberOfRows];
    NSMutableArray *texts = [NSMutableArray arrayWithCapacity:count];
    for (i = 0; i < count; i++) {
        id item = [outlineView itemAtRow:i];
        NSString *string = [item valueForKey:@"type"] ? [item valueForKey:@"string"] : [[item valueForKey:@"string"] string];
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
