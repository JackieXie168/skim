//
//  BDSKCitationFormatter.m
//  Bibdesk
//
//  Created by Christiaan Hofman on 6/1/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "BDSKCitationFormatter.h"
#import "BibTypeManager.h"


@implementation BDSKCitationFormatter

- (id)initWithDelegate:(id)aDelegate {
    if (self = [super init]) {
        delegate = aDelegate;
    }
    return self;
}

- (id)delegate { return delegate; }

- (void)setDelegate:(id)newDelegate { delegate = newDelegate; }

- (NSString *)stringForObjectValue:(id)obj{
    return obj;
}

- (NSAttributedString *)attributedStringForObjectValue:(id)obj withDefaultAttributes:(NSDictionary *)attrs{
    NSMutableAttributedString *attrString = [[NSMutableAttributedString alloc] initWithString:[self stringForObjectValue:obj] attributes:attrs];
    
    static NSCharacterSet *keySepCharSet = nil;
    static NSCharacterSet *keyCharSet = nil;
    
    if (keySepCharSet == nil) {
        keySepCharSet = [[NSCharacterSet characterSetWithCharactersInString:@","] retain];
        keyCharSet = [[keySepCharSet invertedSet] retain];
    }
    
    NSString *string = [attrString string];
    
    unsigned start, length = [string length];
    NSRange range = NSMakeRange(0, 0);
    NSString *keyString;
    
    [attrString removeAttribute:NSLinkAttributeName range:NSMakeRange(0, length)];
    
    do {
        start = NSMaxRange(range);
        range = [string rangeOfCharacterFromSet:keyCharSet options:0 range:NSMakeRange(start, length - start)];
        
        if (range.length) {
            start = range.location;
            range = [string rangeOfCharacterFromSet:keySepCharSet options:0 range:NSMakeRange(start, length - start)];
            if (range.length == 0)
                range.location = length;
            if (range.location > start) {
                range = NSMakeRange(start, range.location - start);
                keyString = [string substringWithRange:range];
                if ([[self delegate] citationFormatter:self isValidKey:keyString]) {
                    [attrString addAttribute:NSForegroundColorAttributeName value:[NSColor blueColor] range:range];
                    [attrString addAttribute:NSUnderlineStyleAttributeName value:[NSNumber numberWithInt:NSSingleUnderlineStyle] range:range];
                }
            }
        }
    } while (range.length);
    
    NSAttributedString *returnString = [[attrString copy] autorelease];
    [attrString release];
    return returnString;
}

- (BOOL)getObjectValue:(id *)obj forString:(NSString *)string errorDescription:(NSString **)error{
    *obj = string;
    return YES;
}

- (BOOL)isPartialStringValid:(NSString *)partialString
            newEditingString:(NSString **)newString
            errorDescription:(NSString **)error{
	static NSCharacterSet *invalidSet = nil;
    if (invalidSet == nil) {
        NSMutableCharacterSet *tmpSet = [[[BibTypeManager sharedManager] invalidCharactersForField:BDSKCiteKeyString inFileType:BDSKBibtexString] mutableCopy];
        [tmpSet removeCharactersInString:@","];
        invalidSet = [tmpSet copy];
        [tmpSet release];
    }
    NSRange r = [partialString rangeOfCharacterFromSet:invalidSet];
    if (r.location != NSNotFound) {
        if(error) *error = [NSString stringWithFormat:NSLocalizedString(@"The character \"%@\" is not allowed in a BibTeX cite key.", @"Error description"), [partialString substringWithRange:r]];
        return NO;
    }else
        return YES;
}

@end
