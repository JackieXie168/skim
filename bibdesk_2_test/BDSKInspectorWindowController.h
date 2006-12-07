//
//  BDSKInspectorWindowController.h
//  bd2xtest
//
//  Created by Christiaan Hofman on 2/5/06.
//  Copyright 2006. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface BDSKInspectorWindowController : NSWindowController {
    IBOutlet NSArrayController *itemsArrayController;
    NSWindowController *observedWindowController;
}

+ (id)sharedController;

- (NSString *)windowNibName;
- (NSString *)windowTitle;

- (void)setMainWindow:(NSWindow *)mainWindow;
- (NSWindowController *)observedWindowController;
- (void)setObservedWindowController:(NSWindowController *)controller;

@end


@interface BDSKNoteWindowController : BDSKInspectorWindowController {} 

- (void)removeNotes:(NSArray *)selectedNotes;

@end


@interface BDSKTagWindowController : BDSKInspectorWindowController {} 

- (void)selectItem:(NSArray *)selectedItems;

@end
