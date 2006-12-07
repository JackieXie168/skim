//
//  NSTableView_BDSKExtensions.m
//  Bibdesk
//
//  Created by Christiaan Hofman on 10/11/05.
/*
 This software is Copyright (c) 2005,2006
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

#import "NSTableView_BDSKExtensions.h"
#import "BDSKFieldEditor.h"
#import "BibPrefController.h"
#import "NSBezierPath_BDSKExtensions.h"
#import <OmniAppKit/OAApplication.h>
#import <OmniFoundation/OFPreference.h>

@interface NSTableView (BDSKExtensionsPrivate)
- (void)rebuildToolTips;
- (void)replacementSetDataSource:(id)anObject;
- (void)replacementReloadData;
- (void)replacementNoteNumberOfRowsChanged;
- (BOOL)replacementBecomeFirstResponder;
- (void)replacementDealloc;
- (void)replacementDraggedImage:(NSImage *)anImage endedAt:(NSPoint)aPoint operation:(NSDragOperation)operation;
- (NSImage *)replacementDragImageForRowsWithIndexes:(NSIndexSet *)dragRows tableColumns:(NSArray *)tableColumns event:(NSEvent*)dragEvent offset:(NSPointPointer)dragImageOffset;
-(void)_drawDropHighlightOnRow:(int)rowIndex;
@end

#pragma mark -

@implementation NSTableView (BDSKExtensions)

static IMP originalSetDataSource;
static IMP originalReloadData;
static IMP originalNoteNumberOfRowsChanged;
static BOOL (*originalBecomeFirstResponder)(id self, SEL _cmd);
static IMP originalDealloc;
static IMP originalDraggedImageEndedAtOperation;
static IMP originalDragImageForRowsWithIndexesTableColumnsEventOffset;

+ (void)didLoad;
{
    originalSetDataSource = OBReplaceMethodImplementationWithSelector(self, @selector(setDataSource:), @selector(replacementSetDataSource:));
    originalReloadData = OBReplaceMethodImplementationWithSelector(self, @selector(reloadData), @selector(replacementReloadData));
    originalNoteNumberOfRowsChanged = OBReplaceMethodImplementationWithSelector(self, @selector(noteNumberOfRowsChanged), @selector(replacementNoteNumberOfRowsChanged));
    originalBecomeFirstResponder = (typeof(originalBecomeFirstResponder))OBReplaceMethodImplementationWithSelector(self, @selector(becomeFirstResponder), @selector(replacementBecomeFirstResponder));
    originalDealloc = OBReplaceMethodImplementationWithSelector(self, @selector(dealloc), @selector(replacementDealloc));
    originalDraggedImageEndedAtOperation = OBReplaceMethodImplementationWithSelector(self, @selector(draggedImage:endedAt:operation:), @selector(replacementDraggedImage:endedAt:operation:));
    originalDragImageForRowsWithIndexesTableColumnsEventOffset = OBReplaceMethodImplementationWithSelector(self, @selector(dragImageForRowsWithIndexes:tableColumns:event:offset:), @selector(replacementDragImageForRowsWithIndexes:tableColumns:event:offset:));
}

- (BOOL)validateDelegatedMenuItem:(NSMenuItem *)menuItem defaultDataSourceSelector:(SEL)dataSourceSelector{
	SEL action = [menuItem action];
	
	if ([_dataSource respondsToSelector:action]) {
		if ([_dataSource respondsToSelector:@selector(validateMenuItem:)]) {
			return [_dataSource validateMenuItem:menuItem];
		} else {
			return (action == @selector(paste:)) || ([self numberOfSelectedRows] > 0);
		}
	} else if ([_delegate respondsToSelector:action]) {
		if ([_delegate respondsToSelector:@selector(validateMenuItem:)]) {
			return [_delegate validateMenuItem:menuItem];
		} else {
			return (action == @selector(paste:)) || ([self numberOfSelectedRows] > 0);
		}
	} else if ([_dataSource respondsToSelector:dataSourceSelector]) {
		if ([_dataSource respondsToSelector:@selector(validateMenuItem:)]) {
			return [_dataSource validateMenuItem:menuItem];
		} else {
			return (action == @selector(paste:)) || ([self numberOfSelectedRows] > 0);
		}
	}else{
		// no action implemented
		return NO;
	}
}

// this is necessary as the NSTableView-OAExtensions defines these actions accordingly
- (BOOL)validateMenuItem:(NSMenuItem *)menuItem{
	SEL action = [menuItem action];
	if (action == @selector(delete:)) {
		return [self validateDelegatedMenuItem:menuItem defaultDataSourceSelector:@selector(tableView:deleteRows:)];
	}
	else if (action == @selector(deleteForward:)) {
		return [_dataSource respondsToSelector:@selector(tableView:deleteRows:)];
	}
	else if (action == @selector(deleteBackward:)) {
		return [_dataSource respondsToSelector:@selector(tableView:deleteRows:)];
	}
	else if (action == @selector(cut:)) {
		return [self validateDelegatedMenuItem:menuItem defaultDataSourceSelector:@selector(tableView:writeRows:toPasteboard:)];
	}
	else if (action == @selector(copy:)) {
		return [self validateDelegatedMenuItem:menuItem defaultDataSourceSelector:@selector(tableView:writeRows:toPasteboard:)];
	}
	else if (action == @selector(paste:)) {
		return [self validateDelegatedMenuItem:menuItem defaultDataSourceSelector:@selector(tableView:addItemsFromPasteboard:)];
	}
	else if (action == @selector(duplicate:)) {
		return [self validateDelegatedMenuItem:menuItem defaultDataSourceSelector:@selector(tableView:writeRows:toPasteboard:)];
	}
    return YES; // we assume that any other implemented action is always valid
}

#pragma mark Autocompletion

- (NSRange)textView:(NSTextView *)textView rangeForUserCompletion:(NSRange)charRange {
	if (textView == [self currentEditor] && [[self delegate] respondsToSelector:@selector(control:textView:rangeForUserCompletion:)]) 
		return [[self delegate] control:self textView:textView rangeForUserCompletion:charRange];
	return charRange;
}

- (BOOL)textViewShouldAutoComplete:(NSTextView *)textView {
	if (textView == [self currentEditor] && [[self delegate] respondsToSelector:@selector(control:textViewShouldAutoComplete:)]) 
		return [(id)[self delegate] control:self textViewShouldAutoComplete:textView];
	return NO;
}

#pragma mark Font preferences methods

- (NSString *)fontNamePreferenceKey{
    if ([[self delegate] respondsToSelector:@selector(tableViewFontNamePreferenceKey:)])
        return [[self delegate] tableViewFontNamePreferenceKey:self];
    return nil;
}

- (NSString *)fontSizePreferenceKey{
    if ([[self delegate] respondsToSelector:@selector(tableViewFontSizePreferenceKey:)])
        return [[self delegate] tableViewFontSizePreferenceKey:self];
    return nil;
}

- (void)awakeFromNib {
    // there was no original awakeFromNib
    NSString *fontNamePrefKey = [self fontNamePreferenceKey];
    [self tableViewFontChanged:nil];
    if (fontNamePrefKey != nil) {
        [OFPreference addObserver:self
                         selector:@selector(tableViewFontChanged:)
                    forPreference:[OFPreference preferenceForKey:fontNamePrefKey]];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(updateFontPanel:)
                                                     name:NSWindowDidBecomeKeyNotification
                                                   object:[self window]];
    }
}

- (NSControlSize)cellControlSize {
    NSCell *dataCell = [[[self tableColumns] lastObject] dataCell];
    return nil == dataCell ? NSRegularControlSize : [dataCell controlSize];
}

- (void)changeFont:(id)sender {
    NSString *fontNamePrefKey = [self fontNamePreferenceKey];
    NSString *fontSizePrefKey = [self fontSizePreferenceKey];
    if (fontNamePrefKey == nil || fontSizePrefKey == nil) 
        return;
    NSFontManager *fontManager = [NSFontManager sharedFontManager];
    OFPreferenceWrapper *defaults = [OFPreferenceWrapper sharedPreferenceWrapper];
    
    NSString *fontName = [defaults objectForKey:fontNamePrefKey];
    float fontSize = [defaults floatForKey:fontSizePrefKey];
	NSFont *font = nil;
        
    if(fontName != nil)
        font = [NSFont fontWithName:fontName size:fontSize];
    if(font == nil)
        font = [NSFont controlContentFontOfSize:[NSFont systemFontSizeForControlSize:[self cellControlSize]]];
    font = [fontManager convertFont:font];
    
    // set the name last, as that's what we observe
    [defaults setFloat:[font pointSize] forKey:fontSizePrefKey];
    [defaults setObject:[font fontName] forKey:fontNamePrefKey];
}

- (void)tableViewFontChanged:(NSNotification *)notification {
    NSString *fontNamePrefKey = [self fontNamePreferenceKey];
    NSString *fontSizePrefKey = [self fontSizePreferenceKey];
    if (fontNamePrefKey == nil || fontSizePrefKey == nil) 
        return;

    NSString *fontName = [[OFPreferenceWrapper sharedPreferenceWrapper] objectForKey:fontNamePrefKey];
    float fontSize = [[OFPreferenceWrapper sharedPreferenceWrapper] floatForKey:fontSizePrefKey];
	NSFont *font = nil;
    
    if(fontName != nil)
        font = [NSFont fontWithName:fontName size:fontSize];
    if(font == nil)
        font = [NSFont systemFontOfSize:[NSFont systemFontSize]];
	
	[self setFont:font];
    
    NSLayoutManager *lm = [[NSLayoutManager alloc] init];
    [lm setTypesetterBehavior:NSTypesetterBehavior_10_2_WithCompatibility];
    [self setRowHeight:([lm defaultLineHeightForFont:font] + 2.0f)];
    [lm release];
        
	[self tile];
    [self reloadData]; // othewise the change isn't immediately visible
    
}

- (void)updateFontPanel:(NSNotification *)notification {
    NSString *fontNamePrefKey = [self fontNamePreferenceKey];
    NSString *fontSizePrefKey = [self fontSizePreferenceKey];
    if (fontNamePrefKey != nil && fontSizePrefKey != nil) {
        NSString *fontName = [[OFPreferenceWrapper sharedPreferenceWrapper] objectForKey:fontNamePrefKey];
        float fontSize = [[OFPreferenceWrapper sharedPreferenceWrapper] floatForKey:fontSizePrefKey];
        [[NSFontManager sharedFontManager] setSelectedFont:[NSFont fontWithName:fontName size:fontSize] isMultiple:NO];
	}
}

#pragma mark Convenience method

- (void)removeAllTableColumns{
    while ([self numberOfColumns] > 0) {
        [self removeTableColumn:[[self tableColumns] objectAtIndex:0]];
    }
}


// copied from -[NSTableView (OAExtensions) scrollSelectedRowsToVisibility:]
- (void)scrollRowToCenter:(unsigned int)row;
{
    NSRect rowRect = [self rectOfRow:row];
    
    if (NSEqualRects(rowRect, NSZeroRect))
        return;
    
    NSRect visibleRect;
    float heightDifference;
    
    visibleRect = [self visibleRect];
    
    // don't change the scroll position if it's already in view, since that would be unexpected
    if (NSContainsRect(visibleRect, rowRect))
        return;
    
    heightDifference = NSHeight(visibleRect) - NSHeight(rowRect);
    if (heightDifference > 0) {
        // scroll to a rect equal in height to the visible rect but centered on the selected rect
        rowRect = NSInsetRect(rowRect, 0.0, -(heightDifference / 2.0));
    } else {
        // force the top of the selectionRect to the top of the view
        rowRect.size.height = NSHeight(visibleRect);
    }
    [self scrollRectToVisible:rowRect];
}

- (NSArray *)tableColumnIdentifiers { return [[self tableColumns] valueForKey:@"identifier"]; }

@end

#pragma mark -

@implementation NSTableView (BDSKExtensionsPrivate)

#pragma mark ToolTips for individual rows and columns

// These are copied and modified from OAXTableView, as it was removed from NSTableView-OAExtensions

- (void)resetCursorRects {
	[self rebuildToolTips];
}

- (void)replacementSetDataSource:(id)anObject {
	originalSetDataSource(self, _cmd, anObject);
	[self rebuildToolTips];
}

- (void)replacementReloadData {
	originalReloadData(self, _cmd);
	[self rebuildToolTips];
}

- (void)replacementNoteNumberOfRowsChanged {
	originalNoteNumberOfRowsChanged(self, _cmd);
	[self rebuildToolTips];
}

- (void)rebuildToolTips {
    NSRange rowRange, columnRange;
    unsigned int rowIndex, columnIndex;
	NSTableColumn *tableColumn;

    if (![_dataSource respondsToSelector:@selector(tableView:toolTipForTableColumn:row:)])
        return;

    [self removeAllToolTips];
    rowRange = [self rowsInRect:[self visibleRect]];
    columnRange = [self columnsInRect:[self visibleRect]];
    for (columnIndex = columnRange.location; columnIndex < NSMaxRange(columnRange); columnIndex++) {
        tableColumn = [[self tableColumns] objectAtIndex:columnIndex];
		for (rowIndex = rowRange.location; rowIndex < NSMaxRange(rowRange); rowIndex++) {
            if ([_dataSource tableView:self toolTipForTableColumn:tableColumn row:rowIndex] != nil)
                [self addToolTipRect:[self frameOfCellAtColumn:columnIndex row:rowIndex] owner:self userData:NULL];
        }
    }
}

- (NSString *)view:(NSView *)view stringForToolTip:(NSToolTipTag)tag point:(NSPoint)point userData:(void *)data {
    if ([_dataSource respondsToSelector:@selector(tableView:toolTipForTableColumn:row:)]) {
		int column = [self columnAtPoint:point];
		int row = [self rowAtPoint:point];
        if (column == -1 || row == -1)
            return nil;
		NSTableColumn *tableColumn = [[self tableColumns] objectAtIndex:column];
		return [_dataSource tableView:self toolTipForTableColumn:tableColumn row:row];
	}
	return nil;
}

#pragma mark Font preferences overrides

- (BOOL)replacementBecomeFirstResponder {
    [self updateFontPanel:nil];
    return originalBecomeFirstResponder(self, _cmd);
}

- (void)replacementDealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [OFPreference removeObserver:self forPreference:nil];
    originalDealloc(self, _cmd);
}

#pragma mark Dragging and drag image

- (void)replacementDraggedImage:(NSImage *)anImage endedAt:(NSPoint)aPoint operation:(NSDragOperation)operation{
    originalDraggedImageEndedAtOperation(self, _cmd, anImage, aPoint, operation);
	
    if([[self dataSource] respondsToSelector:@selector(tableView:concludeDragOperation:)]) 
		[[self dataSource] tableView:self concludeDragOperation:operation];
    
    // flag changes during a drag are not forwarded to the application, so we fix that at the end of the drag
    [[NSNotificationCenter defaultCenter] postNotificationName:OAFlagsChangedNotification object:[NSApp currentEvent]];
}

- (NSImage *)replacementDragImageForRowsWithIndexes:(NSIndexSet *)dragRows tableColumns:(NSArray *)tableColumns event:(NSEvent*)dragEvent offset:(NSPointPointer)dragImageOffset{
   	if([[self dataSource] respondsToSelector:@selector(tableView:dragImageForRowsWithIndexes:)]) {
		NSImage *image = [[self dataSource] tableView:self dragImageForRowsWithIndexes:dragRows];
		if (image != nil)
			return image;
	}
    if(floor(NSAppKitVersionNumber) > NSAppKitVersionNumber10_3){
        return originalDragImageForRowsWithIndexesTableColumnsEventOffset(self, _cmd, dragRows, tableColumns, dragEvent, dragImageOffset);
    } else {
        return nil;
    }
}

#pragma mark Drop highlight

// we override this private method to draw something nicer than the default ugly black square
// from http://www.cocoadev.com/index.pl?UglyBlackHighlightRectWhenDraggingToNSTableView
// modified to use -intercellSpacing and save/restore graphics state

-(void)_drawDropHighlightOnRow:(int)rowIndex{
    NSColor *highlightColor = [NSColor alternateSelectedControlColor];
    float lineWidth = 2.0;
    
    [self lockFocus];
    [NSGraphicsContext saveGraphicsState];
    
    NSRect drawRect = (rowIndex == -1) ? [self visibleRect] : [self rectOfRow:rowIndex];
    
    drawRect = NSInsetRect(drawRect, 0.5f * lineWidth, 0.5f * lineWidth);
    
    NSBezierPath *path = [NSBezierPath bezierPathWithRoundRectInRect:drawRect radius:4.0];
    
    [path setLineWidth:lineWidth];
    
    [[highlightColor colorWithAlphaComponent:0.2] set];
    [path fill];
    
    [[highlightColor colorWithAlphaComponent:0.8] set];
    [path stroke];
    
    [NSGraphicsContext restoreGraphicsState];
    [self unlockFocus];
}

@end
