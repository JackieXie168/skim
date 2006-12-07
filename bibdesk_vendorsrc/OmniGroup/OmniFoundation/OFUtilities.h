// Copyright 1997-2005 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/OmniSourceRelease_2006-09-07/OmniGroup/Frameworks/OmniFoundation/OFUtilities.h 70959 2005-12-07 20:34:33Z wiml $

#import <objc/objc-class.h>
#import <objc/objc-runtime.h>
#import <OmniFoundation/FrameworkDefines.h>
#import <Foundation/NSGeometry.h>
#import <stddef.h> // For size_t

@class NSObject, NSString, NSDictionary;

OmniFoundation_EXTERN void OFLog(NSString *messageFormat, ...);
OmniFoundation_EXTERN NSString *OFGetInput(NSString *promptFormat, ...);

OmniFoundation_EXTERN void OFSetIvar(NSObject *object, NSString *ivarName, NSObject *ivarValue);
OmniFoundation_EXTERN NSObject *OFGetIvar(NSObject *object, NSString *ivarName);

// Makes NSCoding methods simpler.  Note that if 'var' is an object, you DO NOT
// have to retain it afterward a decode; -decodeValueOfObjCType:at: retains it
// for you.
#define OFEncode(coder, var) [coder encodeValueOfObjCType: @encode(typeof(var)) at: &(var)];
#define OFDecode(coder, var) [coder decodeValueOfObjCType: @encode(typeof(var)) at: &(var)];

// This returns the root class for the class tree of which aClass is a member.
static inline Class OFRootClassForClass(Class aClass)
{
    while (((struct objc_class *)aClass)->super_class)
	aClass = aClass->super_class;
    return aClass;
}

OmniFoundation_EXTERN BOOL OFInstanceIsKindOfClass(id instance, Class aClass);

OmniFoundation_EXTERN NSString *OFDescriptionForObject(id object, NSDictionary *locale, unsigned indentLevel);

OmniFoundation_EXTERN SEL OFRegisterSelectorIfAbsent(const char *selName);

// OFNameForPointer() returns a pointer to a string that can be used to uniquely identify an object, be it an instance or a class.  We define that this function only works for classes that have names shorter than OF_MAX_CLASS_NAME_LEN.  This pointer passed to this function must contain at least this much space.
#define OF_MAX_CLASS_NAME_LEN (256)
OmniFoundation_EXTERN char *OFNameForPointer(id object, char *pointerName);

#define OFStackAllocatedNameForPointer(object) \
	OFNameForPointer(object, alloca(OF_MAX_CLASS_NAME_LEN))

#define OFLockRegion_Begin(theLock) NS_DURING [theLock lock];
#define OFLockRegion_End(theLock) NS_HANDLER { [theLock unlock]; [localException raise]; } NS_ENDHANDLER [theLock unlock];

#define OFForEachObject(enumExpression, valueType, valueVar) NSEnumerator * valueVar ## _enumerator = (enumExpression); valueType valueVar; while( (valueVar = [ valueVar ## _enumerator nextObject]) != nil)

#define OFForEachInArray(arrayExpression, valueType, valueVar, loopBody) { NSArray * valueVar ## _array = (arrayExpression); unsigned int valueVar ## _count , valueVar ## _index; valueVar ## _count = [( valueVar ## _array ) count]; for( valueVar ## _index = 0; valueVar ## _index < valueVar ## _count ; valueVar ## _index ++ ) { valueType valueVar = [( valueVar ## _array ) objectAtIndex:( valueVar ## _index )]; loopBody ; } }

OmniFoundation_EXTERN unsigned int OFLocalIPv4Address(void);

// A string which uniquely identifies this computer. Currently, it's the MAC address for the built-in ethernet port, but that or the underlying implementation could change.
OmniFoundation_EXTERN NSString *OFUniqueMachineIdentifier(void);

// A name which identifies this computer.
OmniFoundation_EXTERN NSString *OFHostName(void);

// Utilities for dealing with language names and ISO codes. If either function fails to find a translation match, it'll return its argument.
OmniFoundation_EXTERN NSString *OFISOLanguageCodeForEnglishName(NSString *languageName);
OmniFoundation_EXTERN NSString *OFLocalizedNameForISOLanguageCode(NSString *languageCode);

// The amount of space remaining on the stack of the current thread.
OmniFoundation_EXTERN size_t OFRemainingStackSize(void);

// Formats a four character code into a ASCII representation.  This can take up to 4*3+1 characters.  Each byte can be up to three characters ('\ff'), plus the trailing NULL.  Returns the given fccString for ease in passing to NSLog/printf.
// The fcc is really a FourCharCode (or OSType, OSStatus, ComponentResult, etc, etc, etc).  Don't want to include MacTypes.h here though.
OmniFoundation_EXTERN char *OFFormatFCC(unsigned long fcc, char fccString[13]);

// Parses a FourCharCode (or OSType) from an ObjC property-list type. This is compatible with the strings created by UTCreateStringForOSType(), but also accepts NSDatas and NSNumbers. Returns YES if successful, NO if not.
BOOL OFGet4CCFromPlist(id pl, uint32_t *fourcc);

// Creates a property-list representation of the given FourCharCode. Not necessarily compatible with UTGetOSTypeFromString(), because it might not return an NSString.
id OFCreatePlistFor4CC(uint32_t fourcc);
