// Copyright 1997-2005 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/OmniSourceRelease_2006-09-07/OmniGroup/Frameworks/OmniFoundation/DataStructures.subproj/OFStack.h 68913 2005-10-03 19:36:19Z kc $

#import <Foundation/NSZone.h>
#import <objc/objc.h>

#import <OmniFoundation/FrameworkDefines.h>

typedef struct {
    NSZone                     *stackZone;
    void                       *stackRoot;
    unsigned long               basePointer;
    unsigned long               stackPointer;
    unsigned long               stackSize;
    unsigned long               currentFrameSize;
    unsigned long               frameCount;
} OFStack;


#define OMNI_TYPE_OP(cType, strType)								\
        OmniFoundation_EXTERN void OFStackPush ## strType (OFStack *stack, cType aVal);         \
        OmniFoundation_EXTERN void OFStackPop ## strType (OFStack *stack, cType *aVal);         \
        OmniFoundation_EXTERN void OFStackPeek ## strType (OFStack *stack,			\
                                                             unsigned long basePointer,		\
                                                             int offset, cType *aVal);		\
        OmniFoundation_EXTERN void OFStackPoke ## strType (OFStack *stack,			\
                                                             unsigned long basePointer,		\
                                                             int offset, cType aVal);

OMNI_TYPE_OP(unsigned long, UnsignedLong)
OMNI_TYPE_OP(id,            Id)
OMNI_TYPE_OP(SEL,           SEL)
OMNI_TYPE_OP(void *,        Pointer)

#undef OMNI_TYPE_OP

OmniFoundation_EXTERN void OFStackDebug(BOOL enableStackDebugging);

OmniFoundation_EXTERN OFStack *OFStackAllocate(NSZone *zone);
OmniFoundation_EXTERN void OFStackDeallocate(OFStack *stack);

OmniFoundation_EXTERN void OFStackPushBytes(OFStack *stack,
                                            const void *bytes,
                                            unsigned long size);
OmniFoundation_EXTERN void OFStackPopBytes(OFStack *stack,
                                           void *bytes,
                                           unsigned long size);

OmniFoundation_EXTERN void OFStackPushFrame(OFStack *stack);
OmniFoundation_EXTERN void OFStackPopFrame(OFStack *stack);

/* Advanced features */
OmniFoundation_EXTERN unsigned long OFStackPreviousFrame(OFStack *stack, unsigned long framePointer);
OmniFoundation_EXTERN void          OFStackDiscardBytes(OFStack *stack, unsigned long size);
OmniFoundation_EXTERN void          OFStackPrint(OFStack *stack);

