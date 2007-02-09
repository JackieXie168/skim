//
//  SKSideWindow.h
//  Skim
//
//  Created by Christiaan Hofman on 8/2/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@class SKMainWindowController;

@interface SKSideWindow : NSWindow {
    SKMainWindowController *controller;
    NSAnimation *animation;
}
- (id)initWithMainController:(SKMainWindowController *)aController;
- (void)moveToScreen:(NSScreen *)screen;
- (void)slideIn;
- (void)slideOut;
- (NSView *)mainView;
- (void)setMainView:(NSView *)newContentView;
@end


@interface SKSideWindowContentView : NSView {
    NSTrackingRectTag trackingRect;
}
- (void)trackMouseOvers;
@end
