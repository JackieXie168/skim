// Copyright 2005 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header$

#import <Foundation/NSObject.h>
#import <CoreFoundation/CFString.h>

typedef struct _OFXMLBuffer *OFXMLBuffer;

extern OFXMLBuffer OFXMLBufferCreate(void);
extern void OFXMLBufferDestroy(OFXMLBuffer buf);

extern void OFXMLBufferAppendString(OFXMLBuffer buf, CFStringRef str);
extern void OFXMLBufferAppendASCIICString(OFXMLBuffer buf, const char *str);

extern CFDataRef OFXMLBufferCopyData(OFXMLBuffer buf, CFStringEncoding encoding);
