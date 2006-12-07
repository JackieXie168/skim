// Copyright 1997-2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniBase/system.h,v 1.34 2003/01/15 23:01:35 wiml Exp $
//
// This file contains stuff that isn't necessarily portable between operating systems.

#import <OmniBase/SystemType.h> // Defines YELLOW_BOX and/or RHAPSODY when appropriate

#if defined(sun)

//
// Solaris (PDO or OpenStep)
//

#import <sys/types.h>
#import <sys/errno.h>
#import <unistd.h>
#import <alloca.h>
#import <stdlib.h>

#import <sys/socket.h>
#import <netinet/in.h>
#import <arpa/inet.h>
#import <arpa/nameser.h>
#import <netdb.h>
#import <resolv.h>

#import <dirent.h>
#import <sys/stat.h>

#import <string.h>
#import <ctype.h>
#import <values.h>  // for MAXINT, MAXDOUBLE, etc

#import <sys/uio.h>
#import <sys/file.h>
#import <fcntl.h>

#import <objc/Protocol.h>

#ifdef __cplusplus
extern "C" {
#endif
extern int res_init(void);
extern int gethostname(char *name, int namelen);
#ifdef __cplusplus
}
#endif

#import <math.h>

// These are defined in a really funky place in Solaris.
#if defined(__GNUC__) && !defined(__STRICT_ANSI__)

#if !defined(MIN)
    #define MIN(A,B)	({ __typeof__(A) __a = (A); __typeof__(B) __b = (B); __a < __b ? __a : __b; })
#endif

#if !defined(MAX)
    #define MAX(A,B)	({ __typeof__(A) __a = (A); __typeof__(B) __b = (B); __a < __b ? __b : __a; })
#endif

#if !defined(ABS)
    #define ABS(A)	({ __typeof__(A) __a = (A); __a < 0 ? -__a : __a; })
#endif

#else

#if !defined(MIN)
    #define MIN(A,B)	((A) < (B) ? (A) : (B))
#endif

#if !defined(MAX)
    #define MAX(A,B)	((A) > (B) ? (A) : (B))
#endif

#if !defined(ABS)
    #define ABS(A)	((A) < 0 ? (-(A)) : (A))
#endif

#endif	/* __GNUC__ */

#elif defined(WIN32)

//
// OPENSTEP Enterprise 4.2 for Windows NT or Yellow Box for Windows
//

//  This was apparently removed in the DR2 YellowBox/NT
//#import <ansi/ansi.h>
#import <winnt-pdo.h>
#import <winsock.h>
#import <fcntl.h>
#import <malloc.h>
#import <process.h> // for getpid()
#import <io.h>      // open(), close()

// Sockets
#define OBSocketRead(socketFD, buffer, byteCount) recv(socketFD, buffer, byteCount, 0)
#define OBSocketWrite(socketFD, buffer, byteCount) send(socketFD, buffer, byteCount, 0)
#define OBSocketClose(socketFD) closesocket(socketFD)

// WinSock has these defined, but puts an #if 0 around them.
#define ETIMEDOUT WSAETIMEDOUT
#define ECONNREFUSED WSAECONNREFUSED
#define ENETDOWN WSAENETDOWN
#define ENETUNREACH WSAENETUNREACH
#define EHOSTDOWN WSAEHOSTDOWN
#define EHOSTUNREACH WSAEHOSTUNREACH

// Don't find these anywhere in NT.
#define MAXHOSTNAMELEN (256)
#define IN_CLASSD(i) (((long)(i) & 0xf0000000) == 0xe0000000)
#define IN_MULTICAST(i) IN_CLASSD(i)

#undef alloca

#elif defined(RHAPSODY)

//
// Rhapsody
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
