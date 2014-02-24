//
//  SKNUtilities.m
//  SkimNotes
//
//  Created by Christiaan Hofman on 7/17/08.
/*
 This software is Copyright (c) 2008-2014
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

#import "SKNUtilities.h"
#import <AppKit/AppKit.h>

#define NOTE_PAGE_INDEX_KEY @"pageIndex"
#define NOTE_TYPE_KEY @"type"
#define NOTE_CONTENTS_KEY @"contents"
#define NOTE_TEXT_KEY @"text"

NSString *SKNSkimTextNotes(NSArray *noteDicts) {
    NSMutableString *textString = [NSMutableString string];
    NSEnumerator *dictEnum = [noteDicts objectEnumerator];
    NSDictionary *dict;
    
    while (dict = [dictEnum nextObject]) {
        NSString *type = [dict objectForKey:NOTE_TYPE_KEY];
        NSUInteger pageIndex = [[dict objectForKey:NOTE_PAGE_INDEX_KEY] unsignedIntegerValue];
        NSString *string = [dict objectForKey:NOTE_CONTENTS_KEY];
        NSAttributedString *text = [dict objectForKey:NOTE_TEXT_KEY];
        
        if (pageIndex == NSNotFound || pageIndex == INT_MAX)
            pageIndex = 0;
        
        [textString appendFormat:@"* %@, page %lu\n\n", type, (long)pageIndex + 1];
        if ([string length]) {
            [textString appendString:string];
            [textString appendString:@" \n\n"];
        }
        if ([text length]) {
            [textString appendString:[text string]];
            [textString appendString:@" \n\n"];
        }
    }
    return textString;
}

NSData *SKNSkimRTFNotes(NSArray *noteDicts) {
    NSMutableAttributedString *attrString = [[[NSMutableAttributedString alloc] init] autorelease];
    NSEnumerator *dictEnum = [noteDicts objectEnumerator];
    NSDictionary *dict;
    
    while (dict = [dictEnum nextObject]) {
        NSString *type = [dict objectForKey:NOTE_TYPE_KEY];
        NSUInteger pageIndex = [[dict objectForKey:NOTE_PAGE_INDEX_KEY] unsignedIntegerValue];
        NSString *string = [dict objectForKey:NOTE_CONTENTS_KEY];
        NSAttributedString *text = [dict objectForKey:NOTE_TEXT_KEY];
        
        if (pageIndex == NSNotFound || pageIndex == INT_MAX)
            pageIndex = 0;
        
        [attrString replaceCharactersInRange:NSMakeRange([attrString length], 0) withString:[NSString stringWithFormat:@"* %@, page %lu\n\n", type, (long)pageIndex + 1]];
        if ([string length]) {
            [attrString replaceCharactersInRange:NSMakeRange([attrString length], 0) withString:string];
            [attrString replaceCharactersInRange:NSMakeRange([attrString length], 0) withString:@" \n\n"];
        }
        if ([text length]) {
            [attrString appendAttributedString:text];
            [attrString replaceCharactersInRange:NSMakeRange([attrString length], 0) withString:@" \n\n"];
            
        }
    }
    [attrString fixAttributesInRange:NSMakeRange(0, [attrString length])];
    return [attrString RTFFromRange:NSMakeRange(0, [attrString length]) documentAttributes:nil];
}
