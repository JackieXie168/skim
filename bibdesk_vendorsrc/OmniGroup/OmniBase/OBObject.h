// Copyright 1997-2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniBase/OBObject.h,v 1.25 2003/01/15 22:51:47 kc Exp $
/* $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniBase/OBObject.h,v 1.25 2003/01/15 22:51:47 kc Exp $ */
/* $Id: OBObject.h,v 1.25 2003/01/15 22:51:47 kc Exp $ */

#ifndef _OmniBase_OBObject_h_
#define _OmniBase_OBObject_h_

#import <Foundation/NSObject.h>

// OBObject.h
//


@interface OBObject : NSObject

// Creation and destruction

#if defined(DEBUG_INITIALIZE) || defined(DEBUG_ALLOC)
+ allocWithZone:(NSZone *)zone;
#endif

- (void)dealloc;

@end


@class NSDictionary;
@class NSMutableDictionary;


@interface OBObject (Debug)

// Debugging methods

- (NSMutableDictionary *)debugDictionary;
- (NSString *)descriptionWithLocale:(NSDictionary *)locale indent:(unsigned)level;
- (NSString *)description;


- (NSString *)shortDescription;

@end


#import <OmniBase/FrameworkDefines.h>

// OmniBase Functions

/*"
This method returns the original description for anObject, as implemented on NSObject. This allows you to get the original description even if the normal description methods have been overridden.

See also: - description (NSObject), - description (OBObject), - shortDescription (OBObject)
 "*/
OmniBase_EXTERN NSString *OBShortObjectDescription(id anObject);


// OmniBase Symbols

#import <OmniBase/SystemType.h> // Defines YELLOW_BOX and/or RHAPSODY when appropriate


#endif // _OmniBase_OBObject_h_
