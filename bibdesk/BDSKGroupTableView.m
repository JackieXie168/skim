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

@interface NSTableView (OAPrivateMethodThatWeUse)
- (NSTableColumn *)_typeAheadSelectionColumn;
@end

@implementation BDSKGroupTableView

- (id)initWithFrame:(NSRect)frame {
    if (self = [super initWithFrame:frame]) {
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)decoder {
	if (self = [super initWithCoder:decoder]) {
	}
	return self;
}

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
    [typeAheadHelper setCyclesSimilarResults:YES];
}

- (void)reloadData{
    [super reloadData];
    [typeAheadHelper rebuildTypeAheadSearchCache]; // if we resorted or searched, the cache is stale
}

// override this private method from Omni's tableview extensions in order to return a string from a dictionary object (which may be OATextWithIconCell or a subclass)
- (NSString *)_typeAheadLabelForRow:(int)row;
{
    id cellValue;
    
    cellValue = [_dataSource tableView:self objectValueForTableColumn:[self _typeAheadSelectionColumn] row:row];
    if ([cellValue isKindOfClass:[NSDictionary class]])
        return [cellValue objectForKey:OATextWithIconCellStringKey];
    if ([cellValue isKindOfClass:[NSString class]])
        return cellValue;
    else if ([cellValue respondsToSelector:@selector(stringValue)])
        return [cellValue stringValue];
    else
        OBASSERT_NOT_REACHED("unable to get a label for cell");
    return @"";
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

@end

@implementation BDSKGroupTableHeaderView 

- (id)initWithTableColumn:(NSTableColumn *)tableColumn
{
    if(![super init])
        return nil;
    
    BDSKHeaderPopUpButtonCell *cell;
    cell = [[BDSKHeaderPopUpButtonCell alloc] initWithHeaderCell:[tableColumn headerCell]];
    
    [tableColumn setHeaderCell:cell];
	[cell setControlView:self]; // need to do this ourselves, as we do not descend from NSControl
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
	NSRect headerRect = [self headerRectOfColumn:column];
    BOOL onPopUp = NO;
	
	if ([cell isKindOfClass:[BDSKHeaderPopUpButtonCell class]] &&
		NSPointInRect(location, [cell popUpRectForBounds:[self headerRectOfColumn:column]])) 
		onPopUp = YES;
	
	if ([delegate respondsToSelector:@selector(tableView:menuForTableHeaderColumn:onPopUp:)]) {
		return [delegate tableView:tableView menuForTableHeaderColumn:tableColumn onPopUp:onPopUp];
	}
	return nil;
}

// this is the default implementation from NSControl. Need this as we can be a controlView
- (void)updateCell:(NSCell *)aCell{
	[self setNeedsDisplay:YES];
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
