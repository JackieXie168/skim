//
//  SKThumbnailTableView.m
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

#import "SKThumbnailTableView.h"
#import "OBUtilities.h"
#import "SKTypeSelectHelper.h"
#import "NSColor_SKExtensions.h"

static NSString *SKScrollerWillScrollNotification = @"SKScrollerWillScrollNotification";
static NSString *SKScrollerDidScrollNotification = @"SKScrollerDidScrollNotification";

@interface NSScroller (SKExtensions)
- (void)replacementTrackKnob:(NSEvent *)theEvent;
@end

@implementation NSScroller (SKExtensions)

static IMP originalTrackKnob = NULL;

+ (void)load {
    originalTrackKnob = OBReplaceMethodImplementationWithSelector(self, @selector(trackKnob:), @selector(replacementTrackKnob:));
}

- (void)replacementTrackKnob:(NSEvent *)theEvent {
    [[NSNotificationCenter defaultCenter] postNotificationName:SKScrollerWillScrollNotification object:self];
    originalTrackKnob(self, _cmd, theEvent);
    [[NSNotificationCenter defaultCenter] postNotificationName:SKScrollerDidScrollNotification object:self];
}

@end

@implementation SKThumbnailTableView

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}

- (NSColor *)backgroundColor {
    return [NSColor tableBackgroundColor];
}

- (NSColor *)highlightColor {
    if ([[self window] isKeyWindow] && [[self window] firstResponder] == self)
        return [NSColor alternateSelectedControlColor];
    else
        return [NSColor secondarySelectedTableColor];
}

- (void)highlightSelectionInClipRect:(NSRect)clipRect {
    NSColor *color = [self highlightColor];
    int row;
    NSRect rect;
    
    [NSGraphicsContext saveGraphicsState];
    
    if ([[self delegate] respondsToSelector:@selector(tableViewHighlightedRows:)]) {
        
        NSMutableIndexSet *rowIndexes = [[[self selectedRowIndexes] mutableCopy] autorelease];
        NSArray *rows = [[self delegate] tableViewHighlightedRows:self];
        int i, count = MIN((int)[rows count], 5);
        
        for (i = 0; i < count; i++) {
            row = [[rows objectAtIndex:i] intValue];
            rect = [self rectOfRow:row];
            if (NSIntersectsRect(rect, clipRect) && [rowIndexes containsIndex:row] == NO) {
                [[color colorWithAlphaComponent:0.5 - 0.1 * i] setFill];
                [NSBezierPath fillRect:rect];
            }
            [rowIndexes addIndex:row];
        }
    }
    
    row = [self selectedRow];
    if (row != -1) {
        rect = [self rectOfRow:row];
        if (NSIntersectsRect(rect, clipRect)) {
            [color setFill];
            NSRectFill([self rectOfRow:row]);
        }
    }
    
    [NSGraphicsContext restoreGraphicsState];
}

- (void)selectRowIndexes:(NSIndexSet *)indexes byExtendingSelection:(BOOL)extend {
    [super selectRowIndexes:indexes byExtendingSelection:extend];
    [self setNeedsDisplay:YES];
}

- (void)deselectRow:(int)row {
    [super deselectRow:row];
    [self setNeedsDisplay:YES];
}

- (BOOL)isScrolling { return isScrolling; }

- (void)handleScrollerWillScroll:(NSNotification *)note {
    isScrolling = YES;
}

- (void)handleScrollerDidScroll:(NSNotification *)note {
    isScrolling = NO;
    [self setNeedsDisplayInRect:[self visibleRect]];
}

- (void)awakeFromNib {
    NSScroller *scroller = [[self enclosingScrollView] verticalScroller];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleScrollerWillScroll:)
                                                 name:SKScrollerWillScrollNotification object:scroller];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleScrollerDidScroll:)
                                                 name:SKScrollerDidScrollNotification object:scroller];
}

- (void)setFrame:(NSRect)frameRect {
    [super setFrame:frameRect];
    [self noteHeightOfRowsWithIndexesChanged:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [self numberOfRows])]];
}

- (void)setFrameSize:(NSSize)frameSize {
    [super setFrameSize:frameSize];
    [self noteHeightOfRowsWithIndexesChanged:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [self numberOfRows])]];
}

- (void)mouseDown:(NSEvent *)theEvent {
    if (([theEvent modifierFlags] & NSCommandKeyMask) && [[self delegate] respondsToSelector:@selector(tableView:commandSelectRow:)]) {
        int row = [self rowAtPoint:[self convertPoint:[theEvent locationInWindow] fromView:nil]];
        if (row != -1 && [[self delegate] tableView:self commandSelectRow:row])
            return;
    }
    [super mouseDown:theEvent];
}

@end

#pragma mark -

@implementation SKSnapshotTableView

@end

#pragma mark -

@implementation SKSnapshotPageCell

static NSShadow *selectedShadow = nil;
static NSShadow *deselectedShadow = nil;
static NSColor *selectedColor = nil;
static NSColor *deselectedColor = nil;

+ (void)initialize
{
    BOOL didInit = NO;
    if (NO == didInit) {
        didInit = YES;
        selectedShadow = [[NSShadow alloc] init];
        [selectedShadow setShadowColor:[NSColor colorWithCalibratedWhite:1.0 alpha:0.2]];
        [selectedShadow setShadowOffset:NSMakeSize(0.0, -1.0)];
        deselectedShadow = [[NSShadow alloc] init];
        [deselectedShadow setShadowColor:[NSColor colorWithCalibratedWhite:1.0 alpha:0.2]];
        [deselectedShadow setShadowOffset:NSMakeSize(0.0, -1.0)];
        
        selectedColor = [[NSColor colorWithCalibratedWhite:1.0 alpha:1.0] copy];
        deselectedColor = [[NSColor colorWithCalibratedWhite:0.0 alpha:0.8] copy];
    }
}

- (void)setObjectValue:(id)anObject {
    [super setObjectValue:[anObject valueForKey:@"label"]];
    hasWindow = [[anObject valueForKey:@"hasWindow"] boolValue];
}

- (id)objectValue {
    return [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:hasWindow], @"hasWindow", [self stringValue], @"label", nil];
}

- (NSSize)cellSize {
    NSSize size = [super cellSize];
    size.width = fmaxf(size.width, 12.0);
    return size;
}

- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
    NSRect textRect, imageRect, ignored;
    NSDivideRect(cellFrame, &textRect, &imageRect, 17.0, NSMinYEdge);
    [super drawInteriorWithFrame:textRect inView:controlView];
    if (hasWindow) {
        BOOL isSelected = [self isHighlighted] && [[controlView window] isKeyWindow] && [[[controlView window] firstResponder] isEqual:controlView];
        float radius = 2.0;
        NSBezierPath *path = [NSBezierPath bezierPath];
        NSShadow *shadow;
        NSColor *fillColor;
        
        if (isSelected) {
            shadow = selectedShadow;
            fillColor = selectedColor;
        } else {
            shadow = deselectedShadow;
            fillColor = deselectedColor;
        }
        
        NSDivideRect(imageRect, &imageRect, &ignored, 10.0, NSMinYEdge);
        imageRect.origin.x += 4.0;
        imageRect.size.width = 10.0;
        
        [path moveToPoint:NSMakePoint(NSMinX(imageRect), NSMaxY(imageRect))];
        [path appendBezierPathWithArcWithCenter:NSMakePoint(NSMinX(imageRect) + radius, NSMinY(imageRect) + radius) radius:radius startAngle:180.0 endAngle:270.0];
        [path appendBezierPathWithArcWithCenter:NSMakePoint(NSMaxX(imageRect) - radius, NSMinY(imageRect) + radius) radius:radius startAngle:270.0 endAngle:360.0];
        [path lineToPoint:NSMakePoint(NSMaxX(imageRect), NSMaxY(imageRect))];
        [path closePath];
        
        imageRect = NSInsetRect(imageRect, 1.0, 2.0);
        imageRect.size.height += 1.0;
        
        [path appendBezierPath:[NSBezierPath bezierPathWithRect:imageRect]];
        [path setWindingRule:NSEvenOddWindingRule];
        
        [NSGraphicsContext saveGraphicsState];
        
        [shadow set];
        [fillColor setFill];

        [path fill];
        
        [NSGraphicsContext restoreGraphicsState];
    }
}

@end
