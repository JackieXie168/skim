/*

NSString+Templating.h
TemplateTest
by Buzz Andersen

More information at: http://www.scifihifi.com/weblog/software/NSString+Templating.html

This work is licensed under the Creative Commons Attribution License. To view a copy of this license, visit

http://creativecommons.org/licenses/by/1.0/

or send a letter to Creative Commons, 559 Nathan Abbott Way, Stanford,
California 94305, USA.

*/

#import <Foundation/Foundation.h>


@interface NSString (Templating)

- (NSString *) stringByParsingTagsWithStartDelimeter: (NSString *) startDelim endDelimeter: (NSString *) endDelim usingObject: (id) object;
- (NSString *) stringByEscapingQuotes;
- (NSString *) stringByEscapingCharactersInSet: (NSCharacterSet *) set usingString: (NSString*) escapeString;

@end
