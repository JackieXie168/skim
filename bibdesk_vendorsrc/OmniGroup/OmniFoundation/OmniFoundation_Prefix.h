// Copyright 2003-2004 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniFoundation/OmniFoundation_Prefix.h,v 1.3 2004/02/10 04:07:41 kc Exp $

// The '-H' compiler flag is good for figuring out this list.
#import <CoreFoundation/CoreFoundation.h>
#import <unistd.h>
#import <pthread.h>
#import <mach/mach.h>

#ifdef __OBJC__
    #import <Foundation/Foundation.h>
    #import <OmniBase/OmniBase.h>
    #import <OmniBase/system.h>
        
    // Finally, pick up some very common used but infrequently changed headers from OmniFoundation itself
    #import <OmniFoundation/OFByte.h>
    #import <OmniFoundation/OFByteOrder.h>
    #import <OmniFoundation/OFConcreteInvocation.h>
    #import <OmniFoundation/OFMessageQueue.h>
    #import <OmniFoundation/OFNull.h>
    #import <OmniFoundation/OFObject.h>
    #import <OmniFoundation/OFSimpleLock.h>
    #import <OmniFoundation/OFScheduler.h>
    #import <OmniFoundation/OFScheduledEvent.h>
    #import <OmniFoundation/OFStringScanner.h>
    #import <OmniFoundation/OFUtilities.h>
    #import <OmniFoundation/OFWeakRetainProtocol.h>

    #import <OmniFoundation/NSArray-OFExtensions.h>
    #import <OmniFoundation/NSObject-OFExtensions.h>
    #import <OmniFoundation/NSString-OFExtensions.h>
    #import <OmniFoundation/NSThread-OFExtensions.h>
    
    #import <OmniFoundation/FrameworkDefines.h>
#endif
