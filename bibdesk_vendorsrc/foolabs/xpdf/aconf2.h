/*
 * aconf2.h
 *
 * This gets included by aconf.h, and contains miscellaneous global
 * settings not directly controlled by autoconf.  This is a separate
 * file because otherwise the configure script will munge any
 * #define/#undef constructs.
 *
 * Copyright 2002 Glyph & Cog, LLC
 */

#ifndef ACONF2_H
#define ACONF2_H

/*
 * This controls the use of the interface/implementation pragmas.
 */
#ifdef __GNUC__
#define USE_GCC_PRAGMAS
#endif
/* There is a bug in the version of gcc which ships with MacOS X 10.2 */
#ifdef MAC_OS_X_VERSION_MAX_ALLOWED
#  if MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_2
#    undef USE_GCC_PRAGMAS
#  endif
#endif

#endif
