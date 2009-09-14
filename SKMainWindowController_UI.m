//
//  SKMainWindowController_UI.m
//  Skim
//
//  Created by Christiaan Hofman on 5/2/08.
/*
 This software is Copyright (c) 2008-2009
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
#import "NSWindowController_SKExtensions.h"
#import "SKSideWindow.h"
#import "SKProgressController.h"
#import "SKAnnotationTypeImageCell.h"
#import "SKStringConstants.h"
#import <SkimNotes/SkimNotes.h>
#import "PDFAnnotation_SKExtensions.h"
#import "SKNPDFAnnotationNote_SKExtensions.h"
#import "SKNoteText.h"
#import "SKPDFToolTipWindow.h"
#import "SKMainDocument.h"
#import "PDFPage_SKExtensions.h"
#import "SKGroupedSearchResult.h"
#import "PDFSelection_SKExtensions.h"
#import "NSString_SKExtensions.h"
#import "SKApplication.h"
#import "NSMenu_SKExtensions.h"
#import "SKLineInspector.h"
#import "PDFOutline_SKExtensions.h"
#import "SKDocumentController.h"

#define NOTES_KEY       @"notes"
#define SNAPSHOTS_KEY   @"snapshots"

#define PAGE_COLUMNID   @"page"
#define LABEL_COLUMNID  @"label"
#define NOTE_COLUMNID   @"note"
#define TYPE_COLUMNID   @"type"
#define IMAGE_COLUMNID  @"image"

#define SKLeftSidePaneWidthKey  @"SKLeftSidePaneWidth"
#define SKRightSidePaneWidthKey @"SKRightSidePaneWidth"

static NSString *noteToolImageNames[] = {@"ToolbarTextNoteMenu", @"ToolbarAnchoredNoteMenu", @"ToolbarCircleNoteMenu", @"ToolbarSquareNoteMenu", @"ToolbarHighlightNoteMenu", @"ToolbarUnderlineNoteMenu", @"ToolbarStrikeOutNoteMenu", @"ToolbarLineNoteMenu", @"ToolbarInkNoteMenu"};

#define SKDisableTableToolTipsKey @"SKDisableTableToolTips"

@interface SKMainWindowController (SKPrivateMain)

- (void)selectSelectedNote:(id)sender;
- (void)goToSelectedOutlineItem:(id)sender;

- (void)updatePageNumber;
- (void)updatePageLabel;

- (void)updateNoteFilterPredicate;

- (void)updateFindResultHighlights:(BOOL)scroll;

- (void)observeUndoManagerCheckpoint:(NSNotification *)notification;

@end

@interface SKMainWindowController (UIPrivate)
- (void)changeColorFill:(id)sender;
- (void)changeColorText:(id)sender;
@end

#pragma mark -

@implementation SKMainWindowController (UI)

#pragma mark UI updating

- (void)updateFontPanel {
    PDFAnnotation *annotation = [pdfView activeAnnotation];
    
    if ([[self window] isMainWindow]) {
        if ([annotation isSkimNote]) {
            if ([annotation respondsToSelector:@selector(font)]) {
                mwcFlags.updatingFont = 1;
                [[NSFontManager sharedFontManager] setSelectedFont:[(PDFAnnotationFreeText *)annotation font] isMultiple:NO];
                mwcFlags.updatingFont = 0;
            }
            if ([annotation respondsToSelector:@selector(fontColor)]) {
                mwcFlags.updatingFontAttributes = 1;
                [[NSFontManager sharedFontManager] setSelectedAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[(PDFAnnotationFreeText *)annotation fontColor], NSForegroundColorAttributeName, nil] isMultiple:NO];
                mwcFlags.updatingFontAttributes = 0;
            }
        }
    }
}

- (void)updateColorPanel {
    PDFAnnotation *annotation = [pdfView activeAnnotation];
    NSColor *color = nil;
    NSView *accessoryView = nil;
    
    if ([[self window] isMainWindow]) {
        if ([annotation isSkimNote]) {
            if ([annotation respondsToSelector:@selector(setInteriorColor:)]) {
                if (colorAccessoryView == nil) {
                    colorAccessoryView = [[NSButton alloc] init];
                    [colorAccessoryView setButtonType:NSSwitchButton];
                    [colorAccessoryView setTitle:NSLocalizedString(@"Fill color", @"Button title")];
                    [[colorAccessoryView cell] setControlSize:NSSmallControlSize];
                    [colorAccessoryView setTarget:self];
                    [colorAccessoryView setAction:@selector(changeColorFill:)];
                    [colorAccessoryView sizeToFit];
                }
                accessoryView = colorAccessoryView;
            } else if ([annotation respondsToSelector:@selector(setFontColor:)]) {
                if (textColorAccessoryView == nil) {
                    textColorAccessoryView = [[NSButton alloc] init];
                    [textColorAccessoryView setButtonType:NSSwitchButton];
                    [textColorAccessoryView setTitle:NSLocalizedString(@"Text color", @"Button title")];
                    [[textColorAccessoryView cell] setControlSize:NSSmallControlSize];
                    [textColorAccessoryView setTarget:self];
                    [textColorAccessoryView setAction:@selector(changeColorText:)];
                    [textColorAccessoryView sizeToFit];
                }
                accessoryView = textColorAccessoryView;
            }
            if ([annotation respondsToSelector:@selector(setInteriorColor:)] && [colorAccessoryView state] == NSOnState) {
                color = [(id)annotation interiorColor] ?: [NSColor clearColor];
            } else if ([annotation respondsToSelector:@selector(setFontColor:)] && [textColorAccessoryView state] == NSOnState) {
                color = [(id)annotation fontColor] ?: [NSColor blackColor];
            } else {
                color = [annotation color];
            }
        }
        if ([[NSColorPanel sharedColorPanel] accessoryView] != accessoryView) {
            [[NSColorPanel sharedColorPanel] setAccessoryView:nil];
            [[NSColorPanel sharedColorPanel] setAccessoryView:accessoryView];
        }
    }
    
    if (color) {
        mwcFlags.updatingColor = 1;
        [[NSColorPanel sharedColorPanel] setColor:color];
        mwcFlags.updatingColor = 0;
    }
}

- (void)changeColorFill:(id)sender{
   [self updateColorPanel];
}

- (void)changeColorText:(id)sender{
   [self updateColorPanel];
}

- (void)updateLineInspector {
    PDFAnnotation *annotation = [pdfView activeAnnotation];
    
    if ([[self window] isMainWindow] &&[annotation hasBorder]) {
        mwcFlags.updatingLine = 1;
        [[SKLineInspector sharedLineInspector] setAnnotationStyle:annotation];
        mwcFlags.updatingLine = 0;
    }
}

#pragma mark NSWindow delegate protocol

- (NSString *)windowTitleForDocumentDisplayName:(NSString *)displayName {
    if ([pdfView document])
        return [NSString stringWithFormat:NSLocalizedString(@"%@ (page %ld of %ld)", @"Window title format"), displayName, (long)[self pageNumber], (long)[[pdfView document] pageCount]];
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
        if ([[pdfView document] isFinding])
            [[pdfView document] cancelFindString];
        if ((mwcFlags.isEditingPDF || mwcFlags.isEditingTable) && [self commitEditing] == NO)
            [self discardEditing];
        
        [fullScreenWindow orderOut:nil];
        [blankingWindows makeObjectsPerformSelector:@selector(orderOut:) withObject:nil];
        
        [ownerController setContent:nil];
    }
}

- (void)windowDidChangeScreen:(NSNotification *)notification {
    if ([[notification object] isEqual:[self window]]) {
        NSScreen *screen = [fullScreenWindow screen];
        [fullScreenWindow setFrame:[screen frame] display:NO];
        if ([self isFullScreen]) {
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
        }
        [pdfView layoutDocumentView];
        [pdfView setNeedsDisplay:YES];
    }
}

- (void)windowDidMove:(NSNotification *)notification {
    if ([[notification object] isEqual:[self window]] && [[notification object] isEqual:fullScreenWindow]) {
        NSScreen *screen = [fullScreenWindow screen];
        NSRect screenFrame = [screen frame];
        if (NSEqualRects(screenFrame, [fullScreenWindow frame]) == NO) {
            [fullScreenWindow setFrame:screenFrame display:NO];
            if ([self isFullScreen]) {
                [leftSideWindow orderOut:self];
                [leftSideWindow moveToScreen:screen];
                [leftSideWindow collapse];
                [leftSideWindow orderFront:self];
                [rightSideWindow orderOut:self];
                [leftSideWindow moveToScreen:screen];
                [rightSideWindow collapse];
                [rightSideWindow orderFront:self];
            }
            [pdfView layoutDocumentView];
            [pdfView setNeedsDisplay:YES];
        }
    }
}

#pragma mark NSTableView datasource protocol

// AppKit bug: need a dummy NSTableDataSource implementation, otherwise some NSTableView delegate methods are ignored
- (NSInteger)numberOfRowsInTableView:(NSTableView *)tv { return 0; }

- (id)tableView:(NSTableView *)tv objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row { return nil; }

- (BOOL)tableView:(NSTableView *)tv writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard *)pboard {
    if ([tv isEqual:thumbnailTableView]) {
        NSUInteger idx = [rowIndexes firstIndex];
        if (idx != NSNotFound) {
            PDFPage *page = [[pdfView document] pageAtIndex:idx];
            NSData *pdfData = [page dataRepresentation];
            NSData *tiffData = [page TIFFDataForRect:[page boundsForBox:[pdfView displayBox]]];
            NSString *fileName = [NSString stringWithFormat:NSLocalizedString(@"%@ %C Page %@", @""), ([[[self document] displayName] stringByDeletingPathExtension] ?: @"PDF"), '-', [page displayLabel]];
            [pboard declareTypes:[NSArray arrayWithObjects:NSPDFPboardType, NSTIFFPboardType, NSFilesPromisePboardType, nil] owner:self];
            [pboard setData:pdfData forType:NSPDFPboardType];
            [pboard setData:tiffData forType:NSTIFFPboardType];
            [pboard setPropertyList:[NSArray arrayWithObject:fileName] forType:NSFilesPromisePboardType];
            return YES;
        }
    } else if ([tv isEqual:snapshotTableView]) {
        NSUInteger idx = [rowIndexes firstIndex];
        if (idx != NSNotFound) {
            SKSnapshotWindowController *snapshot = [self objectInSnapshotsAtIndex:idx];
            PDFPage *page = [[pdfView document] pageAtIndex:[snapshot pageIndex]];
            NSString *fileName = [NSString stringWithFormat:NSLocalizedString(@"%@ %C Page %@", @""), ([[[self document] displayName] stringByDeletingPathExtension] ?: @"PDF"), '-', [page displayLabel]];
            [pboard declareTypes:[NSArray arrayWithObjects:NSTIFFPboardType, NSFilesPromisePboardType, nil] owner:self];
            [pboard setData:[[snapshot thumbnailWithSize:0.0] TIFFRepresentation] forType:NSTIFFPboardType];
            [pboard setPropertyList:[NSArray arrayWithObject:fileName] forType:NSFilesPromisePboardType];
            return YES;
        }
    }
    return NO;
}

- (NSArray *)tableView:(NSTableView *)tv namesOfPromisedFilesDroppedAtDestination:(NSURL *)dropDestination forDraggedRowsWithIndexes:(NSIndexSet *)rowIndexes {
    if ([tv isEqual:thumbnailTableView]) {
        NSUInteger idx = [rowIndexes firstIndex];
        if (idx != NSNotFound) {
            PDFPage *page = [[pdfView document] pageAtIndex:idx];
            NSString *fileName = [NSString stringWithFormat:NSLocalizedString(@"%@ %C Page %@", @""), ([[[self document] displayName] stringByDeletingPathExtension] ?: @"PDF"), '-', [page displayLabel]];
            NSString *basePath = [[dropDestination path] stringByAppendingPathComponent:fileName];
            NSString *path = [basePath stringByAppendingPathExtension:@"pdf"];
            NSFileManager *fm = [NSFileManager defaultManager];
            NSInteger i = 0;
            
            while ([fm fileExistsAtPath:path])
                path = [[basePath stringByAppendingFormat:@" - %ld", (long)++i] stringByAppendingPathExtension:@"pdf"];
            if ([[page dataRepresentation] writeToFile:path atomically:YES])
                return [NSArray arrayWithObjects:[path lastPathComponent], nil];
        }
    } else if ([tv isEqual:snapshotTableView]) {
        NSUInteger idx = [rowIndexes firstIndex];
        if (idx != NSNotFound) {
            SKSnapshotWindowController *snapshot = [self objectInSnapshotsAtIndex:idx];
            PDFPage *page = [[pdfView document] pageAtIndex:[snapshot pageIndex]];
            NSString *fileName = [NSString stringWithFormat:NSLocalizedString(@"%@ %C Page %@", @""), ([[[self document] displayName] stringByDeletingPathExtension] ?: @"PDF"), '-', [page displayLabel]];
            NSString *basePath = [[dropDestination path] stringByAppendingPathComponent:fileName];
            NSString *path = [basePath stringByAppendingPathExtension:@"tiff"];
            NSFileManager *fm = [NSFileManager defaultManager];
            NSInteger i = 0;
            
            while ([fm fileExistsAtPath:path])
                path = [[basePath stringByAppendingFormat:@" - %ld", (long)++i] stringByAppendingPathExtension:@"tiff"];
            if ([[[snapshot thumbnailWithSize:0.0] TIFFRepresentation] writeToFile:path atomically:YES])
                return [NSArray arrayWithObjects:[path lastPathComponent], nil];
        }
    }
    return nil;
}

#pragma mark NSTableView delegate protocol

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification {
    if ([[aNotification object] isEqual:findTableView] || [[aNotification object] isEqual:groupedFindTableView]) {
        [self updateFindResultHighlights:YES];
        
        if ([self isPresentation] && [[NSUserDefaults standardUserDefaults] boolForKey:SKAutoHidePresentationContentsKey])
            [self hideLeftSideWindow];
    } else if ([[aNotification object] isEqual:thumbnailTableView]) {
        if (mwcFlags.updatingThumbnailSelection == 0) {
            NSInteger row = [thumbnailTableView selectedRow];
            if (row != -1)
                [pdfView goToPage:[[pdfView document] pageAtIndex:row]];
            
            if ([self isPresentation] && [[NSUserDefaults standardUserDefaults] boolForKey:SKAutoHidePresentationContentsKey])
                [self hideLeftSideWindow];
        }
    } else if ([[aNotification object] isEqual:snapshotTableView]) {
        NSInteger row = [snapshotTableView selectedRow];
        if (row != -1) {
            SKSnapshotWindowController *controller = [[snapshotArrayController arrangedObjects] objectAtIndex:row];
            if ([[controller window] isVisible])
                [[controller window] orderFront:self];
        }
    }
}

- (BOOL)tableView:(NSTableView *)tv commandSelectRow:(NSInteger)row {
    if ([tv isEqual:thumbnailTableView]) {
        NSRect rect = [[[pdfView document] pageAtIndex:row] boundsForBox:kPDFDisplayBoxCropBox];
        
        rect.origin.y = NSMidY(rect) - 100.0;
        rect.size.height = 200.0;
        [self showSnapshotAtPageNumber:row forRect:rect scaleFactor:[pdfView scaleFactor] autoFits:NO];
        return YES;
    }
    return NO;
}

- (CGFloat)tableView:(NSTableView *)tv heightOfRow:(NSInteger)row {
    if ([tv isEqual:thumbnailTableView]) {
        NSSize thumbSize = [[thumbnails objectAtIndex:row] size];
        NSSize cellSize = NSMakeSize([[tv tableColumnWithIdentifier:IMAGE_COLUMNID] width], 
                                     SKMin(thumbSize.height, roundedThumbnailSize));
        if (thumbSize.height < [tv rowHeight])
            return [tv rowHeight];
        else if (thumbSize.width / thumbSize.height < cellSize.width / cellSize.height)
            return cellSize.height;
        else
            return SKMax([tv rowHeight], SKMin(cellSize.width, thumbSize.width) * thumbSize.height / thumbSize.width);
    } else if ([tv isEqual:snapshotTableView]) {
        NSSize thumbSize = [[[[snapshotArrayController arrangedObjects] objectAtIndex:row] thumbnail] size];
        NSSize cellSize = NSMakeSize([[tv tableColumnWithIdentifier:IMAGE_COLUMNID] width], 
                                     SKMin(thumbSize.height, roundedSnapshotThumbnailSize));
        if (thumbSize.height < [tv rowHeight])
            return [tv rowHeight];
        else if (thumbSize.width / thumbSize.height < cellSize.width / cellSize.height)
            return cellSize.height;
        else
            return SKMax([tv rowHeight], SKMin(cellSize.width, thumbSize.width) * thumbSize.height / thumbSize.width);
    }
    return [tv rowHeight];
}

- (void)tableView:(NSTableView *)tv deleteRowsWithIndexes:(NSIndexSet *)rowIndexes {
    if ([tv isEqual:snapshotTableView]) {
        NSArray *controllers = [[snapshotArrayController arrangedObjects] objectsAtIndexes:rowIndexes];
        [[controllers valueForKey:@"window"] makeObjectsPerformSelector:@selector(orderOut:) withObject:self];
        [[self mutableArrayValueForKey:SNAPSHOTS_KEY] removeObjectsInArray:controllers];
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
        NSUInteger idx = [rowIndexes firstIndex];
        if (idx != NSNotFound) {
            PDFPage *page = [[pdfView document] pageAtIndex:idx];
            NSData *pdfData = [page dataRepresentation];
            NSData *tiffData = [page TIFFDataForRect:[page boundsForBox:[pdfView displayBox]]];
            NSPasteboard *pboard = [NSPasteboard generalPasteboard];
            [pboard declareTypes:[NSArray arrayWithObjects:NSPDFPboardType, NSTIFFPboardType, nil] owner:nil];
            [pboard setData:pdfData forType:NSPDFPboardType];
            [pboard setData:tiffData forType:NSTIFFPboardType];
        }
    } else if ([tv isEqual:findTableView]) {
        NSMutableString *string = [NSMutableString string];
        NSUInteger idx = [rowIndexes firstIndex];
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
        NSUInteger idx = [rowIndexes firstIndex];
        while (idx != NSNotFound) {
            SKGroupedSearchResult *result = [groupedSearchResults objectAtIndex:idx];
            NSArray *matches = [result matches];
            [string appendString:@"* "];
            [string appendFormat:NSLocalizedString(@"Page %@", @""), [[result page] displayLabel]];
            [string appendString:@": "];
            [string appendFormat:NSLocalizedString(@"%ld Results", @""), (long)[matches count]];
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

- (BOOL)tableView:(NSTableView *)tv shouldTrackTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)row {
    if ([tv isEqual:findTableView]) {
        return YES;
    } else if ([tv isEqual:groupedFindTableView]) {
        return YES;
    }
    return NO;
}

- (void)tableView:(NSTableView *)tv mouseEnteredTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)row {
    if ([NSApp isActive] && [[NSUserDefaults standardUserDefaults] boolForKey:SKDisableTableToolTipsKey] == NO) { 
        if ([tv isEqual:findTableView]) {
            PDFDestination *dest = [[[findArrayController arrangedObjects] objectAtIndex:row] destination];
            [[SKPDFToolTipWindow sharedToolTipWindow] showForPDFContext:dest atPoint:NSZeroPoint];
        } else if ([tv isEqual:groupedFindTableView]) {
            PDFDestination *dest = [[[[[groupedFindArrayController arrangedObjects] objectAtIndex:row] matches] objectAtIndex:0] destination];
            [[SKPDFToolTipWindow sharedToolTipWindow] showForPDFContext:dest atPoint:NSZeroPoint];
        }
    }
}

- (void)tableView:(NSTableView *)tv mouseExitedTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)row {
    if ([NSApp isActive] && [[NSUserDefaults standardUserDefaults] boolForKey:SKDisableTableToolTipsKey] == NO) { 
        if ([tv isEqual:findTableView]) {
            [[SKPDFToolTipWindow sharedToolTipWindow] fadeOut];
        } else if ([tv isEqual:groupedFindTableView]) {
            [[SKPDFToolTipWindow sharedToolTipWindow] fadeOut];
        }
    }
}

- (void)copyPage:(id)sender {
    [self tableView:thumbnailTableView copyRowsWithIndexes:[sender representedObject]];
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

- (NSMenu *)tableView:(NSTableView *)tv menuForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    NSMenu *menu = nil;
    if ([tv isEqual:thumbnailTableView]) {
        menu = [[[NSMenu allocWithZone:[NSMenu menuZone]] init] autorelease];
        NSMenuItem *menuItem = [menu addItemWithTitle:NSLocalizedString(@"Copy", @"Menu item title") action:@selector(copyPage:) target:self];
        [menuItem setRepresentedObject:[NSIndexSet indexSetWithIndex:row]];
    } else if ([tv isEqual:snapshotTableView]) {
        [snapshotTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
        
        menu = [[[NSMenu allocWithZone:[NSMenu menuZone]] init] autorelease];
        SKSnapshotWindowController *controller = [[snapshotArrayController arrangedObjects] objectAtIndex:row];
        NSMenuItem *menuItem = [menu addItemWithTitle:NSLocalizedString(@"Delete", @"Menu item title") action:@selector(delete:) target:snapshotTableView];
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

- (NSArray *)tableView:(NSTableView *)tv typeSelectHelperSelectionItems:(SKTypeSelectHelper *)typeSelectHelper {
    if ([tv isEqual:thumbnailTableView]) {
        return pageLabels;
    }
    return nil;
}

- (void)tableView:(NSTableView *)tv typeSelectHelper:(SKTypeSelectHelper *)typeSelectHelper didFailToFindMatchForSearchString:(NSString *)searchString {
    if ([tv isEqual:thumbnailTableView]) {
        [statusBar setLeftStringValue:[NSString stringWithFormat:NSLocalizedString(@"No match: \"%@\"", @"Status message"), searchString]];
    }
}

- (void)tableView:(NSTableView *)tv typeSelectHelper:(SKTypeSelectHelper *)typeSelectHelper updateSearchString:(NSString *)searchString {
    if ([tv isEqual:thumbnailTableView]) {
        if (searchString)
            [statusBar setLeftStringValue:[NSString stringWithFormat:NSLocalizedString(@"Go to page: %@", @"Status message"), searchString]];
        else
            [self updateLeftStatus];
    }
}

#pragma mark NSOutlineView datasource protocol

- (NSInteger)outlineView:(NSOutlineView *)ov numberOfChildrenOfItem:(id)item{
    if ([ov isEqual:outlineView]) {
        if (item == nil && [[pdfView document] isLocked] == NO)
            item = [[pdfView document] outlineRoot];
        return [(PDFOutline *)item numberOfChildren];
    } else if ([ov isEqual:noteOutlineView]) {
        if (item == nil)
            return [[noteArrayController arrangedObjects] count];
        else
            return [[item texts] count];
    }
    return 0;
}

- (id)outlineView:(NSOutlineView *)ov child:(NSInteger)anIndex ofItem:(id)item{
    if ([ov isEqual:outlineView]) {
        if (item == nil && [[pdfView document] isLocked] == NO)
            item = [[pdfView document] outlineRoot];
        id obj = [(PDFOutline *)item childAtIndex:anIndex];
        return obj;
    } else if ([ov isEqual:noteOutlineView]) {
        if (item == nil)
            return [[noteArrayController arrangedObjects] objectAtIndex:anIndex];
        else
            return [[item texts] lastObject];
    }
    return nil;
}

- (BOOL)outlineView:(NSOutlineView *)ov isItemExpandable:(id)item{
    if ([ov isEqual:outlineView]) {
        if (item == nil && [[pdfView document] isLocked] == NO)
            item = [[pdfView document] outlineRoot];
        return ([(PDFOutline *)item numberOfChildren] > 0);
    } else if ([ov isEqual:noteOutlineView]) {
        return [[item texts] count] > 0;
    }
    return NO;
}

- (id)outlineView:(NSOutlineView *)ov objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item{
    if ([ov isEqual:outlineView]) {
        NSString *tcID = [tableColumn identifier];
        if([tcID isEqualToString:LABEL_COLUMNID]) {
            return [(PDFOutline *)item label];
        } else if([tcID isEqualToString:PAGE_COLUMNID]) {
            return [(PDFOutline *)item pageLabel];
        }
    } else if ([ov isEqual:noteOutlineView]) {
        NSString *tcID = [tableColumn  identifier];
        if ([tcID isEqualToString:NOTE_COLUMNID])
            return [item type] ? (id)[item string] : (id)[item text];
        else if([tcID isEqualToString:TYPE_COLUMNID])
            return [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:item == [pdfView activeAnnotation]], SKAnnotationTypeImageCellActiveKey, [item type], SKAnnotationTypeImageCellTypeKey, nil];
        else if([tcID isEqualToString:PAGE_COLUMNID])
            return [[item page] displayLabel];
    }
    return nil;
}

- (void)outlineView:(NSOutlineView *)ov setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn byItem:(id)item{
    if ([ov isEqual:noteOutlineView]) {
        if ([[tableColumn identifier] isEqualToString:NOTE_COLUMNID]) {
            if ([item type] && [object isEqualToString:[item string]] == NO)
                [item setString:object];
        }
    }
}

#pragma mark NSOutlineView delegate protocol

- (BOOL)outlineView:(NSOutlineView *)ov shouldEditTableColumn:(NSTableColumn *)tableColumn item:(id)item{
    if ([ov isEqual:noteOutlineView]) {
        if ([[tableColumn identifier] isEqualToString:NOTE_COLUMNID]) {
            if ([item type] == nil) {
                if ([pdfView hideNotes] == NO) {
                    PDFAnnotation *annotation = [(SKNoteText *)item note];
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
        [noteArrayController setSortDescriptors:sortDescriptors];
        [ov setIndicatorImage:[NSImage imageNamed:ascending ? @"NSAscendingSortIndicator" : @"NSDescendingSortIndicator"]
                inTableColumn:tableColumn];
        [ov reloadData];
    }
}

- (void)outlineViewSelectionDidChange:(NSNotification *)notification{
	// Get the destination associated with the search result list. Tell the PDFView to go there.
	if ([[notification object] isEqual:outlineView] && (mwcFlags.updatingOutlineSelection == 0)){
        mwcFlags.updatingOutlineSelection = 1;
        [self goToSelectedOutlineItem:nil];
        mwcFlags.updatingOutlineSelection = 0;
        if ([self isPresentation] && [[NSUserDefaults standardUserDefaults] boolForKey:SKAutoHidePresentationContentsKey])
            [self hideLeftSideWindow];
    }
}

- (NSString *)outlineView:(NSOutlineView *)ov toolTipForCell:(NSCell *)cell rect:(NSRectPointer)rect tableColumn:(NSTableColumn *)tableColumn item:(id)item mouseLocation:(NSPoint)mouseLocation {
    if ([ov isEqual:noteOutlineView] && [[tableColumn identifier] isEqualToString:NOTE_COLUMNID]) {
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

- (CGFloat)outlineView:(NSOutlineView *)ov heightOfRowByItem:(id)item {
    if ([ov isEqual:noteOutlineView]) {
        CGFloat rowHeight = 0.0;
        if (CFDictionaryContainsKey(rowHeights, (const void *)item))
            rowHeight = *(CGFloat *)CFDictionaryGetValue(rowHeights, (const void *)item);
        else if ([item type] == nil)
            rowHeight = 85.0;
        return rowHeight > 0.0 ? rowHeight : [ov rowHeight] + 2.0;
    }
    return [ov rowHeight];
}

- (BOOL)outlineView:(NSOutlineView *)ov canResizeRowByItem:(id)item {
    if ([ov isEqual:noteOutlineView]) {
        return YES;
    }
    return NO;
}

- (void)outlineView:(NSOutlineView *)ov setHeightOfRow:(CGFloat)newHeight byItem:(id)item {
    CFDictionarySetValue(rowHeights, (const void *)item, &newHeight);
}

- (NSArray *)noteItems:(NSArray *)items {
    NSEnumerator *itemEnum = [items objectEnumerator];
    PDFAnnotation *item;
    NSMutableArray *noteItems = [NSMutableArray array];
    
    while (item = [itemEnum nextObject]) {
        if ([item type] == nil) {
            item = [(SKNoteText *)item note];
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
            [pboard setData:[attrString RTFFromRange:NSMakeRange(0, [attrString length]) documentAttributes:nil] forType:NSRTFPboardType];
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
        [self selectSelectedNote:ov];
    }
}

- (NSArray *)outlineViewHighlightedRows:(NSOutlineView *)ov {
    if ([ov isEqual:outlineView]) {
        NSMutableArray *array = [NSMutableArray array];
        NSEnumerator *rowEnum = [lastViewedPages objectEnumerator];
        NSNumber *rowNumber;
        
        while (rowNumber = [rowEnum nextObject]) {
            NSInteger row = [self outlineRowForPageIndex:[rowNumber integerValue]];
            if (row != -1)
                [array addObject:[NSNumber numberWithInteger:row]];
        }
        
        return array;
    }
    return nil;
}

- (BOOL)outlineView:(NSOutlineView *)ov shouldTrackTableColumn:(NSTableColumn *)aTableColumn item:(id)item {
    return YES;
}

- (void)outlineView:(NSOutlineView *)ov mouseEnteredTableColumn:(NSTableColumn *)aTableColumn item:(id)item {
    if ([ov isEqual:outlineView] && [NSApp isActive] && [[NSUserDefaults standardUserDefaults] boolForKey:SKDisableTableToolTipsKey] == NO) { 
        [[SKPDFToolTipWindow sharedToolTipWindow] showForPDFContext:[item destination] atPoint:NSZeroPoint];
    }
}

- (void)outlineView:(NSOutlineView *)ov mouseExitedTableColumn:(NSTableColumn *)aTableColumn item:(id)item {
    if ([ov isEqual:outlineView] && [NSApp isActive] && [[NSUserDefaults standardUserDefaults] boolForKey:SKDisableTableToolTipsKey] == NO) { 
        [[SKPDFToolTipWindow sharedToolTipWindow] fadeOut];
    }
}

- (void)deleteNotes:(id)sender {
    [self outlineView:noteOutlineView deleteItems:[sender representedObject]];
}

- (void)copyNotes:(id)sender {
    [self outlineView:noteOutlineView copyItems:[sender representedObject]];
}

- (void)editNoteFromTable:(id)sender {
    PDFAnnotation *annotation = [sender representedObject];
    NSInteger row = [noteOutlineView rowForItem:annotation];
    [noteOutlineView selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
    [noteOutlineView editColumn:0 row:row withEvent:nil select:YES];
}

- (void)deselectNote:(id)sender {
    [pdfView setActiveAnnotation:nil];
}

- (void)selectNote:(id)sender {
    PDFAnnotation *annotation = [sender representedObject];
    [pdfView scrollAnnotationToVisible:annotation];
    [pdfView setActiveAnnotation:annotation];
}

- (void)revealNote:(id)sender {
    PDFAnnotation *annotation = [sender representedObject];
    [pdfView scrollAnnotationToVisible:annotation];
}

- (void)autoSizeNoteRows:(id)sender {
    CGFloat rowHeight = [noteOutlineView rowHeight];
    NSTableColumn *tableColumn = [noteOutlineView tableColumnWithIdentifier:NOTE_COLUMNID];
    id cell = [tableColumn dataCell];
    CGFloat indentation = [noteOutlineView indentationPerLevel];
    CGFloat width = NSWidth([cell drawingRectForBounds:NSMakeRect(0.0, 0.0, [tableColumn width] - indentation, rowHeight)]);
    NSSize size = NSMakeSize(width, CGFLOAT_MAX);
    NSSize smallSize = NSMakeSize(width - indentation, CGFLOAT_MAX);
    
    NSArray *items = [sender representedObject];
    
    if (items == nil) {
        items = [NSMutableArray array];
        [(NSMutableArray *)items addObjectsFromArray:[self notes]];
        [(NSMutableArray *)items addObjectsFromArray:[[self notes] valueForKeyPath:@"@unionOfArrays.texts"]];
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
        NSUInteger row = [rowIndexes firstIndex];
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
        if ([pdfView hideNotes] == NO && [items count] == 1) {
            PDFAnnotation *annotation = [[self noteItems:items] lastObject];
            if ([annotation isEditable]) {
                if ([[items lastObject] type]) {
                    menuItem = [menu addItemWithTitle:NSLocalizedString(@"Edit", @"Menu item title") action:@selector(editNoteFromTable:) target:self];
                    [menuItem setRepresentedObject:annotation];
                    menuItem = [menu addItemWithTitle:[NSLocalizedString(@"Edit", @"Menu item title") stringByAppendingEllipsis] action:@selector(editThisAnnotation:) target:pdfView];
                    [menuItem setKeyEquivalentModifierMask:NSAlternateKeyMask];
                    [menuItem setAlternate:YES];
                } else {
                    menuItem = [menu addItemWithTitle:NSLocalizedString(@"Edit", @"Menu item title") action:@selector(editThisAnnotation:) target:pdfView];
                }
                [menuItem setRepresentedObject:annotation];
            }
            if ([pdfView activeAnnotation] == annotation)
                menuItem = [menu addItemWithTitle:NSLocalizedString(@"Deselect", @"Menu item title") action:@selector(deselectNote:) target:self];
            else
                menuItem = [menu addItemWithTitle:NSLocalizedString(@"Select", @"Menu item title") action:@selector(selectNote:) target:self];
            [menuItem setRepresentedObject:annotation];
            menuItem = [menu addItemWithTitle:NSLocalizedString(@"Show", @"Menu item title") action:@selector(revealNote:) target:self];
            [menuItem setRepresentedObject:annotation];
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

- (NSArray *)outlineView:(NSOutlineView *)ov typeSelectHelperSelectionItems:(SKTypeSelectHelper *)typeSelectHelper {
    if ([ov isEqual:noteOutlineView]) {
        NSInteger i, count = [noteOutlineView numberOfRows];
        NSMutableArray *texts = [NSMutableArray arrayWithCapacity:count];
        for (i = 0; i < count; i++) {
            id item = [noteOutlineView itemAtRow:i];
            NSString *string = [item string];
            [texts addObject:string ?: @""];
        }
        return texts;
    } else if ([ov isEqual:outlineView]) {
        NSInteger i, count = [outlineView numberOfRows];
        NSMutableArray *array = [NSMutableArray arrayWithCapacity:count];
        for (i = 0; i < count; i++) 
            [array addObject:[[(PDFOutline *)[outlineView itemAtRow:i] label] lossyASCIIString]];
        return array;
    }
    return nil;
}

- (NSWindow *)outlineViewWindowForSheet:(NSOutlineView *)anOutlineView {
    return [self window];
}

- (void)outlineView:(NSOutlineView *)ov typeSelectHelper:(SKTypeSelectHelper *)typeSelectHelper didFailToFindMatchForSearchString:(NSString *)searchString {
    if ([ov isEqual:noteOutlineView]) {
        [statusBar setRightStringValue:[NSString stringWithFormat:NSLocalizedString(@"No match: \"%@\"", @"Status message"), searchString]];
    } else if ([ov isEqual:outlineView]) {
        [statusBar setLeftStringValue:[NSString stringWithFormat:NSLocalizedString(@"No match: \"%@\"", @"Status message"), searchString]];
    }
}

- (void)outlineView:(NSOutlineView *)ov typeSelectHelper:(SKTypeSelectHelper *)typeSelectHelper updateSearchString:(NSString *)searchString {
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

#pragma mark NSControl delegate protocol

- (void)controlTextDidBeginEditing:(NSNotification *)note {
    if ([[note object] isEqual:noteOutlineView]) {
        if (mwcFlags.isEditingTable == NO && mwcFlags.isEditingPDF == NO)
            [[self document] objectDidBeginEditing:self];
        mwcFlags.isEditingTable = YES;
    }
}

- (void)controlTextDidEndEditing:(NSNotification *)note {
    if ([[note object] isEqual:noteOutlineView]) {
        if (mwcFlags.isEditingTable && mwcFlags.isEditingPDF == NO)
            [[self document] objectDidEndEditing:self];
        mwcFlags.isEditingTable = NO;
    }
}

- (void)setDocument:(NSDocument *)document {
    if ([self document] && document == nil && (mwcFlags.isEditingPDF || mwcFlags.isEditingTable)) {
        if ([self commitEditing] == NO)
            [self discardEditing];
        if (mwcFlags.isEditingPDF || mwcFlags.isEditingTable)
            [[self document] objectDidEndEditing:self];
        mwcFlags.isEditingPDF = mwcFlags.isEditingTable = NO;
    }
    [super setDocument:document];
}

#pragma mark NSEditor protocol

- (void)discardEditing {
    [noteOutlineView abortEditing];
    [pdfView discardEditing];
}

- (BOOL)commitEditing {
    if ([pdfView isEditing])
        return [pdfView commitEditing];
    if ([noteOutlineView editedRow] != -1)
        return [[noteOutlineView window] makeFirstResponder:noteOutlineView];
    return YES;
}

- (void)commitEditingWithDelegate:(id)delegate didCommitSelector:(SEL)didCommitSelector contextInfo:(void *)contextInfo {
    BOOL didCommit = [self commitEditing];
    if (delegate && didCommitSelector) {
        // - (void)editor:(id)editor didCommit:(BOOL)didCommit contextInfo:(void *)contextInfo
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[delegate methodSignatureForSelector:didCommitSelector]];
        [invocation setTarget:delegate];
        [invocation setSelector:didCommitSelector];
        [invocation setArgument:&self atIndex:2];
        [invocation setArgument:&didCommit atIndex:3];
        [invocation setArgument:&contextInfo atIndex:4];
        [invocation invoke];
    }
}

#pragma mark SKPDFView delegate protocol

- (void)PDFView:(PDFView *)sender editAnnotation:(PDFAnnotation *)annotation {
    [self showNote:annotation];
}

- (void)PDFViewDidBeginEditing:(PDFView *)sender {
    if (mwcFlags.isEditingPDF == NO && mwcFlags.isEditingTable == NO)
        [[self document] objectDidBeginEditing:self];
    mwcFlags.isEditingPDF = YES;
}

- (void)PDFViewDidEndEditing:(PDFView *)sender {
    if (mwcFlags.isEditingPDF && mwcFlags.isEditingTable == NO)
        [[self document] objectDidEndEditing:self];
    mwcFlags.isEditingPDF = NO;
}

#pragma mark SKSplitView delegate protocol

- (void)splitView:(SKSplitView *)sender doubleClickedDividerAt:(NSInteger)offset{
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
                lastSecondaryPdfViewPaneHeight = SKFloor(0.5 * NSHeight(primaryFrame));
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
        
        if (mwcFlags.usesDrawers == 0) {
            NSView *leftView = [[sender subviews] objectAtIndex:0];
            NSView *mainView = [[sender subviews] objectAtIndex:1]; // pdfView
            NSView *rightView = [[sender subviews] objectAtIndex:2];
            NSRect leftFrame = [leftView frame];
            NSRect mainFrame = [mainView frame];
            NSRect rightFrame = [rightView frame];
            CGFloat contentWidth = NSWidth([sender frame]) - 2 * [sender dividerThickness];
            
            if (NSWidth(leftFrame) <= 1.0)
                leftFrame.size.width = 0.0;
            if (NSWidth(rightFrame) <= 1.0)
                rightFrame.size.width = 0.0;
            
            if (contentWidth < NSWidth(leftFrame) + NSWidth(rightFrame)) {
                CGFloat resizeFactor = contentWidth / (oldSize.width - [sender dividerThickness]);
                leftFrame.size.width = SKFloor(resizeFactor * NSWidth(leftFrame));
                rightFrame.size.width = SKFloor(resizeFactor * NSWidth(rightFrame));
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
            CGFloat contentHeight = NSHeight([sender frame]) - [sender dividerThickness];
            
            if (NSHeight(secondaryFrame) <= 1.0)
                secondaryFrame.size.height = 0.0;
            
            if (contentHeight < NSHeight(secondaryFrame))
                secondaryFrame.size.height = SKFloor(NSHeight(secondaryFrame) * contentHeight / (oldSize.height - [sender dividerThickness]));
            
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
    if (([sender isEqual:splitView] || sender == nil) && [[self window] frameAutosaveName] && mwcFlags.settingUpWindow == 0 && mwcFlags.usesDrawers == 0) {
        [[NSUserDefaults standardUserDefaults] setFloat:NSWidth([leftSideContentView frame]) forKey:SKLeftSidePaneWidthKey];
        [[NSUserDefaults standardUserDefaults] setFloat:NSWidth([rightSideContentView frame]) forKey:SKRightSidePaneWidthKey];
    }
}

#pragma mark NSDrawer delegate protocol

- (NSSize)drawerWillResizeContents:(NSDrawer *)sender toSize:(NSSize)contentSize {
    if ([[self window] frameAutosaveName] && mwcFlags.settingUpWindow == 0) {
        if ([sender isEqual:leftSideDrawer])
            [[NSUserDefaults standardUserDefaults] setFloat:contentSize.width forKey:SKLeftSidePaneWidthKey];
        else if ([sender isEqual:rightSideDrawer])
            [[NSUserDefaults standardUserDefaults] setFloat:contentSize.width forKey:SKRightSidePaneWidthKey];
    }
    return contentSize;
}

- (void)drawerDidOpen:(NSNotification *)notification {
    id sender = [notification object];
    if ([[self window] frameAutosaveName] && mwcFlags.settingUpWindow == 0) {
        if ([sender isEqual:leftSideDrawer])
            [[NSUserDefaults standardUserDefaults] setFloat:[sender contentSize].width forKey:SKLeftSidePaneWidthKey];
        else if ([sender isEqual:rightSideDrawer])
            [[NSUserDefaults standardUserDefaults] setFloat:[sender contentSize].width forKey:SKRightSidePaneWidthKey];
    }
}

- (void)drawerDidClose:(NSNotification *)notification {
    id sender = [notification object];
    if ([[self window] frameAutosaveName] && mwcFlags.settingUpWindow == 0) {
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
        return [self isPresentation] == NO && ([pdfView toolMode] == SKTextToolMode || [pdfView toolMode] == SKNoteToolMode) && [pdfView hideNotes] == NO && (isMarkup == NO || [[pdfView currentSelection] hasCharacters]);
    } else if (action == @selector(createNewTextNote:)) {
        [menuItem setState:[textNoteButton tag] == [menuItem tag] ? NSOnState : NSOffState];
        return [self isPresentation] == NO && ([pdfView toolMode] == SKTextToolMode || [pdfView toolMode] == SKNoteToolMode) && [pdfView hideNotes] == NO;
    } else if (action == @selector(createNewCircleNote:)) {
        [menuItem setState:[circleNoteButton tag] == [menuItem tag] ? NSOnState : NSOffState];
        return [self isPresentation] == NO && ([pdfView toolMode] == SKTextToolMode || [pdfView toolMode] == SKNoteToolMode) && [pdfView hideNotes] == NO;
    } else if (action == @selector(createNewMarkupNote:)) {
        [menuItem setState:[markupNoteButton tag] == [menuItem tag] ? NSOnState : NSOffState];
        return [self isPresentation] == NO && ([pdfView toolMode] == SKTextToolMode || [pdfView toolMode] == SKNoteToolMode) && [pdfView hideNotes] == NO && [[pdfView currentSelection] hasCharacters];
    } else if (action == @selector(editNote:)) {
        PDFAnnotation *annotation = [pdfView activeAnnotation];
        return [self isPresentation] == NO && [annotation isSkimNote] && ([annotation isEditable]);
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
    } else if (action == @selector(delete:) || action == @selector(copy:) || action == @selector(cut:) || action == @selector(paste:) || action == @selector(alternatePaste:) || action == @selector(pasteAsPlainText:) || action == @selector(deselectAll:) || action == @selector(changeAnnotationMode:) || action == @selector(changeToolMode:) || action == @selector(changeToolMode:)) {
        return [pdfView validateMenuItem:menuItem];
    } else if (action == @selector(doGoToNextPage:)) {
        return [pdfView canGoToNextPage];
    } else if (action == @selector(doGoToPreviousPage:) ) {
        return [pdfView canGoToPreviousPage];
    } else if (action == @selector(doGoToFirstPage:)) {
        return [pdfView canGoToFirstPage];
    } else if (action == @selector(doGoToLastPage:)) {
        return [pdfView canGoToLastPage];
    } else if (action == @selector(allGoToNextPage:)) {
        return [[NSApp valueForKeyPath:@"orderedDocuments.@min.pdfView.canGoToNextPage"] boolValue];
    } else if (action == @selector(allGoToPreviousPage:)) {
        return [[NSApp valueForKeyPath:@"orderedDocuments.@min.pdfView.canGoToPreviousPage"] boolValue];
    } else if (action == @selector(allGoToFirstPage:)) {
        return [[NSApp valueForKeyPath:@"orderedDocuments.@min.pdfView.canGoToFirstPage"] boolValue];
    } else if (action == @selector(allGoToLastPage:)) {
        return [[NSApp valueForKeyPath:@"orderedDocuments.@min.pdfView.canGoToLastPage"] boolValue];
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
        return SKAbs([pdfView scaleFactor] - 1.0 ) > 0.01;
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
        [menuItem setState:mwcFlags.leftSidePaneState == (SKLeftSidePaneState)[menuItem tag] ? (([findTableView window] || [groupedFindTableView window]) ? NSMixedState : NSOnState) : NSOffState];
        return (SKLeftSidePaneState)[menuItem tag] == SKThumbnailSidePaneState || [[pdfView document] outlineRoot];
    } else if (action == @selector(changeRightSidePaneState:)) {
        [menuItem setState:mwcFlags.rightSidePaneState == (SKRightSidePaneState)[menuItem tag] ? NSOnState : NSOffState];
        return [self isPresentation] == NO;
    } else if (action == @selector(toggleSplitPDF:)) {
        if ([secondaryPdfView window])
            [menuItem setTitle:NSLocalizedString(@"Hide Split PDF", @"Menu item title")];
        else
            [menuItem setTitle:NSLocalizedString(@"Show Split PDF", @"Menu item title")];
        return [self isPresentation] == NO;
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
    } else if (action == @selector(chooseTransition:)) {
        return [[self pdfDocument] pageCount] > 1;
    } else if (action == @selector(toggleCaseInsensitiveSearch:)) {
        [menuItem setState:mwcFlags.caseInsensitiveSearch ? NSOnState : NSOffState];
        return YES;
    } else if (action == @selector(toggleWholeWordSearch:)) {
        [menuItem setState:mwcFlags.wholeWordSearch ? NSOnState : NSOffState];
        return YES;
    } else if (action == @selector(toggleCaseInsensitiveNoteSearch:)) {
        [menuItem setState:mwcFlags.caseInsensitiveNoteSearch ? NSOnState : NSOffState];
        return YES;
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
    
    [lastViewedPages insertObject:[NSNumber numberWithUnsignedInteger:[page pageIndex]] atIndex:0];
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
    
    [self synchronizeWindowTitleWithDocumentName];
    [self updateLeftStatus];
    
    if ([self isPresentation]) {
        SKPDFView *notesPdfView = [[self presentationNotesDocument] pdfView];
        if (notesPdfView)
            [notesPdfView goToPage:[[notesPdfView document] pageAtIndex:[page pageIndex]]];
    }
}

- (void)handleScaleChangedNotification:(NSNotification *)notification {
    [scaleField setDoubleValue:[pdfView scaleFactor] * 100.0];
    
    [zoomInOutButton setEnabled:[pdfView canZoomOut] forSegment:0];
    [zoomInOutButton setEnabled:[pdfView canZoomIn] forSegment:1];
    [zoomInActualOutButton setEnabled:[pdfView canZoomOut] forSegment:0];
    [zoomInActualOutButton setEnabled:SKAbs([pdfView scaleFactor] - 1.0 ) > 0.01 forSegment:1];
    [zoomInActualOutButton setEnabled:[pdfView canZoomIn] forSegment:2];
    [zoomActualButton setEnabled:SKAbs([pdfView scaleFactor] - 1.0 ) > 0.01];
}

- (void)handleToolModeChangedNotification:(NSNotification *)notification {
    [toolModeButton selectSegmentWithTag:[pdfView toolMode]];
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
    [self updateRightStatus];
}

- (void)handleDidAddAnnotationNotification:(NSNotification *)notification {
    PDFAnnotation *annotation = [[notification userInfo] objectForKey:SKPDFViewAnnotationKey];
    PDFPage *page = [[notification userInfo] objectForKey:SKPDFViewPageKey];
    
    if ([annotation isSkimNote]) {
        mwcFlags.updatingNoteSelection = 1;
        [[self mutableArrayValueForKey:NOTES_KEY] addObject:annotation];
        [noteArrayController rearrangeObjects]; // doesn't seem to be done automatically
        mwcFlags.updatingNoteSelection = 0;
        [noteOutlineView reloadData];
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
            if ([wc isNoteWindowController] && [(SKNoteWindowController *)wc note] == annotation) {
                [wc close];
                break;
            }
        }
        
        mwcFlags.updatingNoteSelection = 1;
        [[self mutableArrayValueForKey:NOTES_KEY] removeObject:annotation];
        [noteArrayController rearrangeObjects]; // doesn't seem to be done automatically
        mwcFlags.updatingNoteSelection = 0;
        [noteOutlineView reloadData];
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

- (void)handleReadingBarDidChangeNotification:(NSNotification *)notification {
    NSDictionary *userInfo = [notification userInfo];
    PDFPage *oldPage = [userInfo objectForKey:SKPDFViewOldPageKey];
    PDFPage *newPage = [userInfo objectForKey:SKPDFViewNewPageKey];
    if (oldPage)
        [self updateThumbnailAtPageIndex:[oldPage pageIndex]];
    if (newPage && [newPage isEqual:oldPage] == NO)
        [self updateThumbnailAtPageIndex:[newPage pageIndex]];
}

- (void)handleDidRemoveDocumentNotification:(NSNotification *)notification {
    if ([[notification userInfo] objectForKey:@"document"] == presentationNotesDocument)
        [self setPresentationNotesDocument:nil];
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
    [nc addObserver:self selector:@selector(handleReadingBarDidChangeNotification:) 
                             name:SKPDFViewReadingBarDidChangeNotification object:pdfView];
    //  UndoManager
    [nc addObserver:self selector:@selector(observeUndoManagerCheckpoint:) 
                             name:NSUndoManagerCheckpointNotification object:[[self document] undoManager]];
    //  SKDocumentController
    [nc addObserver:self selector:@selector(handleDidRemoveDocumentNotification:) 
                             name:SKDocumentControllerDidRemoveDocumentNotification object:nil];
}

@end
