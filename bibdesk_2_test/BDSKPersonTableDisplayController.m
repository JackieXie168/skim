//
//  BDSKPersonTableDisplayController.m
//  bd2
//
//  Created by Michael McCracken on 7/13/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "BDSKPersonTableDisplayController.h"


@implementation BDSKPersonTableDisplayController

- (id)initWithItemSource:(id)newItemSource{
    self = [super init];
    if (self != nil) {
        [self setItemSource:newItemSource];
    }
    return self;
}

- (void)dealloc{
    [self unbind:@"currentPeople"];
    [currentPeople release];
    [super dealloc];
}

- (NSView *)view{
    if(!mainView){
        [NSBundle loadNibNamed:@"BDSKPersonTableDisplayController" owner:self];
    }
    return mainView;
}


- (NSString *)itemsKeyPath{
    return @"currentPeople";
}


- (NSString *)selectionKeyPath{
    return @"selection.people";
}


- (id)itemSource{ return itemSource; }

- (void)setItemSource:(id)newItemSource{
    itemSource = newItemSource; // don't retain - typically your itemSource retains you.  
}

- (NSArray *)currentPeople{
    return currentPeople;
}

- (void)setCurrentPeople:(NSArray *)newCurrentPeople{
    if (newCurrentPeople != currentPeople){
        [currentPeople autorelease];
        currentPeople = [newCurrentPeople retain];
    }
}

@end
