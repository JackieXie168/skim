//
//  SKSplitView.h
//  Skim
//
//  Created by Christiaan Hofman on 2/10/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class CIColor;

@interface SKSplitView : NSSplitView
+ (CIColor *)startColor;
+ (CIColor *)endColor;
@end

@interface NSObject (SKSplitViewExtendedDelegate)
- (void)splitView:(SKSplitView *)sender doubleClickedDividerAt:(int)offset;
@end
