//
//  SKMainWindowController_Actions.m
//  Skim
//
//  Created by Christiaan Hofman on 2/14/09.
/*
 This software is Copyright (c) 2009
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
#import "SKPDFToolTipWindow.h"
#import "SKBookmarkController.h"
#import "BDSKCollapsibleView.h"
#import "BDSKEdgeView.h"
#import "SKSplitView.h"
#import "SKLineInspector.h"
#import "NSEvent_SKExtensions.h"
#import "NSWindowController_SKExtensions.h"
#import "NSPointerFunctions_SKExtensions.h"


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

- (IBAction)selectColor:(id)sender{
    PDFAnnotation *annotation = [pdfView activeAnnotation];
    if ([annotation isSkimNote]) {
        BOOL isFill = ([NSEvent standardModifierFlags] & NSAlternateKeyMask) != 0 && [annotation respondsToSelector:@selector(setInteriorColor:)];
        BOOL isText = ([NSEvent standardModifierFlags] & NSAlternateKeyMask) != 0 && [annotation respondsToSelector:@selector(setFontColor:)];
        NSColor *color = (isFill ? [(id)annotation interiorColor] : (isText ? [(id)annotation fontColor] : [annotation color])) ?: [NSColor clearColor];
        NSColor *newColor = [sender respondsToSelector:@selector(representedObject)] ? [sender representedObject] : [sender respondsToSelector:@selector(color)] ? [sender color] : nil;
        if (newColor && [color isEqual:newColor] == NO) {
            if (isFill)
                [(id)annotation setInteriorColor:[newColor alphaComponent] > 0.0 ? newColor : nil];
            else if (isText)
                [(id)annotation setFontColor:[newColor alphaComponent] > 0.0 ? newColor : nil];
            else
                [annotation setColor:newColor];
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
                [annotation setBorderStyle:[sender style]];
                break;
            case SKDashPatternLineChangeAction:
                [annotation setDashPattern:[sender dashPattern]];
                break;
            case SKStartLineStyleLineChangeAction:
                if ([[annotation type] isEqualToString:SKNLineString])
                    [(PDFAnnotationLine *)annotation setStartLineStyle:[sender startLineStyle]];
                break;
            case SKEndLineStyleLineChangeAction:
                if ([[annotation type] isEqualToString:SKNLineString])
                    [(PDFAnnotationLine *)annotation setEndLineStyle:[sender endLineStyle]];
                break;
        }
        mwcFlags.updatingLine = 0;
    }
}

- (IBAction)createNewNote:(id)sender{
    if ([pdfView hideNotes] == NO) {
        NSInteger type = [sender respondsToSelector:@selector(selectedSegment)] ? [sender selectedSegment] : [sender tag];
        [pdfView addAnnotationWithType:type];
    } else NSBeep();
}

- (IBAction)createNewTextNote:(id)sender{
    if ([pdfView hideNotes] == NO) {
        BOOL isButtonClick = [sender respondsToSelector:@selector(selectedSegment)];
        NSInteger type = [sender tag];
        [pdfView addAnnotationWithType:type];
        if (isButtonClick == NO && type != [textNoteButton tag]) {
            [textNoteButton setTag:type];
            NSString *imgName = type == SKFreeTextNote ? SKImageNameToolbarAddTextNoteMenu : SKImageNameToolbarAddAnchoredNoteMenu;
            [textNoteButton setImage:[NSImage imageNamed:imgName] forSegment:0];
        }
    } else NSBeep();
}

- (IBAction)createNewCircleNote:(id)sender{
    if ([pdfView hideNotes] == NO) {
        BOOL isButtonClick = [sender respondsToSelector:@selector(selectedSegment)];
        NSInteger type = [sender tag];
        [pdfView addAnnotationWithType:type];
        if (isButtonClick == NO && type != [circleNoteButton tag]) {
            [circleNoteButton setTag:type];
            NSString *imgName = type == SKCircleNote ? SKImageNameToolbarAddCircleNoteMenu : SKImageNameToolbarAddSquareNoteMenu;
            [circleNoteButton setImage:[NSImage imageNamed:imgName] forSegment:0];
        }
    } else NSBeep();
}

- (IBAction)createNewMarkupNote:(id)sender{
    if ([pdfView hideNotes] == NO) {
        BOOL isButtonClick = [sender respondsToSelector:@selector(selectedSegment)];
        NSInteger type = [sender tag];
        [pdfView addAnnotationWithType:type];
        if (isButtonClick == NO && type != [markupNoteButton tag]) {
            [markupNoteButton setTag:type];
            NSString *imgName = type == SKHighlightNote ? SKImageNameToolbarAddHighlightNoteMenu : SKUnderlineNote ? SKImageNameToolbarAddUnderlineNoteMenu : SKImageNameToolbarAddStrikeOutNoteMenu;
            [markupNoteButton setImage:[NSImage imageNamed:imgName] forSegment:0];
        }
    } else NSBeep();
}

- (IBAction)createNewLineNote:(id)sender{
    if ([pdfView hideNotes] == NO) {
        [pdfView addAnnotationWithType:SKLineNote];
    } else NSBeep();
}

- (void)selectSelectedNote:(id)sender{
    if ([pdfView hideNotes] == NO) {
        NSArray *selectedNotes = [self selectedNotes];
        if ([selectedNotes count] == 1) {
            PDFAnnotation *annotation = [selectedNotes lastObject];
            [pdfView scrollAnnotationToVisible:annotation];
            [pdfView setActiveAnnotation:annotation];
        }
    } else NSBeep();
}

- (void)goToSelectedOutlineItem:(id)sender {
    PDFOutline *outlineItem = [outlineView itemAtRow:[outlineView selectedRow]];
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
    BOOL wasHidden = [pdfView hideNotes];
    for (PDFAnnotation *note in notes) {
        [note setShouldDisplay:wasHidden];
        [note setShouldPrint:wasHidden];
    }
    [pdfView setHideNotes:wasHidden == NO];
}

- (IBAction)takeSnapshot:(id)sender{
    [pdfView takeSnapshot:sender];
}

- (IBAction)displaySinglePages:(id)sender {
    PDFDisplayMode displayMode = [pdfView displayMode];
    if (displayMode == kPDFDisplayTwoUp)
        [pdfView setDisplayMode:kPDFDisplaySinglePage];
    else if (displayMode == kPDFDisplayTwoUpContinuous)
        [pdfView setDisplayMode:kPDFDisplaySinglePageContinuous];
}

- (IBAction)displayFacingPages:(id)sender {
    PDFDisplayMode displayMode = [pdfView displayMode];
    if (displayMode == kPDFDisplaySinglePage) 
        [pdfView setDisplayMode:kPDFDisplayTwoUp];
    else if (displayMode == kPDFDisplaySinglePageContinuous)
        [pdfView setDisplayMode:kPDFDisplayTwoUpContinuous];
}

- (IBAction)changeDisplaySinglePages:(id)sender {
    PDFDisplayMode tag = [sender tag];
    if ([sender respondsToSelector:@selector(selectedTag)])
        tag = [sender selectedTag];
    PDFDisplayMode displayMode = [pdfView displayMode];
    if (displayMode == kPDFDisplaySinglePage && tag == kPDFDisplayTwoUp) 
        [pdfView setDisplayMode:kPDFDisplayTwoUp];
    else if (displayMode == kPDFDisplaySinglePageContinuous && tag == kPDFDisplayTwoUp)
        [pdfView setDisplayMode:kPDFDisplayTwoUpContinuous];
    else if (displayMode == kPDFDisplayTwoUp && tag == kPDFDisplaySinglePage)
        [pdfView setDisplayMode:kPDFDisplaySinglePage];
    else if (displayMode == kPDFDisplayTwoUpContinuous && tag == kPDFDisplaySinglePage)
        [pdfView setDisplayMode:kPDFDisplaySinglePageContinuous];
}

- (IBAction)toggleDisplayContinuous:(id)sender {
    PDFDisplayMode displayMode = [pdfView displayMode];
    if (displayMode == kPDFDisplaySinglePage) 
        displayMode = kPDFDisplaySinglePageContinuous;
    else if (displayMode == kPDFDisplaySinglePageContinuous)
        displayMode = kPDFDisplaySinglePage;
    else if (displayMode == kPDFDisplayTwoUp)
        displayMode = kPDFDisplayTwoUpContinuous;
    else if (displayMode == kPDFDisplayTwoUpContinuous)
        displayMode = kPDFDisplayTwoUp;
    [pdfView setDisplayMode:displayMode];
}

- (IBAction)changeDisplayContinuous:(id)sender {
    PDFDisplayMode tag = [sender tag];
    if ([sender respondsToSelector:@selector(selectedTag)])
        tag = [sender selectedTag];
    PDFDisplayMode displayMode = [pdfView displayMode];
    if (displayMode == kPDFDisplaySinglePage && tag == kPDFDisplaySinglePageContinuous)
        [pdfView setDisplayMode:kPDFDisplaySinglePageContinuous];
    else if (displayMode == kPDFDisplaySinglePageContinuous && tag == kPDFDisplaySinglePage)
        [pdfView setDisplayMode:kPDFDisplaySinglePage];
    else if (displayMode == kPDFDisplayTwoUp && tag == kPDFDisplaySinglePageContinuous)
        [pdfView setDisplayMode:kPDFDisplayTwoUpContinuous];
    else if (displayMode == kPDFDisplayTwoUpContinuous && tag == kPDFDisplaySinglePage)
        [pdfView setDisplayMode:kPDFDisplayTwoUp];
}

- (IBAction)changeDisplayMode:(id)sender {
    PDFDisplayMode displayMode = [sender tag];
    if ([sender respondsToSelector:@selector(selectedTag)])
        displayMode = [sender selectedTag];
    [pdfView setDisplayMode:displayMode];
}

- (IBAction)toggleDisplayAsBook:(id)sender {
    [pdfView setDisplaysAsBook:[pdfView displaysAsBook] == NO];
}

- (IBAction)toggleDisplayPageBreaks:(id)sender {
    [pdfView setDisplaysPageBreaks:[pdfView displaysPageBreaks] == NO];
}

- (IBAction)changeDisplayBox:(id)sender {
    PDFDisplayBox displayBox = [sender tag];
    if ([sender respondsToSelector:@selector(indexOfSelectedItem)])
        displayBox = [sender indexOfSelectedItem] == 0 ? kPDFDisplayBoxMediaBox : kPDFDisplayBoxCropBox;
    else if ([sender respondsToSelector:@selector(selectedSegment)])
        displayBox = [sender selectedSegment];
    [pdfView setDisplayBox:displayBox];
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

- (IBAction)allGoToNextPage:(id)sender {
    [[NSApp valueForKeyPath:@"orderedDocuments.pdfView"] makeObjectsPerformSelector:@selector(goToNextPage:) withObject:sender];
}

- (IBAction)allGoToPreviousPage:(id)sender {
    [[NSApp valueForKeyPath:@"orderedDocuments.pdfView"] makeObjectsPerformSelector:@selector(goToPreviousPage:) withObject:sender];
}

- (IBAction)allGoToFirstPage:(id)sender {
    [[NSApp valueForKeyPath:@"orderedDocuments.pdfView"] makeObjectsPerformSelector:@selector(goToFirstPage:) withObject:sender];
}

- (IBAction)allGoToLastPage:(id)sender {
    [[NSApp valueForKeyPath:@"orderedDocuments.pdfView"] makeObjectsPerformSelector:@selector(goToLastPage:) withObject:sender];
}

- (IBAction)goToPreviousNextFirstLastPage:(id)sender {
    NSInteger tag = [sender selectedTag];
    if (tag == -1)
        [pdfView goToPreviousPage:sender];
    else if (tag == 1)
        [pdfView goToNextPage:sender];
    else if (tag == -2)
        [pdfView goToFirstPage:sender];
    else if (tag == 2)
        [pdfView goToLastPage:sender];
        
}

- (void)pageSheetDidEnd:(SKPageSheetController *)controller returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
    if (returnCode == NSOKButton)
        [self setPageLabel:[controller stringValue]];
}

- (IBAction)doGoToPage:(id)sender {
    SKPageSheetController *pageSheetController = [[[SKPageSheetController alloc] init] autorelease];
    
    [pageSheetController setObjectValues:pageLabels];
    [pageSheetController setStringValue:[self pageLabel]];
    
    [pageSheetController beginSheetModalForWindow: [self window]
        modalDelegate: self
       didEndSelector: @selector(pageSheetDidEnd:returnCode:contextInfo:)
          contextInfo: nil];
}

- (IBAction)doGoBack:(id)sender {
    [pdfView goBack:sender];
}

- (IBAction)doGoForward:(id)sender {
    [pdfView goForward:sender];
}

- (IBAction)goBackOrForward:(id)sender {
    if ([sender selectedSegment] == 1)
        [pdfView goForward:sender];
    else
        [pdfView goBack:sender];
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
    CGFloat scaleFactor = 1.0;
    NSScreen *screen = [[self window] screen];
	CGDirectDisplayID displayID = (CGDirectDisplayID)[[[screen deviceDescription] objectForKey:@"NSScreenNumber"] unsignedIntValue];
	CGSize physicalSize = CGDisplayScreenSize(displayID);
    NSSize resolution = [[[screen deviceDescription] objectForKey:NSDeviceResolution] sizeValue];
	
    if (CGSizeEqualToSize(physicalSize, CGSizeZero) == NO)
        scaleFactor = CGDisplayPixelsWide(displayID) * 25.4f / (physicalSize.width * resolution.width);
    [pdfView setScaleFactor:scaleFactor];
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
    CGFloat margin = [pdfView displaysPageBreaks] ? 8.0 : 0.0;
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

- (IBAction)zoomInActualOut:(id)sender {
    NSInteger tag = [sender selectedTag];
    if (tag == -1)
        [pdfView zoomOut:sender];
    else if (tag == 0)
        [pdfView setScaleFactor:1.0];
    else if (tag == 1)
        [pdfView zoomIn:sender];
}

- (IBAction)doAutoScale:(id)sender {
    [pdfView setAutoScales:YES];
}

- (IBAction)toggleAutoScale:(id)sender {
    if ([self isPresentation])
        [self toggleAutoActualSize:sender];
    else
        [pdfView setAutoScales:[pdfView autoScales] == NO];
}

- (IBAction)toggleAutoActualSize:(id)sender {
    if ([pdfView autoScales])
        [self doZoomToActualSize:sender];
    else
        [self doAutoScale:sender];
}

- (IBAction)zoomLog:(id)sender {
    [pdfView setScaleFactor:exp([sender doubleValue])];
}

- (void)rotatePageAtIndex:(NSUInteger)idx by:(NSInteger)rotation {
    NSUndoManager *undoManager = [[self document] undoManager];
    [[undoManager prepareWithInvocationTarget:self] rotatePageAtIndex:idx by:-rotation];
    [undoManager setActionName:NSLocalizedString(@"Rotate Page", @"Undo action name")];
    [[self document] undoableActionDoesntDirtyDocument];
    
    PDFPage *page = [[pdfView document] pageAtIndex:idx];
    [page setRotation:[page rotation] + rotation];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:SKPDFPageBoundsDidChangeNotification 
            object:[pdfView document] userInfo:[NSDictionary dictionaryWithObjectsAndKeys:SKPDFPageActionRotate, SKPDFPageActionKey, page, SKPDFPagePageKey, nil]];
}

- (void)rotateAllBy:(NSInteger)rotation {
    NSUndoManager *undoManager = [[self document] undoManager];
    [[undoManager prepareWithInvocationTarget:self] rotateAllBy:-rotation];
    [undoManager setActionName:NSLocalizedString(@"Rotate", @"Undo action name")];
    [[self document] undoableActionDoesntDirtyDocument];
    
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

- (IBAction)rotateAllLeftRight:(id)sender {
    [self rotateAllBy:[sender selectedSegment] == 0 ? -90 : 90];
}

- (void)cropPageAtIndex:(NSUInteger)anIndex toRect:(NSRect)rect {
    NSRect oldRect = [[[pdfView document] pageAtIndex:anIndex] boundsForBox:kPDFDisplayBoxCropBox];
    NSUndoManager *undoManager = [[self document] undoManager];
    [[undoManager prepareWithInvocationTarget:self] cropPageAtIndex:anIndex toRect:oldRect];
    [undoManager setActionName:NSLocalizedString(@"Crop Page", @"Undo action name")];
    [[self document] undoableActionDoesntDirtyDocument];
    
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
    NSPointerArray *oldRects = [[[NSPointerArray alloc] initWithPointerFunctions:[NSPointerFunctions rectPointerFunctions]] autorelease];
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
    [[self document] undoableActionDoesntDirtyDocument];
    
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
    NSPointerArray *rectArray = [[[NSPointerArray alloc] initWithPointerFunctions:[NSPointerFunctions rectPointerFunctions]] autorelease];
    BOOL emptySelection = NSIsEmptyRect(rect[0]);
    
    if (emptySelection) {
        NSInteger i, j, count = [[pdfView document] pageCount];
        rect[0] = rect[1] = NSZeroRect;
        
        [[self progressController] setMaxValue:(double)MIN(18, count)];
        [[self progressController] setDoubleValue:0.0];
        [[self progressController] setMessage:[NSLocalizedString(@"Cropping Pages", @"Message for progress sheet") stringByAppendingEllipsis]];
        [[self progressController] beginSheetModalForWindow:[self window]];
        
        if (count < 18) {
            for (i = 0; i < count; i++) {
                rect[i % 2] = NSUnionRect(rect[i % 2], [[[pdfView document] pageAtIndex:i] foregroundBox]);
                [[self progressController] incrementBy:1.0];
            }
        } else {
            NSInteger start[3] = {0, count / 2 - 3, count - 6};
            for (j = 0; j < 3; j++) {
                for (i = start[j]; i < start[j] + 6; i++) {
                    rect[i % 2] = NSUnionRect(rect[i % 2], [[[pdfView document] pageAtIndex:i] foregroundBox]);
                    [[self progressController] setDoubleValue:(double)(3 * j + i)];
                }
            }
        }
        CGFloat w = SKMax(NSWidth(rect[0]), NSWidth(rect[1]));
        CGFloat h = SKMax(NSHeight(rect[0]), NSHeight(rect[1]));
        for (j = 0; j < 2; j++)
            rect[j] = NSMakeRect(SKFloor(NSMidX(rect[j]) - 0.5 * w), SKFloor(NSMidY(rect[j]) - 0.5 * h), w, h);
        [rectArray addPointer:rect];
        [rectArray addPointer:rect + 1];
    } else {
        [rectArray addPointer:rect];
    }
    
    [self cropPagesToRects:rectArray];
    [pdfView setCurrentSelectionRect:NSZeroRect];
	
    if (emptySelection) {
        [[self progressController] dismiss:nil];
    }
}

- (IBAction)autoCropAll:(id)sender {
    NSPointerArray *rectArray = [[[NSPointerArray alloc] initWithPointerFunctions:[NSPointerFunctions rectPointerFunctions]] autorelease];
    PDFDocument *pdfDoc = [pdfView document];
    NSInteger i, iMax = [[pdfView document] pageCount];
    
	[[self progressController] setMaxValue:(double)iMax];
	[[self progressController] setDoubleValue:0.0];
	[[self progressController] setMessage:[NSLocalizedString(@"Cropping Pages", @"Message for progress sheet") stringByAppendingEllipsis]];
	[[self progressController] beginSheetModalForWindow:[self window]];
    
    for (i = 0; i < iMax; i++) {
        NSRect rect = [[pdfDoc pageAtIndex:i] foregroundBox];
        [rectArray addPointer:&rect];
        [[self progressController] incrementBy:1.0];
        if (i && i % 10 == 0)
            [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
    }
    [self cropPagesToRects:rectArray];
	
    [[self progressController] dismiss:nil];
}

- (IBAction)smartAutoCropAll:(id)sender {
    NSPointerArray *rectArray = [[[NSPointerArray alloc] initWithPointerFunctions:[NSPointerFunctions rectPointerFunctions]] autorelease];
    PDFDocument *pdfDoc = [pdfView document];
    NSInteger i, iMax = [pdfDoc pageCount];
    NSSize size = NSZeroSize;
    
	[[self progressController] setMaxValue:1.1 * iMax];
	[[self progressController] setDoubleValue:0.0];
	[[self progressController] setMessage:[NSLocalizedString(@"Cropping Pages", @"Message for progress sheet") stringByAppendingEllipsis]];
	[[self progressController] beginSheetModalForWindow:[self window]];
    
    for (i = 0; i < iMax; i++) {
        NSRect bbox = [[pdfDoc pageAtIndex:i] foregroundBox];
        size.width = SKMax(size.width, NSWidth(bbox));
        size.height = SKMax(size.height, NSHeight(bbox));
        [[self progressController] incrementBy:1.0];
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
            [[self progressController] incrementBy:1.0];
            if (i && i % 100 == 0)
                [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
        }
    }
    [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
    [self cropPagesToRects:rectArray];
	
    [[self progressController] dismiss:nil];
}

- (IBAction)autoSelectContent:(id)sender {
    [pdfView autoSelectContent:sender];
}

- (IBAction)getInfo:(id)sender {
    [[SKInfoWindowController sharedInstance] showWindow:self];
}

- (IBAction)changeScaleFactor:(id)sender {
    NSInteger scale = [sender integerValue];

	if (scale >= 10.0 && scale <= 500.0 ) {
		[pdfView setScaleFactor:scale / 100.0f];
		[pdfView setAutoScales:NO];
	}
}

- (void)scaleSheetDidEnd:(SKScaleSheetController *)controller returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
    if (returnCode == NSOKButton)
        [pdfView setScaleFactor:[[controller textField] integerValue]];
}

- (IBAction)chooseScale:(id)sender {
    SKScaleSheetController *scaleSheetController = [[[SKScaleSheetController alloc] init] autorelease];
    
    [[scaleSheetController textField] setIntegerValue:[pdfView scaleFactor]];
    
    [scaleSheetController beginSheetModalForWindow: [self window]
        modalDelegate: self
       didEndSelector: @selector(scaleSheetDidEnd:returnCode:contextInfo:)
          contextInfo: nil];
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
    NSInteger newToolMode = [sender respondsToSelector:@selector(selectedSegment)] ? [sender selectedSegment] : [sender tag];
    [pdfView setToolMode:newToolMode];
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
        statusBar = [[SKStatusBar alloc] initWithFrame:NSMakeRect(0.0, 0.0, NSWidth([splitView frame]), 22.0)];
        [statusBar setAutoresizingMask:NSViewWidthSizable | NSViewMaxYMargin];
        [self updateLeftStatus];
        [self updateRightStatus];
        [statusBar setRightAction:@selector(statusBarClicked:)];
        [statusBar setRightTarget:self];
    }
    [statusBar toggleBelowView:splitView offset:1.0];
    [[NSUserDefaults standardUserDefaults] setBool:[statusBar isVisible] forKey:SKShowStatusBarKey];
}

- (IBAction)searchPDF:(id)sender {
    if ([self isFullScreen]) {
        if ([leftSideWindow state] == NSDrawerClosedState || [leftSideWindow state] == NSDrawerClosingState)
            [leftSideWindow expand];
    } else if ([self leftSidePaneIsOpen] == NO) {
        [self toggleLeftSidePane:sender];
    }
    [searchField selectText:self];
}

- (IBAction)performFit:(id)sender {
    if ([self isFullScreen] || [self isPresentation]) {
        NSBeep();
        return;
    }
    
    PDFDisplayMode displayMode = [pdfView displayMode];
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
    
    // Calculate the new size for the pdfView
    size.width = NSWidth(documentRect);
    if (autoScales)
        size.width /= scaleFactor;
    if (isSingleRow) {
        size.height = NSHeight(documentRect);
    } else {
        size.height = NSHeight([[self pdfView] convertRect:[[[self pdfView] currentPage] boundsForBox:[[self pdfView] displayBox]] fromPage:[[self pdfView] currentPage]]);
        if ([[self pdfView] displaysPageBreaks])
            size.height += 8.0 * scaleFactor;
        size.width += [NSScroller scrollerWidth];
    }
    if (autoScales)
        size.height /= scaleFactor;
    
    // Calculate the new size for the window
    size.width = SKCeil(NSWidth(frame) + size.width - oldSize.width);
    size.height = SKCeil(NSHeight(frame) + size.height - oldSize.height);
    // Align the window frame from the old topleft point and constrain to the screen
    frame.origin.y = NSMaxY(frame) - size.height;
    frame.size = size;
    frame = SKConstrainRect(frame, [[[self window] screen] visibleFrame]);
    
    [[self window] setFrame:frame display:[[self window] isVisible]];
}

- (void)passwordSheetDidEnd:(SKPasswordSheetController *)controller returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
    if (returnCode == NSOKButton) {
        [pdfView takePasswordFrom:[controller textField]];
        if ([[pdfView document] isLocked] == NO)
            [[self document] savePasswordInKeychain:[controller stringValue]];
    }
}

- (IBAction)password:(id)sender {
    SKPasswordSheetController *passwordSheetController = [[[SKPasswordSheetController alloc] init] autorelease];
    
    [passwordSheetController beginSheetModalForWindow: [self window]
        modalDelegate:self 
       didEndSelector:@selector(passwordSheetDidEnd:returnCode:contextInfo:)
          contextInfo:NULL];
}

- (void)bookmarkSheetDidEnd:(SKBookmarkSheetController *)controller returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
    if (returnCode == NSAlertDefaultReturn) {
        SKBookmarkController *bmController = [SKBookmarkController sharedBookmarkController];
        NSString *path = [[self document] fileName];
        NSString *label = [controller stringValue];
        NSUInteger pageIndex = [[pdfView currentPage] pageIndex];
        [bmController addBookmarkForPath:path pageIndex:pageIndex label:label toFolder:[controller selectedFolder]];
    }
}

- (IBAction)addBookmark:(id)sender {
    SKBookmarkSheetController *bookmarkSheetController = [[[SKBookmarkSheetController alloc] init] autorelease];
    
	[bookmarkSheetController setStringValue:[[self document] displayName]];
    
    [bookmarkSheetController beginSheetModalForWindow: [self window]
        modalDelegate:self 
       didEndSelector:@selector(bookmarkSheetDidEnd:returnCode:contextInfo:)
          contextInfo:NULL];
}

- (void)setupBookmarkSheetDidEnd:(SKBookmarkSheetController *)controller returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
    if (returnCode == NSAlertDefaultReturn) {
        SKBookmarkController *bmController = [SKBookmarkController sharedBookmarkController];
        NSDictionary *setup = [[self document] currentDocumentSetup];
        NSString *label = [controller stringValue];
        [bmController addBookmarkForSetup:setup label:label toFolder:[controller selectedFolder]];
    }
}

- (IBAction)addSetupBookmark:(id)sender {
    SKBookmarkSheetController *bookmarkSheetController = [[[SKBookmarkSheetController alloc] init] autorelease];
    
	[bookmarkSheetController setStringValue:[[self document] displayName]];
    
    [bookmarkSheetController beginSheetModalForWindow: [self window]
        modalDelegate:self 
       didEndSelector:@selector(setupBookmarkSheetDidEnd:returnCode:contextInfo:)
          contextInfo:NULL];
}

- (void)sessionBookmarkSheetDidEnd:(SKBookmarkSheetController *)controller returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
    if (returnCode == NSAlertDefaultReturn) {
        SKBookmarkController *bmController = [SKBookmarkController sharedBookmarkController];
        NSString *label = [controller stringValue];
        NSArray *setups = [[NSApp orderedDocuments] valueForKey:@"currentDocumentSetup"];
        [bmController addBookmarkForSetups:setups label:label toFolder:[controller selectedFolder]];
    }
}

- (IBAction)addSessionBookmark:(id)sender {
    SKBookmarkSheetController *bookmarkSheetController = [[[SKBookmarkSheetController alloc] init] autorelease];
    
	[bookmarkSheetController setStringValue:[[self document] displayName]];
    
    [bookmarkSheetController beginSheetModalForWindow: [self window]
        modalDelegate:self 
       didEndSelector:@selector(sessionBookmarkSheetDidEnd:returnCode:contextInfo:)
          contextInfo:NULL];
}

- (IBAction)toggleReadingBar:(id)sender {
    [pdfView toggleReadingBar];
}

- (IBAction)savePDFSettingToDefaults:(id)sender {
    if ([self isFullScreen])
        [[NSUserDefaults standardUserDefaults] setObject:[self currentPDFSettings] forKey:SKDefaultFullScreenPDFDisplaySettingsKey];
    else if ([self isPresentation] == NO)
        [[NSUserDefaults standardUserDefaults] setObject:[self currentPDFSettings] forKey:SKDefaultPDFDisplaySettingsKey];
}

- (void)presentationSheetDidEnd:(SKPresentationOptionsSheetController *)controller returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
    [presentationSheetController release];
    presentationSheetController = nil;
}

- (IBAction)chooseTransition:(id)sender {
    presentationSheetController = [[SKPresentationOptionsSheetController alloc] initForController:self];
    
    [presentationSheetController beginSheetModalForWindow: [self window]
        modalDelegate: self
       didEndSelector: @selector(presentationSheetDidEnd:returnCode:contextInfo:)
          contextInfo: NULL];
}

- (IBAction)toggleCaseInsensitiveSearch:(id)sender {
    mwcFlags.caseInsensitiveSearch = (0 == mwcFlags.caseInsensitiveSearch);
    if ([[searchField stringValue] length])
        [self search:searchField];
}

- (IBAction)toggleWholeWordSearch:(id)sender {
    mwcFlags.wholeWordSearch = (0 == mwcFlags.wholeWordSearch);
    if ([[searchField stringValue] length])
        [self search:searchField];
}

- (IBAction)toggleCaseInsensitiveNoteSearch:(id)sender {
    mwcFlags.caseInsensitiveNoteSearch = (0 == mwcFlags.caseInsensitiveNoteSearch);
    if ([[noteSearchField stringValue] length])
        [self searchNotes:noteSearchField];
}

- (IBAction)toggleLeftSidePane:(id)sender {
    if ([self isFullScreen]) {
        [[SKPDFToolTipWindow sharedToolTipWindow] fadeOut];
        if ([self leftSidePaneIsOpen])
            [leftSideWindow collapse];
        else
            [leftSideWindow expand];
    } else if ([self isPresentation]) {
        if ([leftSideWindow isVisible])
            [self hideLeftSideWindow];
        else
            [self showLeftSideWindowOnScreen:[[self window] screen]];
    } else if (mwcFlags.usesDrawers) {
        if ([self leftSidePaneIsOpen]) {
            if (mwcFlags.leftSidePaneState == SKOutlineSidePaneState || [[searchField stringValue] length])
                [[SKPDFToolTipWindow sharedToolTipWindow] fadeOut];
            [leftSideDrawer close];
        } else {
            [leftSideDrawer openOnEdge:NSMinXEdge];
        }
    } else {
        NSRect sideFrame = [leftSideContentView frame];
        NSRect pdfFrame = [pdfContentView frame];
        
        if ([self leftSidePaneIsOpen]) {
            if (mwcFlags.leftSidePaneState == SKOutlineSidePaneState || [[searchField stringValue] length])
                [[SKPDFToolTipWindow sharedToolTipWindow] fadeOut];
            lastLeftSidePaneWidth = NSWidth(sideFrame); // cache this
            pdfFrame.size.width += lastLeftSidePaneWidth;
            sideFrame.size.width = 0.0;
        } else {
            if(lastLeftSidePaneWidth <= 0.0)
                lastLeftSidePaneWidth = 250.0; // a reasonable value to start
            if (lastLeftSidePaneWidth > 0.5 * NSWidth(pdfFrame))
                lastLeftSidePaneWidth = SKFloor(0.5 * NSWidth(pdfFrame));
            pdfFrame.size.width -= lastLeftSidePaneWidth;
            sideFrame.size.width = lastLeftSidePaneWidth;
        }
        pdfFrame.origin.x = NSMaxX(sideFrame) + [splitView dividerThickness];
        [leftSideContentView setFrame:sideFrame];
        [pdfContentView setFrame:pdfFrame];
        [splitView setNeedsDisplay:YES];
        [[self window] invalidateCursorRectsForView:splitView];
        
        [self splitViewDidResizeSubviews:nil];
    }
    if ([currentLeftSideView isEqual:thumbnailView])
        [thumbnailTableView sizeToFit];
    else if ([currentLeftSideView isEqual:outlineView])
        [outlineView sizeToFit];
    else if ([currentLeftSideView isEqual:findView])
        [findTableView sizeToFit];
    else if ([currentLeftSideView isEqual:groupedFindView])
        [groupedFindTableView sizeToFit];
}

- (IBAction)toggleRightSidePane:(id)sender {
    if ([self isFullScreen]) {
        if ([self rightSidePaneIsOpen])
            [rightSideWindow collapse];
        else
            [rightSideWindow expand];
    } else if ([self isPresentation]) {
        if ([rightSideWindow isVisible])
            [self hideRightSideWindow];
        else
            [self showRightSideWindowOnScreen:[[self window] screen]];
    } else if (mwcFlags.usesDrawers) {
        if ([self rightSidePaneIsOpen])
            [rightSideDrawer close];
        else
            [rightSideDrawer openOnEdge:NSMaxXEdge];
    } else {
        NSRect sideFrame = [rightSideContentView frame];
        NSRect pdfFrame = [pdfContentView frame];
        
        if ([self rightSidePaneIsOpen]) {
            lastRightSidePaneWidth = NSWidth(sideFrame); // cache this
            pdfFrame.size.width += lastRightSidePaneWidth;
            sideFrame.size.width = 0.0;
        } else {
            if(lastRightSidePaneWidth <= 0.0)
                lastRightSidePaneWidth = 250.0; // a reasonable value to start
            if (lastRightSidePaneWidth > 0.5 * NSWidth(pdfFrame))
                lastRightSidePaneWidth = SKFloor(0.5 * NSWidth(pdfFrame));
            pdfFrame.size.width -= lastRightSidePaneWidth;
            sideFrame.size.width = lastRightSidePaneWidth;
        }
        sideFrame.origin.x = NSMaxX(pdfFrame) + [splitView dividerThickness];
        [rightSideContentView setFrame:sideFrame];
        [pdfContentView setFrame:pdfFrame];
        [splitView setNeedsDisplay:YES];
        [[self window] invalidateCursorRectsForView:splitView];
        
        [self splitViewDidResizeSubviews:nil];
    }
    if ([currentRightSideView isEqual:noteView])
        [noteOutlineView sizeToFit];
    else if ([currentRightSideView isEqual:snapshotView])
        [snapshotTableView sizeToFit];
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

- (void)scrollSecondaryPdfView {
    NSPoint point = [pdfView bounds].origin;
    PDFPage *page = [pdfView pageForPoint:point nearest:YES];
    point = [secondaryPdfView convertPoint:[secondaryPdfView convertPoint:[pdfView convertPoint:point toPage:page] fromPage:page] toView:[secondaryPdfView documentView]];
    [secondaryPdfView goToPage:page];
    [[secondaryPdfView documentView] scrollPoint:point];
    [secondaryPdfView layoutDocumentView];
}

- (IBAction)toggleSplitPDF:(id)sender {
    if ([secondaryPdfView window]) {
        
        [secondaryPdfEdgeView removeFromSuperview];
        if ([self isFullScreen])
            [pdfEdgeView setEdges:BDSKNoEdgeMask];
        
    } else {
        
        NSRect frame1, frame2, tmpFrame = [pdfSplitView bounds];
        
        NSDivideRect(tmpFrame, &frame1, &frame2, SKRound(0.7 * NSHeight(tmpFrame)), NSMaxYEdge);
        NSDivideRect(frame2, &tmpFrame, &frame2, [pdfSplitView dividerThickness], NSMaxYEdge);
        
        [pdfEdgeView setFrame:frame1];
        
        if (secondaryPdfView == nil) {
            secondaryPdfEdgeView = [[BDSKEdgeView alloc] initWithFrame:frame2];
            secondaryPdfView = [[SKSecondaryPDFView alloc] initWithFrame:[[secondaryPdfEdgeView contentView] bounds]];
            [secondaryPdfView setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
            [secondaryPdfEdgeView addSubview:secondaryPdfView];
            [secondaryPdfView release];
            [pdfSplitView addSubview:secondaryPdfEdgeView];
            // Because of a PDFView bug, display properties can not be changed before it is placed in a window
            [secondaryPdfView setSynchronizedPDFView:pdfView];
            [secondaryPdfView setBackgroundColor:[pdfView backgroundColor]];
            [secondaryPdfView setDisplaysPageBreaks:NO];
            [secondaryPdfView setShouldAntiAlias:[[NSUserDefaults standardUserDefaults] boolForKey:SKShouldAntiAliasKey]];
            [secondaryPdfView setGreekingThreshold:[[NSUserDefaults standardUserDefaults] floatForKey:SKGreekingThresholdKey]];
            [secondaryPdfView setSynchronizeZoom:YES];
            [secondaryPdfView setDocument:[pdfView document]];
        } else {
            [secondaryPdfEdgeView setFrame:frame2];
            [pdfSplitView addSubview:secondaryPdfEdgeView];
        }
        if ([self isFullScreen]) {
            [secondaryPdfEdgeView setEdges:BDSKMaxYEdgeMask];
            [pdfEdgeView setEdges:BDSKMinYEdgeMask];
        } else {
            [secondaryPdfEdgeView setEdges:BDSKEveryEdgeMask];
            [pdfEdgeView setEdges:BDSKEveryEdgeMask];
        }
        
        [self performSelector:@selector(scrollSecondaryPdfView) withObject:nil afterDelay:0.0];
    }
    
    [pdfSplitView adjustSubviews];
    [[self window] recalculateKeyViewLoop];
    if ([self isFullScreen])
        [[self window] makeFirstResponder:pdfView];
}

- (IBAction)toggleFullScreen:(id)sender {
    if ([self isFullScreen])
        [self exitFullScreen:sender];
    else
        [self enterFullScreen:sender];
}

- (IBAction)togglePresentation:(id)sender {
    if ([self isPresentation])
        [self exitFullScreen:sender];
    else
        [self enterPresentation:sender];
}

@end
