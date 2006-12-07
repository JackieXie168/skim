// Copyright 2002-2004 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniFoundation/DataStructures.subproj/OFEnumNameTable.h,v 1.7 2004/02/10 04:07:43 kc Exp $

#import <Foundation/NSObject.h>
#import <CoreFoundation/CFDictionary.h>
#import <CoreFoundation/CFArray.h>

@class OFXMLCursor, OFXMLDocument;

@interface OFEnumNameTable : NSObject
{
    int                    _defaultEnumValue;
    CFMutableArrayRef      _enumOrder;
    CFMutableDictionaryRef _enumToName;
    CFMutableDictionaryRef _nameToEnum;
}

- initWithDefaultEnumValue: (int) defaultEnumValue;
- (int) defaultEnumValue;

- (void) setName: (NSString *) enumName forEnumValue: (int) enumValue;

- (NSString *) nameForEnum: (int) enumValue;
- (int) enumForName: (NSString *) name;
- (BOOL) isEnumValue: (int) enumValue;

- (unsigned int)count;
- (unsigned int)indexForEnum:(int)enumValue;
- (int)enumForIndex:(unsigned int)enumIndex;
- (int)nextEnum:(int)enumValue;
- (NSString *)nextName:(NSString *)name;

// Comparison
- (BOOL) isEqual: (id)anotherEnumeration;

// Archving (primarily for OAEnumStyleAttribute)
+ (NSString *)xmlElementName;
- (void)appendXML:(OFXMLDocument *)doc;
- initFromXML:(OFXMLCursor *)cursor;

@end
