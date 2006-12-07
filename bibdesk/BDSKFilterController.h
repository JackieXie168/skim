//
//  BDSKFilterController.h
//  Bibdesk
//
//  Created by Christiaan Hofman on 17/3/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <OmniAppKit/OmniAppKit.h>
#import "BDSKFilter.h"
#import "BDSKConditionController.h"
#import "BDSKFilterItem.h"


@interface BDSKFilterController : NSWindowController {
	IBOutlet NSButton *enabledCheckButton;
	IBOutlet NSPopUpButton *conjunctionPopUp;
	IBOutlet OAStackView *stackView;
	IBOutlet NSTextField *messageTextField;
	IBOutlet NSObjectController *ownerController;
	NSMutableArray *conditionControllers;
	BDSKFilter *filter;
	BDSKConjunction conjunction;
	BOOL enabled;
}

- (id)initWithFilter:(BDSKFilter *)aFilter;
- (void)updateUI;
- (IBAction)set:(id)sender;
- (IBAction)cancel:(id)sender;
- (void)insertNewConditionAfter:(BDSKConditionController *)aConditionController;
- (void)removeConditionController:(BDSKConditionController *)aConditionController;
- (BOOL)canRemoveCondition;
- (NSArray *)conditionControllers;
- (void)setConditionControllers:(NSArray *)newConditionControllers;
- (BOOL)enabled;
- (void)setEnabled:(BOOL)newEnabled;
- (BDSKConjunction)conjunction;
- (void)setConjunction:(BDSKConjunction)newConjunction;
- (NSArray *)subviewsForStackView:(OAStackView *)aStackView;

@end
