// Copyright 1997-2005 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/SourceRelease_2005-10-03/OmniGroup/Frameworks/OmniBase/rcsid.h 66131 2005-07-27 23:14:19Z wiml $
//
// Define a wrapper macro for rcs_id generation that doesn't produce warnings on any platform.  The old hack of rcs_id = (rcs_id, string) is no longer warning free.

#if defined(__GNUC__)
#if __GNUC__ > 2

#define RCS_ID(rcsIdString) \
	static __attribute__((unused,section("__TEXT,rcsid"))) const char rcs_id[] = rcsIdString;
#define NAMED_RCS_ID(name, rcsIdString) \
	static __attribute__((unused,section("__TEXT,rcsid"))) const char rcs_id_ ## name [] = rcsIdString;

#endif
#endif

#ifndef RCS_ID

#define RCS_ID(rcsIdString) \
	static const void *rcs_id = rcsIdString; \
	static const void *__rcs_id_hack() { __rcs_id_hack(); return rcs_id; }

#define NAMED_RCS_ID(name, rcsIdString) \
	static const void *rcs_id_ ## name = rcsIdString; \
	static const void *__rcs_id_ ## name ## _hack() { __rcs_id_ ## name ## _hack(); return rcs_id_ ## name; }

#endif
