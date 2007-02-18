//
//  NSScrollView_SKExtensions.m
//  Skim
//
//  Created by Christiaan Hofman on 2/18/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "NSScrollView_SKExtensions.h"
#import "OBUtilities.h"


@implementation NSScrollView (BDSKZoomablePDFViewExtensions)

static IMP originalSetHasHorizontalScroller = NULL;
static IMP originalSetHasVerticalScroller = NULL;
static BOOL (*originalHasHorizontalScroller)(id, SEL) = NULL;
static BOOL (*originalHasVerticalScroller)(id, SEL) = NULL;
static IMP originalDealloc = NULL;

static CFMutableSetRef scrollViewsWithHorizontalScrollers = NULL;
static CFMutableSetRef scrollViewsWithoutHorizontalScrollers = NULL;
static CFMutableSetRef scrollViewsWithVerticalScrollers = NULL;
static CFMutableSetRef scrollViewsWithoutVerticalScrollers = NULL;

+ (void)load{
    originalSetHasHorizontalScroller = OBReplaceMethodImplementationWithSelector(self, @selector(setHasHorizontalScroller:), @selector(replacementSetHasHorizontalScroller:));
    originalSetHasVerticalScroller = OBReplaceMethodImplementationWithSelector(self, @selector(setHasVerticalScroller:), @selector(replacementSetHasVerticalScroller:));
    originalHasHorizontalScroller = (typeof(originalHasHorizontalScroller))OBReplaceMethodImplementationWithSelector(self, @selector(hasHorizontalScroller), @selector(replacementHasHorizontalScroller));
    originalHasVerticalScroller = (typeof(originalHasVerticalScroller))OBReplaceMethodImplementationWithSelector(self, @selector(hasVerticalScroller), @selector(replacementHasVerticalScroller));
    originalDealloc = OBReplaceMethodImplementationWithSelector(self, @selector(dealloc), @selector(replacementDealloc));
    
    // set doesn't retain, so no retain cycles; pointer equality used to compare views
    scrollViewsWithHorizontalScrollers = CFSetCreateMutable(CFAllocatorGetDefault(), 0, NULL);
    scrollViewsWithoutHorizontalScrollers = CFSetCreateMutable(CFAllocatorGetDefault(), 0, NULL);
    scrollViewsWithVerticalScrollers = CFSetCreateMutable(CFAllocatorGetDefault(), 0, NULL);
    scrollViewsWithoutVerticalScrollers = CFSetCreateMutable(CFAllocatorGetDefault(), 0, NULL);
}

- (void)replacementDealloc;
{
    CFSetRemoveValue(scrollViewsWithHorizontalScrollers, self);
    CFSetRemoveValue(scrollViewsWithoutHorizontalScrollers, self);
    CFSetRemoveValue(scrollViewsWithVerticalScrollers, self);
    CFSetRemoveValue(scrollViewsWithoutVerticalScrollers, self);
    originalDealloc(self, _cmd);
}

- (void)setAlwaysHasHorizontalScroller:(BOOL)flag;
{
    if (flag) {
        CFSetAddValue(scrollViewsWithHorizontalScrollers, self);
        [self setHasHorizontalScroller:YES];
    } else {
        CFSetRemoveValue(scrollViewsWithHorizontalScrollers, self);
    }
}

- (void)setNeverHasHorizontalScroller:(BOOL)flag;
{
    if (flag) {
        CFSetAddValue(scrollViewsWithoutHorizontalScrollers, self);
        [self setHasHorizontalScroller:NO];
    } else {
        CFSetRemoveValue(scrollViewsWithoutHorizontalScrollers, self);
    }
}

- (void)setAlwaysHasVerticalScroller:(BOOL)flag;
{
    if (flag) {
        CFSetAddValue(scrollViewsWithVerticalScrollers, self);
        [self setHasVerticalScroller:YES];
    } else {
        CFSetRemoveValue(scrollViewsWithVerticalScrollers, self);
    }
}

- (void)setNeverHasVerticalScroller:(BOOL)flag;
{
    if (flag) {
        CFSetAddValue(scrollViewsWithoutVerticalScrollers, self);
        [self setHasVerticalScroller:NO];
    } else {
        CFSetRemoveValue(scrollViewsWithoutVerticalScrollers, self);
    }
}

- (void)replacementSetHasHorizontalScroller:(BOOL)flag;
{
    if (CFSetContainsValue(scrollViewsWithHorizontalScrollers, self))
        flag = YES;
    else if (CFSetContainsValue(scrollViewsWithoutHorizontalScrollers, self))
        flag = NO;
    originalSetHasHorizontalScroller(self, _cmd, flag);
}

- (void)replacementSetHasVerticalScroller:(BOOL)flag;
{
    if (CFSetContainsValue(scrollViewsWithVerticalScrollers, self))
        flag = YES;
    else if (CFSetContainsValue(scrollViewsWithoutVerticalScrollers, self))
        flag = NO;
    originalSetHasVerticalScroller(self, _cmd, flag);
}

- (BOOL)replacementHasHorizontalScroller;
{
    BOOL flag;
    if (CFSetContainsValue(scrollViewsWithHorizontalScrollers, self))
        flag = YES;
    else if (CFSetContainsValue(scrollViewsWithoutHorizontalScrollers, self))
        flag = NO;
    else
        flag = originalHasHorizontalScroller(self, _cmd);
    return flag;
}

- (BOOL)replacementHasVerticalScroller;
{
    BOOL flag;
    if (CFSetContainsValue(scrollViewsWithVerticalScrollers, self))
        flag = YES;
    else if (CFSetContainsValue(scrollViewsWithoutVerticalScrollers, self))
        flag = NO;
    else
        flag = originalHasVerticalScroller(self, _cmd);
    return flag;
}

@end
