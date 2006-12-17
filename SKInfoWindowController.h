//
//  SKInfoWindowController.h
//  Skim
//
//  Created by Christiaan Hofman on 17/12/06.
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

@end
