//
//  NSAttributedString_BDSKExtensions.m
//  Bibdesk
//
//  Created by Christiaan Hofman on 6/5/06.
/*
 This software is Copyright (c) 2006
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

#import "NSAttributedString_BDSKExtensions.h"
#import "BDSKComplexString.h"
#import "NSString_BDSKExtensions.h"
#import "NSCharacterSet_BDSKExtensions.h"
#import "BDSKFontManager.h"


@implementation NSAttributedString (BDSKExtensions)

- (id)initWithTeXString:(NSString *)string attributes:(NSDictionary *)attributes collapseWhitespace:(BOOL)collapse{
    [[self init] release];
    
    // get rid of whitespace if we have to; we can't use this on the attributed string's content store, though
    if(collapse){
        if([string isComplex])
            string = [NSString stringWithString:string];
        string = [string fastStringByCollapsingWhitespaceAndRemovingSurroundingWhitespace];
    }
    
    // set up the attributed string now, so we can start working with its character contents
    NSMutableAttributedString *mas = [[NSMutableAttributedString alloc] initWithString:string attributes:attributes]; // set the whole thing up with default attrs
    NSMutableString *mutableString = [mas mutableString];
    
    BDSKFontManager *fontManager = (BDSKFontManager *)[BDSKFontManager sharedFontManager];
    NSString *texStyle = nil;    
    NSMutableDictionary *attrs = [attributes mutableCopy];
    NSFont *font = [attributes objectForKey:NSFontAttributeName];
    if (font == nil)
        font = [NSFont systemFontOfSize:0];
    
    NSRange searchRange = NSMakeRange(0, [mutableString length]); // starting value; changes as we change the string
    NSRange cmdRange;
    NSRange styleRange;
    unsigned startLoc; // starting character index to apply tex attributes
    unsigned endLoc;   // ending index to apply tex attributes
    
    while( (cmdRange = [mutableString rangeOfTeXCommandInRange:searchRange]).location != NSNotFound){
        
        // find the command
        texStyle = [mutableString substringWithRange:cmdRange];
        
        // delete the command, now that we know what it was
        [mutableString deleteCharactersInRange:cmdRange];
        
        // what does the command affect?
        startLoc = cmdRange.location;  // remember, we deleted our command, but not the brace
        if([mutableString characterAtIndex:startLoc] == '{' && (endLoc = [mutableString indexOfRightBraceMatchingLeftBraceAtIndex:startLoc]) != NSNotFound){
            [attrs setObject:[fontManager convertFont:font toHaveTrait:[fontManager fontTraitMaskForTeXStyle:texStyle]]
                      forKey:NSFontAttributeName];
            styleRange = NSMakeRange(startLoc + 1, (endLoc - startLoc - 1));
            //NSLog(@"applying to %@", [mutableString substringWithRange:styleRange]);
            [mas setAttributes:attrs range:styleRange];
        }
        // new range, since we've altered the string
        searchRange = NSMakeRange(startLoc, [mutableString length] - startLoc);
    }

    [attrs release];
    [mutableString deleteCharactersInCharacterSet:[NSCharacterSet curlyBraceCharacterSet]];
    
    self = [mas copy];
    [mas release];
    
    return self;
}

- (id)initWithAttributedString:(NSAttributedString *)attributedString attributes:(NSDictionary *)attributes {
    [[self init] release];
    NSMutableAttributedString *tmpStr = [[NSMutableAttributedString alloc] initWithAttributedString:attributedString];
    unsigned index = 0, length = [attributedString length];
    NSRange range = NSMakeRange(0, length);
    NSDictionary *attrs;
    [tmpStr addAttributes:attributes range:range];
    while (index < length) {
        attrs = [attributedString attributesAtIndex:index effectiveRange:&range];
        if (range.length > 0) {
            [tmpStr addAttributes:attrs range:range];
            index = NSMaxRange(range);
        } else index++;
    }
    [tmpStr fixAttributesInRange:NSMakeRange(0, [self length])];
    return self = tmpStr;
}

@end
