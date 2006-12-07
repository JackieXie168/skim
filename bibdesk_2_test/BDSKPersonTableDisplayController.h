//
//  BDSKPersonTableDisplayController.h
//  bd2
//
//  Created by Michael McCracken on 7/15/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface BDSKPersonTableDisplayController : NSObject {
    id itemSource;
    NSArray *currentPeople;
    
    IBOutlet NSView *mainView;
}

- (id)initWithItemSource:(id)newItemSource; //@@ should be a protocol here?
- (NSView *)view;

- (NSString *)itemsKeyPath;
- (NSString *)selectionKeyPath;

- (id)itemSource;
- (void)setItemSource:(id)newItemSource;

- (NSArray *)currentPeople;
- (void)setCurrentPeople:(NSArray *)newCurrentPeople;

@end
