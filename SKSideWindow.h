//
//  SKSideWindow.h
//  Skim
//
//  Created by Christiaan Hofman on 2/8/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@class SKMainWindowController;

@interface SKSideWindow : NSWindow {
    SKMainWindowController *controller;
    NSAnimation *animation;
    NSDrawerState state;
    NSRectEdge edge;
}
- (id)initWithMainController:(SKMainWindowController *)aController;
- (id)initWithMainController:(SKMainWindowController *)aController edge:(NSRectEdge)anEdge;
- (void)moveToScreen:(NSScreen *)screen;
- (void)slideIn;
- (void)slideOut;
- (NSView *)mainView;
- (void)setMainView:(NSView *)newContentView;
- (NSRectEdge)edge;
- (int)state;
@end


@interface SKSideWindowContentView : NSView {
    NSTrackingRectTag trackingRect;
}
- (void)trackMouseOvers;
@end
