//
//  SKNoteOutlineView.m
//  Skim
//
//  Created by Christiaan Hofman on 2/25/07.
/*
 This software is Copyright (c) 2007
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

#import "SKNoteOutlineView.h"
#import <Quartz/Quartz.h>


@implementation SKNoteOutlineView

- (void)delete:(id)sender {
    if ([[self delegate] respondsToSelector:@selector(outlineViewDeleteSelectedRows:)]) {
		if ([[self selectedRowIndexes] count] == 0)
			NSBeep();
		else
			[[self delegate] outlineViewDeleteSelectedRows:self];
    }
}

- (void)keyDown:(NSEvent *)theEvent {
    NSString *characters = [theEvent charactersIgnoringModifiers];
    unichar eventChar = [characters length] > 0 ? [characters characterAtIndex:0] : 0;
	unsigned int modifiers = [theEvent modifierFlags] & NSDeviceIndependentModifierFlagsMask;
    
	if ((eventChar == NSDeleteCharacter || eventChar == NSDeleteFunctionKey) && modifiers == 0)
        [self delete:self];
	else
		[super keyDown:theEvent];
}

- (BOOL)resizeRow:(int)row withEvent:(NSEvent *)theEvent {
    id item = [self itemAtRow:row];
    NSPoint startPoint = [self convertPoint:[theEvent locationInWindow] fromView:nil];
    float startHeight = [[self delegate] outlineView:self heightOfRowByItem:item];
	BOOL keepGoing = YES;
    BOOL dragged = NO;
	
    [[NSCursor resizeUpDownCursor] push];
    
	while (keepGoing) {
		theEvent = [[self window] nextEventMatchingMask: NSLeftMouseUpMask | NSLeftMouseDraggedMask];
		switch ([theEvent type]) {
			case NSLeftMouseDragged:
            {
                NSPoint currentPoint = [self convertPoint:[theEvent locationInWindow] fromView:nil];
                float currentHeight = fmax([self rowHeight], startHeight + currentPoint.y - startPoint.y);
                
                [[self delegate] outlineView:self setHeightOfRow:currentHeight byItem:item];
                [self noteHeightOfRowsWithIndexesChanged:[NSIndexSet indexSetWithIndex:row]];
                
                dragged = YES;
                
                break;
			}
            
            case NSLeftMouseUp:
                keepGoing = NO;
                break;
			
            default:
                break;
        }
    }
    [NSCursor pop];
    
    return dragged;
}

- (void)mouseDown:(NSEvent *)theEvent {
    if ([[self delegate] respondsToSelector:@selector(outlineView:canResizeRowByItem:)] && [[self delegate] respondsToSelector:@selector(outlineView:setHeightOfRow:byItem:)]) {
        NSPoint mouseLoc = [self convertPoint:[theEvent locationInWindow] fromView:nil];
        int row = [self rowAtPoint:mouseLoc];
        
        if (row != -1 && [[self delegate] outlineView:self canResizeRowByItem:[self itemAtRow:row]]) {
            NSRect ignored, rect = [self rectOfRow:row];
            NSDivideRect(rect, &rect, &ignored, 5.0, [self isFlipped] ? NSMaxYEdge : NSMinYEdge);
            if (NSPointInRect(mouseLoc, rect) && [self resizeRow:row withEvent:theEvent])
                return;
        }
    }
    [super mouseDown:theEvent];
}

- (void)drawRect:(NSRect)aRect {
    [super drawRect:aRect];
    if ([[self delegate] respondsToSelector:@selector(outlineView:canResizeRowByItem:)]) {
        NSRange visibleRows = [self rowsInRect:[self visibleRect]];
        
        if (visibleRows.length == 0)
            return;
        
        unsigned int row;
        BOOL isFirstResponder = [[self window] isKeyWindow] && [[self window] firstResponder] == self;
        
        [NSGraphicsContext saveGraphicsState];
        [NSBezierPath setDefaultLineWidth:1.0];
        
        for (row = visibleRows.location; row < NSMaxRange(visibleRows); row++) {
            id item = [self itemAtRow:row];
            if ([[self delegate] outlineView:self canResizeRowByItem:item] == NO)
                continue;
            
            BOOL isHighlighted = isFirstResponder && [self isRowSelected:row];
            NSColor *color = isHighlighted ? [NSColor whiteColor] : [NSColor grayColor];
            NSRect rect = [self rectOfRow:row];
            NSPoint startPoint = NSMakePoint(NSMaxX(rect) - 20.0, NSMaxY(rect) - 1.5);
            NSPoint endPoint = NSMakePoint(NSMaxX(rect), NSMaxY(rect) - 1.5);
            
            [color set];
            [NSBezierPath strokeLineFromPoint:startPoint toPoint:endPoint];
            [[color colorWithAlphaComponent:0.5] set];
            startPoint.y -= 2.0;
            endPoint.y -= 2.0;
            [NSBezierPath strokeLineFromPoint:startPoint toPoint:endPoint];
        }
        
        [NSGraphicsContext restoreGraphicsState];
    }
}

- (void)collapseItem:(id)item collapseChildren:(BOOL)collapseChildren {
    // NSOutlineView seems to call resetCursorRect when expanding, but not when collapsing
    [super collapseItem:item collapseChildren:collapseChildren];
    [self resetCursorRects];
}

-(void)resetCursorRects {
    if ([[self delegate] respondsToSelector:@selector(outlineView:canResizeRowByItem:)]) {
        [self discardCursorRects];
        [super resetCursorRects];

        NSRange visibleRows = [self rowsInRect:[self visibleRect]];
        unsigned int row;
        
        if (visibleRows.length == 0)
            return;
        
        for (row = visibleRows.location; row < NSMaxRange(visibleRows); row++) {
            id item = [self itemAtRow:row];
            if ([[self delegate] outlineView:self canResizeRowByItem:item] == NO)
                continue;
            NSRect ignored, rect = [self rectOfRow:row];
            NSDivideRect(rect, &rect, &ignored, 5.0, [self isFlipped] ? NSMaxYEdge : NSMinYEdge);
            [self addCursorRect:rect cursor:[NSCursor resizeUpDownCursor]];
        }
    } else {
        [super resetCursorRects];
    }
}

@end

#pragma mark -

@implementation SKAnnotationTypeImageCell

- (void)dealloc {
    [type release];
    [super dealloc];
}

- (void)setObjectValue:(id)anObject {
    if ([anObject isKindOfClass:[NSDictionary class]]) {
        NSString *newType = [anObject valueForKey:@"type"];
        BOOL newActive = [[anObject valueForKey:@"active"] boolValue];
        if (type != newType) {
            [type release];
            type = [newType retain];
        }
        active = newActive;
    } else if ([anObject isKindOfClass:[NSString class]]) {
        if (type != anObject) {
            [type release];
            type = [anObject retain];
        }
        active = NO;
    } else {
        [super setObjectValue:anObject];
    }
}

static NSImage *createInvertedImage(NSImage *image)
{
    static CIFilter *invertFilter = nil;
    if (invertFilter == nil)
        invertFilter = [[CIFilter filterWithName:@"CIColorInvert"] retain];    
    
    CIImage *ciImage = [CIImage imageWithData:[image TIFFRepresentation]];
    
    [invertFilter setValue:ciImage forKey:@"inputImage"];
    ciImage = [invertFilter valueForKey:@"outputImage"];
    
    NSImage *nsImage = [[NSImage alloc] initWithSize:[image size]];
    CGRect cgRect = [ciImage extent];
    NSRect nsRect = *(NSRect*)&cgRect;
    
    [nsImage lockFocus];
    [ciImage drawAtPoint:NSZeroPoint fromRect:nsRect operation:NSCompositeCopy fraction:1.0];
    [nsImage unlockFocus];
    
    return nsImage;
}

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
    static NSImage *textImage = nil;
    static NSImage *noteImage = nil;
    static NSImage *circleImage = nil;
    static NSImage *squareImage = nil;
    static NSImage *highlightImage = nil;
    static NSImage *strikeOutImage = nil;
    static NSImage *underlineImage = nil;
    static NSImage *invertedTextImage = nil;
    static NSImage *invertedNoteImage = nil;
    static NSImage *invertedCircleImage = nil;
    static NSImage *invertedSquareImage = nil;
    static NSImage *invertedHighlightImage = nil;
    static NSImage *invertedStrikeOutImage = nil;
    static NSImage *invertedUnderlineImage = nil;
    
    if (textImage == nil) {
        textImage = [[NSImage imageNamed:@"AnnotateToolAdorn"] retain];
        noteImage = [[NSImage imageNamed:@"NoteToolAdorn"] retain];
        circleImage = [[NSImage imageNamed:@"CircleToolAdorn"] retain];
        squareImage = [[NSImage imageNamed:@"SquareToolAdorn"] retain];
        highlightImage = [[NSImage imageNamed:@"HighlightToolAdorn"] retain];
        strikeOutImage = [[NSImage imageNamed:@"StrikeOutToolAdorn"] retain];
        underlineImage = [[NSImage imageNamed:@"UnderlineToolAdorn"] retain];
        invertedTextImage = createInvertedImage(textImage);
        invertedNoteImage = createInvertedImage(noteImage);
        invertedCircleImage = createInvertedImage(circleImage);
        invertedSquareImage = createInvertedImage(squareImage);
        invertedHighlightImage = createInvertedImage(highlightImage);
        invertedStrikeOutImage = createInvertedImage(strikeOutImage);
        invertedUnderlineImage = createInvertedImage(underlineImage);
    }
    
    BOOL isSelected = [self isHighlighted] && [[controlView window] isKeyWindow] && [[[controlView window] firstResponder] isEqual:controlView];
    NSImage *image = nil;
    
    if ([type isEqualToString:@"FreeText"])
        image = isSelected ? invertedTextImage : textImage;
    else if ([type isEqualToString:@"Note"])
        image = isSelected ? invertedNoteImage : noteImage;
    else if ([type isEqualToString:@"Circle"])
        image = isSelected ? invertedCircleImage : circleImage;
    else if ([type isEqualToString:@"Square"])
        image = isSelected ? invertedTextImage : squareImage;
    else if ([type isEqualToString:@"Highlight"])
        image = isSelected ? invertedHighlightImage : highlightImage;
    else if ([type isEqualToString:@"StrikeOut"])
        image = isSelected ? invertedStrikeOutImage : strikeOutImage;
    else if ([type isEqualToString:@"Underline"])
        image = isSelected ? invertedUnderlineImage : underlineImage;
    
    if (active) {
        [[NSGraphicsContext currentContext] saveGraphicsState];
        if (isSelected)
            [[NSColor colorWithDeviceWhite:1.0 alpha:0.8] set];
        else
            [[NSColor colorWithDeviceWhite:0.0 alpha:0.7] set];
        [NSBezierPath strokeRect:NSInsetRect(cellFrame, 0.5, 0.5)];
        [[NSGraphicsContext currentContext] restoreGraphicsState];
    }
    
    [super setObjectValue:image];
    [super drawWithFrame:cellFrame inView:controlView];
}

@end
