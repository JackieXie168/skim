//
//  BDSKSearchGroupSheetController.h
//  Bibdesk
//
//  Created by Adam Maxwell on 12/26/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "BDSKSheetController.h"

@class BDSKSearchGroup, BDSKServerInfo;

@interface BDSKSearchGroupSheetController : BDSKSheetController {
    BDSKSearchGroup *group;
    NSString *name;
    NSString *address;
    NSString *database;
    NSString *port;
    int type;
    NSUndoManager *undoManager;
    CFArrayRef editors;
    NSString *username;
    NSString *password;
    
    IBOutlet NSPopUpButton *serverPopup;
    IBOutlet NSMatrix *typeMatrix;
    
    IBOutlet NSTextField *nameField;
    IBOutlet NSTextField *addressField;
    IBOutlet NSTextField *portField;
    IBOutlet NSTextField *databaseField;
    IBOutlet NSSecureTextField *passwordField;
    IBOutlet NSTextField *userField;
}

+ (void)resetServers;
+ (void)saveServers;
+ (NSArray *)serversForType:(int)type;
+ (void)addServer:(BDSKServerInfo *)serverInfo forType:(int)type;
+ (void)setServer:(BDSKServerInfo *)serverInfo atIndex:(unsigned)index forType:(int)type;
+ (void)removeServerAtIndex:(unsigned)index forType:(int)type;

- (id)initWithGroup:(BDSKSearchGroup *)aGroup;

- (IBAction)selectPredefinedServer:(id)sender;
- (IBAction)addServer:(id)sender;
- (IBAction)removeServer:(id)sender;
- (IBAction)editServer:(id)sender;
- (IBAction)resetServers:(id)sender;

- (BOOL)canAddServer;
- (BOOL)canRemoveServer;
- (BOOL)canEditServer;

- (BDSKSearchGroup *)group;

- (int)type;
  - (void)setType:(int)newType;

- (NSString *)name;
- (void)setName:(NSString *)newName;

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
