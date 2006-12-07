// Copyright 1997-2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.

#import <OmniFoundation/NSScanner-OFExtensions.h>

#import <Foundation/Foundation.h>
#import <OmniBase/OmniBase.h>

RCS_ID("$Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniFoundation/OpenStepExtensions.subproj/NSScanner-OFExtensions.m,v 1.8 2003/01/15 22:52:00 kc Exp $")

@implementation NSScanner (OFExtensions)

- (BOOL)scanStringOfLength:(unsigned int)length intoString:(NSString **)result;
{
    NSString                   *string;
    unsigned int                scanLocation;

    string = [self string];
    scanLocation = [self scanLocation];
    if (scanLocation + length >= [string length])
	return NO;
    if (result)
	*result = [string substringWithRange: NSMakeRange(scanLocation, length)];
    [self setScanLocation:scanLocation + length];
    return YES;
}

@end
