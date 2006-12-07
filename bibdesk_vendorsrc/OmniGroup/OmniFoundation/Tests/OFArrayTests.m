// Copyright 2004-2005 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import <Foundation/Foundation.h>
#import <OmniBase/OmniBase.h>
#import <SenTestingKit/SenTestingKit.h>
#import <OmniFoundation/NSArray-OFExtensions.h>
#import <OmniFoundation/NSMutableArray-OFExtensions.h>

RCS_ID("$Header$");

@interface OFSortedArrayManipulations : SenTestCase
{
}


@end

@implementation OFSortedArrayManipulations

// Test cases

- (void)testOrderByArray
{
    NSArray *reference, *empty;
    NSMutableArray *input;
    
    
    reference = [[NSArray alloc] initWithObjects:@"aleph", @"beth", @"gimel", @"he", @"waw", @"zayin", @"het", nil];
    empty = [[NSArray alloc] init];
    input = [[NSMutableArray alloc] initWithObjects:@"waw", @"het", @"gimel", nil];
    
    [input sortBasedOnOrderInArray:reference identical:NO unknownAtFront:NO];
    shouldBeEqual(input, ([NSArray arrayWithObjects:@"gimel", @"waw", @"het", nil]));
    [input sortUsingSelector:@selector(compare:)];
    shouldBeEqual(input, ([NSArray arrayWithObjects:@"gimel", @"het", @"waw", nil]));
    [input addObject:@"nostril"];
    [input sortBasedOnOrderInArray:reference identical:NO unknownAtFront:NO];
    shouldBeEqual(input, ([NSArray arrayWithObjects:@"gimel", @"waw", @"het", @"nostril", nil]));
    [input sortBasedOnOrderInArray:reference identical:NO unknownAtFront:YES];
    shouldBeEqual(input, ([NSArray arrayWithObjects:@"nostril", @"gimel", @"waw", @"het", nil]));
    [input sortBasedOnOrderInArray:[reference reversedArray] identical:NO unknownAtFront:YES];
    shouldBeEqual(input, ([NSArray arrayWithObjects:@"nostril", @"het", @"waw", @"gimel", nil]));
    
    [input removeAllObjects];
    [input sortBasedOnOrderInArray:reference identical:NO unknownAtFront:YES];
    shouldBeEqual(input, empty);
    [input sortBasedOnOrderInArray:reference identical:YES unknownAtFront:YES];
    shouldBeEqual(input, empty);
    [input sortBasedOnOrderInArray:reference identical:YES unknownAtFront:NO];
    shouldBeEqual(input, empty);
    [input sortBasedOnOrderInArray:reference identical:NO unknownAtFront:NO];
    shouldBeEqual(input, empty);
    
    [input sortBasedOnOrderInArray:empty identical:NO unknownAtFront:NO];
    shouldBeEqual(input, empty);

    [input addObject:[NSMutableString stringWithString:@"zayin"]];
    [input sortBasedOnOrderInArray:empty identical:NO unknownAtFront:NO];
    shouldBeEqual(input, [NSArray arrayWithObject:@"zayin"]);
    [input sortBasedOnOrderInArray:empty identical:YES unknownAtFront:YES];
    shouldBeEqual(input, [NSArray arrayWithObject:@"zayin"]);
    
    [input addObject:[reference objectAtIndex:0]];  //aleph
    [input addObject:[reference objectAtIndex:6]];  //het
    [input sortBasedOnOrderInArray:reference identical:NO unknownAtFront:YES];
    shouldBeEqual(input, ([NSArray arrayWithObjects:@"aleph", @"zayin", @"het",nil]));
    [input sortBasedOnOrderInArray:reference identical:YES unknownAtFront:YES];
    shouldBeEqual(input, ([NSArray arrayWithObjects:@"zayin", @"aleph",@"het",nil]));
    [input sortBasedOnOrderInArray:reference identical:YES unknownAtFront:NO];
    shouldBeEqual(input, ([NSArray arrayWithObjects:@"aleph",@"het",@"zayin",nil]));
    
    [input removeAllObjects];
    [input addObjectsFromArray:reference];
    [input reverse];
    [input sortBasedOnOrderInArray:reference identical:NO unknownAtFront:YES];
    shouldBeEqual(input, reference);
    
    [input release];
    [reference release];
    [empty release];
}

@end


@interface OFArrayConveniencesTests : SenTestCase
{
}

@end

@implementation OFArrayConveniencesTests

// Test cases

- (void)testChooseAny
{
    NSArray *x;
    NSObject *y;
    
    y = [[NSObject alloc] init];
    [y autorelease];
    
    x = [NSArray array];
    should([x anyObject] == nil);
    x = [NSArray arrayWithObject:y];
    should([x anyObject] == y);
    x = [NSArray arrayWithObject:@"y"];
    should([x anyObject] != y);
}

- (void)testReplaceByApplying
{
    NSMutableArray *subj;
    NSArray *counting, *Counting, *middle;

    counting = [[[NSArray alloc] initWithObjects:@"one", @"two", @"three", @"four", @"five", nil] autorelease];
    middle = [NSArray arrayWithObjects:@"one", @"TWO", @"THREE", @"FOUR", @"five", nil];
    Counting = [[[NSArray alloc] initWithObjects:@"One", @"Two", @"Three", @"Four", @"Five", nil] autorelease];

    subj = [NSMutableArray array];
    [subj addObjectsFromArray:counting];
    [subj replaceObjectsInRange:(NSRange){1,3} byApplyingSelector:@selector(uppercaseString)];
    shouldBeEqual(subj, middle);

    [subj removeAllObjects];
    [subj addObjectsFromArray:Counting];
    [subj replaceObjectsInRange:(NSRange){0,5} byApplyingSelector:@selector(lowercaseString)];
    shouldBeEqual(subj, counting);
    [subj replaceObjectsInRange:(NSRange){1,4} byApplyingSelector:@selector(uppercaseString)];
    [subj replaceObjectsInRange:(NSRange){4,1} byApplyingSelector:@selector(lowercaseString)];
    shouldBeEqual(subj, middle);
    [subj replaceObjectsInRange:(NSRange){0,4} byApplyingSelector:@selector(lowercaseString)];
    shouldBeEqual(subj, counting);
    [subj replaceObjectsInRange:(NSRange){0,5} byApplyingSelector:@selector(uppercaseFirst)];
    shouldBeEqual(subj, Counting);
}

- (void)testReverse:(NSArray *)counting giving:(NSArray *)gnitnuoc
{
    NSMutableArray *subj;

    subj = [NSMutableArray array];
    [subj addObjectsFromArray:counting];
    shouldBeEqual(subj, [gnitnuoc reversedArray]);
    [subj reverse];
    shouldBeEqual(subj, gnitnuoc);
    shouldBeEqual(subj, [counting reversedArray]);
    shouldBeEqual([subj reversedArray], counting);
    [subj reverse];
    shouldBeEqual(subj, counting);
    shouldBeEqual([subj reversedArray], [counting reversedArray]);
    shouldBeEqual([subj reversedArray], gnitnuoc);
}

- (void)testReversal
{
    NSArray *forward, *backward;
        
    [self testReverse:[[[NSArray alloc] init] autorelease] giving:[[[NSMutableArray alloc] init] autorelease]];
    
    forward = [NSArray arrayWithObject:@"one"];
    [self testReverse:forward giving:forward];
    
    forward = [[NSArray alloc] initWithObjects:@"one", @"two", nil];
    backward = [[NSArray alloc] initWithObjects:@"two", @"one", nil];
    [self testReverse:forward giving:backward];
    [forward release];
    [backward release];
    
    forward = [[NSArray alloc] initWithObjects:@"one", @"two", @"three", nil];
    backward = [[NSArray alloc] initWithObjects:@"three", @"two", @"one", nil];
    [self testReverse:forward giving:backward];
    [forward release];
    [backward release];
    
    forward = [[NSArray alloc] initWithObjects:@"oscillate", @"my", @"metallic", @"sonatas", nil];
    backward = [[NSArray alloc] initWithObjects:@"sonatas", @"metallic", @"my", @"oscillate", nil];
    [self testReverse:forward giving:backward];
    [forward release];
    [backward release];
    
    forward = [[NSArray alloc] initWithObjects:@"one", @"two", @"three", @"four", @"Fibonacci", nil];
    backward = [[NSArray alloc] initWithObjects:@"Fibonacci", @"four", @"three", @"two", @"one", nil];
    [self testReverse:forward giving:backward];
    [forward release];
    [backward release];
}

- (void)testGrouping
{
    NSArray *a;
    OFMultiValueDictionary *grouped;
    
    a = [NSArray arrayWithObjects:@"one", @"THREE", @"FOUR", @"five", @"two", @"three", @"four", @"Two", @"Three", @"Four", @"five", nil];
    
    grouped = [a groupBySelector:@selector(lowercaseString)];
    shouldBeEqual(([NSSet setWithArray:[grouped allKeys]]), 
                  ([NSSet setWithObjects:@"one", @"two", @"three", @"four", @"five", nil]));
    shouldBeEqual(([grouped arrayForKey:@"one"]), 
                  ([NSArray arrayWithObject:@"one"]));
    shouldBeEqual(([grouped arrayForKey:@"two"]), 
                  ([NSArray arrayWithObjects:@"two", @"Two", nil]));
    shouldBeEqual(([grouped arrayForKey:@"three"]), 
                  ([NSArray arrayWithObjects:@"THREE", @"three", @"Three", nil]));
    shouldBeEqual(([grouped arrayForKey:@"four"]), 
                  ([NSArray arrayWithObjects:@"FOUR", @"four", @"Four", nil]));
    shouldBeEqual(([grouped arrayForKey:@"five"]), 
                  ([NSArray arrayWithObjects:@"five", @"five", nil]));

    grouped = [a groupBySelector:@selector(stringByTrimmingCharactersInSet:) withObject:[NSCharacterSet characterSetWithCharactersInString:@"Ttoe"]];
    shouldBeEqual(([NSSet setWithArray:[grouped allKeys]]), 
                  ([NSSet setWithObjects:@"n", @"HREE", @"FOUR", @"fiv", @"four", @"w", @"hr", @"Four", nil]));
    shouldBeEqual(([grouped arrayForKey:@"n"]), 
                  ([NSArray arrayWithObject:@"one"]));
    shouldBeEqual(([grouped arrayForKey:@"HREE"]), 
                  ([NSArray arrayWithObject:@"THREE"]));
    shouldBeEqual(([grouped arrayForKey:@"FOUR"]), 
                  ([NSArray arrayWithObject:@"FOUR"]));
    shouldBeEqual(([grouped arrayForKey:@"fiv"]), 
                  ([NSArray arrayWithObjects:@"five", @"five", nil]));
    shouldBeEqual(([grouped arrayForKey:@"four"]), 
                  ([NSArray arrayWithObject:@"four"]));
    shouldBeEqual(([grouped arrayForKey:@"w"]), 
                  ([NSArray arrayWithObjects:@"two", @"Two", nil]));
    shouldBeEqual(([grouped arrayForKey:@"hr"]), 
                  ([NSArray arrayWithObjects:@"three", @"Three", nil]));
    shouldBeEqual(([grouped arrayForKey:@"Four"]), 
                  ([NSArray arrayWithObject:@"Four"]));
}

- (void)testContains
{
    NSArray *a;
    a = [NSArray arrayWithObjects:@"one", @"THREE", @"FOUR", @"five", @"two", @"three", @"four", @"Two", @"Three", @"Four", @"five", nil];
    
    should((  [a containsObjectsInOrder:[NSArray arrayWithObjects:@"one", @"five", nil]]));
    should((  [a containsObjectsInOrder:[NSArray arrayWithObjects:@"Four", @"five", nil]]));
    shouldnt(([a containsObjectsInOrder:[NSArray arrayWithObjects:@"Four", @"Four", nil]]));
    should((  [a containsObjectsInOrder:[NSArray arrayWithObject:@"two"]]));
    should((  [a containsObjectsInOrder:[NSArray array]]));
    should((  [[NSArray array] containsObjectsInOrder:[NSArray array]]));
    shouldnt(([[NSArray array] containsObjectsInOrder:[NSArray arrayWithObject:@"two"]]));
    shouldnt(([a containsObjectsInOrder:[a arrayByAddingObject:@"six"]]));
    should((  [[a arrayByAddingObject:@"six"] containsObjectsInOrder:a]));
    should((  [a containsObjectsInOrder:a]));
    should((  [a containsObjectsInOrder:[NSArray arrayWithObjects:@"five", nil]]));
    should((  [a containsObjectsInOrder:[NSArray arrayWithObjects:@"five", @"five", nil]]));
    shouldnt(([a containsObjectsInOrder:[NSArray arrayWithObjects:@"five", @"five", @"five", nil]]));
}

@end


