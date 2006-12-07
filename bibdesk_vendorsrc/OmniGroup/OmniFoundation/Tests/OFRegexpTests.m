// Copyright 2000-2004 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import <Foundation/Foundation.h>
#import <OmniBase/OmniBase.h>
#import <SenTestingKit/SenTestingKit.h>
#import <OmniFoundation/OFRegularExpression.h>
#import <OmniFoundation/OFRegularExpressionMatch.h>
#import <OmniFoundation/OFStringScanner.h>
#import <stdio.h>

RCS_ID("$Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniFoundation/Tests/OFRegexpTests.m,v 1.16 2004/02/10 04:07:48 kc Exp $")

@interface OFRegexpTests : SenTestCase
{
}

- (void)matchRx:(OFRegularExpression *)rx
       inString:(NSString *)text
      expecting:(NSString *)matchText :(unsigned)location :(unsigned)length;

- (void)scanForPattern:(NSString *)pat
                inText:(NSString *)text
             expecting:(BOOL)findIt :(NSString *)follows;

@end

@implementation OFRegexpTests

- (void)testSubexpressions
{
    OFRegularExpression *rx;
    OFRegularExpressionMatch *match;

    rx = [[OFRegularExpression alloc] initWithString:@"b(a*)(c*)b"];
    should([rx subexpressionCount] == 2);

    match = [rx matchInString:@"bb"];
    should(match != nil);
    shouldBeEqual([match subexpressionAtIndex:0], @"");
    shouldBeEqual([match subexpressionAtIndex:1], @"");
    shouldBeEqual([match matchString], @"bb");

    match = [rx matchInString:@" bcccb"];
    should(match != nil);
    shouldBeEqual([match subexpressionAtIndex:0], @"");
    shouldBeEqual([match subexpressionAtIndex:1], @"ccc");
    shouldBeEqual([match matchString], @"bcccb");

    match = [rx matchInString:@" baaacbaab  "];
    should(match != nil);
    shouldBeEqual([match subexpressionAtIndex:0], @"aaa");
    shouldBeEqual([match subexpressionAtIndex:1], @"c");
    shouldBeEqual([match matchString], @"baaacb");

    match = [rx matchInString:@" baaacabaab  "];
    should(match != nil);
    shouldBeEqual([match matchString], @"baab");

    match = [rx matchInString:@" baaacabcaab  "];
    should(match == nil);

    [rx release];

    rx = [[OFRegularExpression alloc] initWithString:@"a(fo+)?b"];
    should([rx subexpressionCount] == 1);

    match = [rx matchInString:@"afb"];
    should(match == nil);

    match = [rx matchInString:@"abb"];
    should(match != nil);
    shouldBeEqual([match subexpressionAtIndex:0], nil);
    shouldBeEqual([match matchString], @"ab");

    match = [rx matchInString:@"aafooobb"];
    should(match != nil);
    shouldBeEqual([match subexpressionAtIndex:0], @"fooo");
    shouldBeEqual([match matchString], @"afooob");

    [rx release];

    rx = [[OFRegularExpression alloc] initWithString:@"b( (a))?"];
    should([rx subexpressionCount] == 2);

    match = [rx matchInString:@"b a"];
    should(match != nil);

    shouldBeEqual([match subexpressionAtIndex:1], @"a");
    shouldBeEqual([match subexpressionAtIndex:0], @" a");
    shouldBeEqual([match matchString], @"b a");

    match = [match nextMatch];
    should(match == nil);

    match = [rx matchInString:@"a b a b"];
    should(match != nil);

    shouldBeEqual([match subexpressionAtIndex:1], @"a");
    shouldBeEqual([match subexpressionAtIndex:0], @" a");
    shouldBeEqual([match matchString], @"b a");

    match = [match nextMatch];
    should(match != nil);

    shouldBeEqual([match subexpressionAtIndex:1], nil);
    shouldBeEqual([match subexpressionAtIndex:0], nil);
    shouldBeEqual([match matchString], @"b");

    match = [match nextMatch];
    should(match == nil);
    
    [rx release];
}

- (void)matchRx:(OFRegularExpression *)rx inString:(NSString *)text expecting:(NSString *)matchText :(unsigned)location :(unsigned)length
{
    OFRegularExpressionMatch *match;

    match = [rx matchInString:text];
    if (matchText == nil) {
        should(match == nil);
    } else {
        should(match != nil);
        should1(NSEqualRanges([match matchRange], (NSRange){location,length}),
                ([NSString stringWithFormat:@"Got match range={%d,%d}, should be range={%d,%d}",
                    [match matchRange].location, [match matchRange].length, location, length]));
        shouldBeEqual([match matchString], matchText);
    }
}

- (void)testFooPlus
{
    OFRegularExpression *rx = [[OFRegularExpression alloc] initWithString:@"foo+"];

    [self matchRx:rx inString:@"foo"       expecting:@"foo"  :0 :3];
    [self matchRx:rx inString:@"fooo"      expecting:@"fooo" :0 :4];
    [self matchRx:rx inString:@"fofo"      expecting:nil     :0 :0];
    [self matchRx:rx inString:@"foobar"    expecting:@"foo"  :0 :3];
    [self matchRx:rx inString:@"fooobar"   expecting:@"fooo" :0 :4];
    [self matchRx:rx inString:@"foboar"    expecting:nil     :0 :0];
    [self matchRx:rx inString:@"barfoo"    expecting:@"foo"  :3 :3];
    [self matchRx:rx inString:@"barfooo"   expecting:@"fooo" :3 :4];
    [self matchRx:rx inString:@"barfo"     expecting:nil     :0 :0];
    [self matchRx:rx inString:@"fofoobar"  expecting:@"foo"  :2 :3];
    [self matchRx:rx inString:@"fofooobar" expecting:@"fooo" :2 :4];
    [self matchRx:rx inString:@"fofobooar" expecting:nil     :0 :0];
    [self matchRx:rx inString:@"fofoo"     expecting:@"foo"  :2 :3];
    [self matchRx:rx inString:@"fofooo"    expecting:@"fooo" :2 :4];

    [rx release];
}

- (void)testFoPlus
{
    OFRegularExpression *rx = [[OFRegularExpression alloc] initWithString:@"fo+"];

    [self matchRx:rx inString:@"foooooo"      expecting:@"foooooo"  :0 :7];
    [self matchRx:rx inString:@"foofoofooo"   expecting:@"foo"      :0 :3];
    [self matchRx:rx inString:@"ffoofofooo"   expecting:@"foo"      :1 :3];
    [self matchRx:rx inString:@"offoofofooo"  expecting:@"foo"      :2 :3];
    [self matchRx:rx inString:@"offfofofooo"  expecting:@"fo"       :3 :2];
    
    [rx release];
}

- (void)testFoPlusQ
{
    OFRegularExpression *rx = [[OFRegularExpression alloc] initWithString:@"fo+?"];

    [self matchRx:rx inString:@"foooooo"      expecting:@"fo"  :0 :2];
    [self matchRx:rx inString:@"foofoofooo"   expecting:@"fo"  :0 :2];
    [self matchRx:rx inString:@"ffoofofooo"   expecting:@"fo"  :1 :2];
    [self matchRx:rx inString:@"offoofofooo"  expecting:@"fo"  :2 :2];
    [self matchRx:rx inString:@"offfofofooo"  expecting:@"fo"  :3 :2];
    
    [rx release];
}

- (void)scanForPattern:(NSString *)pat inText:(NSString *)text expecting:(BOOL)findIt :(NSString *)follows
{
    OFStringScanner *scan;

    scan = [[OFStringScanner alloc] initWithString:text];
    if (findIt) {
        should([scan scanUpToStringCaseInsensitive:pat]);
    } else {
        shouldnt([scan scanUpToStringCaseInsensitive:pat]);
    }
    shouldBeEqual([scan readLine], follows);
    [scan release];
}

- (void)testCharScanning
{
    [self scanForPattern:@"oof" inText:@"blah blah oof blah" expecting: YES : @"oof blah"];
    [self scanForPattern:@"oof" inText:@"blah blah ooof blah" expecting: YES : @"oof blah"];
    [self scanForPattern:@"fofoo" inText:@"knurd fofoo blurfl" expecting: YES : @"fofoo blurfl"];
    [self scanForPattern:@"fofoo" inText:@"knurd fofofoo blurfl" expecting: YES : @"fofoo blurfl"];
    [self scanForPattern:@"fofoo" inText:@"knurd foofoofoo blurfl" expecting: NO : nil];
}


@end

