//
//  SKFDFParser.h
//  Skim
//
//  Created by Christiaan Hofman on 6/9/07.
//  Copyright 2007 Christiaan Hofman. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface SKFDFParser : NSObject
+ (NSArray *)notesDictionariesFromFDFString:(NSString *)string;
+ (NSDictionary *)fdfObjectsFromFDFString:(NSString *)string;
@end
