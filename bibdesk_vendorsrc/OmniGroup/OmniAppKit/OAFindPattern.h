// Copyright 2001-2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniAppKit/OAFindPattern.h,v 1.6 2003/01/15 22:51:31 kc Exp $

#import <Foundation/NSObject.h>

@class NSString;

#import <OmniAppKit/OAFindControllerTargetProtocol.h>

@interface OAFindPattern : NSObject <OAFindPattern>
{
    NSString *pattern;
    unsigned int optionsMask;
    BOOL wholeWord;
    NSString *replacementString;
}

- initWithString:(NSString *)aString ignoreCase:(BOOL)ignoreCase wholeWord:(BOOL)isWholeWord backwards:(BOOL)backwards;

@end
