//
//  NSScrollView_SKExtensions.m
//  Skim
//
//  Created by Christiaan Hofman on 2/18/07.
/*
 This software is Copyright (c) 2007
 Christiaan Hofman. All rights reserved.

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:

 - Redistributions of source code must retain the above copyright
   notice, this list of conditions and the following disclaimer.

 - Redistributions in binary form must reproduce the above copyright
    notice, this list of conditions and the following disclaimer in
    the documentation and/or other materials provided with the
    distribution.

 - Neither the name of Christiaan Hofman nor the names of any
    contributors may be used to endorse or promote products derived
    from this software without specific prior written permission.

 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

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
