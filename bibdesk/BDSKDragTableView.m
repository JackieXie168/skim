// BDSKDragTableView.m

/*
 This software is Copyright (c) 2002,2003,2004,2005,2006
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

@implementation BDSKDragTableView

- (void)awakeFromNib{
    [super awakeFromNib]; // this updates the font
    typeAheadHelper = [[OATypeAheadSelectionHelper alloc] init];
    [typeAheadHelper setDataSource:[self delegate]]; // which is the bibdocument
    [typeAheadHelper setCyclesSimilarResults:YES];
}

- (void)dealloc{
    [typeAheadHelper setDataSource:nil];
    [typeAheadHelper release];
    [super dealloc];
}

- (void)keyDown:(NSEvent *)event{
    unichar c = [[event characters] characterAtIndex:0];
    NSCharacterSet *alnum = [NSCharacterSet alphanumericCharacterSet];
    unsigned int flags = ([event modifierFlags] & 0xffff0000U);
    if (c == 0x0020){ // spacebar to page down in the lower pane of the BibDocument splitview, shift-space to page up
        if([event modifierFlags] & NSShiftKeyMask)
            [[self delegate] pageUpInPreview:nil];
        else
            [[self delegate] pageDownInPreview:nil];
	// somehow alternate menu item shortcuts are not available globally, so we catch them here
	}else if((c == NSDeleteCharacter) &&  ([event modifierFlags] & NSAlternateKeyMask)) {
		[[self delegate] alternateDelete:nil];
    // following methods should solve the mysterious problem of arrow/page keys not working for some users
    }else if(c == NSPageDownFunctionKey){
        [[self enclosingScrollView] pageDown:self];
    }else if(c == NSPageUpFunctionKey){
        [[self enclosingScrollView] pageUp:self];
    }else if(c == NSUpArrowFunctionKey){
        int row = [[self selectedRowIndexes] firstIndex];
		if (row == NSNotFound)
			row = 0;
		else if (row > 0)
			row--;
        [self selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:([event modifierFlags] | NSShiftKeyMask)];
        [self scrollRowToVisible:row];
    }else if(c == NSDownArrowFunctionKey){
        int row = [[self selectedRowIndexes] lastIndex];
		if (row == NSNotFound)
			row = 0;
		else if (row < [self numberOfRows] - 1)
			row++;
        [self selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:([event modifierFlags] | NSShiftKeyMask)];
        [self scrollRowToVisible:row];
    // pass it on the typeahead selector
    }else if ([alnum characterIsMember:c] && flags == 0) {
        [typeAheadHelper substringProcessKeyDownCharacter:c];
    }else{
        [super keyDown:event];
    }
}

- (void)reloadData{
    [super reloadData];
    [typeAheadHelper queueSelectorOnce:@selector(rebuildTypeAheadSearchCache)]; // if we resorted or searched, the cache is stale
}

// a convenience method.
- (void)removeAllTableColumns{
    while ([self numberOfColumns] > 0) {
        [self removeTableColumn:[[self tableColumns] objectAtIndex:0]];
    }
}

// @@ legacy implementation for 10.3 compatibility
- (NSImage *)dragImageForRows:(NSArray *)dragRows event:(NSEvent *)dragEvent dragImageOffset:(NSPointPointer)dragImageOffset{
    NSMutableIndexSet *indexes = [NSMutableIndexSet indexSet];
    NSNumber *number;
    NSEnumerator *rowE = [dragRows objectEnumerator];
    while(number = [rowE nextObject])
        [indexes addIndex:[number intValue]];
    
    NSPoint zeroPoint = NSMakePoint(0,0);
	return [self dragImageForRowsWithIndexes:indexes tableColumns:[self tableColumns] event:dragEvent offset:&zeroPoint];
}

- (NSImage *)dragImageForRowsWithIndexes:(NSIndexSet *)dragRows tableColumns:(NSArray *)tableColumns event:(NSEvent*)dragEvent offset:(NSPointPointer)dragImageOffset{
   	if([[self dataSource] respondsToSelector:@selector(tableView:dragImageForRowsWithIndexes:)]) {
		NSImage *image = [[self dataSource] tableView:self dragImageForRowsWithIndexes:dragRows];
		if (image != nil)
			return image;
	}
    return [super dragImageForRowsWithIndexes:dragRows tableColumns:tableColumns event:dragEvent offset:dragImageOffset];
}
    

- (void)draggedImage:(NSImage *)anImage endedAt:(NSPoint)aPoint operation:(NSDragOperation)operation {
	[super draggedImage:anImage endedAt:aPoint operation:operation];
	if([[self dataSource] respondsToSelector:@selector(tableView:concludeDragOperation:)]) 
		[[self dataSource] tableView:self concludeDragOperation:operation];
}

@end
