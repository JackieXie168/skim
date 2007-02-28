// Copyright 2005-2006 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import "NSMutableSet-OFExtensions.h"
#import "NSMutableArray-OFExtensions.h"

#import <Foundation/Foundation.h>
#import <OmniBase/rcsid.h>

RCS_ID("$Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/OmniSourceRelease_2006-09-07/OmniGroup/Frameworks/OmniFoundation/OpenStepExtensions.subproj/NSSet-OFExtensions.m 72176 2006-02-02 00:12:21Z wiml $");

@implementation NSSet (OFExtensions)

struct performAndAddContext {
    SEL sel;
    id singleObject;
    NSMutableSet *result;
};

static void performAndAdd(const void *anObject, void *_context)
{
    struct performAndAddContext *context = _context;
    id addend = [(id <NSObject>)anObject performSelector:context->sel];
    if (addend) {
        if (context->singleObject == addend) {
            /* ok */
        } else if (context->result != nil) {
            [context->result addObject:addend];
        } else if (context->singleObject == nil) {
            context->singleObject = addend;
        } else {
            NSMutableSet *newSet = [NSMutableSet set];
            [newSet addObject:context->singleObject];
            [newSet addObject:addend];
            context->singleObject = nil;
            context->result = newSet;
        }
    }
}

- (NSSet *)setByPerformingSelector:(SEL)aSelector;
{
    struct performAndAddContext ctxt = {
        .result = nil,
        .singleObject = nil,
        .sel = aSelector
    };
    
    CFSetApplyFunction((CFSetRef)self, performAndAdd, &ctxt);
    
    if (ctxt.result)
        return ctxt.result;
    else if (ctxt.singleObject)
        return [NSSet setWithObject:ctxt.singleObject];
    else
        return [NSSet set];
}

struct insertionSortContext {
    SEL sel;
    NSMutableArray *into;
};

static void insertionSort(const void *anObject, void *_context)
{
    struct insertionSortContext *context = _context;
    [context->into insertObject:(id)anObject inArraySortedUsingSelector:context->sel];
}

- (NSArray *)sortedArrayUsingSelector:(SEL)comparator;
{
    struct insertionSortContext ctxt;
    
    ctxt.sel = comparator;
    ctxt.into = [NSMutableArray arrayWithCapacity:[self count]];
    
    CFSetApplyFunction((CFSetRef)self, insertionSort, &ctxt);
    
    return ctxt.into;
}

@end
