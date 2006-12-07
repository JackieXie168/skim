// BDSKMainTableView.m

/*
 This software is Copyright (c) 2002,2003,2004,2005,2006
 Michael O. McCracken. All rights reserved.

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:

 - Redistributions of source code must retain the above copyright
   notice, this list of conditions and the following disclaimer.

 - Redistributions in binary form must reproduce the above copyright
    notice, this list of conditions and the following disclaimer in
    the documentation and/or other materials provided with the
    distribution.

 - Neither the name of Michael O. McCracken nor the names of any
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

#import "BDSKMainTableView.h"
#import <OmniFoundation/OFPreference.h>
#import <OmniFoundation/CFArray-OFExtensions.h>
#import "BibPrefController.h"
#import "BibDocument.h"
#import "BDSKTypeSelectHelper.h"
#import "NSTableView_BDSKExtensions.h"

@implementation BDSKMainTableView

- (void)awakeFromNib{
    [super awakeFromNib]; // this updates the font
    typeSelectHelper = [[BDSKTypeSelectHelper alloc] init];
    [typeSelectHelper setDataSource:[self delegate]]; // which is the bibdocument
    [typeSelectHelper setCyclesSimilarResults:YES];
    [typeSelectHelper setMatchesPrefix:NO];
}

- (void)dealloc{
    [typeSelectHelper setDataSource:nil];
    [typeSelectHelper release];
    [trackingRects release];
    [super dealloc];
}

- (BDSKTypeSelectHelper *)typeSelectHelper{
    return typeSelectHelper;
}

- (void)keyDown:(NSEvent *)event{
    if ([[event characters] length] == 0)
        return;
    unichar c = [[event characters] characterAtIndex:0];
    NSCharacterSet *alnum = [NSCharacterSet alphanumericCharacterSet];
    unsigned int flags = ([event modifierFlags] & 0xffff0000U);
    if (c == 0x0020){ // spacebar to page down in the lower pane of the BibDocument splitview, shift-space to page up
        if([event modifierFlags] & NSShiftKeyMask)
            [[self delegate] pageUpInPreview:nil];
        else
            [[self delegate] pageDownInPreview:nil];
	// somehow alternate menu item shortcuts are not available globally, so we catch them here
	}else if((c == NSDeleteCharacter) &&  ([event modifierFlags] & NSAlternateKeyMask)) {
		[[self delegate] alternateDelete:nil];
    // following methods should solve the mysterious problem of arrow/page keys not working for some users
    }else if(c == NSPageDownFunctionKey){
        [[self enclosingScrollView] pageDown:self];
    }else if(c == NSPageUpFunctionKey){
        [[self enclosingScrollView] pageUp:self];
    }else if(c == NSUpArrowFunctionKey){
        int row = [[self selectedRowIndexes] firstIndex];
		if (row == NSNotFound)
			row = 0;
		else if (row > 0)
			row--;
        [self selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:([event modifierFlags] | NSShiftKeyMask)];
        [self scrollRowToVisible:row];
    }else if(c == NSDownArrowFunctionKey){
        int row = [[self selectedRowIndexes] lastIndex];
		if (row == NSNotFound)
			row = 0;
		else if (row < [self numberOfRows] - 1)
			row++;
        [self selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:([event modifierFlags] | NSShiftKeyMask)];
        [self scrollRowToVisible:row];
    // pass it on the typeahead selector
    }else if ([alnum characterIsMember:c] && flags == 0) {
        [typeSelectHelper processKeyDownCharacter:c];
    }else{
        [super keyDown:event];
    }
}

#pragma mark Tracking rects

- (void)reloadData{
    [super reloadData];
    [typeSelectHelper queueSelectorOnce:@selector(rebuildTypeSelectSearchCache)]; // if we resorted or searched, the cache is stale
	[self rebuildTrackingRects];
}

- (void)resetCursorRects {
	[super resetCursorRects];
    [self rebuildTrackingRects];
}

- (void)setDataSource:(id)anObject {
	[super setDataSource:anObject];
	[self rebuildTrackingRects];
}

- (void)noteNumberOfRowsChanged {
	[super noteNumberOfRowsChanged];
	[self rebuildTrackingRects];
}

- (void)rebuildTrackingRects {
    if ([[self delegate] respondsToSelector:@selector(tableView:shouldTrackTableColumn:row:)] == NO)
        return;
    
    if(trackingRects == nil){
       trackingRects = OFCreateIntegerArray();
    }else{
        CFIndex idx = [trackingRects count];
        while(idx--){
            [self removeTrackingRect:(NSTrackingRectTag)[trackingRects objectAtIndex:idx]];
            [trackingRects removeObjectAtIndex:idx];
        }
    }
    
    NSRange rowRange = [self rowsInRect:[self visibleRect]];
    NSRange columnRange = [self columnsInRect:[self visibleRect]];
    int rowIndex, columnIndex;
	NSTableColumn *tableColumn;
    NSTrackingRectTag tag;
    BOOL assumeInside = [[self delegate] respondsToSelector:@selector(tableView:mouseEnteredTableColumn:row:)];
    
    for (columnIndex = columnRange.location; columnIndex < NSMaxRange(columnRange); columnIndex++) {
        tableColumn = [[self tableColumns] objectAtIndex:columnIndex];
		for (rowIndex = rowRange.location; rowIndex < NSMaxRange(rowRange); rowIndex++) {
            if ([[self delegate] tableView:self shouldTrackTableColumn:tableColumn row:rowIndex]) {
                tag = [self addTrackingRect:[self frameOfCellAtColumn:columnIndex row:rowIndex] owner:self userData:NULL assumeInside:assumeInside];
                [trackingRects addObject:(id)tag];
            }
        }
    }
}

- (void)mouseEntered:(NSEvent *)theEvent{
    if ([[self delegate] respondsToSelector:@selector(tableView:mouseEnteredTableColumn:row:)]) {
        NSPoint point = [self convertPoint:[theEvent locationInWindow] fromView:nil];
		int column = [self columnAtPoint:point];
		int row = [self rowAtPoint:point];
        if (column != -1 && row != -1) {
            NSTableColumn *tableColumn = [[self tableColumns] objectAtIndex:column];
            [[self delegate] tableView:self mouseEnteredTableColumn:tableColumn row:row];
        }
	}
}

- (void)mouseExited:(NSEvent *)theEvent{
    if ([[self delegate] respondsToSelector:@selector(tableView:mouseExitedTableColumn:row:)]) {
        NSPoint point = [self convertPoint:[theEvent locationInWindow] fromView:nil];
		int column = [self columnAtPoint:point];
		int row = [self rowAtPoint:point];
        if (column != -1 && row != -1) {
            NSTableColumn *tableColumn = [[self tableColumns] objectAtIndex:column];
            [[self delegate] tableView:self mouseExitedTableColumn:tableColumn row:row];
        }
	}
}

- (IBAction)deleteForward:(id)sender{
    // we use the same for Delete and the Backspace
    // Omni's implementation of deleteForward: selects the next item, which selects the wrong item too early because we may delay for the warning
    [self deleteBackward:sender];
}

@end
