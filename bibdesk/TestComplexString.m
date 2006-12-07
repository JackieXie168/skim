//
//  TestComplexString.m
//  Bibdesk
//
//  Created by Michael McCracken on 12/25/04.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "TestComplexString.h"

@implementation TestStringNode

- (void)testNumberFromBibTeXString{
    BDSKStringNode *sn = [BDSKStringNode nodeWithBibTeXString:@"14"];
    UKNotNil(sn);
    UKIntsEqual(BSN_NUMBER, [sn type]);
    UKStringsEqual(@"14", [sn value]);
}

- (void)testStringFromBibTeXString{
    BDSKStringNode *sn = [BDSKStringNode nodeWithBibTeXString:@"{string}"];
    
    UKNotNil(sn);
    UKIntsEqual(BSN_STRING, [sn type]);
    UKStringsEqual(@"string", [sn value]);
}

- (void)testMacroFromBibTeXString{
    BDSKStringNode *sn = [BDSKStringNode nodeWithBibTeXString:@"macro"];
    
    UKNotNil(sn);
    UKIntsEqual(BSN_MACRODEF, [sn type]);
    UKStringsEqual(@"macro", [sn value]);
}

@end

@interface ResolverMock : NSObject <BDSKMacroResolver> {
    NSDictionary *dict;
}
@end

@implementation TestComplexString

- (void)testLoneMacroFromBibTeXString{
    NSString *cs = [NSString complexStringWithBibTeXString:@"macro1"
											 macroResolver:[[[ResolverMock alloc] init] autorelease]];
    
    UKNotNil(cs);
    UKTrue([cs isComplex]);
    UKStringsEqual(@"expansion1", (NSString *)cs);
}

- (void)testQuotedStringFromBibTeXString{
    NSString *cs = [NSString complexStringWithBibTeXString:@"{quoted string}"
											 macroResolver:[[[ResolverMock alloc] init] autorelease]];
    UKNotNil(cs);
    UKFalse([cs isComplex]);
    UKStringsEqual(@"quoted string", (NSString *)cs);
}

- (void)testLoneNumberFromBibTeXString{
     NSString *cs = [NSString complexStringWithBibTeXString:@"14"
											  macroResolver:[[[ResolverMock alloc] init] autorelease]];
    UKNotNil(cs);
    UKTrue([cs isComplex]);
    UKStringsEqual(@"14", (NSString *)cs);
}

- (void)testTwoNumbersFromBibTeXString{
    NSString *cs = [NSString complexStringWithBibTeXString:@"14 # 14"
											 macroResolver:[[[ResolverMock alloc] init] autorelease]];
    UKNotNil(cs);
    UKTrue([cs isComplex]);
    UKStringsEqual(@"1414", (NSString *)cs);
}

- (void)testThreeNumbersFromBibTeXString{
    NSString *cs = [NSString complexStringWithBibTeXString:@"14 # 14 # 14"
											 macroResolver:[[[ResolverMock alloc] init] autorelease]];
    UKNotNil(cs);
    UKTrue([cs isComplex]);
    UKStringsEqual(@"141414", (NSString *)cs);
}

- (void)testQuotedNestedStringFromBibTeXString{
    NSString *cs = [NSString complexStringWithBibTeXString:@"{quoted {nested} string}"
											 macroResolver:[[[ResolverMock alloc] init] autorelease]];
    UKNotNil(cs);
    UKFalse([cs isComplex]);
    UKStringsEqual(@"quoted {nested} string", (NSString *)cs);
}

- (void)testQuotedNestedConcatenatedStringFromBibTeXString{
    NSString *cs = [NSString complexStringWithBibTeXString:@"{A } # {quoted {nested} string} # {dood}"
											 macroResolver:[[[ResolverMock alloc] init] autorelease]];
    UKNotNil(cs);
    UKTrue([cs isComplex]);
    UKStringsEqual(@"A quoted {nested} stringdood", (NSString *)cs);
    UKNotNil([(BDSKComplexString*)cs nodes]);
    UKIntsEqual(3, [[(BDSKComplexString*)cs nodes] count]);
}

- (void)testEmptyStringFromBibTeXString{
    NSString *cs = [NSString complexStringWithBibTeXString:@""
											 macroResolver:[[[ResolverMock alloc] init] autorelease]];
    UKNotNil(cs);
    UKFalse([cs isComplex]);
    UKStringsEqual(@"", (NSString *)cs);
    UKNil([(BDSKComplexString*)cs nodes]);
}

- (void)testWhitespaceStringFromBibTeXString{
    NSString *cs = [NSString complexStringWithBibTeXString:@" "
											 macroResolver:[[[ResolverMock alloc] init] autorelease]];
    UKNotNil(cs);
    UKFalse([cs isComplex]);
    UKStringsEqual(@"", (NSString *)cs);
    UKNil([(BDSKComplexString*)cs nodes]);
}


- (void)testDisplayTwoNumbers{
    NSArray *a = [NSArray arrayWithObjects:[BDSKStringNode nodeWithBibTeXString:@"14"], 
        [BDSKStringNode nodeWithBibTeXString:@"14"], nil];
    NSString *cs = [NSString complexStringWithArray:a
									  macroResolver:[[[ResolverMock alloc] init] autorelease]];
    UKNotNil(cs);
    UKTrue([cs isComplex]);
    UKStringsEqual(@"1414", (NSString *)cs);
}


- (void)testDisplayThreeNumbers{
    NSArray *a = [NSArray arrayWithObjects:[BDSKStringNode nodeWithBibTeXString:@"14"], 
        [BDSKStringNode nodeWithBibTeXString:@"14"], 
        [BDSKStringNode nodeWithBibTeXString:@"14"], nil];
    NSString *cs = [NSString complexStringWithArray:a
									  macroResolver:[[[ResolverMock alloc] init] autorelease]];
    UKNotNil(cs);
    UKTrue([cs isComplex]);
    UKStringsEqual(@"141414", (NSString *)cs);
}


- (void)testUnquotedStringError{
    // ERROR Here:
    // not sure what I want to get here. Exception?
//    NSString *cs = [NSString complexStringWithBibTeXString:@"unquoted string"
//                                             macroResolver:[[[ResolverMock alloc] init] autorelease]];
//    UKFail();    
}


@end



@implementation ResolverMock

- (id)init{
    if(self = [super init]){
    
        dict = [NSDictionary dictionaryWithObjectsAndKeys:@"expansion1", @"macro1", @"expansion2", @"macro2", nil];
        [dict retain];
    }
    return self;
}

- (void)dealloc{
    [dict release];
    [super dealloc];
}

- (NSString *)valueOfMacro:(NSString *)macro{
    return [dict objectForKey:macro];
}

@end
