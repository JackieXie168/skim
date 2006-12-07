/*
This software is Copyright (c) 2002, Michael O. McCracken
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

- Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
-  Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
-  Neither the name of Michael O. McCracken nor the names of any contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#import "BDSKDragOutlineView.h"
@class BibItem;
@class BibAuthor;
#import <OmniBase/OmniBase.h>

@implementation NSOutlineView (MyExtensions)
- (NSArray*)allSelectedItems {
    NSMutableArray *items = [NSMutableArray array];
    NSEnumerator *selectedRows = [self selectedRowEnumerator];
    NSNumber *selRow = nil;
    while( (selRow = [selectedRows nextObject]) ) {
        if ([self itemAtRow:[selRow intValue]])
            [items addObject: [self itemAtRow:[selRow intValue]]];
    }
    return items;
}

- (void) removeAllTableColumns{
    NSEnumerator *e = [[self tableColumns] objectEnumerator];
    NSTableColumn *tc;

    while (tc = [e nextObject]) {
        if(tc != [self outlineTableColumn])
            [self removeTableColumn:tc];
    }
}

@end

@implementation BDSKDragOutlineView
- (NSImage*)dragImageForRows:(NSArray*)dragRows event:(NSEvent*)dragEvent dragImageOffset:(NSPointPointer)dragImageOffset{
    NSPasteboard *myPb = [NSPasteboard pasteboardWithUniqueName];
    NSArray *types;
    NSImage *image;
    NSAttributedString *string;
    NSString *s;
    NSSize maxSize = NSMakeSize(600,200); // tunable...
    NSSize stringSize;

    NSMutableArray *dragItems = [NSMutableArray arrayWithCapacity:5];
    NSEnumerator *rowE = [dragRows objectEnumerator];
    NSNumber *row = nil;
    NSEnumerator *childE = nil;
    id child = nil;
    id rowItem;
    
    while(row = [rowE nextObject]){
        rowItem = [self itemAtRow:[row intValue]];

        if([rowItem isKindOfClass:[BibItem class]]){
            [dragItems addObject:rowItem];
        }else if([rowItem isKindOfClass:[BibAuthor class]]){
            // rowItem *should* be expanded if we're getting called. (We assume this!)
#warning bibauthor dependence
            childE = [[rowItem children] objectEnumerator];
            while(child = [childE nextObject]){
                if ([dragItems indexOfObjectIdenticalTo:child] == NSNotFound) {
                    [dragItems addObject:child];
                }
            }

        }
    }    
    if([[self dataSource] outlineView:self
                          writeItems:dragItems
                       toPasteboard:myPb]){
        types = [myPb types];
        if([myPb hasType:NSStringPboardType])
        {
            // draw the string into image
            s = [myPb stringForType:NSStringPboardType];
            string = [[NSAttributedString alloc] initWithString:s];
            image = [[[NSImage alloc] init] autorelease];
            stringSize = [string size];
            if(stringSize.width > maxSize.width)
                stringSize.width = maxSize.width += 4.0;
            if(stringSize.height > maxSize.height)
                stringSize.height = maxSize.height += 4.0; // 4.0 from oakit
            [image setSize:stringSize];

            [image lockFocus];
            [string drawAtPoint:NSZeroPoint];
            //[s drawWithFont:[NSFont systemFontOfSize:12.0] color:[NSColor textColor] alignment:NSCenterTextAlignment verticallyCenter:YES inRectangle:(NSRect){NSMakePoint(0, -2), stringSize}];
            [image unlockFocus];

        }
    }else if([myPb hasType:NSPDFPboardType]){
        image = [[[NSImage alloc] initWithData:[myPb dataForType:NSPDFPboardType]] autorelease];
    }else{
        image = [super dragImageForRows:dragRows event:dragEvent dragImageOffset:dragImageOffset];
    }
    //*dragImageOffset = NSMakePoint(([image size].width)/2.0, 0.0);
    return image;
}

- (NSDragOperation)draggingSourceOperationMaskForLocal:(BOOL)isLocal {
    if (isLocal) return NSDragOperationEvery; // might want more than this later, maybe?
    else return NSDragOperationCopy;
}

- (void)awakeFromNib{
    typeAheadHelper = [[OATypeAheadSelectionHelper alloc] init];
    [typeAheadHelper setDataSource:self];
    [typeAheadHelper setCyclesSimilarResults:YES];
}

- (void)dealloc{
    [typeAheadHelper release];
}

- (void)keyDown:(NSEvent *)event{
    unichar c = [[event characters] characterAtIndex:0];
    NSCharacterSet *alnum = [NSCharacterSet alphanumericCharacterSet];
    if (c == NSDeleteCharacter ||
        c == NSBackspaceCharacter) {
        [[self delegate] delPub:nil];
    }else if(c == NSNewlineCharacter ||
             c == NSEnterCharacter ||
             c == NSCarriageReturnCharacter){
        [[self delegate] editPubCmd:nil];
    }else if ([alnum characterIsMember:c]) {
        //NSLog(@"keydown sending %c", c);
        [typeAheadHelper newProcessKeyDownCharacter:c];
    }else{
        [super keyDown:event];
    }
}

#pragma mark || Methods to support the type-ahead selector.
- (NSArray *)typeAheadSelectionItems{
    NSEnumerator *authE = [[[self delegate] allAuthors] objectEnumerator];
    NSMutableArray *authStringsArray = [NSMutableArray arrayWithCapacity:15];
    id auth = nil;
    while(auth = [authE nextObject]){
        [authStringsArray addObject:[auth name]];
    }
    return [[authStringsArray copy] autorelease];
}

- (NSString *)currentlySelectedItem{
    int selRow = [self selectedRow];
    int level = -1;
    
    if (selRow != -1) {
    	// if there is a row, find the row above it that is at top-level and return the value of that one. (It's the parent)
        level = [self levelForRow:selRow];
        // sanity check:
        OBASSERT(level >= 0);
        while(level > 0 && selRow > 0){
            selRow--;
            level = [self levelForRow:selRow];
        }
      /*  return [[[self dataSource] outlineView:self
                    objectValueForTableColumn:[self outlineTableColumn]
                                       byItem:[self itemAtRow:selRow]] ]; */
        return [[self itemAtRow:selRow] name];
    }else{
        return nil;
    }
}

- (void)typeAheadSelectItemAtIndex:(int)itemIndex{
    NSString *itemToSelect = [[[self delegate] allAuthors] objectAtIndex:itemIndex];
    int  rowToSelect = [self rowForItem:itemToSelect];
    [self selectRow:rowToSelect byExtendingSelection:NO];
}
@end
