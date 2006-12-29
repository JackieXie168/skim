//
//  BDSKSearchGroupSheetController.h
//  Bibdesk
//
//  Created by Adam Maxwell on 12/26/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "BDSKSheetController.h"

@class BDSKSearchGroup;

@interface BDSKSearchGroupSheetController : BDSKSheetController {
    BDSKSearchGroup *group;
    NSString *address;
    NSString *database;
    NSString *port;
    int type;
    NSUndoManager *undoManager;
    CFArrayRef editors;
    NSString *username;
    NSString *password;
    
    IBOutlet NSPopUpButton *serverPopup;
    IBOutlet NSTextField *addressField;
    IBOutlet NSTextField *portField;
    IBOutlet NSTextField *databaseField;
    IBOutlet NSMatrix *typematrix;
    
    IBOutlet NSSecureTextField *passwordField;
    IBOutlet NSTextField *userField;
}

- (id)initWithGroup:(BDSKSearchGroup *)aGroup;

- (BDSKSearchGroup *)group;

- (NSString *)address;
- (void)setAddress:(NSString *)newAddress;

- (NSString *)database;
- (void)setDatabase:(NSString *)newDb;

- (NSString *)port;
- (void)setPort:(NSString *)newPort;

- (NSString *)username;
- (void)setUsername:(NSString *)user;

- (NSString *)password;
- (void)setPassword:(NSString *)pw;

- (IBAction)selectPredefinedServer:(id)sender;

- (BOOL)commitEditing;
- (NSUndoManager *)undoManager;

@end
