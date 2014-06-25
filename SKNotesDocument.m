//
//  SKNotesDocument.m
//  Skim
//
//  Created by Christiaan Hofman on 4/10/07.
/*
 This software is Copyright (c) 2007-2014
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
#import "SKDocumentController.h"
#import "SKTemplateParser.h"
#import "SKApplicationController.h"
#import "NSValue_SKExtensions.h"
#import "NSURL_SKExtensions.h"
#import "SKTypeSelectHelper.h"
#import <SkimNotes/SkimNotes.h>
#import "SKNotesPage.h"
#import "SKNoteText.h"
#import "PDFAnnotation_SKExtensions.h"
#import "SKStringConstants.h"
#import "SKFDFParser.h"
#import "SKStatusBar.h"
#import "NSWindowController_SKExtensions.h"
#import "NSDocument_SKExtensions.h"
#import "NSMenu_SKExtensions.h"
#import "NSView_SKExtensions.h"
#import "NSFileManager_SKExtensions.h"
#import "SKToolbarItem.h"
#import "SKAnnotationTypeImageCell.h"
#import "SKPrintableView.h"
#import "SKPDFView.h"
#import "NSPointerArray_SKExtensions.h"
#import "SKFloatMapTable.h"
#import "NSColor_SKExtensions.h"
#import "NSString_SKExtensions.h"
#import "NSError_SKExtensions.h"
#import "SKTemplateManager.h"
#import "SKCenteredTextFieldCell.h"
#import "NSArray_SKExtensions.h"

#define SKNotesDocumentWindowFrameAutosaveName @"SKNotesDocumentWindow"

#define SKNotesDocumentToolbarIdentifier @"SKNotesDocumentToolbarIdentifier"
#define SKNotesDocumentSearchToolbarItemIdentifier @"SKNotesDocumentSearchToolbarItemIdentifier"
#define SKNotesDocumentOpenPDFToolbarItemIdentifier @"SKNotesDocumentOpenPDFToolbarItemIdentifier"

#define SKLastExportedNotesTypeKey @"SKLastExportedNotesType"

#define SKWindowFrameKey @"windowFrame"

#define NOTES_KEY @"notes"
#define PAGES_KEY @"pages"

#define NOTE_COLUMNID   @"note"
#define TYPE_COLUMNID   @"type"
#define COLOR_COLUMNID  @"color"
#define PAGE_COLUMNID   @"page"
#define AUTHOR_COLUMNID @"author"
#define DATE_COLUMNID   @"date"

#define STATUSBAR_HEIGHT 22.0

#define COLUMN_INDENTATION 16.0
#define EXTRA_ROW_HEIGHT 2.0
#define DEFAULT_TEXT_ROW_HEIGHT 85.0

@implementation SKNotesDocument

@synthesize outlineView, arrayController, searchField, notes, pdfDocument, sourceFileURL;

- (id)init {
    self = [super init];
    if (self) {
        notes = [[NSArray alloc] init];
        pdfDocument = nil;
        rowHeights = [[SKFloatMapTable alloc] init];
        windowRect = NSZeroRect;
        caseInsensitiveSearch = [[NSUserDefaults standardUserDefaults] boolForKey:SKCaseInsensitiveNoteSearchKey];
    }
    return self;
}

- (void)dealloc {
    [outlineView setDelegate:nil];
    [outlineView setDataSource:nil];
    SKDESTROY(notes);
    SKDESTROY(pdfDocument);
    SKDESTROY(sourceFileURL);
	SKDESTROY(rowHeights);
    SKDESTROY(toolbarItems);
    SKDESTROY(statusBar);
    SKDESTROY(noteTypeSheetController);
    SKDESTROY(outlineView);
    SKDESTROY(arrayController);
    SKDESTROY(searchField);
    [super dealloc];
}

- (NSString *)windowNibName {
    return @"NotesDocument";
}

- (void)showWindows{
    NSWindowController *wc = [[self windowControllers] lastObject];
    BOOL wasVisible = [wc isWindowLoaded] && [[wc window] isVisible];
    [super showWindows];
    
    // Get the search string keyword if available (Spotlight passes this)
    NSAppleEventDescriptor *event = [[NSAppleEventManager sharedAppleEventManager] currentAppleEvent];
    NSString *searchString;
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:SKDisableSearchAfterSpotlighKey] == NO &&
        [event eventID] == kAEOpenDocuments && 
        (searchString = [[event descriptorForKeyword:keyAESearchText] stringValue]) && 
        [@"" isEqualToString:searchString] == NO &&
        [searchField window]) {
        if ([searchString length] > 2 && [searchString characterAtIndex:0] == '"' && [searchString characterAtIndex:[searchString length] - 1] == '"') {
            //strip quotes
            searchString = [searchString substringWithRange:NSMakeRange(1, [searchString length] - 2)];
        } else {
            // strip extra search criteria
            NSRange range = [searchString rangeOfString:@":"];
            if (range.location != NSNotFound) {
                range = [searchString rangeOfCharacterFromSet:[NSCharacterSet whitespaceCharacterSet] options:NSBackwardsSearch range:NSMakeRange(0, range.location)];
                if (range.location != NSNotFound && range.location > 0)
                    searchString = [searchString substringWithRange:NSMakeRange(0, range.location)];
            }
        }
        [searchField setStringValue:searchString];
        [self performSelector:@selector(searchNotes:) withObject:searchField afterDelay:0.0];
    }
    
    if (wasVisible == NO)
        [[NSNotificationCenter defaultCenter] postNotificationName:SKDocumentDidShowNotification object:self];
}

- (void)windowControllerDidLoadNib:(NSWindowController *)aController {
    settingUpWindow = YES;
    
    [aController setShouldCloseDocument:YES];
    
    [self setupToolbarForWindow:[aController window]];
    
    [aController setWindowFrameAutosaveNameOrCascade:SKNotesDocumentWindowFrameAutosaveName];
    
    [[aController window] setAutorecalculatesContentBorderThickness:NO forEdge:NSMinYEdge];
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:SKShowNotesStatusBarKey])
        [self toggleStatusBar:nil];
    
    if (NSEqualRects(windowRect, NSZeroRect) == NO)
        [[aController window] setFrame:windowRect display:NO];
    
    NSMenu *menu = [NSMenu menu];
    [menu addItemWithTitle:NSLocalizedString(@"Ignore Case", @"Menu item title") action:@selector(toggleCaseInsensitiveSearch:) target:self];
    [[searchField cell] setSearchMenuTemplate:menu];
    [[searchField cell] setPlaceholderString:NSLocalizedString(@"Search", @"placeholder")];
    
    [outlineView setAutoresizesOutlineColumn: NO];
    [outlineView setIndentationPerLevel:1.0];
    
    NSSortDescriptor *indexSortDescriptor = [[[NSSortDescriptor alloc] initWithKey:SKNPDFAnnotationPageIndexKey ascending:YES] autorelease];
    NSSortDescriptor *stringSortDescriptor = [[[NSSortDescriptor alloc] initWithKey:SKNPDFAnnotationStringKey ascending:YES selector:@selector(localizedCaseInsensitiveNumericCompare:)] autorelease];
    [arrayController setSortDescriptors:[NSArray arrayWithObjects:indexSortDescriptor, stringSortDescriptor, nil]];
    [outlineView reloadData];
    
    [outlineView setTypeSelectHelper:[SKTypeSelectHelper typeSelectHelperWithMatchOption:SKSubstringMatch]];
    
    noteTypeSheetController = [[SKNoteTypeSheetController alloc] init];
    [noteTypeSheetController setDelegate:self];
    
    menu = [[outlineView headerView] menu];
    [menu addItem:[NSMenuItem separatorItem]];
    [[menu addItemWithTitle:NSLocalizedString(@"Note Type", @"Menu item title") action:NULL keyEquivalent:@""] setSubmenu:[noteTypeSheetController noteTypeMenu]];
    
    settingUpWindow = NO;
}

- (NSArray *)writableTypesForSaveOperation:(NSSaveOperationType)saveOperation {
    NSArray *writableTypes = [super writableTypesForSaveOperation:saveOperation];
    if (saveOperation == NSSaveToOperation) {
        NSMutableArray *tmpArray = [[writableTypes mutableCopy] autorelease];
        [[SKTemplateManager sharedManager] resetCustomTemplateTypes];
        [tmpArray addObjectsFromArray:[[SKTemplateManager sharedManager] customTemplateTypes]];
        writableTypes = tmpArray;
    }
    return writableTypes;
}

- (NSString *)fileNameExtensionForType:(NSString *)typeName saveOperation:(NSSaveOperationType)saveOperation {
    return [super fileNameExtensionForType:typeName saveOperation:saveOperation] ?: [[SKTemplateManager sharedManager] fileNameExtensionForTemplateType:typeName];
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

- (void)saveToURL:(NSURL *)absoluteURL ofType:(NSString *)typeName forSaveOperation:(NSSaveOperationType)saveOperation delegate:(id)delegate didSaveSelector:(SEL)didSaveSelector contextInfo:(void *)contextInfo {
    if (saveOperation == NSSaveToOperation && exportUsingPanel)
        [[NSUserDefaults standardUserDefaults] setObject:typeName forKey:SKLastExportedNotesTypeKey];
    [super saveToURL:absoluteURL ofType:typeName forSaveOperation:saveOperation delegate:delegate didSaveSelector:didSaveSelector contextInfo:contextInfo];
}

- (NSFileWrapper *)fileWrapperOfType:(NSString *)typeName error:(NSError **)outError {
    NSFileWrapper *fileWrapper = nil;
    NSWorkspace *ws = [NSWorkspace sharedWorkspace];
    
    if ([ws type:SKNotesRTFDDocumentType conformsToType:typeName])
        fileWrapper = [self notesRTFDFileWrapper];
    else if ([ws type:SKNotesDocumentType conformsToType:typeName] || 
             [ws type:SKNotesTextDocumentType conformsToType:typeName] || 
             [ws type:SKNotesRTFDocumentType conformsToType:typeName] || 
             [ws type:SKNotesFDFDocumentType conformsToType:typeName] || 
             [[SKTemplateManager sharedManager] isRichTextBundleTemplateType:typeName] == NO)
        fileWrapper = [super fileWrapperOfType:typeName error:outError];
    else
        fileWrapper = [self notesFileWrapperForTemplateType:typeName];
    
    if (fileWrapper == nil && outError != NULL)
        *outError = [NSError writeFileErrorWithLocalizedDescription:NSLocalizedString(@"Unable to write notes", @"Error description")];
    
    return fileWrapper;
}

- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError {
    NSData *data = nil;
    NSWorkspace *ws = [NSWorkspace sharedWorkspace];
    
    if ([ws type:SKNotesDocumentType conformsToType:typeName]) {
        data = [self notesData];
    } else if ([ws type:SKNotesTextDocumentType conformsToType:typeName]) {
        data = [[self notesString] dataUsingEncoding:NSUTF8StringEncoding];
    } else if ([ws type:SKNotesRTFDocumentType conformsToType:typeName]) {
        data = [self notesRTFData];
    } else if ([ws type:SKNotesFDFDocumentType conformsToType:typeName]) {
        NSString *filename = nil;
        NSURL *pdfURL = [[self fileURL] URLReplacingPathExtension:@"pdf"];
        if ([pdfURL checkResourceIsReachableAndReturnError:NULL])
            filename = [pdfURL lastPathComponent];
        data = [self notesFDFDataForFile:filename fileIDStrings:nil];
    } else {
        data = [self notesDataForTemplateType:typeName];
    }
    
    if (data == nil && outError != NULL)
        *outError = [NSError writeFileErrorWithLocalizedDescription:NSLocalizedString(@"Unable to write notes", @"Error description")];
    
    return data;
}

- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError {
    BOOL didRead = NO;
    NSArray *array = nil;
    NSWorkspace *ws = [NSWorkspace sharedWorkspace];
    
    if ([ws type:typeName conformsToType:SKNotesDocumentType]) {
        array = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    } else if ([ws type:typeName conformsToType:SKNotesFDFDocumentType]) {
        array = [SKFDFParser noteDictionariesFromFDFData:data];
    }
    
    if (array) {
        NSMutableArray *newNotes = [NSMutableArray arrayWithCapacity:[array count]];
        
        [self willChangeValueForKey:PAGES_KEY];
        [pdfDocument autorelease];
        pdfDocument = [[PDFDocument alloc] init];
        
        for (NSDictionary *dict in array) {
            PDFAnnotation *note = [[PDFAnnotation alloc] initSkimNoteWithProperties:dict];
            PDFPage *page;
            NSUInteger pageIndex = [[dict objectForKey:SKNPDFAnnotationPageIndexKey] unsignedIntegerValue];
            NSUInteger pageCount = [pdfDocument pageCount];
            
            while (pageIndex >= pageCount) {
                page = [[SKNotesPage alloc] init];
                [pdfDocument insertPage:page atIndex:pageCount++];
                [page release];
            }
            [[pdfDocument pageAtIndex:pageIndex] addAnnotation:note];
            [newNotes addObject:note];
            [note release];
        }
        [self didChangeValueForKey:PAGES_KEY];
        
        [self willChangeValueForKey:NOTES_KEY];
        [notes autorelease];
        notes = [newNotes copy];
        [self didChangeValueForKey:NOTES_KEY];
        
        [outlineView reloadData];
        didRead = YES;
    }
    
    if (didRead == NO && outError != NULL)
        *outError = [NSError readFileErrorWithLocalizedDescription:NSLocalizedString(@"Unable to load file", @"Error description")];
    
    return didRead;
}

- (NSDictionary *)fileAttributesToWriteToURL:(NSURL *)absoluteURL ofType:(NSString *)typeName forSaveOperation:(NSSaveOperationType)saveOperation originalContentsURL:(NSURL *)absoluteOriginalContentsURL error:(NSError **)outError {
    NSMutableDictionary *dict = [[[super fileAttributesToWriteToURL:absoluteURL ofType:typeName forSaveOperation:saveOperation originalContentsURL:absoluteOriginalContentsURL error:outError] mutableCopy] autorelease];
    NSWorkspace *ws = [NSWorkspace sharedWorkspace];
    
    // only set the creator code for our native types
    if ([[NSUserDefaults standardUserDefaults] boolForKey:SKShouldSetCreatorCodeKey] && [ws type:typeName conformsToType:SKNotesDocumentType])
        [dict setObject:[NSNumber numberWithUnsignedInt:'SKim'] forKey:NSFileHFSCreatorCode];
    
    if ([ws type:typeName conformsToType:SKNotesDocumentType])
        [dict setObject:[NSNumber numberWithUnsignedInt:'SKNT'] forKey:NSFileHFSTypeCode];
    else if ([[absoluteURL pathExtension] isEqualToString:@"rtf"] || [ws type:typeName conformsToType:SKNotesRTFDocumentType])
        [dict setObject:[NSNumber numberWithUnsignedInt:'RTF '] forKey:NSFileHFSTypeCode];
    else if ([[absoluteURL pathExtension] isEqualToString:@"txt"] || [ws type:typeName conformsToType:SKNotesTextDocumentType])
        [dict setObject:[NSNumber numberWithUnsignedInt:'TEXT'] forKey:NSFileHFSTypeCode];
    
    return dict;
}

- (void)updateNoteFilterPredicate {
    [arrayController setFilterPredicate:[noteTypeSheetController filterPredicateForSearchString:[searchField stringValue] caseInsensitive:caseInsensitiveSearch]];
    [outlineView reloadData];
}

- (NSDictionary *)currentDocumentSetup {
    NSMutableDictionary *setup = [[[super currentDocumentSetup] mutableCopy] autorelease];
    NSWindow *window = [[[self windowControllers] lastObject] window];
    if (window)
        [setup setObject:NSStringFromRect([window frame]) forKey:SKWindowFrameKey];
    return setup;
}

- (void)applySetup:(NSDictionary *)setup {
    NSString *rectString = [setup objectForKey:SKWindowFrameKey];
    NSWindowController *wc = [[self windowControllers] lastObject];
    if (wc == nil) {
        [self makeWindowControllers];
        wc = [[self windowControllers] lastObject];
    }
    if (rectString) {
        if ([wc isWindowLoaded] == NO) {
            windowRect = NSRectFromString(rectString);
        } else {
            [[wc window] setFrame:NSRectFromString(rectString) display:YES];
        }
    }
}

- (void)setFileURL:(NSURL *)absoluteURL {
    if (absoluteURL)
        [self setSourceFileURL:nil];
    [super setFileURL:absoluteURL];
    [[NSNotificationCenter defaultCenter] postNotificationName:SKDocumentFileURLDidChangeNotification object:self];
}

- (NSString *)displayName {
    if (sourceFileURL)
        return [[sourceFileURL lastPathComponent] stringByDeletingPathExtension];
    return [super displayName];
}

#pragma mark Printing

- (NSPrintOperation *)printOperationWithSettings:(NSDictionary *)printSettings error:(NSError **)outError {
    NSPrintInfo *printInfo = [[self printInfo] copy];
    [[printInfo dictionary] addEntriesFromDictionary:printSettings];
    [printInfo setHorizontalPagination:NSFitPagination];
    [printInfo setHorizontallyCentered:NO];
    [printInfo setVerticallyCentered:NO];
    
    SKPrintableView *printableView = [[SKPrintableView alloc] initWithFrame:[printInfo imageablePageBounds]];
    [printableView setVerticallyResizable:YES];
    [printableView setHorizontallyResizable:NO];
    
    NSAttributedString *attrString = [[NSAttributedString alloc] initWithRTF:[self notesRTFData] documentAttributes:NULL];
    NSTextStorage *textStorage = [printableView textStorage];
    [textStorage beginEditing];
    [textStorage setAttributedString:attrString];
    [textStorage endEditing];
    
    NSPrintOperation *printOperation = [NSPrintOperation printOperationWithView:printableView printInfo:printInfo];
    
    [attrString release];
    [printableView release];
    [printInfo release];
    [[printOperation printPanel] setOptions:NSPrintPanelShowsCopies | NSPrintPanelShowsPageRange | NSPrintPanelShowsPaperSize | NSPrintPanelShowsOrientation | NSPrintPanelShowsScaling | NSPrintPanelShowsPreview];
    
    if (printOperation == nil && outError)
        *outError = [NSError printDocumentErrorWithLocalizedDescription:nil];
    
    return printOperation;
}

#pragma mark Actions

- (IBAction)openPDF:(id)sender {
    NSURL *url = sourceFileURL ?: [[self fileURL] URLReplacingPathExtension:@"pdf"];
    NSError *error = nil;
    if ([url checkResourceIsReachableAndReturnError:NULL]) {
        // resolve symlinks and aliases
        NSNumber *isAlias = nil;
        url = [url URLByResolvingSymlinksInPath];
        while ([url getResourceValue:&isAlias forKey:NSURLIsAliasFileKey error:NULL] && [isAlias boolValue]) {
            NSData *data = [NSURL bookmarkDataWithContentsOfURL:url error:NULL];
            if (data)
                url = [NSURL URLByResolvingBookmarkData:data options:NSURLBookmarkResolutionWithoutUI relativeToURL:nil bookmarkDataIsStale:NULL error:NULL] ?: url;
        }
        if (nil == [[NSDocumentController sharedDocumentController] openDocumentWithContentsOfURL:url display:YES error:&error] && [error isUserCancelledError] == NO)
            [self presentError:error];
    } else NSBeep();
}

- (IBAction)searchNotes:(id)sender {
    [self updateNoteFilterPredicate];
}

- (IBAction)toggleStatusBar:(id)sender {
    if (statusBar == nil) {
        statusBar = [[SKStatusBar alloc] initWithFrame:NSMakeRect(0.0, 0.0, NSWidth([[outlineView enclosingScrollView] frame]), STATUSBAR_HEIGHT)];
        [statusBar setAutoresizingMask:NSViewWidthSizable | NSViewMaxYMargin];
    }
    [[NSUserDefaults standardUserDefaults] setBool:(NO == [statusBar isVisible]) forKey:SKShowNotesStatusBarKey];
    [statusBar toggleBelowView:[outlineView enclosingScrollView] animate:sender != nil];
}

- (void)copyNotes:(id)sender {
    [self outlineView:outlineView copyItems:[sender representedObject]];
}

- (void)autoSizeNoteRows:(id)sender {
    CGFloat height,rowHeight = [outlineView rowHeight];
    NSTableColumn *tableColumn = [outlineView tableColumnWithIdentifier:NOTE_COLUMNID];
    id cell = [tableColumn dataCell];
    CGFloat indentation = COLUMN_INDENTATION;
    NSRect rect = NSMakeRect(0.0, 0.0, [tableColumn width] - indentation, CGFLOAT_MAX);
    indentation += [outlineView indentationPerLevel];
    NSRect fullRect = NSMakeRect(0.0, 0.0, NSWidth([outlineView frame]) - indentation, CGFLOAT_MAX);
    
    NSArray *items = [sender representedObject];
    
    if (items == nil) {
        items = [NSMutableArray array];
        [(NSMutableArray *)items addObjectsFromArray:[self notes]];
        [(NSMutableArray *)items addObjectsFromArray:[[self notes] valueForKeyPath:@"@unionOfArrays.texts"]];
        [(NSMutableArray *)items removeObject:[NSNull null]];
    }
    
    for (id item in items) {
        if ([(PDFAnnotation *)item type]) {
            [cell setObjectValue:[item string]];
            height = [cell cellSizeForBounds:rect].height;
        } else {
            [cell setObjectValue:[item text]];
            height = [cell cellSizeForBounds:fullRect].height;
        }
        [rowHeights setFloat:fmax(height, rowHeight) + EXTRA_ROW_HEIGHT forKey:item];
    }
    // don't use noteHeightOfRowsWithIndexesChanged: as this only updates the visible rows and the scrollers
    [outlineView reloadData];
}

- (void)resetHeightOfNoteRows:(id)sender {
    NSArray *items = [sender representedObject];
    if (items == nil) {
        [rowHeights removeAllFloats];
    } else {
        for (id item in items)
            [rowHeights removeFloatForKey:item];
    }
    [outlineView reloadData];
}

- (IBAction)toggleCaseInsensitiveSearch:(id)sender {
    caseInsensitiveSearch = NO == caseInsensitiveSearch;
    if ([[searchField stringValue] length])
        [self searchNotes:searchField];
    [[NSUserDefaults standardUserDefaults] setBool:caseInsensitiveSearch forKey:SKCaseInsensitiveNoteSearchKey];
}

- (void)performFindPanelAction:(id)sender {
    if ([sender tag] == NSFindPanelActionShowFindPanel) {
        NSToolbar *toolbar = [[[[self windowControllers] objectAtIndex:0] window] toolbar];
        if ([[[toolbar items] valueForKey:@"itemIdentifier"] containsObject:SKNotesDocumentSearchToolbarItemIdentifier] == NO)
            [toolbar insertItemWithItemIdentifier:SKNotesDocumentSearchToolbarItemIdentifier atIndex:0];
        if ([toolbar displayMode] == NSToolbarDisplayModeLabelOnly)
            [toolbar setDisplayMode:NSToolbarDisplayModeDefault];
        [toolbar setVisible:YES];
        [searchField selectText:nil];
    } else {
        NSBeep();
	}
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
    } else if (action == @selector(performFindPanelAction:)) {
        switch ([menuItem tag]) {
            case NSFindPanelActionShowFindPanel:
                return YES;
            default:
                return NO;
        }
    }
    return YES;
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
    PDFAnnotation *note = item;
    if (tableColumn == nil) {
        return [note text];
    } else if ([tcID isEqualToString:NOTE_COLUMNID]) {
        return [note type] ? (id)[note string] : (id)[note text];
    } else if([tcID isEqualToString:TYPE_COLUMNID]) {
        return [NSDictionary dictionaryWithObjectsAndKeys:[note type], SKAnnotationTypeImageCellTypeKey, nil];
    } else if([tcID isEqualToString:COLOR_COLUMNID]) {
        return [note type] ? [note color] : nil;
    } else if ([tcID isEqualToString:PAGE_COLUMNID]) {
        return [note type] ? [NSString stringWithFormat:@"%lu", (unsigned long)([note pageIndex] + 1)] : nil;
    }
    return nil;
}

- (NSCell *)outlineView:(NSOutlineView *)ov dataCellForTableColumn:(NSTableColumn *)tableColumn item:(id)item {
    if (tableColumn == nil && [(PDFAnnotation *)item type] == nil) {
        return [[ov tableColumnWithIdentifier:NOTE_COLUMNID] dataCellForRow:[ov rowForItem:item]];
    }
    return [tableColumn dataCellForRow:[ov rowForItem:item]];
}

- (void)outlineView:(NSOutlineView *)ov didClickTableColumn:(NSTableColumn *)tableColumn {
    NSTableColumn *oldTableColumn = [ov highlightedTableColumn];
    NSMutableArray *sortDescriptors = nil;
    BOOL ascending = YES;
    if ([NSEvent modifierFlags] & NSCommandKeyMask)
        tableColumn = nil;
    if ([oldTableColumn isEqual:tableColumn]) {
        sortDescriptors = [[[arrayController sortDescriptors] mutableCopy] autorelease];
        [sortDescriptors replaceObjectAtIndex:0 withObject:[[sortDescriptors firstObject] reversedSortDescriptor]];
        ascending = [[sortDescriptors firstObject] ascending];
    } else {
        NSString *tcID = [tableColumn identifier];
        NSSortDescriptor *pageIndexSortDescriptor = [[[NSSortDescriptor alloc] initWithKey:SKNPDFAnnotationPageIndexKey ascending:ascending] autorelease];
        NSSortDescriptor *boundsSortDescriptor = [[[NSSortDescriptor alloc] initWithKey:SKNPDFAnnotationBoundsKey ascending:ascending selector:@selector(boundsCompare:)] autorelease];
        sortDescriptors = [NSMutableArray arrayWithObjects:pageIndexSortDescriptor, boundsSortDescriptor, nil];
        if ([tcID isEqualToString:TYPE_COLUMNID]) {
            [sortDescriptors insertObject:[[[NSSortDescriptor alloc] initWithKey:SKNPDFAnnotationTypeKey ascending:YES selector:@selector(noteTypeCompare:)] autorelease] atIndex:0];
        } else if ([tcID isEqualToString:COLOR_COLUMNID]) {
            [sortDescriptors insertObject:[[[NSSortDescriptor alloc] initWithKey:SKNPDFAnnotationColorKey ascending:YES selector:@selector(colorCompare:)] autorelease] atIndex:0];
        } else if ([tcID isEqualToString:NOTE_COLUMNID]) {
            [sortDescriptors insertObject:[[[NSSortDescriptor alloc] initWithKey:SKNPDFAnnotationStringKey ascending:YES selector:@selector(localizedCaseInsensitiveNumericCompare:)] autorelease] atIndex:0];
        } else if ([tcID isEqualToString:AUTHOR_COLUMNID]) {
            [sortDescriptors insertObject:[[[NSSortDescriptor alloc] initWithKey:SKNPDFAnnotationUserNameKey ascending:YES selector:@selector(localizedCaseInsensitiveNumericCompare:)] autorelease] atIndex:0];
        } else if ([tcID isEqualToString:DATE_COLUMNID]) {
            [sortDescriptors insertObject:[[[NSSortDescriptor alloc] initWithKey:SKNPDFAnnotationModificationDateKey ascending:YES] autorelease] atIndex:0];
        } else if ([tcID isEqualToString:PAGE_COLUMNID]) {
            if (oldTableColumn == nil)
                ascending = NO;
        }
        if (oldTableColumn)
            [ov setIndicatorImage:nil inTableColumn:oldTableColumn];
        [ov setHighlightedTableColumn:tableColumn]; 
    }
    [arrayController setSortDescriptors:sortDescriptors];
    if (tableColumn)
        [ov setIndicatorImage:[NSImage imageNamed:ascending ? @"NSAscendingSortIndicator" : @"NSDescendingSortIndicator"]
                inTableColumn:tableColumn];
    [ov reloadData];
}

- (void)outlineView:(NSOutlineView *)ov copyItems:(NSArray *)items  {
    NSPasteboard *pboard = [NSPasteboard generalPasteboard];
    NSMutableArray *copiedItems = [NSMutableArray array];
    NSMutableAttributedString *attrString = [[[NSMutableAttributedString alloc] init] autorelease];
    BOOL isAttributed = NO;
    PDFAnnotation *item;
    
    for (item in items) {
        if ([item type] == nil)
            item = [(SKNoteText *)item note];
        
        if ([copiedItems containsObject:item] == NO && [item isMarkup] == NO)
            [copiedItems addObject:item];
    }
    for (item in items) {
        if ([attrString length])
            [attrString replaceCharactersInRange:NSMakeRange([attrString length], 0) withString:@"\n\n"];
        if ([item type]) {
            [attrString replaceCharactersInRange:NSMakeRange([attrString length], 0) withString:[item string]];
        } else {
            [attrString appendAttributedString:[(SKNoteText *)item text]];
            isAttributed = YES;
        }
    }
    
    [pboard clearContents];
    if (isAttributed)
        [pboard writeObjects:[NSArray arrayWithObjects:attrString, nil]];
    else
        [pboard writeObjects:[NSArray arrayWithObjects:[attrString string], nil]];
    if ([copiedItems count] > 0)
        [pboard writeObjects:copiedItems];
}

- (BOOL)outlineView:(NSOutlineView *)ov canCopyItems:(NSArray *)items  {
    return [items count] > 0;
}

- (CGFloat)outlineView:(NSOutlineView *)ov heightOfRowByItem:(id)item {
    CGFloat rowHeight = [rowHeights floatForKey:item];
    return (rowHeight > 0.0 ? rowHeight : ([(PDFAnnotation *)item type] ? [ov rowHeight] + EXTRA_ROW_HEIGHT : DEFAULT_TEXT_ROW_HEIGHT));
}

- (BOOL)outlineView:(NSOutlineView *)ov canResizeRowByItem:(id)item {
    return YES;
}

- (void)outlineView:(NSOutlineView *)ov setHeight:(CGFloat)newHeight ofRowByItem:(id)item {
    [rowHeights setFloat:newHeight forKey:item];
}

- (NSString *)outlineView:(NSOutlineView *)ov toolTipForCell:(NSCell *)cell rect:(NSRectPointer)rect tableColumn:(NSTableColumn *)tableColumn item:(id)item mouseLocation:(NSPoint)mouseLocation {
    return [item string];
}

- (NSArray *)outlineView:(NSOutlineView *)ov typeSelectHelperSelectionStrings:(SKTypeSelectHelper *)typeSelectHelper {
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

#pragma mark Contextual menu

- (void)menuNeedsUpdate:(NSMenu *)menu {
    if ([menu isEqual:[outlineView menu]]) {
        NSMenuItem *item;
        NSMutableArray *items = [NSMutableArray array];
        NSIndexSet *rowIndexes = [outlineView selectedRowIndexes];
        NSInteger row = [outlineView clickedRow];
        [menu removeAllItems];
        if (row != -1) {
            if ([rowIndexes containsIndex:row] == NO)
                rowIndexes = [NSIndexSet indexSetWithIndex:row];
            [rowIndexes enumerateIndexesUsingBlock:^(NSUInteger rowIdx, BOOL *stop) {
                [items addObject:[outlineView itemAtRow:rowIdx]];
            }];
            
            if ([self outlineView:outlineView canCopyItems:items]) {
                item = [menu addItemWithTitle:NSLocalizedString(@"Copy", @"Menu item title") action:@selector(copyNotes:) target:self];
                [item setRepresentedObject:items];
                [menu addItem:[NSMenuItem separatorItem]];
            }
            item = [menu addItemWithTitle:[items count] == 1 ? NSLocalizedString(@"Auto Size Row", @"Menu item title") : NSLocalizedString(@"Auto Size Rows", @"Menu item title") action:@selector(autoSizeNoteRows:) target:self];
            [item setRepresentedObject:items];
            [menu addItemWithTitle:NSLocalizedString(@"Auto Size All", @"Menu item title") action:@selector(autoSizeNoteRows:) target:self];
        }
    }
}

#pragma mark SKNoteTypeSheetController delegate protocol

- (void)noteTypeSheetControllerNoteTypesDidChange:(SKNoteTypeSheetController *)controller {
    [self updateNoteFilterPredicate];
}

- (NSWindow *)windowForNoteTypeSheetController:(SKNoteTypeSheetController *)controller {
    return [outlineView window];
}

#pragma mark Toolbar

- (void)setupToolbarForWindow:(NSWindow *)aWindow {
    // Create a new toolbar instance, and attach it to our document window
    NSToolbar *toolbar = [[[NSToolbar alloc] initWithIdentifier:SKNotesDocumentToolbarIdentifier] autorelease];
    SKToolbarItem *item;
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:1];
    
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
    size.width = 240.0;
    [item setMaxSize:size];
    [dict setObject:item forKey:SKNotesDocumentSearchToolbarItemIdentifier];
    [item release];
    
    item = [[SKToolbarItem alloc] initWithItemIdentifier:SKNotesDocumentOpenPDFToolbarItemIdentifier];
    [item setLabels:NSLocalizedString(@"Open PDF", @"Toolbar item label")];
    [item setToolTip:NSLocalizedString(@"Open Associated PDF File", @"Tool tip message")];
    [item setImageNamed:@"PDFDocument"];
    [item setTarget:self];
    [item setAction:@selector(openPDF:)];
    [dict setObject:item forKey:SKNotesDocumentOpenPDFToolbarItemIdentifier];
    [item release];
    
    toolbarItems = [dict mutableCopy];
    
    // Attach the toolbar to the window
    [aWindow setToolbar:toolbar];
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
        return [(sourceFileURL ?: [[self fileURL] URLReplacingPathExtension:@"pdf"]) checkResourceIsReachableAndReturnError:NULL];
    return YES;
}

#pragma mark Scripting

- (id)handleSaveScriptCommand:(NSScriptCommand *)command {
	NSDictionary *args = [command evaluatedArguments];
    id fileType = [args objectForKey:@"FileType"];
    id file = [args objectForKey:@"File"];
    // we don't want to expose the UTI types to the user, and we allow template file names without extension
    if (fileType && file) {
        NSString *normalizedType = nil;
        SKTemplateManager *tm = [SKTemplateManager sharedManager];
        if ([fileType isEqualToString:@"Skim Notes"])
            normalizedType = SKNotesDocumentType;
        else if ([fileType isEqualToString:@"Notes as Text"])
            normalizedType = SKNotesTextDocumentType;
        else if ([fileType isEqualToString:@"Notes as RTF"])
            normalizedType = SKNotesRTFDocumentType;
        else if ([fileType isEqualToString:@"Notes as RTFD"])
            normalizedType = SKNotesRTFDDocumentType;
        else if ([fileType isEqualToString:@"Notes as FDF"])
            normalizedType = SKNotesFDFDocumentType;
        else if ([[self writableTypesForSaveOperation:NSSaveToOperation] containsObject:fileType] == NO)
            normalizedType = [tm templateTypeForDisplayName:fileType];
        if (normalizedType || [[tm customTemplateTypes] containsObject:fileType]) {
            NSMutableDictionary *arguments = [[command arguments] mutableCopy];
            if (normalizedType) {
                fileType = normalizedType;
                [arguments setObject:fileType forKey:@"FileType"];
            }
            // for some reason the default implementation adds the extension twice for template types
            if ([[file pathExtension] isCaseInsensitiveEqual:[tm fileNameExtensionForTemplateType:fileType]])
                [arguments setObject:[file URLByDeletingPathExtension] forKey:@"File"];
            [command setArguments:arguments];
            [arguments release];
        }
    }
    return [super handleSaveScriptCommand:command];
}

@end
