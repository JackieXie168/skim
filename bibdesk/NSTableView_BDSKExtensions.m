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

@implementation NSTableView (BDSKExtensions)

static IMP originalSetDataSource;
static IMP originalReloadData;
static IMP originalNoteNumberOfRowsChanged;
static BOOL (*originalBecomeFirstResponder)(id self, SEL _cmd);
static IMP originalDealloc;

+ (void)didLoad;
{
    originalSetDataSource = OBReplaceMethodImplementationWithSelector(self, @selector(setDataSource:), @selector(replacementSetDataSource:));
    originalReloadData = OBReplaceMethodImplementationWithSelector(self, @selector(reloadData), @selector(replacementReloadData));
    originalNoteNumberOfRowsChanged = OBReplaceMethodImplementationWithSelector(self, @selector(noteNumberOfRowsChanged), @selector(replacementNoteNumberOfRowsChanged));
    originalBecomeFirstResponder = (typeof(originalBecomeFirstResponder))OBReplaceMethodImplementationWithSelector(self, @selector(becomeFirstResponder), @selector(replacementBecomeFirstResponder));
    originalDealloc = OBReplaceMethodImplementationWithSelector(self, @selector(dealloc), @selector(replacementDealloc));
}

- (BOOL)validateDelegatedMenuItem:(id<NSMenuItem>)menuItem defaultDataSourceSelector:(SEL)dataSourceSelector{
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
- (BOOL)validateMenuItem:(id<NSMenuItem>)menuItem{
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
    int rowIndex, columnIndex;
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
		NSTableColumn *tableColumn = [[self tableColumns] objectAtIndex:[self columnAtPoint:point]];
		int row = [self rowAtPoint:point];
		return [_dataSource tableView:self toolTipForTableColumn:tableColumn row:row];
	}
	return nil;
}

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

- (NSString *)fontChangedNotificationName{
    if ([[self delegate] respondsToSelector:@selector(tableViewFontChangedNotificationName:)])
        return [[self delegate] tableViewFontChangedNotificationName:self];
    return nil;
}

- (BOOL)replacementBecomeFirstResponder {
    [self updateFontPanel:nil];
    return originalBecomeFirstResponder(self, _cmd);
}

- (void)replacementDealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    originalDealloc(self, _cmd);
}

- (void)awakeFromNib {
    // there was no original awakeFromNib
    NSString *fontChangedNoteName = [self fontChangedNotificationName];
    [self tableViewFontChanged:nil];
    if (fontChangedNoteName != nil) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(tableViewFontChanged:)
                                                     name:fontChangedNoteName
                                                   object:nil];
     }
     if ([self fontNamePreferenceKey] != nil) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(updateFontPanel:)
                                                     name:NSWindowDidBecomeKeyNotification
                                                   object:[self window]];
    }
}

- (void)changeFont:(id)sender {
    NSString *fontNamePrefKey = [self fontNamePreferenceKey];
    NSString *fontSizePrefKey = [self fontSizePreferenceKey];
    if (fontNamePrefKey == nil || fontSizePrefKey == nil) 
        return;
	NSFontManager *fontManager = [NSFontManager sharedFontManager];
	NSFont *selectedFont = [fontManager selectedFont];
	if (selectedFont == nil)
		selectedFont = [NSFont systemFontOfSize:[NSFont systemFontSize]];
	NSFont *font = [fontManager convertFont:selectedFont];
    
    [[OFPreferenceWrapper sharedPreferenceWrapper] setObject:[font fontName] forKey:fontNamePrefKey];
    [[OFPreferenceWrapper sharedPreferenceWrapper] setFloat:[font pointSize] forKey:fontSizePrefKey];
    
    NSString *fontChangedNoteName = [self fontChangedNotificationName];
    if (fontChangedNoteName != nil) 
        [[NSNotificationCenter defaultCenter] postNotificationName:fontChangedNoteName object:self];
    else 
        [self tableViewFontChanged:nil];
}

- (void)tableViewFontChanged:(NSNotification *)notification {
    NSString *fontNamePrefKey = [self fontNamePreferenceKey];
    NSString *fontSizePrefKey = [self fontSizePreferenceKey];
    if (fontNamePrefKey == nil || fontSizePrefKey == nil) 
        return;
    NSString *fontName = [[OFPreferenceWrapper sharedPreferenceWrapper] objectForKey:fontNamePrefKey];
    float fontSize = [[OFPreferenceWrapper sharedPreferenceWrapper] floatForKey:fontSizePrefKey];
    NSFont *font = [NSFont fontWithName:fontName size:fontSize];
	
	[self setFont:font];
    
    NSLayoutManager *lm = [[NSLayoutManager alloc] init];
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

@end
