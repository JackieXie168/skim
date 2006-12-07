//
//  BDSKConditionController.h
//  Bibdesk
//
//  Created by Christiaan Hofman on 17/3/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "BDSKCondition.h"
#import "BDSKFilterItem.h"

@class BDSKFilterController;


@interface BDSKConditionController : NSObject {
	IBOutlet NSPopUpButton *itemTypePopUp;
	IBOutlet NSPopUpButton *keyPopUp;
	IBOutlet NSPopUpButton *comparisonPopUp;
	IBOutlet NSTextField *valueTextField;
	IBOutlet NSView *view;
	IBOutlet NSButton *addButton;
	IBOutlet NSButton *removeButton;
	IBOutlet NSObjectController *ownerController;
	IBOutlet NSWindow *addKeySheet;
	IBOutlet NSTextField *newKeyField;
	BDSKFilterController *filterController;
	BDSKCondition *condition;
	NSMutableArray *keys;
	BOOL canRemove;
}

- (id)initWithFilterController:(BDSKFilterController *)aFilterController;
- (id)initWithFilterController:(BDSKFilterController *)aFilterController condition:(BDSKCondition *)aCondition;
- (NSView *)view;
- (NSMenu *)keyMenu;
- (void)updateKeyMenu;
- (void)updateKeys;
- (IBAction)changeKey:(id)sender;
- (IBAction)addCondition:(id)sender;
- (IBAction)removeCondition:(id)sender;
- (BDSKCondition *)condition;
- (BOOL)canRemove;
- (void)setCanRemove:(BOOL)flag;
- (NSArray *)keys;
- (void)setKeys:(NSArray *)newKeys;
- (void)addKey:(NSString *)newKey;
- (IBAction)addNewKey:(id)sender;
- (IBAction)dismissAddKeySheet:(id)sender;
- (void)addKeySheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo;

@end
