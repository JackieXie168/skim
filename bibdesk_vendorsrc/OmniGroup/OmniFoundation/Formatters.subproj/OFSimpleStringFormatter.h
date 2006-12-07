// Copyright 1997-2004 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniFoundation/Formatters.subproj/OFSimpleStringFormatter.h,v 1.7 2004/02/10 04:07:44 kc Exp $

#import <Foundation/NSFormatter.h>

@interface OFSimpleStringFormatter : NSFormatter
{
    unsigned int maxLength;
}

- initWithMaxLength:(unsigned int)value;

- (void)setMaxLength:(unsigned int)value;
- (unsigned int)maxLength;

@end
