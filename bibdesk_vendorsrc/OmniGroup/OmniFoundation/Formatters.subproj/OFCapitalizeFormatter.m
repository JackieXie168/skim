// Copyright 1998-2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.

#import <OmniFoundation/OFCapitalizeFormatter.h>

#import <Foundation/Foundation.h>
#import <OmniBase/OmniBase.h>

RCS_ID("$Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniFoundation/Formatters.subproj/OFCapitalizeFormatter.m,v 1.8 2003/01/15 22:51:57 kc Exp $")

@implementation OFCapitalizeFormatter

#warning Only capitalizes ASCII - Foundation really needs public functions like unichartoupper(unichar c)

- (BOOL)isPartialStringValid:(NSString *)partialString newEditingString:(NSString **)newString errorDescription:(NSString **)error;
{
    unichar *buffer, *pointer;
    BOOL upcaseNext, changed = NO;
    
    if (![super isPartialStringValid:partialString newEditingString:newString errorDescription:error])
        return NO;

    pointer = buffer = alloca(([partialString length] + 1) * sizeof(unichar));
    buffer[[partialString length]] = 0;
    [partialString getCharacters:buffer];

    upcaseNext = YES;
    while (*pointer) {
	changed = NO;
        if (upcaseNext && (*pointer >= 'a') && (*pointer <= 'z')) {
            *pointer += 'A' - 'a';
            changed = YES;
        } else if (*pointer == ' ') {
            upcaseNext = YES;            
        } else
            upcaseNext = NO;
        pointer++;
    }
    if (changed)
        *newString = [NSString stringWithCharacters:buffer length:[partialString length]];
    return !changed;
}

@end
