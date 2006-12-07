// Copyright 1997-2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniFoundation/OFUtilities.h,v 1.28 2003/03/25 21:31:31 len Exp $

#import <objc/objc-class.h>
#import <objc/objc-runtime.h>
#import <OmniFoundation/FrameworkDefines.h>
#import <Foundation/NSGeometry.h>
#import <stddef.h> // For size_t

@class NSObject, NSString, NSDictionary;

#ifndef NO_INLINE
#define OFUtilities_INLINE inline
#else
#define OFUtilities_INLINE
#endif // NO_INLINE

OmniFoundation_EXTERN void OFLog(NSString *messageFormat, ...);
OmniFoundation_EXTERN NSString *OFGetInput(NSString *promptFormat, ...);

OmniFoundation_EXTERN void OFSetIvar(NSObject *object, NSString *ivarName, NSObject *ivarValue);
OmniFoundation_EXTERN NSObject *OFGetIvar(NSObject *object, NSString *ivarName);

// Makes NSCoding methods simpler.  Note that if 'var' is an object, you DO NOT
// have to retain it afterward a decode; -decodeValueOfObjeCType:at: retains it
// for you.
#define OFEncode(coder, var) [coder encodeValueOfObjCType: @encode(typeof(var)) at: &(var)];
#define OFDecode(coder, var) [coder decodeValueOfObjCType: @encode(typeof(var)) at: &(var)];

// This returns the root class for the class tree of which aClass is a member.
static OFUtilities_INLINE Class OFRootClassForClass(Class aClass)
{
    while (((struct objc_class *)aClass)->super_class)
	aClass = aClass->super_class;
    return aClass;
}

OmniFoundation_EXTERN BOOL OFInstanceIsKindOfClass(id instance, Class aClass);

OmniFoundation_EXTERN NSString *OFDescriptionForObject(id object, NSDictionary *locale, unsigned indentLevel);
 // This function returns a pointer to a string that can be used to uniquely identify an object, be it an instance or a class.  We define that this function only works for classes that have names shorter than OF_MAX_CLASS_NAME_LEN.  This pointer passed to this function must contain at least this much space.

OmniFoundation_EXTERN SEL OFRegisterSelectorIfAbsent(const char *selName);
OmniFoundation_EXTERN NSRect OFLargestRectAvoidingRect(NSRect parentRect, NSRect childRect);

#define OF_MAX_CLASS_NAME_LEN (256)
OmniFoundation_EXTERN char *OFNameForPointer(id object, char *pointerName);

#define OFStackAllocatedNameForPointer(object) \
	OFNameForPointer(object, alloca(OF_MAX_CLASS_NAME_LEN))

#define OFLockRegion_Begin(theLock) NS_DURING [theLock lock];
#define OFLockRegion_End(theLock) NS_HANDLER { [theLock unlock]; [localException raise]; } NS_ENDHANDLER [theLock unlock];

OmniFoundation_EXTERN unsigned int OFLocalIPv4Address(void);

// A string which uniquely identifies this computer. Currently, it's the MAC address for the built-in ethernet port, but that or the underlying implementation could change.
OmniFoundation_EXTERN NSString *OFUniqueMachineIdentifier();

// Utilities for dealing with language names and ISO codes. If either function fails to find a translation match, it'll return its argument.
OmniFoundation_EXTERN NSString *OFISOLanguageCodeForEnglishName(NSString *languageName);
OmniFoundation_EXTERN NSString *OFLocalizedNameForISOLanguageCode(NSString *languageCode);

// The amount of space remaining on the stack of the current thread.
OmniFoundation_EXTERN size_t OFRemainingStackSize();

