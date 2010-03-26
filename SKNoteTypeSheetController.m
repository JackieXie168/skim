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

#define NOTETYPES_COUNT 9

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
    NSUInteger i;
    for (i = 0; i < NOTETYPES_COUNT; i++)
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
    NSUInteger i;
    for (i = 0; i < NOTETYPES_COUNT; i++) {
        NSMenuItem *item = [noteTypeMenu itemAtIndex:i];
        if ([item state] == NSOnState)
            [types addObject:[item representedObject]];
    }
    return types;
}

- (NSPredicate *)filterPredicateForSearchString:(NSString *)searchString caseInsensitive:(BOOL)caseInsensitive {
    NSPredicate *filterPredicate = nil;
    NSPredicate *typePredicate = nil;
    NSPredicate *searchPredicate = nil;
    NSArray *types = [self noteTypes];
    if ([types count] < NOTETYPES_COUNT) {
        NSExpression *lhs = [NSExpression expressionForKeyPath:@"type"];
        NSMutableArray *predicateArray = [NSMutableArray array];
        
        for (NSString *type in types) {
            NSExpression *rhs = [NSExpression expressionForConstantValue:type];
            NSPredicate *predicate = [NSComparisonPredicate predicateWithLeftExpression:lhs rightExpression:rhs modifier:NSDirectPredicateModifier type:NSEqualToPredicateOperatorType options:0];
            [predicateArray addObject:predicate];
        }
        typePredicate = [NSCompoundPredicate orPredicateWithSubpredicates:predicateArray];
    }
    if (searchString && [searchString isEqualToString:@""] == NO) {
        NSExpression *lhs = [NSExpression expressionForConstantValue:searchString];
        NSExpression *rhs = [NSExpression expressionForKeyPath:@"string"];
        NSUInteger options = NSDiacriticInsensitivePredicateOption;
        if (caseInsensitive)
            options |= NSCaseInsensitivePredicateOption;
        NSPredicate *stringPredicate = [NSComparisonPredicate predicateWithLeftExpression:lhs rightExpression:rhs modifier:NSDirectPredicateModifier type:NSInPredicateOperatorType options:options];
        rhs = [NSExpression expressionForKeyPath:@"text.string"];
        NSPredicate *textPredicate = [NSComparisonPredicate predicateWithLeftExpression:lhs rightExpression:rhs modifier:NSDirectPredicateModifier type:NSInPredicateOperatorType options:options];
        searchPredicate = [NSCompoundPredicate orPredicateWithSubpredicates:[NSArray arrayWithObjects:stringPredicate, textPredicate, nil]];
    }
    if (typePredicate) {
        if (searchPredicate)
            filterPredicate = [NSCompoundPredicate andPredicateWithSubpredicates:[NSArray arrayWithObjects:typePredicate, searchPredicate, nil]];
        else
            filterPredicate = typePredicate;
    } else if (searchPredicate) {
        filterPredicate = searchPredicate;
    }
    return filterPredicate;
}

- (void)noteTypesUpdated {
    [delegate noteTypeSheetControllerNoteTypesDidChange:self];
}

- (void)toggleDisplayNoteType:(id)sender {
    [sender setState:NO == [sender state]];
    [self noteTypesUpdated];
}

- (void)displayAllNoteTypes:(id)sender {
    NSUInteger i;
    for (i = 0; i < NOTETYPES_COUNT; i++)
        [[noteTypeMenu itemAtIndex:i] setState:NSOnState];
    [self noteTypesUpdated];
}

- (void)noteTypeSheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
    if (returnCode == NSOKButton) {
    NSUInteger i;
        for (i = 0; i < NOTETYPES_COUNT; i++)
            [[noteTypeMenu itemAtIndex:i] setState:[[matrix cellWithTag:i] state]];
        [self noteTypesUpdated];
    }
}

- (void)selectNoteTypes:(id)sender {
    [self window];
    
    NSUInteger i;
    for (i = 0; i < NOTETYPES_COUNT; i++)
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
