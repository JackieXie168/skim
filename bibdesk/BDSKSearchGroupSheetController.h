//
//  BDSKSearchGroupSheetController.h
//  Bibdesk
//
//  Created by Adam Maxwell on 12/26/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "BDSKSheetController.h"

@class BDSKGroup;

@interface BDSKSearchGroupSheetController : BDSKSheetController {
    BDSKGroup *group;
    NSString *address;
    NSString *database;
    int port;
    int type;
    NSUndoManager *undoManager;
    CFArrayRef editors;
    
    IBOutlet NSPopUpButton *serverPopup;
    IBOutlet NSTextField *addressField;
    IBOutlet NSTextField *portField;
    IBOutlet NSTextField *databaseField;
    IBOutlet NSMatrix *typematrix;
}

- (id)initWithGroup:(BDSKGroup *)aGroup;
- (BDSKGroup *)group;

- (NSString *)address;
- (void)setAddress:(NSString *)newAddress;

- (NSString *)database;
- (void)setDatabase:(NSString *)newDb;

- (int)port;
- (void)setPort:(int)newPort;

- (IBAction)selectPredefinedServer:(id)sender;

- (BOOL)commitEditing;
- (NSUndoManager *)undoManager;

@end
