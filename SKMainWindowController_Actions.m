//
//  SKMainWindowController_Actions.m
//  Skim
//
//  Created by Christiaan Hofman on 2/14/09.
/*
 This software is Copyright (c) 2009-2014
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

#define STATUSBAR_HEIGHT 22.0

#define PAGE_BREAK_MARGIN 8.0

#define DEFAULT_SIDE_PANE_WIDTH 250.0
#define MIN_SIDE_PANE_WIDTH 100.0

#define DEFAULT_SPLIT_PDF_FACTOR 0.3

@interface SKMainWindowController (SKPrivateUI)
- (void)updateLineInspector;
@end

@implementation SKMainWindowController (Actions)

- (IBAction)changeColor:(id)sender{
    PDFAnnotation *annotation = [pdfView activeAnnotation];
    if (mwcFlags.updatingColor == 0 && [annotation isSkimNote]) {
        BOOL isFill = [colorAccessoryView state] == NSOnState && [annotation respondsToSelector:@selector(setInteriorColor:)];
        BOOL isText = [textColorAccessoryView state] == NSOnState && [annotation respondsToSelector:@selector(setFontColor:)];
        NSColor *color = (isFill ? [(id)annotation interiorColor] : (isText ? [(id)annotation fontColor] : [annotation color])) ?: [NSColor clearColor];
        if ([color isEqual:[sender color]] == NO) {
            mwcFlags.updatingColor = 1;
            if (isFill)
                [(id)annotation setInteriorColor:[[sender color] alphaComponent] > 0.0 ? [sender color] : nil];
            else if (isText)
                [(id)annotation setFontColor:[[sender color] alphaComponent] > 0.0 ? [sender color] : nil];
            else
                [annotation setColor:[sender color]];
            mwcFlags.updatingColor = 0;
        }
    }
}

- (IBAction)changeFont:(id)sender{
    PDFAnnotation *annotation = [pdfView activeAnnotation];
    if (mwcFlags.updatingFont == 0 && [annotation isSkimNote] && [annotation respondsToSelector:@selector(setFont:)] && [annotation respondsToSelector:@selector(font)]) {
        NSFont *font = [sender convertFont:[(PDFAnnotationFreeText *)annotation font]];
        mwcFlags.updatingFont = 1;
        [(PDFAnnotationFreeText *)annotation setFont:font];
        mwcFlags.updatingFont = 0;
    }
}

- (IBAction)changeAttributes:(id)sender{
    PDFAnnotation *annotation = [pdfView activeAnnotation];
    if (mwcFlags.updatingFontAttributes == 0 && [annotation isSkimNote] && [annotation respondsToSelector:@selector(setFontColor:)] && [annotation respondsToSelector:@selector(fontColor)]) {
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
    if ([annotation isSkimNote] && [annotation respondsToSelector:@selector(setAlignment:)] && [annotation respondsToSelector:@selector(alignment)]) {
        [(PDFAnnotationFreeText *)annotation setAlignment:NSLeftTextAlignment];
    }
}

- (IBAction)alignRight:(id)sender {
    PDFAnnotation *annotation = [pdfView activeAnnotation];
    if ([annotation isSkimNote] && [annotation respondsToSelector:@selector(setAlignment:)] && [annotation respondsToSelector:@selector(alignment)]) {
        [(PDFAnnotationFreeText *)annotation setAlignment:NSRightTextAlignment];
    }
}

- (IBAction)alignCenter:(id)sender {
    PDFAnnotation *annotation = [pdfView activeAnnotation];
    if ([annotation isSkimNote] && [annotation respondsToSelector:@selector(setAlignment:)] && [annotation respondsToSelector:@selector(alignment)]) {
        [(PDFAnnotationFreeText *)annotation setAlignment:NSCenterTextAlignment];
    }
}

- (void)changeLineAttribute:(id)sender {
    SKLineChangeAction action = [sender currentLineChangeAction];
    PDFAnnotation *annotation = [pdfView activeAnnotation];
    if (mwcFlags.updatingLine == 0 && [annotation hasBorder]) {
        mwcFlags.updatingLine = 1;
        switch (action) {
            case SKLineWidthLineChangeAction:
                [annotation setLineWidth:[sender lineWidth]];
                break;
            case SKStyleLineChangeAction:
                [annotation setBorderStyle:[(SKLineInspector *)sender style]];
                break;
            case SKDashPatternLineChangeAction:
                [annotation setDashPattern:[sender dashPattern]];
                break;
            case SKStartLineStyleLineChangeAction:
                if ([annotation isLine])
                    [(PDFAnnotationLine *)annotation setStartLineStyle:[sender startLineStyle]];
                break;
            case SKEndLineStyleLineChangeAction:
                if ([annotation isLine])
                    [(PDFAnnotationLine *)annotation setEndLineStyle:[sender endLineStyle]];
                break;
        }
        mwcFlags.updatingLine = 0;
        // in case one property changes another, e.g. when adding a dashPattern the borderStyle can change
        [self updateLineInspector];
    }
}

- (IBAction)createNewNote:(id)sender{
    if ([pdfView hideNotes] == NO)
        [pdfView addAnnotationWithType:[sender tag]];
    else NSBeep();
}

- (void)addNoteFromPanel:(id)sender {
    [self createNewNote:sender];
    [[self window] makeKeyWindow];
    [[self window] makeFirstResponder:[self pdfView]];
}

- (void)selectSelectedNote:(id)sender{
    if ([pdfView hideNotes] == NO) {
        NSArray *selectedNotes = [self selectedNotes];
        if ([selectedNotes count] == 1) {
            PDFAnnotation *annotation = [selectedNotes lastObject];
            [pdfView scrollAnnotationToVisible:annotation];
            [pdfView setActiveAnnotation:annotation];
        }
        NSInteger column = [sender clickedColumn];
        if (column != -1) {
            NSString *colID = [[[sender tableColumns] objectAtIndex:column] identifier];
            if ([colID isEqualToString:@"color"])
                [[NSColorPanel sharedColorPanel] orderFront:nil];
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

- (IBAction)editNote:(id)sender{
    if ([pdfView hideNotes] == NO) {
        [pdfView editActiveAnnotation:sender];
    } else NSBeep();
}

- (IBAction)toggleHideNotes:(id)sender{
    NSNumber *wasHidden = [NSNumber numberWithBool:[pdfView hideNotes]];
    [pdfView setHideNotes:[pdfView hideNotes] == NO];
    [notes setValue:wasHidden forKey:@"shouldDisplay"];
    [notes setValue:wasHidden forKey:@"shouldPrint"];
}

- (IBAction)takeSnapshot:(id)sender{
    [pdfView takeSnapshot:sender];
}

- (IBAction)changeDisplaySinglePages:(id)sender {
    [pdfView setDisplayMode:([pdfView displayMode] & ~kPDFDisplayTwoUp) | [sender tag]];
}

- (IBAction)changeDisplayContinuous:(id)sender {
    [pdfView setDisplayMode:([pdfView displayMode] & ~kPDFDisplaySinglePageContinuous) | [sender tag]];
}

- (IBAction)changeDisplayMode:(id)sender {
    [pdfView setDisplayMode:[sender tag]];
}

- (IBAction)toggleDisplayAsBook:(id)sender {
    [pdfView setDisplaysAsBook:[pdfView displaysAsBook] == NO];
}

- (IBAction)toggleDisplayPageBreaks:(id)sender {
    [pdfView setDisplaysPageBreaks:[pdfView displaysPageBreaks] == NO];
}

- (IBAction)changeDisplayBox:(id)sender {
    [pdfView setDisplayBox:[sender tag]];
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

- (void)pageSheetDidEnd:(SKTextFieldSheetController *)controller returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
    if (returnCode == NSOKButton)
        [self setPageLabel:[controller stringValue]];
}

- (IBAction)doGoToPage:(id)sender {
    SKTextFieldSheetController *pageSheetController = [[[SKTextFieldSheetController alloc] initWithWindowNibName:@"PageSheet"] autorelease];
    
    [(NSComboBox *)[pageSheetController textField] addItemsWithObjectValues:pageLabels];
    [pageSheetController setStringValue:[self pageLabel]];
    
    [pageSheetController beginSheetModalForWindow:[self window] completionHandler:^(NSInteger result) {
            if (result == NSOKButton)
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
        [pdfView goToPage:[pdfDoc pageAtIndex:MIN(beforeMarkedPageIndex, [pdfDoc pageCount] - 1)]];
    } else if (currentPageIndex != markedPageIndex) {
        beforeMarkedPageIndex = currentPageIndex;
        [pdfView goToPage:[pdfDoc pageAtIndex:MIN(markedPageIndex, [pdfDoc pageCount] - 1)]];
    }
}

- (IBAction)markPage:(id)sender {
    markedPageIndex = [[pdfView currentPage] pageIndex];
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
    if (NSIsEmptyRect(selRect) == NO) {
        NSRect bounds = [pdfView bounds];
        CGFloat scale = 1.0;
        bounds.size.width -= [NSScroller scrollerWidth];
        bounds.size.height -= [NSScroller scrollerWidth];
        if (NSWidth(bounds) * NSHeight(selRect) > NSWidth(selRect) * NSHeight(bounds))
            scale = NSHeight(bounds) / NSHeight(selRect);
        else
            scale = NSWidth(bounds) / NSWidth(selRect);
        [pdfView setScaleFactor:scale];
        NSScrollView *scrollView = [[pdfView documentView] enclosingScrollView];
        if ([scrollView hasHorizontalScroller] == NO || [scrollView hasVerticalScroller] == NO) {
            bounds = [pdfView bounds];
            if ([scrollView hasVerticalScroller])
                bounds.size.width -= [NSScroller scrollerWidth];
            if ([scrollView hasHorizontalScroller])
                bounds.size.height -= [NSScroller scrollerWidth];
            if (NSWidth(bounds) * NSHeight(selRect) > NSWidth(selRect) * NSHeight(bounds))
                scale = NSHeight(bounds) / NSHeight(selRect);
            else
                scale = NSWidth(bounds) / NSWidth(selRect);
            [pdfView setScaleFactor:scale];
        }
        [pdfView goToRect:selRect onPage:[pdfView currentSelectionPage]]; 
    } else NSBeep();
}

- (IBAction)doZoomToFit:(id)sender {
    [pdfView setAutoScales:YES];
    [pdfView setAutoScales:NO];
}

- (IBAction)alternateZoomToFit:(id)sender {
    PDFDisplayMode displayMode = [pdfView displayMode];
    NSRect frame = [pdfView frame];
    PDFPage *page = [pdfView currentPage];
    NSRect pageRect = [page boundsForBox:[pdfView displayBox]];
    CGFloat scrollerWidth = 0.0;
    CGFloat margin = [pdfView displaysPageBreaks] ? PAGE_BREAK_MARGIN : 0.0;
    CGFloat scaleFactor;
    NSUInteger pageCount = [[pdfView document] pageCount];
    if (displayMode == kPDFDisplaySinglePage || displayMode == kPDFDisplayTwoUp) {
        // zoom to width
        NSUInteger numCols = (displayMode == kPDFDisplayTwoUp && pageCount > 1 && ([pdfView displaysAsBook] == NO || pageCount > 2)) ? 2 : 1;
        if (NSWidth(frame) * ( margin + NSHeight(pageRect) ) > NSHeight(frame) * numCols * ( margin + NSWidth(pageRect) ) )
            scrollerWidth = [NSScroller scrollerWidth];
        scaleFactor = ( NSWidth(frame) - scrollerWidth ) / ( margin + NSWidth(pageRect) );
    } else {
        // zoom to height
        NSUInteger numRows = pageCount;
        if (displayMode == kPDFDisplayTwoUpContinuous)
            numRows = [pdfView displaysAsBook] ? (1 + pageCount) / 2 : 1 + pageCount / 2;
        if (NSHeight(frame) * ( margin + NSWidth(pageRect) ) > NSWidth(frame) * numRows * ( margin + NSHeight(pageRect) ) )
            scrollerWidth = [NSScroller scrollerWidth];
        scaleFactor = ( NSHeight(frame) - scrollerWidth ) / ( margin + NSHeight(pageRect) );
    }
    [pdfView setScaleFactor:scaleFactor];
    [pdfView layoutDocumentView];
    [pdfView scrollPageToVisible:page];
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
    
    PDFPage *page = [pdfView currentPage];
    NSInteger i, count = [[pdfView document] pageCount];
    for (i = 0; i < count; i++)
        [[[pdfView document] pageAtIndex:i] setRotation:[[[pdfView document] pageAtIndex:i] rotation] + rotation];
    [pdfView layoutDocumentView];
    // due to as PDFKit bug, PDFView doesn't notice that it's currentPage has changed, so we need to force a page change to have it notice first
    [pdfView goToPreviousPage:nil];
    [pdfView goToPage:page];
    
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
    PDFPage *currentPage = [pdfView currentPage];
    NSRect visibleRect = [pdfView convertRect:[pdfView convertRect:[[pdfView documentView] visibleRect] fromView:[pdfView documentView]] toPage:[pdfView currentPage]];
    
    NSInteger i, count = [[pdfView document] pageCount];
    NSInteger rectCount = [rects count];
    NSPointerArray *oldRects = [NSPointerArray rectPointerArray];
    for (i = 0; i < count; i++) {
        PDFPage *page = [[pdfView document] pageAtIndex:i];
        NSRect rect = NSIntersectionRect(*(NSRectPointer)[rects pointerAtIndex:i % rectCount], [page boundsForBox:kPDFDisplayBoxMediaBox]);
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
    // layout after cropping when you're in the middle of a document can lose the current page
    [pdfView goToPage:currentPage];
    [[pdfView documentView] scrollRectToVisible:[pdfView convertRect:[pdfView convertRect:visibleRect fromPage:currentPage] toView:[pdfView documentView]]];
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
    if (statusBar == nil) {
        statusBar = [[SKStatusBar alloc] initWithFrame:NSMakeRect(0.0, 0.0, NSWidth([splitView frame]), STATUSBAR_HEIGHT)];
        [statusBar setAutoresizingMask:NSViewWidthSizable | NSViewMaxYMargin];
        [self updateLeftStatus];
        [self updateRightStatus];
        [statusBar setRightAction:@selector(statusBarClicked:)];
        [statusBar setRightTarget:self];
    }
    [[NSUserDefaults standardUserDefaults] setBool:(NO == [statusBar isVisible]) forKey:SKShowStatusBarKey];
    [statusBar toggleBelowView:splitView animate:sender != nil];
}

- (IBAction)searchPDF:(id)sender {
    BOOL selectImmediate = YES;
    if ([self interactionMode] == SKFullScreenMode) {
        if ([leftSideWindow state] == NSDrawerClosedState || [leftSideWindow state] == NSDrawerClosingState)
            [leftSideWindow expand];
    } else if ([self leftSidePaneIsOpen] == NO) {
        selectImmediate = [[NSUserDefaults standardUserDefaults] boolForKey:SKDisableAnimationsKey];
        [self toggleLeftSidePane:sender];
    }
    // workaround for an AppKit bug: when selecting immediately before the animation, the search fields does not display its text
    if (selectImmediate)
        [leftSideController.searchField selectText:self];
    else
        [leftSideController.searchField performSelector:@selector(selectText:) withObject:nil afterDelay:[[NSAnimationContext currentContext] duration]];
}

- (IBAction)performFit:(id)sender {
    if ([self interactionMode] != SKNormalMode) {
        NSBeep();
        return;
    }
    
    PDFDisplayMode displayMode = [[self pdfView] displayMode];
    CGFloat scaleFactor = [[self pdfView] scaleFactor];
    BOOL autoScales = [[self pdfView] autoScales];
    BOOL isSingleRow;
    
    if (displayMode == kPDFDisplaySinglePage || displayMode == kPDFDisplayTwoUp)
        isSingleRow = YES;
    else if (displayMode == kPDFDisplaySinglePageContinuous || [[self pdfView] displaysAsBook])
        isSingleRow = [[[self pdfView] document] pageCount] <= 1;
    else
        isSingleRow = [[[self pdfView] document] pageCount] <= 2;
    
    NSRect frame = [[self window] frame];
    NSSize size, oldSize = [[self pdfView] frame].size;
    NSRect documentRect = [[[self pdfView] documentView] convertRect:[[[self pdfView] documentView] bounds] toView:nil];
    PDFPage *page = [[self pdfView] currentPage];
    PDFDisplayBox box = [[self pdfView] displayBox];
    
    // Calculate the new size for the pdfView
    size.width = NSWidth(documentRect);
    if (autoScales)
        size.width /= scaleFactor;
    if (isSingleRow) {
        size.height = NSHeight(documentRect);
    } else {
        size.height = NSHeight([[self pdfView] convertRect:[page boundsForBox:box] fromPage:page]);
        if ([[self pdfView] displaysPageBreaks])
            size.height += PAGE_BREAK_MARGIN * scaleFactor;
        size.width += [NSScroller scrollerWidth];
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
        [[self pdfView] goToRect:[page boundsForBox:box] onPage:page];
}

- (IBAction)password:(id)sender {
    SKTextFieldSheetController *passwordSheetController = [[[SKTextFieldSheetController alloc] initWithWindowNibName:@"PasswordSheet"] autorelease];
    
    [passwordSheetController beginSheetModalForWindow:[self window] completionHandler:^(NSInteger result) {
            if (result == NSOKButton) {
                [[passwordSheetController window] orderOut:nil];
                [[pdfView document] unlockWithPassword:[passwordSheetController stringValue]];
            }
        }];
}

- (IBAction)toggleReadingBar:(id)sender {
    [pdfView toggleReadingBar];
}

- (IBAction)savePDFSettingToDefaults:(id)sender {
    if ([self interactionMode] == SKFullScreenMode)
        [[NSUserDefaults standardUserDefaults] setObject:[self currentPDFSettings] forKey:SKDefaultFullScreenPDFDisplaySettingsKey];
    else if ([self interactionMode] == SKNormalMode)
        [[NSUserDefaults standardUserDefaults] setObject:[self currentPDFSettings] forKey:SKDefaultPDFDisplaySettingsKey];
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

- (IBAction)toggleCaseInsensitiveNoteSearch:(id)sender {
    mwcFlags.caseInsensitiveNoteSearch = (0 == mwcFlags.caseInsensitiveNoteSearch);
    if ([[rightSideController.searchField stringValue] length])
        [self searchNotes:rightSideController.searchField];
    [[NSUserDefaults standardUserDefaults] setBool:mwcFlags.caseInsensitiveNoteSearch forKey:SKCaseInsensitiveNoteSearchKey];
}

- (IBAction)toggleLeftSidePane:(id)sender {
    if ([self interactionMode] == SKFullScreenMode) {
        [[SKImageToolTipWindow sharedToolTipWindow] fadeOut];
        if ([self leftSidePaneIsOpen])
            [leftSideWindow collapse];
        else
            [leftSideWindow expand];
    } else if ([self interactionMode] == SKPresentationMode) {
        if ([leftSideWindow isVisible])
            [self hideLeftSideWindow];
        else
            [self showLeftSideWindow];
    } else if (mwcFlags.usesDrawers) {
        if ([self leftSidePaneIsOpen]) {
            if (mwcFlags.leftSidePaneState == SKOutlineSidePaneState || [[leftSideController.searchField stringValue] length])
                [[SKImageToolTipWindow sharedToolTipWindow] fadeOut];
            [leftSideDrawer close];
        } else {
            [leftSideDrawer openOnEdge:NSMinXEdge];
        }
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
    if ([self interactionMode] == SKFullScreenMode) {
        if ([self rightSidePaneIsOpen])
            [rightSideWindow collapse];
        else
            [rightSideWindow expand];
    } else if ([self interactionMode] == SKPresentationMode) {
        if ([rightSideWindow isVisible])
            [self hideRightSideWindow];
        else
            [self showRightSideWindow];
    } else if (mwcFlags.usesDrawers) {
        if ([self rightSidePaneIsOpen])
            [rightSideDrawer close];
        else
            [rightSideDrawer openOnEdge:NSMaxXEdge];
    } else {
        CGFloat position = [splitView maxPossiblePositionOfDividerAtIndex:1];
        if ([self rightSidePaneIsOpen]) {
            if ([[[self window] firstResponder] isDescendantOf:rightSideContentView])
                [[self window] makeFirstResponder:pdfView];
            lastRightSidePaneWidth = fmaxf(MIN_SIDE_PANE_WIDTH, NSWidth([rightSideContentView frame]));
        } else {
            if(lastRightSidePaneWidth <= 0.0)
                lastRightSidePaneWidth = DEFAULT_SIDE_PANE_WIDTH; // a reasonable value to start
            if (lastRightSidePaneWidth > 0.5 * NSWidth([centerContentView frame]))
                lastRightSidePaneWidth = floor(0.5 * NSWidth([centerContentView frame]));
            position -= lastRightSidePaneWidth + [splitView dividerThickness];
        }
        [splitView setPosition:position ofDividerAtIndex:1 animate:sender != nil];
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

- (void)removeSecondaryPdfContentView {
    [secondaryPdfContentView removeFromSuperview];
    [pdfSplitView adjustSubviews];
}

- (IBAction)toggleSplitPDF:(id)sender {
    if ([pdfSplitView isAnimating])
        return;
    
    if ([secondaryPdfView window]) {
        
        lastSplitPDFHeight = NSHeight([secondaryPdfContentView frame]);
        
        NSTimeInterval delay = [[NSUserDefaults standardUserDefaults] boolForKey:SKDisableAnimationsKey] ? 0.0 : [[NSAnimationContext currentContext] duration];
        [pdfSplitView setPosition:[pdfSplitView maxPossiblePositionOfDividerAtIndex:0] ofDividerAtIndex:0 animate:YES];
        [self performSelector:@selector(removeSecondaryPdfContentView) withObject:nil afterDelay:delay];
        
    } else {
        
        NSRect frame = [pdfSplitView bounds];
        
        if (lastSplitPDFHeight <= 0.0)
            lastSplitPDFHeight = floor(DEFAULT_SPLIT_PDF_FACTOR * NSHeight(frame));
        
        CGFloat position = NSHeight(frame) - lastSplitPDFHeight - [pdfSplitView dividerThickness];
        NSPoint point = NSZeroPoint;
        PDFPage *page = nil;
        
        if (secondaryPdfView == nil) {
            secondaryPdfContentView = [[NSView alloc] init];
            secondaryPdfView = [[SKSecondaryPDFView alloc] initWithFrame:[secondaryPdfContentView bounds]];
            [secondaryPdfView setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
            [secondaryPdfContentView setHidden:YES];
            [secondaryPdfContentView addSubview:secondaryPdfView];
            [secondaryPdfView release];
            [pdfSplitView addSubview:secondaryPdfContentView];
            // Because of a PDFView bug, display properties can not be changed before it is placed in a window
            [secondaryPdfView setSynchronizedPDFView:pdfView];
            [secondaryPdfView setBackgroundColor:[pdfView backgroundColor]];
            [secondaryPdfView setDisplaysPageBreaks:NO];
            [secondaryPdfView setShouldAntiAlias:[[NSUserDefaults standardUserDefaults] boolForKey:SKShouldAntiAliasKey]];
            [secondaryPdfView setGreekingThreshold:[[NSUserDefaults standardUserDefaults] floatForKey:SKGreekingThresholdKey]];
            [secondaryPdfView setSynchronizeZoom:YES];
            [secondaryPdfView setDocument:[pdfView document]];
            point = NSMakePoint(NSMinX(frame), NSMaxY(frame) - position - [pdfSplitView dividerThickness]);
            page = [pdfView pageForPoint:point nearest:YES];
        } else {
            [secondaryPdfContentView setHidden:YES];
            [pdfSplitView addSubview:secondaryPdfContentView];
        }
        
        [pdfSplitView setPosition:position ofDividerAtIndex:0 animate:YES];
        
        if (page) {
            point = [secondaryPdfView convertPoint:[secondaryPdfView convertPoint:[pdfView convertPoint:point toPage:page] fromPage:page] toView:[secondaryPdfView documentView]];
            [secondaryPdfView goToPage:page];
            [[secondaryPdfView documentView] scrollPoint:point];
            [secondaryPdfView layoutDocumentView];
        }
    }
    
    [[self window] recalculateKeyViewLoop];
    if ([self interactionMode] == SKFullScreenMode)
        [[self window] makeFirstResponder:pdfView];
}

- (IBAction)toggleFullscreen:(id)sender {
    if ([self interactionMode] == SKFullScreenMode)
        [self exitFullscreen:sender];
    else
        [self enterFullscreen:sender];
}

- (IBAction)togglePresentation:(id)sender {
    if ([self interactionMode] == SKPresentationMode)
        [self exitFullscreen:sender];
    else
        [self enterPresentation:sender];
}

- (IBAction)performFindPanelAction:(id)sender {
    if (interactionMode == SKPresentationMode) {
        NSBeep();
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

- (void)cancelOperation:(id)sender {
    // passed on from SKSideWindow or SKFullScreenWindow
    if ([self interactionMode] != SKNormalMode) {
        if (sender == [self window]) {
            [self exitFullscreen:sender];
        } else if (sender == leftSideWindow || sender == rightSideWindow) {
            NSDrawerState state = [(SKSideWindow *)sender state];
            if (state == NSDrawerClosedState || state == NSDrawerClosingState)
                [self exitFullscreen:sender];
            else if (sender == leftSideWindow)
                [self toggleLeftSidePane:sender];
            else if (sender == rightSideWindow)
                [self toggleRightSidePane:sender];
        }
    }
}

@end
