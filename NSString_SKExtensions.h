//
//  NSString_SKExtensions.h
//  Skim
//
//  Created by Christiaan Hofman on 12/2/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSString (SKExtensions)

- (NSString *)fastStringByCollapsingWhitespaceAndNewlinesAndRemovingSurroundingWhitespaceAndNewlines;

@end
