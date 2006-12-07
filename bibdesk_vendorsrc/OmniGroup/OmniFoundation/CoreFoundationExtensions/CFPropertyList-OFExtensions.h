// Copyright 2003-2004 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniFoundation/CoreFoundationExtensions/CFPropertyList-OFExtensions.h,v 1.2 2004/02/10 04:07:41 kc Exp $

#include <CoreFoundation/CFData.h>
#include <CoreFoundation/CFPropertyList.h>

/* This simply creates a CFStream, writes the property list using CFPropertyListWriteToStream(), and returns the resulting bytes. if an error occurs, an exception is raised. */
CFDataRef OFCreateDataFromPropertyList(CFAllocatorRef allocator, CFPropertyListRef plist, CFPropertyListFormat format);

