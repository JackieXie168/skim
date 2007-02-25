//
//  BDSKNotesWindowController.m
//  Bibdesk
//
//  Created by Christiaan Hofman on 25/2/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "BDSKNotesWindowController.h"
#import "NSFileManager_ExtendedAttributes.h"


@implementation BDSKNotesWindowController

- (id)initWithURL:(NSURL *)aURL {
    if (self = [super init]) {
        if (aURL == nil) {
            [self release];
            return nil;
        }
        
        url = [aURL retain];
        notes = [[NSMutableArray alloc] init];
        
        [self refresh:self];
    }
    return self;
}

- (void)dealloc {
    [notes release];
    [super dealloc];
}

- (NSString *)windowNibName { return @"NotesWindow"; }

- (NSString *)windowTitleForDocumentDisplayName:(NSString *)displayName{
    return [NSString stringWithFormat:@"%@ - Notes", [[url path] lastPathComponent]];
}

- (NSString *)representedFilenameForWindow:(NSWindow *)aWindow {
    NSString *path = [url path];
    return path ? path : @"";
}

- (void)loadNotes {
    NSError *error = nil;
    NSArray *array = [[[NSFileManager defaultManager] skimNotesFromExtendedAttributesAtPath:[url path] error:&error] retain];
    
    if (array) {
        [notes removeAllObjects];
        notes = [array mutableCopy];
    } else {
        [NSApp presentError:error];
    }
}

#pragma mark Actions

- (IBAction)refresh:(id)sender {
    NSError *error = nil;
    NSArray *array = [[[NSFileManager defaultManager] skimNotesFromExtendedAttributesAtPath:[url path] error:&error] retain];
    
    if (array) {
        NSEnumerator *dictEnum = [array objectEnumerator];
        NSDictionary *dict;
        
        [notes removeAllObjects];
        while (dict = [dictEnum nextObject]) {
            NSMutableDictionary *note = [dict mutableCopy];
            
            if ([[dict valueForKey:@"type"] isEqualToString:@"Note"])
                [note setObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithFloat:85.0], @"rowHeight", [dict valueForKey:@"text"], @"contents", nil] forKey:@"child"];
            
            [notes addObject:note];
            [note release];
        }
        
        [outlineView reloadData];
    } else {
        [NSApp presentError:error];
    }
}

- (IBAction)openInSkim:(id)sender {
    [[NSWorkspace sharedWorkspace] openFile:[url path] withApplication:@"Skim"];
}

#pragma mark NSOutlineView datasource and delegate methods

- (int)outlineView:(NSOutlineView *)ov numberOfChildrenOfItem:(id)item {
    if (item == nil)
        return [notes count];
    else if ([[item valueForKey:@"type"] isEqualToString:@"Note"])
        return 1;
    return 0;
}

- (BOOL)outlineView:(NSOutlineView *)ov isItemExpandable:(id)item {
    return [[item valueForKey:@"type"] isEqualToString:@"Note"];
}

- (id)outlineView:(NSOutlineView *)ov child:(int)index ofItem:(id)item {
    if (item == nil) {
        return [notes objectAtIndex:index];
    } else {
        return [item valueForKey:@"child"];
    }
}

- (id)outlineView:(NSOutlineView *)ov objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item {
    NSString *tcID = [tableColumn identifier];
    if ([tcID isEqualToString:@"note"]) {
        return [item valueForKey:@"contents"];
    } else if ([tcID isEqualToString:@"page"]) {
        NSNumber *pageNumber = [item valueForKey:@"pageIndex"];
        return pageNumber ? [NSString stringWithFormat:@"%i", [pageNumber intValue] + 1] : nil;
    }
    return nil;
}

- (float)outlineView:(NSOutlineView *)ov heightOfRowByItem:(id)item {
    NSNumber *heightNumber = [item valueForKey:@"rowHeight"];
    return heightNumber ? [heightNumber floatValue] : 17.0;
}

- (void)outlineView:(NSOutlineView *)ov setHeightOfRow:(int)newHeight byItem:(id)item {
    [item setObject:[NSNumber numberWithFloat:newHeight] forKey:@"rowHeight"];
}

- (BOOL)outlineView:(NSOutlineView *)ov canResizeRowByItem:(id)item {
    return nil != [item valueForKey:@"rowHeight"];
}

- (NSString *)outlineView:(NSOutlineView *)ov toolTipForCell:(NSCell *)cell rect:(NSRectPointer)rect tableColumn:(NSTableColumn *)tableColumn item:(id)item mouseLocation:(NSPoint)mouseLocation {
    return [item valueForKey:@"type"] ? [item valueForKey:@"contents"] : [[item valueForKey:@"contents"] string];
}

@end


@implementation BDSKNotesOutlineView

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

@end
