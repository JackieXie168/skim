//
//  BDSKCharacterConversion.h
//  Bibdesk
//
//  Created by Christiaan Hofman on 5/4/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface BDSKCharacterConversion : NSWindowController {
	IBOutlet NSPopUpButton *listButton;
	IBOutlet NSTableView *tableView;
	IBOutlet NSButton *addButton;
	IBOutlet NSButton *removeButton;
	NSMutableDictionary *oneWayDict;
	NSMutableDictionary *twoWayDict;
	NSMutableDictionary *currentDict;
	NSMutableArray *currentArray;
	NSFormatter *texFormatter;
}

+ (BDSKCharacterConversion *)sharedConversionEditor;

- (IBAction)saveChanges:(id)sender;
- (IBAction)cancel:(id)sender;
- (IBAction)changeList:(id)sender;
- (IBAction)add:(id)sender;
- (IBAction)remove:(id)sender;

- (int)listType;
- (void)setListType:(int)newListType;
- (NSDictionary *)oneWayDict;
- (void)setOneWayDict:(NSDictionary *)newOneWayDict;
- (NSDictionary *)twoWayDict;
- (void)setTwoWayDict:(NSDictionary *)newTwoWayDict;

- (void)updateButtons;

@end


@interface BDSKRomanCharacterFormatter : NSFormatter {
}
@end


@interface BDSKTeXFormatter : NSFormatter {
}
@end
