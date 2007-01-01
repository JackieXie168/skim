//
//  BDSKSearchGroupSheetController.h
//  Bibdesk
//
//  Created by Adam Maxwell on 12/26/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "BDSKSheetController.h"

@class BDSKSearchGroup, BDSKServerInfo, BDSKCollapsibleView;

@interface BDSKSearchGroupSheetController : BDSKSheetController {
    BDSKSearchGroup *group;
    NSUndoManager *undoManager;
    CFArrayRef editors;
    BDSKServerInfo *serverInfo;
    NSString *type;
    
    BOOL isExpanded;
    
    IBOutlet NSPopUpButton *serverPopup;
    IBOutlet NSMatrix *typeMatrix;
    
    IBOutlet NSTextField *nameField;
    IBOutlet NSTextField *addressField;
    IBOutlet NSTextField *portField;
    IBOutlet NSTextField *databaseField;
    IBOutlet NSSecureTextField *passwordField;
    IBOutlet NSTextField *userField;
    IBOutlet NSPopUpButton *syntaxPopup;
    IBOutlet NSComboBox *encodingComboBox;
    IBOutlet NSButton *removeDiacriticsButton;
    
    IBOutlet NSButton *editButton;
    
    IBOutlet BDSKCollapsibleView *serverView;
    IBOutlet NSButton *revealButton;
}

+ (void)resetServers;
+ (void)saveServers;
+ (NSArray *)serversForType:(NSString *)type;
+ (void)addServer:(BDSKServerInfo *)info forType:(NSString *)type;
+ (void)setServer:(BDSKServerInfo *)info atIndex:(unsigned)index forType:(NSString *)type;
+ (void)removeServerAtIndex:(unsigned)index forType:(NSString *)type;

- (id)initWithGroup:(BDSKSearchGroup *)aGroup;

- (IBAction)selectServerType:(id)sender;
- (IBAction)selectPredefinedServer:(id)sender;
- (IBAction)selectSyntax:(id)sender;

- (IBAction)addServer:(id)sender;
- (IBAction)removeServer:(id)sender;
- (IBAction)editServer:(id)sender;
- (IBAction)resetServers:(id)sender;

- (IBAction)expand:(id)sender;
- (IBAction)collapse:(id)sender;
- (IBAction)toggle:(id)sender;

- (BOOL)canAddServer;
- (BOOL)canRemoveServer;
- (BOOL)canEditServer;

- (void)setType:(NSString *)t;
- (NSString *)type;
- (void)setServerInfo:(BDSKServerInfo *)info;

- (BDSKSearchGroup *)group;
- (IBAction)selectPredefinedServer:(id)sender;

- (BOOL)commitEditing;
- (NSUndoManager *)undoManager;

@end
