//
//  BDSKPublicationTableDisplayController.h
//  bd2
//
//  Created by Michael McCracken on 6/21/05.
//  Copyright 2005 Michael McCracken. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface BDSKPublicationTableDisplayController : NSObject {
    id itemSource;
    NSArray *currentPublications;
    
    IBOutlet NSView *mainView;
}

- (id)initWithItemSource:(id)newItemSource; //@@ should be a protocol here?
- (NSView *)view;

- (NSString *)itemsKeyPath;
- (NSString *)selectionKeyPath;


- (id)itemSource;
- (void)setItemSource:(id)newItemSource;

- (NSArray *)currentPublications;
- (void)setCurrentPublications:(NSArray *)newCurrentPublications;

@end
