//
//  BDSKForm.m
//  Bibdesk
//
//  Created by Adam Maxwell on 05/22/05.
/*
 This software is Copyright (c) 2005,2006,2007
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

#import "BDSKForm.h"
#import "BDSKComplexString.h"
#import "NSImage+Toolbox.h"
#import "BibEditor.h"
#import "BDSKFieldEditor.h"
#import "NSBezierPath_BDSKExtensions.h"

// private methods for getting the rect(s) of each cell in the matrix
@interface BDSKForm (Private)
- (id)cellForButtonAtPoint:(NSPoint)point;
- (id)cellForTitleAtPoint:(NSPoint)point;
- (void)setDragSourceCell:(id)cell;
@end

@implementation BDSKForm

// this is called when loading the nib. We replace the cell class and the prototype cell
- (id)initWithCoder:(NSCoder *)coder{
	if (self = [super initWithCoder:coder]) {
		dragRow = -1;
		highlight = NO;
		dragSourceCell = nil;
		// we replace the prototype cell with our own if necessary
		if (![[self prototype] isKindOfClass:[BDSKFormCell class]]){
			BDSKFormCell *cell = [[BDSKFormCell alloc] init];
			[cell setFont:[(NSCell *)[self prototype] font]];
			[cell setTitleFont:[[self prototype] titleFont]];
			[cell setWraps:[[self prototype] wraps]];
			[cell setScrollable:[[self prototype] isScrollable]];
			[cell setEnabled:[[self prototype] isEnabled]];
			[cell setEditable:[[self prototype] isEditable]];
			[cell setSelectable:[[self prototype] isSelectable]];
			[cell setAlignment:[[self prototype] alignment]];
			[cell setTitleAlignment:[[self prototype] titleAlignment]];
			[cell setSendsActionOnEndEditing:[[self prototype] sendsActionOnEndEditing]];
			[self setCellClass:[BDSKFormCell class]];
			[self setPrototype:cell];
			[cell release];
		}
	}
	return self;
}

-(void)drawRect:(NSRect)rect{
	[super drawRect:rect];
    
	if (highlight && dragRow != -1) {
        NSColor *highlightColor = [NSColor alternateSelectedControlColor];
        float lineWidth = 2.0;
        
        NSRect highlightRect = NSInsetRect([self cellFrameAtRow:dragRow column:0], 0.5f * lineWidth, 0.5f * lineWidth);
        
        NSBezierPath *path = [NSBezierPath bezierPathWithRoundRectInRect:highlightRect radius:4.0];
        
        [path setLineWidth:lineWidth];
        
        [NSGraphicsContext saveGraphicsState];
        
        [[highlightColor colorWithAlphaComponent:0.2] set];
        [path fill];
        
        [[highlightColor colorWithAlphaComponent:0.8] set];
        [path stroke];
        
        [NSGraphicsContext restoreGraphicsState];
	}
}

- (void)dealloc{
	[super dealloc];
}

- (void)setDelegate:(id <BDSKFormDelegate>)aDelegate{
    if(aDelegate){
        OBPRECONDITION([(id)aDelegate conformsToProtocol:@protocol(BDSKFormDelegate)]);
        NSAssert1([(id)aDelegate conformsToProtocol:@protocol(BDSKFormDelegate)], @"%@ does not conform to BDSKFormDelegate protocol", [aDelegate class]);
    }
    [super setDelegate:aDelegate];
}

- (id <BDSKFormDelegate>)delegate{
    return [super delegate];
}

- (void)mouseDown:(NSEvent *)theEvent{
    
    NSPoint mouseLoc = [self convertPoint:[theEvent locationInWindow] fromView:nil];
    // NSLog(@"the point is at x = %f and y = %f", point.x, point.y);
    BDSKFormCell *cell = (BDSKFormCell *)[self cellForButtonAtPoint:mouseLoc];
    if(cell){
		[cell setButtonHighlighted:YES];
		BOOL keepOn = YES;
		BOOL isInside = YES;
		while (keepOn) {
			theEvent = [[self window] nextEventMatchingMask: NSLeftMouseUpMask | NSLeftMouseDraggedMask];
			mouseLoc = [self convertPoint:[theEvent locationInWindow] fromView:nil];
			isInside = ([[self cellForButtonAtPoint:mouseLoc] isEqual:cell]);
			switch ([theEvent type]) {
				case NSLeftMouseDragged:
					[cell setButtonHighlighted:isInside];
                    if(isInside && [cell hasFileIcon]){
                        
                        NSPasteboard *pboard = [NSPasteboard pasteboardWithName:NSDragPboard];
						
						if([[self delegate] writeDataToPasteboard:pboard forFormCell:cell]){
							NSImage *iconImage;
							NSImage *dragImage = [[NSImage alloc] initWithSize:NSMakeSize(32.0,32.0)];
                            iconImage = [[self delegate] respondsToSelector:@selector(dragIconForFormCell:)] ? [[self delegate] dragIconForFormCell:cell] : [[self delegate] fileIconForFormCell:cell];
                            
                            // copy the image so we can resize the copy without affecting any cached images
                            iconImage = [iconImage copy];
                            [iconImage setScalesWhenResized:YES];
                            [iconImage setSize:NSMakeSize(32.0, 32.0)];

                            // composite for transparency
							[dragImage lockFocus];
							[iconImage compositeToPoint:NSZeroPoint operation:NSCompositeCopy fraction:0.6];
							[dragImage unlockFocus];
                            
                            [iconImage release];
							
							mouseLoc.x -= 16;
							mouseLoc.y += 16;
							
							[self setDragSourceCell:cell];
                            
							[self dragImage:dragImage at:mouseLoc offset:NSZeroSize event:theEvent pasteboard:pboard source:self slideBack:YES];
						}
						
						// we shouldn't follow the mouse events anymore
                        [cell setButtonHighlighted:NO];
						keepOn = NO;
                    }
					break;
				case NSLeftMouseUp:
					if (isInside){
                        if([cell hasArrowButton])
                            [[self delegate] arrowClickedInFormCell:cell];
                        else if([cell hasFileIcon])
                            [[self delegate] iconClickedInFormCell:cell];
                    }
					[cell setButtonHighlighted:NO];
					keepOn = NO;
					break;
				default:
					/* Ignore any other kind of event. */
					break;
			}
		}
    }else if ((cell = [self cellForTitleAtPoint:mouseLoc]) && [theEvent clickCount] == 2){
        [[self delegate] doubleClickedTitleOfFormCell:cell];
	}else{
    	[super mouseDown:theEvent];
	}
}


// the AppKit calls this when necessary, so it's caching the rects for us
- (void)resetCursorRects{
    
    int rows = [self numberOfRows];
    int columns = [self numberOfColumns];
    int i, j;
    NSRect cellRect;
    BDSKFormCell *aCell;
    
	for(i = 0; i < rows; i++){
        for(j = 0; j < columns; j++){
            // Get the cell's frame rect
            cellRect = [self cellFrameAtRow:i column:j];
            
            aCell = (BDSKFormCell *)[self cellAtRow:i column:j];
			
			// set the I-beam cursor for the text part, this takes the button into account
			[self addCursorRect:[aCell textRectForBounds:cellRect] cursor:[NSCursor IBeamCursor]];
			
			if([[self delegate] formCellHasArrowButton:aCell]){
                
                // set a finger cursor for the button part.
				[self addCursorRect:[aCell buttonRectForBounds:cellRect] cursor:[NSCursor pointingHandCursor]];
            }
        }
    }
}

- (void)removeAllEntries{
    int numRows = [self numberOfRows];
    while(numRows--){
        [self removeEntryAtIndex:numRows];
    }
}

- (NSFormCell *)insertEntry:(NSString *)title
             usingTitleFont:(NSFont *)titleFont
         attributesForTitle:(NSDictionary *)attrs
                    indexAndTag:(int)index 
                objectValue:(id<NSCopying>)objectValue{
    
    // this will be an instance of the prototype cell
    NSFormCell *theCell = [self insertEntry:title atIndex:index];
    [theCell setTag:index];
    [theCell setObjectValue:objectValue];
    [theCell setTitleFont:titleFont];
    NSAttributedString *attrTitle = [[NSAttributedString alloc] initWithString:title attributes:attrs];
    [theCell setAttributedTitle:attrTitle];
    [attrTitle release];
    
    return theCell;
}

- (id)dragSourceCell{
    return dragSourceCell;
}

#pragma mark BDSKFieldEditorDelegate protocol

- (BOOL)textViewShouldLinkKeys:(NSTextView *)textView{
    return [[self delegate] textViewShouldLinkKeys:textView forFormCell:[self selectedCell]];
}

- (BOOL)textView:(NSTextView *)textView isValidKey:(NSString *)key{
    return [[self delegate] textView:textView isValidKey:key forFormCell:[self selectedCell]];
}

- (BOOL)textView:(NSTextView *)aTextView clickedOnLink:(id)link atIndex:(unsigned)charIndex{
    return [[self delegate] textView:aTextView clickedOnLink:link atIndex:charIndex forFormCell:[self selectedCell]];
}

#pragma mark NSDraggingDestination protocol 

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender{
    NSDragOperation dragOp = [self draggingUpdated:sender];
    if (dragOp == NSDragOperationNone && [[self window] respondsToSelector:@selector(draggingEntered:)])
        dragOp = [[self window] draggingEntered:sender];
    return dragOp;
}

- (NSDragOperation)draggingUpdated:(id <NSDraggingInfo>)sender{
	NSPoint mouseLoc = [self convertPoint:[sender draggingLocation] fromView:nil];
	int row, column;
	id cell;
    NSDragOperation dragOp = NSDragOperationNone;
	
	if ([self delegate] == nil) {
        dragOp = NSDragOperationNone;
	} else {
        [self getRow:&row column:&column forPoint:mouseLoc];
        if (cell = [self cellAtRow:row column:0])
            dragOp = [[self delegate] canReceiveDrag:sender forFormCell:cell];
        if (dragOp != NSDragOperationNone) {	
            if (row != dragRow) {
                [self setNeedsDisplayInRect:[self cellFrameAtRow:row column:0]];
                if (highlight)
                    [self setNeedsDisplayInRect:[self cellFrameAtRow:dragRow column:0]];
            }
            dragRow = row;
            highlight = YES;
        } else {
            if (highlight)
                [self setNeedsDisplayInRect:[self cellFrameAtRow:dragRow column:0]];
            highlight = NO;
            dragRow = -1;
        }
    }
    if (dragOp == NSDragOperationNone && [[self window] respondsToSelector:@selector(draggingUpdated:)])
        dragOp = [[self window] draggingUpdated:sender];
    return dragOp;
}

- (void)draggingExited:(id <NSDraggingInfo>)sender{
	if (highlight && dragRow != -1)
		[self setNeedsDisplayInRect:[self cellFrameAtRow:dragRow column:0]];
    highlight = NO;
	dragRow = -1;
}

- (BOOL)prepareForDragOperation:(id <NSDraggingInfo>)sender{
	BOOL accept = dragRow != -1;
    
    highlight = NO;
	
    if (accept) {
        [self setNeedsDisplayInRect:[self cellFrameAtRow:dragRow column:0]];
    } else if ([[self window] respondsToSelector:@selector(prepareForDragOperation:)]) {
        accept = [[self window] prepareForDragOperation:sender];
    }
	return accept;
} 

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender{
	BOOL accept = dragRow != -1 && [self delegate];
    
    if (accept) {
        id cell = [self cellAtRow:dragRow column:0];
        accept = [[self delegate] receiveDrag:sender forFormCell:cell];
	} else if ([[self window] respondsToSelector:@selector(performDragOperation:)]) {
        accept = [[self window] performDragOperation:sender];
    }
    
    dragRow = -1;
	
    return accept;
}

#pragma mark -
#pragma mark NSDraggingSource protocol

- (unsigned int)draggingSourceOperationMaskForLocal:(BOOL)isLocal{
    return (isLocal) ? NSDragOperationEvery : NSDragOperationCopy;
}

- (NSArray *)namesOfPromisedFilesDroppedAtDestination:(NSURL *)dropDestination{
	return [[self delegate] namesOfPromisedFilesDroppedAtDestination:dropDestination forFormCell:dragSourceCell];
}

- (void)draggedImage:(NSImage *)anImage endedAt:(NSPoint)aPoint operation:(NSDragOperation)operation{
	[[self delegate] cleanUpAfterDragOperation:operation forFormCell:dragSourceCell];
}

@end

@implementation BDSKForm (Private)

// This method returns the cell at point. If there is no cell, or usingButton is YES and the point 
// is not in the button rect, nil is returned. 

- (id)cellForButtonAtPoint:(NSPoint)point{
    int row, column;
    id cell = nil;
	
	if ([self getRow:&row column:&column forPoint:point]) {
	
        // see if it is in the button rect
        if(cell = [self cellAtRow:row column:column]){ 
            // see if there is an arrow button
            if([[self delegate] formCellHasArrowButton:cell] || [[self delegate] formCellHasFileIcon:cell]){
                NSRect aRect = [self cellFrameAtRow:row column:column];
                // check if point is in the button rect
                if( NSMouseInRect(point, [cell buttonRectForBounds:aRect], [self isFlipped]) == NO)
                    cell = nil;
            }  else{
                // there is no button, or point was outside its rect
                cell = nil;
            }
        }
	}
    
	return cell;
}

- (id)cellForTitleAtPoint:(NSPoint)point{
    int row, column;
    id cell = nil;
	
	if ([self getRow:&row column:&column forPoint:point]) {
	
        // see if it is in the button rect
        if(cell = [self cellAtRow:row column:column]){ 
            NSRect aRect = [self cellFrameAtRow:row column:column];
            // check if point is in the title rect
            if( NSMouseInRect(point, [cell titleRectForBounds:aRect], [self isFlipped]) == NO)
                cell = nil;
        }
	}
    
	return cell;
}

- (void)setDragSourceCell:(id)cell{
    // no need to retain, as it's one of our cells
	dragSourceCell = cell;
}

- (NSRange)textView:(NSTextView *)textView rangeForUserCompletion:(NSRange)charRange {
	if (textView == [self currentEditor] && [[self delegate] respondsToSelector:@selector(control:textView:rangeForUserCompletion:)]) 
		return [(id)[self delegate] control:self textView:textView rangeForUserCompletion:charRange];
	return charRange;
}

- (BOOL)textViewShouldAutoComplete:(NSTextView *)textView {
	if (textView == [self currentEditor] && [[self delegate] respondsToSelector:@selector(control:textViewShouldAutoComplete:)]) 
		return [(id)[self delegate] control:self textViewShouldAutoComplete:textView];
	return NO;
}

@end
