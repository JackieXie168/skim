//
//  BDSKZoomGroupSheetController.h
//  Bibdesk
//
//  Created by Adam Maxwell on 12/26/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "BDSKSheetController.h"

@class BDSKZoomGroup;

@interface BDSKZoomGroupSheetController : BDSKSheetController {
    BDSKZoomGroup *group;
    NSString *host;
    int port;
    NSUndoManager *undoManager;
    CFArrayRef editors;
    
    IBOutlet NSComboBox *serverComboBox;
    IBOutlet NSPopUpButton *serverPopup;
    IBOutlet NSTextField *portTextField;
}

- (id)initWithGroup:(BDSKZoomGroup *)aGroup;
- (BDSKZoomGroup *)group;

- (IBAction)selectPredefinedServer:(id)sender;
- (IBAction)changeServer:(id)sender;
- (IBAction)changePort:(id)sender;

- (BOOL)commitEditing;
- (NSUndoManager *)undoManager;

@end
