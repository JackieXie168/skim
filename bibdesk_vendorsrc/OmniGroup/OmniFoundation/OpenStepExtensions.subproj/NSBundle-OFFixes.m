// Copyright 1999-2004 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import "NSBundle-OFFixes.h"

#import <Foundation/Foundation.h>
#import <OmniBase/OmniBase.h>

#ifdef __MACH__
#import <mach-o/dyld.h>
#endif

RCS_ID("$Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniFoundation/OpenStepExtensions.subproj/NSBundle-OFFixes.m,v 1.17 2004/02/10 04:07:45 kc Exp $")

@implementation NSBundle (OFFixes)

static IMP oldBundleForClass = NULL;
static NSMutableDictionary *cachedBundlesForClasses = nil;
static NSLock *cachedBundlesForClassesLock = nil;

+ (void) performPosing;
{
    cachedBundlesForClasses = [[NSMutableDictionary alloc] init];
    cachedBundlesForClassesLock = [[NSRecursiveLock alloc] init];
    oldBundleForClass = OBReplaceMethodImplementationWithSelector(((Class)self)->isa /* we're replacing a class method */, @selector(bundleForClass:), @selector(replacement_bundleForClass:));
    OBPOSTCONDITION(oldBundleForClass != NULL);
}

// In 10.0.4, +bundleForClass: accesses the filesystem every time you call it, so we're now caching the results
// TJW: Retested on 10.2.6 and 10.3 7A179 (from WWDC2003).  This is still a problem: It seems they've added a single-entry cache, but if you repeatedly pass classes from different bundles, you'll get repeated stat/access calls for those bundles.
// Test case submitted at http://www.omnigroup.com/~bungi/NSBundleFileAccessTest-20030702.zip
// Submitted to Radar as #3313045
+ (NSBundle *)replacement_bundleForClass:(Class)aClass;
{
    NSBundle *bundle = nil;
    NSException *savedException = nil;
    NSString *className;

    if (aClass == nil)
        return oldBundleForClass(self, _cmd, aClass);
    className = NSStringFromClass(aClass);
    if (className == nil)
        return oldBundleForClass(self, _cmd, aClass);
    [cachedBundlesForClassesLock lock];
    NS_DURING {
        bundle = [cachedBundlesForClasses objectForKey:className];
        if (bundle == nil) {
            bundle = oldBundleForClass(self, _cmd, aClass);
            if (bundle != nil)
                [cachedBundlesForClasses setObject:bundle forKey:className];
        }
    } NS_HANDLER {
        savedException = localException;
    } NS_ENDHANDLER;
    [cachedBundlesForClassesLock unlock];
    if (savedException != nil)
        [savedException raise];
    return bundle;
}

@end
