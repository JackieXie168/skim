//
//  BDSKMenuItem.m
//  Bibdesk
//
//  Created by Christiaan Hofman on 2/4/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "BDSKMenuItem.h"


@implementation BDSKMenuItem

- (id)delegate {
    return [[delegate retain] autorelease];
}

- (void)setDelegate:(id)newDelegate {
    if (delegate != newDelegate) {
        delegate = newDelegate;
    }
}

- (BOOL)hasSubmenu {
	if (delegate && [delegate respondsToSelector:@selector(submenuForMenuItem:)]) {
		return YES;
	}
	return [super hasSubmenu];
}

- (NSMenu *)submenu {
	if (delegate && [delegate respondsToSelector:@selector(submenuForMenuItem:)]) {
		return [delegate submenuForMenuItem:self];
	}
	return [super submenu];
}

@end
