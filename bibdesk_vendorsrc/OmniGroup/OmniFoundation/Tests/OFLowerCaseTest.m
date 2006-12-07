// Copyright 1997-2004 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import <OmniFoundation/OmniFoundation.h>
#import <OmniBase/OmniBase.h>
#import <CoreFoundation/CoreFoundation.h>

RCS_ID("$Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniFoundation/Tests/OFLowerCaseTest.m,v 1.7 2004/02/10 04:07:48 kc Exp $")

int main(int argc, char *argv[])
{
    CFMutableDictionaryRef dict;

    [OBPostLoader processClasses];
    
    dict = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, OFCaseInsensitiveStringKeyDictionaryCallbacks, &kCFTypeDictionaryValueCallBacks);
    
    CFDictionaryAddValue(dict, @"foo key", @"foo value");
    NSLog(@"FOO KEY = %@", CFDictionaryGetValue(dict, @"FOO KEY"));


    return 0;
}
