//
//  BDSKWebParser.h
//  Bibdesk
//
//  Created by Christiaan Hofman on 4/2/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>

enum {
	BDSKUnknownWebType = -1, 
    BDSKHCiteWebType
};

@interface BDSKWebParser : NSObject

+ (int)webTypeOfDocument:(DOMDocument *)domDocument fromURL:(NSURL *)url;

+ (BOOL)canParseDocument:(DOMDocument *)domDocument fromURL:(NSURL *)url ofType:(int)webType;
+ (BOOL)canParseDocument:(DOMDocument *)domDocument fromURL:(NSURL *)url;

+ (NSArray *)itemsFromDocument:(DOMDocument *)domDocument fromURL:(NSURL *)url ofType:(int)webType error:(NSError **)outError;
+ (NSArray *)itemsFromDocument:(DOMDocument *)domDocument fromURL:(NSURL *)url error:(NSError **)outError;

@end
