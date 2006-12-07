// Copyright 1998-2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.

#import <OmniFoundation/OFUppercaseFormatter.h>

#import <Foundation/Foundation.h>
#import <OmniBase/OmniBase.h>

RCS_ID("$Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniFoundation/Formatters.subproj/OFUppercaseFormatter.m,v 1.6 2003/01/15 22:51:58 kc Exp $")

@implementation OFUppercaseFormatter

- (BOOL)isPartialStringValid:(NSString *)partialString newEditingString:(NSString **)newString errorDescription:(NSString **)error;
{
    if (![super isPartialStringValid:partialString newEditingString:newString errorDescription:error])
        return NO;

    *newString = [partialString uppercaseString];
    return [*newString isEqualToString:partialString];
}

@end
