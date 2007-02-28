// Copyright 2002-2006 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import <OmniFoundation/OmniFoundation.h>
#import <OmniBase/OmniBase.h>
#define STEnableDeprecatedAssertionMacros
#import <SenTestingKit/SenTestingKit.h>

RCS_ID("$Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/OmniSourceRelease_2006-09-07/OmniGroup/Frameworks/OmniFoundation/Tests/OFDateTestCase.m 79087 2006-09-07 23:37:02Z kc $")

@interface OFDateTestCase : SenTestCase
{
}

- (NSCalendarDate *)parseDate:(NSString *)spec;
- (void)testRoundingToHHMM:(NSArray *)testCase;
- (void)testRoundingToDOW:(NSArray *)testCase;

/* Generic methods */
+ (SenTest *)dataDrivenTestSuite;
+ (SenTest *)testSuiteForMethod:(NSString *)methodName cases:(NSArray *)testCases;

@end

@implementation OFDateTestCase

- (NSCalendarDate *)parseDate:(NSString *)spec
{
    // Parses a date with either a numeric offset time zone, or a symbolic time zone (which may carry DST behavior with it).

    NSCalendarDate *result;

    // We need to parse using the numeric time zone format first; otherwise, the date will acquire the current local time zone, which is not what we want.

    result = [[NSCalendarDate alloc] initWithString:spec]; // implicit format: "%Y-%m-%d %H:%M:%S %z"
    if (!result)
        result = [[NSCalendarDate alloc] initWithString:spec calendarFormat:@"%Y-%m-%d %H:%M:%S %Z"];  // try parsing symbolic date

    if (!result) {
        fail1(([NSString stringWithFormat:@"Cannot parse \"%@\" as NSCalendarDate", spec]));
    }

    return result;
}

- (void)testRoundingToHHMM:(NSArray *)testCase;
{
    NSCalendarDate *input, *desired, *output;
    int hour, minute;

    input = [self parseDate:[testCase objectAtIndex:0]];
    hour = [[testCase objectAtIndex:1] intValue];
    minute = [[testCase objectAtIndex:2] intValue];
    desired = [self parseDate:[testCase objectAtIndex:3]];

    output = [input dateByRoundingToHourOfDay:hour minute:minute];

    shouldBeEqual1(output, desired,
                   ([NSString stringWithFormat:@"RoundToHHMM%@", [testCase description]]));
}

- (void)testRoundingToDOW:(NSArray *)testCase;
{
    NSCalendarDate *input, *desired, *output;
    int dayOfWeek;

    input = [self parseDate:[testCase objectAtIndex:0]];
    dayOfWeek = [[testCase objectAtIndex:1] intValue];
    desired = [self parseDate:[testCase objectAtIndex:2]];

    output = [input dateByRoundingToDayOfWeek:dayOfWeek];

    shouldBeEqual1(output, desired,
                   ([NSString stringWithFormat:@"RoundToDOW%@", [testCase description]]));
}


// TODO: This is a generic plist-driven test suite generator; move it to a superclass.
+ (SenTest *)dataDrivenTestSuite
{
    NSString *casesPath;
    NSDictionary *allTestCases;
    NSEnumerator *methodEnumerator;
    NSString *methodName;
    SenTestSuite *suite;

    casesPath = [[NSBundle bundleForClass:self] pathForResource:[self description] ofType:@"tests"];
    allTestCases = [NSDictionary dictionaryWithContentsOfFile:casesPath];
    if (!allTestCases) {
        [NSException raise:NSGenericException format:@"Unable to load test cases for class %@ from path: \"%@\"", [self description], casesPath];
        return nil;
    }

    suite = [[SenTestSuite alloc] initWithName:[casesPath lastPathComponent]];
    [suite autorelease];
    
    methodEnumerator = [allTestCases keyEnumerator];
    while( (methodName = [methodEnumerator nextObject]) != nil ) {
        [suite addTest:[self testSuiteForMethod:methodName cases:[allTestCases objectForKey:methodName]]];
    }

    return suite;
}

+ (SenTest *)testSuiteForMethod:(NSString *)methodName cases:(NSArray *)testCases
{
    SEL method;
    NSMethodSignature *methodSignature;
    SenTestSuite *suite;
    unsigned caseIndex, caseCount;

    method = NSSelectorFromString([methodName stringByAppendingString:@":"]);
    if (method == NULL || ![self instancesRespondToSelector:method]) {
        [NSException raise:NSGenericException format:@"Unimplemented method -[%@ %@:] referenced in test case file", [self description], methodName];
    }
    methodSignature = [self instanceMethodSignatureForSelector:method];
    if (!methodSignature ||
        [methodSignature numberOfArguments] != 3 || /* 3 args: self, _cmd, and the test case */
        strcmp([methodSignature methodReturnType], "v") != 0) {
        [NSException raise:NSGenericException format:@"Method -[%@ %@:] referenced in test case file has incorrect signature", [self description], methodName];
    }

    suite = [[SenTestSuite alloc] initWithName:methodName];
    [suite autorelease];

    caseCount = [testCases count];
    for(caseIndex = 0; caseIndex < caseCount; caseIndex ++) {
        id testArguments = [testCases objectAtIndex:caseIndex];
        NSInvocation *testInvocation;
        SenTestCase *testCase;

        testInvocation = [NSInvocation invocationWithMethodSignature:methodSignature];
        [testInvocation setSelector:method];
        [testInvocation setArgument:&testArguments atIndex:2];
        [testInvocation retainArguments];

        testCase = [self testCaseWithInvocation:testInvocation];
        [suite addTest:testCase];
    }

    return suite;
} 

- (NSString *)name
{
    id firstArg;

    [[self invocation] getArgument:&firstArg atIndex:2];
    
    return [NSString stringWithFormat:@"-[%@ %@%@]", NSStringFromClass([self class]), NSStringFromSelector([[self invocation] selector]), [firstArg description]];
}

+ (id)defaultTestSuite
{
    return [self dataDrivenTestSuite];
}

@end


