// Copyright 2002-2004 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniFoundation/OFSoftwareUpdateCheckTool.h,v 1.5 2004/02/10 04:07:41 kc Exp $

#define OFOSUSCT_Success	0
#define OFOSUSCT_MiscFailure	1

#define OFOSUSCT_RemoteNetworkFailure	10	// timed out, connection failed, etc
#define OFOSUSCT_RemoteServiceFailure	11	// connected, but failed (404, or garbled response, or something)
#define OFOSUSCT_LocalNetworkFailure	12	// we don't seem to have a network right now, or if we do, we can't reach the dest. host (this can also occur if the dest hostname does not exist)

