// Copyright 1997-2004 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import <OmniFoundation/NSMutableArray-OFExtensions.h>

#import <OmniFoundation/NSArray-OFExtensions.h>

#import <Foundation/Foundation.h>
#import <OmniBase/OmniBase.h>

RCS_ID("$Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniFoundation/OpenStepExtensions.subproj/NSMutableArray-OFExtensions.m,v 1.16 2004/02/10 04:07:45 kc Exp $")

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
