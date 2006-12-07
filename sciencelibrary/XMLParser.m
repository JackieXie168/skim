//
//  XMLParser.m
//  CocoaMed
//
//  Created by kmarek on Sun Mar 24 2002.
//  Copyright (c) 2001 __MyCompanyName__. All rights reserved.
//

#import "XMLParser.h"


@implementation XMLParser
+(NSString *)parse: (NSString *)stringToBeParsed withBeginningTag:(NSString *)beginningTag withEndingTag: (NSString *)endingTag
{
    NSScanner *theScanner;
    NSString *parseResults;
    
    theScanner = [NSScanner scannerWithString:stringToBeParsed];
    [theScanner scanUpToString:beginningTag intoString:NULL];
    [theScanner scanString:beginningTag intoString:NULL];    
    if ([theScanner scanUpToString:endingTag intoString:&parseResults]==NO) {
	parseResults=@"";
    }
    
    return parseResults;
}
@end
