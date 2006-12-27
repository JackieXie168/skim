//
//  Controller.h
//  z3950Test
//
//  Created by Adam Maxwell on 12/25/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <yaz/zoom.h>

@class BDSKZoomConnection;

@interface Controller : NSObject {
    IBOutlet NSSearchField *_searchField;
    IBOutlet NSTextView *_textView;
    IBOutlet NSPopUpButton *_popup;
    
    ZOOM_connection connection;
    BDSKZoomConnection *_connection;
    NSString *_currentType;
}

- (IBAction)search:(id)sender;
- (IBAction)changeType:(id)sender;

@end
