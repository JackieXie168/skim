//
//  BDSKMenuItem.h
//  Bibdesk
//
//  Created by Christiaan Hofman on 2/4/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface BDSKMenuItem : NSMenuItem {
	id delegate;
}

- (id)delegate;
- (void)setDelegate:(id)newDelegate;

@end

@interface NSObject (BDSKMenuItemDelegate)

- (NSMenu *)submenuForMenuItem:(NSMenuItem *)menuItem;

@end