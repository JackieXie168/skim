// Copyright 1997-2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.

#import <OmniFoundation/OmniFoundation.h>
#import <OmniBase/OmniBase.h>
#import <CoreFoundation/CoreFoundation.h>

RCS_ID("$Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniFoundation/Tests/OFLowerCaseTest.m,v 1.5 2003/01/15 22:52:04 kc Exp $")

int main(int argc, char *argv[])
{
    CFMutableDictionaryRef dict;

    [OBPostLoader processClasses];
    
    dict = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, OFCaseInsensitiveStringKeyDictionaryCallbacks, &kCFTypeDictionaryValueCallBacks);
    
    CFDictionaryAddValue(dict, @"foo key", @"foo value");
    NSLog(@"FOO KEY = %@", CFDictionaryGetValue(dict, @"FOO KEY"));


    return 0;
}
