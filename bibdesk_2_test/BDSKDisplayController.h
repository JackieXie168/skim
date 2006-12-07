//
//  BDSKDisplayController.h
//  bd2xtest
//
//  Created by Christiaan Hofman on 1/29/06.
//  Copyright 2006. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ImageBackgroundBox.h"


@interface BDSKDisplayController : NSWindowController {
    IBOutlet NSView *mainView;
    NSDocument *document;
    NSString *itemEntityName;
}

- (NSView *)view;

- (NSDocument *)document;
- (void)setDocument:(NSDocument *)newDocument;

- (NSManagedObjectContext *)managedObjectContext;

- (NSString *)itemEntityName;
- (void)setItemEntityName:(NSString *)entityName;

- (void)updateUI;

- (BOOL)canAddRelationshipsFromPasteboardType:(NSString *)type parent:(NSManagedObject *)parent;
- (BOOL)addRelationshipsFromPasteboard:(NSPasteboard *)pboard forType:(NSString *)type parent:(NSManagedObject *)parent keyPath:(NSString *)keyPath;

@end


@interface BDSKItemDisplayController : BDSKDisplayController {
    IBOutlet NSObjectController *itemObjectController;
}

- (NSObjectController *)itemObjectController;

- (BOOL)addRelationshipsFromPasteboard:(NSPasteboard *)pboard forType:(NSString *)type keyPath:(NSString *)keyPath;

@end
