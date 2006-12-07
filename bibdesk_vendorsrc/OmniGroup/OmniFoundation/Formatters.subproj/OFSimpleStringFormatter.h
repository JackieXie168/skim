// Copyright 1997-2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniFoundation/Formatters.subproj/OFSimpleStringFormatter.h,v 1.5 2003/01/15 22:51:57 kc Exp $

#import <Foundation/NSFormatter.h>

@interface OFSimpleStringFormatter : NSFormatter
{
    unsigned int maxLength;
}

- initWithMaxLength:(unsigned int)value;

- (void)setMaxLength:(unsigned int)value;
- (unsigned int)maxLength;

@end
