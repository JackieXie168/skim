//
//  BDSKForm.m
//  Bibdesk
//
//  Created by Adam Maxwell on 05/22/05.
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

#import "BDSKForm.h"
#import "BDSKComplexString.h"

// private methods for getting the rect(s) of each cell in the matrix
@interface BDSKForm (Private)
- (id)cellAtPoint:(NSPoint)point usingButton:(BOOL)usingButton;
+ (NSCursor *)fingerCursor;
@end

@implementation BDSKForm

// this is called when loading the nib. We replace the cell class and the prototype cell
- (id)initWithCoder:(NSCoder *)coder{
	if (self = [super initWithCoder:coder]) {
		// we replace the prototype cell with our own if necessary
		if (![[self prototype] isKindOfClass:[BDSKFormCell class]]){
			BDSKFormCell *cell = [[BDSKFormCell alloc] init];
			[cell setFont:[[self prototype] font]];
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
		currentCell = nil;
	}
	return self;
}

- (void)dealloc{
	[currentCell release];
	[super dealloc];
}

- (void)mouseDown:(NSEvent *)theEvent{
    
    NSPoint point = [self convertPoint:[theEvent locationInWindow] fromView:nil];
    // NSLog(@"the point is at x = %f and y = %f", point.x, point.y);
    NSCell *cell = [self cellAtPoint:point usingButton:YES];
    
    if(cell){
		[self setCurrentCell:(BDSKFormCell *)cell];
    }else{
		[super mouseDown:theEvent];
	}
}

- (void)mouseUp:(NSEvent *)theEvent{
    
    NSPoint point = [self convertPoint:[theEvent locationInWindow] fromView:nil];
    // NSLog(@"the point is at x = %f and y = %f", point.x, point.y);
    NSCell *cell = [self cellAtPoint:point usingButton:YES];
    
    if(cell && cell == currentCell){ 
		[self setCurrentCell:nil];
		if([[self delegate] respondsToSelector:@selector(arrowClickedInFormCell:)])
			[[self delegate] arrowClickedInFormCell:cell];
    }else{
		[self setCurrentCell:nil];
		[super mouseUp:theEvent];
	}
}

- (void)mouseDragged:(NSEvent *)theEvent{
	if(currentCell){
		NSPoint point = [self convertPoint:[theEvent locationInWindow] fromView:nil];
		NSCell *cell = [self cellAtPoint:point usingButton:YES];

		[currentCell setButtonHighlighted:(cell == currentCell)];
	}
	[super mouseDragged:theEvent];
}

- (BDSKFormCell *)currentCell{
	return currentCell;
}

- (void)setCurrentCell:(BDSKFormCell *)cell{
	if(currentCell != cell){
		if(cell)
			[cell setButtonHighlighted:YES];
		else if(currentCell)
			[currentCell setButtonHighlighted:NO];
		[currentCell release];
		currentCell = [cell retain];
	}
}

// the AppKit calls this when necessary, so it's caching the rects for us
- (void)resetCursorRects{
    
    int rows = [self numberOfRows];
    int columns = [self numberOfColumns];
    int i, j;
	int titleWidth;
    NSRect cellRect;
    BDSKFormCell *aCell;
    
	for(i = 0; i < rows; i++){
        for(j = 0; j < columns; j++){
            // Get the cell's frame rect
            cellRect = [self cellFrameAtRow:i column:j];
            
            aCell = (BDSKFormCell *)[self cellAtRow:i column:j];
			
			// set the I-beam cursor for the text part, this takes the button into account
			[self addCursorRect:[aCell textRectForBounds:cellRect] cursor:[NSCursor IBeamCursor]];
			
			if([[self delegate] respondsToSelector:@selector(formCellHasArrowButton:)] &&
			   [[self delegate] formCellHasArrowButton:aCell]){
                
                // set a finger cursor for the button part.
				[self addCursorRect:[aCell buttonRectForBounds:cellRect] cursor:[BDSKForm fingerCursor]];
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

@end

@implementation BDSKForm (Private)

// This method returns the cell at point. If there is no cell, or usingButton is YES and the point 
// is not in the button rect, nil is returned. 

- (id)cellAtPoint:(NSPoint)point usingButton:(BOOL)usingButton{
    int row, column;
	
	if (![self getRow:&row column:&column forPoint:point]) 
		return nil;
	
	BDSKFormCell *cell = (BDSKFormCell *)[self cellAtRow:row column:column];
	
	// if we use a button, we have to see if it is in the button rect
	if(usingButton){ 
		// see if there is an arrow button
		if([[self delegate] respondsToSelector:@selector(formCellHasArrowButton:)] &&
		   [[self delegate] formCellHasArrowButton:cell]){
			NSRect aRect = [self cellFrameAtRow:row column:column];
			// check if point is in the button rect
			if( NSMouseInRect(point, [cell buttonRectForBounds:aRect], [self isFlipped]) )
				return cell;
		}
		// there is no button, or point was outside its rect
		return nil;
	}
	
	return cell;
}

// workaround for 10.2 systems

+ (NSCursor *)fingerCursor{
    static NSCursor	*fingerCursor = nil;    
    if (fingerCursor == nil){
        if([NSCursor respondsToSelector:@selector(pointingHandCursor)]){
            fingerCursor = [NSCursor pointingHandCursor];
        } else {
            NSImage	*image = [NSImage imageNamed: @"fingerCursor"];
            fingerCursor = [[NSCursor alloc] initWithImage:image
                                                   hotSpot:NSMakePoint (8, 8)];
        }
    }
    
    return fingerCursor;
}

    
@end
