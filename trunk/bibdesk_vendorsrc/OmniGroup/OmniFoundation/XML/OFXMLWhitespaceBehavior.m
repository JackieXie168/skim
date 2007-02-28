// Copyright 2003-2005 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import <OmniFoundation/OFXMLWhitespaceBehavior.h>

#import <Foundation/Foundation.h>
#import <OmniBase/OmniBase.h>
#import <OmniBase/rcsid.h>
#import <OmniFoundation/CFDictionary-OFExtensions.h>

RCS_ID("$Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/OmniSourceRelease_2006-09-07/OmniGroup/Frameworks/OmniFoundation/XML/OFXMLWhitespaceBehavior.m 68913 2005-10-03 19:36:19Z kc $");

@implementation OFXMLWhitespaceBehavior

// Init and dealloc

- init;
{
    _nameToBehavior  = (NSMutableDictionary *)CFDictionaryCreateMutable(kCFAllocatorDefault, 0, &OFNSObjectDictionaryKeyCallbacks, &OFIntegerDictionaryValueCallbacks);
    return self;
}

- (void)dealloc;
{
    [_nameToBehavior release];
    [super dealloc];
}

- (void) setBehavior: (OFXMLWhitespaceBehaviorType) behavior forElementName: (NSString *) elementName;
{
    OBPRECONDITION(OFXMLWhitespaceBehaviorTypeAuto == 0);
    
    if (behavior == OFXMLWhitespaceBehaviorTypeAuto)
        [_nameToBehavior removeObjectForKey: elementName];
    else
        [_nameToBehavior setObject: (id)behavior forKey: elementName];
}

- (OFXMLWhitespaceBehaviorType) behaviorForElementName: (NSString *) elementName;
{
    OBPRECONDITION(OFXMLWhitespaceBehaviorTypeAuto == 0);

    return (OFXMLWhitespaceBehaviorType)[_nameToBehavior objectForKey: elementName];
}

@end
