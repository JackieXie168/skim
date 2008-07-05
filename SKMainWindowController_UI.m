//
//  SKMainWindowController_UI.m
//  Skim
//
//  Created by Christiaan Hofman on 5/2/08.
/*
 This software is Copyright (c) 2008
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

#import "SKMainWindowController_UI.h"
#import "SKTocOutlineView.h"
#import "SKNoteOutlineView.h"
#import "SKThumbnailTableView.h"
#import "SKFindTableView.h"
#import "SKSplitView.h"
#import "SKPDFView.h"
#import "SKStatusBar.h"
#import "SKSnapshotWindowController.h"
#import "SKNoteWindowController.h"
#import "SKSideWindow.h"
#import "SKProgressController.h"
#import "SKAnnotationTypeImageCell.h"
#import "SKStringConstants.h"
#import <SkimNotes/PDFAnnotation_SKNExtensions.h>
#import <SkimNotes/SKNPDFAnnotationNote.h>
#import "PDFAnnotation_SKExtensions.h"
#import "SKNPDFAnnotationNote_SKExtensions.h"
#import "SKPDFHoverWindow.h"
#import "SKPDFDocument.h"
#import "PDFPage_SKExtensions.h"
#import "SKGroupedSearchResult.h"
#import "PDFSelection_SKExtensions.h"
#import "NSString_SKExtensions.h"
#import "SKApplication.h"
#import "NSMenu_SKExtensions.h"

static NSString *SKMainWindowLabelColumnIdentifer = @"label";
static NSString *SKMainWindowNoteColumnIdentifer = @"note";
static NSString *SKMainWindowTypeColumnIdentifer = @"type";
static NSString *SKMainWindowImageColumnIdentifer = @"image";

static NSString *noteToolImageNames[] = {@"ToolbarTextNoteMenu", @"ToolbarAnchoredNoteMenu", @"ToolbarCircleNoteMenu", @"ToolbarSquareNoteMenu", @"ToolbarHighlightNoteMenu", @"ToolbarUnderlineNoteMenu", @"ToolbarStrikeOutNoteMenu", @"ToolbarLineNoteMenu"};

@interface SKMainWindowController (SKPrivateMain)

- (void)updateFontPanel;
- (void)updateColorPanel;
- (void)updateLineInspector;

- (void)updateLeftStatus;
- (void)updateRightStatus;

- (void)updatePageNumber;
- (void)updatePageLabel;

- (void)updateNoteFilterPredicate;

- (void)updateFindResultHighlights:(BOOL)scroll;

- (void)hideLeftSideWindow;
- (void)hideRightSideWindow;

- (void)goToPage:(PDFPage *)page;

- (void)goToSelectedOutlineItem;

- (void)showHoverWindowForDestination:(PDFDestination *)dest;

- (void)selectSelectedNote;

- (void)observeUndoManagerCheckpoint:(NSNotification *)notification;

@end

#pragma mark -

@implementation SKMainWindowController (UI)

#pragma mark NSWindow delegate protocol

- (NSString *)windowTitleForDocumentDisplayName:(NSString *)displayName {
    if ([pdfView document])
        return [NSString stringWithFormat:NSLocalizedString(@"%@ (page %i of %i)", @"Window title format"), displayName, [self pageNumber], [[pdfView document] pageCount]];
    else
        return displayName;
}

- (void)windowDidBecomeMain:(NSNotification *)notification {
    if ([[self window] isEqual:[notification object]]) {
        [self updateFontPanel];
        [self updateColorPanel];
        [self updateLineInspector];
    }
}

- (void)windowDidResignMain:(NSNotification *)notification {
    if ([[[NSColorPanel sharedColorPanel] accessoryView] isEqual:colorAccessoryView])
        [[NSColorPanel sharedColorPanel] setAccessoryView:nil];
}

- (void)windowWillClose:(NSNotification *)notification {
    if ([[notification object] isEqual:[self window]]) {
        // timers retain their target, so invalidate them now or they may keep firing after the PDF is gone
        if (snapshotTimer) {
            [snapshotTimer invalidate];
            [snapshotTimer release];
            snapshotTimer = nil;
        }
        if (temporaryAnnotationTimer) {
            [temporaryAnnotationTimer invalidate];
            [temporaryAnnotationTimer release];
            temporaryAnnotationTimer = nil;
        }
        
        [ownerController setContent:nil];
    }
}

- (void)windowDidChangeScreen:(NSNotification *)notification {
    if ([[notification object] isEqual:[self window]]) {
        if ([self isFullScreen]) {
            NSScreen *screen = [fullScreenWindow screen];
            [fullScreenWindow setFrame:[screen frame] display:NO];
            
            if ([[leftSideWindow screen] isEqual:screen] == NO) {
                [leftSideWindow orderOut:self];
                [leftSideWindow moveToScreen:screen];
                [leftSideWindow collapse];
                [leftSideWindow orderFront:self];
            }
            if ([[rightSideWindow screen] isEqual:screen] == NO) {
                [rightSideWindow orderOut:self];
                [leftSideWindow moveToScreen:screen];
                [rightSideWindow collapse];
                [rightSideWindow orderFront:self];
            }
        } else if ([self isPresentation]) {
            [fullScreenWindow setFrame:[[fullScreenWindow screen] frame] display:NO];
        }
        [pdfView layoutDocumentView];
        [pdfView setNeedsDisplay:YES];
    }
}

#pragma mark NSTableView delegate protocol

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification {
    if ([[aNotification object] isEqual:findTableView]) {
        [self updateFindResultHighlights:YES];
        
        if ([self isPresentation] && [[NSUserDefaults standardUserDefaults] boolForKey:SKAutoHidePresentationContentsKey])
            [self hideLeftSideWindow];
    } else if ([[aNotification object] isEqual:groupedFindTableView]) {
        [self updateFindResultHighlights:YES];
        
        if ([self isPresentation] && [[NSUserDefaults standardUserDefaults] boolForKey:SKAutoHidePresentationContentsKey])
            [self hideLeftSideWindow];
    } else if ([[aNotification object] isEqual:thumbnailTableView]) {
        if (updatingThumbnailSelection == NO) {
            int row = [thumbnailTableView selectedRow];
            if (row != -1)
                [self goToPage:[[pdfView document] pageAtIndex:row]];
            
            if ([self isPresentation] && [[NSUserDefaults standardUserDefaults] boolForKey:SKAutoHidePresentationContentsKey])
                [self hideLeftSideWindow];
        }
    } else if ([[aNotification object] isEqual:snapshotTableView]) {
        int row = [snapshotTableView selectedRow];
        if (row != -1) {
            SKSnapshotWindowController *controller = [[snapshotArrayController arrangedObjects] objectAtIndex:row];
            if ([[controller window] isVisible])
                [[controller window] orderFront:self];
        }
    }
}

// AppKit bug: need a dummy NSTableDataSource implementation, otherwise some NSTableView delegate methods are ignored
- (int)numberOfRowsInTableView:(NSTableView *)tv { return 0; }

- (id)tableView:(NSTableView *)tv objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row { return nil; }

- (BOOL)tableView:(NSTableView *)tv commandSelectRow:(int)row {
    if ([tv isEqual:thumbnailTableView]) {
        NSRect rect = [[[pdfView document] pageAtIndex:row] boundsForBox:kPDFDisplayBoxCropBox];
        
        rect.origin.y = NSMidY(rect) - 100.0;
        rect.size.height = 200.0;
        [self showSnapshotAtPageNumber:row forRect:rect scaleFactor:[pdfView scaleFactor] autoFits:NO];
        return YES;
    }
    return NO;
}

- (float)tableView:(NSTableView *)tv heightOfRow:(int)row {
    if ([tv isEqual:thumbnailTableView]) {
        NSSize thumbSize = [[[thumbnails objectAtIndex:row] image] size];
        NSSize cellSize = NSMakeSize([[tv tableColumnWithIdentifier:SKMainWindowImageColumnIdentifer] width], 
                                     fminf(thumbSize.height, roundedThumbnailSize));
        if (thumbSize.height < 1.0)
            return 1.0;
        else if (thumbSize.width / thumbSize.height < cellSize.width / cellSize.height)
            return cellSize.height;
        else
            return fmaxf(1.0, fminf(cellSize.width, thumbSize.width) * thumbSize.height / thumbSize.width);
    } else if ([tv isEqual:snapshotTableView]) {
        NSSize thumbSize = [[[[snapshotArrayController arrangedObjects] objectAtIndex:row] thumbnail] size];
        NSSize cellSize = NSMakeSize([[tv tableColumnWithIdentifier:SKMainWindowImageColumnIdentifer] width], 
                                     fminf(thumbSize.height, roundedSnapshotThumbnailSize));
        if (thumbSize.height < 1.0)
            return 1.0;
        else if (thumbSize.width / thumbSize.height < cellSize.width / cellSize.height)
            return cellSize.height;
        else
            return fmaxf(32.0, fminf(cellSize.width, thumbSize.width) * thumbSize.height / thumbSize.width);
    }
    return [tv rowHeight];
}

- (void)tableView:(NSTableView *)tv deleteRowsWithIndexes:(NSIndexSet *)rowIndexes {
    if ([tv isEqual:snapshotTableView]) {
        NSArray *controllers = [[snapshotArrayController arrangedObjects] objectsAtIndexes:rowIndexes];
        [[controllers valueForKey:@"window"] makeObjectsPerformSelector:@selector(orderOut:) withObject:self];
        [[self mutableArrayValueForKey:SKMainWindowSnapshotsKey] removeObjectsInArray:controllers];
    }
}

- (BOOL)tableView:(NSTableView *)tv canDeleteRowsWithIndexes:(NSIndexSet *)rowIndexes {
    if ([tv isEqual:snapshotTableView]) {
        return [rowIndexes count] > 0;
    }
    return NO;
}

- (void)tableView:(NSTableView *)tv copyRowsWithIndexes:(NSIndexSet *)rowIndexes {
    if ([tv isEqual:thumbnailTableView]) {
        unsigned int idx = [rowIndexes firstIndex];
        if (idx != NSNotFound) {
            PDFPage *page = [[pdfView document] pageAtIndex:idx];
            NSData *pdfData = [page dataRepresentation];
            NSData *tiffData = [[page imageForBox:[pdfView displayBox]] TIFFRepresentation];
            NSPasteboard *pboard = [NSPasteboard generalPasteboard];
            [pboard declareTypes:[NSArray arrayWithObjects:NSPDFPboardType, NSTIFFPboardType, nil] owner:nil];
            [pboard setData:pdfData forType:NSPDFPboardType];
            [pboard setData:tiffData forType:NSTIFFPboardType];
        }
    } else if ([tv isEqual:findTableView]) {
        NSMutableString *string = [NSMutableString string];
        unsigned int idx = [rowIndexes firstIndex];
        while (idx != NSNotFound) {
            PDFSelection *match = [searchResults objectAtIndex:idx];
            [string appendString:@"* "];
            [string appendFormat:NSLocalizedString(@"Page %@", @""), [match firstPageLabel]];
            [string appendFormat:@": %@\n", [[match contextString] string]];
            idx = [rowIndexes indexGreaterThanIndex:idx];
        }
        NSPasteboard *pboard = [NSPasteboard generalPasteboard];
        [pboard declareTypes:[NSArray arrayWithObjects:NSStringPboardType, nil] owner:nil];
        [pboard setString:string forType:NSStringPboardType];
    } else if ([tv isEqual:groupedFindTableView]) {
        NSMutableString *string = [NSMutableString string];
        unsigned int idx = [rowIndexes firstIndex];
        while (idx != NSNotFound) {
            SKGroupedSearchResult *result = [groupedSearchResults objectAtIndex:idx];
            NSArray *matches = [result matches];
            [string appendString:@"* "];
            [string appendFormat:NSLocalizedString(@"Page %@", @""), [[result page] label]];
            [string appendString:@": "];
            [string appendFormat:NSLocalizedString(@"%i Results", @""), [matches count]];
            [string appendFormat:@":\n\t%@\n", [[matches valueForKeyPath:@"contextString.string"] componentsJoinedByString:@"\n\t"]];
            idx = [rowIndexes indexGreaterThanIndex:idx];
        }
        NSPasteboard *pboard = [NSPasteboard generalPasteboard];
        [pboard declareTypes:[NSArray arrayWithObjects:NSStringPboardType, nil] owner:nil];
        [pboard setString:string forType:NSStringPboardType];
    }
}

- (BOOL)tableView:(NSTableView *)tv canCopyRowsWithIndexes:(NSIndexSet *)rowIndexes {
    if ([tv isEqual:thumbnailTableView] || [tv isEqual:findTableView] || [tv isEqual:groupedFindTableView]) {
        return [rowIndexes count] > 0;
    }
    return NO;
}

- (NSArray *)tableViewHighlightedRows:(NSTableView *)tv {
    if ([tv isEqual:thumbnailTableView]) {
        return lastViewedPages;
    }
    return nil;
}

- (BOOL)tableView:(NSTableView *)tv shouldTrackTableColumn:(NSTableColumn *)aTableColumn row:(int)row {
    if ([tv isEqual:findTableView]) {
        return YES;
    } else if ([tv isEqual:groupedFindTableView]) {
        return YES;
    }
    return NO;
}

- (void)tableView:(NSTableView *)tv mouseEnteredTableColumn:(NSTableColumn *)aTableColumn row:(int)row {
    if ([tv isEqual:findTableView]) {
        PDFDestination *dest = [[[findArrayController arrangedObjects] objectAtIndex:row] destination];
        [self showHoverWindowForDestination:dest];
    } else if ([tv isEqual:groupedFindTableView]) {
        PDFDestination *dest = [[[[[groupedFindArrayController arrangedObjects] objectAtIndex:row] matches] objectAtIndex:0] destination];
        [self showHoverWindowForDestination:dest];
    }
}

- (void)tableView:(NSTableView *)tv mouseExitedTableColumn:(NSTableColumn *)aTableColumn row:(int)row {
    if ([tv isEqual:findTableView]) {
        [[SKPDFHoverWindow sharedHoverWindow] fadeOut];
    } else if ([tv isEqual:groupedFindTableView]) {
        [[SKPDFHoverWindow sharedHoverWindow] fadeOut];
    }
}

- (void)copyPage:(id)sender {
    PDFPage *page = [sender representedObject];
    NSData *pdfData = [page dataRepresentation];
    NSData *tiffData = [[page imageForBox:[pdfView displayBox]] TIFFRepresentation];
    NSPasteboard *pboard = [NSPasteboard generalPasteboard];
    [pboard declareTypes:[NSArray arrayWithObjects:NSPDFPboardType, NSTIFFPboardType, nil] owner:nil];
    [pboard setData:pdfData forType:NSPDFPboardType];
    [pboard setData:tiffData forType:NSTIFFPboardType];
}

- (void)deleteSnapshot:(id)sender {
    SKSnapshotWindowController *controller = [sender representedObject];
    [[controller window] orderOut:self];
    [[self mutableArrayValueForKey:SKMainWindowSnapshotsKey] removeObject:controller];
}

- (void)showSnapshot:(id)sender {
    SKSnapshotWindowController *controller = [sender representedObject];
    if ([[controller window] isVisible])
        [[controller window] orderFront:self];
    else
        [controller deminiaturize];
}

- (void)hideSnapshot:(id)sender {
    SKSnapshotWindowController *controller = [sender representedObject];
    if ([[controller window] isVisible])
        [controller miniaturize];
}

- (NSMenu *)tableView:(NSTableView *)tv menuForTableColumn:(NSTableColumn *)tableColumn row:(int)row {
    NSMenu *menu = nil;
    if ([tv isEqual:thumbnailTableView]) {
        menu = [[[NSMenu allocWithZone:[NSMenu menuZone]] init] autorelease];
        NSMenuItem *menuItem = [menu addItemWithTitle:NSLocalizedString(@"Copy", @"Menu item title") action:@selector(copyPage:) target:self];
        [menuItem setRepresentedObject:[[pdfView document] pageAtIndex:row]];
    } else if ([tv isEqual:snapshotTableView]) {
        [snapshotTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
        
        menu = [[[NSMenu allocWithZone:[NSMenu menuZone]] init] autorelease];
        SKSnapshotWindowController *controller = [[snapshotArrayController arrangedObjects] objectAtIndex:row];
        NSMenuItem *menuItem = [menu addItemWithTitle:NSLocalizedString(@"Delete", @"Menu item title") action:@selector(deleteSnapshot:) target:self];
        [menuItem setRepresentedObject:controller];
        menuItem = [menu addItemWithTitle:NSLocalizedString(@"Show", @"Menu item title") action:@selector(showSnapshot:) target:self];
        [menuItem setRepresentedObject:controller];
        if ([[controller window] isVisible]) {
            menuItem = [menu addItemWithTitle:NSLocalizedString(@"Hide", @"Menu item title") action:@selector(hideSnapshot:) target:self];
            [menuItem setRepresentedObject:controller];
        }
    }
    return menu;
}

#pragma mark NSOutlineView datasource protocol

- (int)outlineView:(NSOutlineView *)ov numberOfChildrenOfItem:(id)item{
    if ([ov isEqual:outlineView]) {
        if (item == nil){
            if ((pdfOutline) && ([[pdfView document] isLocked] == NO)){
                return [pdfOutline numberOfChildren];
            }else{
                return 0;
            }
        }else{
            return [(PDFOutline *)item numberOfChildren];
        }
    } else if ([ov isEqual:noteOutlineView]) {
        if (item == nil) {
            return [[noteArrayController arrangedObjects] count];
        } else {
            return [[item texts] count];
        }
    }
    return 0;
}

- (id)outlineView:(NSOutlineView *)ov child:(int)anIndex ofItem:(id)item{
    if ([ov isEqual:outlineView]) {
        if (item == nil){
            if ((pdfOutline) && ([[pdfView document] isLocked] == NO)){
                // Apple's sample code retains this object before returning it, which prevents a crash, but also causes a leak.  We could rewrite PDFOutline, but it's easier just to collect these objects and release them in -dealloc.
                id obj = [pdfOutline childAtIndex:anIndex];
                if (obj)
                    [pdfOutlineItems addObject:obj];
                return obj;
                
            }else{
                return nil;
            }
        }else{
            id obj = [(PDFOutline *)item childAtIndex:anIndex];
            if (obj)
                [pdfOutlineItems addObject:obj];
            return obj;
        }
    } else if ([ov isEqual:noteOutlineView]) {
        if (item == nil) {
            return [[noteArrayController arrangedObjects] objectAtIndex:anIndex];
        } else {
            return [[item texts] lastObject];
        }
    }
    return nil;
}

- (BOOL)outlineView:(NSOutlineView *)ov isItemExpandable:(id)item{
    if ([ov isEqual:outlineView]) {
        if (item == nil){
            if ((pdfOutline) && ([[pdfView document] isLocked] == NO)){
                return ([pdfOutline numberOfChildren] > 0);
            }else{
                return NO;
            }
        }else{
            return ([(PDFOutline *)item numberOfChildren] > 0);
        }
    } else if ([ov isEqual:noteOutlineView]) {
        return [[item texts] count] > 0;
    }
    return NO;
}

- (id)outlineView:(NSOutlineView *)ov objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item{
    if ([ov isEqual:outlineView]) {
        NSString *tcID = [tableColumn identifier];
        if([tcID isEqualToString:SKMainWindowLabelColumnIdentifer]){
            return [(PDFOutline *)item label];
        }else if([tcID isEqualToString:SKMainWindowPageColumnIdentifer]){
            return [[[(PDFOutline *)item destination] page] label];
        }else{
            [NSException raise:@"Unexpected tablecolumn identifier" format:@" - %@ ", tcID];
            return nil;
        }
    } else if ([ov isEqual:noteOutlineView]) {
        NSString *tcID = [tableColumn  identifier];
        if ([tcID isEqualToString:SKMainWindowNoteColumnIdentifer]) {
            return [item type] ? (id)[item string] : (id)[item text];
        } else if([tcID isEqualToString:SKMainWindowTypeColumnIdentifer]) {
            return [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:item == [pdfView activeAnnotation]], SKAnnotationTypeImageCellActiveKey, [item type], SKAnnotationTypeImageCellTypeKey, nil];
        } else if([tcID isEqualToString:SKMainWindowPageColumnIdentifer]) {
            return [[item page] label];
        }
    }
    return nil;
}

- (void)outlineView:(NSOutlineView *)ov setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn byItem:(id)item{
    if ([ov isEqual:noteOutlineView]) {
        if ([[tableColumn identifier] isEqualToString:SKMainWindowNoteColumnIdentifer]) {
            if ([item type] && [object isEqualToString:[item string]] == NO)
                [item setString:object];
        }
    }
}

#pragma mark NSOutlineView delegate protocol

- (BOOL)outlineView:(NSOutlineView *)ov shouldEditTableColumn:(NSTableColumn *)tableColumn item:(id)item{
    if ([ov isEqual:noteOutlineView]) {
        if ([[tableColumn identifier] isEqualToString:SKMainWindowNoteColumnIdentifer]) {
            if ([item type] == nil) {
                if ([pdfView hideNotes] == NO) {
                    PDFAnnotation *annotation = [(SKNoteText *)item annotation];
                    [pdfView scrollAnnotationToVisible:annotation];
                    [pdfView setActiveAnnotation:annotation];
                    [self showNote:annotation];
                }
                return NO;
            } else {
                return YES;
            }
        }
    }
    return NO;
}

- (void)outlineView:(NSOutlineView *)ov didClickTableColumn:(NSTableColumn *)tableColumn {
    if ([ov isEqual:noteOutlineView]) {
        NSTableColumn *oldTableColumn = [ov highlightedTableColumn];
        NSArray *sortDescriptors = nil;
        BOOL ascending = YES;
        if ([oldTableColumn isEqual:tableColumn]) {
            sortDescriptors = [[noteArrayController sortDescriptors] valueForKey:@"reversedSortDescriptor"];
            ascending = [[sortDescriptors lastObject] ascending];
        } else {
            NSString *tcID = [tableColumn identifier];
            NSSortDescriptor *pageIndexSortDescriptor = [[[NSSortDescriptor alloc] initWithKey:SKNPDFAnnotationPageIndexKey ascending:ascending] autorelease];
            NSSortDescriptor *boundsSortDescriptor = [[[NSSortDescriptor alloc] initWithKey:SKNPDFAnnotationBoundsKey ascending:ascending selector:@selector(boundsCompare:)] autorelease];
            NSMutableArray *sds = [NSMutableArray arrayWithObjects:pageIndexSortDescriptor, boundsSortDescriptor, nil];
            if ([tcID isEqualToString:SKMainWindowTypeColumnIdentifer]) {
                [sds insertObject:[[[NSSortDescriptor alloc] initWithKey:SKNPDFAnnotationTypeKey ascending:YES selector:@selector(noteTypeCompare:)] autorelease] atIndex:0];
            } else if ([tcID isEqualToString:SKMainWindowNoteColumnIdentifer]) {
                [sds insertObject:[[[NSSortDescriptor alloc] initWithKey:SKNPDFAnnotationStringKey ascending:YES selector:@selector(localizedCaseInsensitiveNumericCompare:)] autorelease] atIndex:0];
            } else if ([tcID isEqualToString:SKMainWindowPageColumnIdentifer]) {
                if (oldTableColumn == nil)
                    ascending = NO;
            }
            sortDescriptors = sds;
            if (oldTableColumn)
                [ov setIndicatorImage:nil inTableColumn:oldTableColumn];
            [ov setHighlightedTableColumn:tableColumn]; 
        }
        [noteArrayController setSortDescriptors:sortDescriptors];
        [ov setIndicatorImage:[NSImage imageNamed:ascending ? @"NSAscendingSortIndicator" : @"NSDescendingSortIndicator"]
                inTableColumn:tableColumn];
        [ov reloadData];
    }
}

- (void)outlineViewSelectionDidChange:(NSNotification *)notification{
	// Get the destination associated with the search result list. Tell the PDFView to go there.
	if ([[notification object] isEqual:outlineView] && (updatingOutlineSelection == NO)){
        [self goToSelectedOutlineItem];
        if ([self isPresentation] && [[NSUserDefaults standardUserDefaults] boolForKey:SKAutoHidePresentationContentsKey])
            [self hideLeftSideWindow];
    }
}

- (NSString *)outlineView:(NSOutlineView *)ov toolTipForCell:(NSCell *)cell rect:(NSRectPointer)rect tableColumn:(NSTableColumn *)tableColumn item:(id)item mouseLocation:(NSPoint)mouseLocation {
    if ([ov isEqual:noteOutlineView] && [[tableColumn identifier] isEqualToString:@"note"]) {
        return [item string];
    }
    return nil;
}

- (void)outlineViewItemDidExpand:(NSNotification *)notification{
    if ([[notification object] isEqual:outlineView]) {
        [self updateOutlineSelection];
    }
}


- (void)outlineViewItemDidCollapse:(NSNotification *)notification{
    if ([[notification object] isEqual:outlineView]) {
        [self updateOutlineSelection];
    }
}

- (void)outlineViewNoteTypesDidChange:(NSOutlineView *)ov {
    if ([ov isEqual:noteOutlineView]) {
        [self updateNoteFilterPredicate];
    }
}

- (float)outlineView:(NSOutlineView *)ov heightOfRowByItem:(id)item {
    float rowHeight = 0.0;
    if ([ov isEqual:noteOutlineView]) {
        if (CFDictionaryContainsKey(rowHeights, (const void *)item))
            rowHeight = *(float *)CFDictionaryGetValue(rowHeights, (const void *)item);
        else if ([item type] == nil)
            rowHeight = 85.0;
        return rowHeight > 0.0 ? rowHeight : [ov rowHeight] + 2.0;
    }
    return rowHeight > 0.0 ? rowHeight : [ov rowHeight];
}

- (BOOL)outlineView:(NSOutlineView *)ov canResizeRowByItem:(id)item {
    if ([ov isEqual:noteOutlineView]) {
        return YES;
    }
    return NO;
}

- (void)outlineView:(NSOutlineView *)ov setHeightOfRow:(float)newHeight byItem:(id)item {
    CFDictionarySetValue(rowHeights, (const void *)item, &newHeight);
}

- (NSArray *)noteItems:(NSArray *)items {
    NSEnumerator *itemEnum = [items objectEnumerator];
    PDFAnnotation *item;
    NSMutableArray *noteItems = [NSMutableArray array];
    
    while (item = [itemEnum nextObject]) {
        if ([item type] == nil) {
            item = [(SKNoteText *)item annotation];
        }
        if ([noteItems containsObject:item] == NO)
            [noteItems addObject:item];
    }
    return noteItems;
}

- (void)outlineView:(NSOutlineView *)ov deleteItems:(NSArray *)items  {
    if ([ov isEqual:noteOutlineView] && [items count]) {
        NSEnumerator *itemEnum = [[self noteItems:items] objectEnumerator];
        PDFAnnotation *item;
        while (item = [itemEnum nextObject])
            [pdfView removeAnnotation:item];
        [[[self document] undoManager] setActionName:NSLocalizedString(@"Remove Note", @"Undo action name")];
    }
}

- (BOOL)outlineView:(NSOutlineView *)ov canDeleteItems:(NSArray *)items  {
    if ([ov isEqual:noteOutlineView]) {
        return [items count] > 0;
    }
    return NO;
}

- (void)outlineView:(NSOutlineView *)ov copyItems:(NSArray *)items  {
    if ([ov isEqual:noteOutlineView] && [items count]) {
        NSPasteboard *pboard = [NSPasteboard generalPasteboard];
        NSMutableArray *types = [NSMutableArray array];
        NSData *noteData = nil;
        NSMutableAttributedString *attrString = [[items valueForKey:SKNPDFAnnotationTypeKey] containsObject:[NSNull null]] ? [[[NSMutableAttributedString alloc] init] autorelease] : nil;
        NSMutableString *string = [NSMutableString string];
        NSEnumerator *itemEnum;
        id item;
        
        itemEnum = [[self noteItems:items] objectEnumerator];
        while (item = [itemEnum nextObject]) {
            if ([item isMovable]) {
                noteData = [NSKeyedArchiver archivedDataWithRootObject:[item SkimNoteProperties]];
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
        if (noteData)
            [types addObject:SKSkimNotePboardType];
        if ([string length])
            [types addObject:NSStringPboardType];
        if ([attrString length])
            [types addObject:NSRTFPboardType];
        if ([types count])
            [pboard declareTypes:types owner:nil];
        if (noteData)
            [pboard setData:noteData forType:SKSkimNotePboardType];
        if ([string length])
            [pboard setString:string forType:NSStringPboardType];
        if ([attrString length])
            [pboard setData:[attrString RTFFromRange:NSMakeRange(0, [string length]) documentAttributes:nil] forType:NSRTFPboardType];
    }
}

- (BOOL)outlineView:(NSOutlineView *)ov canCopyItems:(NSArray *)items  {
    if ([ov isEqual:noteOutlineView]) {
        return [items count] > 0;
    }
    return NO;
}

- (void)outlineViewInsertNewline:(NSOutlineView *)ov {
    if ([ov isEqual:noteOutlineView]) {
        [self selectSelectedNote];
    }
}

- (NSArray *)outlineViewHighlightedRows:(NSOutlineView *)ov {
    if ([ov isEqual:outlineView]) {
        NSMutableArray *array = [NSMutableArray array];
        NSEnumerator *rowEnum = [lastViewedPages objectEnumerator];
        NSNumber *rowNumber;
        
        while (rowNumber = [rowEnum nextObject]) {
            int row = [self outlineRowForPageIndex:[rowNumber intValue]];
            if (row != -1)
                [array addObject:[NSNumber numberWithInt:row]];
        }
        
        return array;
    }
    return nil;
}

- (BOOL)outlineView:(NSOutlineView *)ov shouldTrackTableColumn:(NSTableColumn *)aTableColumn item:(id)item {
    return YES;
}

- (void)outlineView:(NSOutlineView *)ov mouseEnteredTableColumn:(NSTableColumn *)aTableColumn item:(id)item {
    if ([ov isEqual:outlineView]) {
        [self showHoverWindowForDestination:[item destination]];
    }
}

- (void)outlineView:(NSOutlineView *)ov mouseExitedTableColumn:(NSTableColumn *)aTableColumn item:(id)item {
    if ([ov isEqual:outlineView]) {
        [[SKPDFHoverWindow sharedHoverWindow] fadeOut];
    }
}

- (void)deleteNotes:(id)sender {
    [self outlineView:noteOutlineView deleteItems:[sender representedObject]];
}

- (void)copyNotes:(id)sender {
    [self outlineView:noteOutlineView copyItems:[sender representedObject]];
}

- (void)selectNote:(id)sender {
    PDFAnnotation *annotation = [sender representedObject];
    [pdfView setActiveAnnotation:annotation];
}

- (void)deselectNote:(id)sender {
    [pdfView setActiveAnnotation:nil];
}

- (void)autoSizeNoteRows:(id)sender {
    float rowHeight = [noteOutlineView rowHeight];
    NSTableColumn *tableColumn = [noteOutlineView tableColumnWithIdentifier:SKMainWindowNoteColumnIdentifer];
    id cell = [tableColumn dataCell];
    float indentation = [noteOutlineView indentationPerLevel];
    float width = NSWidth([cell drawingRectForBounds:NSMakeRect(0.0, 0.0, [tableColumn width] - indentation, rowHeight)]);
    NSSize size = NSMakeSize(width, FLT_MAX);
    NSSize smallSize = NSMakeSize(width - indentation, FLT_MAX);
    
    NSArray *items = [sender representedObject];
    
    if (items == nil) {
        items = [NSMutableArray array];
        [(NSMutableArray *)items addObjectsFromArray:[self notes]];
        [(NSMutableArray *)items addObjectsFromArray:[[self notes] valueForKeyPath:@"@unionOfArrays.texts"]];
    }
    
    int i, count = [items count];
    NSMutableIndexSet *rowIndexes = [NSMutableIndexSet indexSet];
    int row;
    id item;
    
    for (i = 0; i < count; i++) {
        item = [items objectAtIndex:i];
        [cell setObjectValue:[item type] ? (id)[item string] : (id)[item text]];
        NSAttributedString *attrString = [cell attributedStringValue];
        NSRect rect = [attrString boundingRectWithSize:[item type] ? size : smallSize options:NSStringDrawingUsesLineFragmentOrigin];
        float height = fmaxf(NSHeight(rect) + 3.0, rowHeight + 2.0);
        CFDictionarySetValue(rowHeights, (const void *)item, &height);
        row = [noteOutlineView rowForItem:item];
        if (row != -1)
            [rowIndexes addIndex:row];
    }
    // don't use noteHeightOfRowsWithIndexesChanged: as this only updates the visible rows and the scrollers
    [noteOutlineView reloadData];
}

- (NSMenu *)outlineView:(NSOutlineView *)ov menuForTableColumn:(NSTableColumn *)tableColumn item:(id)item {
    NSMenu *menu = nil;
    NSMenuItem *menuItem;
    
    if ([ov isEqual:noteOutlineView]) {
        if ([noteOutlineView isRowSelected:[noteOutlineView rowForItem:item]] == NO)
            [noteOutlineView selectRowIndexes:[NSIndexSet indexSetWithIndex:[noteOutlineView rowForItem:item]] byExtendingSelection:NO];
        
        NSMutableArray *items = [NSMutableArray array];
        NSIndexSet *rowIndexes = [noteOutlineView selectedRowIndexes];
        unsigned int row = [rowIndexes firstIndex];
        while (row != NSNotFound) {
            [items addObject:[noteOutlineView itemAtRow:row]];
            row = [rowIndexes indexGreaterThanIndex:row];
        }
        
        menu = [[[NSMenu allocWithZone:[NSMenu menuZone]] init] autorelease];
        if ([self outlineView:ov canDeleteItems:items]) {
            menuItem = [menu addItemWithTitle:NSLocalizedString(@"Delete", @"Menu item title") action:@selector(deleteNotes:) target:self];
            [menuItem setRepresentedObject:items];
        }
        if ([self outlineView:ov canCopyItems:[NSArray arrayWithObjects:item, nil]]) {
            menuItem = [menu addItemWithTitle:NSLocalizedString(@"Copy", @"Menu item title") action:@selector(copyNotes:) target:self];
            [menuItem setRepresentedObject:items];
        }
        if ([pdfView hideNotes] == NO) {
            NSArray *noteItems = [self noteItems:items];
            if ([noteItems count] == 1) {
                PDFAnnotation *annotation = [noteItems lastObject];
                if ([annotation isEditable]) {
                    menuItem = [menu addItemWithTitle:NSLocalizedString(@"Edit", @"Menu item title") action:@selector(editThisAnnotation:) target:pdfView];
                    [menuItem setRepresentedObject:annotation];
                }
                if ([pdfView activeAnnotation] == annotation)
                    menuItem = [menu addItemWithTitle:NSLocalizedString(@"Deselect", @"Menu item title") action:@selector(deselectNote:) target:self];
                else
                    menuItem = [menu addItemWithTitle:NSLocalizedString(@"Select", @"Menu item title") action:@selector(selectNote:) target:self];
                [menuItem setRepresentedObject:annotation];
            }
        }
        if ([menu numberOfItems] > 0)
            [menu addItem:[NSMenuItem separatorItem]];
        menuItem = [menu addItemWithTitle:[items count] == 1 ? NSLocalizedString(@"Auto Size Row", @"Menu item title") : NSLocalizedString(@"Auto Size Rows", @"Menu item title") action:@selector(autoSizeNoteRows:) target:self];
        [menuItem setRepresentedObject:items];
        menuItem = [menu addItemWithTitle:NSLocalizedString(@"Auto Size All", @"Menu item title") action:@selector(autoSizeNoteRows:) target:self];
    }
    return menu;
}

- (void)outlineViewCommandKeyPressedDuringNavigation:(NSOutlineView *)ov {
    PDFAnnotation *annotation = [[self selectedNotes] lastObject];
    if (annotation) {
        [pdfView scrollAnnotationToVisible:annotation];
        [pdfView setActiveAnnotation:annotation];
    }
}

#pragma mark SKTypeSelectHelper datasource protocol

- (NSArray *)typeSelectHelperSelectionItems:(SKTypeSelectHelper *)typeSelectHelper {
    if ([typeSelectHelper isEqual:[thumbnailTableView typeSelectHelper]] || [typeSelectHelper isEqual:[pdfView typeSelectHelper]]) {
        return pageLabels;
    } else if ([typeSelectHelper isEqual:[noteOutlineView typeSelectHelper]]) {
        int i, count = [noteOutlineView numberOfRows];
        NSMutableArray *texts = [NSMutableArray arrayWithCapacity:count];
        for (i = 0; i < count; i++) {
            id item = [noteOutlineView itemAtRow:i];
            NSString *string = [item string];
            [texts addObject:string ? string : @""];
        }
        return texts;
    } else if ([typeSelectHelper isEqual:[outlineView typeSelectHelper]]) {
        int i, count = [outlineView numberOfRows];
        NSMutableArray *array = [NSMutableArray arrayWithCapacity:count];
        for (i = 0; i < count; i++) 
            [array addObject:[[(PDFOutline *)[outlineView itemAtRow:i] label] lossyASCIIString]];
        return array;
    }
    return nil;
}

- (unsigned int)typeSelectHelperCurrentlySelectedIndex:(SKTypeSelectHelper *)typeSelectHelper {
    if ([typeSelectHelper isEqual:[thumbnailTableView typeSelectHelper]] || [typeSelectHelper isEqual:[pdfView typeSelectHelper]]) {
        return [[thumbnailTableView selectedRowIndexes] lastIndex];
    } else if ([typeSelectHelper isEqual:[noteOutlineView typeSelectHelper]]) {
        int row = [noteOutlineView selectedRow];
        return row == -1 ? NSNotFound : row;
    } else if ([typeSelectHelper isEqual:[outlineView typeSelectHelper]]) {
        int row = [outlineView selectedRow];
        return row == -1 ? NSNotFound : row;
    }
    return NSNotFound;
}

- (void)typeSelectHelper:(SKTypeSelectHelper *)typeSelectHelper selectItemAtIndex:(unsigned int)itemIndex {
    if ([typeSelectHelper isEqual:[thumbnailTableView typeSelectHelper]] || [typeSelectHelper isEqual:[pdfView typeSelectHelper]]) {
        [self setPageNumber:itemIndex + 1];
    } else if ([typeSelectHelper isEqual:[noteOutlineView typeSelectHelper]]) {
        [noteOutlineView selectRowIndexes:[NSIndexSet indexSetWithIndex:itemIndex] byExtendingSelection:NO];
        [noteOutlineView scrollRowToVisible:itemIndex];
    } else if ([typeSelectHelper isEqual:[outlineView typeSelectHelper]]) {
        [outlineView selectRowIndexes:[NSIndexSet indexSetWithIndex:itemIndex] byExtendingSelection:NO];
        [noteOutlineView scrollRowToVisible:itemIndex];
    }
}

- (void)typeSelectHelper:(SKTypeSelectHelper *)typeSelectHelper didFailToFindMatchForSearchString:(NSString *)searchString {
    if ([typeSelectHelper isEqual:[thumbnailTableView typeSelectHelper]] || [typeSelectHelper isEqual:[pdfView typeSelectHelper]]) {
        [statusBar setLeftStringValue:[NSString stringWithFormat:NSLocalizedString(@"No match: \"%@\"", @"Status message"), searchString]];
    } else if ([typeSelectHelper isEqual:[noteOutlineView typeSelectHelper]]) {
        [statusBar setRightStringValue:[NSString stringWithFormat:NSLocalizedString(@"No match: \"%@\"", @"Status message"), searchString]];
    } else if ([typeSelectHelper isEqual:[outlineView typeSelectHelper]]) {
        [statusBar setLeftStringValue:[NSString stringWithFormat:NSLocalizedString(@"No match: \"%@\"", @"Status message"), searchString]];
    }
}

- (void)typeSelectHelper:(SKTypeSelectHelper *)typeSelectHelper updateSearchString:(NSString *)searchString {
    if ([typeSelectHelper isEqual:[thumbnailTableView typeSelectHelper]] || [typeSelectHelper isEqual:[pdfView typeSelectHelper]]) {
        if (searchString)
            [statusBar setLeftStringValue:[NSString stringWithFormat:NSLocalizedString(@"Go to page: %@", @"Status message"), searchString]];
        else
            [self updateLeftStatus];
    } else if ([typeSelectHelper isEqual:[noteOutlineView typeSelectHelper]]) {
        if (searchString)
            [statusBar setRightStringValue:[NSString stringWithFormat:NSLocalizedString(@"Finding note: \"%@\"", @"Status message"), searchString]];
        else
            [self updateRightStatus];
    } else if ([typeSelectHelper isEqual:[outlineView typeSelectHelper]]) {
        if (searchString)
            [statusBar setLeftStringValue:[NSString stringWithFormat:NSLocalizedString(@"Finding: \"%@\"", @"Status message"), searchString]];
        else
            [self updateLeftStatus];
    }
}

#pragma mark SKSplitView delegate protocol

- (void)splitView:(SKSplitView *)sender doubleClickedDividerAt:(int)offset{
    if ([sender isEqual:splitView]) {
        if (offset == 0)
            [self toggleLeftSidePane:self];
        else
            [self toggleRightSidePane:self];
    } else if ([sender isEqual:pdfSplitView] && [[sender subviews] count] > 1) {
        NSRect primaryFrame = [pdfEdgeView frame];
        NSRect secondaryFrame = [secondaryPdfEdgeView frame];
        
        if (NSHeight(secondaryFrame) > 0.0) {
            lastSecondaryPdfViewPaneHeight = NSHeight(secondaryFrame); // cache this
            primaryFrame.size.height += lastLeftSidePaneWidth;
            secondaryFrame.size.height = 0.0;
        } else {
            if(lastSecondaryPdfViewPaneHeight <= 0.0)
                lastSecondaryPdfViewPaneHeight = 200.0; // a reasonable value to start
            if (lastSecondaryPdfViewPaneHeight > 0.5 * NSHeight(primaryFrame))
                lastSecondaryPdfViewPaneHeight = floorf(0.5 * NSHeight(primaryFrame));
            primaryFrame.size.height -= lastSecondaryPdfViewPaneHeight;
            secondaryFrame.size.height = lastSecondaryPdfViewPaneHeight;
        }
        primaryFrame.origin.y = NSMaxY(secondaryFrame) + [pdfSplitView dividerThickness];
        [pdfEdgeView setFrame:primaryFrame];
        [secondaryPdfEdgeView setFrame:secondaryFrame];
        [pdfSplitView setNeedsDisplay:YES];
        [secondaryPdfView layoutDocumentView];
        [secondaryPdfView setNeedsDisplay:YES];
        [[self window] invalidateCursorRectsForView:sender];
    }
}

- (void)splitView:(NSSplitView *)sender resizeSubviewsWithOldSize:(NSSize)oldSize {
    if ([sender isEqual:splitView]) {
        
        if (usesDrawers == NO) {
            NSView *leftView = [[sender subviews] objectAtIndex:0];
            NSView *mainView = [[sender subviews] objectAtIndex:1]; // pdfView
            NSView *rightView = [[sender subviews] objectAtIndex:2];
            NSRect leftFrame = [leftView frame];
            NSRect mainFrame = [mainView frame];
            NSRect rightFrame = [rightView frame];
            float contentWidth = NSWidth([sender frame]) - 2 * [sender dividerThickness];
            
            if (NSWidth(leftFrame) <= 1.0)
                leftFrame.size.width = 0.0;
            if (NSWidth(rightFrame) <= 1.0)
                rightFrame.size.width = 0.0;
            
            if (contentWidth < NSWidth(leftFrame) + NSWidth(rightFrame)) {
                float resizeFactor = contentWidth / (oldSize.width - [sender dividerThickness]);
                leftFrame.size.width = floorf(resizeFactor * NSWidth(leftFrame));
                rightFrame.size.width = floorf(resizeFactor * NSWidth(rightFrame));
            }
            
            mainFrame.size.width = contentWidth - NSWidth(leftFrame) - NSWidth(rightFrame);
            mainFrame.origin.x = NSMaxX(leftFrame) + [sender dividerThickness];
            rightFrame.origin.x =  NSMaxX(mainFrame) + [sender dividerThickness];
            leftFrame.size.height = rightFrame.size.height = mainFrame.size.height = NSHeight([sender frame]);
            [leftView setFrame:leftFrame];
            [rightView setFrame:rightFrame];
            [mainView setFrame:mainFrame];
        }
        
    } else if ([sender isEqual:pdfSplitView]) {
        
        if ([[sender subviews] count] > 1) {
            NSView *primaryView = [[sender subviews] objectAtIndex:0];
            NSView *secondaryView = [[sender subviews] objectAtIndex:1];
            NSRect primaryFrame = [primaryView frame];
            NSRect secondaryFrame = [secondaryView frame];
            float contentHeight = NSHeight([sender frame]) - [sender dividerThickness];
            
            if (NSHeight(secondaryFrame) <= 1.0)
                secondaryFrame.size.height = 0.0;
            
            if (contentHeight < NSHeight(secondaryFrame))
                secondaryFrame.size.height = floorf(NSHeight(secondaryFrame) * contentHeight / (oldSize.height - [sender dividerThickness]));
            
            primaryFrame.size.height = contentHeight - NSHeight(secondaryFrame);
            primaryFrame.origin.x = NSMaxY(secondaryFrame) + [sender dividerThickness];
            primaryFrame.size.width = secondaryFrame.size.width = NSWidth([sender frame]);
            [primaryView setFrame:primaryFrame];
            [secondaryView setFrame:secondaryFrame];
        } else {
            [[[sender subviews] objectAtIndex:0] setFrame:[sender bounds]];
        }
        
    }
    [sender adjustSubviews];
}

- (void)splitViewDidResizeSubviews:(NSNotification *)notification {
    id sender = [notification object];
    if (([sender isEqual:splitView] || sender == nil) && [[self window] frameAutosaveName] && settingUpWindow == NO && usesDrawers == NO) {
        [[NSUserDefaults standardUserDefaults] setFloat:NSWidth([leftSideContentView frame]) forKey:SKLeftSidePaneWidthKey];
        [[NSUserDefaults standardUserDefaults] setFloat:NSWidth([rightSideContentView frame]) forKey:SKRightSidePaneWidthKey];
    }
}

#pragma mark NSDrawer delegate protocol

- (NSSize)drawerWillResizeContents:(NSDrawer *)sender toSize:(NSSize)contentSize {
    if ([[self window] frameAutosaveName] && settingUpWindow == NO) {
        if ([sender isEqual:leftSideDrawer])
            [[NSUserDefaults standardUserDefaults] setFloat:contentSize.width forKey:SKLeftSidePaneWidthKey];
        else if ([sender isEqual:rightSideDrawer])
            [[NSUserDefaults standardUserDefaults] setFloat:contentSize.width forKey:SKRightSidePaneWidthKey];
    }
    return contentSize;
}

- (void)drawerDidOpen:(NSNotification *)notification {
    id sender = [notification object];
    if ([[self window] frameAutosaveName] && settingUpWindow == NO) {
        if ([sender isEqual:leftSideDrawer])
            [[NSUserDefaults standardUserDefaults] setFloat:[sender contentSize].width forKey:SKLeftSidePaneWidthKey];
        else if ([sender isEqual:rightSideDrawer])
            [[NSUserDefaults standardUserDefaults] setFloat:[sender contentSize].width forKey:SKRightSidePaneWidthKey];
    }
}

- (void)drawerDidClose:(NSNotification *)notification {
    id sender = [notification object];
    if ([[self window] frameAutosaveName] && settingUpWindow == NO) {
        if ([sender isEqual:leftSideDrawer])
            [[NSUserDefaults standardUserDefaults] setFloat:0.0 forKey:SKLeftSidePaneWidthKey];
        else if ([sender isEqual:rightSideDrawer])
            [[NSUserDefaults standardUserDefaults] setFloat:0.0 forKey:SKRightSidePaneWidthKey];
    }
}

#pragma mark UI validation

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem {
    SEL action = [menuItem action];
    if (action == @selector(createNewNote:)) {
        BOOL isMarkup = [menuItem tag] == SKHighlightNote || [menuItem tag] == SKUnderlineNote || [menuItem tag] == SKStrikeOutNote;
        return [self isPresentation] == NO && ([pdfView toolMode] == SKTextToolMode || [pdfView toolMode] == SKNoteToolMode) && (isMarkup == NO || [[[pdfView currentSelection] pages] count]) && [pdfView hideNotes] == NO;
    } else if (action == @selector(createNewTextNote:)) {
        [menuItem setState:[textNoteButton tag] == [menuItem tag] ? NSOnState : NSOffState];
        return [self isPresentation] == NO && ([pdfView toolMode] == SKTextToolMode || [pdfView toolMode] == SKNoteToolMode) && [pdfView hideNotes] == NO;
    } else if (action == @selector(createNewCircleNote:)) {
        [menuItem setState:[circleNoteButton tag] == [menuItem tag] ? NSOnState : NSOffState];
        return [self isPresentation] == NO && ([pdfView toolMode] == SKTextToolMode || [pdfView toolMode] == SKNoteToolMode) && [pdfView hideNotes] == NO;
    } else if (action == @selector(createNewMarkupNote:)) {
        [menuItem setState:[markupNoteButton tag] == [menuItem tag] ? NSOnState : NSOffState];
        return [self isPresentation] == NO && ([pdfView toolMode] == SKTextToolMode || [pdfView toolMode] == SKNoteToolMode) && [[[pdfView currentSelection] pages] count] && [pdfView hideNotes] == NO;
    } else if (action == @selector(editNote:)) {
        PDFAnnotation *annotation = [pdfView activeAnnotation];
        return [self isPresentation] == NO && [annotation isSkimNote] && ([[annotation type] isEqualToString:SKNFreeTextString] || [[annotation type] isEqualToString:SKNNoteString]);
    } else if (action == @selector(toggleHideNotes:)) {
        if ([pdfView hideNotes])
            [menuItem setTitle:NSLocalizedString(@"Show Notes", @"Menu item title")];
        else
            [menuItem setTitle:NSLocalizedString(@"Hide Notes", @"Menu item title")];
        return YES;
    } else if (action == @selector(displaySinglePages:)) {
        BOOL displaySinglePages = [pdfView displayMode] == kPDFDisplaySinglePage || [pdfView displayMode] == kPDFDisplaySinglePageContinuous;
        [menuItem setState:displaySinglePages ? NSOnState : NSOffState];
        return [self isPresentation] == NO;
    } else if (action == @selector(displayFacingPages:)) {
        BOOL displayFacingPages = [pdfView displayMode] == kPDFDisplayTwoUp || [pdfView displayMode] == kPDFDisplayTwoUpContinuous;
        [menuItem setState:displayFacingPages ? NSOnState : NSOffState];
        return [self isPresentation] == NO;
    } else if (action == @selector(changeDisplaySinglePages:)) {
        BOOL displaySinglePages1 = [pdfView displayMode] == kPDFDisplaySinglePage || [pdfView displayMode] == kPDFDisplaySinglePageContinuous;
        BOOL displaySinglePages2 = (PDFDisplayMode)[menuItem tag] == kPDFDisplaySinglePage;
        [menuItem setState:displaySinglePages1 == displaySinglePages2 ? NSOnState : NSOffState];
        return [self isPresentation] == NO;
    } else if (action == @selector(changeDisplayContinuous:)) {
        BOOL displayContinuous1 = [pdfView displayMode] == kPDFDisplaySinglePageContinuous || [pdfView displayMode] == kPDFDisplayTwoUpContinuous;
        BOOL displayContinuous2 = (PDFDisplayMode)[menuItem tag] == kPDFDisplaySinglePageContinuous;
        [menuItem setState:displayContinuous1 == displayContinuous2 ? NSOnState : NSOffState];
        return [self isPresentation] == NO;
    } else if (action == @selector(changeDisplayMode:)) {
        [menuItem setState:[pdfView displayMode] == (PDFDisplayMode)[menuItem tag] ? NSOnState : NSOffState];
        return [self isPresentation] == NO;
    } else if (action == @selector(toggleDisplayContinuous:)) {
        BOOL displayContinuous = [pdfView displayMode] == kPDFDisplaySinglePageContinuous || [pdfView displayMode] == kPDFDisplayTwoUpContinuous;
        [menuItem setState:displayContinuous ? NSOnState : NSOffState];
        return [self isPresentation] == NO;
    } else if (action == @selector(toggleDisplayAsBook:)) {
        [menuItem setState:[pdfView displaysAsBook] ? NSOnState : NSOffState];
        return [self isPresentation] == NO && ([pdfView displayMode] == kPDFDisplayTwoUp || [pdfView displayMode] == kPDFDisplayTwoUpContinuous);
    } else if (action == @selector(toggleDisplayPageBreaks:)) {
        [menuItem setState:[pdfView displaysPageBreaks] ? NSOnState : NSOffState];
        return [self isPresentation] == NO;
    } else if (action == @selector(changeDisplayBox:)) {
        [menuItem setState:[pdfView displayBox] == (PDFDisplayBox)[menuItem tag] ? NSOnState : NSOffState];
        return [self isPresentation] == NO;
    } else if (action == @selector(changeToolMode:)) {
        [menuItem setState:[pdfView toolMode] == (SKToolMode)[menuItem tag] ? NSOnState : NSOffState];
        return YES;
    } else if (action == @selector(changeAnnotationMode:)) {
        if ([[menuItem menu] numberOfItems] > 8)
            [menuItem setState:[pdfView toolMode] == SKNoteToolMode && [pdfView annotationMode] == (SKToolMode)[menuItem tag] ? NSOnState : NSOffState];
        else
            [menuItem setState:[pdfView annotationMode] == (SKToolMode)[menuItem tag] ? NSOnState : NSOffState];
        return YES;
    } else if (action == @selector(doGoToNextPage:)) {
        return [pdfView canGoToNextPage];
    } else if (action == @selector(doGoToPreviousPage:) ) {
        return [pdfView canGoToPreviousPage];
    } else if (action == @selector(doGoToFirstPage:)) {
        return [pdfView canGoToFirstPage];
    } else if (action == @selector(doGoToLastPage:)) {
        return [pdfView canGoToLastPage];
    } else if (action == @selector(allGoToNextPage:)) {
        return NO == [[NSApp valueForKeyPath:@"orderedDocuments.pdfView.canGoToNextPage"] containsObject:[NSNumber numberWithBool:NO]];
    } else if (action == @selector(allGoToPreviousPage:)) {
        return NO == [[NSApp valueForKeyPath:@"orderedDocuments.pdfView.canGoToPreviousPage"] containsObject:[NSNumber numberWithBool:NO]];
    } else if (action == @selector(allGoToFirstPage:)) {
        return NO == [[NSApp valueForKeyPath:@"orderedDocuments.pdfView.canGoToFirstPage"] containsObject:[NSNumber numberWithBool:NO]];
    } else if (action == @selector(allGoToLastPage:)) {
        return NO == [[NSApp valueForKeyPath:@"orderedDocuments.pdfView.canGoToLastPage"] containsObject:[NSNumber numberWithBool:NO]];
    } else if (action == @selector(doGoBack:)) {
        return [pdfView canGoBack];
    } else if (action == @selector(doGoForward:)) {
        return [pdfView canGoForward];
    } else if (action == @selector(goToMarkedPage:)) {
        if (beforeMarkedPageIndex != NSNotFound) {
            [menuItem setTitle:NSLocalizedString(@"Jump Back From Marked Page", @"Menu item title")];
            return YES;
        } else {
            [menuItem setTitle:NSLocalizedString(@"Go To Marked Page", @"Menu item title")];
            return markedPageIndex != NSNotFound && markedPageIndex != [[pdfView currentPage] pageIndex];
        }
    } else if (action == @selector(doZoomIn:)) {
        return [self isPresentation] == NO && [pdfView canZoomIn];
    } else if (action == @selector(doZoomOut:)) {
        return [self isPresentation] == NO && [pdfView canZoomOut];
    } else if (action == @selector(doZoomToActualSize:)) {
        return fabsf([pdfView scaleFactor] - 1.0 ) > 0.01;
    } else if (action == @selector(doZoomToPhysicalSize:)) {
        return [self isPresentation] == NO;
    } else if (action == @selector(doZoomToSelection:)) {
        return [self isPresentation] == NO && NSIsEmptyRect([pdfView currentSelectionRect]) == NO;
    } else if (action == @selector(doZoomToFit:)) {
        return [self isPresentation] == NO && [pdfView autoScales] == NO;
    } else if (action == @selector(alternateZoomToFit:)) {
        PDFDisplayMode displayMode = [pdfView displayMode];
        if (displayMode == kPDFDisplaySinglePage || displayMode == kPDFDisplayTwoUp) {
            [menuItem setTitle:NSLocalizedString(@"Zoom To Width", @"Menu item title")];
        } else {
            [menuItem setTitle:NSLocalizedString(@"Zoom To Height", @"Menu item title")];
        }
        return [self isPresentation] == NO;
    } else if (action == @selector(doAutoScale:)) {
        return [pdfView autoScales] == NO;
    } else if (action == @selector(toggleAutoScale:)) {
        [menuItem setState:[pdfView autoScales] ? NSOnState : NSOffState];
        return YES;
    } else if (action == @selector(cropAll:) || action == @selector(crop:) || action == @selector(autoCropAll:) || action == @selector(smartAutoCropAll:)) {
        return [self isPresentation] == NO;
    } else if (action == @selector(autoSelectContent:)) {
        return [self isPresentation] == NO && [pdfView toolMode] == SKSelectToolMode;
    } else if (action == @selector(toggleLeftSidePane:)) {
        if ([self leftSidePaneIsOpen])
            [menuItem setTitle:NSLocalizedString(@"Hide Contents Pane", @"Menu item title")];
        else
            [menuItem setTitle:NSLocalizedString(@"Show Contents Pane", @"Menu item title")];
        return YES;
    } else if (action == @selector(toggleRightSidePane:)) {
        if ([self rightSidePaneIsOpen])
            [menuItem setTitle:NSLocalizedString(@"Hide Notes Pane", @"Menu item title")];
        else
            [menuItem setTitle:NSLocalizedString(@"Show Notes Pane", @"Menu item title")];
        return [self isPresentation] == NO;
    } else if (action == @selector(changeLeftSidePaneState:)) {
        [menuItem setState:leftSidePaneState == (SKLeftSidePaneState)[menuItem tag] ? (([findTableView window] || [groupedFindTableView window]) ? NSMixedState : NSOnState) : NSOffState];
        return (SKLeftSidePaneState)[menuItem tag] == SKThumbnailSidePaneState || pdfOutline;
    } else if (action == @selector(changeRightSidePaneState:)) {
        [menuItem setState:rightSidePaneState == (SKRightSidePaneState)[menuItem tag] ? NSOnState : NSOffState];
        return [self isPresentation] == NO;
    } else if (action == @selector(toggleSplitPDF:)) {
        if ([secondaryPdfView window])
            [menuItem setTitle:NSLocalizedString(@"Hide Split PDF", @"Menu item title")];
        else
            [menuItem setTitle:NSLocalizedString(@"Show Split PDF", @"Menu item title")];
        return [self isPresentation] == NO && [self isFullScreen] == NO;
    } else if (action == @selector(toggleStatusBar:)) {
        if ([statusBar isVisible])
            [menuItem setTitle:NSLocalizedString(@"Hide Status Bar", @"Menu item title")];
        else
            [menuItem setTitle:NSLocalizedString(@"Show Status Bar", @"Menu item title")];
        return [self isPresentation] == NO;
    } else if (action == @selector(searchPDF:)) {
        return [self isPresentation] == NO;
    } else if (action == @selector(toggleFullScreen:)) {
        if ([self isFullScreen])
            [menuItem setTitle:NSLocalizedString(@"Remove Full Screen", @"Menu item title")];
        else
            [menuItem setTitle:NSLocalizedString(@"Full Screen", @"Menu item title")];
        return [[self pdfDocument] isLocked] == NO;
    } else if (action == @selector(togglePresentation:)) {
        if ([self isPresentation])
            [menuItem setTitle:NSLocalizedString(@"Remove Presentation", @"Menu item title")];
        else
            [menuItem setTitle:NSLocalizedString(@"Presentation", @"Menu item title")];
        return [[self pdfDocument] isLocked] == NO;
    } else if (action == @selector(getInfo:)) {
        return [self isPresentation] == NO;
    } else if (action == @selector(performFit:)) {
        return [self isFullScreen] == NO && [self isPresentation] == NO;
    } else if (action == @selector(password:)) {
        return [self isPresentation] == NO && [[self pdfDocument] isLocked];
    } else if (action == @selector(toggleReadingBar:)) {
        if ([[self pdfView] hasReadingBar])
            [menuItem setTitle:NSLocalizedString(@"Hide Reading Bar", @"Menu item title")];
        else
            [menuItem setTitle:NSLocalizedString(@"Show Reading Bar", @"Menu item title")];
        return [self isPresentation] == NO;
    } else if (action == @selector(savePDFSettingToDefaults:)) {
        if ([self isFullScreen])
            [menuItem setTitle:NSLocalizedString(@"Use Current View Settings as Default for Full Screen", @"Menu item title")];
        else
            [menuItem setTitle:NSLocalizedString(@"Use Current View Settings as Default", @"Menu item title")];
        return [self isPresentation] == NO;
    } else if (action == @selector(toggleCaseInsensitiveSearch:)) {
        [menuItem setState:caseInsensitiveSearch ? NSOnState : NSOffState];
        return YES;
    } else if (action == @selector(toggleWholeWordSearch:)) {
        [menuItem setState:wholeWordSearch ? NSOnState : NSOffState];
        return floor(NSAppKitVersionNumber) > NSAppKitVersionNumber10_4;
    }
    return YES;
}

#pragma mark Notification handlers

- (void)handleChangedHistoryNotification:(NSNotification *)notification {
    [backForwardButton setEnabled:[pdfView canGoBack] forSegment:0];
    [backForwardButton setEnabled:[pdfView canGoForward] forSegment:1];
}

- (void)handlePageChangedNotification:(NSNotification *)notification {
    PDFPage *page = [pdfView currentPage];
    
    [lastViewedPages insertObject:[NSNumber numberWithUnsignedInt:[page pageIndex]] atIndex:0];
    if ([lastViewedPages count] > 5)
        [lastViewedPages removeLastObject];
    [thumbnailTableView setNeedsDisplay:YES];
    [outlineView setNeedsDisplay:YES];
    
    [self updatePageNumber];
    [self updatePageLabel];
    
    [previousNextPageButton setEnabled:[pdfView canGoToPreviousPage] forSegment:0];
    [previousNextPageButton setEnabled:[pdfView canGoToNextPage] forSegment:1];
    [previousPageButton setEnabled:[pdfView canGoToFirstPage] forSegment:0];
    [previousPageButton setEnabled:[pdfView canGoToPreviousPage] forSegment:1];
    [nextPageButton setEnabled:[pdfView canGoToNextPage] forSegment:0];
    [nextPageButton setEnabled:[pdfView canGoToLastPage] forSegment:1];
    [previousNextFirstLastPageButton setEnabled:[pdfView canGoToFirstPage] forSegment:0];
    [previousNextFirstLastPageButton setEnabled:[pdfView canGoToPreviousPage] forSegment:1];
    [previousNextFirstLastPageButton setEnabled:[pdfView canGoToNextPage] forSegment:2];
    [previousNextFirstLastPageButton setEnabled:[pdfView canGoToLastPage] forSegment:3];
    
    [self updateOutlineSelection];
    [self updateNoteSelection];
    [self updateThumbnailSelection];
    
    if (beforeMarkedPageIndex != NSNotFound && [[pdfView currentPage] pageIndex] != markedPageIndex)
        beforeMarkedPageIndex = NSNotFound;
    
    [mainWindow setTitle:[self windowTitleForDocumentDisplayName:[[self document] displayName]]];
    [self updateLeftStatus];
}

- (void)handleScaleChangedNotification:(NSNotification *)notification {
    [scaleField setFloatValue:[pdfView scaleFactor] * 100.0];
    
    [zoomInOutButton setEnabled:[pdfView canZoomOut] forSegment:0];
    [zoomInOutButton setEnabled:[pdfView canZoomIn] forSegment:1];
    [zoomInActualOutButton setEnabled:[pdfView canZoomOut] forSegment:0];
    [zoomInActualOutButton setEnabled:fabsf([pdfView scaleFactor] - 1.0 ) > 0.01 forSegment:1];
    [zoomInActualOutButton setEnabled:[pdfView canZoomIn] forSegment:2];
    [zoomActualButton setEnabled:fabsf([pdfView scaleFactor] - 1.0 ) > 0.01];
}

- (void)handleToolModeChangedNotification:(NSNotification *)notification {
    [toolModeButton selectSegmentWithTag:[pdfView toolMode]];
    [statusBar setRightAction:[pdfView toolMode] == SKSelectToolMode ? @selector(statusBarClicked:) : NULL];
}

- (void)handleDisplayBoxChangedNotification:(NSNotification *)notification {
    [displayBoxButton selectSegmentWithTag:[pdfView displayBox]];
    if (notification) // no need to do this when loading the document
        [self resetThumbnails];
}

- (void)handleDisplayModeChangedNotification:(NSNotification *)notification {
    PDFDisplayMode displayMode = [pdfView displayMode];
    [displayModeButton selectSegmentWithTag:displayMode];
    [singleTwoUpButton selectSegmentWithTag:(displayMode == kPDFDisplaySinglePage || displayMode == kPDFDisplaySinglePageContinuous) ? kPDFDisplaySinglePage : kPDFDisplayTwoUp];
    [continuousButton selectSegmentWithTag:(displayMode == kPDFDisplaySinglePage || displayMode == kPDFDisplayTwoUp) ? kPDFDisplaySinglePage : kPDFDisplaySinglePageContinuous];
}

- (void)handleAnnotationModeChangedNotification:(NSNotification *)notification {
    [toolModeButton setImage:[NSImage imageNamed:noteToolImageNames[[pdfView annotationMode]]] forSegment:SKNoteToolMode];
}

- (void)handleSelectionChangedNotification:(NSNotification *)notification {
    [self updateRightStatus];
}

- (void)handleMagnificationChangedNotification:(NSNotification *)notification {
    [self updateRightStatus];
}

- (void)handleApplicationWillTerminateNotification:(NSNotification *)notification {
    if ([self isFullScreen] || [self isPresentation])
        [self exitFullScreen:self];
}

- (void)handleApplicationDidResignActiveNotification:(NSNotification *)notification {
    if ([self isPresentation]) {
        [fullScreenWindow setLevel:NSNormalWindowLevel];
    }
}

- (void)handleApplicationWillBecomeActiveNotification:(NSNotification *)notification {
    if ([self isPresentation]) {
        [fullScreenWindow setLevel:NSPopUpMenuWindowLevel];
    }
}

- (void)handleDocumentWillSaveNotification:(NSNotification *)notification {
    [pdfView endAnnotationEdit:self];
}

- (void)handleDidChangeActiveAnnotationNotification:(NSNotification *)notification {
    PDFAnnotation *annotation = [pdfView activeAnnotation];
    
    if ([[self window] isMainWindow]) {
        [self updateFontPanel];
        [self updateColorPanel];
        [self updateLineInspector];
    }
    if ([annotation isSkimNote]) {
        if ([[self selectedNotes] containsObject:annotation] == NO) {
            [noteOutlineView selectRowIndexes:[NSIndexSet indexSetWithIndex:[noteOutlineView rowForItem:annotation]] byExtendingSelection:NO];
        }
    } else {
        [noteOutlineView deselectAll:self];
    }
    [noteOutlineView reloadData];
}

- (void)handleDidAddAnnotationNotification:(NSNotification *)notification {
    PDFAnnotation *annotation = [[notification userInfo] objectForKey:SKPDFViewAnnotationKey];
    PDFPage *page = [[notification userInfo] objectForKey:SKPDFViewPageKey];
    
    if ([annotation isSkimNote])
        [self addNote:annotation];
    
    if (page) {
        [self updateThumbnailAtPageIndex:[page pageIndex]];
        NSEnumerator *snapshotEnum = [snapshots objectEnumerator];
        SKSnapshotWindowController *wc;
        while (wc = [snapshotEnum nextObject]) {
            if ([wc isPageVisible:page])
                [self snapshotNeedsUpdate:wc];
        }
        [secondaryPdfView setNeedsDisplayForAnnotation:annotation onPage:page];
    }
}

- (void)handleDidRemoveAnnotationNotification:(NSNotification *)notification {
    PDFAnnotation *annotation = [[notification userInfo] objectForKey:SKPDFViewAnnotationKey];
    PDFPage *page = [[notification userInfo] objectForKey:SKPDFViewPageKey];
    
    if ([annotation isSkimNote]) {
        if ([[self selectedNotes] containsObject:annotation])
            [noteOutlineView deselectAll:self];
        
        NSWindowController *wc = nil;
        NSEnumerator *wcEnum = [[[self document] windowControllers] objectEnumerator];
        
        while (wc = [wcEnum nextObject]) {
            if ([wc isKindOfClass:[SKNoteWindowController class]] && [(SKNoteWindowController *)wc note] == annotation) {
                [wc close];
                break;
            }
        }
        
        [self removeNote:annotation];
    }
    if (page) {
        [self updateThumbnailAtPageIndex:[page pageIndex]];
        NSEnumerator *snapshotEnum = [snapshots objectEnumerator];
        SKSnapshotWindowController *wc;
        while (wc = [snapshotEnum nextObject]) {
            if ([wc isPageVisible:page])
                [self snapshotNeedsUpdate:wc];
        }
        [secondaryPdfView setNeedsDisplayForAnnotation:annotation onPage:page];
    }
    [noteOutlineView reloadData];
}

- (void)handleDidMoveAnnotationNotification:(NSNotification *)notification {
    PDFPage *oldPage = [[notification userInfo] objectForKey:SKPDFViewOldPageKey];
    PDFPage *newPage = [[notification userInfo] objectForKey:SKPDFViewNewPageKey];
    
    if (oldPage || newPage) {
        if (oldPage)
            [self updateThumbnailAtPageIndex:[oldPage pageIndex]];
        if (newPage)
            [self updateThumbnailAtPageIndex:[newPage pageIndex]];
        NSEnumerator *snapshotEnum = [snapshots objectEnumerator];
        SKSnapshotWindowController *wc;
        while (wc = [snapshotEnum nextObject]) {
            if ([wc isPageVisible:oldPage] || [wc isPageVisible:newPage])
                [self snapshotNeedsUpdate:wc];
        }
        [secondaryPdfView setNeedsDisplay:YES];
    }
    
    [noteArrayController rearrangeObjects];
    [noteOutlineView reloadData];
}

- (void)handleDoubleClickedAnnotationNotification:(NSNotification *)notification {
    PDFAnnotation *annotation = [[notification userInfo] objectForKey:SKPDFViewAnnotationKey];
    
    [self showNote:annotation];
}

- (void)handleReadingBarDidChangeNotification:(NSNotification *)notification {
    NSDictionary *userInfo = [notification userInfo];
    PDFPage *oldPage = [userInfo objectForKey:SKPDFViewOldPageKey];
    PDFPage *newPage = [userInfo objectForKey:SKPDFViewNewPageKey];
    if (oldPage)
        [self updateThumbnailAtPageIndex:[oldPage pageIndex]];
    if (newPage && [newPage isEqual:oldPage] == NO)
        [self updateThumbnailAtPageIndex:[newPage pageIndex]];
}

#pragma mark Observer registration

- (void)registerForNotifications {
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    // Application
    [nc addObserver:self selector:@selector(handleApplicationWillTerminateNotification:) 
                             name:SKApplicationStartsTerminatingNotification object:NSApp];
    [nc addObserver:self selector:@selector(handleApplicationDidResignActiveNotification:) 
                             name:NSApplicationDidResignActiveNotification object:NSApp];
    [nc addObserver:self selector:@selector(handleApplicationWillBecomeActiveNotification:) 
                             name:NSApplicationWillBecomeActiveNotification object:NSApp];
    // Document
    [nc addObserver:self selector:@selector(handleDocumentWillSaveNotification:) 
                             name:SKPDFDocumentWillSaveNotification object:[self document]];
    // PDFView
    [nc addObserver:self selector:@selector(handlePageChangedNotification:) 
                             name:PDFViewPageChangedNotification object:pdfView];
    [nc addObserver:self selector:@selector(handleScaleChangedNotification:) 
                             name:PDFViewScaleChangedNotification object:pdfView];
    [nc addObserver:self selector:@selector(handleToolModeChangedNotification:) 
                             name:SKPDFViewToolModeChangedNotification object:pdfView];
    [nc addObserver:self selector:@selector(handleAnnotationModeChangedNotification:) 
                             name:SKPDFViewAnnotationModeChangedNotification object:pdfView];
    [nc addObserver:self selector:@selector(handleSelectionChangedNotification:) 
                             name:SKPDFViewSelectionChangedNotification object:pdfView];
    [nc addObserver:self selector:@selector(handleMagnificationChangedNotification:) 
                             name:SKPDFViewMagnificationChangedNotification object:pdfView];
    [nc addObserver:self selector:@selector(handleDisplayModeChangedNotification:) 
                             name:SKPDFViewDisplayModeChangedNotification object:pdfView];
    [nc addObserver:self selector:@selector(handleDisplayBoxChangedNotification:) 
                             name:SKPDFViewDisplayBoxChangedNotification object:pdfView];
    [nc addObserver:self selector:@selector(handleChangedHistoryNotification:) 
                             name:PDFViewChangedHistoryNotification object:pdfView];
    [nc addObserver:self selector:@selector(handleDidChangeActiveAnnotationNotification:) 
                             name:SKPDFViewActiveAnnotationDidChangeNotification object:pdfView];
    [nc addObserver:self selector:@selector(handleDidAddAnnotationNotification:) 
                             name:SKPDFViewDidAddAnnotationNotification object:pdfView];
    [nc addObserver:self selector:@selector(handleDidRemoveAnnotationNotification:) 
                             name:SKPDFViewDidRemoveAnnotationNotification object:pdfView];
    [nc addObserver:self selector:@selector(handleDidMoveAnnotationNotification:) 
                             name:SKPDFViewDidMoveAnnotationNotification object:pdfView];
    [nc addObserver:self selector:@selector(handleDoubleClickedAnnotationNotification:) 
                             name:SKPDFViewAnnotationDoubleClickedNotification object:pdfView];
    [nc addObserver:self selector:@selector(handleReadingBarDidChangeNotification:) 
                             name:SKPDFViewReadingBarDidChangeNotification object:pdfView];
    [nc addObserver:self selector:@selector(observeUndoManagerCheckpoint:) 
                             name:NSUndoManagerCheckpointNotification object:[[self document] undoManager]];
}

@end
