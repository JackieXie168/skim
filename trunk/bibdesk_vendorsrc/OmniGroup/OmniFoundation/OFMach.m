// Copyright 1997-2005 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import <OmniFoundation/OFMach.h>

#import <OmniBase/OmniBase.h>
#import <sys/sysctl.h>
#import <stdio.h>

RCS_ID("$Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/OmniSourceRelease_2006-09-07/OmniGroup/Frameworks/OmniFoundation/OFMach.m 68913 2005-10-03 19:36:19Z kc $")

static unsigned int _OFNumberOfProcessors = 0xffffffff;

unsigned int OFNumberOfProcessors(void)
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
