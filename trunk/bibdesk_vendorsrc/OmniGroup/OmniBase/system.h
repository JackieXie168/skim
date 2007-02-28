// Copyright 1997-2006 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/OmniSourceRelease_2006-09-07/OmniGroup/Frameworks/OmniBase/system.h 79079 2006-09-07 22:35:32Z kc $
//
// This file contains stuff that isn't necessarily portable between operating systems.

#import <OmniBase/SystemType.h> // For OBOperatingSystemMajorVersion

#if defined(__APPLE__) && defined(__MACH__)
//
// Mac OS X
//

#import <libc.h>
#import <stddef.h>
#import <arpa/nameser.h>
#import <resolv.h>
#import <netdb.h>
#import <sys/types.h>
#import <sys/time.h>
#import <sys/dir.h>
#import <sys/errno.h>
#import <sys/stat.h>
#import <sys/uio.h>
#import <sys/file.h>
#import <fcntl.h>
#if (OBOperatingSystemMajorVersion == 10) && !defined(MAC_OS_X_VERSION_MAX_ALLOWED)
// On pre-Jaguar systems (identified using the above #if condition), <c.h> defines true and false, but so does <CarbonCore/MacTypes.h>.  We'd like <c.h>'s definition, since it actually typedefs the enum as 'bool', but unfortunately that would break the Foundation precompiled header (which prebuilds <CarbonCore/ConditionalMacros.h>), so we'll use Carbon's version instead.  Unfortunately, this means the 'bool' type won't actually be declared, since Carbon's true/false enum isn't named.  C'est la vie!
#import <Carbon/Carbon.h> // defines true and false
#define bool bool // So <c.h> won't try to define the 'bool' type (with true and false)
// OK, now it's safe to #import <c.h>.
#endif
#import <c.h> // For MIN(), etc.
#import <unistd.h>
#import <math.h> // For floor(), etc.

#import <pthread.h>

#else

//
// Unknown system
//

#error Unknown system!

#endif

// Default to using BSD socket API.

#ifndef OBSocketRead
#define OBSocketRead(socketFD, buffer, byteCount) read(socketFD, buffer, byteCount)
#endif
#ifndef OBSocketWrite
#define OBSocketWrite(socketFD, buffer, byteCount) write(socketFD, buffer, byteCount)
#endif
#ifndef OBSocketWriteVectors
#define OBSocketWriteVectors(socketFD, buffers, bufferCount) writev(socketFD, buffers, bufferCount)
#endif
#ifndef OBSocketClose
#define OBSocketClose(socketFD) close(socketFD)
#endif
