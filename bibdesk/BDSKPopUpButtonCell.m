//
//  BDSKPopUpButtonCell.m
//  Bibdesk
//
//  Created by Sven-S. Porst on Tue Aug 03 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "BDSKPopUpButtonCell.h"


@implementation BDSKPopUpButtonCell : NSPopUpButtonCell
- (void) dismissPopUp {
	[[NSNotificationCenter defaultCenter] postNotificationName:BDSKPopUpDismissedNotification object:[self controlView]];
	[super dismissPopUp];
}

@end
