//
//  SKNoteTypeSheetController.h
//  Skim
//
//  Created by Christiaan on 3/25/10.
//  Copyright 2010 Christiaan Hofman. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "SKWindowController.h"

@protocol SKNoteTypeSheetControllerDelegate;

@interface SKNoteTypeSheetController : SKWindowController {
    NSMatrix *matrix;
    NSTextField *messageField;
    NSArray *buttons;
    NSMenu *noteTypeMenu;
    id <SKNoteTypeSheetControllerDelegate> delegate;
}

@property (nonatomic, assign) IBOutlet NSMatrix *matrix;
@property (nonatomic, assign) IBOutlet NSTextField *messageField;
@property (nonatomic, assign) IBOutlet NSArray *buttons;
@property (nonatomic, assign) id <SKNoteTypeSheetControllerDelegate> delegate;
@property (nonatomic, readonly) NSArray *noteTypes;
@property (nonatomic, readonly) NSMenu *noteTypeMenu;

- (NSPredicate *)filterPredicateForSearchString:(NSString *)searchString caseInsensitive:(BOOL)caseInsensitive;

@end


@protocol SKNoteTypeSheetControllerDelegate <NSObject>
- (void)noteTypeSheetControllerNoteTypesDidChange:(SKNoteTypeSheetController *)controller;
- (NSWindow *)windowForNoteTypeSheetController:(SKNoteTypeSheetController *)controller;
@end
