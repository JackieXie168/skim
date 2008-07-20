//
//  SKUtilities.h
//  Skim
//
//  Created by Christiaan Hofman on 2/15/07.

/* Some of the following functions are inspired by OmniBase/SKUtilities.h and subject to the following copyright */

// Copyright 1997-2008 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import <objc/objc.h>
#import <objc/objc-class.h>
#import <objc/objc-runtime.h>

IMP SKReplaceMethodImplementation(Class aClass, SEL aSelector, IMP anImp, BOOL isInstance);
IMP SKReplaceMethodImplementationWithSelector(Class aClass, SEL aSelector, SEL impSelector);
IMP SKReplaceClassMethodImplementationWithSelector(Class aClass, SEL aSelector, SEL impSelector);
void SKRegisterMethodImplementation(Class aClass, SEL aSelector, IMP anImp, const char *types, BOOL isInstance);
IMP SKRegisterMethodImplementationWithSelector(Class aClass, SEL aSelector, SEL impSelector);
IMP SKRegisterClassMethodImplementationWithSelector(Class aClass, SEL aSelector, SEL impSelector);

#define OBINITIALIZE \
    do { \
        static BOOL hasBeenInitialized = NO; \
        [super initialize]; \
        if (hasBeenInitialized) \
            return; \
        hasBeenInitialized = YES;\
    } while (0);
