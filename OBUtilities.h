//
//  OBUtilities.h
//  Skim
//
//  Created by Christiaan Hofman on 2/15/07.

/* Following functions are from OmniBase/OBUtilities.h and subject to the following copyright */

// Copyright 1997-2006 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import <objc/objc.h>
#import <objc/objc-class.h>
#import <objc/objc-runtime.h>

IMP OBRegisterInstanceMethodWithSelector(Class aClass, SEL oldSelector, SEL newSelector);
IMP OBReplaceMethodImplementation(Class aClass, SEL oldSelector, IMP newImp);
IMP OBReplaceMethodImplementationWithSelector(Class aClass, SEL oldSelector, SEL newSelector);
