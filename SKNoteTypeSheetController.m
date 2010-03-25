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

@interface SKNoteTypeSheetController (Private)
- (void)toggleDisplayNoteType:(id)sender;
- (void)displayAllNoteTypes:(id)sender;
- (void)selectNoteTypes:(id)sender;
@end

@implementation SKNoteTypeSheetController

- (id)init {
    if (self = [super initWithWindowNibName:@"NoteTypeSheet"]) {
        noteTypeMenu = [[NSMenu allocWithZone:[NSMenu menuZone]] init];
        NSArray *noteTypes = [NSArray arrayWithObjects:SKNFreeTextString, SKNNoteString, SKNCircleString, SKNSquareString, SKNHighlightString, SKNUnderlineString, SKNStrikeOutString, SKNLineString, SKNInkString, nil];
        NSMenuItem *menuItem;
        for (NSString *type in noteTypes) {
            menuItem = [noteTypeMenu addItemWithTitle:[type typeName] action:@selector(toggleDisplayNoteType:) target:self];
            [menuItem setRepresentedObject:type];
            [menuItem setState:NSOnState];
        }
        [noteTypeMenu addItem:[NSMenuItem separatorItem]];
        menuItem = [noteTypeMenu addItemWithTitle:NSLocalizedString(@"Show All", @"Menu item title") action:@selector(displayAllNoteTypes:) target:self];
        menuItem = [noteTypeMenu addItemWithTitle:[NSLocalizedString(@"Select", @"Menu item title") stringByAppendingEllipsis] action:@selector(selectNoteTypes:) target:self];
    }
    return self;
}

- (void)dealloc {
    delegate = nil;
    SKDESTROY(noteTypeMenu);
    [super dealloc];
}

- (void)windowDidLoad {
    NSInteger i;
    for (i = 0; i < NUMBER_OF_TYPES; i++)
        [[matrix cellWithTag:i] setTitle:[[noteTypeMenu itemAtIndex:i] title]];
    [matrix sizeToFit];
    
    [messageField sizeToFit];
    
    SKAutoSizeRightButtons(buttons);
    
    NSRect frame = [[self window] frame];
    NSRect matrixFrame = [matrix frame];
    NSRect messageFrame = [messageField frame];
    frame.size.width = fmax(NSWidth(matrixFrame) + 2.0 * NSMinX(matrixFrame), NSWidth(messageFrame) + 2.0 * NSMinX(messageFrame));
    [[self window] setFrame:frame display:NO];
}

- (NSMenu *)noteTypeMenu {
    return noteTypeMenu;
}

- (NSArray *)noteTypes {
    NSMutableArray *types = [NSMutableArray array];
    NSInteger i;
    
    for (i = 0; i < NUMBER_OF_TYPES; i++) {
        NSMenuItem *item = [noteTypeMenu itemAtIndex:i];
        if ([item state] == NSOnState)
            [types addObject:[item representedObject]];
    }
    return types;
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

- (id <SKNoteTypeSheetControllerDelegate>)delegate {
    return delegate;
}

- (void)setDelegate:(id <SKNoteTypeSheetControllerDelegate>)newDelegate {
    delegate = newDelegate;
}

@end
