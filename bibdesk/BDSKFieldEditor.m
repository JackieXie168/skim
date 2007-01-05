//
//  BDSKFieldEditor.m
//  Bibdesk
//
//  Created by Christiaan Hofman on 19/12/05.
/*
 This software is Copyright (c) 2005,2006,2007
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

#import "BDSKFieldEditor.h"
#import "BDSKTextViewCompletionController.h"

@interface BDSKFieldEditor (Private)

- (BOOL)delegateHandlesDragOperation:(id <NSDraggingInfo>)sender;
- (void)doAutoCompleteIfPossible;
- (void)handleTextDidBeginEditingNotification:(NSNotification *)note;
- (void)handleTextDidEndEditingNotification:(NSNotification *)note;

@end

@implementation BDSKFieldEditor

- (id)init {
	if (self = [super initWithFrame:NSZeroRect]) {
		[self setFieldEditor:YES];
		delegatedDraggedTypes = nil;
        isEditing = NO;
        
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(handleTextDidBeginEditingNotification:)
													 name:NSTextDidBeginEditingNotification
												   object:self];
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(handleTextDidEndEditingNotification:)
													 name:NSTextDidEndEditingNotification
												   object:self];
	}
	return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
	[delegatedDraggedTypes release];
	[super dealloc];
}

#pragma mark Delegated drag methods

- (void)registerForDelegatedDraggedTypes:(NSArray *)pboardTypes {
	[delegatedDraggedTypes release];
	delegatedDraggedTypes = [pboardTypes copy];
	[self updateDragTypeRegistration];
}

- (void)updateDragTypeRegistration {
	if ([delegatedDraggedTypes count] == 0) {
		[super updateDragTypeRegistration];
	} else if ([self isEditable] && [self isRichText]) {
		NSMutableArray *dragTypes = [[NSMutableArray alloc] initWithArray:[self acceptableDragTypes]];
		[dragTypes addObjectsFromArray:delegatedDraggedTypes];
		[self registerForDraggedTypes:dragTypes];
		[dragTypes release];
	} else {
		[self registerForDraggedTypes:delegatedDraggedTypes];
	}
}

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender {
	if ([self delegateHandlesDragOperation:sender]) {
		if ([[self delegate] respondsToSelector:@selector(draggingEntered:)])
			return [[self delegate] draggingEntered:sender];
		return NSDragOperationNone;
	} else
		return [super draggingEntered:sender];
}

- (NSDragOperation)draggingUpdated:(id <NSDraggingInfo>)sender {
	if ([self delegateHandlesDragOperation:sender]) {
		if ([[self delegate] respondsToSelector:@selector(draggingUpdated:)])
			return [[self delegate] draggingUpdated:sender];
		return [sender draggingSourceOperationMask];
	} else
		return [super draggingUpdated:sender];
}

- (void)draggingExited:(id <NSDraggingInfo>)sender {
	if ([self delegateHandlesDragOperation:sender]) {
		if ([[self delegate] respondsToSelector:@selector(draggingExited:)])
			[[self delegate] draggingExited:sender];
	} else
		[super draggingExited:sender];
}

- (BOOL)wantsPeriodicDraggingUpdates {
	return YES;
}

- (BOOL)prepareForDragOperation:(id <NSDraggingInfo>)sender {
	if ([self delegateHandlesDragOperation:sender]) {
		if ([[self delegate] respondsToSelector:@selector(prepareForDragOperation:)])
			return [[self delegate] prepareForDragOperation:sender];
		return YES;
	} else
		return [super prepareForDragOperation:sender];
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender {
	if ([self delegateHandlesDragOperation:sender]) {
		if ([[self delegate] respondsToSelector:@selector(performDragOperation:)])
			return [[self delegate] performDragOperation:sender];
		return NO;
	} else
		return [super performDragOperation:sender];
}

- (void)concludeDragOperation:(id <NSDraggingInfo>)sender {
	if ([self delegateHandlesDragOperation:sender]) {
		if ([[self delegate] respondsToSelector:@selector(concludeDragOperation:)])
			[[self delegate] concludeDragOperation:sender];
	} else
		[super concludeDragOperation:sender];
}

#pragma mark Completion methods

static inline BOOL completionWindowIsVisibleForTextView(NSTextView *textView)
{
    BDSKTextViewCompletionController *controller = [BDSKTextViewCompletionController sharedController];
    return ([[controller completionWindow] isVisible] && [[controller currentTextView] isEqual:textView]);
}

static inline BOOL forwardSelectorForCompletionInTextView(SEL selector, NSTextView *textView)
{
    OBPRECONDITION([[BDSKTextViewCompletionController sharedController] respondsToSelector:selector]);
    if(completionWindowIsVisibleForTextView(textView)){
        [[BDSKTextViewCompletionController sharedController] performSelector:selector withObject:nil];
        return YES;
    }
    return NO;
}

// insertText: and deleteBackward: affect the text content, so we send to super first, then autocomplete unconditionally since the completion controller needs to see the changes
- (void)insertText:(id)insertString {
    [super insertText:insertString];
    [self doAutoCompleteIfPossible];
    // passing a nil argument to the completion controller's insertText: is safe, and we can ensure the completion window is visible this way
    forwardSelectorForCompletionInTextView(_cmd, self);
}

- (void)deleteBackward:(id)sender {
    [super deleteBackward:(id)sender];
    // deleting a spelling error should also show the completions again
    [self doAutoCompleteIfPossible];
    forwardSelectorForCompletionInTextView(_cmd, self);
}

// moveLeft and moveRight should happen regardless of completion, or you can't navigate the line with arrow keys
- (void)moveLeft:(id)sender {
    forwardSelectorForCompletionInTextView(_cmd, self);
    [super moveLeft:sender];
}

- (void)moveRight:(id)sender {
    forwardSelectorForCompletionInTextView(_cmd, self);
    [super moveRight:sender];
}

// the following movement methods are conditional based on whether the autocomplete window is visible
- (void)moveUp:(id)sender {
    if(forwardSelectorForCompletionInTextView(_cmd, self) == NO)
        [super moveUp:sender];
}

- (void)moveDown:(id)sender {
    if(forwardSelectorForCompletionInTextView(_cmd, self) == NO)
        [super moveDown:sender];
}

- (void)insertTab:(id)sender {
    if(forwardSelectorForCompletionInTextView(_cmd, self) == NO)
        [super insertTab:sender];
}

- (void)insertNewline:(id)sender {
    if(forwardSelectorForCompletionInTextView(_cmd, self) == NO)
        [super insertNewline:sender];
}

- (NSRange)rangeForUserCompletion {
    // @@ check this if we have problems inserting accented characters; super's implementation can mess that up
    OBPRECONDITION([self markedRange].length == 0);    
    NSRange charRange = [super rangeForUserCompletion];
	if ([[self delegate] respondsToSelector:@selector(textView:rangeForUserCompletion:)]) 
		return [[self delegate] textView:self rangeForUserCompletion:charRange];
	return charRange;
}

#pragma mark Auto-completion methods

- (NSArray *)completionsForPartialWordRange:(NSRange)charRange indexOfSelectedItem:(int *)index;
{
    id delegate = [self delegate];
    SEL delegateSEL = @selector(control:textView:completions:forPartialWordRange:indexOfSelectedItem:);
    OBPRECONDITION(delegate == nil || [delegate isKindOfClass:[NSControl class]]); // typically the NSForm
    
    NSArray *completions = nil;
    
    if([delegate respondsToSelector:delegateSEL])
        completions = [delegate control:delegate textView:self completions:nil forPartialWordRange:[self rangeForUserCompletion] indexOfSelectedItem:index];
    else if([[[self window] delegate] respondsToSelector:delegateSEL])
        completions = [[[self window] delegate] control:delegate textView:self completions:nil forPartialWordRange:[self rangeForUserCompletion] indexOfSelectedItem:index];
    
    // Default is to call -[NSSpellChecker completionsForPartialWordRange:inString:language:inSpellDocumentWithTag:], but this apparently sends a DO message to CocoAspell (in a separate process), and we block the main runloop until it returns a long time later.  Lacking a way to determine whether the system speller (which works fine) or CocoAspell is in use, we'll just return our own completions.
    return completions;
}

- (void)complete:(id)sender;
{
    // forward this method so the controller can handle cancellation and undo
    if(forwardSelectorForCompletionInTextView(_cmd, self))
        return;

    NSRange selRange = [self rangeForUserCompletion];
    NSString *string = [self string];
    if(selRange.location == NSNotFound || [string isEqualToString:@""] || selRange.length == 0)
        return;

    // make sure to initialize this
    int idx = 0;
    NSArray *completions = [self completionsForPartialWordRange:selRange indexOfSelectedItem:&idx];
    
    if(sender == self) // auto-complete, don't select an item
		idx = -1;
	
    [[BDSKTextViewCompletionController sharedController] displayCompletions:completions indexOfSelectedItem:idx forPartialWordRange:selRange originalString:[string substringWithRange:selRange] atPoint:[self locationForCompletionWindow] forTextView:self];
}

- (NSRange)selectionRangeForProposedRange:(NSRange)proposedSelRange granularity:(NSSelectionGranularity)granularity {
    if(completionWindowIsVisibleForTextView(self))
        [[BDSKTextViewCompletionController sharedController] endDisplayNoComplete];
    return [super selectionRangeForProposedRange:proposedSelRange granularity:granularity];
}

- (BOOL)becomeFirstResponder {
    if(completionWindowIsVisibleForTextView(self))
        [[BDSKTextViewCompletionController sharedController] endDisplayNoComplete];
    return [super becomeFirstResponder];
}
    
- (BOOL)resignFirstResponder {
    if(completionWindowIsVisibleForTextView(self))
        [[BDSKTextViewCompletionController sharedController] endDisplayNoComplete];
    return [super resignFirstResponder];
}

@end


@implementation BDSKFieldEditor (Private)

#pragma mark Delegated drag methods

- (BOOL)delegateHandlesDragOperation:(id <NSDraggingInfo>)sender {
	return ([delegatedDraggedTypes count] > 0 && [[sender draggingPasteboard] availableTypeFromArray:delegatedDraggedTypes] != nil);
}

- (void)doAutoCompleteIfPossible {
	if (completionWindowIsVisibleForTextView(self) == NO && isEditing) {
        if ([[self delegate] respondsToSelector:@selector(textViewShouldAutoComplete:)] &&
            [[self delegate] textViewShouldAutoComplete:self] == YES)
            [self complete:self]; // NB: the self argument is critical here (see comment in complete:)
    }
} 

- (void)handleTextDidBeginEditingNotification:(NSNotification *)note { isEditing = YES; }

- (void)handleTextDidEndEditingNotification:(NSNotification *)note { isEditing = NO; }

@end
