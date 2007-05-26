//
//  NSValue_SKExtensions.h
//  Skim
//
//  Created by Christiaan Hofman on 26/5/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSValue (SKExtensions)

- (NSComparisonResult)boundsCompare:(NSValue *)aValue;

- (NSString *)rectString;
- (NSString *)pointString;
- (NSString *)originString;
- (NSString *)sizeString;
- (NSString *)midPointString;

@end
