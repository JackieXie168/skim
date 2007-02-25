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
        
        NSError *error = nil;
        notes = [[[NSFileManager defaultManager] skimNotesFromExtendedAttributesAtPath:[url path] error:&error] retain];
        
        if (notes == nil)
            [NSApp presentError:error];
    }
    return self;
}

- (NSString *)windowNibName { return @"NotesWindow"; }

- (NSString *)windowTitleForDocumentDisplayName:(NSString *)displayName{
    return [NSString stringWithFormat:@"%@ - Notes", [[url path] lastPathComponent]];
}

- (NSString *)representedFilenameForWindow:(NSWindow *)aWindow {
    NSString *path = [url path];
    return path ? path : @"";
}

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

- (id)outlineView:(NSOutlineView *)outlineView child:(int)index ofItem:(id)item {
    if (item == nil)
        return [notes objectAtIndex:index];
    else
        return [NSDictionary dictionaryWithObjectsAndKeys:[item valueForKey:@"text"], @"contents", nil];
}

- (id)outlineView:(NSOutlineView *)ov objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item {
    NSString *tcID = [tableColumn identifier];
    if ([tcID isEqualToString:@"note"])
        return [item valueForKey:@"contents"];
    else if ([tcID isEqualToString:@"page"])
        return [NSString stringWithFormat:@"%i", [[item valueForKey:@"pageIndex"] intValue] + 1];
    return nil;
}

- (float)outlineView:(NSOutlineView *)outlineView heightOfRowByItem:(id)item {
    if ([item valueForKey:@"type"] == nil)
        return 85.0;
    return 17.0;
}

@end
