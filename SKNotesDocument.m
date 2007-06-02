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
#import "SKoutlineView.h"
#import "BDAlias.h"
#import "SKDocumentController.h"
#import "SKTemplateParser.h"
#import "SKApplicationController.h"
#import "NSString_SKExtensions.h"

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
    
    NSMenu *menu = [[[NSMenu allocWithZone:[NSMenu menuZone]] init] autorelease];
    NSMenuItem *menuItem = nil;
    menuItem = [menu addItemWithTitle:[@"FreeText" typeName] action:@selector(toggleDisplayNoteType:) keyEquivalent:@""];
    [menuItem setTarget:self];
    [menuItem setRepresentedObject:@"FreeText"];
    [menuItem setState:NSOnState];
    menuItem = [menu addItemWithTitle:[@"Note" typeName] action:@selector(toggleDisplayNoteType:) keyEquivalent:@""];
    [menuItem setTarget:self];
    [menuItem setState:NSOnState];
    [menuItem setRepresentedObject:@"Note"];
    menuItem = [menu addItemWithTitle:[@"Circle" typeName] action:@selector(toggleDisplayNoteType:) keyEquivalent:@""];
    [menuItem setTarget:self];
    [menuItem setRepresentedObject:@"Circle"];
    [menuItem setState:NSOnState];
    menuItem = [menu addItemWithTitle:[@"Square" typeName] action:@selector(toggleDisplayNoteType:) keyEquivalent:@""];
    [menuItem setTarget:self];
    [menuItem setRepresentedObject:@"Square"];
    [menuItem setState:NSOnState];
    menuItem = [menu addItemWithTitle:[@"Highlight" typeName] action:@selector(toggleDisplayNoteType:) keyEquivalent:@""];
    [menuItem setTarget:self];
    [menuItem setRepresentedObject:@"Highlight"];
    [menuItem setState:NSOnState];
    menuItem = [menu addItemWithTitle:[@"Underline" typeName] action:@selector(toggleDisplayNoteType:) keyEquivalent:@""];
    [menuItem setTarget:self];
    [menuItem setRepresentedObject:@"Underline"];
    [menuItem setState:NSOnState];
    menuItem = [menu addItemWithTitle:[@"StrikeOut" typeName] action:@selector(toggleDisplayNoteType:) keyEquivalent:@""];
    [menuItem setTarget:self];
    [menuItem setRepresentedObject:@"StrikeOut"];
    [menuItem setState:NSOnState];
    menuItem = [menu addItemWithTitle:[@"Line" typeName] action:@selector(toggleDisplayNoteType:) keyEquivalent:@""];
    [menuItem setTarget:self];
    [menuItem setRepresentedObject:@"Line"];
    [menuItem setState:NSOnState];
    [[outlineView headerView] setMenu:menu];
    
    [outlineView reloadData];
}

- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError {
    NSData *data = nil;
    
    if ([typeName isEqualToString:SKNotesDocumentType]) {
        data = [NSKeyedArchiver archivedDataWithRootObject:[notes valueForKey:@"dictionaryValue"]];
    } else if ([typeName isEqualToString:SKNotesRTFDocumentType]) {
        data = [self notesRTFData];
    } else if ([typeName isEqualToString:SKNotesTextDocumentType]) {
        data = [[self notesString] dataUsingEncoding:NSUTF8StringEncoding];
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

- (NSString *)notesString {
    NSString *templatePath = [[NSApp delegate] pathForApplicationSupportFile:@"notesTemplate" ofType:@"txt"];
    NSString *templateString = [[NSString alloc] initWithContentsOfFile:templatePath encoding:NSUTF8StringEncoding error:NULL];
    NSString *string = [SKTemplateParser stringByParsingTemplate:templateString usingObject:self];
    return string;
}

- (NSData *)notesRTFData {
    NSString *templatePath = [[NSApp delegate] pathForApplicationSupportFile:@"notesTemplate" ofType:@"rtf"];
    NSDictionary *docAttributes = nil;
    NSAttributedString *templateAttrString = [[NSAttributedString alloc] initWithPath:templatePath documentAttributes:&docAttributes];
    NSAttributedString *attrString = [SKTemplateParser attributedStringByParsingTemplate:templateAttrString usingObject:self];
    NSData *data = [attrString RTFFromRange:NSMakeRange(0, [attrString length]) documentAttributes:docAttributes];
    [templateAttrString release];
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

- (IBAction)openPDF:(id)sender {
    NSString *path = [[[self fileName] stringByDeletingPathExtension] stringByAppendingPathExtension:@"pdf"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:path])
        [[NSDocumentController sharedDocumentController] openDocumentWithContentsOfURL:[NSURL fileURLWithPath:path] display:YES error:NULL];
    else NSBeep();
}

- (void)toggleDisplayNoteType:(id)sender {
    [sender setState:![sender state]];
    
    NSExpression *lhs = [NSExpression expressionForKeyPath:@"type"];
    NSMutableArray *predicateArray = [NSMutableArray array];
    NSMenu *menu = [[outlineView headerView] menu];
    int i, iMax = [menu numberOfItems];
    BOOL shouldFilter = NO;
    
    for (i = 0; i < iMax; i++) {
        NSMenuItem *item = [menu itemAtIndex:i];
        if ([item state] == NSOnState) {
            NSString *type = [item representedObject];
            NSExpression *rhs = [NSExpression expressionForConstantValue:type];
            NSPredicate *predicate = [NSComparisonPredicate predicateWithLeftExpression:lhs rightExpression:rhs modifier:NSDirectPredicateModifier type:NSEqualToPredicateOperatorType options:0];
            [predicateArray addObject:predicate];
        } else {
            shouldFilter = YES;
        }
    }
    [arrayController setFilterPredicate:shouldFilter ? [NSCompoundPredicate orPredicateWithSubpredicates:predicateArray] : nil];
    [outlineView reloadData];
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
        return [[arrayController arrangedObjects] count];
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

- (void)outlineView:(NSOutlineView *)ov didClickTableColumn:(NSTableColumn *)tableColumn {
    NSTableColumn *oldTableColumn = [ov highlightedTableColumn];
    NSArray *sortDescriptors = nil;
    BOOL ascending = YES;
    if ([oldTableColumn isEqual:tableColumn]) {
        sortDescriptors = [[arrayController sortDescriptors] valueForKey:@"reversedSortDescriptor"];
        ascending = [[sortDescriptors lastObject] ascending];
    } else {
        NSString *tcID = [tableColumn identifier];
        NSSortDescriptor *pageIndexSortDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"pageIndex" ascending:ascending] autorelease];
        NSSortDescriptor *boundsSortDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"bounds" ascending:ascending selector:@selector(boundsCompare:)] autorelease];
        NSMutableArray *sds = [NSMutableArray arrayWithObjects:pageIndexSortDescriptor, boundsSortDescriptor, nil];
        if ([tcID isEqualToString:@"type"]) {
            [sds insertObject:[[[NSSortDescriptor alloc] initWithKey:@"noteType" ascending:YES] autorelease] atIndex:0];
        } else if ([tcID isEqualToString:@"note"]) {
            [sds insertObject:[[[NSSortDescriptor alloc] initWithKey:@"contents" ascending:YES selector:@selector(caseInsensitiveCompare:)] autorelease] atIndex:0];
        } else if ([tcID isEqualToString:@"page"]) {
            if (oldTableColumn == nil)
                ascending = NO;
        }
        sortDescriptors = sds;
        if (oldTableColumn)
            [ov setIndicatorImage:nil inTableColumn:oldTableColumn];
        [ov setHighlightedTableColumn:tableColumn]; 
    }
    [arrayController setSortDescriptors:sortDescriptors];
    [ov setIndicatorImage:[NSImage imageNamed:ascending ? @"NSAscendingSortIndicator" : @"NSDescendingSortIndicator"]
            inTableColumn:tableColumn];
    [ov reloadData];
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
