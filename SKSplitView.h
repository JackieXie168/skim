//
//  SKSplitView.h
//  Skim
//
//  Created by Christiaan Hofman on 10/2/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class CIColor;

@interface SKSplitView : NSSplitView
+ (CIColor *)startColor;
+ (CIColor *)endColor;
@end

@interface NSObject (SKSplitViewExtendedDelegate)
- (void)splitViewDoubleClick:(SKSplitView *)sender;
@end
