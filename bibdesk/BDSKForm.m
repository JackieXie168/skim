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

static unsigned int ButtonRectWidth = 15;

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
		if (![[self prototype] isKindOfClass:[BDSKImageTextFormCell class]]){
			BDSKImageTextFormCell *cell = [[BDSKImageTextFormCell alloc] init];
			[cell setFont:[[self prototype] font]];
			[cell setTitleFont:[[self prototype] titleFont]];
			[self setCellClass:[BDSKImageTextFormCell class]];
			[self setPrototype:cell];
			[cell release];
		}
	}
	return self;
}

- (void)mouseDown:(NSEvent *)theEvent{
    
    NSPoint point = [self convertPoint:[theEvent locationInWindow] fromView:nil];
    // NSLog(@"the point is at x = %f and y = %f", point.x, point.y);
    NSCell *cell = [self cellAtPoint:point usingButton:YES];
    
    if(cell && [[self delegate] respondsToSelector:@selector(arrowClickedInFormCell:)]){
		[[self delegate] arrowClickedInFormCell:cell];
        // keep the textfield from getting the selection, so this looks more like a button
        [[self window] makeFirstResponder:nil];
		// don't do the default implementation
		return;
    }
	
    [super mouseDown:theEvent];
}

// the AppKit calls this when necessary, so it's caching the rects for us
- (void)resetCursorRects{
    
    int rows = [self numberOfRows];
    int columns = [self numberOfColumns];
    int i = 0;
    int j = 0;
    NSRect aRect;
    NSCell *aCell;
    
    while(i < rows){
        while(j < columns){
            // Get the cell's frame rect
            aRect = [self cellFrameAtRow:i column:j];
            
            // this portion depends on the isInherited property of the cell's object, which is
            // not a great idea in a view subclass, but it's straightforward and this class is
            // pretty much tied to BibEditor anyway
            aCell = [self cellAtRow:i column:j];
			if([[self delegate] respondsToSelector:@selector(formCellHasArrowButton:)] &&
			   [[self delegate] formCellHasArrowButton:aCell]){
                
                // only add an I-beam for the text portion
                aRect.size.width -= ButtonRectWidth;
                [self addCursorRect:aRect cursor:[NSCursor IBeamCursor]];
                
                // set up the coordinates for the button, since we need special behavior for those in mouseDown
                // Offset the origin by the (width of cell), since we just shrank it above
                aRect.origin.x += aRect.size.width;
                // Shrink the width so we just get the button widget
                aRect.size.width = ButtonRectWidth;
                aRect.size.height;
                
                // set a finger cursor for the button part, since this cell's object is inherited
                [self addCursorRect:aRect cursor:[BDSKForm fingerCursor]];
            } else {
                // set an I-beam cursor for the entire text field cell
                [self addCursorRect:aRect cursor:[NSCursor IBeamCursor]];
            }
            j++;
        }
        j = 0;
        i++;
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
	
	NSCell *cell = [self cellAtRow:row column:column];
	
	// if we use a button, we have to see if it is in the button rect
	if(usingButton){ 
		// see if there is an arrow button
		if([[self delegate] respondsToSelector:@selector(formCellHasArrowButton:)] &&
		   [[self delegate] formCellHasArrowButton:cell]){
			NSRect aRect = [self cellFrameAtRow:row column:column];
			// Offset the origin by the (width of cell) - (width of button widget)
			aRect.origin.x += (aRect.size.width - ButtonRectWidth);
			// Shrink the width so we just get the button widget
			aRect.size.width = ButtonRectWidth;
			// check if point is in the button rect
			if( NSMouseInRect(point, aRect, [self isFlipped]) )
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

@implementation BDSKImageTextFormCell

// handles tabbing into a cell to display the macro editor
- (void)selectWithFrame:(NSRect)aRect inView:(NSView *)controlView editor:(NSText *)textObj delegate:(id)anObject start:(int)selStart length:(int)selLength{
	if([controlView isKindOfClass:[BDSKForm class]] &&
	   [[(BDSKForm*)controlView delegate] respondsToSelector:@selector(control:textShouldStartEditing:)]){
        [[(BDSKForm*)controlView delegate] control:(BDSKForm*)controlView textShouldStartEditing:textObj];
	}
    [super selectWithFrame:aRect inView:controlView editor:textObj delegate:anObject start:selStart length:selLength];
}

// handles mouse clicks to display the macro editor
- (void)editWithFrame:(NSRect)aRect inView:(NSView *)controlView editor:(NSText *)textObj delegate:(id)anObject event:(NSEvent *)theEvent{
	BOOL shouldEdit = YES;
	if([controlView isKindOfClass:[BDSKForm class]] &&
	   [[(BDSKForm*)controlView delegate] respondsToSelector:@selector(control:textShouldStartEditing:)]){
	   shouldEdit = [[(BDSKForm*)controlView delegate] control:(BDSKForm*)controlView textShouldStartEditing:textObj];
	}
	if(shouldEdit)
		[super editWithFrame:aRect inView:controlView editor:textObj delegate:anObject event:theEvent];
}

// this method is actually called by NSMatrix
- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView{
    //NSLog(@"%@ in view %@", NSStringFromSelector(_cmd), [controlView class]);
    [super drawWithFrame:cellFrame inView:controlView];

    if(![controlView isKindOfClass:[BDSKForm class]] ||
       ![[(BDSKForm *)controlView delegate] respondsToSelector:@selector(formCellHasArrowButton:)] ||
	   ![[(BDSKForm *)controlView delegate] formCellHasArrowButton:self])
        return;

    // get the arrow image from the bundle
    static NSImage *arrowImage;
    if(!arrowImage)
        arrowImage = [NSImage imageNamed:@"ArrowImage"];
    NSAssert(arrowImage != nil, @"Can't find arrow image.");
        
    // location chosen by trial-and-error for NSForm cells in BibEditor
    NSPoint thePoint;
    thePoint.x = (cellFrame.origin.x + cellFrame.size.width - [arrowImage size].width - 3);
    thePoint.y = cellFrame.origin.y + cellFrame.size.height - 3;
    
    [controlView lockFocus];
    [arrowImage compositeToPoint:thePoint operation:NSCompositeSourceOver];
    [controlView unlockFocus];
}

@end
