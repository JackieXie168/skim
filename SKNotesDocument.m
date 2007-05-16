//
//  SKNotesDocument.m
//  Skim
//
//  Created by Christiaan Hofman on 4/10/07.
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

#import "SKNotesDocument.h"
#import "SKDocument.h"
#import "SKNoteOutlineView.h"
#import "BDAlias.h"

@implementation SKNotesDocument

- (id)init {
    if (self = [super init]) {
        notes = [[NSMutableArray alloc] initWithCapacity:10];
    }
    return self;
}

- (void)dealloc {
    [notes release];
    [super dealloc];
}

- (NSString *)windowNibName {
    return @"NotesDocument";
}

- (void)windowControllerDidLoadNib:(NSWindowController *)aController {
    [aController setShouldCloseDocument:YES];
    
    NSSortDescriptor *indexSortDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"pageIndex" ascending:YES] autorelease];
    NSSortDescriptor *contentsSortDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"contents" ascending:YES] autorelease];
    [arrayController setSortDescriptors:[NSArray arrayWithObjects:indexSortDescriptor, contentsSortDescriptor, nil]];
    
    [outlineView reloadData];
}

- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError {
    NSData *data = nil;
    
    if ([typeName isEqualToString:SKNotesDocumentType]) {
        data = [NSKeyedArchiver archivedDataWithRootObject:[notes valueForKey:@"dictionaryValue"]];
    } else if ([typeName isEqualToString:SKNotesRTFDocumentType]) {
        data = [self notesRTFData];
    }
    
    if (data == nil && outError != NULL)
        *outError = [NSError errorWithDomain:SKDocumentErrorDomain code:0 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Unable to write notes", @"Error description"), NSLocalizedDescriptionKey, nil]];
    
    return data;
}

- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError {
    BOOL didRead = NO;
    
    if ([typeName isEqualToString:SKNotesDocumentType]) {
        NSArray *array = [NSKeyedUnarchiver unarchiveObjectWithData:data];
        
        if (array) {
            NSEnumerator *dictEnum = [array objectEnumerator];
            NSDictionary *dict;
            NSMutableArray *newNotes = [NSMutableArray arrayWithCapacity:[array count]];
            
            while (dict = [dictEnum nextObject]) {
                NSMutableDictionary *note = [dict mutableCopy];
                
                if ([[dict valueForKey:@"type"] isEqualToString:@"Note"])
                    [note setObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithFloat:85.0], @"rowHeight", [dict valueForKey:@"text"], @"contents", nil] forKey:@"child"];
                
                [newNotes addObject:note];
                [note release];
            }
            [[self mutableArrayValueForKey:@"notes"] setArray:newNotes];
            [outlineView reloadData];
            didRead = YES;
        }
    }
    
    if (didRead == NO && outError != NULL)
        *outError = [NSError errorWithDomain:SKDocumentErrorDomain code:0 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Unable to load file", @"Error description"), NSLocalizedDescriptionKey, nil]];
    
    return didRead;
}

- (NSData *)notesRTFData {
    NSMutableAttributedString *attrString = [[NSMutableAttributedString alloc] init];
    NSEnumerator *noteEnum = [notes objectEnumerator];
    NSDictionary *note;
    NSData *data;
    NSFont *standardFont = [NSFont systemFontOfSize:12.0];
    NSAttributedString *newlinesAttrString = [[NSAttributedString alloc] initWithString:@"\n\n" attributes:[NSDictionary dictionaryWithObjectsAndKeys:standardFont, NSFontAttributeName, nil]];
    
    while (note = [noteEnum nextObject]) {
        NSString *type = [note valueForKey:@"type"];
        NSString *contents = [note valueForKey:@"contents"];
        NSFont *font = [note valueForKey:@"font"];
        NSAttributedString *tmpAttrString = nil;
        NSString *tmpString = nil;
        
        if ([type isEqualToString:@"FreeText"]) 
            tmpString = NSLocalizedString(@"Text Note", @"Description for export");
        else if ([type isEqualToString:@"Note"]) 
            tmpString = NSLocalizedString(@"Anchored Note", @"Description for export");
        else if ([type isEqualToString:@"Circle"]) 
            tmpString = NSLocalizedString(@"Circle", @"Description for export");
        else if ([type isEqualToString:@"Square"]) 
            tmpString = NSLocalizedString(@"Box", @"Description for export");
        else if ([type isEqualToString:@"MarkUp"] || [type isEqualToString:@"Highlight"]) 
            tmpString = NSLocalizedString(@"Highlight", @"Description for export");
        else if ([type isEqualToString:@"Underline"]) 
            tmpString = NSLocalizedString(@"Underline", @"Description for export");
        else if ([type isEqualToString:@"StrikeOut"]) 
            tmpString = NSLocalizedString(@"Strike Out", @"Description for export");
        else if ([type isEqualToString:@"Arrow"]) 
            tmpString = NSLocalizedString(@"Arrow", @"Description for export");
        tmpString = [NSString stringWithFormat:NSLocalizedString(@"%C %@, page %i", @"Description for export"), 0x2022, tmpString, [[note valueForKey:@"pageIndex"] unsignedIntValue] + 1]; 
        tmpAttrString = [[NSAttributedString alloc] initWithString:tmpString attributes:[NSDictionary dictionaryWithObjectsAndKeys:standardFont, NSFontAttributeName, nil]];
        [attrString appendAttributedString:tmpAttrString];
        [tmpAttrString release];
        [attrString appendAttributedString:newlinesAttrString];
        
        if ([contents length]) {
            tmpAttrString = [[NSAttributedString alloc] initWithString:contents ? contents : @"" attributes:[NSDictionary dictionaryWithObjectsAndKeys:font ? font : standardFont, NSFontAttributeName, nil]];
            [attrString appendAttributedString:tmpAttrString];
            [tmpAttrString release];
            [attrString appendAttributedString:newlinesAttrString];
        }
        
        tmpAttrString = [note valueForKey:@"text"];
        if ([tmpAttrString length]) {
            [attrString appendAttributedString:tmpAttrString];
            [attrString appendAttributedString:newlinesAttrString];
        }
    }
    
    data = [attrString RTFFromRange:NSMakeRange(0, [attrString length]) documentAttributes:nil];
    [attrString release];
    [newlinesAttrString release];
    
    return data;
}

// these are necessary for the app controller, we may change it there
- (NSDictionary *)currentDocumentSetup {
    NSMutableDictionary *setup = [NSMutableDictionary dictionary];
    NSString *fileName = [self fileName];
    
    if (fileName) {
        NSData *data = [[BDAlias aliasWithPath:fileName] aliasData];
        
        [setup setObject:fileName forKey:@"fileName"];
        if(data)
            [setup setObject:data forKey:@"_BDAlias"];
    }
    
    return setup;
}

#pragma mark Accessors

- (NSArray *)notes {
    return notes;
}

- (void)setNotes:(NSArray *)newNotes {
    [notes setArray:notes];
}

- (unsigned)countOfNotes {
    return [notes count];
}

- (id)objectInNotesAtIndex:(unsigned)theIndex {
    return [notes objectAtIndex:theIndex];
}

- (void)insertObject:(id)obj inNotesAtIndex:(unsigned)theIndex {
    [notes insertObject:obj atIndex:theIndex];
}

- (void)removeObjectFromNotesAtIndex:(unsigned)theIndex {
    [notes removeObjectAtIndex:theIndex];
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
        return [[arrayController arrangedObjects] objectAtIndex:index];
    } else {
        return [item valueForKey:@"child"];
    }
}

- (id)outlineView:(NSOutlineView *)ov objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item {
    NSString *tcID = [tableColumn identifier];
    if ([tcID isEqualToString:@"note"]) {
        return [item valueForKey:@"contents"];
    } else if([tcID isEqualToString:@"type"]) {
        return [NSDictionary dictionaryWithObjectsAndKeys:[item valueForKey:@"type"], @"type", nil];
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
