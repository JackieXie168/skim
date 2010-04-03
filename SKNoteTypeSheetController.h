//
//  SKNoteTypeSheetController.h
//  Skim
//
//  Created by Christiaan on 3/25/10.
//  Copyright 2010 Christiaan Hofman. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "SKWindowController.h"

@class SKNoteTypeSheetController;

@protocol SKNoteTypeSheetControllerDelegate <NSObject>
- (void)noteTypeSheetControllerNoteTypesDidChange:(SKNoteTypeSheetController *)controller;
- (NSWindow *)windowForNoteTypeSheetController:(SKNoteTypeSheetController *)controller;
@end


@interface SKNoteTypeSheetController : SKWindowController {
    IBOutlet NSMatrix *matrix;
    IBOutlet NSTextField *messageField;
    IBOutlet NSArray *buttons;
    NSMenu *noteTypeMenu;
    id <SKNoteTypeSheetControllerDelegate> delegate;
}

@property (nonatomic, assign) id <SKNoteTypeSheetControllerDelegate> delegate;
@property (nonatomic, readonly) NSArray *noteTypes;
@property (nonatomic, readonly) NSMenu *noteTypeMenu;

- (NSPredicate *)filterPredicateForSearchString:(NSString *)searchString caseInsensitive:(BOOL)caseInsensitive;

@end
