//
//  TestComplexString.m
//  BibDesk
//
//  Created by Michael McCracken on 12/25/04.
/*
 This software is Copyright (c) 2004,2005,2006,2007
 Michael O. McCracken. All rights reserved.

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:

 - Redistributions of source code must retain the above copyright
   notice, this list of conditions and the following disclaimer.

 - Redistributions in binary form must reproduce the above copyright
    notice, this list of conditions and the following disclaimer in
    the documentation and/or other materials provided with the
    distribution.

 - Neither the name of Michael O. McCracken nor the names of any
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
    NSString *cs = [NSString stringWithBibTeXString:@"macro1"
											 macroResolver:[[[ResolverMock alloc] init] autorelease]];
    
    UKNotNil(cs);
    UKTrue([cs isComplex]);
    UKStringsEqual(@"expansion1", (NSString *)cs);
}

- (void)testQuotedStringFromBibTeXString{
    NSString *cs = [NSString stringWithBibTeXString:@"{quoted string}"
											 macroResolver:[[[ResolverMock alloc] init] autorelease]];
    UKNotNil(cs);
    UKFalse([cs isComplex]);
    UKStringsEqual(@"quoted string", (NSString *)cs);
}

- (void)testLoneNumberFromBibTeXString{
     NSString *cs = [NSString stringWithBibTeXString:@"14"
											  macroResolver:[[[ResolverMock alloc] init] autorelease]];
    UKNotNil(cs);
    UKTrue([cs isComplex]);
    UKStringsEqual(@"14", (NSString *)cs);
}

- (void)testTwoNumbersFromBibTeXString{
    NSString *cs = [NSString stringWithBibTeXString:@"14 # 14"
											 macroResolver:[[[ResolverMock alloc] init] autorelease]];
    UKNotNil(cs);
    UKTrue([cs isComplex]);
    UKStringsEqual(@"1414", (NSString *)cs);
}

- (void)testThreeNumbersFromBibTeXString{
    NSString *cs = [NSString stringWithBibTeXString:@"14 # 14 # 14"
											 macroResolver:[[[ResolverMock alloc] init] autorelease]];
    UKNotNil(cs);
    UKTrue([cs isComplex]);
    UKStringsEqual(@"141414", (NSString *)cs);
}

- (void)testQuotedNestedStringFromBibTeXString{
    NSString *cs = [NSString stringWithBibTeXString:@"{quoted {nested} string}"
											 macroResolver:[[[ResolverMock alloc] init] autorelease]];
    UKNotNil(cs);
    UKFalse([cs isComplex]);
    UKStringsEqual(@"quoted {nested} string", (NSString *)cs);
}

- (void)testQuotedNestedConcatenatedStringFromBibTeXString{
    NSString *cs = [NSString stringWithBibTeXString:@"{A } # {quoted {nested} string} # {dood}"
											 macroResolver:[[[ResolverMock alloc] init] autorelease]];
    UKNotNil(cs);
    UKTrue([cs isComplex]);
    UKStringsEqual(@"A quoted {nested} stringdood", (NSString *)cs);
    UKNotNil([(BDSKComplexString*)cs nodes]);
    UKIntsEqual(3, [[(BDSKComplexString*)cs nodes] count]);
}

- (void)testEmptyStringFromBibTeXString{
    NSString *cs = [NSString stringWithBibTeXString:@""
											 macroResolver:[[[ResolverMock alloc] init] autorelease]];
    UKNotNil(cs);
    UKFalse([cs isComplex]);
    UKStringsEqual(@"", (NSString *)cs);
    UKNil([(BDSKComplexString*)cs nodes]);
}

- (void)testWhitespaceStringFromBibTeXString{
    NSString *cs = [NSString stringWithBibTeXString:@" "
											 macroResolver:[[[ResolverMock alloc] init] autorelease]];
    UKNotNil(cs);
    UKFalse([cs isComplex]);
    UKStringsEqual(@"", (NSString *)cs);
    UKNil([(BDSKComplexString*)cs nodes]);
}


- (void)testDisplayTwoNumbers{
    NSArray *a = [NSArray arrayWithObjects:[BDSKStringNode nodeWithBibTeXString:@"14"], 
        [BDSKStringNode nodeWithBibTeXString:@"14"], nil];
    NSString *cs = [NSString stringWithNodes:a
									  macroResolver:[[[ResolverMock alloc] init] autorelease]];
    UKNotNil(cs);
    UKTrue([cs isComplex]);
    UKStringsEqual(@"1414", (NSString *)cs);
}


- (void)testDisplayThreeNumbers{
    NSArray *a = [NSArray arrayWithObjects:[BDSKStringNode nodeWithBibTeXString:@"14"], 
        [BDSKStringNode nodeWithBibTeXString:@"14"], 
        [BDSKStringNode nodeWithBibTeXString:@"14"], nil];
    NSString *cs = [NSString stringWithNodes:a
									  macroResolver:[[[ResolverMock alloc] init] autorelease]];
    UKNotNil(cs);
    UKTrue([cs isComplex]);
    UKStringsEqual(@"141414", (NSString *)cs);
}


- (void)testUnquotedStringError{
    // ERROR Here:
    // not sure what I want to get here. Exception?
//    NSString *cs = [NSString stringWithBibTeXString:@"unquoted string"
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
