// BDSKDragTableView.m

/*
 This software is Copyright (c) 2002,2003,2004,2005
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

#import "BDSKDragTableView.h"
#import "BibDocument.h"
#import "BibDocument_DataSource.h"
#import "NSImage+Toolbox.h"
#import "NSBezierPath_BDSKExtensions.h"

static NSColor *sStripeColor = nil;

@implementation BDSKDragTableView

// This method computes and returns an image to use for dragging.  Override this to return a custom image.  'dragRows' represents the rows participating in the drag.  'dragEvent' is a reference to the mouse down event that began the drag.  'dragImageOffset' is an in/out parameter.  This method will be called with dragImageOffset set to NSZeroPoint, but it can be modified to re-position the returned image.  A dragImageOffset of NSZeroPoint will cause the image to be centered under the mouse.

- (NSImage*)dragImageForRows:(NSArray*)dragRows event:(NSEvent*)dragEvent dragImageOffset:(NSPointPointer)dragImageOffset{
    NSImage *image = nil;
    NSString *s = nil;
    
    NSPasteboard *pb = [NSPasteboard pasteboardWithName:NSDragPboard];
    NSString *dragType = [pb availableTypeFromArray:[NSArray arrayWithObjects:NSFilenamesPboardType, NSURLPboardType, NSFilesPromisePboardType, NSPDFPboardType, NSRTFPboardType, NSStringPboardType, nil]];
	
    if([dragType isEqualToString:NSFilenamesPboardType]){
        image = [NSImage imageForFile:[[pb propertyListForType:NSFilenamesPboardType] objectAtIndex:0]];
    
    }else if([dragType isEqualToString:NSURLPboardType]){
        image = [[[NSImage imageForURL:[NSURL URLFromPasteboard:pb]] copy] autorelease];
        [image setSize:NSMakeSize(32,32)];
    
	}else if([dragType isEqualToString:NSFilesPromisePboardType]){
        image = [NSImage imageForFile:[[pb propertyListForType:NSFilesPromisePboardType] lastObject]];
        
    }else if([dragType isEqualToString:NSStringPboardType]){
        s = [pb stringForType:NSStringPboardType];  // draw the string from the drag pboard, if it's available
    
	} else {
        s = [[self dataSource] citeStringForRows:dragRows tableViewDragSource:self];
    }
    
    if(s){
		NSAttributedString *attrString;
		int maxLength  = 2000; // tunable...
		NSSize maxSize = NSMakeSize(600,200); // tunable...
		NSSize size;
		NSRect rect = NSZeroRect;
		NSPoint point = NSMakePoint(3.0, 2.0);
		NSColor *color = [NSColor secondarySelectedControlColor];
		
        attrString = [[[NSAttributedString alloc] initWithString:([s length] > maxLength)? [s substringToIndex:maxLength] : s] autorelease];
        size = [attrString size];
        if(size.width == 0 || size.height == 0){
            NSLog(@"string size was zero");
            size = maxSize; // work around bug in NSAttributedString
        }
        if(size.width > maxSize.width)
            size.width = maxSize.width += 4.0;
        if(size.height > maxSize.height)
            size.height = maxSize.height += 4.0; // 4.0 from oakit
        
		size.width += 2 * point.x;
		size.height += 2 * point.y;
		rect.size = size;
		rect = NSInsetRect(rect, 1.0, 1.0); // inset by half of the linewidth
                
		image = [[[NSImage alloc] initWithSize:size] autorelease];
        
        [image lockFocus];
		
		[[color colorWithAlphaComponent:0.2] set];
		[NSBezierPath fillRoundRectInRect:rect radius:4.0];
		[[color colorWithAlphaComponent:0.8] set];
		[NSBezierPath setDefaultLineWidth:2.0];
		[NSBezierPath strokeRoundRectInRect:rect radius:4.0];
		
        [attrString drawAtPoint:point];
        
        // draw a count of the rows being dragged, similar to Mail.app
        NSMutableAttributedString *countString = [[[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%i", [dragRows count]]] autorelease];
        [countString addAttribute:NSForegroundColorAttributeName value:[NSColor whiteColor] range:NSMakeRange(0, [countString length])];		
        NSSize countSize = [countString size];
        NSRect countRect = NSMakeRect(NSMaxX(rect) - 3 * countSize.width, countSize.width, countSize.width, countSize.height);
        [[NSColor redColor] set];
        [NSBezierPath fillHorizontalOvalAroundRect:countRect];
        [countString drawInRect:countRect];
        
        [image unlockFocus];
	}
	
    if(image){
		NSImage *dragImage = [[NSImage alloc] initWithSize:[image size]];
		
		[dragImage lockFocus];
        [image compositeToPoint:NSZeroPoint operation:NSCompositeCopy fraction:0.6];
        [dragImage unlockFocus];
		
		return [dragImage autorelease];
	}else{
        return [super dragImageForRows:dragRows event:dragEvent dragImageOffset:dragImageOffset];
    }
}

- (NSDragOperation)draggingSourceOperationMaskForLocal:(BOOL)isLocal {
    if (isLocal) return NSDragOperationEvery; // might want more than this later, maybe?
    else return NSDragOperationCopy;
}

- (void)awakeFromNib{
    typeAheadHelper = [[OATypeAheadSelectionHelper alloc] init];
    [typeAheadHelper setDataSource:[self delegate]]; // which is the bibdocument
    [typeAheadHelper setCyclesSimilarResults:YES];
	
	// setup custom header class (cf http://cocoa.mamasam.com/COCOADEV/2004/01/1/81202.php)
	NSTableHeaderView * currentTableHeaderView =  [self headerView];
	BDSKDragTableHeaderView * customTableHeaderView = [[[BDSKDragTableHeaderView alloc] init] autorelease];
	
	[customTableHeaderView setFrame:[currentTableHeaderView frame]];
	[customTableHeaderView setBounds:[currentTableHeaderView bounds]];
	
	[self setHeaderView:customTableHeaderView];	
}

- (void)dealloc{
    [typeAheadHelper release];
    [super dealloc];
}

-(NSMenu*)menuForEvent:(NSEvent *)evt {
	id theDelegate = [self delegate];
	NSPoint pt = [self convertPoint:[evt locationInWindow] fromView:nil];
	int column = [self columnAtPoint:pt];
	int row = [self rowAtPoint:pt];
	NSTableColumn *tableColumn = nil;
	
	if (column >= 0 && row >= 0 && [theDelegate respondsToSelector:@selector(tableView:menuForTableColumn:row:)]) {
		// select the clicked row if it isn't selected yet
		if (![self isRowSelected:row])
			[self selectRow:row byExtendingSelection:NO];
		return [theDelegate tableView:self menuForTableColumn:[[self tableColumns] objectAtIndex:column] row:row];	
	}
	return nil; 
} 

- (void)keyDown:(NSEvent *)event{
    unichar c = [[event characters] characterAtIndex:0];
    NSCharacterSet *alnum = [NSCharacterSet alphanumericCharacterSet];
    if (c == NSDeleteCharacter ||
        c == NSBackspaceCharacter) {
        [[self delegate] delPub:self];
    }else if(c == NSNewlineCharacter ||
             c == NSEnterCharacter ||
             c == NSCarriageReturnCharacter){
        [[self delegate] editPubCmd:nil];
    }else if(c == NSTabCharacter) {
        [[self window] selectNextKeyView:self];
    }else if(c == NSBackTabCharacter) { // shift-tab
        [[self window] selectPreviousKeyView:self];
    }else if(c == 0x0020){ // spacebar to page down in the lower pane of the BibDocument splitview, shift-space to page up
        if([event modifierFlags] & NSShiftKeyMask)
            [[self delegate] pageUpInPreview:nil];
        else
            [[self delegate] pageDownInPreview:nil];
    // following methods should solve the mysterious problem of arrow/page keys not working for some users
    }else if(c == NSPageDownFunctionKey){
        [[self enclosingScrollView] pageDown:self];
    }else if(c == NSPageUpFunctionKey){
        [[self enclosingScrollView] pageUp:self];
    }else if(c == NSUpArrowFunctionKey){
        NSArray *selRows = [[self selectedRowEnumerator] allObjects];
        int row = ([selRows count] != 0 ? [[selRows objectAtIndex:0] intValue] : 0);
        row = MAX(0, (row - 1));
        [self selectRow:row byExtendingSelection:([event modifierFlags] | NSShiftKeyMask)];
        [self scrollRowToVisible:row];
    }else if(c == NSDownArrowFunctionKey){
        NSArray *selRows = [[self selectedRowEnumerator] allObjects];
        int row = ([selRows count] != 0 ? [[selRows lastObject] intValue] : [self numberOfRows] - 1);
        row = MIN([self numberOfRows] - 1, (row + 1));
        [self selectRow:row byExtendingSelection:([event modifierFlags] | NSShiftKeyMask)];
        [self scrollRowToVisible:row];
    // pass it on the typeahead selector
    }else if ([alnum characterIsMember:c]) {
        [typeAheadHelper newProcessKeyDownCharacter:c];
    }else{
        [super keyDown:event];
    }
}

- (void)reloadData{
    [super reloadData];
    [typeAheadHelper rebuildTypeAheadSearchCache]; // if we resorted or searched, the cache is stale
}

// a convenience method.
- (void)removeAllTableColumns{
    while ([self numberOfColumns] > 0) {
        [self removeTableColumn:[[self tableColumns] objectAtIndex:0]];
    }
}

// Bogarted from apple sample code
#define STRIPE_RED   (237.0 / 255.0)
#define STRIPE_GREEN (243.0 / 255.0)
#define STRIPE_BLUE  (255.0 / 255.0)
// This is called after the table background is filled in,
// but before the cell contents are drawn.
// We override it so we can do our own light-blue row stripes a la iTunes.
- (void) highlightSelectionInClipRect:(NSRect)rect {
	if (BDSK_USING_JAGUAR) {	
		[self drawStripesInRect:rect];
	}
    [super highlightSelectionInClipRect:rect];
}

// This routine does the actual blue stripe drawing,
// filling in every other row of the table with a blue background
// so you can follow the rows easier with your eyes.
- (void) drawStripesInRect:(NSRect)clipRect {
    NSRect stripeRect;
    float fullRowHeight = [self rowHeight] + [self intercellSpacing].height;
    float clipBottom = NSMaxY(clipRect);
    int firstStripe = clipRect.origin.y / fullRowHeight;
    if (firstStripe % 2 == 0)
        firstStripe++;   // we're only interested in drawing the stripes
                         // set up first rect
    stripeRect.origin.x = clipRect.origin.x;
    stripeRect.origin.y = firstStripe * fullRowHeight;
    stripeRect.size.width = clipRect.size.width;
    stripeRect.size.height = fullRowHeight;
    // set the color
    if (sStripeColor == nil){
        sStripeColor = [[NSColor colorWithCalibratedRed:STRIPE_RED
                                                  green:STRIPE_GREEN
                                                   blue:STRIPE_BLUE
                                                  alpha:1.0] retain];
    }
    [sStripeColor set];
    // and draw the stripes
    while (stripeRect.origin.y < clipBottom) {
        NSRectFill(stripeRect);
        stripeRect.origin.y += fullRowHeight * 2.0;
    }
}

// ----------------------------------------------------------------------------------------
#pragma mark || tableView menu validation
// ----------------------------------------------------------------------------------------

// this is necessary as the NSTableView-OAExtensions defines these actions accordingly
- (BOOL)validateMenuItem:(id<NSMenuItem>)menuItem{
	SEL action = [menuItem action];
	if (action == @selector(delete:) || action == @selector(cut:) || 
		action == @selector(copy:) || action == @selector(paste:) || 
		action == @selector(duplicate:) || action == @selector(selectAll:)) {
		
		if ([_dataSource respondsToSelector:action]) {
			if ([_dataSource respondsToSelector:@selector(validateMenuItem:)]) {
				return [_dataSource validateMenuItem:menuItem];
			}
		} else if ([_delegate respondsToSelector:action]) {
			if ([_delegate respondsToSelector:@selector(validateMenuItem:)]) {
				return [_delegate validateMenuItem:menuItem];
			}
		}
		// this is our default
		return (action == @selector(paste:) || [self numberOfSelectedRows] > 0);
	}
}

@end


@implementation BDSKDragTableHeaderView 

- (NSMenu *)menuForEvent:(NSEvent *)theEvent {
	NSTableView * myTV = [self tableView];
	BibDocument * theDelegate = [myTV delegate];
	NSPoint pt = [self convertPoint:[theEvent locationInWindow] fromView:nil];
	int column = [self columnAtPoint:pt];
	NSTableColumn *tableColumn = nil;
    
	if ([theDelegate respondsToSelector:@selector(tableView:menuForTableHeaderColumn:)]) {
        if(column != -1)
            tableColumn = [[myTV tableColumns] objectAtIndex:column];
		return [theDelegate tableView:myTV menuForTableHeaderColumn:tableColumn];
	}
	return nil;
}

- (void)mouseDown:(NSEvent *)theEvent{
    // mouseDown in the table header has peculiar behavior for a double-click if you use -[NSTableView setDoubleAction:] on the
    // tableview itself.  The header sends a double-click action to the tableview row/cell that's selected.  
    // Since none of Apple's apps does this, we'll follow suit and just resort.
    if([theEvent clickCount] > 1)
        theEvent = [NSEvent mouseEventWithType:[theEvent type]
                                      location:[theEvent locationInWindow]
                                 modifierFlags:[theEvent modifierFlags]
                                     timestamp:[theEvent timestamp]
                                  windowNumber:[theEvent windowNumber]
                                       context:[theEvent context]
                                   eventNumber:[theEvent eventNumber]
                                    clickCount:1
                                      pressure:[theEvent pressure]];
    [super mouseDown:theEvent];
}

@end
