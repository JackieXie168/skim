// Copyright 1997-2005 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import <OmniFoundation/NSMutableArray-OFExtensions.h>

#import <OmniFoundation/NSArray-OFExtensions.h>
#import <OmniFoundation/CFDictionary-OFExtensions.h>

#import <Foundation/Foundation.h>
#import <OmniBase/OmniBase.h>

RCS_ID("$Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/SourceRelease_2005-10-03/OmniGroup/Frameworks/OmniFoundation/OpenStepExtensions.subproj/NSMutableArray-OFExtensions.m 66170 2005-07-28 17:40:10Z kc $")

@implementation NSMutableArray (OFExtensions)

- (void)insertObjectsFromArray:(NSArray *)anArray atIndex:(unsigned int)anIndex
{
    [self replaceObjectsInRange:(NSRange){ location:anIndex, length:0 } withObjectsFromArray:anArray];
}

- (void)removeIdenticalObjectsFromArray:(NSArray *)removeArray;
{
    NSEnumerator               *removeEnumerator;
    id				removeObject;

    if (!removeArray)
	return;
    removeEnumerator = [removeArray objectEnumerator];
    while ((removeObject = [removeEnumerator nextObject]))
	[self removeObjectIdenticalTo:removeObject];
}

static void addObjectToArray(const void *value, void *context)
{
    [(NSMutableArray *)context addObject:(id)value];
}

- (void)addObjectsFromSet:(NSSet *)aSet;
{
    if (aSet == nil || [aSet count] == 0)
        return;

    /* We use this instead of an NSSet method in order to avoid autoreleases */
    CFSetApplyFunction((CFSetRef)aSet, addObjectToArray, (void *)self);
}

- (void)replaceObjectsInRange:(NSRange)replacementRange byApplyingSelector:(SEL)selector
{
    NSMutableArray *replacements = [[NSMutableArray alloc] initWithCapacity:replacementRange.length];
    unsigned index;

    NS_DURING;
    
    for(index = 0; index < replacementRange.length; index ++) {
        id sourceObject, replacementObject;

        sourceObject = [self objectAtIndex:(replacementRange.location + index)];
        replacementObject = [sourceObject performSelector:selector];
        if (replacementObject == nil)
            OBRejectInvalidCall(self, _cmd, @"Object at index %d returned nil from %@", (replacementRange.location + index), NSStringFromSelector(selector));
        [replacements addObject:replacementObject];
    }

    [self replaceObjectsInRange:replacementRange withObjectsFromArray:replacements];

    NS_HANDLER {
        [replacements release];
        [localException raise];
    } NS_ENDHANDLER;

    [replacements release];
}

- (void)reverse
{
    unsigned count, index;

    count = [self count];
    if (count < 2)
        return;
    for(index = 0; index < count/2; index ++) {
        unsigned otherIndex = count - index - 1;
        [self exchangeObjectAtIndex:index withObjectAtIndex:otherIndex];
    }
}

struct sortOrderingContext {
    CFMutableDictionaryRef sortOrdering;
    BOOL putUnknownObjectsAtFront;
};

static NSComparisonResult orderObjectsBySavedIndex(id object1, id object2, void *_context)
{
    const struct sortOrderingContext context = *(struct sortOrderingContext *)_context;
    Boolean obj1Known, obj2Known;
    unsigned int obj1Index, obj2Index;
    
    if (object1 == object2)
        return NSOrderedSame;
    
    obj1Index = obj2Index = 0;
    obj1Known = CFDictionaryGetValueIfPresent(context.sortOrdering, object1, (const void **)&obj1Index);
    obj2Known = CFDictionaryGetValueIfPresent(context.sortOrdering, object2, (const void **)&obj2Index);

    if (obj1Known) {
        if (obj2Known) {
            if (obj1Index < obj2Index)
                return NSOrderedAscending;
            else {
                OBASSERT(obj1Index != obj2Index);
                return NSOrderedDescending;
            }
        } else
            return context.putUnknownObjectsAtFront ? NSOrderedDescending : NSOrderedAscending;
    } else {
        if (obj2Known)
            return context.putUnknownObjectsAtFront ? NSOrderedAscending : NSOrderedDescending;
        else
            return NSOrderedSame;
    }
}

- (void)sortBasedOnOrderInArray:(NSArray *)ordering identical:(BOOL)usePointerEquality unknownAtFront:(BOOL)putUnknownObjectsAtFront;
{
    struct sortOrderingContext context;
    unsigned int orderingCount = [ordering count], orderingIndex;
    
    context.putUnknownObjectsAtFront = putUnknownObjectsAtFront;
    context.sortOrdering = CFDictionaryCreateMutable(kCFAllocatorDefault, orderingCount,
                                                     usePointerEquality? &OFNonOwnedPointerDictionaryKeyCallbacks : &OFNSObjectDictionaryKeyCallbacks,
                                                     &OFIntegerDictionaryValueCallbacks);
    for(orderingIndex = 0; orderingIndex < orderingCount; orderingIndex++)
        CFDictionaryAddValue(context.sortOrdering, [ordering objectAtIndex:orderingIndex], (void *)orderingIndex);
    [self sortUsingFunction:&orderObjectsBySavedIndex context:&context];
    CFRelease(context.sortOrdering);
}


/* Assumes the array is already sorted to insert the object quickly in the right place */
/* (new objects are inserted just after old objects that are NSOrderedSame) */
- (void)insertObject:anObject inArraySortedUsingSelector:(SEL)selector;
{
    unsigned int low = 0;
    unsigned int range = 1;
    unsigned int test = 0;
    unsigned int count = [self count];
    NSComparisonResult result;
    IMP insertedImpOfSel = [anObject methodForSelector:selector];
    IMP objectAtIndexImp = [self methodForSelector:@selector(objectAtIndex:)];

    while (count >= range) /* range is the lowest power of 2 > count */
        range <<= 1;

    while (range) {
        test = low + (range >>= 1);
        if (test >= count)
            continue;
        result = (NSComparisonResult)insertedImpOfSel(anObject, selector, 
			objectAtIndexImp(self, @selector(objectAtIndex:), test));
        if (result == NSOrderedDescending)
            low = test+1;
    }
    [self insertObject:anObject atIndex:low];
}    

/* Assumes the array is already sorted to find the object quickly and remove it */
- (void)removeObject: (id)anObject fromArraySortedUsingSelector:(SEL)selector
{
    unsigned index;
    
    index = [self indexOfObject: anObject inArraySortedUsingSelector: selector];
    if (index != NSNotFound)
        [self removeObjectAtIndex: index];
}


struct sortOnAttributeContext {
    SEL getAttribute;
    SEL compareAttributes;
};

static int doCompareOnAttribute(id a, id b, void *ctxt)
{
    SEL getAttribute = ((struct sortOnAttributeContext *)ctxt)->getAttribute;
    SEL compareAttributes = ((struct sortOnAttributeContext *)ctxt)->compareAttributes;
    id attributeA, attributeB;

    attributeA = [a performSelector:getAttribute];
    attributeB = [b performSelector:getAttribute];

    return (int)[attributeA performSelector:compareAttributes withObject:attributeB];
}
    
- (void)sortOnAttribute:(SEL)fetchAttributeSelector usingSelector:(SEL)comparisonSelector
{
    struct sortOnAttributeContext sortContext;

    sortContext.getAttribute = fetchAttributeSelector;
    sortContext.compareAttributes = comparisonSelector;

    [self sortUsingFunction:doCompareOnAttribute context:&sortContext];
}

@end
