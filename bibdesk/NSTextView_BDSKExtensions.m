//
//  NSTextView_BDSKExtensions.m
//  Bibdesk
//
//  Created by Michael McCracken on Thu Jul 18 2002.
//  Copyright (c) 2002 __MyCompanyName__. All rights reserved.
//

#import "NSTextView_BDSKExtensions.h"


@implementation NSTextView (BDSKExtensions)
- (void)selectLine:(int) line;
{
    int i;
    NSString *string;
    unsigned start;
    unsigned end;
    unsigned irrelevant;
    NSRange myRange;

    string = [self string];

    // simple sanity check:
    if(line > [string length]) return;
    
    myRange.location = 0;
    myRange.length = 1;
    for (i = 1; i <= line; i++) {
        [string getLineStart:&start
                       end:&end
               contentsEnd:&irrelevant
                  forRange:myRange];
        myRange.location = end;
    }
    myRange.location = start;
    myRange.length = (end - start);
    [self setSelectedRange:myRange];
    [self scrollRangeToVisible:myRange];
}
@end
