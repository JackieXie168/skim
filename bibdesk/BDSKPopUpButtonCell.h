//
//  BDSKPopUpButtonCell.h
//  Bibdesk
//
//  Created by Sven-S. Porst on Tue Aug 03 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import <AppKit/AppKit.h>

#define BDSKPopUpDismissedNotification @"BDSKPopUpDismissedNotification"


/*
 Subclass that sends a notification when the popup menu is dismissed
 The relevant notification's object is the control containing this cell
*/

@interface BDSKPopUpButtonCell : NSPopUpButtonCell {

}

@end
