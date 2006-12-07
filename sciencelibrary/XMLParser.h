//
//  XMLParser.h
//  CocoaMed
//
//  Created by kmarek on Sun Mar 24 2002.
//  Copyright (c) 2001 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface XMLParser : NSObject {

}
+(NSString *)parse: (NSString *)stringToBeParsed withBeginningTag:(NSString *)beginningTag withEndingTag: (NSString *)endingTag;
@end
