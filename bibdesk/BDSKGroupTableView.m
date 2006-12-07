//
//  BDSKGroupTableView.m
//  Bibdesk
//
//  Created by Adam Maxwell on 10/19/05.
/*
 This software is Copyright (c) 2005
 Adam Maxwell. All rights reserved.
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:
 
 - Redistributions of source code must retain the above copyright
 notice, this list of conditions and the following disclaimer.
 
 - Redistributions in binary form must reproduce the above copyright
 notice, this list of conditions and the following disclaimer in
 the documentation and/or other materials provided with the
 distribution.
 
 - Neither the name of Adam Maxwell nor the names of any
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

#import "BDSKGroupTableView.h"
#import <OmniBase/OmniBase.h>
#import <OmniAppKit/OmniAppKit.h>
#import "BibPrefController.h"
#import <OmniFoundation/NSString-OFExtensions.h>
#import "BDSKHeaderPopUpButtonCell.h"
#import "NSBezierPath_BDSKExtensions.h"
#import "BibDocument_Groups.h"

@implementation BDSKGroupTableView

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [typeAheadHelper release];
    [super dealloc];
}

- (void)awakeFromNib
{
    if([self numberOfColumns] == 0) 
		[NSException raise:BDSKUnimplementedException format:@"%@ needs at least one column.", [self class]];
    NSTableColumn *column = [[self tableColumns] objectAtIndex:0];
    OBPRECONDITION(column);
 	
	NSTableHeaderView *currentTableHeaderView = [self headerView];
	BDSKGroupTableHeaderView *customTableHeaderView = [[BDSKGroupTableHeaderView alloc] initWithTableColumn:column];
	
	[customTableHeaderView setFrame:[currentTableHeaderView frame]];
	[customTableHeaderView setBounds:[currentTableHeaderView bounds]];
	
	[self setHeaderView:customTableHeaderView];	
    [customTableHeaderView release];
    
    [self handleFontChangedNotification:nil];
    
	[[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleFontChangedNotification:)
                                                 name:BDSKTableViewFontChangedNotification
                                               object:nil];
	
    OBPRECONDITION([[self enclosingScrollView] contentView]);
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleClipViewFrameChangedNotification:)
                                                 name:NSViewFrameDidChangeNotification
                                               object:[[self enclosingScrollView] contentView]];
    
    typeAheadHelper = [[OATypeAheadSelectionHelper alloc] init];
    [typeAheadHelper setDataSource:[self delegate]];
    [typeAheadHelper setCyclesSimilarResults:NO];
}

- (void)reloadData{
    [super reloadData];
    [typeAheadHelper rebuildTypeAheadSearchCache]; // if we resorted or searched, the cache is stale
}

- (void)keyDown:(NSEvent *)theEvent
{
    unichar c = [[theEvent characters] characterAtIndex:0];
	// modified from NSTableView-OAExtensions.h which uses a shared typeahead helper instance (which we can't access to force it to recache)
	if (![[NSUserDefaults standardUserDefaults] boolForKey:@"DisableTypeAheadSelection"]) {

        // @@ this is a hack; recaching in -reloadData doesn't work for us the first time around, but we don't want to recache on every keystroke
        if([[typeAheadHelper valueForKey:@"typeAheadSearchCache"] count] == 0)
            [typeAheadHelper rebuildTypeAheadSearchCache];

		if (([[NSCharacterSet alphanumericCharacterSet] characterIsMember:c] || ([typeAheadHelper isProcessing] && ![[NSCharacterSet controlCharacterSet] characterIsMember:c]))) {
			 
			[typeAheadHelper processKeyDownCharacter:c];
			return;
		}
	}
    [self interpretKeyEvents:[NSArray arrayWithObject:theEvent]];
}

- (void)handleClipViewFrameChangedNotification:(NSNotification *)note
{
    // work around for bug where corner view doesn't get redrawn after scrollers hide
    [[self cornerView] setNeedsDisplay:YES];
}

- (void)handleFontChangedNotification:(NSNotification *)note
{
    // The font we're using now
    NSFont *font = [NSFont fontWithName:[[OFPreferenceWrapper sharedPreferenceWrapper] objectForKey:BDSKTableViewFontKey]
                                   size:[[OFPreferenceWrapper sharedPreferenceWrapper] floatForKey:BDSKTableViewFontSizeKey]];
	
	[self setFont:font];
    // let the cell calculate the row height for us, so the text baseline isn't fouled up
    float rowHeight = [[[[self tableColumns] objectAtIndex:0] dataCell] cellSize].height;
    [self setRowHeight:rowHeight];
    
    // default is (3.0, 2.0); use a larger spacing for the gradient and drop highlights
    NSSize intercellSize = NSMakeSize(3.0, rowHeight / 2);
    [self setIntercellSpacing:intercellSize];
    
	[self tile];
    [self reloadData]; // otherwise the change isn't immediately visible
}

- (void)drawDropHighlightOnRow:(int)rowIndex usingColor:(NSColor *)highlightColor
{
    float widthOffset = [self intercellSpacing].width;
    float heightOffset = [self intercellSpacing].height / 2;
    
    [self lockFocus];
    [NSGraphicsContext saveGraphicsState];
    
    NSRect drawRect = [self rectOfRow:rowIndex];
    
    drawRect.size.width -= widthOffset;
    drawRect.origin.x += widthOffset/2.0;
    
    drawRect.size.height -= heightOffset;
    drawRect.origin.y += heightOffset/2.0;
    
    [[highlightColor colorWithAlphaComponent:0.2] set];
    [NSBezierPath fillRoundRectInRect:drawRect radius:4.0];
    
    [[highlightColor colorWithAlphaComponent:0.8] set];
    [NSBezierPath setDefaultLineWidth:1.5];
    [NSBezierPath strokeRoundRectInRect:drawRect radius:4.0];
    
    [NSGraphicsContext restoreGraphicsState];
    [self unlockFocus];
}

// we override this private method to draw something nicer than the default ugly black square
// from http://www.cocoadev.com/index.pl?UglyBlackHighlightRectWhenDraggingToNSTableView
// modified to use -intercellSpacing and save/restore graphics state

-(void)_drawDropHighlightOnRow:(int)rowIndex
{
    [self drawDropHighlightOnRow:rowIndex usingColor:[NSColor alternateSelectedControlColor]];
}

// public method for updating the highlights (as when another table's selection changes)
- (void)updateHighlights
{
    [self setNeedsDisplay:YES];
}

- (void)drawHighlightOnRows:(NSIndexSet *)rows
{
    unsigned row = [rows firstIndex];
    
    while(row != NSNotFound){
		if([self isRowSelected:row] == NO)
			[self drawDropHighlightOnRow:row usingColor:[NSColor disabledControlTextColor]];
        row = [rows indexGreaterThanIndex:row];
    }
}

- (void)highlightSelectionInClipRect:(NSRect)clipRect
{
    [super highlightSelectionInClipRect:clipRect];
    
    if(floor(NSAppKitVersionNumber) <= NSAppKitVersionNumber10_2)
        return;
    
    [self drawHighlightOnRows:[[self delegate] indexesOfRowsToHighlightInRange:[self rowsInRect:clipRect] tableView:self]];
}

- (void)setDelegate:(id <BDSKGroupTableDelegate>)aDelegate
{
    NSAssert1(aDelegate == nil || [(id)aDelegate conformsToProtocol:@protocol(BDSKGroupTableDelegate)], @"%@ does not conform to BDSKGroupTableDelegate protocol", [aDelegate class]);
    [super setDelegate:aDelegate];
}

// @@ legacy implementation for 10.3 compatibility
- (NSImage *)dragImageForRows:(NSArray *)dragRows event:(NSEvent *)dragEvent dragImageOffset:(NSPointPointer)dragImageOffset{
    NSMutableIndexSet *indexes = [NSMutableIndexSet indexSet];
    NSNumber *number;
    NSEnumerator *rowE = [dragRows objectEnumerator];
    while(number = [rowE nextObject])
        [indexes addIndex:[number intValue]];
    
    NSPoint zeroPoint = NSMakePoint(0,0);
	return [self dragImageForRowsWithIndexes:indexes tableColumns:[self tableColumns] event:dragEvent offset:&zeroPoint];
}

- (NSImage *)dragImageForRowsWithIndexes:(NSIndexSet *)dragRows tableColumns:(NSArray *)tableColumns event:(NSEvent*)dragEvent offset:(NSPointPointer)dragImageOffset{
   	if([[self dataSource] respondsToSelector:@selector(tableView:dragImageForRowsWithIndexes:)]) {
		NSImage *image = [[self dataSource] tableView:self dragImageForRowsWithIndexes:dragRows];
		if (image != nil)
			return image;
	}
    return [super dragImageForRowsWithIndexes:dragRows tableColumns:tableColumns event:dragEvent offset:dragImageOffset];
}

- (void)draggedImage:(NSImage *)anImage endedAt:(NSPoint)aPoint operation:(NSDragOperation)operation {
	[super draggedImage:anImage endedAt:aPoint operation:operation];
	if([[self dataSource] respondsToSelector:@selector(tableView:concludeDragOperation:)]) 
		[[self dataSource] tableView:self concludeDragOperation:operation];
}

// make sure we never select the first row together with any other row
- (void)selectRowIndexes:(NSIndexSet *)indexes byExtendingSelection:(BOOL)extend{
	if ([self isRowSelected:0]) {
		if ([indexes containsIndex:0] && [indexes count] > 1) {
			NSMutableIndexSet *mutableIndexes = [indexes mutableCopy];
			[mutableIndexes removeIndex:0];
			indexes = [mutableIndexes autorelease];
		}
		extend = NO;
	} else if ([indexes containsIndex:0]) {
		indexes = [NSIndexSet indexSetWithIndex:0];
		extend = NO;
	}
	[super selectRowIndexes:indexes byExtendingSelection:extend];
}

// the default implementation is broken with the above modifications, and would be invalid anyway
- (IBAction)selectAll:(id)sender {
	int numRows = [self numberOfRows];
	if (numRows == 1) 
		return;
	// this follows the default implementation: do it in 2 steps to make sure the selectedRow will be the last one
	if (numRows > 2)
		[self selectRowIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(1,numRows - 2)] byExtendingSelection:NO];
	[self selectRowIndexes:[NSIndexSet indexSetWithIndex:numRows - 1] byExtendingSelection:YES];
}

// the default implementation would be meaningless anyway as we don't allow empty selection
- (IBAction)deselectAll:(id)sender {
	[self selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
	[self scrollRowToVisible:0];
}

@end

@implementation BDSKGroupTableHeaderView 

- (id)initWithTableColumn:(NSTableColumn *)tableColumn
{
    if(![super init])
        return nil;
    
    BDSKHeaderPopUpButtonCell *cell;
    cell = [[BDSKHeaderPopUpButtonCell alloc] initWithHeaderCell:[tableColumn headerCell]];
        
    [tableColumn setHeaderCell:cell];
    [cell release];
    
    return self;
}

- (void)dealloc
{
    [super dealloc];
}

- (void)mouseDown:(NSEvent *)theEvent
{
    NSPoint location = [self convertPoint:[theEvent locationInWindow] fromView:nil];
    
    int colIndex = [self columnAtPoint:location];
    OBASSERT(colIndex != -1);
    if(colIndex == -1)
        return;
    
    NSTableColumn *column = [[[self tableView] tableColumns] objectAtIndex:colIndex];
    id cell = [column headerCell];
	NSRect headerRect = [self headerRectOfColumn:colIndex];
    
	if ([cell isKindOfClass:[BDSKHeaderPopUpButtonCell class]]) {
		if (NSPointInRect(location, [cell popUpRectForBounds:headerRect])) {
			[cell trackMouse:theEvent 
					  inRect:headerRect 
					  ofView:self 
				untilMouseUp:YES];
		} else {
			[super mouseDown:theEvent];
		}
	} else {
		[super mouseDown:theEvent];
	}
}

- (NSMenu *)menuForEvent:(NSEvent *)theEvent {
	BDSKGroupTableView *tableView = (BDSKGroupTableView *)[self tableView];
	id delegate = [tableView delegate];
	NSPoint location = [self convertPoint:[theEvent locationInWindow] fromView:nil];
	int column = [self columnAtPoint:location];
	
	if (column == -1)
		return nil;
	
	NSTableColumn *tableColumn = [[tableView tableColumns] objectAtIndex:column];
    id cell = [tableColumn headerCell];
    BOOL onPopUp = NO;
		
	if ([cell isKindOfClass:[BDSKHeaderPopUpButtonCell class]] &&
		NSPointInRect(location, [cell popUpRectForBounds:[self headerRectOfColumn:column]])) 
		onPopUp = YES;
		
	if ([delegate respondsToSelector:@selector(tableView:menuForTableHeaderColumn:onPopUp:)]) {
		return [delegate tableView:tableView menuForTableHeaderColumn:tableColumn onPopUp:onPopUp];
	}
	return nil;
}

- (NSPopUpButtonCell *)popUpHeaderCell{
	id headerCell = [[[[self tableView] tableColumns] objectAtIndex:0] headerCell];
	OBASSERT([headerCell isKindOfClass:[NSPopUpButtonCell class]]);
	return headerCell;
}

@end

@implementation BDSKGroupTextFieldCell 

- (NSColor *)textColor;
{
    if (_cFlags.highlighted)
        return [NSColor textBackgroundColor];
    else
        return [super textColor];
}

@end
