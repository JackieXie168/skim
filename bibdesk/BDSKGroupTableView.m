//
//  BDSKGroupTableView.m
//  Bibdesk
//
//  Created by Adam Maxwell on 10/19/05.
/*
 This software is Copyright (c) 2005,2006
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
#import "NSTableView_BDSKExtensions.h"
#import "NSIndexSet_BDSKExtensions.h"
#import "BDSKTypeSelectHelper.h"
#import "BDSKGroup.h"
#import "BibAuthor.h"
#import "BDSKGroupCell.h"

@interface BDSKGroupCellFormatter : NSFormatter
@end

#pragma mark

@implementation BDSKGroupTableView

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [typeSelectHelper release];
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
    
    BDSKGroupCellFormatter *fomatter = [[BDSKGroupCellFormatter alloc] init];
    [[column dataCell] setFormatter:fomatter];
    [fomatter release];
    
    [super awakeFromNib]; // this updates the font
    
    OBPRECONDITION([[self enclosingScrollView] contentView]);
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleClipViewFrameChangedNotification:)
                                                 name:NSViewFrameDidChangeNotification
                                               object:[[self enclosingScrollView] contentView]];
    
    typeSelectHelper = [[BDSKTypeSelectHelper alloc] init];
    [typeSelectHelper setDataSource:[self delegate]];
    [typeSelectHelper setCyclesSimilarResults:NO];
    [typeSelectHelper setMatchesPrefix:NO];
}

- (BDSKTypeSelectHelper *)typeSelectHelper{
    return typeSelectHelper;
}

- (NSPopUpButtonCell *)popUpHeaderCell{
	return [(BDSKGroupTableHeaderView *)[self headerView] popUpHeaderCell];
}

- (void)reloadData{
    [super reloadData];
    [typeSelectHelper rebuildTypeSelectSearchCache]; // if we resorted or searched, the cache is stale
}

- (void)keyDown:(NSEvent *)theEvent
{
    if ([[theEvent characters] length] == 0)
        return;
    unichar c = [[theEvent characters] characterAtIndex:0];
    unsigned int modifierFlags = ([theEvent modifierFlags] & NSDeviceIndependentModifierFlagsMask & ~NSAlphaShiftKeyMask);
	// modified from NSTableView-OAExtensions.h which uses a shared typeahead helper instance (which we can't access to force it to recache)
	if (![[NSUserDefaults standardUserDefaults] boolForKey:@"DisableTypeAheadSelection"]) {

        // @@ this is a hack; recaching in -reloadData doesn't work for us the first time around, but we don't want to recache on every keystroke
        if([[typeSelectHelper valueForKey:@"searchCache"] count] == 0)
            [typeSelectHelper rebuildTypeSelectSearchCache];

		if (([[NSCharacterSet alphanumericCharacterSet] characterIsMember:c] || ([typeSelectHelper isProcessing] && ![[NSCharacterSet controlCharacterSet] characterIsMember:c])) && modifierFlags == 0) {
			 
			[typeSelectHelper processKeyDownCharacter:c];
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

- (void)tableViewFontChanged:(NSNotification *)note
{
    // overwrite this as we want to change the intercellspacing
    NSString *fontNamePrefKey = [self fontNamePreferenceKey];
    NSString *fontSizePrefKey = [self fontSizePreferenceKey];
    if (fontNamePrefKey == nil || fontSizePrefKey == nil) 
        return;
    NSString *fontName = [[OFPreferenceWrapper sharedPreferenceWrapper] objectForKey:fontNamePrefKey];
    float fontSize = [[OFPreferenceWrapper sharedPreferenceWrapper] floatForKey:fontSizePrefKey];
    NSFont *font = [NSFont fontWithName:fontName size:fontSize];
	
	[self setFont:font];
    
    // This is how IB calculates row height based on font http://lists.apple.com/archives/cocoa-dev/2006/Mar/msg01591.html
    NSSize textSize = [@"" sizeWithAttributes:[NSDictionary dictionaryWithObject:font forKey:NSFontAttributeName]];
    float rowHeight = textSize.height;
    [self setRowHeight:rowHeight];
    
    // default is (3.0, 2.0); use a larger spacing for the gradient and drop highlights
    NSSize intercellSize = NSMakeSize(3.0, 0.5f * rowHeight);
    [self setIntercellSpacing:intercellSize];

	[self tile];
    [self reloadData]; // otherwise the change isn't immediately visible
}

- (void)mouseDown:(NSEvent *)theEvent{
    if ([theEvent clickCount] == 2) {
        NSPoint point = [self convertPoint:[theEvent locationInWindow] fromView:nil];
        int row = [self rowAtPoint:point];
        int column = [self columnAtPoint:point];
        if (row != -1 && column == 0) {
            BDSKGroupCell *cell = [[[self tableColumns] objectAtIndex:0] dataCellForRow:row];
            NSRect iconRect = [cell iconRectForBounds:[self frameOfCellAtColumn:column row:row]];
            if (NSPointInRect(point, iconRect)) {
                [[self delegate] tableView:self doubleClickedOnIconOfRow:row];
                return;
            }
        }
    }
    [super mouseDown:theEvent];
}

- (void)drawHighlightOnRows:(NSIndexSet *)rows usingColor:(NSColor *)highlightColor
{
    NSParameterAssert(rows != nil);
    NSParameterAssert(highlightColor != nil);
    
    float lineWidth = 1.0f;
    float heightOffset = 0.5f * [self intercellSpacing].height;
    
    [self lockFocus];
    [NSGraphicsContext saveGraphicsState];
    
    // use a dark stroke with a light center fill
    [[highlightColor colorWithAlphaComponent:0.2] setFill];
    [[highlightColor colorWithAlphaComponent:0.8] setStroke];
    
    unsigned rowIndex = [rows firstIndex];
    NSRect drawRect;
    NSBezierPath *path;
    
    while(rowIndex != NSNotFound){
        
        drawRect = NSInsetRect([self rectOfRow:rowIndex], lineWidth, 0.5f * heightOffset);
        
        path = [NSBezierPath bezierPathWithRoundRectInRect:drawRect radius:4.0];
        [path setLineWidth:lineWidth];
        [path fill];
        [path stroke];
        
        rowIndex = [rows indexGreaterThanIndex:rowIndex];
    }
    
    [NSGraphicsContext restoreGraphicsState];
    [self unlockFocus];    
}

// we override this private method to draw something nicer than the default ugly black square
// from http://www.cocoadev.com/index.pl?UglyBlackHighlightRectWhenDraggingToNSTableView
// modified to use -intercellSpacing and save/restore graphics state

-(void)_drawDropHighlightOnRow:(int)rowIndex
{
    NSColor *highlightColor = [NSColor alternateSelectedControlColor];
    if(rowIndex == -1){
        float lineWidth = 2.0;
        
        [self lockFocus];
        [NSGraphicsContext saveGraphicsState];
        
        // use a dark stroke with a light center fill
        [[highlightColor colorWithAlphaComponent:0.2] setFill];
        [[highlightColor colorWithAlphaComponent:0.8] setStroke];
        
        NSRect drawRect = NSInsetRect([self visibleRect], 0.5f * lineWidth, 0.5f * lineWidth);
        NSBezierPath *path = [NSBezierPath bezierPathWithRoundRectInRect:drawRect radius:4.0];
        
        [path setLineWidth:lineWidth];
        [path fill];
        [path stroke];
        
        [NSGraphicsContext restoreGraphicsState];
        [self unlockFocus];
    }else{
        [self drawHighlightOnRows:[NSIndexSet indexSetWithIndex:rowIndex] usingColor:highlightColor];
    }
}

// public method for updating the highlights (as when another table's selection changes)
- (void)updateHighlights
{
    [self setNeedsDisplay:YES];
}

- (void)highlightSelectionInClipRect:(NSRect)clipRect
{
    [super highlightSelectionInClipRect:clipRect];
    // check this in case it's been disconnected in one of our reloading optimizations
    id delegate = [self delegate];
    if(delegate != nil)
        [self drawHighlightOnRows:[delegate indexesOfRowsToHighlightInRange:[self rowsInRect:clipRect] tableView:self] usingColor:[NSColor disabledControlTextColor]];
}

- (void)setDelegate:(id <BDSKGroupTableDelegate>)aDelegate
{
    NSAssert1(aDelegate == nil || [(id)aDelegate conformsToProtocol:@protocol(BDSKGroupTableDelegate)], @"%@ does not conform to BDSKGroupTableDelegate protocol", [aDelegate class]);
    [super setDelegate:aDelegate];
}

// make sure that certain rows are only selected as a single selection
- (void)selectRowIndexes:(NSIndexSet *)indexes byExtendingSelection:(BOOL)extend{
    NSIndexSet *singleIndexes = [[self delegate] tableViewSingleSelectionIndexes:self];
    
    // don't extend rows that should be in single selection
    if (extend == YES && [[self selectedRowIndexes] intersectsIndexSet:singleIndexes])
        return;
    // remove single selection rows from multiple selections
    if ((extend == YES || [indexes count] > 1) && [indexes intersectsIndexSet:singleIndexes]) {
        NSMutableIndexSet *mutableIndexes = [[indexes mutableCopy] autorelease];
        [mutableIndexes removeIndexes:singleIndexes];
        indexes = mutableIndexes;
    }
    if ([indexes count] == 0) 
        return;
    
    [super selectRowIndexes:indexes byExtendingSelection:extend];
    // this is needed because we draw multiple selections differently and OAGradientTableView calls this only for deprecated 10.3 methods
    [self setNeedsDisplay:YES];
}

// the default implementation is broken with the above modifications, and would be invalid anyway
- (IBAction)selectAll:(id)sender {
    NSIndexSet *singleIndexes = [[self delegate] tableViewSingleSelectionIndexes:self];
    NSMutableIndexSet *indexes = [NSMutableIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [self numberOfRows])];
    [indexes removeIndexes:singleIndexes];
    if ([indexes count] == 0) {
        return;
    } else if ([indexes count] == 1) {
        [self selectRowIndexes:indexes byExtendingSelection:NO];
    } else {
        // this follows the default implementation: do it in 2 steps to make sure the selectedRow will be the last one
        NSIndexSet *lastIndex = [NSIndexSet indexSetWithIndex:[indexes lastIndex]];
        [indexes removeIndex:[indexes lastIndex]];
        [self selectRowIndexes:indexes byExtendingSelection:NO];
        [self selectRowIndexes:lastIndex byExtendingSelection:YES];
    }
}

// the default implementation would be meaningless anyway as we don't allow empty selection
- (IBAction)deselectAll:(id)sender {
	[self selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
	[self scrollRowToVisible:0];
}

- (NSColor *)backgroundColor {
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"BDSKDisableBackgroundColorForGroupTableKey"])
        return [super backgroundColor];
    
    static NSColor *backgroundColor = nil;
    if (nil == backgroundColor) {
        // from Mail.app on 10.4; should be based on control tint?
        float red = (231.0f/255.0f), green = (237.0f/255.0f), blue = (246.0f/255.0f);
        backgroundColor = [[NSColor colorWithDeviceRed:red green:green blue:blue alpha:1.0] retain];
    }
    return backgroundColor;
}

@end

#pragma mark -

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

#pragma mark -

@implementation BDSKGroupCellFormatter

// this is actually never used, as BDSKGroupCell doesn't go through the formatter for display
- (NSString *)stringForObjectValue:(id)obj{
    OBASSERT([obj isKindOfClass:[BDSKGroup class]]);
    return [[obj name] description];
}

- (NSString *)editingStringForObjectValue:(id)obj{
    OBASSERT([obj isKindOfClass:[BDSKGroup class]]);
    id name = [obj name];
    return [name isKindOfClass:[BibAuthor class]] ? [name originalName] : [name description];
}

- (BOOL)getObjectValue:(id *)obj forString:(NSString *)string errorDescription:(NSString **)error{
    *obj = [[[BDSKGroup alloc] initWithName:string count:0] autorelease];
    return YES;
}

@end
