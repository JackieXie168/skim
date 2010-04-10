//
//  SKPresentationOptionsSheetController.m
//  Skim
//
//  Created by Christiaan Hofman on 9/28/08.
/*
 This software is Copyright (c) 2008-2010
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

#import "SKPresentationOptionsSheetController.h"
#import <Quartz/Quartz.h>
#import "SKMainWindowController.h"
#import "SKMainDocument.h"
#import "SKDocumentController.h"
#import "SKTransitionInfo.h"
#import "SKThumbnail.h"
#import "SKThumbnailTableView.h"
#import "SKTypeSelectHelper.h"
#import "SKMainWindowController.h"
#import "SKPDFView.h"
#import "SKPDFToolTipWindow.h"
#import "NSWindowController_SKExtensions.h"
#import "NSDocument_SKExtensions.h"
#import "NSGeometry_SKExtensions.h"

#define RIGHTARROW_CHARACTER 0x2192

#define PAGE_COLUMNID @"page"
#define IMAGE_COLUMNID @"image"

#define TRANSITIONSTYLE_KEY @"transitionStyle"
#define DURATION_KEY @"duration"
#define SHOULDRESTRICT_KEY @"shouldRestrict"
#define CONTENTOBJECT_BINDINGNAME @"contentObject"

static NSString *SKTransitionPboardType = @"SKTransitionPboardType";

static char *SKTransitionPropertiesObservationContext;

@implementation SKPresentationOptionsSheetController

@synthesize notesDocumentPopUpButton, tableView, separateCheckButton, boxes, transitionLabels, transitionControls, buttons, objectController, arrayController, separate, transition, transitions, undoManager;
@dynamic pageTransitions, notesDocument, isScrolling;

- (id)initForController:(SKMainWindowController *)aController {
    if (self = [super init]) {
        controller = aController;
        separate = NO;
        transition = [[SKTransitionInfo alloc] init];
        transitions = nil;
    }
    return self;
}

- (void)dealloc {
    [self stopObservingTransitions:[NSArray arrayWithObject:transition]];
    [self stopObservingTransitions:transitions];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
    [[self window] setDelegate:nil];
    [tableView setDelegate:nil];
    [tableView setDataSource:nil];
    SKDESTROY(transition);
    SKDESTROY(transitions);
    SKDESTROY(undoManager);
    SKDESTROY(notesDocumentPopUpButton);
    SKDESTROY(tableView);
    SKDESTROY(separateCheckButton);
    SKDESTROY(boxes);
    SKDESTROY(transitionLabels);
    SKDESTROY(transitionControls);
    SKDESTROY(buttons);
    SKDESTROY(objectController);
    SKDESTROY(arrayController);
    [super dealloc];
}

- (void)handleDocumentsDidChangeNotification:(NSNotification *)note {
    id currentDoc = [[[notesDocumentPopUpButton selectedItem] representedObject] retain];
    
    while ([notesDocumentPopUpButton numberOfItems] > 1)
        [notesDocumentPopUpButton removeItemAtIndex:[notesDocumentPopUpButton numberOfItems] - 1];
    
    id doc;
    NSMutableArray *documents = [NSMutableArray array];
    NSUInteger pageCount = [[controller pdfDocument] pageCount];
    for (doc in [[NSDocumentController sharedDocumentController] documents]) {
        if ([doc isPDFDocument] && doc != [controller document] && [[doc pdfDocument] pageCount] == pageCount)
            [documents addObject:doc];
    }
    NSSortDescriptor *sortDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"displayName" ascending:YES] autorelease];
    [documents sortUsingDescriptors:[NSArray arrayWithObject:sortDescriptor]];
    
    for (doc in documents) {
        [notesDocumentPopUpButton addItemWithTitle:[doc displayName]];
        [[notesDocumentPopUpButton lastItem] setRepresentedObject:doc];
    }
    
    NSInteger docIndex = [notesDocumentPopUpButton indexOfItemWithRepresentedObject:currentDoc];
    [notesDocumentPopUpButton selectItemAtIndex:docIndex == -1 ? 0 : docIndex];
    [currentDoc release];
}

- (void)windowDidLoad {
    // add the filter names to the popup
    NSUInteger i, count = 1 + [[SKTransitionController transitionNames] count];
    
    NSPopUpButton *transitionStylePopUpButton = [transitionControls objectAtIndex:0];
    [transitionStylePopUpButton removeAllItems];
    for (i = 0; i < count; i++) {
        [transitionStylePopUpButton addItemWithTitle:[SKTransitionController localizedNameForStyle:i]];
        [[transitionStylePopUpButton lastItem] setTag:i];
    }
    
    [[notesDocumentPopUpButton itemAtIndex:0] setTitle:NSLocalizedString(@"None", @"Menu item title")];
    
    SKTransitionController *transitionController = [[controller pdfView] transitionController];
    [transition setTransitionStyle:[transitionController transitionStyle]];
    [transition setDuration:[transitionController duration]];
    [transition setShouldRestrict:[transitionController shouldRestrict]];
    [self startObservingTransitions:[NSArray arrayWithObject:transition]];
    
    [separateCheckButton sizeToFit];
    [[transitionControls lastObject] sizeToFit];
    
    SKAutoSizeButtons(buttons, YES);
    
    CGFloat dw = SKAutoSizeLabelFields(transitionLabels, transitionControls, NO);
    
    if (fabs(dw) > 0.0) {
        NSRect frame = [[self window] frame];
        frame.size.width += dw;
        [[self window] setFrame:frame display:NO];
        
        SKShiftAndResizeViews(boxes, -dw, dw);
        SKShiftAndResizeViews([NSArray arrayWithObjects:separateCheckButton, nil], -dw, 0.0);
    }
    
    // collapse the table
    [[self window] setFrame:NSInsetRect([[self window] frame], 0.5 * NSWidth([[tableView enclosingScrollView] frame]) + 4.0, 0.0) display:NO];
    
    [tableView registerForDraggedTypes:[NSArray arrayWithObject:SKTransitionPboardType]];
    
    [tableView setBackgroundColor:[[NSColor controlAlternatingRowBackgroundColors] lastObject]];
    
    SKTypeSelectHelper *typeSelectHelper = [SKTypeSelectHelper typeSelectHelperWithMatchOption:SKFullStringMatch];
    [typeSelectHelper setMatchesImmediately:NO];
    [typeSelectHelper setCyclesSimilarResults:NO];
    [tableView setTypeSelectHelper:typeSelectHelper];
    
    if ([[[controller pdfView] transitionController] pageTransitions]) {
        [[self undoManager] disableUndoRegistration];
        [self setSeparate:YES];
        [[self undoManager] enableUndoRegistration];
    }
    
    // set the current notes document and observe changes for the popup
    [self handleDocumentsDidChangeNotification:nil];
    NSInteger docIndex = [notesDocumentPopUpButton indexOfItemWithRepresentedObject:[controller presentationNotesDocument]];
    [notesDocumentPopUpButton selectItemAtIndex:docIndex > 0 ? docIndex : 0];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleDocumentsDidChangeNotification:) 
                                                 name:SKDocumentDidShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleDocumentsDidChangeNotification:) 
                                                 name:SKDocumentControllerDidRemoveDocumentNotification object:nil];
}

- (void)makeTransitions {
    if (transitions) return;
    
    // determine the table width by getting the largest page label
    NSTableColumn *tableColumn = [tableView tableColumnWithIdentifier:PAGE_COLUMNID];
    id cell = [tableColumn dataCell];
    CGFloat labelWidth = 0.0;
    
    NSMutableArray *array = [NSMutableArray array];
    NSDictionary *dictionary = [transition properties];
    NSEnumerator *ptEnum = [[[[controller pdfView] transitionController] pageTransitions] objectEnumerator];
    SKThumbnail *tn = nil;
    
    for (SKThumbnail *next in [controller thumbnails]) {
        if (tn) {
            SKTransitionInfo *info = [[SKTransitionInfo alloc] init];
            [info setThumbnail:tn];
            [info setLabel:[NSString stringWithFormat:@"%@%C%@", [tn label], RIGHTARROW_CHARACTER, [next label]]];
            [info setProperties:([ptEnum nextObject] ?: dictionary)];
            [array addObject:info];
            [cell setStringValue:[info label]];
            labelWidth = fmax(labelWidth, ceil([cell cellSize].width));
            [info release];
        }
        tn = next;
    }
    
    [tableColumn setMinWidth:labelWidth];
    [tableColumn setMaxWidth:labelWidth];
    [tableColumn setWidth:labelWidth];
    
    NSRect frame = [[tableView enclosingScrollView] frame];
    frame.size.width = 19.0 + [[[tableView tableColumns] valueForKeyPath:@"@sum.width"] doubleValue];
    [[tableView enclosingScrollView] setFrame:frame];
    
    [self setTransitions:array];
}

- (NSString *)windowNibName {
    return @"TransitionSheet";
}

- (void)dismissSheet:(id)sender {
    [[SKPDFToolTipWindow sharedToolTipWindow] orderOut:nil];
    if ([sender tag] == NSCancelButton) {
        [super dismissSheet:sender];
    } else if ([objectController commitEditing]) {
        // don't make changes when nothing was changed
        if ([undoManager canUndo]) {
            SKTransitionController *transitionController = [[controller pdfView] transitionController];
            [transitionController setTransitionStyle:[transition transitionStyle]];
            [transitionController setDuration:[transition duration]];
            [transitionController setShouldRestrict:[transition shouldRestrict]];
            [transitionController setPageTransitions:[self pageTransitions]];
            [[controller undoManager] setActionName:NSLocalizedString(@"Change Transitions", @"Undo action name")];
        }
        [controller setPresentationNotesDocument:[self notesDocument]];
        [super dismissSheet:sender];
    }
}

- (void)setSeparate:(BOOL)newSeparate {
    if (separate != newSeparate) {
        separate = newSeparate;
        
        [[SKPDFToolTipWindow sharedToolTipWindow] orderOut:nil];
        
        NSWindow *window = [self window];
        BOOL isVisible = [window isVisible];
        NSRect frame = [window frame];
        NSView *scrollView = [tableView enclosingScrollView];
        CGFloat extraWidth;
        
        [objectController commitEditing];
        [objectController unbind:CONTENTOBJECT_BINDINGNAME];
        if (separate) {
            [self makeTransitions];
            
            [objectController bind:CONTENTOBJECT_BINDINGNAME toObject:arrayController withKeyPath:@"selection.self" options:nil];
            
            extraWidth = NSWidth([scrollView frame]) + 8.0;
            frame.size.width += extraWidth;
            frame.origin.x -= floor(0.5 * extraWidth);
            [window setFrame:frame display:isVisible animate:isVisible];
            [scrollView setHidden:NO];
        } else {
            [objectController bind:CONTENTOBJECT_BINDINGNAME toObject:self withKeyPath:@"transition" options:nil];
            
            [scrollView setHidden:YES];
            extraWidth = NSWidth([scrollView frame]) + 8.0;
            frame.size.width -= extraWidth;
            frame.origin.x += floor(0.5 * extraWidth);
            [window setFrame:frame display:isVisible animate:isVisible];
        }
        [[[self undoManager] prepareWithInvocationTarget:self] setSeparate:separate == NO];
    }
}

- (void)setTransitions:(NSArray *)newTransitions {
    if (transitions != newTransitions) {
        [[[self undoManager] prepareWithInvocationTarget:self] setTransitions:transitions];
        [self stopObservingTransitions:transitions];
        [transitions release];
        transitions = [newTransitions copy];
        [self startObservingTransitions:transitions];
    }
}

- (NSArray *)pageTransitions {
    if (separate && [transitions count])
        return [transitions valueForKey:@"properties"];
    else
        return nil;
}

- (SKMainDocument *)notesDocument {
    [self window];
    return [[notesDocumentPopUpButton selectedItem] representedObject];
}

- (BOOL)isScrolling {
    return [tableView isScrolling];
}

#pragma mark Undo

- (NSUndoManager *)undoManager {
    if (undoManager == nil)
        undoManager = [[NSUndoManager alloc] init];
    return undoManager;
}

- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow *)sender {
    return [self undoManager];
}

- (void)startObservingTransitions:(NSArray *)infos {
    for (SKTransitionInfo *info in infos) {
        [info addObserver:self forKeyPath:TRANSITIONSTYLE_KEY options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:&SKTransitionPropertiesObservationContext];
        [info addObserver:self forKeyPath:DURATION_KEY options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:&SKTransitionPropertiesObservationContext];
        [info addObserver:self forKeyPath:SHOULDRESTRICT_KEY options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:&SKTransitionPropertiesObservationContext];
    }
}

- (void)stopObservingTransitions:(NSArray *)infos {
    for (SKTransitionInfo *info in infos) {
        [info removeObserver:self forKeyPath:TRANSITIONSTYLE_KEY];
        [info removeObserver:self forKeyPath:DURATION_KEY];
        [info removeObserver:self forKeyPath:SHOULDRESTRICT_KEY];
    }
}

- (void)setValue:(id)value forKey:(NSString *)key ofTransition:(SKTransitionInfo *)info {
    [info setValue:value forKey:key];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (context == &SKTransitionPropertiesObservationContext) {
        SKTransitionInfo *info = (SKTransitionInfo *)object;
        id newValue = [change objectForKey:NSKeyValueChangeNewKey];
        id oldValue = [change objectForKey:NSKeyValueChangeOldKey];
        
        if ([newValue isEqual:[NSNull null]]) newValue = nil;
        if ([oldValue isEqual:[NSNull null]]) oldValue = nil;
        
        if ((newValue || oldValue) && [newValue isEqual:oldValue] == NO)
            [[[self undoManager] prepareWithInvocationTarget:self] setValue:oldValue forKey:keyPath ofTransition:info];
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

#pragma mark NSTableView dataSource and delegate

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tv { return 0; }

- (id)tableView:(NSTableView *)tv objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row { return nil; }

- (BOOL)tableView:(NSTableView *)tv writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard *)pboard {
    SKTransitionInfo *info = [transitions objectAtIndex:[rowIndexes firstIndex]];
    [pboard declareTypes:[NSArray arrayWithObject:SKTransitionPboardType] owner:nil];
    [pboard setPropertyList:[info properties] forType:SKTransitionPboardType];
    return YES;
}

- (NSDragOperation)tableView:(NSTableView *)tv validateDrop:(id < NSDraggingInfo >)info proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)operation {
    if (row >= 0 && row < (NSInteger)[transitions count] && operation == NSTableViewDropOn &&
        nil != [[info draggingPasteboard] availableTypeFromArray:[NSArray arrayWithObject:SKTransitionPboardType]])
        return NSDragOperationEvery;
    return NSDragOperationNone;
}

- (BOOL)tableView:(NSTableView *)tv acceptDrop:(id < NSDraggingInfo >)info row:(NSInteger)row dropOperation:(NSTableViewDropOperation)operation {
    NSPasteboard *pboard = [info draggingPasteboard];
    if ([pboard availableTypeFromArray:[NSArray arrayWithObject:SKTransitionPboardType]]) {
        [[transitions objectAtIndex:row] setProperties:[pboard propertyListForType:SKTransitionPboardType]];
        return YES;
    }
    return NO;
}

- (BOOL)tableView:(NSTableView *)tv hasPDFContextForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    if ([[tableColumn identifier] isEqualToString:IMAGE_COLUMNID])
        return YES;
    return NO;
}

- (id<SKPDFToolTipContext>)tableView:(NSTableView *)tv PDFContextForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    if ([[tableColumn identifier] isEqualToString:IMAGE_COLUMNID])
        return [[controller pdfDocument] pageAtIndex:row];
    return nil;
}

- (void)tableView:(NSTableView *)tv copyRowsWithIndexes:(NSIndexSet *)rowIndexes {
    NSPasteboard *pboard = [NSPasteboard generalPasteboard];
    [pboard declareTypes:[NSArray arrayWithObject:SKTransitionPboardType] owner:nil];
    [pboard setPropertyList:[[transitions objectAtIndex:[rowIndexes firstIndex]] properties] forType:SKTransitionPboardType];
}

- (BOOL)tableView:(NSTableView *)tv canCopyRowsWithIndexes:(NSIndexSet *)rowIndexes {
    return YES;
}

- (void)tableViewPaste:(NSTableView *)tv {
    NSPasteboard *pboard = [NSPasteboard generalPasteboard];
    if ([pboard availableTypeFromArray:[NSArray arrayWithObject:SKTransitionPboardType]])
        [[transitions objectAtIndex:[tableView selectedRow]] setProperties:[pboard propertyListForType:SKTransitionPboardType]];
}

- (BOOL)tableViewCanPaste:(NSTableView *)tv {
    return ([tableView selectedRow] != -1 && [[NSPasteboard generalPasteboard] availableTypeFromArray:[NSArray arrayWithObject:SKTransitionPboardType]]);
}

- (NSArray *)tableView:(NSTableView *)tv typeSelectHelperSelectionItems:(SKTypeSelectHelper *)typeSelectHelper {
    return [transitions valueForKeyPath:@"thumbnail.label"];
}

@end
