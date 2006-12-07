// BDSKMacroEditor.m
// Created by Michael McCracken, January 2005

/*
 This software is Copyright (c) 2005
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

#import "BDSKMacroEditor.h"
#import "BDSKComplexString.h"
#import "BDSKComplexStringFormatter.h"
#import "BDSKScrollableTextField.h"

#define MARGIN 4.0

@interface BDSKMacroEditor (Private)

- (void)endEditingAndOrderOut;

- (void)attachWindow;
- (void)hideWindow;

- (NSRect)currentCellFrame;
- (id)currentCell;

- (void)setExpandedValue:(NSString *)expandedValue;
- (void)setErrorReason:(NSString *)reason errorMessage:(NSString *)message;

- (void)cellFrameDidChange:(NSNotification *)notification;

- (void)setupWindow;
- (NSWindow *)window;

@end

@implementation BDSKMacroEditor

- (id)init {
	if (self = [super init]) {
		control = nil;
		row = -1;
		column = -1;
        [self setupWindow];
	}
	return self;
}

- (void)dealloc {
    [window release];
	[super dealloc];
}

- (BOOL)attachToView:(NSControl *)aControl atRow:(int)aRow column:(int)aColumn withValue:(NSString *)aString {
	if ([self isEditing]) 
		return NO; // we are already busy editing
	
	//OBASSERT([aControl isKindOfClass:[NSForm class]] || [aControl isKindOfClass:[NSTableView class]] || [aControl isKindOfClass:[NSTextField class]]);
	
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	NSView *contentView = [[aControl enclosingScrollView] contentView];
	if (contentView == nil)
		contentView = aControl;
	
	control = [aControl retain];
	row = aRow;
	column = aColumn;
	
	[control scrollRectToVisible:[self currentCellFrame]];
	[self setExpandedValue:aString];
	[self cellFrameDidChange:nil]; // reset the frame and show the window
	
	[nc addObserver:self
		   selector:@selector(controlTextDidChange:)
			   name:NSControlTextDidChangeNotification
			 object:control];
	[nc addObserver:self
		   selector:@selector(controlTextDidEndEditing:)
			   name:NSControlTextDidEndEditingNotification
			 object:control];

	// observe future changes in the frame and the key status of the window
	// if the target control has a scrollview, we should observe its content view, or we won't notice scrolling
	[nc addObserver:self
		   selector:@selector(cellFrameDidChange:)
			   name:NSViewFrameDidChangeNotification
			 object:contentView];
	[nc addObserver:self
		   selector:@selector(cellFrameDidChange:)
			   name:NSViewBoundsDidChangeNotification
			 object:contentView];
	
	return YES;
}

- (BOOL)isEditing {
	return (control != nil);
}

@end

@implementation BDSKMacroEditor (Private)

- (void)endEditingAndOrderOut {
	NSView *contentView = [[control enclosingScrollView] contentView];
	
	if (contentView == nil)
		contentView = control;
	
    // we're going away now, so we can unregister for all notifications
    [[NSNotificationCenter defaultCenter] removeObserver:self];	
	[self hideWindow];
	
	// release the temporary objects
	[control release];
	control = nil; // we should set this to nil, as we use this as a flag that we are editing
	row = -1;
	column = -1;
}

- (void)attachWindow {
	[[control window] addChildWindow:[self window] ordered:NSWindowAbove];
    [[self window] orderFront:self];
}

- (void)hideWindow {
    [[control window] removeChildWindow:[self window]];
    [[self window] orderOut:self];
}

- (id)currentCell {
	return [(NSTextField *)control cell];
}

- (NSRect)currentCellFrame {
	return [(NSTextField*)control bounds];
}

- (void)setExpandedValue:(NSString *)expandedValue {
	NSColor *color = [NSColor blueColor];
	if ([expandedValue isInherited]) 
		color = [color blendedColorWithFraction:0.4 ofColor:[NSColor controlBackgroundColor]];
	[expandedValueTextField setTextColor:color];
	[expandedValueTextField setStringValue:expandedValue];
	[expandedValueTextField setToolTip:NSLocalizedString(@"This field contains macros and is being edited as it would appear in a BibTeX file. This is the expanded value.", @"")];
}

- (void)setErrorReason:(NSString *)reason errorMessage:(NSString *)message {
	[expandedValueTextField setTextColor:[NSColor redColor]];
	[expandedValueTextField setStringValue:reason];
	[expandedValueTextField setToolTip:message]; 
}

#pragma mark Frame change and keywindow notification handlers

- (void)cellFrameDidChange:(NSNotification *)notification {
	NSRectEdge lowerEdge = [control isFlipped] ? NSMaxYEdge : NSMinYEdge;
	NSRect lowerEdgeRect, ignored;
	NSRect winFrame = [[self window] frame];
	NSView *contentView = [[control enclosingScrollView] contentView];
	if (contentView == nil)
		contentView = control;
	
	NSDivideRect([self currentCellFrame], &lowerEdgeRect, &ignored, 1.0, lowerEdge);
	lowerEdgeRect = NSIntersectionRect(lowerEdgeRect, [contentView visibleRect]);
	// see if the cell's lower edge is scrolled out of sight
	if (NSIsEmptyRect(lowerEdgeRect)) {
		if ([[self window] isVisible] == YES) 
			[self hideWindow];
		return;
	}
	
	lowerEdgeRect = [control convertRect:lowerEdgeRect toView:nil]; // takes into account isFlipped
    winFrame.origin = [[control window] convertBaseToScreen:lowerEdgeRect.origin];
	winFrame.origin.y -= NSHeight(winFrame);
	winFrame.size.width = MAX(NSWidth(lowerEdgeRect), 2 * MARGIN);
	[[self window] setFrame:winFrame display:YES];
	
	if ([[self window] isVisible] == NO) 
		[self attachWindow];
}

#pragma mark Window close delegate method

- (void)windowWillClose:(NSNotification *)notification {
	// this gets called whenever an editor window closes
	if ([self isEditing]){
        //OBASSERT_NOT_REACHED("macro textfield window closed while editing");
		[self endEditingAndOrderOut];
    }
}

#pragma mark NSControl notification handlers

- (void)controlTextDidEndEditing:(NSNotification *)notification {
    [self endEditingAndOrderOut];
}

- (void)controlTextDidChange:(NSNotification*)notification { 
    BDSKComplexStringFormatter *formatter = [[self currentCell] formatter];
	//OBASSERT([formatter isKindOfClass:[BDSKComplexStringFormatter class]]);
	NSString *error = [formatter parseError];
	if (error)
		[self setErrorReason:error errorMessage:[NSString stringWithFormat:NSLocalizedString(@"Invalid BibTeX string: %@. This change will not be recorded.", @"Invalid raw bibtex string error message"),error]];
	else
		[self setExpandedValue:[formatter parsedString]];
}

#pragma mark Window

- (NSWindow *)window{
    return window;
}

- (void)setupWindow{
    expandedValueTextField = [[BDSKScrollableTextField alloc] init];
    [expandedValueTextField setDrawsBackground:NO];
    [expandedValueTextField setBordered:NO];
    [expandedValueTextField setEditable:NO];
    [expandedValueTextField sizeToFit];
    [expandedValueTextField setAutoresizingMask:NSViewHeightSizable|NSViewWidthSizable];
    
    NSRect frame = [expandedValueTextField frame];
    frame.origin = NSMakePoint(MARGIN, MARGIN);
    [expandedValueTextField setFrame:frame];
    
    window = [[NSWindow alloc] initWithContentRect:NSInsetRect(frame, -MARGIN, -MARGIN) styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:NO];
    [window setBackgroundColor:[NSColor controlBackgroundColor]];
    [window setOpaque:NO];
    [window setHasShadow:YES];
    [window setAlphaValue:0.9];
    [[window contentView] addSubview:expandedValueTextField];
    
    [expandedValueTextField release];
}

@end

#pragma mark -
#pragma mark Subclass for NSTableView

@implementation MacroTableViewWindowController

- (BOOL)attachToView:(NSControl *)aControl atRow:(int)aRow column:(int)aColumn withValue:(NSString *)aString {
    
    NSParameterAssert([aControl isKindOfClass:[NSTableView class]]);
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self
           selector:@selector(tableViewColumnDidResize:)
               name:NSTableViewColumnDidResizeNotification
             object:control];
    [nc addObserver:self
           selector:@selector(tableViewColumnDidMove:)
               name:NSTableViewColumnDidMoveNotification
             object:control];
    
    return [super attachToView:aControl atRow:aRow column:aColumn withValue:aString];
}

#pragma mark NSTableView notification handlers

- (void)tableViewColumnDidResize:(NSNotification *)notification {
	[self cellFrameDidChange:nil];
}

- (void)tableViewColumnDidMove:(NSNotification *)notification {
	NSDictionary *userInfo = [notification userInfo];
	int oldColumn = [[userInfo objectForKey:@"oldColumn"] intValue];
	int newColumn = [[userInfo objectForKey:@"newColumn"] intValue];
	if (oldColumn == column) {
		column = newColumn;
	} else if (oldColumn < column) {
		if (newColumn >= column)
			column--;
	} else if (oldColumn > column) {
		if (newColumn < column)
			column++;
	}
	[self cellFrameDidChange:nil];
}

- (id)currentCell {
    return [[[(NSTableView*)control tableColumns] objectAtIndex:column] dataCellForRow:row];
}

- (NSRect)currentCellFrame {
	return [(NSTableView*)control frameOfCellAtColumn:column row:row];
}

@end

#pragma mark -
#pragma mark Subclass for NSForm

@implementation MacroFormWindowController

- (BOOL)attachToView:(NSControl *)aControl atRow:(int)aRow column:(int)aColumn withValue:(NSString *)aString {
    NSParameterAssert([aControl isKindOfClass:[NSForm class]]);    
    return [super attachToView:aControl atRow:aRow column:aColumn withValue:aString];
}

- (id)currentCell {
	return [(NSForm *)control cellAtIndex:row];
}

- (NSRect)currentCellFrame {
	NSRect cellFrame = NSZeroRect;
    float offset = [[(NSForm*)control cellAtRow:row column:column] titleWidth] + 4.0;
    NSRect ignored;
    cellFrame = [(NSForm*)control cellFrameAtRow:row column:column];
    NSDivideRect(cellFrame, &ignored, &cellFrame, offset, NSMinXEdge);

	return cellFrame;
}

@end

#pragma mark -
#pragma mark Subclass for NSMatrix

@implementation MacroMatrixWindowController

- (BOOL)attachToView:(NSControl *)aControl atRow:(int)aRow column:(int)aColumn withValue:(NSString *)aString {
    NSParameterAssert([aControl isKindOfClass:[NSMatrix class]]);    
    return [super attachToView:aControl atRow:aRow column:aColumn withValue:aString];
}

- (id)currentCell {
	return [(NSMatrix *)control cellAtRow:row column:column];
}

- (NSRect)currentCellFrame {
	return [(NSMatrix*)control cellFrameAtRow:row column:column];
}


@end


