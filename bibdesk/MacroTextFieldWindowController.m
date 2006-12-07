// MacroTextFieldWindowController.m
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

#import "MacroTextFieldWindowController.h"


@interface MacroTextFieldWindowController (Private)

- (void)endEditingAndOrderOut;
- (void)setExpandedValue:(NSString *)expandedValue;
- (void)setErrorReason:(NSString *)reason errorMessage:(NSString *)message;

- (void)cellFrameChanged:(NSNotification *)aNotification;
- (void)cellWindowDidBecomeKey:(NSNotification *)aNotification;
- (void)cellWindowDidResignKey:(NSNotification *)aNotification;

@end

@implementation MacroTextFieldWindowController

- (NSString *)windowNibName{
    return @"MacroTextFieldWindow";
}

- (BOOL)editCellOfView:(NSControl *)aControl
				 atRow:(int)aRow
				column:(int)aColumn
			 withValue:(NSString *)aString
		 macroResolver:(id<BDSKMacroResolver>)aMacroResolver
			  delegate:(id)aDelegate
	 shouldEndSelector:(SEL)shouldEndSelector 
		didEndSelector:(SEL)didEndSelector 
		   contextInfo:(void *)contextInfo{
    
	if (control)
		return NO; // we are already busy editing
	
	NSAssert([aControl isKindOfClass:[NSForm class]] || [aControl isKindOfClass:[NSTableView class]] || [aControl isKindOfClass:[NSTextField class]], @"Edited control view must be a NSForm, NSTableView or NSTextField.");
	
	control = [aControl retain];
	row = aRow;
	column = aColumn;
	
	startEdit = YES;
	forceEndEditing = NO;
	
	// reset the view: reset the frame and draw the focus ring we are covering
	[self cellFrameChanged:nil]; // the order is important, as this can set canEdit to NO!
	[self cellWindowDidBecomeKey:nil];
	
	if(startEdit == NO){
		// the cell is out of sight, so we can't edit it
		[control release];
		control = nil;
		return NO;
	}

    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	NSCell *cell = nil;
	NSView *contentView = control;
	NSWindow *controlWindow = [control window];
	
	if([control isKindOfClass:[NSForm class]]){
		cell = [(NSForm *)control cellAtIndex:row];
		contentView = [[control enclosingScrollView] contentView];
	}else if([control isKindOfClass:[NSTableView class]]){
		cell = [[[(NSTableView *)control tableColumns] objectAtIndex:column] dataCellForRow:row];
		contentView = [[control enclosingScrollView] contentView];
	}else if([control isKindOfClass:[NSTextField class]]){
		cell = [(NSTextField *)control cell];
	}
	
	NSAssert([cell isKindOfClass:[NSTextFieldCell class]] || [cell isKindOfClass:[NSFormCell class]], @"Edited cell must be a NSTextfieldCell or NSFormCell.");
	
	// we retain all the temporary objects
    startString = [aString retain];
	macroResolver = [aMacroResolver retain];
	// we take over temporarily as the delegate
	controlDelegate = [[(id)control delegate] retain];
	[(id)control setDelegate:self];
	// we temporarily remove the formatter, as it can interfere with our editing
	cellFormatter = [[cell formatter] retain];
	[cell setFormatter:nil];
	// remember these for the callback
	theDelegate = [aDelegate retain];
	theShouldEndSelector = shouldEndSelector;
	theDidEndSelector = didEndSelector;
	theContextInfo = contextInfo; // this should be retained by the calling object
	
    // we will now be editing the bibtex string
	[cell setStringValue:[aString stringAsBibTeXString]];
	[[control currentEditor] setString:[aString stringAsBibTeXString]];
    [self setExpandedValue:aString];
    
    // select the text for editing
    [[control currentEditor] selectAll:self];
    
    [controlWindow addChildWindow:[self window] ordered:NSWindowAbove];
	
	// observe future changes in the frame and the key status of the window
	// if the target control has a scrollview, we should observe its content view, or we won't notice scrolling
	[nc addObserver:self
		   selector:@selector(cellFrameChanged:)
			   name:NSViewFrameDidChangeNotification
			 object:contentView];
	[nc addObserver:self
		   selector:@selector(cellFrameChanged:)
			   name:NSViewBoundsDidChangeNotification
			 object:contentView];
	[nc addObserver:self
		   selector:@selector(cellWindowDidBecomeKey:)
			   name:NSWindowDidBecomeKeyNotification
			 object:controlWindow];
	[nc addObserver:self
		   selector:@selector(cellWindowDidResignKey:)
			   name:NSWindowDidResignKeyNotification
			 object:controlWindow];
	
	startEdit = NO;
    [[self window] orderFront:self];
	
	return YES;
}

- (NSString *)stringValue{
	NSString *error = nil;
	return [self stringValueGeneratingError:&error];
}

- (NSString *)stringValueGeneratingError:(NSString **)error{
	if(!control){
		*error = NSLocalizedString(@"No current edit.",@"");
		return nil;
	}
	
	NSString *stringValue = nil;
    NSText *fieldEditor = [control currentEditor];
    
	NS_DURING
		stringValue = [NSString complexStringWithBibTeXString:[fieldEditor string] macroResolver:macroResolver];
    NS_HANDLER
		if (![[localException name] isEqualToString:BDSKComplexStringException])
			[localException raise];
		*error = [localException reason];
    NS_ENDHANDLER
	
	return stringValue;
}

BDSKFormConcreteImplementation_NULL_IMPLEMENTATION

@end

@implementation MacroTextFieldWindowController (Private)

- (void)endEditingAndOrderOut{
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	NSCell *cell = nil;
	NSView *contentView = control;
	NSWindow *controlWindow = [control window];
    NSString *stringValue = [self stringValue];
    
	if(stringValue == nil)
		stringValue = startString;
	
	if([control isKindOfClass:[NSForm class]]){
		cell = [(NSForm *)control cellAtIndex:row];
		contentView = [[control enclosingScrollView] contentView];
	}else if([control isKindOfClass:[NSTableView class]]){
		cell = [[[(NSTableView *)control tableColumns] objectAtIndex:column] dataCellForRow:row];
		contentView = [[control enclosingScrollView] contentView];
	}else if([control isKindOfClass:[NSTextField class]]){
		cell = [(NSTextField *)control cell];
	}

	[nc removeObserver:self
				  name:NSViewFrameDidChangeNotification
				object:contentView];
	[nc removeObserver:self
				  name:NSViewBoundsDidChangeNotification
				object:contentView];
	[nc removeObserver:self
				  name:NSWindowDidBecomeKeyNotification
				object:controlWindow];
	[nc removeObserver:self
				  name:NSWindowDidResignKeyNotification
				object:controlWindow];
    
	[cell setObjectValue:stringValue];
	[cell setFormatter:cellFormatter];
	[(id)control setDelegate:controlDelegate];
    [controlWindow removeChildWindow:[self window]];

	if(theDidEndSelector){
		// the message signature should be - (void)macroEditorDidEndEditing:(NSControl *)control withValue:(NSString *)value contextInfo:(void *)contextInfo; 
		NSMethodSignature *signature = [theDelegate methodSignatureForSelector:theDidEndSelector];
		NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
		[invocation setSelector:theDidEndSelector];
		[invocation setArgument:&control atIndex:2];
		[invocation setArgument:&stringValue atIndex:3];
		[invocation setArgument:&theContextInfo atIndex:4];
		[invocation invokeWithTarget:theDelegate];
    }
	
	// release the temporary objects
	[control release];
	control = nil; // we should set this to nil, as we use this as a flag that we are editing
	[controlDelegate release];
	controlDelegate = nil;
	[cellFormatter release];
	cellFormatter = nil;
	[macroResolver release];
	macroResolver = nil;
	[startString release];
	startString = nil;
	[theDelegate release];
	theDelegate = nil;
	theShouldEndSelector = NULL;
	theDidEndSelector = NULL;
	
    [[self window] orderOut:self];
}

- (void)setExpandedValue:(NSString *)expandedValue{
	[expandedValueTextField setTextColor:[NSColor blueColor]];
	[expandedValueTextField setStringValue:expandedValue];
	[backgroundView setToolTip:NSLocalizedString(@"This field contains macros and is being edited as it would appear in a BibTeX file. This is the expanded value.", @"")];
}

- (void)setErrorReason:(NSString *)reason errorMessage:(NSString *)message{
	[expandedValueTextField setTextColor:[NSColor redColor]];
	[expandedValueTextField setStringValue:reason];
	[backgroundView setToolTip:message]; 
}

#pragma mark Delegate methods and notification handlers

- (void)cellFrameChanged:(NSNotification *)aNotification{
	NSRect cellFrame = NSZeroRect;
	NSRect winFrame = [[self window] frame];
	float margin = 4; // for the shadow
	NSView *contentView = control;
	
	if([control isKindOfClass:[NSForm class]]){
		NSForm *form = (NSForm*)control;
		float offset = [[form cellAtRow:row column:column] titleWidth] + 4;
		cellFrame = [form cellFrameAtRow:row column:column];
		cellFrame.origin.x += offset;
		cellFrame.size.width -= offset;
		contentView = [[control enclosingScrollView] contentView];
	}else if([control isKindOfClass:[NSTableView class]]){
		NSTableView *tv = (NSTableView*)control;
		cellFrame = [tv frameOfCellAtColumn:column row:row];
		contentView = [[control enclosingScrollView] contentView];
	}else if([control isKindOfClass:[NSTextField class]]){
		NSTextField *textField = (NSTextField*)control;
		cellFrame = [textField bounds];
	}
	
	// see if the cell is scrolled out of sight
	if(!NSContainsRect([contentView visibleRect], cellFrame)){
		
		if(startEdit){
			// this will invalidate our edit
			startEdit = NO;
		}else{
			// we should stop editing
			forceEndEditing = YES;
			if([[control window] makeFirstResponder:nil])
				[[control window] endEditingFor:control];
			forceEndEditing = NO;
		}
	}
	
	cellFrame = [control convertRect:cellFrame toView:nil]; // takes into account isFlipped
    NSPoint point = [[control window] convertBaseToScreen:cellFrame.origin];
	winFrame.origin.x = point.x - margin;
	winFrame.origin.y = point.y - winFrame.size.height;
	winFrame.size.width = cellFrame.size.width + 2 * margin;
	[[self window] setFrame:winFrame display:!startEdit];
}

- (void)cellWindowDidBecomeKey:(NSNotification *)aNotification{
	[backgroundView setShowFocusRing:YES];
}

- (void)cellWindowDidResignKey:(NSNotification *)aNotification{
	[backgroundView setShowFocusRing:NO];
}

- (void)controlTextDidChange:(NSNotification*)aNotification { 
    NSString *error = nil;
	NSString *stringValue = [self stringValueGeneratingError:&error];
    
	if(error){
		[self setErrorReason:error
				errorMessage:NSLocalizedString(@"Invalid BibTeX string: this change will not be recorded.", @"Invalid raw bibtex string error message")];
	}else{
		[self setExpandedValue:stringValue];
	}
}

- (BOOL)control:(NSControl *)aControl textShouldEndEditing:(NSText *)fieldEditor{
	BOOL shouldEnd = YES;
	NSString *stringValue = [self stringValue];
	
	if(!forceEndEditing && theShouldEndSelector){
		// the message signature should be - (BOOL)macroEditorShouldEndEditing:(NSControl *)control withValue:(NSString *)value contextInfo:(void *)contextInfo; 
		NSMethodSignature *signature = [theDelegate methodSignatureForSelector:theShouldEndSelector];
		NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
		[invocation setSelector:theShouldEndSelector];
		[invocation setArgument:&control atIndex:2];
		[invocation setArgument:&stringValue atIndex:3];
		[invocation setArgument:&theContextInfo atIndex:4];
		[invocation invokeWithTarget:theDelegate];
		[invocation getReturnValue:&shouldEnd];
    }
	return shouldEnd;	
}

- (void)controlTextDidEndEditing:(NSNotification *)notification{
    [self endEditingAndOrderOut];
}

- (void)windowWillClose:(NSNotification *)aNotification{
	// safety call, should not happen
	forceEndEditing = YES;
	if(control)
		[self endEditingAndOrderOut];
	forceEndEditing = NO;
}

#pragma mark Forwarded delegate methods

- (void)arrowClickedInFormCell:(id)aCell{
	if([controlDelegate respondsToSelector:@selector(arrowClickedInFormCell:)])
		[controlDelegate arrowClickedInFormCell:aCell];
}

- (BOOL)formCellHasArrowButton:(id)aCell{
	return ([controlDelegate respondsToSelector:@selector(formCellHasArrowButton:)] &&
			[controlDelegate formCellHasArrowButton:aCell]);
}

@end

//
// Workaround for problems with editing in tableviews
//

@interface BDSKMacroEditorTableView : NSTableView {} @end

#import <objc/objc-class.h>

@implementation BDSKMacroEditorTableView

+ (void)performPosing;
{
    // don't use +poseAsClass: since that would force +initialize early (and +performPosing gets called w/o forcing it via OBPostLoader).
    class_poseAs((Class)self, ((Class)self)->super_class);
}

- (void)textDidEndEditing:(NSNotification *)aNotification;
{
     // The default behavior of NSTableView sends a final setObjectValue: to the datasource after we set the BibItem's value as a complex string, which then trashes our complex string.  The cell owner's macroEditorDidEndEditing is then responsible for setting the value and handling the selection of the table.
    
    // Check specifically if this is an instance of the MacroTextFieldWindowController, since any NSWindowController delegate could have an endEditingAndOrderOut method
    if([_delegate isMemberOfClass:NSClassFromString(@"MacroTextFieldWindowController")] &&
       [_delegate respondsToSelector:@selector(endEditingAndOrderOut)]){
		int selRow = [self selectedRow];
		int editCol = [self editedColumn];
        [_delegate endEditingAndOrderOut];
		if(editCol != -1 && selRow != -1){
			if(++selRow >= [self numberOfRows]) // NSTableView wraps to the first row by default
				selRow = 0;
			[self selectRow:selRow byExtendingSelection:NO];
			[self editColumn:editCol row:selRow withEvent:nil select:YES];
		}
    }else
        [super textDidEndEditing:aNotification];
}

@end
