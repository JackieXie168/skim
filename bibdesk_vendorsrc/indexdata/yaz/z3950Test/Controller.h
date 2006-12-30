//
//  Controller.h
//  z3950Test
//
//  Created by Adam Maxwell on 12/25/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <yaz/BDSKZoom.h>

@class BDSKZoomConnection;

@interface Controller : NSObject {
    IBOutlet NSSearchField *_searchField;
    IBOutlet NSTextView *_textView;
    IBOutlet NSPopUpButton *_popup;
    
    NSString *_hostname;
    NSString *_database;
    int _port;
    BDSKZoomSyntaxType _syntaxType;
    
    IBOutlet NSTextField *_addressField;
    IBOutlet NSTextField *_dbaseField;
    IBOutlet NSTextField *_portField;
    IBOutlet NSPopUpButton *_syntaxPopup;
    
    ZOOM_connection connection;
    BDSKZoomConnection *_connection;
    NSString *_currentType;
    
    BOOL _connectionNeedsReset;
}

- (IBAction)search:(id)sender;
- (IBAction)changeType:(id)sender;
- (IBAction)changeAddress:(id)sender;
- (IBAction)changePort:(id)sender;
- (IBAction)changeDbase:(id)sender;
- (IBAction)changeSyntaxType:(id)sender;

@end
