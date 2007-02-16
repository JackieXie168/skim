//
//  SKFullScreenWindow.h
//  Skim
//
//  Created by Christiaan Hofman on 2/16/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface SKFullScreenWindow : NSWindow{
}

- (id)initWithScreen:(NSScreen *)screen;

- (NSView *)mainView;
- (void)setMainView:(NSView *)view;

@end
