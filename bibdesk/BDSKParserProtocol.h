/*
 *  BDSKParserProtocol.h
 *  Bibdesk
 *
 *  Created by Adam Maxwell on 02/07/06.
 *  Copyright 2006 __MyCompanyName__. All rights reserved.
 *
 */

#import <Foundation/NSObject.h>

@protocol BDSKParser <NSObject>

+ (NSMutableArray *)itemsFromString:(NSString *)itemString error:(NSError **)outError;
+ (NSMutableArray *)itemsFromString:(NSString *)itemString error:(NSError **)outError frontMatter:(NSMutableString *)frontMatter filePath:(NSString *)filePath;

@end