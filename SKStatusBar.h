//
//  SKStatusBar.h
//  Skim
//
//  Created by Christiaan Hofman on 8/7/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface SKStatusBar : NSView {
	id leftCell;
	id rightCell;
}

+ (CIColor *)lowerColor;
+ (CIColor *)upperColor;

- (void)toggleBelowView:(NSView *)view offset:(float)offset;

- (BOOL)isVisible;

- (NSString *)leftStringValue;
- (void)setLeftStringValue:(NSString *)aString;

- (NSAttributedString *)leftAttributedStringValue;
- (void)setLeftAttributedStringValue:(NSAttributedString *)object;

- (NSString *)rightStringValue;
- (void)setRightStringValue:(NSString *)aString;

- (NSAttributedString *)rightAttributedStringValue;
- (void)setRightAttributedStringValue:(NSAttributedString *)object;

- (NSFont *)font;
- (void)setFont:(NSFont *)fontObject;

@end
