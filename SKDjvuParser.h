//
//  MADjvuParser.h
//  DjvuViewer
//
//  Created by Sylvain Bouchard on 13-06-12, based on the work of Alex Martynov 2/13/12.
//  Copyright (c) 2012 Sylvain Bouchard. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef struct SKDjvuParserContext SKDjvuParserContext;

@interface SKDjvuParser : NSObject
{
    NSString *filePath;
    SKDjvuParserContext *context;
}

@property(nonatomic, assign, readonly) NSUInteger numberOfPages;

- (id)initWithPath:(NSString*)path;
- (UIImage*)imageForPage:(NSUInteger)page ofSize:(CGSize)size;
- (bool)textForPage:(NSUInteger)page returnAreas:(NSMutableArray*)areas;

@end