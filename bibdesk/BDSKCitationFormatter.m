//
//  BDSKCitationFormatter.m
//  Bibdesk
//
//  Created by Christiaan Hofman on 1/6/07.
/*
 This software is Copyright (c) 2005,2006,2007
 Christiaan Hofman. All rights reserved.

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:

 - Redistributions of source code must retain the above copyright
   notice, this list of conditions and the following disclaimer.

 - Redistributions in binary form must reproduce the above copyright
    notice, this list of conditions and the following disclaimer in
    the documentation and/or other materials provided with the
    distribution.

 - Neither the name of Christiaan Hofman nor the names of any
    contributors may be used to endorse or promote products derived
    from this software without specific prior written permission.

 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

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
                    [attrString addAttribute:NSLinkAttributeName value:keyString range:range];
                    [attrString addAttribute:NSForegroundColorAttributeName value:[NSColor blueColor] range:range];
                    [attrString addAttribute:NSUnderlineStyleAttributeName value:[NSNumber numberWithInt:NSUnderlineStyleSingle] range:range];
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
