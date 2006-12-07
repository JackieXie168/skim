//
//  BDSKFormCellFormatter.m
//  Bibdesk
//
//  Created by Michael McCracken on Mon Jul 22 2002.
//  Copyright (c) 2002 __MyCompanyName__. All rights reserved.
//

#import "BDSKFormCellFormatter.h"


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

- (BOOL)isPartialStringValid:(NSString **)partialStringPtr
       proposedSelectedRange:(NSRangePointer)proposedSelRangePtr
              originalString:(NSString *)origString
       originalSelectedRange:(NSRange)origSelRange
            errorDescription:(NSString **)error{

    NSArray *strings = [[NSApp delegate] stringsForCompletionEntry:_entry];
    NSEnumerator *stringE = [strings objectEnumerator];
    NSString *string = nil;
    NSString *proposedString = [[(*partialStringPtr) copy] autorelease];

  /*  
    while(string = [stringE nextObject]){
        if ([string hasPrefix:*partialStringPtr]) {
            *partialStringPtr = [NSString stringWithString:string];
            *proposedSelRangePtr = NSMakeRange(origSelRange.location,
                                               [(*partialStringPtr) length] - origSelRange.location);
            return NO;
        }
    }*/
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
