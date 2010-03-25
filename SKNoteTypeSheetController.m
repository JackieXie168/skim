//
//  SKNoteTypeSheetController.m
//  Skim
//
//  Created by Christiaan on 3/25/10.
//  Copyright 2010 Christiaan Hofman. All rights reserved.
//

#import "SKNoteTypeSheetController.h"
#import "NSWindowController_SKExtensions.h"
#import "NSGeometry_SKExtensions.h"
#import "NSString_SKExtensions.h"
#import "NSMenu_SKExtensions.h"
#import <SKimNotes/SkimNotes.h>

#define NUMBER_OF_TYPES 9

@implementation SKNoteTypeSheetController

- (void)dealloc {
    delegate = nil;
    SKDESTROY(noteTypeMenu);
    [super dealloc];
}

- (NSString *)windowNibName {
    return @"NoteTypeSheet";
}

- (void)windowDidLoad {
    NSMenu *menu = [self noteTypeMenu];
    NSInteger i;
    for (i = 0; i < NUMBER_OF_TYPES; i++)
        [[matrix cellWithTag:i] setTitle:[[menu itemAtIndex:i] title]];
    [matrix sizeToFit];
    
    [messageField sizeToFit];
    
    SKAutoSizeRightButtons(buttons);
    
    NSRect frame = [[self window] frame];
    NSRect matrixFrame = [matrix frame];
    NSRect messageFrame = [messageField frame];
    frame.size.width = fmax(NSWidth(matrixFrame) + 2.0 * NSMinX(matrixFrame), NSWidth(messageFrame) + 2.0 * NSMinX(messageFrame));
    [[self window] setFrame:frame display:NO];
}

- (void)noteTypesUpdated {
    [delegate noteTypeSheetControllerNoteTypesDidChange:self];
}

- (void)toggleDisplayNoteType:(id)sender {
    [sender setState:NO == [sender state]];
    [self noteTypesUpdated];
}

- (void)displayAllNoteTypes:(id)sender {
    NSInteger i;
    for (i = 0; i < NUMBER_OF_TYPES; i++)
        [[noteTypeMenu itemAtIndex:i] setState:NSOnState];
    [self noteTypesUpdated];
}

- (void)noteTypeSheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
    if (returnCode == NSOKButton) {
        NSInteger i;
        for (i = 0; i < NUMBER_OF_TYPES; i++)
            [[noteTypeMenu itemAtIndex:i] setState:[[matrix cellWithTag:i] state]];
        [self noteTypesUpdated];
    }
}

- (void)selectNoteTypes:(id)sender {
    [self window];
    
    NSInteger i;
    for (i = 0; i < NUMBER_OF_TYPES; i++)
        [[matrix cellWithTag:i] setState:[[noteTypeMenu itemAtIndex:i] state]];
	
    [self beginSheetModalForWindow:[delegate windowForNoteTypeSheetController:self]
        modalDelegate:self 
       didEndSelector:@selector(noteTypeSheetDidEnd:returnCode:contextInfo:)
          contextInfo:NULL];
}

- (NSMenu *)noteTypeMenu {
    if (noteTypeMenu == nil) {
        noteTypeMenu = [[NSMenu allocWithZone:[NSMenu menuZone]] init];
        NSMenuItem *menuItem = nil;
        menuItem = [noteTypeMenu addItemWithTitle:[SKNFreeTextString typeName] action:@selector(toggleDisplayNoteType:) target:self];
        [menuItem setRepresentedObject:SKNFreeTextString];
        [menuItem setState:NSOnState];
        menuItem = [noteTypeMenu addItemWithTitle:[SKNNoteString typeName] action:@selector(toggleDisplayNoteType:) target:self];
        [menuItem setState:NSOnState];
        [menuItem setRepresentedObject:SKNNoteString];
        menuItem = [noteTypeMenu addItemWithTitle:[SKNCircleString typeName] action:@selector(toggleDisplayNoteType:) target:self];
        [menuItem setRepresentedObject:SKNCircleString];
        [menuItem setState:NSOnState];
        menuItem = [noteTypeMenu addItemWithTitle:[SKNSquareString typeName] action:@selector(toggleDisplayNoteType:) target:self];
        [menuItem setRepresentedObject:SKNSquareString];
        [menuItem setState:NSOnState];
        menuItem = [noteTypeMenu addItemWithTitle:[SKNHighlightString typeName] action:@selector(toggleDisplayNoteType:) target:self];
        [menuItem setRepresentedObject:SKNHighlightString];
        [menuItem setState:NSOnState];
        menuItem = [noteTypeMenu addItemWithTitle:[SKNUnderlineString typeName] action:@selector(toggleDisplayNoteType:) target:self];
        [menuItem setRepresentedObject:SKNUnderlineString];
        [menuItem setState:NSOnState];
        menuItem = [noteTypeMenu addItemWithTitle:[SKNStrikeOutString typeName] action:@selector(toggleDisplayNoteType:) target:self];
        [menuItem setRepresentedObject:SKNStrikeOutString];
        [menuItem setState:NSOnState];
        menuItem = [noteTypeMenu addItemWithTitle:[SKNLineString typeName] action:@selector(toggleDisplayNoteType:) target:self];
        [menuItem setRepresentedObject:SKNLineString];
        [menuItem setState:NSOnState];
        menuItem = [noteTypeMenu addItemWithTitle:[SKNInkString typeName] action:@selector(toggleDisplayNoteType:) target:self];
        [menuItem setRepresentedObject:SKNInkString];
        [menuItem setState:NSOnState];
        [noteTypeMenu addItem:[NSMenuItem separatorItem]];
        menuItem = [noteTypeMenu addItemWithTitle:NSLocalizedString(@"Show All", @"noteTypeMenu item title") action:@selector(displayAllNoteTypes:) target:self];
        menuItem = [noteTypeMenu addItemWithTitle:[NSLocalizedString(@"Select", @"noteTypeMenu item title") stringByAppendingEllipsis] action:@selector(selectNoteTypes:) target:self];
    }
    
    return noteTypeMenu;
}

- (NSArray *)noteTypes {
    NSMutableArray *types = [NSMutableArray array];
    NSMenu *menu = [self noteTypeMenu];
    NSInteger i;
    
    for (i = 0; i < NUMBER_OF_TYPES; i++) {
        NSMenuItem *item = [menu itemAtIndex:i];
        if ([item state] == NSOnState)
            [types addObject:[item representedObject]];
    }
    return types;
}

- (id <SKNoteTypeSheetControllerDelegate>)delegate {
    return delegate;
}

- (void)setDelegate:(id <SKNoteTypeSheetControllerDelegate>)newDelegate {
    delegate = newDelegate;
}

@end
