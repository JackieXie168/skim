//
//  BDSKTypeInfoEditor.h
//  Bibdesk
//
//  Created by Christiaan Hofman on 5/4/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface BDSKTypeInfoEditor : NSWindowController {
	IBOutlet NSTableView *typeTableView;
	IBOutlet NSTableView *requiredTableView;
	IBOutlet NSTableView *optionalTableView;
	IBOutlet NSButton *addTypeButton;
	IBOutlet NSButton *removeTypeButton;
	IBOutlet NSButton *addRequiredButton;
	IBOutlet NSButton *removeRequiredButton;
	IBOutlet NSButton *addOptionalButton;
	IBOutlet NSButton *removeOptionalButton;
	IBOutlet NSButton *revertCurrentToDefaultButton;
	IBOutlet NSButton *revertAllToDefaultButton;
	NSMutableDictionary *fieldsForTypesDict;
	NSMutableArray *types;
	NSDictionary *defaultFieldsForTypesDict;
	NSArray *defaultTypes;
	NSMutableArray *currentRequiredFields;
	NSMutableArray *currentOptionalFields;
	NSArray *currentDefaultRequiredFields;
	NSArray *currentDefaultOptionalFields;
	NSString *currentType;
}

+ (BDSKTypeInfoEditor *)sharedTypeInfoEditor;

- (void)revertTypes;

- (void)addType:(NSString *)newType withFields:(NSDictionary *)fieldsDict;
- (void)setCurrentType:(NSString *)newCurrentType;

- (IBAction)cancel:(id)sender;
- (IBAction)saveChanges:(id)sender;
- (IBAction)addType:(id)sender;
- (IBAction)removeType:(id)sender;
- (IBAction)addRequired:(id)sender;
- (IBAction)removeRequired:(id)sender;
- (IBAction)addOptional:(id)sender;
- (IBAction)removeOptional:(id)sender;
- (IBAction)revertCurrentToDefault:(id)sender;
- (IBAction)revertAllToDefault:(id)sender;

- (BOOL)canEditType:(NSString *)type;
- (BOOL)canEditField:(NSString *)field;
- (void)updateButtons;

@end
