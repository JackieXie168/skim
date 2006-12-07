// Copyright 1997-2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.

#import <OmniFoundation/OFMach.h>

#import <OmniBase/OmniBase.h>
#import <sys/sysctl.h>
#import <stdio.h>

RCS_ID("$Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniFoundation/OFMach.m,v 1.6 2003/01/15 22:51:50 kc Exp $")

static unsigned int _OFNumberOfProcessors = 0xffffffff;

unsigned int OFNumberOfProcessors()
{
    if (_OFNumberOfProcessors == 0xffffffff) {
        int name[] = {CTL_HW, HW_NCPU};
        size_t size;
        
        size = sizeof(_OFNumberOfProcessors);
        if (sysctl(name, 2, &_OFNumberOfProcessors, &size, NULL, 0) < 0) {
            perror("sysctl");
            _OFNumberOfProcessors = 0;
        }
    }

    return _OFNumberOfProcessors;
}
