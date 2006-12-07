//  BDSKFormCellFormatter.m

//  Created by Michael McCracken on Mon Jul 22 2002.
/*
 This software is Copyright (c) 2002, Michael O. McCracken
 All rights reserved.

 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 -  Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 -  Neither the name of Michael O. McCracken nor the names of any contributors may be used to endorse or promote products derived from this software without specific prior written permission.

 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "BDSKFormCellFormatter.h"

//  About this file: BDSKFormCellFormatter
//
//  This is an NSFormatter subclass that provides for the autocompletion
//  facility in the NSFormCells that populate the form in the BibEditor window.
//


@implementation BDSKFormCellFormatter
- (NSString *)stringForObjectValue:(id)obj{
    return obj;
}

- (NSAttributedString *)attributedStringForObjectValue:(id)obj withDefaultAttributes:(NSDictionary *)attrs{
    return [[[NSAttributedString alloc] initWithString:[self stringForObjectValue:obj] attributes:attrs] autorelease];
}

- (BOOL)getObjectValue:(id *)obj forString:(NSString *)string errorDescription:(NSString **)error{
    *obj = string; // ? retain?
    return YES;
}

- (BOOL)isPartialStringValid:(NSString **)partialStringPtr     proposedSelectedRange:(NSRangePointer)proposedSelRangePtr  originalString:(NSString *)origString originalSelectedRange:(NSRange)origSelRange
            errorDescription:(NSString **)error{


    NSArray *strings = [[NSApp delegate] stringsForCompletionEntry:_entry];
    NSEnumerator *stringE = [strings objectEnumerator];
    NSString *string = nil;

    while(string = [stringE nextObject]){
        if ([string hasPrefix:*partialStringPtr]) {
            break;
        }
    }
    // If this would not move the cursor forward, it is a delete.
    // also allow to keep typing for no match - new entries are OK.
    if (!string || origSelRange.location == proposedSelRangePtr->location) return YES;

    // If the partial string is shorter than the
    // match,  provide the match and set the selection
    if ([string length] > [*partialStringPtr length]) {

        proposedSelRangePtr->location = [*partialStringPtr length];
        proposedSelRangePtr->length = [string length] - [*partialStringPtr length];
        *partialStringPtr = string;
        return NO;
    }
    return YES;
}

- (NSString *)entry{
    return _entry;
}

- (void)setEntry:(NSString *)entry{
    [_entry autorelease];
    _entry = [entry retain];
}

- (void)dealloc{
    [_entry release];
}

@end
