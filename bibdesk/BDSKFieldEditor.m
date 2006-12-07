//
//  BDSKFieldEditor.m
//  Bibdesk
//
//  Created by Christiaan Hofman on 19/12/05.
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

#import "BDSKFieldEditor.h"
#import "BDSKTextViewCompletionController.h"

@interface BDSKFieldEditor (Private)

- (BOOL)delegateHandlesDragOperation:(id <NSDraggingInfo>)sender;
- (void)doAutoCompleteIfPossible;

@end

static BOOL shouldChangeRangeForUserCompletion = YES;

@implementation BDSKFieldEditor

- (id)init {
	if (self = [super initWithFrame:NSZeroRect]) {
		[self setFieldEditor:YES];
		delegatedDraggedTypes = nil;
	}
	return self;
}

- (void)dealloc {
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

- (void)keyDown:(NSEvent *)event {
    BDSKTextViewCompletionController *completionController = [BDSKTextViewCompletionController sharedController];
    
    BOOL wasVisibleBeforeEvent = [[completionController completionWindow] isVisible];
    shouldChangeRangeForUserCompletion = NO;

    if([[event characters] length] == 0){ // if this is an accent, length is zero, and characterAtIndex: will raise an exception
        [super keyDown:event];
    }else if(wasVisibleBeforeEvent == NO){ // delay this so we can trap the arrow keys
        shouldChangeRangeForUserCompletion = YES;
        [super keyDown:event]; // send to super first, or else the doAutocomplete might still wipe out any marked text
        [self doAutoCompleteIfPossible];
    }else if([completionController currentTextView] == self){
        unichar ch = [[event characters] characterAtIndex:0];
        shouldChangeRangeForUserCompletion = YES;
        switch(ch){
            // let the completion controller handle these, since we don't want to change the insertion point!
            case NSUpArrowFunctionKey:
            case NSDownArrowFunctionKey:
            case NSEnterCharacter:
            case NSNewlineCharacter:
            case NSCarriageReturnCharacter:
            case 0x001B: // escape
                [completionController handleKeyDown:event];
                break;
            case NSTabCharacter: // in normal text views, the completion controller handles this just fine, but the field editor handles tab differently; sending super will move us to the next field
                [completionController handleKeyDown:event];
                break;
            case 0x0020: // spacebar
                [super keyDown:event]; // we don't want the completion controller to insert, as this may just be a separator between words
                break;
            default:
                [super keyDown:event];
                [completionController handleKeyDown:event];
        }
    }
}

- (NSRange)rangeForUserCompletion {
    // if this is an accent character, we don't want to change the existing selection (and rangeForUserCompletion will change the selection) if we're called by the completion controller
    if(shouldChangeRangeForUserCompletion == NO) 
        return NSMakeRange(NSNotFound, 0);
    
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
    if([[[BDSKTextViewCompletionController sharedController] completionWindow] isVisible])
        [[BDSKTextViewCompletionController sharedController] endDisplayNoComplete];
    return [super selectionRangeForProposedRange:proposedSelRange granularity:granularity];
}

- (BOOL)becomeFirstResponder {
    if([[[BDSKTextViewCompletionController sharedController] completionWindow] isVisible])
        [[BDSKTextViewCompletionController sharedController] endDisplayNoComplete];
    return [super becomeFirstResponder];
}
    
- (BOOL)resignFirstResponder {
    if([[[BDSKTextViewCompletionController sharedController] completionWindow] isVisible])
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
	if ([[[BDSKTextViewCompletionController sharedController] completionWindow] isVisible] == NO) {
        if ([[self delegate] respondsToSelector:@selector(textViewShouldAutoComplete:)] &&
            [[self delegate] textViewShouldAutoComplete:self] == YES)
            [self complete:self];
    }
}    

@end
