//
//  SKMainWindowController_Actions.m
//  Skim
//
//  Created by Christiaan Hofman on 2/14/09.
/*
 This software is Copyright (c) 2009-2020
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

#import "SKMainWindowController_Actions.h"
#import "SKMainWindowController_FullScreen.h"
#import "SKLeftSideViewController.h"
#import "SKRightSideViewController.h"
#import "SKMainToolbarController.h"
#import <Quartz/Quartz.h>
#import <SkimNotes/SkimNotes.h>
#import "SKStringConstants.h"
#import "SKPDFView.h"
#import "SKSecondaryPDFView.h"
#import "PDFAnnotation_SKExtensions.h"
#import "PDFPage_SKExtensions.h"
#import "NSImage_SKExtensions.h"
#import "NSString_SKExtensions.h"
#import "NSGeometry_SKExtensions.h"
#import "SKTextFieldSheetController.h"
#import "SKPresentationOptionsSheetController.h"
#import "SKProgressController.h"
#import "SKInfoWindowController.h"
#import "SKMainDocument.h"
#import "SKStatusBar.h"
#import "SKSideWindow.h"
#import "SKImageToolTipWindow.h"
#import "SKSplitView.h"
#import "SKLineInspector.h"
#import "NSEvent_SKExtensions.h"
#import "NSWindowController_SKExtensions.h"
#import "NSPointerArray_SKExtensions.h"
#import "NSDocument_SKExtensions.h"
#import "NSResponder_SKExtensions.h"
#import "SKFindController.h"
#import "PDFView_SKExtensions.h"
#import "SKSnapshotWindowController.h"
#import "PDFDocument_SKExtensions.h"
#import "NSColor_SKExtensions.h"
#import "NSScroller_SKExtensions.h"
#import "SKNoteText.h"
#import "SKNoteWindowController.h"
#import "SKNoteTextView.h"
#import "SKMainTouchBarController.h"
#import "SKThumbnailItem.h"
#import "SKFloatMapTable.h"
#import "PDFSelection_SKExtensions.h"

#define STATUSBAR_HEIGHT 22.0

#define PAGE_BREAK_MARGIN 4.0

#define DEFAULT_SIDE_PANE_WIDTH 250.0
#define MIN_SIDE_PANE_WIDTH 100.0

#define DEFAULT_SPLIT_PDF_FACTOR 0.3


#if SDK_BEFORE(10_13)
@interface PDFView (SKHighSierraDeclarations)
@property (nonatomic) NSEdgeInsets pageBreakMargins;
@end
#endif

@interface SKMainWindowController (SKPrivateUI)
- (void)updateLineInspector;
- (void)updateNoteFilterPredicate;
- (void)updateSnapshotFilterPredicate;
@end

@implementation SKMainWindowController (Actions)

- (IBAction)changeColor:(id)sender{
    PDFAnnotation *annotation = [pdfView activeAnnotation];
    if (mwcFlags.updatingColor == 0 && [self hasOverview] == NO && [annotation isSkimNote]) {
        BOOL isFill = [colorAccessoryView state] == NSOnState && [annotation hasInteriorColor];
        BOOL isText = [textColorAccessoryView state] == NSOnState && [annotation isText];
        BOOL isShift = ([NSEvent standardModifierFlags] & NSShiftKeyMask) != 0;
        mwcFlags.updatingColor = 1;
        [annotation setColor:[sender color] alternate:isFill || isText updateDefaults:isShift];
        mwcFlags.updatingColor = 0;
    }
}

- (IBAction)changeFont:(id)sender{
    PDFAnnotation *annotation = [pdfView activeAnnotation];
    if (mwcFlags.updatingFont == 0 && [self hasOverview] == NO && [annotation isSkimNote] && [annotation isText]) {
        NSFont *font = [sender convertFont:[(PDFAnnotationFreeText *)annotation font]];
        mwcFlags.updatingFont = 1;
        [(PDFAnnotationFreeText *)annotation setFont:font];
        mwcFlags.updatingFont = 0;
    }
}

- (IBAction)changeAttributes:(id)sender{
    PDFAnnotation *annotation = [pdfView activeAnnotation];
    if (mwcFlags.updatingFontAttributes == 0 && mwcFlags.updatingColor == 0 && [self hasOverview] == NO && [annotation isSkimNote] && [annotation isText]) {
        NSColor *color = [(PDFAnnotationFreeText *)annotation fontColor];
        NSColor *newColor = [[sender convertAttributes:[NSDictionary dictionaryWithObjectsAndKeys:color, NSForegroundColorAttributeName, nil]] valueForKey:NSForegroundColorAttributeName];
        if ([newColor isEqual:color] == NO) {
            mwcFlags.updatingFontAttributes = 1;
            [(PDFAnnotationFreeText *)annotation setFontColor:newColor];
            mwcFlags.updatingFontAttributes = 0;
        }
    }
}

- (IBAction)alignLeft:(id)sender {
    PDFAnnotation *annotation = [pdfView activeAnnotation];
    if ([self hasOverview] == NO && [annotation isSkimNote] && [annotation isText]) {
        [(PDFAnnotationFreeText *)annotation setAlignment:NSLeftTextAlignment];
    }
}

- (IBAction)alignRight:(id)sender {
    PDFAnnotation *annotation = [pdfView activeAnnotation];
    if ([self hasOverview] == NO && [annotation isSkimNote] && [annotation isText]) {
        [(PDFAnnotationFreeText *)annotation setAlignment:NSRightTextAlignment];
    }
}

- (IBAction)alignCenter:(id)sender {
    PDFAnnotation *annotation = [pdfView activeAnnotation];
    if ([self hasOverview] == NO && [annotation isSkimNote] && [annotation isText]) {
        [(PDFAnnotationFreeText *)annotation setAlignment:NSCenterTextAlignment];
    }
}

- (void)changeLineAttribute:(id)sender {
    SKLineChangeAction action = [sender currentLineChangeAction];
    PDFAnnotation *annotation = [pdfView activeAnnotation];
    if (mwcFlags.updatingLine == 0 && [self hasOverview] == NO && [annotation hasBorder]) {
        mwcFlags.updatingLine = 1;
        switch (action) {
            case SKLineChangeActionLineWidth:
                [annotation setLineWidth:[sender lineWidth]];
                break;
            case SKLineChangeActionStyle:
                [annotation setBorderStyle:[(SKLineInspector *)sender style]];
                break;
            case SKLineChangeActionDashPattern:
                [annotation setDashPattern:[sender dashPattern]];
                break;
            case SKLineChangeActionStartLineStyle:
                if ([annotation isLine])
                    [(PDFAnnotationLine *)annotation setStartLineStyle:[sender startLineStyle]];
                break;
            case SKLineChangeActionEndLineStyle:
                if ([annotation isLine])
                    [(PDFAnnotationLine *)annotation setEndLineStyle:[sender endLineStyle]];
                break;
            case SKNoLineChangeAction:
                break;
        }
        mwcFlags.updatingLine = 0;
        // in case one property changes another, e.g. when adding a dashPattern the borderStyle can change
        [self updateLineInspector];
    }
}

- (IBAction)createNewNote:(id)sender{
    if ([pdfView hideNotes] == NO && [[self pdfDocument] allowsNotes])
        [pdfView addAnnotationWithType:[sender tag]];
    else NSBeep();
}

- (void)addNoteFromPanel:(id)sender {
    if ([self hasOverview] == NO) {
        [self createNewNote:sender];
        [[self window] makeKeyWindow];
        [[self window] makeFirstResponder:[self pdfView]];
    }
}

- (void)selectSelectedNote:(id)sender{
    if ([pdfView hideNotes] == NO) {
        NSIndexSet *rowIndexes = [sender selectedRowIndexes];
        if ([rowIndexes count] == 1) {
            id item = [sender itemAtRow:[rowIndexes firstIndex]];
            PDFAnnotation *annotation = nil;
            if ([(PDFAnnotation *)item type]) {
                annotation = item;
                NSInteger column = [sender clickedColumn];
                if (column != -1) {
                    NSString *colID = [[[sender tableColumns] objectAtIndex:column] identifier];
                    if ([colID isEqualToString:@"color"])
                        [[NSColorPanel sharedColorPanel] orderFront:nil];
                }
            } else {
                annotation = [(SKNoteText *)item note];
                if ([annotation isNote]) {
                    [self showNote:annotation];
                    SKNoteWindowController *noteController = (SKNoteWindowController *)[self windowControllerForNote:annotation];
                    [[noteController window] makeFirstResponder:[noteController textView]];
                    [[noteController textView] selectAll:nil];
                }
            }
            [pdfView scrollAnnotationToVisible:annotation];
            [pdfView setActiveAnnotation:annotation];
        }
    } else NSBeep();
}

- (void)goToSelectedOutlineItem:(id)sender {
    PDFOutline *outlineItem = [leftSideController.tocOutlineView itemAtRow:[leftSideController.tocOutlineView selectedRow]];
    if ([outlineItem destination])
        [pdfView goToDestination:[outlineItem destination]];
    else if ([outlineItem action])
        [pdfView performAction:[outlineItem action]];
}

- (void)goToSelectedFindResults:(id)sender {
    if ([sender clickedRow] != -1)
        [self selectFindResultHighlight:NSDirectSelection];
}

- (void)toggleSelectedSnapshots:(id)sender {
    // there should only be a single snapshot
    NSInteger row = [rightSideController.snapshotTableView selectedRow];
    if (row == -1)
        return;
    SKSnapshotWindowController *controller = [[rightSideController.snapshotArrayController arrangedObjects] objectAtIndex:row];
    if ([[controller window] isVisible])
        [controller miniaturize];
    else
        [controller deminiaturize];
}

- (IBAction)editNote:(id)sender{
    if ([pdfView hideNotes] == NO) {
        [pdfView editActiveAnnotation:sender];
    } else NSBeep();
}

- (IBAction)toggleHideNotes:(id)sender{
    NSNumber *wasHidden = [NSNumber numberWithBool:[pdfView hideNotes]];
    [notes setValue:wasHidden forKey:@"shouldDisplay"];
    [notes setValue:wasHidden forKey:@"shouldPrint"];
    [pdfView setHideNotes:[pdfView hideNotes] == NO];
    [touchBarController handleToolModeChangedNotification:nil];
}

- (IBAction)takeSnapshot:(id)sender{
    [pdfView takeSnapshot:sender];
}

- (IBAction)changeDisplaySinglePages:(id)sender {
    PDFDisplayMode displayMode = ([pdfView displayMode] & ~kPDFDisplayTwoUp) | [sender tag];
    if ([pdfView displaysHorizontally] && displayMode == kPDFDisplaySinglePageContinuous)
        displayMode = kPDFDisplayHorizontalContinuous;
    [pdfView setExtendedDisplayModeAndRewind:displayMode];
}

- (IBAction)changeDisplayContinuous:(id)sender {
    PDFDisplayMode displayMode = ([pdfView displayMode] & ~kPDFDisplaySinglePageContinuous) | [sender tag];
    if ([pdfView displaysHorizontally] && displayMode == kPDFDisplaySinglePageContinuous)
        displayMode = kPDFDisplayHorizontalContinuous;
    [pdfView setExtendedDisplayModeAndRewind:displayMode];
}

- (IBAction)changeDisplayMode:(id)sender {
    [pdfView setExtendedDisplayModeAndRewind:[sender tag]];
}

- (IBAction)changeDisplayDirection:(id)sender {
    [pdfView setDisplaysHorizontallyAndRewind:[sender tag]];
}

- (IBAction)toggleDisplaysRTL:(id)sender {
    [pdfView setDisplaysRightToLeftAndRewind:[pdfView displaysRightToLeft] == NO];
}

- (IBAction)toggleDisplaysAsBook:(id)sender {
    [pdfView setDisplaysAsBookAndRewind:[pdfView displaysAsBook] == NO];
}

- (IBAction)toggleDisplayPageBreaks:(id)sender {
    [pdfView setDisplaysPageBreaks:[pdfView displaysPageBreaks] == NO];
}

- (IBAction)changeDisplayBox:(id)sender {
    [pdfView setDisplayBoxAndRewind:[sender tag]];
}

- (IBAction)doGoToNextPage:(id)sender {
    [pdfView goToNextPage:sender];
}

- (IBAction)doGoToPreviousPage:(id)sender {
    [pdfView goToPreviousPage:sender];
}


- (IBAction)doGoToFirstPage:(id)sender {
    [pdfView goToFirstPage:sender];
}

- (IBAction)doGoToLastPage:(id)sender {
    [pdfView goToLastPage:sender];
}

static NSArray *allMainDocumentPDFViews() {
    NSMutableArray *array = [NSMutableArray array];
    for (id document in [[NSDocumentController sharedDocumentController] documents]) {
        if ([document respondsToSelector:@selector(pdfView)])
            [array addObject:[document pdfView]];
    }
    return array;
}

- (IBAction)allGoToNextPage:(id)sender {
    [allMainDocumentPDFViews() makeObjectsPerformSelector:@selector(goToNextPage:) withObject:sender];
}

- (IBAction)allGoToPreviousPage:(id)sender {
    [allMainDocumentPDFViews() makeObjectsPerformSelector:@selector(goToPreviousPage:) withObject:sender];
}

- (IBAction)allGoToFirstPage:(id)sender {
    [allMainDocumentPDFViews() makeObjectsPerformSelector:@selector(goToFirstPage:) withObject:sender];
}

- (IBAction)allGoToLastPage:(id)sender {
    [allMainDocumentPDFViews() makeObjectsPerformSelector:@selector(goToLastPage:) withObject:sender];
}

- (IBAction)doGoToPage:(id)sender {
    SKTextFieldSheetController *pageSheetController = [[[SKTextFieldSheetController alloc] initWithWindowNibName:@"PageSheet"] autorelease];
    
    [(NSComboBox *)[pageSheetController textField] addItemsWithObjectValues:pageLabels];
    [pageSheetController setStringValue:[self pageLabel]];
    
    [pageSheetController beginSheetModalForWindow:[self window] completionHandler:^(NSInteger result) {
            if (result == NSModalResponseOK)
                [self setPageLabel:[pageSheetController stringValue]];
        }];
}

- (IBAction)doGoBack:(id)sender {
    [pdfView goBack:sender];
}

- (IBAction)doGoForward:(id)sender {
    [pdfView goForward:sender];
}

- (IBAction)goToMarkedPage:(id)sender {
    PDFDocument *pdfDoc = [pdfView document];
    NSUInteger currentPageIndex = [[pdfView currentPage] pageIndex];
    if (markedPageIndex == NSNotFound || [pdfDoc isLocked] || [pdfDoc pageCount] == 0) {
        NSBeep();
    } else if (beforeMarkedPageIndex != NSNotFound) {
        [pdfView goToPageAtIndex:MIN(beforeMarkedPageIndex, [pdfDoc pageCount] - 1) point:beforeMarkedPagePoint];
    } else if (currentPageIndex != markedPageIndex) {
        NSUInteger lastPageIndex = [pdfView currentPageIndexAndPoint:&beforeMarkedPagePoint rotated:NULL];
        [pdfView goToPageAtIndex:MIN(markedPageIndex, [pdfDoc pageCount] - 1) point:markedPagePoint];
        beforeMarkedPageIndex = lastPageIndex;
    }
}

- (IBAction)markPage:(id)sender {
    if (markedPageIndex != NSNotFound)
        [(SKThumbnailItem *)[overviewView itemAtIndex:markedPageIndex] setMarked:NO];
    markedPageIndex = [pdfView currentPageIndexAndPoint:&markedPagePoint rotated:NULL];
    beforeMarkedPageIndex = NSNotFound;
    [(SKThumbnailItem *)[overviewView itemAtIndex:markedPageIndex] setMarked:YES];
}

- (IBAction)doZoomIn:(id)sender {
    [pdfView zoomIn:sender];
}

- (IBAction)doZoomOut:(id)sender {
    [pdfView zoomOut:sender];
}

- (IBAction)doZoomToPhysicalSize:(id)sender {
    [pdfView setPhysicalScaleFactor:1.0];
}

- (IBAction)doZoomToActualSize:(id)sender {
    [pdfView setScaleFactor:1.0];
}

- (IBAction)doZoomToSelection:(id)sender {
    NSRect selRect = [pdfView currentSelectionRect];
    PDFPage *page = [pdfView currentPage];
    if (NSIsEmptyRect(selRect) == NO && page)
        [pdfView zoomToRect:selRect onPage:page];
    else NSBeep();
}

- (IBAction)doZoomToFit:(id)sender {
    [pdfView setAutoScales:YES];
    [pdfView setAutoScales:NO];
    if (RUNNING(10_12) && 0 == ([pdfView displayMode] & kPDFDisplaySinglePageContinuous)) {
        CGFloat pageHeight = NSHeight([[pdfView currentPage] boundsForBox:[pdfView displayBox]]);
        if ([pdfView displaysPageBreaks])
            pageHeight += 2.0 * PAGE_BREAK_MARGIN;
        CGFloat scaleFactor = fmax([pdfView minimumScaleFactor], NSHeight([pdfView frame]) / pageHeight);
        if (scaleFactor < [pdfView scaleFactor])
            [pdfView setScaleFactor:scaleFactor];
    }
}

// @@ Horizontal layout
- (IBAction)alternateZoomToFit:(id)sender {
    PDFDisplayMode displayMode = [pdfView extendedDisplayMode];
    NSRect frame = [pdfView frame];
    PDFPage *page = [pdfView currentPage];
    NSRect pageRect = [page boundsForBox:[pdfView displayBox]];
    CGFloat scrollerWidth = 0.0;
    CGFloat scaleFactor;
    NSUInteger pageCount = [[pdfView document] pageCount];
    if ([pdfView displaysPageBreaks]) {
        if (RUNNING_BEFORE(10_13)) {
            pageRect = NSInsetRect(pageRect, -PAGE_BREAK_MARGIN, -PAGE_BREAK_MARGIN);
        } else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wpartial-availability"
            NSEdgeInsets margins = [pdfView pageBreakMargins];
#pragma clang diagnostic pop
            pageRect = NSInsetRect(pageRect, -margins.bottom, -margins.left);
            pageRect.size.width += margins.right - margins.left;
            pageRect.size.height += margins.top - margins.bottom;
        }
    }
    if ((displayMode & kPDFDisplaySinglePageContinuous) == 0) {
        // zoom to width
        NSUInteger numCols = (displayMode == kPDFDisplayTwoUp && pageCount > 1 && ([pdfView displaysAsBook] == NO || pageCount > 2)) ? 2 : 1;
        if (NSWidth(frame) * ( NSHeight(pageRect) ) > NSHeight(frame) * numCols * ( NSWidth(pageRect) ))
            scrollerWidth =  [NSScroller effectiveScrollerWidth];
        scaleFactor = ( NSWidth(frame) - scrollerWidth ) / ( NSWidth(pageRect) );
    } else {
        // zoom to height
        NSUInteger numRows = pageCount;
        if (displayMode == kPDFDisplayTwoUpContinuous)
            numRows = [pdfView displaysAsBook] ? (1 + pageCount) / 2 : 1 + pageCount / 2;
        if (NSHeight(frame) * ( NSWidth(pageRect) ) > NSWidth(frame) * numRows * ( NSHeight(pageRect) ))
            scrollerWidth = [NSScroller effectiveScrollerWidth];
        scaleFactor = ( NSHeight(frame) - scrollerWidth ) / ( NSHeight(pageRect) );
    }
    [pdfView setScaleFactor:scaleFactor];
    [pdfView layoutDocumentView];
    [pdfView goToRect:pageRect onPage:page];
}

- (IBAction)doAutoScale:(id)sender {
    [pdfView setAutoScales:YES];
}

- (IBAction)toggleAutoScale:(id)sender {
    if ([self interactionMode] == SKPresentationMode)
        [pdfView toggleAutoActualSize:sender];
    else
        [pdfView setAutoScales:[pdfView autoScales] == NO];
}

- (void)rotatePageAtIndex:(NSUInteger)idx by:(NSInteger)rotation {
    NSUndoManager *undoManager = [[self document] undoManager];
    [[undoManager prepareWithInvocationTarget:self] rotatePageAtIndex:idx by:-rotation];
    [undoManager setActionName:NSLocalizedString(@"Rotate Page", @"Undo action name")];
    [[self document] undoableActionIsDiscardable];
    
    PDFPage *page = [[pdfView document] pageAtIndex:idx];
    [page setRotation:[page rotation] + rotation];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:SKPDFPageBoundsDidChangeNotification 
            object:[pdfView document] userInfo:[NSDictionary dictionaryWithObjectsAndKeys:SKPDFPageActionRotate, SKPDFPageActionKey, page, SKPDFPagePageKey, nil]];
}

- (void)rotateAllBy:(NSInteger)rotation {
    NSUndoManager *undoManager = [[self document] undoManager];
    [[undoManager prepareWithInvocationTarget:self] rotateAllBy:-rotation];
    [undoManager setActionName:NSLocalizedString(@"Rotate", @"Undo action name")];
    [[self document] undoableActionIsDiscardable];
    
    [pdfView setNeedsRewind:YES];
    
    NSInteger i, count = [[pdfView document] pageCount];
    for (i = 0; i < count; i++)
        [[[pdfView document] pageAtIndex:i] setRotation:[[[pdfView document] pageAtIndex:i] rotation] + rotation];
    [pdfView layoutDocumentView];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:SKPDFPageBoundsDidChangeNotification 
            object:[pdfView document] userInfo:[NSDictionary dictionaryWithObjectsAndKeys:SKPDFPageActionRotate, SKPDFPageActionKey, nil]];
}

- (IBAction)rotateRight:(id)sender {
    [self rotatePageAtIndex:[[pdfView currentPage] pageIndex] by:90];
}

- (IBAction)rotateLeft:(id)sender {
    [self rotatePageAtIndex:[[pdfView currentPage] pageIndex] by:-90];
}

- (IBAction)rotateAllRight:(id)sender {
    [self rotateAllBy:90];
}

- (IBAction)rotateAllLeft:(id)sender {
    [self rotateAllBy:-90];
}

- (void)cropPageAtIndex:(NSUInteger)anIndex toRect:(NSRect)rect {
    NSRect oldRect = [[[pdfView document] pageAtIndex:anIndex] boundsForBox:kPDFDisplayBoxCropBox];
    NSUndoManager *undoManager = [[self document] undoManager];
    [[undoManager prepareWithInvocationTarget:self] cropPageAtIndex:anIndex toRect:oldRect];
    [undoManager setActionName:NSLocalizedString(@"Crop Page", @"Undo action name")];
    [[self document] undoableActionIsDiscardable];
    
    PDFPage *page = [[pdfView document] pageAtIndex:anIndex];
    rect = NSIntersectionRect(rect, [page boundsForBox:kPDFDisplayBoxMediaBox]);
    [page setBounds:rect forBox:kPDFDisplayBoxCropBox];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:SKPDFPageBoundsDidChangeNotification 
            object:[pdfView document] userInfo:[NSDictionary dictionaryWithObjectsAndKeys:SKPDFPageActionCrop, SKPDFPageActionKey, page, SKPDFPagePageKey, nil]];
    
    // make sure we show the crop box
    [pdfView setDisplayBox:kPDFDisplayBoxCropBox];
}

- (IBAction)crop:(id)sender {
    NSRect rect = NSIntegralRect([pdfView currentSelectionRect]);
    PDFPage *page = [pdfView currentSelectionPage] ?: [pdfView currentPage];
    if (NSIsEmptyRect(rect))
        rect = [page foregroundBox];
    [self cropPageAtIndex:[page pageIndex] toRect:rect];
}

- (void)cropPagesToRects:(NSPointerArray *)rects {
    [pdfView setNeedsRewind:YES];
    
    NSInteger i, count = [[pdfView document] pageCount];
    NSInteger rectCount = [rects count];
    NSPointerArray *oldRects = [NSPointerArray rectPointerArray];
    for (i = 0; i < count; i++) {
        PDFPage *page = [[pdfView document] pageAtIndex:i];
        NSRect rect = NSIntersectionRect([rects rectAtIndex:i % rectCount], [page boundsForBox:kPDFDisplayBoxMediaBox]);
        NSRect oldRect = [page boundsForBox:kPDFDisplayBoxCropBox];
        [oldRects addPointer:&oldRect];
        [page setBounds:rect forBox:kPDFDisplayBoxCropBox];
    }
    
    NSUndoManager *undoManager = [[self document] undoManager];
    [[undoManager prepareWithInvocationTarget:self] cropPagesToRects:oldRects];
    [undoManager setActionName:NSLocalizedString(@"Crop", @"Undo action name")];
    [[self document] undoableActionIsDiscardable];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:SKPDFPageBoundsDidChangeNotification 
            object:[pdfView document] userInfo:[NSDictionary dictionaryWithObjectsAndKeys:SKPDFPageActionCrop, SKPDFPageActionKey, nil]];
    
    // make sure we show the crop box
    [pdfView setDisplayBox:kPDFDisplayBoxCropBox];
}

- (IBAction)cropAll:(id)sender {
    NSRect rect[2] = {NSIntegralRect([pdfView currentSelectionRect]), NSZeroRect};
    NSPointerArray *rectArray = [NSPointerArray rectPointerArray];
    BOOL emptySelection = NSIsEmptyRect(rect[0]);
    
    if (emptySelection) {
        NSInteger i, j, count = [[pdfView document] pageCount];
        rect[0] = rect[1] = NSZeroRect;
        
        if (count == 0)
            return;
        
        [self beginProgressSheetWithMessage:[NSLocalizedString(@"Cropping Pages", @"Message for progress sheet") stringByAppendingEllipsis] maxValue:MIN(18, count)];
        
        if (count == 1) {
            rect[0] = [[[pdfView document] pageAtIndex:0] foregroundBox];
            [self incrementProgressSheet];
        } else if (count < 19) {
            for (i = 0; i < count; i++) {
                rect[i % 2] = NSUnionRect(rect[i % 2], [[[pdfView document] pageAtIndex:i] foregroundBox]);
                [self incrementProgressSheet];
            }
        } else {
            NSInteger start[3] = {1, (count - 5) / 2, count - 6};
            for (j = 0; j < 3; j++) {
                for (i = start[j]; i < start[j] + 6; i++) {
                    rect[i % 2] = NSUnionRect(rect[i % 2], [[[pdfView document] pageAtIndex:i] foregroundBox]);
                    [self incrementProgressSheet];
                }
            }
        }
        CGFloat w = fmax(NSWidth(rect[0]), NSWidth(rect[1]));
        CGFloat h = fmax(NSHeight(rect[0]), NSHeight(rect[1]));
        for (j = 0; j < 2; j++)
            rect[j] = NSMakeRect(floor(NSMidX(rect[j]) - 0.5 * w), floor(NSMidY(rect[j]) - 0.5 * h), w, h);
        [rectArray addPointer:rect];
        [rectArray addPointer:rect + 1];
    } else {
        [rectArray addPointer:rect];
    }
    
    [self cropPagesToRects:rectArray];
    [pdfView setCurrentSelectionRect:NSZeroRect];
	
    if (emptySelection)
        [self dismissProgressSheet];
}

- (IBAction)autoCropAll:(id)sender {
    NSPointerArray *rectArray = [NSPointerArray rectPointerArray];
    PDFDocument *pdfDoc = [pdfView document];
    NSInteger i, iMax = [[pdfView document] pageCount];
    
    [self beginProgressSheetWithMessage:[NSLocalizedString(@"Cropping Pages", @"Message for progress sheet") stringByAppendingEllipsis] maxValue:iMax];
    
    for (i = 0; i < iMax; i++) {
        NSRect rect = [[pdfDoc pageAtIndex:i] foregroundBox];
        [rectArray addPointer:&rect];
        [self incrementProgressSheet];
        if (i && i % 10 == 0)
            [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
    }
    [self cropPagesToRects:rectArray];
	
    [self dismissProgressSheet];
}

- (IBAction)smartAutoCropAll:(id)sender {
    NSPointerArray *rectArray = [NSPointerArray rectPointerArray];
    PDFDocument *pdfDoc = [pdfView document];
    NSInteger i, iMax = [pdfDoc pageCount];
    NSSize size = NSZeroSize;
    
	[self beginProgressSheetWithMessage:[NSLocalizedString(@"Cropping Pages", @"Message for progress sheet") stringByAppendingEllipsis] maxValue:11 * iMax / 10];
    
    for (i = 0; i < iMax; i++) {
        NSRect bbox = [[pdfDoc pageAtIndex:i] foregroundBox];
        size.width = fmax(size.width, NSWidth(bbox));
        size.height = fmax(size.height, NSHeight(bbox));
        [self incrementProgressSheet];
        if (i && i % 10 == 0)
            [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
    }
    [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
    for (i = 0; i < iMax; i++) {
        PDFPage *page = [pdfDoc pageAtIndex:i];
        NSRect rect = [page foregroundBox];
        NSRect bounds = [page boundsForBox:kPDFDisplayBoxMediaBox];
        if (NSMinX(rect) - NSMinX(bounds) > NSMaxX(bounds) - NSMaxX(rect))
            rect.origin.x = NSMaxX(rect) - size.width;
        rect.origin.y = NSMaxY(rect) - size.height;
        rect.size = size;
        rect = SKConstrainRect(rect, bounds);
        [rectArray addPointer:&rect];
        if (i && i % 10 == 0) {
            [self incrementProgressSheet];
            if (i && i % 100 == 0)
                [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
        }
    }
    [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
    [self cropPagesToRects:rectArray];
	
    [self dismissProgressSheet];
}

- (IBAction)autoSelectContent:(id)sender {
    [pdfView autoSelectContent:sender];
}

- (IBAction)getInfo:(id)sender {
    [[SKInfoWindowController sharedInstance] showWindow:self];
}

- (IBAction)delete:(id)sender {
    [pdfView delete:sender];
}

- (IBAction)paste:(id)sender {
    [pdfView paste:sender];
}

- (IBAction)alternatePaste:(id)sender {
    [pdfView alternatePaste:sender];
}

- (IBAction)pasteAsPlainText:(id)sender {
    [pdfView pasteAsPlainText:sender];
}

- (IBAction)copy:(id)sender {
    [pdfView copy:sender];
}

- (IBAction)cut:(id)sender {
    [pdfView cut:sender];
}

- (IBAction)deselectAll:(id)sender {
    [pdfView deselectAll:sender];
}

- (IBAction)changeToolMode:(id)sender {
    [pdfView setToolMode:[sender tag]];
}

- (IBAction)changeAnnotationMode:(id)sender {
    [pdfView setToolMode:SKNoteToolMode];
    [pdfView setAnnotationMode:[sender tag]];
}

- (IBAction)statusBarClicked:(id)sender {
    [self updateRightStatus];
}

- (IBAction)toggleStatusBar:(id)sender {
    [[NSUserDefaults standardUserDefaults] setBool:(NO == [statusBar isVisible]) forKey:SKShowStatusBarKey];
    NSView *view = [self hasOverview] ? overviewContentView : splitView;
    [statusBar toggleBelowView:view animate:sender != nil];
}

- (IBAction)searchPDF:(id)sender {
    if ([self hasOverview]) {
        [self hideOverviewAnimating:YES completionHandler:^{ [self searchPDF:sender]; }];
        return;
    }
    if ([self leftSidePaneIsOpen] == NO)
        [self toggleLeftSidePane:sender];
    // workaround for an AppKit bug: when selecting immediately before the animation, the search fields does not display its text
    if ([splitView isAnimating])
        [splitView enqueueOperation:^{ [leftSideController.searchField selectText:self]; }];
    else
        [leftSideController.searchField selectText:self];
}

- (IBAction)filterNotes:(id)sender {
    if ([self hasOverview]) {
        [self hideOverviewAnimating:YES completionHandler:^{ [self filterNotes:sender]; }];
        return;
    }
    if ([self rightSidePaneIsOpen] == NO)
        [self toggleRightSidePane:sender];
    // workaround for an AppKit bug: when selecting immediately before the animation, the search fields does not display its text
    if ([splitView isAnimating])
        [splitView enqueueOperation:^{ [rightSideController.searchField selectText:self]; }];
    else
        [rightSideController.searchField selectText:self];
}

- (IBAction)search:(id)sender {
    
    PDFDocument *pdfDoc = [pdfView document];
    
    // cancel any previous find to remove those results, or else they stay around
    if ([pdfDoc isFinding])
        [pdfDoc cancelFindString];
    [pdfView setHighlightedSelections:nil];
    
    if ([[sender stringValue] isEqualToString:@""]) {
        
        if (mwcFlags.leftSidePaneState == SKSidePaneStateThumbnail)
            [self displayThumbnailViewAnimating:YES];
        else
            [self displayTocViewAnimating:YES];
    } else {
        NSInteger options = mwcFlags.caseInsensitiveSearch ? NSCaseInsensitiveSearch : 0;
        if (mwcFlags.wholeWordSearch) {
            NSScanner *scanner = [NSScanner scannerWithString:[sender stringValue]];
            NSMutableArray *words = [NSMutableArray array];
            NSString *word;
            [scanner setCharactersToBeSkipped:nil];
            while ([scanner isAtEnd] == NO) {
                if ('"' == [[scanner string] characterAtIndex:[scanner scanLocation]]) {
                    [scanner setScanLocation:[scanner scanLocation] + 1];
                    if ([scanner scanUpToString:@"\"" intoString:&word])
                        [words addObject:word];
                    if ([scanner isAtEnd] == NO)
                        [scanner setScanLocation:[scanner scanLocation] + 1];
                } else if ([scanner scanUpToCharactersFromSet:[NSCharacterSet whitespaceCharacterSet] intoString:&word]) {
                    [words addObject:word];
                }
                [scanner scanCharactersFromSet:[NSCharacterSet whitespaceCharacterSet] intoString:NULL];
            }
            [pdfDoc beginFindStrings:words withOptions:options];
        } else {
            [pdfDoc beginFindString:[sender stringValue] withOptions:options];
        }
        if (mwcFlags.findPaneState == SKFindPaneStateSingular)
            [self displayFindViewAnimating:YES];
        else
            [self displayGroupedFindViewAnimating:YES];
        
        NSPasteboard *findPboard = [NSPasteboard pasteboardWithName:NSFindPboard];
        [findPboard clearContents];
        [findPboard writeObjects:[NSArray arrayWithObjects:[sender stringValue], nil]];
    }
}

- (IBAction)searchNotes:(id)sender {
    if (mwcFlags.rightSidePaneState == SKSidePaneStateNote)
        [self updateNoteFilterPredicate];
    else
        [self updateSnapshotFilterPredicate];
    if ([[sender stringValue] length]) {
        NSPasteboard *findPboard = [NSPasteboard pasteboardWithName:NSFindPboard];
        [findPboard clearContents];
        [findPboard writeObjects:[NSArray arrayWithObjects:[sender stringValue], nil]];
    }
}

// @@ Horizontal layout

- (IBAction)performFit:(id)sender {
    if ([self interactionMode] != SKNormalMode) {
        NSBeep();
        return;
    }
    
    PDFDisplayMode displayMode = [[self pdfView] displayMode];
    BOOL horizontal = [[self pdfView] displaysHorizontally] && displayMode == kPDFDisplaySinglePageContinuous;
    CGFloat scaleFactor = [[self pdfView] scaleFactor];
    BOOL autoScales = [[self pdfView] autoScales];
    BOOL isSingleRow;
    
    if (displayMode == kPDFDisplaySinglePage || displayMode == kPDFDisplayTwoUp || horizontal)
        isSingleRow = YES;
    else if (displayMode == kPDFDisplaySinglePageContinuous || [[self pdfView] displaysAsBook])
        isSingleRow = [[[self pdfView] document] pageCount] <= 1;
    else
        isSingleRow = [[[self pdfView] document] pageCount] <= 2;
    
    NSRect frame = [[self window] frame];
    NSSize size, oldSize = [[self pdfView] frame].size;
    NSRect documentRect = [[[self pdfView] documentView] convertRect:[[[self pdfView] documentView] bounds] toView:nil];
    PDFPage *page = [[self pdfView] currentPage];
    NSRect pageRect = [page boundsForBox:[[self pdfView] displayBox]];
    
    if ([pdfView displaysPageBreaks]) {
        if (RUNNING_BEFORE(10_13)) {
            pageRect = NSInsetRect(pageRect, -PAGE_BREAK_MARGIN, -PAGE_BREAK_MARGIN);
        } else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wpartial-availability"
            NSEdgeInsets margins = [pdfView pageBreakMargins];
#pragma clang diagnostic pop
            pageRect = NSInsetRect(pageRect, -margins.bottom, -margins.left);
            pageRect.size.width += margins.right - margins.left;
            pageRect.size.height += margins.top - margins.bottom;
        }
    }
    
    // Calculate the new size for the pdfView
    size.width = NSWidth(documentRect);
    if (autoScales)
        size.width /= scaleFactor;
    if (isSingleRow) {
        size.height = NSHeight(documentRect);
        if (horizontal && [[[self pdfView] document] pageCount] > 1)
            size.width = NSWidth([[self pdfView] convertRect:pageRect fromPage:page]) + [NSScroller effectiveScrollerWidth];
    } else {
        size.height = NSHeight([[self pdfView] convertRect:pageRect fromPage:page]);
        size.width += [NSScroller effectiveScrollerWidth];
    }
    if (autoScales)
        size.height /= scaleFactor;
    
    // Calculate the new size for the window
    size.width = ceil(NSWidth(frame) + size.width - oldSize.width);
    size.height = ceil(NSHeight(frame) + size.height - oldSize.height);
    // Align the window frame from the old topleft point and constrain to the screen
    frame.origin.y = NSMaxY(frame) - size.height;
    frame.size = size;
    frame = [[self window] constrainFrameRect:frame toScreen:[[self window] screen] ?: [NSScreen mainScreen]];
    
    [[self window] setFrame:frame display:[[self window] isVisible]];
    
    if (displayMode == kPDFDisplaySinglePageContinuous || displayMode == kPDFDisplayTwoUpContinuous)
        [[self pdfView] goToRect:pageRect onPage:page];
}

- (IBAction)password:(id)sender {
    SKTextFieldSheetController *passwordSheetController = [[[SKTextFieldSheetController alloc] initWithWindowNibName:@"PasswordSheet"] autorelease];
    
    [passwordSheetController beginSheetModalForWindow:[self window] completionHandler:^(NSInteger result) {
            if (result == NSModalResponseOK) {
                [[passwordSheetController window] orderOut:nil];
                [[pdfView document] unlockWithPassword:[passwordSheetController stringValue]];
            }
        }];
}

- (IBAction)toggleReadingBar:(id)sender {
    [pdfView toggleReadingBar];
}

- (IBAction)togglePacer:(id)sender {
    if ([self interactionMode] != SKPresentationMode)
        [pdfView togglePacer];
}

- (IBAction)changePacerSpeed:(id)sender {
    NSInteger tag = [sender tag];
    if (tag == 0)
        [pdfView setPacerSpeed:[pdfView pacerSpeed] + 1.0];
    else if (tag == -1)
        [pdfView setPacerSpeed:fmax(1.0, [pdfView pacerSpeed] - 1.0)];
    else if (tag > 0)
        [pdfView setPacerSpeed:[[sender title] doubleValue]];
}

- (IBAction)savePDFSettingToDefaults:(id)sender {
    if ([self interactionMode] == SKNormalMode)
        [[NSUserDefaults standardUserDefaults] setObject:[self currentPDFSettings] forKey:SKDefaultPDFDisplaySettingsKey];
    else if ([self interactionMode] != SKPresentationMode)
        [[NSUserDefaults standardUserDefaults] setObject:[self currentPDFSettings] forKey:SKDefaultFullScreenPDFDisplaySettingsKey];
}

- (IBAction)chooseTransition:(id)sender {
    presentationSheetController = [[SKPresentationOptionsSheetController alloc] initForController:self];
    
    [presentationSheetController beginSheetModalForWindow:[self window] completionHandler:^(NSInteger result) {
            SKDESTROY(presentationSheetController);
        }];
}

- (IBAction)toggleCaseInsensitiveSearch:(id)sender {
    mwcFlags.caseInsensitiveSearch = (0 == mwcFlags.caseInsensitiveSearch);
    if ([[leftSideController.searchField stringValue] length])
        [self search:leftSideController.searchField];
    [[NSUserDefaults standardUserDefaults] setBool:mwcFlags.caseInsensitiveSearch forKey:SKCaseInsensitiveSearchKey];
}

- (IBAction)toggleWholeWordSearch:(id)sender {
    mwcFlags.wholeWordSearch = (0 == mwcFlags.wholeWordSearch);
    if ([[leftSideController.searchField stringValue] length])
        [self search:leftSideController.searchField];
    [[NSUserDefaults standardUserDefaults] setBool:mwcFlags.wholeWordSearch forKey:SKWholeWordSearchKey];
}

- (IBAction)toggleCaseInsensitiveFilter:(id)sender {
    mwcFlags.caseInsensitiveFilter = (0 == mwcFlags.caseInsensitiveFilter);
    if ([[rightSideController.searchField stringValue] length])
        [self searchNotes:rightSideController.searchField];
    [[NSUserDefaults standardUserDefaults] setBool:mwcFlags.caseInsensitiveFilter forKey:SKCaseInsensitiveFilterKey];
}

- (IBAction)toggleLeftSidePane:(id)sender {
    if ([self interactionMode] == SKPresentationMode) {
        if ([sideWindow isVisible])
            [self hideSideWindow];
        else
            [self showSideWindow];
    } else if ([self hasOverview]) {
        [self hideOverviewAnimating:sender != nil completionHandler:^{ [self toggleLeftSidePane:sender]; }];
    } else {
        CGFloat position = [splitView minPossiblePositionOfDividerAtIndex:0];
        if ([self leftSidePaneIsOpen]) {
            if ([[[self window] firstResponder] isDescendantOf:leftSideContentView])
                [[self window] makeFirstResponder:pdfView];
            lastLeftSidePaneWidth = fmaxf(MIN_SIDE_PANE_WIDTH, NSWidth([leftSideContentView frame]));
        } else {
            if(lastLeftSidePaneWidth <= 0.0)
                lastLeftSidePaneWidth = DEFAULT_SIDE_PANE_WIDTH; // a reasonable value to start
            if (lastLeftSidePaneWidth > 0.5 * NSWidth([centerContentView frame]))
                lastLeftSidePaneWidth = floor(0.5 * NSWidth([centerContentView frame]));
            position = lastLeftSidePaneWidth;
        }
        [splitView setPosition:position ofDividerAtIndex:0 animate:sender != nil];
    }
}

- (IBAction)toggleRightSidePane:(id)sender {
    if ([self interactionMode] == SKPresentationMode) {
    } else if ([self hasOverview]) {
        [self hideOverviewAnimating:sender != nil completionHandler:^{ [self toggleRightSidePane:sender]; }];
    } else {
        CGFloat position = [splitView maxPossiblePositionOfDividerAtIndex:1];
        if ([self rightSidePaneIsOpen]) {
            if ([[[self window] firstResponder] isDescendantOf:rightSideContentView])
                [[self window] makeFirstResponder:pdfView];
            lastRightSidePaneWidth = fmaxf(MIN_SIDE_PANE_WIDTH, NSWidth([rightSideContentView frame]));
            [splitView setPosition:position ofDividerAtIndex:1 animate:sender != nil];
        } else {
            if(lastRightSidePaneWidth <= 0.0)
                lastRightSidePaneWidth = DEFAULT_SIDE_PANE_WIDTH; // a reasonable value to start
            if (lastRightSidePaneWidth > 0.5 * NSWidth([centerContentView frame]))
                lastRightSidePaneWidth = floor(0.5 * NSWidth([centerContentView frame]));
            position -= lastRightSidePaneWidth + [splitView dividerThickness];
            [splitView setPosition:position ofDividerAtIndex:1 animate:sender != nil];
            if (mwcFlags.autoResizeNoteRows && [splitView isAnimating]) {
               [splitView enqueueOperation:^{
                   [rowHeights removeAllFloats];
                   [rightSideController.noteOutlineView noteHeightOfRowsChangedAnimating:YES];
               }];
            }
        }
    }
}

- (IBAction)changeLeftSidePaneState:(id)sender {
    [self setLeftSidePaneState:[sender tag]];
}

- (IBAction)changeRightSidePaneState:(id)sender {
    [self setRightSidePaneState:[sender tag]];
}

- (IBAction)changeFindPaneState:(id)sender {
    [self setFindPaneState:[sender tag]];
}

- (IBAction)toggleOverview:(id)sender {
    if ([self hasOverview])
        [self hideOverviewAnimating:YES];
    else
        [self showOverviewAnimating:YES];
}

- (IBAction)toggleSplitPDF:(id)sender {
    if ([pdfSplitView isAnimating])
        return;
    
    if ([self hasOverview]) {
        [self hideOverviewAnimating:YES completionHandler:^{ [self toggleSplitPDF:sender]; }];
        return;
    }
    
    if ([secondaryPdfView window]) {
        
        lastSplitPDFHeight = NSHeight([secondaryPdfView frame]);
        
        [pdfSplitView setPosition:[pdfSplitView maxPossiblePositionOfDividerAtIndex:0] ofDividerAtIndex:0 animate:YES];
        if ([pdfSplitView isAnimating]) {
            [pdfSplitView enqueueOperation:^{
                [secondaryPdfView removeFromSuperview];
                [pdfSplitView adjustSubviews];
            }];
        } else {
            [secondaryPdfView removeFromSuperview];
            [pdfSplitView adjustSubviews];
        }
        
    } else {
        
        NSRect frame = [pdfSplitView bounds];
        
        if (lastSplitPDFHeight <= 0.0)
            lastSplitPDFHeight = floor(DEFAULT_SPLIT_PDF_FACTOR * NSHeight(frame));
        
        CGFloat position = NSHeight(frame) - lastSplitPDFHeight - [pdfSplitView dividerThickness];
        NSPoint point = frame.origin;
        PDFPage *page = nil;
        BOOL fixedAtBottom = [[[pdfView scrollView] contentView] isFlipped] == NO;
        
        if (secondaryPdfView == nil) {
            secondaryPdfView = [[SKSecondaryPDFView alloc] initWithFrame:NSMakeRect(0.0, 0.0, 200.0, 20.0)];
            [secondaryPdfView setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
            [secondaryPdfView setHidden:YES];
            [pdfSplitView addSubview:secondaryPdfView];
            // Because of a PDFView bug, display properties can not be changed before it is placed in a window
            [secondaryPdfView setSynchronizedPDFView:pdfView];
            [secondaryPdfView setBackgroundColor:[pdfView backgroundColor]];
            [[secondaryPdfView scrollView] setDrawsBackground:[[pdfView scrollView] drawsBackground]];
            [secondaryPdfView applyDefaultPageBackgroundColor];
            [secondaryPdfView setDisplaysPageBreaks:NO];
            [secondaryPdfView setShouldAntiAlias:[[NSUserDefaults standardUserDefaults] boolForKey:SKShouldAntiAliasKey]];
            [secondaryPdfView setInterpolationQuality:[[NSUserDefaults standardUserDefaults] integerForKey:SKInterpolationQualityKey]];
            [secondaryPdfView setGreekingThreshold:[[NSUserDefaults standardUserDefaults] floatForKey:SKGreekingThresholdKey]];
            [secondaryPdfView setSynchronizeZoom:YES];
            [secondaryPdfView setDocument:[pdfView document]];
            point.y += fixedAtBottom ? -lastSplitPDFHeight : NSHeight(frame) - position - [pdfSplitView dividerThickness];
            page = [pdfView pageForPoint:point nearest:YES];
            
        } else {
            [secondaryPdfView setHidden:YES];
            [pdfSplitView addSubview:secondaryPdfView];
        }
        
        [pdfSplitView setPosition:position ofDividerAtIndex:0 animate:YES];
        
        if (page) {
            [secondaryPdfView goToPage:page];
            point = [secondaryPdfView convertPoint:[secondaryPdfView convertPoint:[pdfView convertPoint:point toPage:page] fromPage:page] toView:[secondaryPdfView documentView]];
            if ([[[secondaryPdfView scrollView] contentView] isFlipped] == fixedAtBottom)
                point.y -= ([[secondaryPdfView documentView] isFlipped] == fixedAtBottom ? 1.0 : -1.0) * NSHeight([[secondaryPdfView documentView] visibleRect]);
            [[secondaryPdfView documentView] scrollPoint:point];
            [secondaryPdfView layoutDocumentView];
        }
    }
    
    [[self window] recalculateKeyViewLoop];
}

- (IBAction)toggleFullscreen:(id)sender {
    if ([self canExitFullscreen])
        [self exitFullscreen];
    else if ([self canEnterFullscreen])
        [self enterFullscreen];
}

- (IBAction)togglePresentation:(id)sender {
    if ([self canExitPresentation])
        [self exitPresentation];
    else if ([self canEnterPresentation])
        [self enterPresentation];
}

- (IBAction)performFindPanelAction:(id)sender {
    if ([self interactionMode] == SKPresentationMode) {
        NSBeep();
        return;
    }
    
    if ([self hasOverview]) {
        [self hideOverviewAnimating:YES completionHandler:^{ [self performFindPanelAction:sender]; }];
        return;
    }
	
    NSStringCompareOptions forward = YES;
    NSString *findString = nil;
    
    switch ([sender tag]) {
		case NSFindPanelActionShowFindPanel:
            [self showFindBar];
            break;
		case NSFindPanelActionPrevious:
            forward = NO;
		case NSFindPanelActionNext:
            if ([[findController view] window]) {
                [findController findForward:forward];
            } else {
                NSPasteboard *findPboard = [NSPasteboard pasteboardWithName:NSFindPboard];
                NSArray *strings = [findPboard readObjectsForClasses:[NSArray arrayWithObject:[NSString class]] options:[NSDictionary dictionary]];
                if ([strings count] > 0)
                    findString = [strings objectAtIndex:0];
                if ([findString length] > 0)
                    [self findString:findString forward:forward];
                else
                    NSBeep();
            }
            break;
		case NSFindPanelActionSetFindString:
            findString = [[[self pdfView] currentSelection] string];
            if ([findString length] == 0) {
                NSBeep();
            } else if ([[findController view] window]) {
                [findController setFindString:findString];
                [findController updateFindPboard];
            } else {
                NSPasteboard *findPboard = [NSPasteboard pasteboardWithName:NSFindPboard];
                [findPboard clearContents];
                [findPboard writeObjects:[NSArray arrayWithObjects:findString, nil]];
            }
            break;
        default:
            NSBeep();
            break;
	}
}

- (IBAction)centerSelectionInVisibleArea:(id)sender {
    if ([self interactionMode] == SKPresentationMode) {
        NSBeep();
        return;
    }
    
    if ([self hasOverview]) {
        [self hideOverviewAnimating:YES completionHandler:^{ [self performFindPanelAction:sender]; }];
        return;
    }
    
    PDFSelection *selection = [pdfView currentSelection];
    if ([selection hasCharacters] == NO) {
        NSBeep();
        return;
    }
    
    [pdfView goToSelection:selection];
    PDFPage *page = [selection safeFirstPage];
    NSRect rect = [pdfView convertRect:[selection boundsForPage:page] fromPage:page];
    NSView *clipView = [[pdfView scrollView] contentView];
    NSRect visibleRect = [pdfView convertRect:[clipView visibleRect] fromView:clipView];
    visibleRect.origin.x = floor(NSMidX(rect) - 0.5 * NSWidth(visibleRect));
    visibleRect.origin.y = ceil(NSMidY(rect) - 0.5 * NSHeight(visibleRect));
    visibleRect = [pdfView convertRect:visibleRect toView:[pdfView documentView]];
    [[pdfView documentView] scrollRectToVisible:visibleRect];
}

- (void)cancelOperation:(id)sender {
    // passed on from SKSideWindow or SKFullScreenWindow
    if ([self hasOverview]) {
        [self hideOverviewAnimating:YES];
    } else if ([self interactionMode] != SKNormalMode) {
        if (sender == [self window]) {
            if ([self canExitFullscreen])
                [self exitFullscreen];
            else if ([self canExitPresentation])
                [self exitPresentation];
        } else if (sender == sideWindow) {
            [self toggleLeftSidePane:sender];
        }
    }
}

- (void)scrollUp:(id)sender {
    NSScrollView *scrollView = [[self pdfView] scrollView];
    NSClipView *clipView = [scrollView contentView];
    NSPoint point = [clipView bounds].origin;
    point.y += [clipView isFlipped] ? -4.0 * [scrollView verticalLineScroll] : 4.0 * [scrollView verticalLineScroll];
    [clipView scrollPoint:point];
}

- (void)scrollDown:(id)sender {
    NSScrollView *scrollView = [[self pdfView] scrollView];
    NSClipView *clipView = [scrollView contentView];
    NSPoint point = [clipView bounds].origin;
    point.y += [clipView isFlipped] ? 4.0 * [scrollView verticalLineScroll] : -4.0 * [scrollView verticalLineScroll];
    [clipView scrollPoint:point];
}

- (void)scrollRight:(id)sender {
    NSScrollView *scrollView = [[self pdfView] scrollView];
    NSClipView *clipView = [scrollView contentView];
    NSPoint point = [clipView bounds].origin;
    point.x += + 4.0 * [scrollView horizontalLineScroll];
    [clipView scrollPoint:point];
}

- (void)scrollLeft:(id)sender {
    NSScrollView *scrollView = [[self pdfView] scrollView];
    NSClipView *clipView = [scrollView contentView];
    NSPoint point = [clipView bounds].origin;
    point.x += -4.0 * [scrollView horizontalLineScroll];
    [clipView scrollPoint:point];
}

@end
