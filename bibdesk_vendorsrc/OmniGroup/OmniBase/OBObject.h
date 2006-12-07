// Copyright 1997-2004 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniBase/OBObject.h,v 1.29 2004/02/10 04:07:39 kc Exp $
/* $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniBase/OBObject.h,v 1.29 2004/02/10 04:07:39 kc Exp $ */
/* $Id: OBObject.h,v 1.29 2004/02/10 04:07:39 kc Exp $ */

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

#if defined(DEBUG_ALLOC)
- (void)dealloc;
#endif

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

#import <OmniBase/SystemType.h> // Defines OBOperatingSystem{Major,Minor}Version


#endif // _OmniBase_OBObject_h_
