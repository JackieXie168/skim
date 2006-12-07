//
//  BDSKPublicationTableDisplayController.m
//  bd2
//
//  Created by Michael McCracken on 6/21/05.
//  Copyright 2005 Michael McCracken. All rights reserved.
//

#import "BDSKPublicationTableDisplayController.h"


@implementation BDSKPublicationTableDisplayController

- (id)initWithItemSource:(id)newItemSource{
    self = [super init];
    if (self != nil) {
        [self setItemSource:newItemSource];
    }
    return self;
}

- (void)dealloc{
    [self unbind:@"currentPublications"];
    [currentPublications release];
    [super dealloc];
}

- (NSView *)view{
    if(!mainView){
        [NSBundle loadNibNamed:@"BDSKPublicationTableDisplayController" owner:self];
    }
    return mainView;
}

- (NSString *)itemsKeyPath{
    return @"currentPublications";
}

- (NSString *)selectionKeyPath{
    return @"selection.publicationsInSelfOrChildren";
}

- (id)itemSource{ return itemSource; }

- (void)setItemSource:(id)newItemSource{
    itemSource = newItemSource; // don't retain - typically your itemSource retains you.  
}

- (NSArray *)currentPublications{
    return currentPublications;
}

- (void)setCurrentPublications:(NSArray *)newCurrentPublications{
    if (newCurrentPublications != currentPublications){
        [currentPublications autorelease];
        currentPublications = [newCurrentPublications retain];
    }
}


@end
