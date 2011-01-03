//
//  SKNoteTypeSheetController.m
//  Skim
//
//  Created by Christiaan Hofman on 3/25/10.
/*
 This software is Copyright (c) 2010-2011
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

@synthesize matrix, messageField, buttons, delegate, noteTypeMenu;
@dynamic noteTypes;

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
    SKDESTROY(matrix);
    SKDESTROY(messageField);
    SKDESTROY(buttons);
    [super dealloc];
}

- (void)windowDidLoad {
    NSUInteger i;
    for (i = 0; i < NOTETYPES_COUNT; i++)
        [[matrix cellWithTag:i] setTitle:[[noteTypeMenu itemAtIndex:i] title]];
    [matrix sizeToFit];
    
    [messageField sizeToFit];
    
    SKAutoSizeButtons(buttons, YES);
    
    NSRect frame = [[self window] frame];
    NSRect matrixFrame = [matrix frame];
    NSRect messageFrame = [messageField frame];
    frame.size.width = fmax(NSWidth(matrixFrame) + 2.0 * NSMinX(matrixFrame), NSWidth(messageFrame) + 2.0 * NSMinX(messageFrame));
    [[self window] setFrame:frame display:NO];
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

- (void)toggleDisplayNoteType:(id)sender {
    [sender setState:NO == [sender state]];
    [delegate noteTypeSheetControllerNoteTypesDidChange:self];
}

- (void)displayAllNoteTypes:(id)sender {
    NSUInteger i;
    for (i = 0; i < NOTETYPES_COUNT; i++)
        [[noteTypeMenu itemAtIndex:i] setState:NSOnState];
    [delegate noteTypeSheetControllerNoteTypesDidChange:self];
}

- (void)noteTypeSheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
    if (returnCode == NSOKButton) {
        NSUInteger i;
        for (i = 0; i < NOTETYPES_COUNT; i++)
            [[noteTypeMenu itemAtIndex:i] setState:[[matrix cellWithTag:i] state]];
        [delegate noteTypeSheetControllerNoteTypesDidChange:self];
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

@end
