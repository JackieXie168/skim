//
//  BDSKNoteTableDisplayController.m
//  bd2
//
//  Created by Michael McCracken on 7/13/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "BDSKNoteTableDisplayController.h"


@implementation BDSKNoteTableDisplayController

- (id)initWithItemSource:(id)newItemSource{
    self = [super init];
    if (self != nil) {
        [self setItemSource:newItemSource];
    }
    return self;
}

- (void)dealloc{
    [self unbind:@"currentNotes"];
    [currentNotes release];
    [super dealloc];
}

- (NSView *)view{
    if(!mainView){
        [NSBundle loadNibNamed:@"BDSKNoteTableDisplayController" owner:self];
    }
    return mainView;
}


- (NSString *)itemsKeyPath{
    return @"currentNotes";
}


- (NSString *)selectionKeyPath{
    return @"selection.notes";
}


- (id)itemSource{ return itemSource; }

- (void)setItemSource:(id)newItemSource{
    itemSource = newItemSource; // don't retain - typically your itemSource retains you.  
}

- (NSArray *)currentNotes{
    return currentNotes;
}

- (void)setCurrentNotes:(NSArray *)newCurrentNotes{
    if (newCurrentNotes != currentNotes){
        [currentNotes autorelease];
        currentNotes = [newCurrentNotes retain];
    }
}

@end
