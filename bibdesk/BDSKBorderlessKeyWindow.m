//
//  BDSKBorderlessKeyWindow.m
//  Bibdesk
//
//  Created by Michael McCracken on 12/23/04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//
#import "BDSKBorderlessKeyWindow.h"

@implementation BDSKBorderlessKeyWindow
- (id)initWithContentRect:(NSRect)contentRect 
                styleMask:(unsigned int)aStyle
                  backing:(NSBackingStoreType)bufferingType 
                    defer:(BOOL)flag {
    
    if (self = [super initWithContentRect:contentRect
                                styleMask:NSBorderlessWindowMask
                                  backing:NSBackingStoreBuffered
                                    defer:flag]) {
		// we make the window transparent, the highlight is bigger than the textfield
		[self setBackgroundColor:[NSColor clearColor]];
		[self setOpaque:NO];
        return self;
    }
    
    return nil;
}
- (BOOL) canBecomeKeyWindow {
    return YES;
}
@end
