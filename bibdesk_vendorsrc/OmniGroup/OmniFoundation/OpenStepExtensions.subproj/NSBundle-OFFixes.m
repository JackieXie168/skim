// Copyright 1999-2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.

#import "NSBundle-OFFixes.h"

#import <Foundation/Foundation.h>
#import <OmniBase/OmniBase.h>

#ifdef __MACH__
#import <mach-o/dyld.h>
#endif

RCS_ID("$Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniFoundation/OpenStepExtensions.subproj/NSBundle-OFFixes.m,v 1.9 2003/01/15 22:51:58 kc Exp $")

@implementation NSBundle (OFFixes)

#if defined(__APPLE__) && defined(__MACH__)

static IMP oldLoadedBundles = NULL;
static IMP oldBundleForClass = NULL;
static NSMutableDictionary *cachedBundlesForClasses = nil;
static NSLock *cachedBundlesForClassesLock = nil;

+ (void) performPosing;
{
    cachedBundlesForClasses = [[NSMutableDictionary alloc] init];
    cachedBundlesForClassesLock = [[NSRecursiveLock alloc] init];
    oldLoadedBundles = OBReplaceMethodImplementationWithSelector(((Class)self)->isa /* we're replacing a class method */, @selector(loadedBundles), @selector(replacement_loadedBundles));
    oldBundleForClass = OBReplaceMethodImplementationWithSelector(((Class)self)->isa /* we're replacing a class method */, @selector(bundleForClass:), @selector(replacement_bundleForClass:));
    OBPOSTCONDITION(oldLoadedBundles != NULL);
    OBPOSTCONDITION(oldBundleForClass != NULL);
}

//
// In Mac OS X Server, if you run an application from a relative path, this method can
// return duplicate bundles.  For example when running Zuul as './Zuul' after cd'ing
// into the Zuul.app app-wrapper, it returns:
//
// (
//     NSBundle </Local/Public/bungi/BuildOutput/Applications/Zuul/Zuul.debug> (loaded),
//     ...
//     NSBundle <.> (loaded),
//     ...
// )
//
// This wouldn't be that big of a deal except that the WorkSpace, at least in some
// configurations, like Connie's iMac, seem to invoke the application this way.
//
// We'll look through the returned bundles and if there are relative paths, standardize
// them and remove the duplicates.
//
// This doesn't attetmpt to standardize all the paths (which might be through symlinks)
// since that would be slow and I haven't seen any problems of that sort -- also,
// I think NSBundle does that anyway.
//

+ (NSArray *) replacement_loadedBundles;
{
    NSArray      *bundles;
    unsigned int  bundleIndex, bundleCount;
    
    // Call the original
    bundles = oldLoadedBundles(self, _cmd);

    bundleCount = [bundles count];
    for (bundleIndex = 0; bundleIndex < bundleCount; bundleIndex++) {
        NSBundle *bundle;
        NSString *bundlePath;
        
        bundle = [bundles objectAtIndex: bundleIndex];
        bundlePath = [bundle bundlePath];
        if (![bundlePath isAbsolutePath]) {
            //
            // Ok, we need to try to fix the bug.  For now, we'll just remove
            // any '.' entries.
            NSMutableArray *filteredBundles;

            filteredBundles = [NSMutableArray arrayWithCapacity: bundleCount];
            for (bundleIndex = 0; bundleIndex < bundleCount; bundleIndex++) {
                bundle = [bundles objectAtIndex: bundleIndex];
                bundlePath = [bundle bundlePath];
                if (![bundlePath isAbsolutePath]) {
                    if ([bundlePath isEqualToString: @"."])
                        continue;
                    else
                        NSLog(@"Non-. relative bundle path found: '%@'", bundlePath);
                }
                [filteredBundles addObject: bundle];
            }

            return filteredBundles;
        }
    }

    return bundles;
}

// In 10.0.4, +bundleForClass: accesses the filesystem every time you call it, so we're now caching the results
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

#endif



#ifdef __MACH__
- (void)fixFrameworkVersioning;
{
    NSString *tmp2;
    NSString *frameworkName;
    NSSymbol sym;
    NSModule mod;
    const char *symbolName;
    const char *fullName;

// _infoDictionary was replaced by _cfBundle as of MacOS X DP2
#if OBOperatingSystemMajorVersion <= 5
    if (_infoDictionary != nil || _tmp2 == nil)
#else
    if (_cfBundle != nil || _tmp2 == nil)
#endif
        return;
    tmp2 = (NSString *)_tmp2;
    if (![[tmp2 pathExtension] isEqualToString:@"framework"])
        return;

    frameworkName = [[tmp2 lastPathComponent] stringByDeletingPathExtension];

    symbolName = [[@".objc_class_name_NSFramework_" stringByAppendingString:frameworkName] cString];
    if (!NSIsSymbolNameDefined(symbolName))
        return;
    sym = NSLookupAndBindSymbol(symbolName);
    mod = NSModuleForSymbol(sym);
    fullName = NSLibraryNameForModule(mod);


    [(id)_tmp2 release];
    _tmp2 = [[[NSString stringWithCString:fullName] stringByDeletingLastPathComponent] retain];

//  NSLog(@"Fixing up %@", (id)_tmp2);
}
#endif


@end
