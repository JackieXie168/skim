//
//  BDSKNoteTableDisplayController.h
//  bd2
//
//  Created by Michael McCracken on 7/13/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface BDSKNoteTableDisplayController : NSObject {
    id itemSource;
    NSArray *currentNotes;
    
    IBOutlet NSView *mainView;
}

- (id)initWithItemSource:(id)newItemSource; //@@ should be a protocol here?
- (NSView *)view;

- (NSString *)itemsKeyPath;
- (NSString *)selectionKeyPath;

- (id)itemSource;
- (void)setItemSource:(id)newItemSource;

- (NSArray *)currentNotes;
- (void)setCurrentNotes:(NSArray *)newCurrentNotes;

@end
