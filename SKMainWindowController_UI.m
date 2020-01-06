//
//  SKMainWindowController_UI.m
//  Skim
//
//  Created by Christiaan Hofman on 5/2/08.
/*
 This software is Copyright (c) 2008-2020
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
#import "SKMainWindowController_FullScreen.h"
#import "SKMainWindowController_Actions.h"
#import "SKLeftSideViewController.h"
#import "SKRightSideViewController.h"
#import "SKMainToolbarController.h"
#import "SKPDFView.h"
#import "SKStatusBar.h"
#import "SKSnapshotWindowController.h"
#import "SKNoteWindowController.h"
#import "SKNoteTextView.h"
#import "NSWindowController_SKExtensions.h"
#import "SKSideWindow.h"
#import "SKProgressController.h"
#import "SKAnnotationTypeImageView.h"
#import "SKStringConstants.h"
#import <SkimNotes/SkimNotes.h>
#import "PDFAnnotation_SKExtensions.h"
#import "SKNPDFAnnotationNote_SKExtensions.h"
#import "SKNoteText.h"
#import "SKImageToolTipWindow.h"
#import "SKMainDocument.h"
#import "PDFPage_SKExtensions.h"
#import "SKGroupedSearchResult.h"
#import "PDFSelection_SKExtensions.h"
#import "NSString_SKExtensions.h"
#import "SKApplication.h"
#import "NSMenu_SKExtensions.h"
#import "SKLineInspector.h"
#import "SKFieldEditor.h"
#import "PDFOutline_SKExtensions.h"
#import "SKDocumentController.h"
#import "SKFloatMapTable.h"
#import "SKFindController.h"
#import "NSColor_SKExtensions.h"
#import "SKSplitView.h"
#import "SKScrollView.h"
#import "NSEvent_SKExtensions.h"
#import "SKDocumentController.h"
#import "NSError_SKExtensions.h"
#import "PDFView_SKExtensions.h"
#import "NSInvocation_SKExtensions.h"
#import "NSURL_SKExtensions.h"
#import "PDFDocument_SKExtensions.h"
#import "NSArray_SKExtensions.h"
#import "SKCenteredTextFieldCell.h"
#import "SKScroller.h"
#import "SKNoteTableRowView.h"
#import "SKHighlightingTableRowView.h"
#import "SKSecondaryPDFView.h"
#import "SKControlTableCellView.h"

#define NOTES_KEY       @"notes"
#define SNAPSHOTS_KEY   @"snapshots"

#define PAGE_COLUMNID       @"page"
#define LABEL_COLUMNID      @"label"
#define NOTE_COLUMNID       @"note"
#define TYPE_COLUMNID       @"type"
#define COLOR_COLUMNID      @"color"
#define AUTHOR_COLUMNID     @"author"
#define DATE_COLUMNID       @"date"
#define IMAGE_COLUMNID      @"image"
#define RELEVANCE_COLUMNID  @"relevance"

#define ROWVIEW_IDENTIFIER @"row"

#define SKLeftSidePaneWidthKey  @"SKLeftSidePaneWidth"
#define SKRightSidePaneWidthKey @"SKRightSidePaneWidth"

#define MIN_SIDE_PANE_WIDTH 100.0
#define DEFAULT_SPLIT_PANE_HEIGHT 200.0
#define MIN_SPLIT_PANE_HEIGHT 50.0

#define SNAPSHOT_HEIGHT 200.0

#define COLUMN_INDENTATION 16.0
#define EXTRA_ROW_HEIGHT 2.0
#define DEFAULT_TEXT_ROW_HEIGHT 85.0
#define DEFAULT_MARKUP_ROW_HEIGHT 50.0

@interface SKMainWindowController (SKPrivateMain)

- (void)cleanup;

- (void)goToSelectedOutlineItem:(id)sender;

- (void)updatePageNumber;
- (void)updatePageLabel;

- (void)updateNoteFilterPredicate;

- (void)observeUndoManagerCheckpoint:(NSNotification *)notification;

@end

@interface SKMainWindowController (UIPrivate)
- (void)changeColorProperty:(id)sender;
@end

#pragma mark -

@implementation SKMainWindowController (UI)

#pragma mark Utility panel updating

- (NSButton *)newColorAccessoryButtonWithTitle:(NSString *)title {
    NSButton *button = [[NSButton alloc] init];
    [button setButtonType:NSSwitchButton];
    [button setTitle:title];
    [[button cell] setControlSize:NSSmallControlSize];
    [button setTarget:self];
    [button setAction:@selector(changeColorProperty:)];
    [button sizeToFit];
    return button;
}

- (void)updateColorPanel {
    PDFAnnotation *annotation = [pdfView activeAnnotation];
    NSColor *color = nil;
    NSView *accessoryView = nil;
    
    if ([[self window] isMainWindow]) {
        if ([annotation isSkimNote]) {
            if ([annotation hasInteriorColor]) {
                if (colorAccessoryView == nil)
                    colorAccessoryView = [self newColorAccessoryButtonWithTitle:NSLocalizedString(@"Fill color", @"Check button title")];
                accessoryView = colorAccessoryView;
            } else if ([annotation isText]) {
                if (textColorAccessoryView == nil)
                    textColorAccessoryView = [self newColorAccessoryButtonWithTitle:NSLocalizedString(@"Text color", @"Check button title")];
                accessoryView = textColorAccessoryView;
            }
            if ([annotation hasInteriorColor] && [colorAccessoryView state] == NSOnState) {
                color = [(id)annotation interiorColor] ?: [NSColor clearColor];
            } else if ([annotation isText] && [textColorAccessoryView state] == NSOnState) {
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

- (void)changeColorProperty:(id)sender{
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

- (void)updateUtilityPanel {
    PDFAnnotation *annotation = [pdfView activeAnnotation];
    
    if ([[self window] isMainWindow]) {
        if ([annotation isSkimNote]) {
            if ([annotation isText]) {
                mwcFlags.updatingFont = 1;
                [[NSFontManager sharedFontManager] setSelectedFont:[(PDFAnnotationFreeText *)annotation font] isMultiple:NO];
                mwcFlags.updatingFont = 0;
                mwcFlags.updatingFontAttributes = 1;
                [[NSFontManager sharedFontManager] setSelectedAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[(PDFAnnotationFreeText *)annotation fontColor], NSForegroundColorAttributeName, nil] isMultiple:NO];
                mwcFlags.updatingFontAttributes = 0;
            }
        }
    }
    
    [self updateColorPanel];
    [self updateLineInspector];
}

#pragma mark NSWindow delegate protocol

- (NSString *)windowTitleForDocumentDisplayName:(NSString *)displayName {
    if ([pdfView document])
        return [NSString stringWithFormat:NSLocalizedString(@"%@ (page %ld of %ld)", @"Window title format"), displayName, (long)[self pageNumber], (long)[[pdfView document] pageCount]];
    else
        return displayName;
}

- (void)windowDidBecomeMain:(NSNotification *)notification {
    if ([[self window] isEqual:[notification object]])
        [self updateUtilityPanel];
}

- (void)windowDidResignMain:(NSNotification *)notification {
    if ([[[NSColorPanel sharedColorPanel] accessoryView] isEqual:colorAccessoryView])
        [[NSColorPanel sharedColorPanel] setAccessoryView:nil];
}

- (void)windowWillClose:(NSNotification *)notification {
    if ([[notification object] isEqual:[self window]]) {
        // if we were not yet removed in removeWindowController: we should save our document info now
        // otherwise [self document] is nil so this is safe
        if ([self document]) {
            [self setRecentInfoNeedsUpdate:YES];
            [[self document] saveRecentDocumentInfo];
        }
        // timers retain their target, so invalidate them now or they may keep firing after the PDF is gone
        if (snapshotTimer) {
            [snapshotTimer invalidate];
            SKDESTROY(snapshotTimer);
        }
        if ([[pdfView document] isFinding])
            [[pdfView document] cancelFindString];
        if ((mwcFlags.isEditingPDF || mwcFlags.isEditingTable) && [self commitEditing] == NO)
            [self discardEditing];
        [self cleanup]; // clean up everything
    }
}

- (void)windowDidChangeScreen:(NSNotification *)notification {
    if ([[notification object] isEqual:[self window]] && [[notification object] isEqual:mainWindow] == NO) {
        NSScreen *screen = [[self window] screen];
        [[self window] setFrame:[screen frame] display:NO];
        if ([self interactionMode] == SKLegacyFullScreenMode) {
            NSDrawerState state;
            if ([[leftSideWindow screen] isEqual:screen] == NO) {
                state = [leftSideWindow state];
                [leftSideWindow remove];
                [leftSideWindow attachToWindow:[self window]];
                if (state == NSDrawerOpenState || state == NSDrawerOpeningState)
                    [leftSideWindow slideIn];
            }
            if ([[rightSideWindow screen] isEqual:screen] == NO) {
                state = [rightSideWindow state];
                [rightSideWindow remove];
                [rightSideWindow attachToWindow:[self window]];
                if (state == NSDrawerOpenState || state == NSDrawerOpeningState)
                    [rightSideWindow slideIn];
            }
        }
        [pdfView layoutDocumentView];
        [pdfView requiresDisplay];
    }
}

- (void)windowDidMove:(NSNotification *)notification {
    if ([[notification object] isEqual:[self window]] && [[notification object] isEqual:[self mainWindow]] == NO) {
        NSScreen *screen = [[self window] screen];
        NSRect screenFrame = [screen frame];
        if (NSEqualRects(screenFrame, [[self window] frame]) == NO) {
            [[self window] setFrame:screenFrame display:NO];
            if ([self interactionMode] == SKLegacyFullScreenMode) {
                [leftSideWindow remove];
                [leftSideWindow attachToWindow:[self window]];
                [rightSideWindow remove];
                [rightSideWindow attachToWindow:[self window]];
            }
            [pdfView layoutDocumentView];
            [pdfView requiresDisplay];
        }
    }
}

- (id)windowWillReturnFieldEditor:(NSWindow *)sender toObject:(id)anObject {
    if ([anObject isEqual:[findController findField]] || [anObject isEqual:[pdfView editTextField]]) {
        if (fieldEditor == nil) {
            fieldEditor = [[SKFieldEditor alloc] init];
            [fieldEditor setFieldEditor:YES];
        }
        if ([anObject isEqual:[findController findField]])
            [fieldEditor ignoreSelectors:@selector(performFindPanelAction:), NULL];
        else
            [fieldEditor ignoreSelectors:@selector(changeFont:), @selector(changeAttributes:), @selector(changeColor:), @selector(alignLeft:), @selector(alignRight:), @selector(alignCenter:), NULL];
        return fieldEditor;
    }
    return nil;
}

#pragma mark Page history highlights

#define MAX_HIGHLIGHTS 5

- (NSInteger)thumbnailHighlightLevelForRow:(NSInteger)row {
    if ([[NSUserDefaults standardUserDefaults] boolForKey:SKDisableHistoryHighlightsKey] == NO) {
        NSInteger i, iMax = [lastViewedPages count];
        for (i = 0; i < iMax; i++) {
            if (row == (NSInteger)[lastViewedPages pointerAtIndex:i])
                return MAX(0, MAX_HIGHLIGHTS - i);
        }
    }
    return 0;
}

- (NSInteger)tocHighlightLevelForRow:(NSInteger)row {
    if ([[NSUserDefaults standardUserDefaults] boolForKey:SKDisableHistoryHighlightsKey] == NO) {
        NSOutlineView *ov = leftSideController.tocOutlineView;
        NSInteger numRows = [ov numberOfRows];
        NSInteger firstPage = [[[ov itemAtRow:row] page] pageIndex];
        NSInteger lastPage = row + 1 < numRows ? [[[ov itemAtRow:row + 1] page] pageIndex] : [[self pdfDocument] pageCount];
        NSRange range = NSMakeRange(firstPage, MAX(1L, lastPage - firstPage));
        NSInteger i, iMax = [lastViewedPages count];
        for (i = 0; i < iMax; i++) {
            if (NSLocationInRange((NSUInteger)[lastViewedPages pointerAtIndex:i], range))
                return MAX(0, MAX_HIGHLIGHTS - i);
        }
    }
    return 0;
}

- (void)updateThumbnailHighlights {
    [leftSideController.thumbnailTableView enumerateAvailableRowViewsUsingBlock:^(SKHighlightingTableRowView *rowView, NSInteger row){
        [rowView setHighlightLevel:[self thumbnailHighlightLevelForRow:row]];
    }];
}

- (void)updateTocHighlights {
    [leftSideController.tocOutlineView enumerateAvailableRowViewsUsingBlock:^(SKHighlightingTableRowView *rowView, NSInteger row){
        [rowView setHighlightLevel:[self tocHighlightLevelForRow:row]];
    }];
}

#pragma mark NSTableView datasource protocol

// AppKit bug: need a dummy NSTableDataSource implementation, otherwise some NSTableView delegate methods are ignored
- (NSInteger)numberOfRowsInTableView:(NSTableView *)tv {
    if ([tv isEqual:rightSideController.snapshotTableView]) {
        return [[rightSideController.snapshotArrayController arrangedObjects] count];
    }
    return 0;
}

- (id)tableView:(NSTableView *)tv objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    if ([tv isEqual:rightSideController.snapshotTableView]) {
        return [[rightSideController.snapshotArrayController arrangedObjects] objectAtIndex:row];
    }
    return nil;
}

- (id<NSPasteboardWriting>)tableView:(NSTableView *)tv pasteboardWriterForRow:(NSInteger)row {
    if ([tv isEqual:leftSideController.thumbnailTableView]) {
        if ([[pdfView document] isLocked] == NO) {
            PDFPage *page = [[pdfView document] pageAtIndex:row];
            NSString *fileUTI = [[pdfView document] allowsPrinting] ? (NSString *)kUTTypePDF : (NSString *)kUTTypeTIFF;
            Class promiseClass = NSClassFromString(@"NSFilePromiseProvider");
            if (promiseClass) {
                return [[[promiseClass alloc] initWithFileType:fileUTI delegate:page] autorelease];
            } else {
                NSString *fileExt = nil;
                NSString *pdfType = nil;
                NSPasteboardItem *item = [[[NSPasteboardItem alloc] init] autorelease];
                if ([[pdfView document] allowsPrinting]) {
                    fileExt = @"pdf";
                    pdfType = NSPasteboardTypePDF;
                } else {
                    fileExt = @"tiff";
                }
                [item setString:fileUTI forType:(NSString *)kPasteboardTypeFilePromiseContent];
                [item setDataProvider:page forTypes:[NSArray arrayWithObjects:(NSString *)kPasteboardTypeFileURLPromise, NSPasteboardTypeTIFF, pdfType, nil]];
                return item;
            }
        }
    } else if ([tv isEqual:rightSideController.snapshotTableView]) {
        SKSnapshotWindowController *snapshot = [[rightSideController.snapshotArrayController arrangedObjects] objectAtIndex:row];
        Class promiseClass = NSClassFromString(@"NSFilePromiseProvider");
        if (promiseClass) {
            return [[[promiseClass alloc] initWithFileType:NSPasteboardTypeTIFF delegate:snapshot] autorelease];
        } else {
            NSPasteboardItem *item = [[[NSPasteboardItem alloc] init] autorelease];
            [item setString:(NSString *)kUTTypeTIFF forType:(NSString *)kPasteboardTypeFilePromiseContent];
            [item setDataProvider:snapshot forTypes:[NSArray arrayWithObjects:(NSString *)kPasteboardTypeFileURLPromise, NSPasteboardTypeTIFF, nil]];
            return item;
        }
    }
    return nil;
}

- (void)tableView:(NSTableView *)tv sortDescriptorsDidChange:(NSArray *)oldDescriptors {
    if ([tv isEqual:leftSideController.groupedFindTableView]) {
        [leftSideController.groupedFindArrayController setSortDescriptors:[tv sortDescriptors]];
    }
}

#pragma mark NSTableView delegate protocol


// This makes the thumbnail tableview view based on 10.7+
// on 10.6 this is ignored, and the cell based tableview uses the datasource methods
- (NSView *)tableView:(NSTableView *)tv viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    if ([tv isEqual:leftSideController.thumbnailTableView] ||
        [tv isEqual:rightSideController.snapshotTableView] ||
        [tv isEqual:leftSideController.findTableView]) {
        return [tv makeViewWithIdentifier:[tableColumn identifier] owner:self];
    } else if ([tv isEqual:leftSideController.groupedFindTableView]) {
        NSTableCellView *view = [tv makeViewWithIdentifier:[tableColumn identifier] owner:self];
        if ([[tableColumn identifier] isEqualToString:RELEVANCE_COLUMNID]) {
            // IB does not allow setting te height and height sizable mask of a NSLeveleIndicator
            NSControl *levelIndicator = [(SKControlTableCellView *)view control];
            [levelIndicator setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
            [levelIndicator setFrame:[view bounds]];
        }
        return view;
    }
    return nil;
}

- (NSView *)tableView:(NSTableView *)tv rowViewForRow:(NSInteger)row {
    if ([tv isEqual:leftSideController.thumbnailTableView]) {
        SKHighlightingTableRowView *rowView = [tv makeViewWithIdentifier:ROWVIEW_IDENTIFIER owner:self];
        [rowView setHighlightLevel:[self thumbnailHighlightLevelForRow:row]];
        return rowView;
    }
    return nil;
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification {
    if ([[aNotification object] isEqual:leftSideController.thumbnailTableView]) {
        if (mwcFlags.updatingThumbnailSelection == 0) {
            NSInteger row = [leftSideController.thumbnailTableView selectedRow];
            if (row != -1)
                [pdfView goToPage:[[pdfView document] pageAtIndex:row]];
            
            if ([self interactionMode] == SKPresentationMode && [[NSUserDefaults standardUserDefaults] boolForKey:SKAutoHidePresentationContentsKey])
                [self hideLeftSideWindow];
        }
    } else if ([[aNotification object] isEqual:rightSideController.snapshotTableView]) {
        NSInteger row = [[aNotification object] selectedRow];
        if (row != -1) {
            SKSnapshotWindowController *controller = [[rightSideController.snapshotArrayController arrangedObjects] objectAtIndex:row];
            if ([[controller window] isVisible])
                [[controller window] orderFront:self];
        }
    } else if ([[aNotification object] isEqual:leftSideController.findTableView] ||
               [[aNotification object] isEqual:leftSideController.groupedFindTableView]) {
        [self selectFindResultHighlight:NSDirectSelection];
    }
}

- (BOOL)tableView:(NSTableView *)tv commandSelectRow:(NSInteger)row {
    if ([tv isEqual:leftSideController.thumbnailTableView]) {
        NSRect rect = [[[pdfView document] pageAtIndex:row] boundsForBox:kPDFDisplayBoxCropBox];
        
        rect.origin.y = NSMidY(rect) - 0.5 * SNAPSHOT_HEIGHT;
        rect.size.height = SNAPSHOT_HEIGHT;
        [self showSnapshotAtPageNumber:row forRect:rect scaleFactor:[pdfView scaleFactor] autoFits:NO];
        return YES;
    }
    return NO;
}

- (void)tableViewColumnDidResize:(NSNotification *)aNotification {
    if ([[[[aNotification userInfo] objectForKey:@"NSTableColumn"] identifier] isEqualToString:IMAGE_COLUMNID]) {
        NSTableView *tv = [aNotification object];
        if ([tv isEqual:leftSideController.thumbnailTableView] || [tv isEqual:rightSideController.snapshotTableView]) {
            [tv noteHeightOfRowsWithIndexesChanged:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [tv numberOfRows])]];
        }
    }
}

- (CGFloat)tableView:(NSTableView *)tv heightOfRow:(NSInteger)row {
    NSSize thumbSize = NSZeroSize;
    CGFloat thumbHeight = 0.0, rowHeight = [tv rowHeight];
    if ([tv isEqual:leftSideController.thumbnailTableView]) {
        thumbSize = [[thumbnails objectAtIndex:row] size];
        thumbHeight = roundedThumbnailSize;
    } else if ([tv isEqual:rightSideController.snapshotTableView]) {
        thumbSize = [[(SKSnapshotWindowController *)[[rightSideController.snapshotArrayController arrangedObjects] objectAtIndex:row] thumbnail] size];
        thumbHeight = roundedSnapshotThumbnailSize;
    } else {
        return rowHeight;
    }
    if (thumbSize.height <= rowHeight)
        return rowHeight;
    return fmax(rowHeight, fmin(thumbHeight, fmin(thumbSize.height, [[tv tableColumnWithIdentifier:IMAGE_COLUMNID] width] * thumbSize.height / thumbSize.width)));
}

- (void)tableView:(NSTableView *)tv copyRowsWithIndexes:(NSIndexSet *)rowIndexes {
    if ([tv isEqual:leftSideController.thumbnailTableView]) {
        NSUInteger idx = [rowIndexes firstIndex];
        if (idx != NSNotFound && [[pdfView document] isLocked] == NO) {
            PDFPage *page = [[pdfView document] pageAtIndex:idx];
            NSData *tiffData = [page TIFFDataForRect:[page boundsForBox:[pdfView displayBox]]];
            NSPasteboard *pboard = [NSPasteboard generalPasteboard];
            NSPasteboardItem *pboardItem = [[[NSPasteboardItem alloc] init] autorelease];
            if ([[pdfView document] allowsPrinting])
                [pboardItem setData:[page dataRepresentation] forType:NSPasteboardTypePDF];
            [pboardItem setData:tiffData forType:NSPasteboardTypeTIFF];
            [pboard clearContents];
            [pboard writeObjects:[NSArray arrayWithObjects:pboardItem, nil]];
        }
    } else if ([tv isEqual:leftSideController.findTableView]) {
        NSMutableString *string = [NSMutableString string];
        NSArray *results = [leftSideController.findArrayController arrangedObjects];
        [rowIndexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
            PDFSelection *match = [results objectAtIndex:idx];
            [string appendString:@"* "];
            [string appendFormat:NSLocalizedString(@"Page %@", @""), [match firstPageLabel]];
            [string appendFormat:@": %@\n", [[match contextString] string]];
        }];
        NSPasteboard *pboard = [NSPasteboard generalPasteboard];
        [pboard clearContents];
        [pboard writeObjects:[NSArray arrayWithObjects:string, nil]];
    } else if ([tv isEqual:leftSideController.groupedFindTableView]) {
        NSMutableString *string = [NSMutableString string];
        NSArray *results = [leftSideController.groupedFindArrayController arrangedObjects];
        [rowIndexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
            SKGroupedSearchResult *result = [results objectAtIndex:idx];
            NSArray *matches = [result matches];
            [string appendString:@"* "];
            [string appendFormat:NSLocalizedString(@"Page %@", @""), [[result page] displayLabel]];
            [string appendString:@": "];
            [string appendFormat:NSLocalizedString(@"%ld Results", @""), (long)[matches count]];
            [string appendFormat:@":\n\t%@\n", [[matches valueForKeyPath:@"contextString.string"] componentsJoinedByString:@"\n\t"]];
        }];
        NSPasteboard *pboard = [NSPasteboard generalPasteboard];
        [pboard clearContents];
        [pboard writeObjects:[NSArray arrayWithObjects:string, nil]];
    }
}

- (BOOL)tableView:(NSTableView *)tv canCopyRowsWithIndexes:(NSIndexSet *)rowIndexes {
    if ([tv isEqual:leftSideController.thumbnailTableView] ||
        [tv isEqual:leftSideController.findTableView] ||
        [tv isEqual:leftSideController.groupedFindTableView]) {
        return [rowIndexes count] > 0;
    }
    return NO;
}

- (void)tableView:(NSTableView *)tv deleteRowsWithIndexes:(NSIndexSet *)rowIndexes {
    if ([tv isEqual:rightSideController.snapshotTableView]) {
        NSArray *controllers = [[rightSideController.snapshotArrayController arrangedObjects] objectsAtIndexes:rowIndexes];
        [controllers makeObjectsPerformSelector:@selector(close)];
    }
}

- (BOOL)tableView:(NSTableView *)tv canDeleteRowsWithIndexes:(NSIndexSet *)rowIndexes {
    if ([tv isEqual:rightSideController.snapshotTableView]) {
        return [rowIndexes count] > 0;
    }
    return NO;
}

- (void)tableViewMoveLeft:(NSTableView *)tv {
    if (([tv isEqual:leftSideController.findTableView] || [tv isEqual:leftSideController.groupedFindTableView])) {
        [self selectFindResultHighlight:NSSelectingPrevious];
    }
}

- (void)tableViewMoveRight:(NSTableView *)tv {
    if (([tv isEqual:leftSideController.findTableView] || [tv isEqual:leftSideController.groupedFindTableView])) {
        [self selectFindResultHighlight:NSSelectingNext];
    }
}

- (id <SKImageToolTipContext>)tableView:(NSTableView *)tv imageContextForRow:(NSInteger)row {
    if ([tv isEqual:leftSideController.findTableView])
        return [[[leftSideController.findArrayController arrangedObjects] objectAtIndex:row] destination];
    else if ([tv isEqual:leftSideController.groupedFindTableView])
        return [[[[[leftSideController.groupedFindArrayController arrangedObjects] objectAtIndex:row] matches] objectAtIndex:0] destination];
    return nil;
}

- (NSArray *)tableView:(NSTableView *)tv typeSelectHelperSelectionStrings:(SKTypeSelectHelper *)typeSelectHelper {
    if ([tv isEqual:leftSideController.thumbnailTableView]) {
        return pageLabels;
    }
    return nil;
}

- (void)tableView:(NSTableView *)tv typeSelectHelper:(SKTypeSelectHelper *)typeSelectHelper didFailToFindMatchForSearchString:(NSString *)searchString {
    if ([tv isEqual:leftSideController.thumbnailTableView]) {
        [statusBar setLeftStringValue:[NSString stringWithFormat:NSLocalizedString(@"No match: \"%@\"", @"Status message"), searchString]];
    }
}

- (void)tableView:(NSTableView *)tv typeSelectHelper:(SKTypeSelectHelper *)typeSelectHelper updateSearchString:(NSString *)searchString {
    if ([tv isEqual:leftSideController.thumbnailTableView]) {
        if (searchString)
            [statusBar setLeftStringValue:[NSString stringWithFormat:NSLocalizedString(@"Go to page: %@", @"Status message"), searchString]];
        else
            [self updateLeftStatus];
    }
}

#pragma mark NSOutlineView datasource protocol

- (NSInteger)outlineView:(NSOutlineView *)ov numberOfChildrenOfItem:(id)item{
    if ([ov isEqual:leftSideController.tocOutlineView]) {
        if (item == nil && [[pdfView document] isLocked] == NO)
            item = [[pdfView document] outlineRoot];
        return [(PDFOutline *)item numberOfChildren];
    } else if ([ov isEqual:rightSideController.noteOutlineView]) {
        if (item == nil)
            return [[rightSideController.noteArrayController arrangedObjects] count];
        else
            return [item hasNoteText];
    }
    return 0;
}

- (id)outlineView:(NSOutlineView *)ov child:(NSInteger)anIndex ofItem:(id)item{
    if ([ov isEqual:leftSideController.tocOutlineView]) {
        if (item == nil && [[pdfView document] isLocked] == NO)
            item = [[pdfView document] outlineRoot];
        id obj = [(PDFOutline *)item childAtIndex:anIndex];
        return obj;
    } else if ([ov isEqual:rightSideController.noteOutlineView]) {
        if (item == nil)
            return [[rightSideController.noteArrayController arrangedObjects] objectAtIndex:anIndex];
        else
            return [item noteText];
    }
    return nil;
}

- (BOOL)outlineView:(NSOutlineView *)ov isItemExpandable:(id)item{
    if ([ov isEqual:leftSideController.tocOutlineView]) {
        if (item == nil && [[pdfView document] isLocked] == NO)
            item = [[pdfView document] outlineRoot];
        return ([(PDFOutline *)item numberOfChildren] > 0);
    } else if ([ov isEqual:rightSideController.noteOutlineView]) {
        return [item hasNoteText];
    }
    return NO;
}

- (id)outlineView:(NSOutlineView *)ov objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item{
    if ([ov isEqual:leftSideController.tocOutlineView] || [ov isEqual:rightSideController.noteOutlineView]) {
        return item;
    }
    return nil;
}

- (NSDragOperation)outlineView:(NSOutlineView *)ov validateDrop:(id <NSDraggingInfo>)info proposedItem:(id)item proposedChildIndex:(NSInteger)anIndex {
    NSDragOperation dragOp = NSDragOperationNone;
    if ([ov isEqual:rightSideController.noteOutlineView]) {
        NSPasteboard *pboard = [info draggingPasteboard];
        if ([pboard canReadObjectForClasses:[NSArray arrayWithObject:[NSColor class]] options:[NSDictionary dictionary]] &&
            anIndex == NSOutlineViewDropOnItemIndex && [(PDFAnnotation *)item type] != nil)
            dragOp = NSDragOperationEvery;
    }
    return dragOp;
}

- (BOOL)outlineView:(NSOutlineView *)ov acceptDrop:(id <NSDraggingInfo>)info item:(id)item childIndex:(NSInteger)anIndex {
    if ([ov isEqual:rightSideController.noteOutlineView]) {
        NSPasteboard *pboard = [info draggingPasteboard];
        if ([pboard canReadObjectForClasses:[NSArray arrayWithObject:[NSColor class]] options:[NSDictionary dictionary]]) {
            BOOL isShift = ([NSEvent standardModifierFlags] & NSShiftKeyMask) != 0;
            BOOL isAlt = ([NSEvent standardModifierFlags] & NSAlternateKeyMask) != 0;
            [item setColor:[NSColor colorFromPasteboard:pboard] alternate:isAlt updateDefaults:isShift];
            return YES;
        }
    }
    return NO;
}

#pragma mark NSOutlineView delegate protocol

- (NSView *)outlineView:(NSOutlineView *)ov viewForTableColumn:(NSTableColumn *)tableColumn item:(id)item {
    if ([ov isEqual:leftSideController.tocOutlineView]) {
        return [ov makeViewWithIdentifier:[tableColumn identifier] owner:self];
    } else if ([ov isEqual:rightSideController.noteOutlineView]) {
        if ([(PDFAnnotation *)item type]) {
            NSTableCellView *view = [ov makeViewWithIdentifier:[tableColumn identifier] owner:self];
            // Xcode keeps changing the frames when converting to Xcode 8 format
            [[view textField] ?: [view imageView] setFrame:[view bounds]];
            if ([[tableColumn identifier] isEqualToString:TYPE_COLUMNID])
                [(SKAnnotationTypeImageView *)[view imageView] setHasOutline:[pdfView activeAnnotation] == item];
            return view;
        }
    }
    return nil;
}

- (NSTableRowView *)outlineView:(NSOutlineView *)ov rowViewForItem:(id)item {
    if ([ov isEqual:leftSideController.tocOutlineView]) {
        SKHighlightingTableRowView *rowView = [ov makeViewWithIdentifier:ROWVIEW_IDENTIFIER owner:self];
        [rowView setHighlightLevel:[self tocHighlightLevelForRow:[ov rowForItem:item]]];
        return rowView;
    } else if ([ov isEqual:rightSideController.noteOutlineView]) {
        return [ov makeViewWithIdentifier:ROWVIEW_IDENTIFIER owner:self];
    }
    return nil;
}

- (void)outlineView:(NSOutlineView *)ov didAddRowView:(NSTableRowView *)rowView forRow:(NSInteger)row {
    if ([ov isEqual:rightSideController.noteOutlineView]) {
        SKNoteTableRowView *noteRowView = [rowView isKindOfClass:[SKNoteTableRowView class]] ? (SKNoteTableRowView *)rowView : nil;
        NSTableCellView *view = [noteRowView rowCellView];
        if (view) {
            [noteRowView setRowCellView:nil];
            [view removeFromSuperview];
        }
        id item = [ov itemAtRow:row];
        if ([(PDFAnnotation *)item type] == nil) {
            NSRect frame = NSZeroRect;
            NSInteger column, numColumns = [ov numberOfColumns];
            NSArray *tcs = [ov tableColumns];
            for (column = 0; column < numColumns; column++) {
                if ([[tcs objectAtIndex:column] isHidden] == NO)
                    frame = NSUnionRect(frame, [ov frameOfCellAtColumn:column row:row]);
            }
            view = [ov makeViewWithIdentifier:NOTE_COLUMNID owner:self];
            [view setObjectValue:item];
            [view setFrame:[ov convertRect:frame toView:rowView]];
            [rowView addSubview:view];
            [noteRowView setRowCellView:view];
        }
    }
}

- (void)outlineView:(NSOutlineView *)ov didRemoveRowView:(NSTableRowView *)rowView forRow:(NSInteger)row {
    if ([ov isEqual:rightSideController.noteOutlineView]) {
        SKNoteTableRowView *noteRowView = [rowView isKindOfClass:[SKNoteTableRowView class]] ? (SKNoteTableRowView *)rowView : nil;
        NSTableCellView *view = [noteRowView rowCellView];
        if (view) {
            [noteRowView setRowCellView:nil];
            [view setObjectValue:nil];
            [view removeFromSuperview];
        }
    }
}

- (void)outlineView:(NSOutlineView *)ov didClickTableColumn:(NSTableColumn *)tableColumn {
    if ([ov isEqual:rightSideController.noteOutlineView]) {
        NSTableColumn *oldTableColumn = [ov highlightedTableColumn];
        NSTableColumn *newTableColumn = ([NSEvent modifierFlags] & NSCommandKeyMask) ? nil : tableColumn;
        NSMutableArray *sortDescriptors = nil;
        BOOL ascending = YES;
        if ([oldTableColumn isEqual:newTableColumn]) {
            sortDescriptors = [[[rightSideController.noteArrayController sortDescriptors] mutableCopy] autorelease];
            [sortDescriptors replaceObjectAtIndex:0 withObject:[[sortDescriptors firstObject] reversedSortDescriptor]];
            ascending = [[sortDescriptors firstObject] ascending];
        } else {
            NSString *tcID = [newTableColumn identifier];
            NSSortDescriptor *pageIndexSortDescriptor = [[[NSSortDescriptor alloc] initWithKey:SKNPDFAnnotationPageIndexKey ascending:ascending] autorelease];
            NSSortDescriptor *boundsSortDescriptor = [[[NSSortDescriptor alloc] initWithKey:SKPDFAnnotationBoundsOrderKey ascending:ascending selector:@selector(compare:)] autorelease];
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
            }
            if (oldTableColumn)
                [ov setIndicatorImage:nil inTableColumn:oldTableColumn];
            [ov setHighlightedTableColumn:newTableColumn]; 
        }
        [rightSideController.noteArrayController setSortDescriptors:sortDescriptors];
        if (newTableColumn)
            [ov setIndicatorImage:[NSImage imageNamed:ascending ? @"NSAscendingSortIndicator" : @"NSDescendingSortIndicator"]
                    inTableColumn:newTableColumn];
        [ov reloadData];
    }
}

- (void)outlineViewSelectionDidChange:(NSNotification *)notification{
	// Get the destination associated with the search result list. Tell the PDFView to go there.
	if ([[notification object] isEqual:leftSideController.tocOutlineView] && (mwcFlags.updatingOutlineSelection == 0)){
        mwcFlags.updatingOutlineSelection = 1;
        [self goToSelectedOutlineItem:nil];
        mwcFlags.updatingOutlineSelection = 0;
        if ([self interactionMode] == SKPresentationMode && [[NSUserDefaults standardUserDefaults] boolForKey:SKAutoHidePresentationContentsKey])
            [self hideLeftSideWindow];
    }
}

- (void)outlineViewItemDidExpand:(NSNotification *)notification{
    if ([[notification object] isEqual:leftSideController.tocOutlineView]) {
        [self updateTocHighlights];
        [self updateOutlineSelection];
    }
}

- (void)outlineViewItemDidCollapse:(NSNotification *)notification{
    if ([[notification object] isEqual:leftSideController.tocOutlineView]) {
        [self updateTocHighlights];
        [self updateOutlineSelection];
    }
}

- (void)outlineViewColumnDidResize:(NSNotification *)notification{
    if (mwcFlags.autoResizeNoteRows &&
        [[notification object] isEqual:rightSideController.noteOutlineView] &&
        [[[[notification userInfo] objectForKey:@"NSTableColumn"] identifier] isEqualToString:NOTE_COLUMNID] &&
        [(SKScrollView *)[[notification object] enclosingScrollView] isResizingSubviews] == NO) {
        [rowHeights removeAllFloats];
        [rightSideController.noteOutlineView noteHeightOfRowsWithIndexesChanged:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [rightSideController.noteOutlineView numberOfRows])]];
    }
}

- (void)outlineView:(NSOutlineView *)ov didChangeHiddenOfTableColumn:(NSTableColumn *)tableColumn {
    if (mwcFlags.autoResizeNoteRows &&
        [ov isEqual:rightSideController.noteOutlineView] &&
        [[tableColumn identifier] isEqualToString:NOTE_COLUMNID]) {
        [rowHeights removeAllFloats];
        [rightSideController.noteOutlineView noteHeightOfRowsWithIndexesChanged:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [rightSideController.noteOutlineView numberOfRows])]];
    }
}

- (CGFloat)outlineView:(NSOutlineView *)ov heightOfRowByItem:(id)item {
    if ([ov isEqual:rightSideController.noteOutlineView]) {
        CGFloat rowHeight = [rowHeights floatForKey:item];
        if (rowHeight <= 0.0) {
            if (mwcFlags.autoResizeNoteRows) {
                NSTableColumn *tableColumn = [ov tableColumnWithIdentifier:NOTE_COLUMNID];
                id cell = [tableColumn dataCell];
                [cell setObjectValue:[item objectValue]];
                if ([(PDFAnnotation *)item type] == nil) {
                    rowHeight = [cell cellSizeForBounds:NSMakeRect(0.0, 0.0, fmax(10.0, NSWidth([ov frame]) - COLUMN_INDENTATION - [ov indentationPerLevel]), CGFLOAT_MAX)].height;
                } else if ([tableColumn isHidden] == NO) {
                    rowHeight = [cell cellSizeForBounds:NSMakeRect(0.0, 0.0, [tableColumn width] - COLUMN_INDENTATION, CGFLOAT_MAX)].height;
                }
                rowHeight = fmax(rowHeight, [ov rowHeight]) + EXTRA_ROW_HEIGHT;
                [rowHeights setFloat:rowHeight forKey:item];
            } else {
                rowHeight = [(PDFAnnotation *)item type] ? [ov rowHeight] + EXTRA_ROW_HEIGHT : ([[(SKNoteText *)item note] isNote] ? DEFAULT_TEXT_ROW_HEIGHT : DEFAULT_MARKUP_ROW_HEIGHT);
            }
        }
        return rowHeight;
    }
    return [ov rowHeight];
}

- (void)outlineView:(NSOutlineView *)ov setHeight:(CGFloat)newHeight ofRowByItem:(id)item {
    [rowHeights setFloat:newHeight forKey:item];
}

- (NSArray *)noteItems:(NSArray *)items {
    NSMutableArray *noteItems = [NSMutableArray array];
    
    for (PDFAnnotation *item in items) {
        if ([item type] == nil) {
            item = [(SKNoteText *)item note];
        }
        if ([noteItems containsObject:item] == NO)
            [noteItems addObject:item];
    }
    return noteItems;
}

- (void)outlineView:(NSOutlineView *)ov deleteItems:(NSArray *)items  {
    if ([ov isEqual:rightSideController.noteOutlineView] && [items count]) {
        for (PDFAnnotation *item in [self noteItems:items])
            [pdfView removeAnnotation:item];
        [[[self document] undoManager] setActionName:NSLocalizedString(@"Remove Note", @"Undo action name")];
    }
}

- (BOOL)outlineView:(NSOutlineView *)ov canDeleteItems:(NSArray *)items  {
    if ([ov isEqual:rightSideController.noteOutlineView]) {
        return [[self pdfDocument] allowsNotes] && [items count] > 0;
    }
    return NO;
}

- (void)outlineView:(NSOutlineView *)ov copyItems:(NSArray *)items  {
    if ([ov isEqual:rightSideController.noteOutlineView] && [items count]) {
        NSPasteboard *pboard = [NSPasteboard generalPasteboard];
        NSMutableArray *copiedItems = [NSMutableArray array];
        NSMutableAttributedString *attrString = [[[NSMutableAttributedString alloc] init] autorelease];
        BOOL isAttributed = NO;
        id item;
        
        for (item in [self noteItems:items]) {
            if ([item isMovable])
                [copiedItems addObject:item];
        }
        for (item in items) {
            if ([attrString length])
                [attrString replaceCharactersInRange:NSMakeRange([attrString length], 0) withString:@"\n\n"];
            if ([(PDFAnnotation *)item type] == nil && [[(SKNoteText *)item note] isNote]) {
                [attrString appendAttributedString:[(SKNoteText *)item text]];
                isAttributed = YES;
            } else {
                [attrString replaceCharactersInRange:NSMakeRange([attrString length], 0) withString:[item string] ?: @""];
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
}

- (BOOL)outlineView:(NSOutlineView *)ov canCopyItems:(NSArray *)items  {
    if ([ov isEqual:rightSideController.noteOutlineView]) {
        return [items count] > 0;
    }
    return NO;
}

- (id <SKImageToolTipContext>)outlineView:(NSOutlineView *)ov imageContextForItem:(id)item {
    if ([ov isEqual:leftSideController.tocOutlineView])
        return [item destination];
    return nil;
}

- (void)outlineViewCommandKeyPressedDuringNavigation:(NSOutlineView *)ov {
    PDFAnnotation *annotation = [[self selectedNotes] lastObject];
    if (annotation) {
        [pdfView scrollAnnotationToVisible:annotation];
        [pdfView setActiveAnnotation:annotation];
    }
}

- (NSArray *)outlineView:(NSOutlineView *)ov typeSelectHelperSelectionStrings:(SKTypeSelectHelper *)typeSelectHelper {
    if ([ov isEqual:rightSideController.noteOutlineView]) {
        NSInteger i, count = [rightSideController.noteOutlineView numberOfRows];
        NSMutableArray *texts = [NSMutableArray arrayWithCapacity:count];
        for (i = 0; i < count; i++) {
            id item = [rightSideController.noteOutlineView itemAtRow:i];
            NSString *string = [item string];
            [texts addObject:string ?: @""];
        }
        return texts;
    } else if ([ov isEqual:leftSideController.tocOutlineView]) {
        NSInteger i, count = [leftSideController.tocOutlineView numberOfRows];
        NSMutableArray *array = [NSMutableArray arrayWithCapacity:count];
        for (i = 0; i < count; i++) 
            [array addObject:[[(PDFOutline *)[leftSideController.tocOutlineView itemAtRow:i] label] lossyStringUsingEncoding:NSASCIIStringEncoding]];
        return array;
    }
    return nil;
}

- (void)outlineView:(NSOutlineView *)ov typeSelectHelper:(SKTypeSelectHelper *)typeSelectHelper didFailToFindMatchForSearchString:(NSString *)searchString {
    if ([ov isEqual:rightSideController.noteOutlineView]) {
        [statusBar setRightStringValue:[NSString stringWithFormat:NSLocalizedString(@"No match: \"%@\"", @"Status message"), searchString]];
    } else if ([ov isEqual:leftSideController.tocOutlineView]) {
        [statusBar setLeftStringValue:[NSString stringWithFormat:NSLocalizedString(@"No match: \"%@\"", @"Status message"), searchString]];
    }
}

- (void)outlineView:(NSOutlineView *)ov typeSelectHelper:(SKTypeSelectHelper *)typeSelectHelper updateSearchString:(NSString *)searchString {
    if ([ov isEqual:rightSideController.noteOutlineView]) {
        if (searchString)
            [statusBar setRightStringValue:[NSString stringWithFormat:NSLocalizedString(@"Finding note: \"%@\"", @"Status message"), searchString]];
        else
            [self updateRightStatus];
    } else if ([ov isEqual:leftSideController.tocOutlineView]) {
        if (searchString)
            [statusBar setLeftStringValue:[NSString stringWithFormat:NSLocalizedString(@"Finding: \"%@\"", @"Status message"), searchString]];
        else
            [self updateLeftStatus];
    }
}

#pragma mark Contextual menus

- (void)copyPage:(id)sender {
    [self tableView:leftSideController.thumbnailTableView copyRowsWithIndexes:[sender representedObject]];
}

- (void)selectSelections:(id)sender {
    [pdfView setCurrentSelection:[PDFSelection selectionByAddingSelections:[sender representedObject]]];
}

- (void)addAnnotationsForSelections:(id)sender {
    for (PDFSelection *selection in [sender representedObject])
        [pdfView addAnnotationWithType:[sender tag] selection:selection];
}

- (void)deleteSnapshot:(id)sender {
    [[sender representedObject] close];
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

- (void)deleteNotes:(id)sender {
    [self outlineView:rightSideController.noteOutlineView deleteItems:[sender representedObject]];
}

- (void)copyNotes:(id)sender {
    [self outlineView:rightSideController.noteOutlineView copyItems:[sender representedObject]];
}

- (void)editNoteFromTable:(id)sender {
    PDFAnnotation *annotation = [sender representedObject];
    SKNoteOutlineView *ov = rightSideController.noteOutlineView;
    NSInteger row = [ov rowForItem:annotation];
    NSInteger column = [ov columnWithIdentifier:NOTE_COLUMNID];
    if (row != -1 && column != -1) {
        [ov selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
        [ov editColumn:column row:row withEvent:nil select:YES];
    }
}

- (void)editNoteTextFromTable:(id)sender {
    PDFAnnotation *annotation = [sender representedObject];
    [pdfView scrollAnnotationToVisible:annotation];
    [pdfView setActiveAnnotation:annotation];
    [self showNote:annotation];
    SKNoteWindowController *noteController = (SKNoteWindowController *)[self windowControllerForNote:annotation];
    [[noteController window] makeFirstResponder:[noteController textView]];
    [[noteController textView] selectAll:nil];
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
    CGFloat height = 0.0, rowHeight = [rightSideController.noteOutlineView rowHeight];
    NSTableColumn *tableColumn = [rightSideController.noteOutlineView tableColumnWithIdentifier:NOTE_COLUMNID];
    id cell = [tableColumn dataCell];
    NSRect rect = NSMakeRect(0.0, 0.0, [tableColumn width] - COLUMN_INDENTATION, CGFLOAT_MAX);
    NSRect fullRect = NSMakeRect(0.0, 0.0,  NSWidth([rightSideController.noteOutlineView frame]) - COLUMN_INDENTATION - [rightSideController.noteOutlineView indentationPerLevel], CGFLOAT_MAX);
    NSMutableIndexSet *rowIndexes = nil;
    NSArray *items = [sender representedObject];
    NSInteger row;
    
    if (items == nil) {
        NSMutableArray *tmpItems = [NSMutableArray array];
        for (PDFAnnotation *note in items) {
            [tmpItems addObject:note];
            if ([note hasNoteText])
                [tmpItems addObject:[note noteText]];
        }
        items = tmpItems;
    } else {
        rowIndexes = [NSMutableIndexSet indexSet];
    }
    
    for (id item in items) {
        [cell setObjectValue:[item objectValue]];
        if ([(PDFAnnotation *)item type] == nil)
            height = [cell cellSizeForBounds:fullRect].height;
        else if ([tableColumn isHidden] == NO)
            height = [cell cellSizeForBounds:rect].height;
        else
            height = 0.0;
        [rowHeights setFloat:fmax(height, rowHeight) + EXTRA_ROW_HEIGHT forKey:item];
        if (rowIndexes) {
            row = [rightSideController.noteOutlineView rowForItem:item];
            if (row != -1)
                [rowIndexes addIndex:row];
        }
    }
    [rightSideController.noteOutlineView noteHeightOfRowsWithIndexesChanged:rowIndexes];
}

- (void)resetHeightOfNoteRows:(id)sender {
    NSArray *items = [sender representedObject];
    if (items == nil) {
        [rowHeights removeAllFloats];
    } else {
        for (id item in items)
            [rowHeights removeFloatForKey:item];
    }
    [rightSideController.noteOutlineView noteHeightOfRowsWithIndexesChanged:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [rightSideController.noteOutlineView numberOfRows])]];
}

- (void)toggleAutoResizeNoteRows:(id)sender {
    mwcFlags.autoResizeNoteRows = (0 == mwcFlags.autoResizeNoteRows);
    if (mwcFlags.autoResizeNoteRows) {
        [rowHeights removeAllFloats];
        [rightSideController.noteOutlineView noteHeightOfRowsWithIndexesChanged:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [rightSideController.noteOutlineView numberOfRows])]];
    } else {
        [self autoSizeNoteRows:nil];
    }
}

- (void)menuNeedsUpdate:(NSMenu *)menu {
    NSMenuItem *item = nil;
    [menu removeAllItems];
    if ([menu isEqual:[leftSideController.thumbnailTableView menu]]) {
        NSInteger row = [leftSideController.thumbnailTableView clickedRow];
        if (row != -1) {
            item = [menu addItemWithTitle:NSLocalizedString(@"Copy", @"Menu item title") action:@selector(copyPage:) target:self];
            [item setRepresentedObject:[NSIndexSet indexSetWithIndex:row]];
        }
    } else if ([menu isEqual:[leftSideController.findTableView menu]]) {
        NSIndexSet *rowIndexes = [leftSideController.findTableView selectedRowIndexes];
        NSInteger row = [leftSideController.findTableView clickedRow];
        if (row != -1) {
            if ([rowIndexes containsIndex:row] == NO)
                rowIndexes = [NSIndexSet indexSetWithIndex:row];
            NSArray *selections = [[leftSideController.findArrayController arrangedObjects] objectsAtIndexes:rowIndexes];
            item = [menu addItemWithTitle:NSLocalizedString(@"Select", @"Menu item title") action:@selector(selectSelections:) target:self];
            [item setRepresentedObject:selections];
            if ([pdfView hideNotes] == NO && [[self pdfDocument] allowsNotes]) {
                item = [menu addItemWithTitle:NSLocalizedString(@"New Circle", @"Menu item title") action:@selector(addAnnotationsForSelections:) target:self tag:SKCircleNote];
                [item setRepresentedObject:selections];
                item = [menu addItemWithTitle:NSLocalizedString(@"New Box", @"Menu item title") action:@selector(addAnnotationsForSelections:) target:self tag:SKSquareNote];
                [item setRepresentedObject:selections];
                item = [menu addItemWithTitle:NSLocalizedString(@"New Highlight", @"Menu item title") action:@selector(addAnnotationsForSelections:) target:self tag:SKHighlightNote];
                [item setRepresentedObject:selections];
                item = [menu addItemWithTitle:NSLocalizedString(@"New Underline", @"Menu item title") action:@selector(addAnnotationsForSelections:) target:self tag:SKUnderlineNote];
                [item setRepresentedObject:selections];
                item = [menu addItemWithTitle:NSLocalizedString(@"New Strike Out", @"Menu item title") action:@selector(addAnnotationsForSelections:) target:self tag:SKStrikeOutNote];
                [item setRepresentedObject:selections];
            }
        }
    } else if ([menu isEqual:[leftSideController.groupedFindTableView menu]]) {
        NSIndexSet *rowIndexes = [leftSideController.groupedFindTableView selectedRowIndexes];
        NSInteger row = [leftSideController.groupedFindTableView clickedRow];
        if (row != -1) {
            if ([rowIndexes containsIndex:row] == NO)
                rowIndexes = [NSIndexSet indexSetWithIndex:row];
            NSArray *selections = [[[leftSideController.groupedFindArrayController arrangedObjects] objectsAtIndexes:rowIndexes] valueForKeyPath:@"@unionOfArrays.matches"];
            item = [menu addItemWithTitle:NSLocalizedString(@"Select", @"Menu item title") action:@selector(selectSelections:) target:self];
            [item setRepresentedObject:selections];
            if ([pdfView hideNotes] == NO && [[self pdfDocument] allowsNotes]) {
                item = [menu addItemWithTitle:NSLocalizedString(@"New Circle", @"Menu item title") action:@selector(addAnnotationsForSelections:) target:self tag:SKCircleNote];
                [item setRepresentedObject:selections];
                item = [menu addItemWithTitle:NSLocalizedString(@"New Box", @"Menu item title") action:@selector(addAnnotationsForSelections:) target:self tag:SKSquareNote];
                [item setRepresentedObject:selections];
                item = [menu addItemWithTitle:NSLocalizedString(@"New Highlight", @"Menu item title") action:@selector(addAnnotationsForSelections:) target:self tag:SKHighlightNote];
                [item setRepresentedObject:selections];
                item = [menu addItemWithTitle:NSLocalizedString(@"New Underline", @"Menu item title") action:@selector(addAnnotationsForSelections:) target:self tag:SKUnderlineNote];
                [item setRepresentedObject:selections];
                item = [menu addItemWithTitle:NSLocalizedString(@"New Strike Out", @"Menu item title") action:@selector(addAnnotationsForSelections:) target:self tag:SKStrikeOutNote];
                [item setRepresentedObject:selections];
            }
        }
    } else if ([menu isEqual:[rightSideController.snapshotTableView menu]]) {
        NSInteger row = [rightSideController.snapshotTableView clickedRow];
        if (row != -1) {
            SKSnapshotWindowController *controller = [[rightSideController.snapshotArrayController arrangedObjects] objectAtIndex:row];
            item = [menu addItemWithTitle:NSLocalizedString(@"Delete", @"Menu item title") action:@selector(deleteSnapshot:) target:self];
            [item setRepresentedObject:controller];
            item = [menu addItemWithTitle:NSLocalizedString(@"Show", @"Menu item title") action:@selector(showSnapshot:) target:self];
            [item setRepresentedObject:controller];
            if ([[controller window] isVisible]) {
                item = [menu addItemWithTitle:NSLocalizedString(@"Hide", @"Menu item title") action:@selector(hideSnapshot:) target:self];
                [item setRepresentedObject:controller];
            }
        }
    } else if ([menu isEqual:[rightSideController.noteOutlineView menu]]) {
        NSArray *items;
        NSIndexSet *rowIndexes = [rightSideController.noteOutlineView selectedRowIndexes];
        NSInteger row = [rightSideController.noteOutlineView clickedRow];
        if (row != -1) {
            if ([rowIndexes containsIndex:row] == NO)
                rowIndexes = [NSIndexSet indexSetWithIndex:row];
            items = [rightSideController.noteOutlineView itemsAtRowIndexes:rowIndexes];
            
            if ([self outlineView:rightSideController.noteOutlineView canDeleteItems:items]) {
                item = [menu addItemWithTitle:NSLocalizedString(@"Delete", @"Menu item title") action:@selector(deleteNotes:) target:self];
                [item setRepresentedObject:items];
            }
            if ([self outlineView:rightSideController.noteOutlineView canCopyItems:items]) {
                item = [menu addItemWithTitle:NSLocalizedString(@"Copy", @"Menu item title") action:@selector(copyNotes:) target:self];
                [item setRepresentedObject:items];
            }
            if ([pdfView hideNotes] == NO && [items count] == 1) {
                PDFAnnotation *annotation = [[self noteItems:items] lastObject];
                if ([annotation isEditable]) {
                    if ([(PDFAnnotation *)[items lastObject] type] == nil) {
                        if ([[(SKNoteText *)[items lastObject] note] isNote]) {
                            item = [menu addItemWithTitle:[NSLocalizedString(@"Edit", @"Menu item title") stringByAppendingEllipsis] action:@selector(editNoteTextFromTable:) target:self];
                            [item setRepresentedObject:annotation];
                        }
                    } else if ([[rightSideController.noteOutlineView tableColumnWithIdentifier:NOTE_COLUMNID] isHidden]) {
                        item = [menu addItemWithTitle:[NSLocalizedString(@"Edit", @"Menu item title") stringByAppendingEllipsis] action:@selector(editThisAnnotation:) target:pdfView];
                        [item setRepresentedObject:annotation];
                    } else {
                        item = [menu addItemWithTitle:NSLocalizedString(@"Edit", @"Menu item title") action:@selector(editNoteFromTable:) target:self];
                        [item setRepresentedObject:annotation];
                        item = [menu addItemWithTitle:[NSLocalizedString(@"Edit", @"Menu item title") stringByAppendingEllipsis] action:@selector(editThisAnnotation:) target:pdfView];
                        [item setRepresentedObject:annotation];
                        [item setKeyEquivalentModifierMask:NSAlternateKeyMask];
                        [item setAlternate:YES];
                    }
                }
                if ([pdfView hideNotes] == NO && [[self pdfDocument] allowsNotes]) {
                    if ([pdfView activeAnnotation] == annotation) {
                        item = [menu addItemWithTitle:NSLocalizedString(@"Deselect", @"Menu item title") action:@selector(deselectNote:) target:self];
                        [item setRepresentedObject:annotation];
                    } else {
                        item = [menu addItemWithTitle:NSLocalizedString(@"Select", @"Menu item title") action:@selector(selectNote:) target:self];
                        [item setRepresentedObject:annotation];
                    }
                    item = [menu addItemWithTitle:NSLocalizedString(@"Show", @"Menu item title") action:@selector(revealNote:) target:self];
                    [item setRepresentedObject:annotation];
                }
            }
            if ([menu numberOfItems] > 0)
                [menu addItem:[NSMenuItem separatorItem]];
            item = [menu addItemWithTitle:[items count] == 1 ? NSLocalizedString(@"Auto Size Row", @"Menu item title") : NSLocalizedString(@"Auto Size Rows", @"Menu item title") action:@selector(autoSizeNoteRows:) target:self];
            [item setRepresentedObject:items];
            item = [menu addItemWithTitle:[items count] == 1 ? NSLocalizedString(@"Undo Auto Size Row", @"Menu item title") : NSLocalizedString(@"Undo Auto Size Rows", @"Menu item title") action:@selector(resetHeightOfNoteRows:) target:self];
            [item setRepresentedObject:items];
            [item setKeyEquivalentModifierMask:NSAlternateKeyMask];
            [item setAlternate:YES];
            [menu addItemWithTitle:NSLocalizedString(@"Auto Size All", @"Menu item title") action:@selector(autoSizeNoteRows:) target:self];
            item = [menu addItemWithTitle:NSLocalizedString(@"Undo Auto Size All", @"Menu item title") action:@selector(resetHeightOfNoteRows:) target:self];
            [item setKeyEquivalentModifierMask:NSAlternateKeyMask];
            [item setAlternate:YES];
            [menu addItemWithTitle:NSLocalizedString(@"Automatically Resize", @"Menu item title") action:@selector(toggleAutoResizeNoteRows:) target:self];
        }
    }
}

#pragma mark NSControl delegate protocol

- (void)controlTextDidBeginEditing:(NSNotification *)note {
    if ([[note object] isEqual:rightSideController.noteOutlineView]) {
        if (mwcFlags.isEditingTable == NO && mwcFlags.isEditingPDF == NO)
            [[self document] objectDidBeginEditing:(id)self];
        mwcFlags.isEditingTable = YES;
    }
}

- (void)controlTextDidEndEditing:(NSNotification *)note {
    if ([[note object] isEqual:rightSideController.noteOutlineView]) {
        if (mwcFlags.isEditingTable && mwcFlags.isEditingPDF == NO)
            [[self document] objectDidEndEditing:(id)self];
        mwcFlags.isEditingTable = NO;
    }
}

- (void)setDocument:(NSDocument *)document {
    if ([self document] && document == nil && (mwcFlags.isEditingPDF || mwcFlags.isEditingTable)) {
        if ([self commitEditing] == NO)
            [self discardEditing];
        if (mwcFlags.isEditingPDF || mwcFlags.isEditingTable)
            [[self document] objectDidEndEditing:(id)self];
        mwcFlags.isEditingPDF = mwcFlags.isEditingTable = NO;
    }
    [super setDocument:document];
}

#pragma mark NSEditor protocol

- (void)discardEditing {
    [rightSideController.noteOutlineView abortEditing];
    [pdfView discardEditing];
    // when using abortEditing the control does not call the controlTextDidEndEditing: delegate method
    if (mwcFlags.isEditingTable || mwcFlags.isEditingPDF)
        [[self document] objectDidEndEditing:(id)self];
    mwcFlags.isEditingTable = NO;
    mwcFlags.isEditingPDF = NO;
}

- (BOOL)commitEditing {
    if ([pdfView editTextField])
        return [pdfView commitEditing];
    if ([rightSideController.noteOutlineView editedRow] != -1)
        return [[rightSideController.noteOutlineView window] makeFirstResponder:rightSideController.noteOutlineView];
    return YES;
}

- (void)commitEditingWithDelegate:(id)delegate didCommitSelector:(SEL)didCommitSelector contextInfo:(void *)contextInfo {
    BOOL didCommit = [self commitEditing];
    if (delegate && didCommitSelector) {
        // - (void)editor:(id)editor didCommit:(BOOL)didCommit contextInfo:(void *)contextInfo
        NSInvocation *invocation = [NSInvocation invocationWithTarget:delegate selector:didCommitSelector];
        [invocation setArgument:&self atIndex:2];
        [invocation setArgument:&didCommit atIndex:3];
        [invocation setArgument:&contextInfo atIndex:4];
        [invocation invoke];
    }
}

#pragma mark SKNoteTypeSheetController delegate protocol

- (void)noteTypeSheetControllerNoteTypesDidChange:(SKNoteTypeSheetController *)controller {
    [self updateNoteFilterPredicate];
}

- (NSWindow *)windowForNoteTypeSheetController:(SKNoteTypeSheetController *)controller {
    return [self window];
}

#pragma mark SKPDFView delegate protocol

- (void)PDFViewOpenPDF:(PDFView *)sender forRemoteGoToAction:(PDFActionRemoteGoTo *)action {
    NSURL *fileURL = [action URL];
    SKDocumentController *sdc = [NSDocumentController sharedDocumentController];
    Class docClass = [sdc documentClassForContentsOfURL:fileURL];
    if (docClass) {
        [sdc openDocumentWithContentsOfURL:fileURL display:YES completionHandler:^(NSDocument *document, BOOL documentWasAlreadyOpen, NSError *error) {
            if ([document isPDFDocument]) {
                NSUInteger pageIndex = [action pageIndex];
                if (pageIndex < [[document pdfDocument] pageCount]) {
                    PDFPage *page = [[document pdfDocument] pageAtIndex:pageIndex];
                    PDFDestination *dest = [[[PDFDestination alloc] initWithPage:page atPoint:[action point]] autorelease];
                    [[(SKMainDocument *)document pdfView] goToDestination:dest];
                }
            } else if (document == nil && error && [error isUserCancelledError] == NO) {
                [self presentError:error];
            }
        }];
    } else if (fileURL) {
        // fall back to just opening the file and ignore the destination
        [[NSWorkspace sharedWorkspace] openURL:fileURL];
    }
}

- (void)PDFViewWillClickOnLink:(PDFView *)sender withURL:(NSURL *)url {
    SKDocumentController *sdc = [NSDocumentController sharedDocumentController];
    if ([url isFileURL] && [sdc documentClassForContentsOfURL:url]) {
        [sdc openDocumentWithContentsOfURL:url display:YES completionHandler:^(NSDocument *document, BOOL documentWasAlreadyOpen, NSError *error){
            if (document == nil && error && [error isUserCancelledError] == NO)
                [self presentError:error];
        }];
    } else {
        [[NSWorkspace sharedWorkspace] openURL:url];
    }
}

- (void)PDFViewPerformFind:(PDFView *)sender {
    [self showFindBar];
}

- (void)PDFViewPerformGoToPage:(PDFView *)sender {
    [self doGoToPage:sender];
}

- (void)PDFViewPerformPrint:(PDFView *)sender {
    [[self document] printDocument:sender];
}

- (void)PDFViewDidBeginEditing:(PDFView *)sender {
    if (mwcFlags.isEditingPDF == NO && mwcFlags.isEditingTable == NO)
        [[self document] objectDidBeginEditing:(id)self];
    mwcFlags.isEditingPDF = YES;
}

- (void)PDFViewDidEndEditing:(PDFView *)sender {
    if (mwcFlags.isEditingPDF && mwcFlags.isEditingTable == NO)
        [[self document] objectDidEndEditing:(id)self];
    mwcFlags.isEditingPDF = NO;
}

- (void)PDFView:(PDFView *)sender editAnnotation:(PDFAnnotation *)annotation {
    [self showNote:annotation];
}

- (void)PDFView:(PDFView *)sender showSnapshotAtPageNumber:(NSInteger)pageNum forRect:(NSRect)rect scaleFactor:(CGFloat)scaleFactor autoFits:(BOOL)autoFits {
    [self showSnapshotAtPageNumber:pageNum forRect:rect scaleFactor:scaleFactor autoFits:autoFits];
}

- (void)PDFViewExitFullscreen:(PDFView *)sender {
    [self exitFullscreen];
}

- (void)PDFViewToggleContents:(PDFView *)sender {
    [self toggleLeftSidePane:sender];
}

#pragma mark NSSplitView delegate protocol

- (BOOL)splitView:(NSSplitView *)sender canCollapseSubview:(NSView *)subview {
    if ([sender isEqual:splitView]) {
        return [subview isEqual:centerContentView] == NO;
    } else if ([sender isEqual:pdfSplitView]) {
        return [subview isEqual:secondaryPdfView];
    }
    return NO;
}

- (BOOL)splitView:(NSSplitView *)sender shouldCollapseSubview:(NSView *)subview forDoubleClickOnDividerAtIndex:(NSInteger)dividerIndex {
    if ([sender isEqual:splitView]) {
        if ([subview isEqual:leftSideContentView])
            [self toggleLeftSidePane:sender];
        else if ([subview isEqual:rightSideContentView])
            [self toggleRightSidePane:sender];
    } else if ([sender isEqual:pdfSplitView]) {
        if ([subview isEqual:secondaryPdfView]) {
            CGFloat position = [pdfSplitView maxPossiblePositionOfDividerAtIndex:dividerIndex];
            if ([pdfSplitView isSubviewCollapsed:secondaryPdfView]) {
                if (lastSplitPDFHeight <= 0.0)
                    lastSplitPDFHeight = DEFAULT_SPLIT_PANE_HEIGHT;
                if (lastSplitPDFHeight > NSHeight([pdfContentView frame]))
                    lastSplitPDFHeight = floor(0.5 * NSHeight([pdfView frame]));
                position -= lastSplitPDFHeight;
            } else {
                lastSplitPDFHeight = NSHeight([secondaryPdfView frame]);
            }
            [pdfSplitView setPosition:position ofDividerAtIndex:dividerIndex animate:YES];
        }
    }
    return NO;
}

- (BOOL)splitView:(NSSplitView *)sender shouldHideDividerAtIndex:(NSInteger)dividerIndex {
    return [sender isEqual:splitView];
}

- (CGFloat)splitView:(NSSplitView *)sender constrainMaxCoordinate:(CGFloat)proposedMax ofSubviewAt:(NSInteger)dividerIndex {
    if ([sender respondsToSelector:@selector(isAnimating)] && [(SKSplitView *)sender isAnimating])
        return proposedMax;
    else if ([sender isEqual:splitView] && dividerIndex == 1)
        return proposedMax - MIN_SIDE_PANE_WIDTH;
    else if ([sender isEqual:pdfSplitView])
        return proposedMax - MIN_SPLIT_PANE_HEIGHT;
    return proposedMax;
}

- (CGFloat)splitView:(NSSplitView *)sender constrainMinCoordinate:(CGFloat)proposedMin ofSubviewAt:(NSInteger)dividerIndex {
    if ([sender respondsToSelector:@selector(isAnimating)] && [(SKSplitView *)sender isAnimating])
        return proposedMin;
    else if ([sender isEqual:splitView] && dividerIndex == 0)
        return proposedMin + MIN_SIDE_PANE_WIDTH;
    return proposedMin;
}

- (void)splitView:(NSSplitView *)sender resizeSubviewsWithOldSize:(NSSize)oldSize {
    if ([sender isEqual:splitView]) {
        NSView *leftView = [[sender subviews] objectAtIndex:0];
        NSView *mainView = [[sender subviews] objectAtIndex:1];
        NSView *rightView = [[sender subviews] objectAtIndex:2];
        BOOL leftCollapsed = [sender isSubviewCollapsed:leftView];
        BOOL rightCollapsed = [sender isSubviewCollapsed:rightView];
        NSSize leftSize = [leftView frame].size;
        NSSize mainSize = [mainView frame].size;
        NSSize rightSize = [rightView frame].size;
        CGFloat contentWidth = NSWidth([sender frame]);
        
        if (leftCollapsed)
            leftSize.width = 0.0;
        else
            contentWidth -= [sender dividerThickness];
        if (rightCollapsed)
            rightSize.width = 0.0;
        else
            contentWidth -= [sender dividerThickness];
        
        if (contentWidth < leftSize.width + rightSize.width) {
            CGFloat oldContentWidth = oldSize.width;
            if (leftCollapsed == NO)
                oldContentWidth -= [sender dividerThickness];
            if (rightCollapsed == NO)
                oldContentWidth -= [sender dividerThickness];
            CGFloat resizeFactor = contentWidth / oldContentWidth;
            leftSize.width = floor(resizeFactor * leftSize.width);
            rightSize.width = floor(resizeFactor * rightSize.width);
        }
        
        mainSize.width = contentWidth - leftSize.width - rightSize.width;
        leftSize.height = rightSize.height = mainSize.height = NSHeight([sender frame]);
        if (leftCollapsed == NO)
            [leftView setFrameSize:leftSize];
        if (rightCollapsed == NO)
            [rightView setFrameSize:rightSize];
        [mainView setFrameSize:mainSize];
    }
    [sender adjustSubviews];
}

- (void)splitViewDidResizeSubviews:(NSNotification *)notification {
    id sender = [notification object];
    if (([sender isEqual:splitView] || sender == nil) && [[self window] frameAutosaveName] && mwcFlags.settingUpWindow == 0) {
        CGFloat leftWidth = [splitView isSubviewCollapsed:leftSideContentView] ? 0.0 : NSWidth([leftSideContentView frame]);
        CGFloat rightWidth = [splitView isSubviewCollapsed:rightSideContentView] ? 0.0 : NSWidth([rightSideContentView frame]);
        [[NSUserDefaults standardUserDefaults] setFloat:leftWidth forKey:SKLeftSidePaneWidthKey];
        [[NSUserDefaults standardUserDefaults] setFloat:rightWidth forKey:SKRightSidePaneWidthKey];
    }
}

#pragma mark UI validation

static NSArray *allMainDocumentPDFViews() {
    NSMutableArray *array = [NSMutableArray array];
    for (id document in [[NSDocumentController sharedDocumentController] documents]) {
        if ([document respondsToSelector:@selector(pdfView)])
            [array addObject:[document pdfView]];
    }
    return array;
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem {
    SEL action = [menuItem action];
    if (action == @selector(createNewNote:)) {
        BOOL isMarkup = [menuItem tag] == SKHighlightNote || [menuItem tag] == SKUnderlineNote || [menuItem tag] == SKStrikeOutNote;
        return [self interactionMode] != SKPresentationMode && [[self pdfDocument] allowsNotes] && ([pdfView toolMode] == SKTextToolMode || [pdfView toolMode] == SKNoteToolMode) && [pdfView hideNotes] == NO && (isMarkup == NO || [[pdfView currentSelection] hasCharacters]);
    } else if (action == @selector(editNote:)) {
        PDFAnnotation *annotation = [pdfView activeAnnotation];
        return [self interactionMode] != SKPresentationMode && [annotation isSkimNote] && ([annotation isEditable]);
    } else if (action == @selector(alignLeft:) || action == @selector(alignRight:) || action == @selector(alignCenter:)) {
        PDFAnnotation *annotation = [pdfView activeAnnotation];
        return [self interactionMode] != SKPresentationMode && [annotation isSkimNote] && ([annotation isEditable]) && [annotation isText];
    } else if (action == @selector(toggleHideNotes:)) {
        if ([pdfView hideNotes])
            [menuItem setTitle:NSLocalizedString(@"Show Notes", @"Menu item title")];
        else
            [menuItem setTitle:NSLocalizedString(@"Hide Notes", @"Menu item title")];
        return YES;
    } else if (action == @selector(changeDisplaySinglePages:)) {
        [menuItem setState:([pdfView displayMode] & kPDFDisplayTwoUp) == (PDFDisplayMode)[menuItem tag] ? NSOnState : NSOffState];
        return [self interactionMode] != SKPresentationMode && [[self pdfDocument] isLocked] == NO;
    } else if (action == @selector(changeDisplayContinuous:)) {
        [menuItem setState:([pdfView displayMode] & kPDFDisplaySinglePageContinuous) == (PDFDisplayMode)[menuItem tag] ? NSOnState : NSOffState];
        return [self interactionMode] != SKPresentationMode && [[self pdfDocument] isLocked] == NO;
    } else if (action == @selector(changeDisplayMode:)) {
        [menuItem setState:[pdfView displayMode] == (PDFDisplayMode)[menuItem tag] ? NSOnState : NSOffState];
        return [self interactionMode] != SKPresentationMode && [[self pdfDocument] isLocked] == NO;
    } else if (action == @selector(toggleDisplayAsBook:)) {
        [menuItem setState:[pdfView displaysAsBook] ? NSOnState : NSOffState];
        return [self interactionMode] != SKPresentationMode && [[self pdfDocument] isLocked] == NO && ([pdfView displayMode] == kPDFDisplayTwoUp || [pdfView displayMode] == kPDFDisplayTwoUpContinuous);
    } else if (action == @selector(toggleDisplayPageBreaks:)) {
        [menuItem setState:[pdfView displaysPageBreaks] ? NSOnState : NSOffState];
        return [self interactionMode] != SKPresentationMode && [[self pdfDocument] isLocked] == NO;
    } else if (action == @selector(changeDisplayBox:)) {
        [menuItem setState:[pdfView displayBox] == (PDFDisplayBox)[menuItem tag] ? NSOnState : NSOffState];
        return [self interactionMode] != SKPresentationMode && [[self pdfDocument] isLocked] == NO;
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
    } else if (action == @selector(doGoToPage:)) {
        return [[self pdfDocument] isLocked] == NO;
    } else if (action == @selector(allGoToNextPage:)) {
        return [[allMainDocumentPDFViews() valueForKeyPath:@"@min.canGoToNextPage"] boolValue];
    } else if (action == @selector(allGoToPreviousPage:)) {
        return [[allMainDocumentPDFViews() valueForKeyPath:@"@min.canGoToPreviousPage"] boolValue];
    } else if (action == @selector(allGoToFirstPage:)) {
        return [[allMainDocumentPDFViews() valueForKeyPath:@"@min.canGoToFirstPage"] boolValue];
    } else if (action == @selector(allGoToLastPage:)) {
        return [[allMainDocumentPDFViews() valueForKeyPath:@"@min.canGoToLastPage"] boolValue];
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
    } else if (action == @selector(markPage:)) {
        return [[self pdfDocument] isLocked] == NO;
    } else if (action == @selector(doZoomIn:)) {
        return [self interactionMode] != SKPresentationMode && [pdfView canZoomIn];
    } else if (action == @selector(doZoomOut:)) {
        return [self interactionMode] != SKPresentationMode && [pdfView canZoomOut];
    } else if (action == @selector(doZoomToActualSize:)) {
        return [[self pdfDocument] isLocked] == NO && ([pdfView autoScales] || fabs([pdfView scaleFactor] - 1.0 ) > 0.01);
    } else if (action == @selector(doZoomToPhysicalSize:)) {
        return [self interactionMode] != SKPresentationMode && [[self pdfDocument] isLocked] == NO && ([pdfView autoScales] || fabs([pdfView physicalScaleFactor] - 1.0 ) > 0.01);
    } else if (action == @selector(doZoomToSelection:)) {
        return [self interactionMode] != SKPresentationMode && [[self pdfDocument] isLocked] == NO && NSIsEmptyRect([pdfView currentSelectionRect]) == NO;
    } else if (action == @selector(doZoomToFit:)) {
        return [self interactionMode] != SKPresentationMode && [[self pdfDocument] isLocked] == NO && [pdfView autoScales] == NO;
    } else if (action == @selector(alternateZoomToFit:)) {
        PDFDisplayMode displayMode = [pdfView displayMode];
        if (displayMode == kPDFDisplaySinglePage || displayMode == kPDFDisplayTwoUp) {
            [menuItem setTitle:NSLocalizedString(@"Zoom To Width", @"Menu item title")];
        } else {
            [menuItem setTitle:NSLocalizedString(@"Zoom To Height", @"Menu item title")];
        }
        return [self interactionMode] != SKPresentationMode && [[self pdfDocument] isLocked] == NO;
    } else if (action == @selector(doAutoScale:)) {
        return [[self pdfDocument] isLocked] == NO && [pdfView autoScales] == NO;
    } else if (action == @selector(toggleAutoScale:)) {
        [menuItem setState:[pdfView autoScales] ? NSOnState : NSOffState];
        return [[self pdfDocument] isLocked] == NO;
    } else if (action == @selector(rotateRight:) || action == @selector(rotateLeft:) || action == @selector(rotateAllRight:) || action == @selector(rotateAllLeft:)) {
        return [[self pdfDocument] isLocked] == NO;
    } else if (action == @selector(cropAll:) || action == @selector(crop:) || action == @selector(autoCropAll:) || action == @selector(smartAutoCropAll:)) {
        return [self interactionMode] != SKPresentationMode && [[self pdfDocument] isLocked] == NO;
    } else if (action == @selector(autoSelectContent:)) {
        return [self interactionMode] != SKPresentationMode && [[self pdfDocument] isLocked] == NO && [pdfView toolMode] == SKSelectToolMode;
    } else if (action == @selector(takeSnapshot:)) {
        return [[self pdfDocument] isLocked] == NO;
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
        return [self interactionMode] != SKPresentationMode;
    } else if (action == @selector(changeLeftSidePaneState:)) {
        [menuItem setState:mwcFlags.leftSidePaneState == (SKLeftSidePaneState)[menuItem tag] ? (([leftSideController.findTableView window] || [leftSideController.groupedFindTableView window]) ? NSMixedState : NSOnState) : NSOffState];
        return (SKLeftSidePaneState)[menuItem tag] == SKSidePaneStateThumbnail || [[pdfView document] outlineRoot];
    } else if (action == @selector(changeRightSidePaneState:)) {
        [menuItem setState:mwcFlags.rightSidePaneState == (SKRightSidePaneState)[menuItem tag] ? NSOnState : NSOffState];
        return [self interactionMode] != SKPresentationMode;
    } else if (action == @selector(toggleSplitPDF:)) {
        if ([(NSView *)secondaryPdfView window])
            [menuItem setTitle:NSLocalizedString(@"Hide Split PDF", @"Menu item title")];
        else
            [menuItem setTitle:NSLocalizedString(@"Show Split PDF", @"Menu item title")];
        return [self interactionMode] != SKPresentationMode;
    } else if (action == @selector(toggleStatusBar:)) {
        if ([statusBar isVisible])
            [menuItem setTitle:NSLocalizedString(@"Hide Status Bar", @"Menu item title")];
        else
            [menuItem setTitle:NSLocalizedString(@"Show Status Bar", @"Menu item title")];
        return [self interactionMode] == SKNormalMode || [self interactionMode] == SKFullScreenMode;
    } else if (action == @selector(searchPDF:)) {
        return [self interactionMode] != SKPresentationMode;
    } else if (action == @selector(toggleFullscreen:)) {
        if ([self interactionMode] == SKFullScreenMode || [self interactionMode] == SKLegacyFullScreenMode)
            [menuItem setTitle:NSLocalizedString(@"Remove Full Screen", @"Menu item title")];
        else
            [menuItem setTitle:NSLocalizedString(@"Full Screen", @"Menu item title")];
        return [self canEnterFullscreen] || [self canExitFullscreen];
    } else if (action == @selector(togglePresentation:)) {
        if ([self interactionMode] == SKPresentationMode)
            [menuItem setTitle:NSLocalizedString(@"Remove Presentation", @"Menu item title")];
        else
            [menuItem setTitle:NSLocalizedString(@"Presentation", @"Menu item title")];
        return [self canEnterPresentation] || [self canExitPresentation];
    } else if (action == @selector(getInfo:)) {
        return [self interactionMode] != SKPresentationMode;
    } else if (action == @selector(performFit:)) {
        return [self interactionMode] == SKNormalMode && [[self pdfDocument] isLocked] == NO;
    } else if (action == @selector(password:)) {
        return [self interactionMode] != SKPresentationMode && [[self pdfDocument] permissionsStatus] != kPDFDocumentPermissionsOwner;
    } else if (action == @selector(toggleReadingBar:)) {
        if ([[self pdfView] hasReadingBar])
            [menuItem setTitle:NSLocalizedString(@"Hide Reading Bar", @"Menu item title")];
        else
            [menuItem setTitle:NSLocalizedString(@"Show Reading Bar", @"Menu item title")];
        return [self interactionMode] != SKPresentationMode && [[self pdfDocument] isLocked] == NO;
    } else if (action == @selector(savePDFSettingToDefaults:)) {
        if ([self interactionMode] == SKFullScreenMode || [self interactionMode] == SKLegacyFullScreenMode)
            [menuItem setTitle:NSLocalizedString(@"Use Current View Settings as Default for Full Screen", @"Menu item title")];
        else
            [menuItem setTitle:NSLocalizedString(@"Use Current View Settings as Default", @"Menu item title")];
        return [self interactionMode] != SKPresentationMode && [[self pdfDocument] isLocked] == NO;
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
    } else if (action == @selector(toggleAutoResizeNoteRows:)) {
        [menuItem setState:mwcFlags.autoResizeNoteRows ? NSOnState : NSOffState];
        return YES;
    } else if (action == @selector(performFindPanelAction:)) {
        if ([self interactionMode] == SKPresentationMode)
            return NO;
        switch ([menuItem tag]) {
            case NSFindPanelActionShowFindPanel:
                return YES;
            case NSFindPanelActionNext:
            case NSFindPanelActionPrevious:
                return YES;
            case NSFindPanelActionSetFindString:
                return [[[self pdfView] currentSelection] hasCharacters];
            default:
                return NO;
        }
    }
    return YES;
}

#pragma mark Notification handlers

#define MAX_HIGHLIGHTS 5

- (void)handlePageChangedNotification:(NSNotification *)notification {
    // When the PDFView is changing scale, or when view settings change when switching fullscreen modes, 
    // a lot of wrong page change notifications may be send, which we better ignore. 
    // Full screen switching and zooming should not change the current page anyway.
    if ([pdfView isZooming] || mwcFlags.isSwitchingFullScreen || [pdfView needsRewind])
        return;
    
    PDFPage *page = [pdfView currentPage];
    NSUInteger pageIndex = [page pageIndex];
    
    if ([lastViewedPages count] == 0) {
        [lastViewedPages addPointer:(void *)pageIndex];
    } else if ((NSUInteger)[lastViewedPages pointerAtIndex:0] != pageIndex) {
        [lastViewedPages insertPointer:(void *)pageIndex atIndex:0];
        if ([lastViewedPages count] > MAX_HIGHLIGHTS)
            [lastViewedPages setCount:MAX_HIGHLIGHTS];
    }
    [self updateThumbnailHighlights];
    [self updateTocHighlights];
    
    [self updatePageNumber];
    [self updatePageLabel];
    
    [self updateOutlineSelection];
    [self updateNoteSelection];
    [self updateThumbnailSelection];
    
    if (beforeMarkedPageIndex != NSNotFound && [[pdfView currentPage] pageIndex] != markedPageIndex)
        beforeMarkedPageIndex = NSNotFound;
    
    [self synchronizeWindowTitleWithDocumentName];
    [self updateLeftStatus];
    if ([[NSUserDefaults standardUserDefaults] boolForKey:SKDisplayPageBoundsKey])
        [self updateRightStatus];

    if ([self interactionMode] == SKPresentationMode && [self presentationNotesDocument]) {
        PDFDocument *pdfDoc = [[self presentationNotesDocument] pdfDocument];
        NSInteger offset = [self presentationNotesOffset];
        pageIndex = (NSUInteger)MAX(0, MIN((NSInteger)[pdfDoc pageCount], (NSInteger)pageIndex + offset));
        if ([self presentationNotesDocument] == [self document])
            [[presentationPreview pdfView] goToPage:[pdfDoc pageAtIndex:pageIndex]];
        else
            [[self presentationNotesDocument] setCurrentPage:[pdfDoc pageAtIndex:pageIndex]];
    }
    
    mwcFlags.recentInfoNeedsUpdate = 1;
}

- (void)handleDisplayBoxChangedNotification:(NSNotification *)notification {
    [self allThumbnailsNeedUpdate];
    if ([[NSUserDefaults standardUserDefaults] boolForKey:SKDisplayPageBoundsKey])
        [self updateRightStatus];
}

- (void)handleSelectionOrMagnificationChangedNotification:(NSNotification *)notification {
    [self updateRightStatus];
}

- (void)handleDarkModeChangedNotification:(NSNotification *)notification {
    NSColor *backgroundColor = nil;
    switch (interactionMode) {
        case SKNormalMode:
            backgroundColor = [PDFView defaultBackgroundColor];
            break;
        case SKFullScreenMode:
        case SKLegacyFullScreenMode:
            backgroundColor = [PDFView defaultFullScreenBackgroundColor];
            break;
        default:
            return;
    }
    [pdfView setBackgroundColor:backgroundColor];
    [secondaryPdfView setBackgroundColor:backgroundColor];
}

- (void)handleApplicationWillTerminateNotification:(NSNotification *)notification {
    if ([self interactionMode] == SKPresentationMode || [self interactionMode] == SKLegacyFullScreenMode)
        [self exitFullscreen];
}

- (void)handleApplicationDidResignActiveNotification:(NSNotification *)notification {
    if ([self interactionMode] == SKPresentationMode && [[NSUserDefaults standardUserDefaults] boolForKey:SKUseNormalLevelForPresentationKey] == NO) {
        [[self window] setLevel:NSNormalWindowLevel];
    }
}

- (void)handleApplicationWillBecomeActiveNotification:(NSNotification *)notification {
    if ([self interactionMode] == SKPresentationMode && [[NSUserDefaults standardUserDefaults] boolForKey:SKUseNormalLevelForPresentationKey] == NO) {
        [[self window] setLevel:NSPopUpMenuWindowLevel];
    }
}

- (void)setHasOutline:(BOOL)hasOutline forAnnotation:(PDFAnnotation *)annotation {
    SKNoteOutlineView *ov = rightSideController.noteOutlineView;
    NSInteger row = [ov rowForItem:annotation];
    NSUInteger column = [ov columnWithIdentifier:TYPE_COLUMNID];
    if (row != -1 && column != NSNotFound) {
        NSTableCellView *view = [ov viewAtColumn:column row:row makeIfNecessary:NO];
        if (view)
            [(SKAnnotationTypeImageView *)[view imageView] setHasOutline:hasOutline];
    }
}

- (void)handleDidChangeActiveAnnotationNotification:(NSNotification *)notification {
    PDFAnnotation *annotation = [pdfView activeAnnotation];
    SKNoteOutlineView *ov = rightSideController.noteOutlineView;
    
    [self setHasOutline:NO forAnnotation:[[notification userInfo] objectForKey:SKPDFViewAnnotationKey]];
    
    if ([[self window] isMainWindow])
        [self updateUtilityPanel];
    if ([annotation isSkimNote]) {
        if ([[self selectedNotes] containsObject:annotation] == NO) {
            [ov selectRowIndexes:[NSIndexSet indexSetWithIndex:[ov rowForItem:annotation]] byExtendingSelection:NO];
        }
        [self setHasOutline:YES forAnnotation:annotation];
    } else {
        [ov deselectAll:self];
    }
    [ov reloadData];
    if ([[NSUserDefaults standardUserDefaults] boolForKey:SKDisplayNoteBoundsKey])
        [self updateRightStatus];
}

- (void)handleDidAddAnnotationNotification:(NSNotification *)notification {
    PDFAnnotation *annotation = [[notification userInfo] objectForKey:SKPDFViewAnnotationKey];
    PDFPage *page = [[notification userInfo] objectForKey:SKPDFViewPageKey];
    
    if ([annotation isSkimNote] && mwcFlags.addOrRemoveNotesInBulk == 0) {
        mwcFlags.updatingNoteSelection = 1;
        [[self mutableArrayValueForKey:NOTES_KEY] addObject:annotation];
        [rightSideController.noteArrayController rearrangeObjects]; // doesn't seem to be done automatically
        mwcFlags.updatingNoteSelection = 0;
        [rightSideController.noteOutlineView reloadData];
    }
    if (page) {
        [self updateThumbnailAtPageIndex:[page pageIndex]];
        for (SKSnapshotWindowController *wc in snapshots) {
            if ([wc isPageVisible:page])
                [self snapshotNeedsUpdate:wc];
        }
        [secondaryPdfView setNeedsDisplayForAnnotation:annotation onPage:page];
    }
}

- (void)handleDidRemoveAnnotationNotification:(NSNotification *)notification {
    PDFAnnotation *annotation = [[notification userInfo] objectForKey:SKPDFViewAnnotationKey];
    PDFPage *page = [[notification userInfo] objectForKey:SKPDFViewPageKey];
    
    if ([annotation isSkimNote] && mwcFlags.addOrRemoveNotesInBulk == 0) {
        if ([[self selectedNotes] containsObject:annotation])
            [rightSideController.noteOutlineView deselectAll:self];
        
        [[self windowControllerForNote:annotation] close];
        
        mwcFlags.updatingNoteSelection = 1;
        [[self mutableArrayValueForKey:NOTES_KEY] removeObject:annotation];
        [rightSideController.noteArrayController rearrangeObjects]; // doesn't seem to be done automatically
        mwcFlags.updatingNoteSelection = 0;
        [rightSideController.noteOutlineView reloadData];
    }
    if (page) {
        [self updateThumbnailAtPageIndex:[page pageIndex]];
        for (SKSnapshotWindowController *wc in snapshots) {
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
        for (SKSnapshotWindowController *wc in snapshots) {
            if ([wc isPageVisible:oldPage] || [wc isPageVisible:newPage])
                [self snapshotNeedsUpdate:wc];
        }
        [secondaryPdfView requiresDisplay];
        if (RUNNING(10_9))
            [pdfView requiresDisplay];
    }
    
    [rightSideController.noteArrayController rearrangeObjects];
    [rightSideController.noteOutlineView reloadData];
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

- (void)handleWillRemoveDocumentNotification:(NSNotification *)notification {
    if ([[notification userInfo] objectForKey:SKDocumentControllerDocumentKey] == presentationNotesDocument)
        [self setPresentationNotesDocument:nil];
}

- (void)handleNoteViewFrameDidChangeNotification:(NSNotification *)notification {
    if (mwcFlags.autoResizeNoteRows) {
        [rowHeights removeAllFloats];
        [rightSideController.noteOutlineView noteHeightOfRowsWithIndexesChanged:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [rightSideController.noteOutlineView numberOfRows])]];
    }
}

- (void)handleScrollerDidScrollNotification:(NSNotification *)notification {
    SKScroller *scroller = [notification object];
    if ([[pdfView document] isLocked] == NO ||
        scroller == [leftSideController.thumbnailTableView.enclosingScrollView verticalScroller] ||
        scroller == [presentationSheetController verticalScroller]) {
        [[self thumbnails] makeObjectsPerformSelector:@selector(dirtyIfNeeded)];
    }
}

#pragma mark Observer registration

- (void)registerForNotifications {
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    // Application
    [nc addObserver:self selector:@selector(handleApplicationWillTerminateNotification:) 
                             name:SKApplicationStartsTerminatingNotification object:NSApp];
    [nc addObserver:self selector:@selector(handleDarkModeChangedNotification:)
                             name:SKDarkModeChangedNotification object:NSApp];
    [nc addObserver:self selector:@selector(handleApplicationDidResignActiveNotification:) 
                             name:NSApplicationDidResignActiveNotification object:NSApp];
    [nc addObserver:self selector:@selector(handleApplicationWillBecomeActiveNotification:) 
                             name:NSApplicationWillBecomeActiveNotification object:NSApp];
    // PDFView
    [nc addObserver:self selector:@selector(handlePageChangedNotification:) 
                             name:PDFViewPageChangedNotification object:pdfView];
    [nc addObserver:self selector:@selector(handleSelectionOrMagnificationChangedNotification:) 
                             name:SKPDFViewSelectionChangedNotification object:pdfView];
    [nc addObserver:self selector:@selector(handleSelectionOrMagnificationChangedNotification:) 
                             name:SKPDFViewMagnificationChangedNotification object:pdfView];
    [nc addObserver:self selector:@selector(handleDisplayBoxChangedNotification:) 
                             name:PDFViewDisplayBoxChangedNotification object:pdfView];
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
    // View
    [nc addObserver:self selector:@selector(handleNoteViewFrameDidChangeNotification:) 
                             name:NSViewFrameDidChangeNotification object:[rightSideController.noteOutlineView enclosingScrollView]];
    //  UndoManager
    [nc addObserver:self selector:@selector(observeUndoManagerCheckpoint:) 
                             name:NSUndoManagerCheckpointNotification object:[[self document] undoManager]];
    //  SKDocumentController
    [nc addObserver:self selector:@selector(handleWillRemoveDocumentNotification:) 
                             name:SKDocumentControllerWillRemoveDocumentNotification object:nil];
    
    // SKScroller
    [nc addObserver:self selector:@selector(handleScrollerDidScrollNotification:)
               name:SKScrollerDidScrollNotification object:nil];
}

@end
