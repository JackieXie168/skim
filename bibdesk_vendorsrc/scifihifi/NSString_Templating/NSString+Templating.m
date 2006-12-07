/*

NSString+Templating.m
TemplateTest
by Buzz Andersen

More information at: http://www.scifihifi.com/weblog/software/NSString+Templating.html

This work is licensed under the Creative Commons Attribution License. To view a copy of this license, visit

http://creativecommons.org/licenses/by/1.0/

or send a letter to Creative Commons, 559 Nathan Abbott Way, Stanford,
California 94305, USA.

*/

#import "NSString+Templating.h"


@implementation NSString (Templating)

- (NSString *) stringByParsingTagsWithStartDelimeter: (NSString *) startDelim endDelimeter: (NSString *) endDelim usingObject: (id) object {
    NSScanner *scanner = [NSScanner scannerWithString: self];
    NSMutableString *result = [[NSMutableString alloc] init];

    [scanner setCharactersToBeSkipped: nil];
    
    while (![scanner isAtEnd]) {
        NSString *tag;
        NSString *beforeText;
                
        if ([scanner scanUpToString: startDelim intoString: &beforeText]) {
            [result appendString: beforeText];
        }
        
        if ([scanner scanString: startDelim intoString: nil]) {
            if ([scanner scanString: endDelim intoString: nil]) {
                continue;
            }
            else if ([scanner scanUpToString: endDelim intoString: &tag] && [scanner scanString: endDelim intoString: nil]) {
                id keyValue = [object valueForKeyPath: [tag stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceCharacterSet]]];
                
                if (keyValue != nil) {
                    [result appendFormat: @"%@", keyValue];
                }
            }
        }
    }
    
    return [result autorelease];    
}

- (NSString *) stringByEscapingQuotes {
    return [self stringByEscapingCharactersInSet: [NSCharacterSet characterSetWithCharactersInString: @"\""] usingString: @"\\"];
}

- (NSString *) stringByEscapingCharactersInSet: (NSCharacterSet *) set usingString: (NSString *) escapeString {
    NSMutableString *result = [[NSMutableString alloc] init];
    int stringLength = [self length];
    int currentPosition = 0;
    unichar currentChar;
    
    while (currentPosition < stringLength) {
        currentChar = [self characterAtIndex: currentPosition];

        if ([set characterIsMember: currentChar]) {
            [result appendString: escapeString];
        }
        
        [result appendFormat: @"%C", currentChar];

        currentPosition++;
    }
    
    return [result autorelease];    
}

@end
