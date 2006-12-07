// Copyright 1997-2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.

#import <OmniBase/assertions.h>
#import <Foundation/Foundation.h>
#import <OmniBase/rcsid.h>

RCS_ID("$Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniBase/assertions.m,v 1.23 2003/03/24 23:05:04 neo Exp $")

#ifdef OMNI_ASSERTIONS_ON
#warning (Assertions enabled.  To disable, undefine OMNI_ASSERTIONS_ON.)
#else
#warning (Assertions disabled.  To enable, define OMNI_ASSERTIONS_ON.)
#endif

static void OBLogAssertionFailure(const char *type, const char *expression, const char *file, unsigned int lineNumber)
{
    fprintf(stderr, "%s failed: requires '%s', file %s, line %d\n", type, expression, file, lineNumber);
}

// Some machines (NT, at least) lose the last stack frame when you call abort(), which makes it difficult to debug assertion failures.  We'll call OBAbort() instead of abort() so that you can set a breakpoint on OBAbort() and not lose the stack frame.

#ifdef DEBUG

static void OBAbort(const char *type, const char *expression, const char *file, unsigned int lineNumber)
{
    OBLogAssertionFailure(type, expression, file, lineNumber);

    fprintf(stderr, "Aborting (presumably due to assertion failure).\n");
    fflush(stderr);
    abort();
}

#endif

//
// The default assertion handler
//

#define OBDefaultAssertionHandler OBLogAssertionFailure

#ifdef OMNI_ASSERTIONS_ON
static NSString *OBShouldAbortOnAssertFailureEnabled = @"OBShouldAbortOnAssertFailureEnabled";
#endif
static OBAssertionFailureHandler currentAssertionHandler = OBDefaultAssertionHandler;

void OBSetAssertionFailureHandler(OBAssertionFailureHandler handler)
{
    if (handler)
        currentAssertionHandler = handler;
    else
        currentAssertionHandler = OBDefaultAssertionHandler;
}

void OBAssertFailed(const char *type, const char *expression, const char *file, unsigned int lineNumber)
{
    currentAssertionHandler(type, expression, file, lineNumber);
}

// Unless OMNI_PRODUCTION_BUILD is specified, log a message about whether assertions are enabled or not.
#ifndef OMNI_PRODUCTION_BUILD

@interface _OBAssertionWarning : NSObject
@end

@implementation _OBAssertionWarning
+ (void)didLoad;
{
#ifdef OMNI_ASSERTIONS_ON
    NSUserDefaults *userDefaults;
    
    fprintf(stderr, "*** Assertions are ON ***\n");
    userDefaults = [NSUserDefaults standardUserDefaults];
    if ([userDefaults boolForKey:OBShouldAbortOnAssertFailureEnabled])
        OBSetAssertionFailureHandler(OBAbort);
#else
#ifdef DEBUG
    fprintf(stderr, "*** Assertions are OFF ***\n");
#endif
#endif
}
@end

#endif // OMNI_PRODUCTION_BUILD

