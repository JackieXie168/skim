//
//  BDSKWebParser.m
//  Bibdesk
//
//  Created by Christiaan Hofman on 4/2/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "BDSKWebParser.h"
#import <OmniBase/OBUtilities.h>
#import "BDSKHCiteParser.h"


@implementation BDSKWebParser

static Class webParserClassForType(int stringType)
{
    Class parserClass = Nil;
    switch(stringType){
		case BDSKHCiteWebType: 
            parserClass = [BDSKHCiteParser class];
            break;
        default:
            parserClass = Nil;
    }    
    return parserClass;
}

+ (int)webTypeOfDocument:(DOMDocument *)domDocument fromURL:(NSURL *)url{
	if([BDSKHCiteParser canParseDocument:domDocument fromURL:url])
		return BDSKHCiteWebType;
    return BDSKUnknownWebType;
}

+ (BOOL)canParseDocument:(DOMDocument *)domDocument fromURL:(NSURL *)url ofType:(int)webType{
    Class parserClass = Nil;
    if (webType == BDSKUnknownWebType)
        webType = [self webTypeOfDocument:domDocument fromURL:url];
    parserClass = webParserClassForType(webType);
    return parserClass != Nil ? [parserClass canParseDocument:domDocument fromURL:url] : NO;
}

+ (BOOL)canParseDocument:(DOMDocument *)domDocument fromURL:(NSURL *)url{
    return NO;
}

+ (NSArray *)itemsFromDocument:(DOMDocument *)domDocument fromURL:(NSURL *)url ofType:(int)webType error:(NSError **)outError{
    Class parserClass = Nil;
    parserClass = webParserClassForType(webType);
    return [parserClass itemsFromDocument:domDocument fromURL:url error:outError];
}

+ (NSArray *)itemsFromDocument:(DOMDocument *)domDocument fromURL:(NSURL *)url error:(NSError **)outError{
    if([self class] == [BDSKWebParser class]){
        return [self itemsFromDocument:domDocument fromURL:(NSURL *)url ofType:BDSKUnknownWebType error:outError];
    }else{
        OBRequestConcreteImplementation(self, _cmd);
        return nil;
    }
}

@end
