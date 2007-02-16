//
//  SKInfoWindowController.h
//  Skim
//
//  Created by Christiaan Hofman on 12/17/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class SKDocument;

@interface SKInfoWindowController : NSWindowController {
    NSMutableDictionary *info;
}

+ (id)sharedInstance;

- (NSDictionary *)info;
- (void)setInfo:(NSDictionary *)newInfo;

- (void)fillInfoForDocument:(SKDocument *)doc;

- (void)handleWindowDidBecomeKeyNotification:(NSNotification *)notification;
- (void)handleWindowDidResignKeyNotification:(NSNotification *)notification;

@end
