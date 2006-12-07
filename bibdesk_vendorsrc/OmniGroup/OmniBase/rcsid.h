// Copyright 1997-2004 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniBase/rcsid.h,v 1.15 2004/02/10 04:07:39 kc Exp $
//
// Define a wrapper macro for rcs_id generation that doesn't produce warnings on any platform.  The old hack of rcs_id = (rcs_id, string) is no longer warning free.

#define RCS_ID(rcsIdString) \
	static const void *rcs_id = rcsIdString; \
	static const void *__rcs_id_hack() { __rcs_id_hack(); return rcs_id; }

#define NAMED_RCS_ID(name, rcsIdString) \
	static const void *rcs_id_ ## name = rcsIdString; \
	static const void *__rcs_id_ ## name ## _hack() { __rcs_id_ ## name ## _hack(); return rcs_id_ ## name; }
