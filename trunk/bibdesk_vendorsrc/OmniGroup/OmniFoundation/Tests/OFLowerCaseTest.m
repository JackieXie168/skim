// Copyright 1997-2005 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import <OmniFoundation/OmniFoundation.h>
#import <OmniBase/OmniBase.h>
#import <CoreFoundation/CoreFoundation.h>

RCS_ID("$Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/OmniSourceRelease_2006-09-07/OmniGroup/Frameworks/OmniFoundation/Tests/OFLowerCaseTest.m 66043 2005-07-25 21:17:05Z kc $")

int main(int argc, char *argv[])
{
    CFMutableDictionaryRef dict;

    [OBPostLoader processClasses];
    
    dict = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, &OFCaseInsensitiveStringKeyDictionaryCallbacks, &kCFTypeDictionaryValueCallBacks);
    
    CFDictionaryAddValue(dict, @"foo key", @"foo value");
    NSLog(@"FOO KEY = %@", CFDictionaryGetValue(dict, @"FOO KEY"));


    return 0;
}
