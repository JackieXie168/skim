//
//  BDSKInspectorWindowController.m
//  bd2xtest
//
//  Created by Christiaan Hofman on 2/5/06.
//  Copyright 2006. All rights reserved.
//

#import "BDSKInspectorWindowController.h"
#import "BDSKSecondaryWindowController.h"


@implementation BDSKInspectorWindowController

+ (id)sharedController {
    static NSMutableDictionary *sharedControllers = nil;
    if (sharedControllers == nil) {
        sharedControllers = [[NSMutableDictionary alloc] initWithCapacity:2];
    }
    NSString *className = NSStringFromClass([self class]);
    id sharedController = [sharedControllers objectForKey:className];
    if (sharedController == nil) {
        sharedController = [[[self class] alloc] init];
        [sharedControllers setObject:sharedController forKey:className];
        [sharedController release];
    }
    return sharedController;
}

- (id)init {
    self = [self initWithWindowNibName:[self windowNibName]];
    if (self) {
        observedWindowController = nil;
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self setMainWindow:nil];
    [super dealloc];
}

- (NSString *)windowNibName {
    // should be implemented by concrete subclass
    return [super windowNibName];
}

- (NSString *)windowTitle {
    // should be implemented by concrete subclass
    return nil;
}

- (NSString *)keyPathForBinding {
    // should be implemented by concrete subclass
    return nil;
}

- (BOOL)deletesObjectsOnRemove {
    // should be implemented by concrete subclass
    return NO;
}

- (void)windowDidLoad {
    [super windowDidLoad];
    [[self window] setTitle:[self windowTitle]];
    [self setMainWindow:[NSApp mainWindow]];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mainWindowChanged:) name:NSWindowDidBecomeMainNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mainWindowResigned:) name:NSWindowDidResignMainNotification object:nil];
}

- (void)mainWindowChanged:(NSNotification *)notification {
    [self setMainWindow:[notification object]];
}

- (void)mainWindowResigned:(NSNotification *)notification {
    [self setMainWindow:nil];
}

- (NSWindowController *)observedWindowController {
    return observedWindowController;
}

- (void)setObservedWindowController:(NSWindowController *)controller {
    if (controller != observedWindowController) {
        [observedWindowController release];
        observedWindowController = [controller retain];
    }
}

- (void)setMainWindow:(NSWindow *)mainWindow {
    NSWindowController *controller = [mainWindow windowController];

    if ([controller isKindOfClass:[BDSKSecondaryWindowController class]] == NO) 
        controller = nil;
    [self setObservedWindowController:controller];
}

@end


@implementation BDSKNoteWindowController

- (NSString *)windowNibName { return @"BDSKNoteWindow"; }

- (NSString *)windowTitle { return NSLocalizedString(@"Notes", @"Notes window title"); }

- (void)removeNotes:(NSArray *)selectedItems {
    [itemsArrayController removeObjects:selectedItems];
    // dirty fix for CoreData bug, which registers an extra change when objects are deleted
    [[observedWindowController document] updateChangeCount:NSChangeUndone];
}

@end


@implementation BDSKTagWindowController

- (NSString *)windowNibName { return @"BDSKTagWindow"; }

- (NSString *)windowTitle { return NSLocalizedString(@"Tags", @"Tags window title"); }

- (void)selectItem:(NSArray *)selectedItems {
    id item = [selectedItems lastObject];
    NSString *entityName = [[item entity] name];
    
    if (observedWindowController == nil || item == nil || 
        [[[(BDSKSecondaryWindowController *)observedWindowController sourceGroup] valueForKey:@"itemEntityName"] isEqualToString:entityName] == NO) 
        return;
        
    NSArrayController *arrayController = [observedWindowController valueForKeyPath:@"displayController.itemsArrayController"];
    [arrayController setSelectedObjects:selectedItems];
}

@end
