// Copyright 2002-2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniFoundation/DataStructures.subproj/OFEnumNameTable.h,v 1.2 2003/01/15 22:51:53 kc Exp $

#import <Foundation/NSObject.h>
#import <CoreFoundation/CFDictionary.h>

@interface OFEnumNameTable : NSObject
{
    int                    _defaultEnumValue;
    CFMutableDictionaryRef _enumToName;
    CFMutableDictionaryRef _nameToEnum;
}

- initWithDefaultEnumValue: (int) defaultEnumValue;
- (int) defaultEnumValue;

- (void) setName: (NSString *) enumName forEnumValue: (int) enumValue;

- (NSString *) nameForEnum: (int) enumValue;
- (int) enumForName: (NSString *) name;

@end
