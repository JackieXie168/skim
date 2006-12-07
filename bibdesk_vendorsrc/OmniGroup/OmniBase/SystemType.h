// Copyright 1998-2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniBase/SystemType.h,v 1.15 2003/01/15 22:51:47 kc Exp $


#if defined(WIN32)

//
// OPENSTEP Enterprise 4.2 for Windows NT or Yellow Box for Windows
//

// Unfortunately, Apple has not yet provided any official mechanism for figuring out which version of the libraries you're using.  Fortunately, FOUNDATION_STATIC_INLINE wasn't defined under OPENSTEP Enterprise 4.2.

#import <Foundation/NSObjCRuntime.h>
#ifdef FOUNDATION_STATIC_INLINE

// Yellow Box APIs are available
#ifndef YELLOW_BOX
#define YELLOW_BOX
#endif

#endif

#elif defined(__APPLE__) && defined(__MACH__)

// Mac OS X or Mac OS X Server (was Rhapsody)

#import <sys/version.h>

// Yellow Box APIs are available
#ifndef YELLOW_BOX
#define YELLOW_BOX
#endif

// This define is intended to allow one to distinguish between Rhapsody and OPENSTEP for the purposes of conditional code, since Apple has not yet provided an equivalent.
#ifndef RHAPSODY
#define RHAPSODY
#endif

#define OBOperatingSystemMajorVersion KERNEL_MAJOR_VERSION
#define OBOperatingSystemMinorVersion KERNEL_MINOR_VERSION

#elif defined(NeXT)

//
// NeXT-derived platform, e.g. OPENSTEP/Mach or Rhapsody
//

#define OBOperatingSystemMajorVersion NS_TARGET_MAJOR
#define OBOperatingSystemMinorVersion NS_TARGET_MINOR

#if (OBOperatingSystemMajorVersion > 4) || ((OBOperatingSystemMinorVersion == 4) && (OBOperatingSystemMinorVersion > 1))

// Yellow Box APIs are available
#ifndef YELLOW_BOX
#define YELLOW_BOX
#endif

// This define is intended to allow one to distinguish between Rhapsody and OPENSTEP for the purposes of conditional code, since Apple has not yet provided an equivalent.
#ifndef RHAPSODY
#define RHAPSODY
#endif

#endif

#elif defined(__sun__)

// Unfortunately, Apple has not yet provided any official mechanism for figuring out which version of the libraries you're using.  Fortunately, FOUNDATION_STATIC_INLINE wasn't defined under OPENSTEP Enterprise 4.2.

#import <Foundation/NSObjCRuntime.h>
#ifdef FOUNDATION_STATIC_INLINE

// Yellow Box APIs are available
#ifndef YELLOW_BOX
#define YELLOW_BOX
#endif

#endif

#endif

#ifdef YELLOW_BOX

// Yellow Box has EOF 3.0
#ifndef EOF3_0
#define EOF3_0
#endif

#endif
