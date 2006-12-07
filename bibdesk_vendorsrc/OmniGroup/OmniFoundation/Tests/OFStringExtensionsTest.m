// Copyright 2004-2005 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import <SenTestingKit/SenTestingKit.h>

#import <OmniBase/OmniBase.h>
#import <OmniFoundation/NSString-OFExtensions.h>
#import <OmniFoundation/NSMutableString-OFExtensions.h>
#import <OmniFoundation/OFUtilities.h>

RCS_ID("$Header$");

@interface OFStringExtensionTest : SenTestCase
@end

@implementation OFStringExtensionTest

- (void)testStringEncodingNames;
{
    const CFStringEncoding *allEncodings = CFStringGetListOfAvailableEncodings();
    CFIndex encodingIndex;
    
    for(encodingIndex = 0; allEncodings[encodingIndex] != kCFStringEncodingInvalidId; encodingIndex ++) {
        CFStringEncoding enc = allEncodings[encodingIndex];
        
        NSString *savable = [NSString defaultValueForCFStringEncoding:enc];
        CFStringEncoding roundTrip = [NSString cfStringEncodingForDefaultValue:savable];
        should1(roundTrip == enc,
                ([NSString stringWithFormat:@"CFEncoding %u encodes to \"%@\" decodes to %u", enc, savable, roundTrip]));
        
        //  kCFStringEncodingShiftJIS_X0213_00 comes through the roundtrip as kCFStringEncodingShiftJIS which produces a spurious(?) failure
    }
    
    should([NSString cfStringEncodingForDefaultValue:@"iana iso-8859-1"] == kCFStringEncodingISOLatin1);
    should([NSString cfStringEncodingForDefaultValue:@"iana utf-8"] == kCFStringEncodingUTF8);
    should([NSString cfStringEncodingForDefaultValue:@"iana UTF-8"] == kCFStringEncodingUTF8);
}



- (void)testAbbreviatedStringForHz;
{
    shouldBeEqual([NSString abbreviatedStringForHertz:0], @"0 Hz");
    shouldBeEqual([NSString abbreviatedStringForHertz:1], @"1 Hz");
    shouldBeEqual([NSString abbreviatedStringForHertz:9], @"9 Hz");
    shouldBeEqual([NSString abbreviatedStringForHertz:10], @"10 Hz");
    shouldBeEqual([NSString abbreviatedStringForHertz:11], @"11 Hz");
    shouldBeEqual([NSString abbreviatedStringForHertz:100], @"100 Hz");
    shouldBeEqual([NSString abbreviatedStringForHertz:990], @"990 Hz");
    shouldBeEqual([NSString abbreviatedStringForHertz:999], @"1.0 KHz");
    shouldBeEqual([NSString abbreviatedStringForHertz:1000], @"1.0 KHz");
    shouldBeEqual([NSString abbreviatedStringForHertz:1099], @"1.1 KHz");
    shouldBeEqual([NSString abbreviatedStringForHertz:1100], @"1.1 KHz");
    shouldBeEqual([NSString abbreviatedStringForHertz:1000000], @"1.0 MHz");
    shouldBeEqual([NSString abbreviatedStringForHertz:10000000], @"10.0 MHz");
    shouldBeEqual([NSString abbreviatedStringForHertz:100000000], @"100.0 MHz");
    shouldBeEqual([NSString abbreviatedStringForHertz:1000000000], @"1.0 GHz");
    shouldBeEqual([NSString abbreviatedStringForHertz:1800000000], @"1.8 GHz");
    shouldBeEqual([NSString abbreviatedStringForHertz:2000000000], @"2.0 GHz");
    shouldBeEqual([NSString abbreviatedStringForHertz:10000000000LL], @"10.0 GHz");
}

- (void)testTrimming
{
    shouldBeEqual([@"" stringByRemovingSurroundingWhitespace], @"");
    shouldBeEqual([@" " stringByRemovingSurroundingWhitespace], @"");
    shouldBeEqual([@"  " stringByRemovingSurroundingWhitespace], @"");
    shouldBeEqual([@"\t\n\r " stringByRemovingSurroundingWhitespace], @"");
    shouldBeEqual([@"foo " stringByRemovingSurroundingWhitespace], @"foo");
    shouldBeEqual([@"foo " stringByRemovingSurroundingWhitespace], @"foo");
    shouldBeEqual([@"foo " stringByRemovingSurroundingWhitespace], @"foo");
    shouldBeEqual([@"foo  " stringByRemovingSurroundingWhitespace], @"foo");
    shouldBeEqual([@" foo " stringByRemovingSurroundingWhitespace], @"foo");
    shouldBeEqual([@"  foo " stringByRemovingSurroundingWhitespace], @"foo");
    shouldBeEqual([@"foo" stringByRemovingSurroundingWhitespace], @"foo");
    shouldBeEqual([@"  foo" stringByRemovingSurroundingWhitespace], @"foo");
    
    NSMutableString *buf = [[[NSMutableString alloc] init] autorelease];
    [buf setString:@""]; [buf removeSurroundingWhitespace]; shouldBeEqual(buf, @"");
    [buf setString:@" "]; [buf removeSurroundingWhitespace]; shouldBeEqual(buf, @"");
    [buf setString:@"  "]; [buf removeSurroundingWhitespace]; shouldBeEqual(buf, @"");
    [buf setString:@"\t\n\r "]; [buf removeSurroundingWhitespace]; shouldBeEqual(buf, @"");
    [buf setString:@"foo "]; [buf removeSurroundingWhitespace]; shouldBeEqual(buf, @"foo");
    [buf setString:@"foo  "]; [buf removeSurroundingWhitespace]; shouldBeEqual(buf, @"foo");
    [buf setString:@" foo "]; [buf removeSurroundingWhitespace]; shouldBeEqual(buf, @"foo");
    [buf setString:@"  foo "]; [buf removeSurroundingWhitespace]; shouldBeEqual(buf, @"foo");
    [buf setString:@"foo"]; [buf removeSurroundingWhitespace]; shouldBeEqual(buf, @"foo");
    [buf setString:@"  foo"]; [buf removeSurroundingWhitespace]; shouldBeEqual(buf, @"foo");
}

- (void)testDecimal:(double)d expecting:(NSString *)decimalized :(NSString *)exponential
{
    NSString *t0 = OFCreateDecimalStringFromDouble(d);
    NSString *t1, *t2;
    char *buf;
    
    buf = OFShortASCIIDecimalStringFromDouble(d, OF_FLT_DIGITS_E, NO, YES);
    t1 = (NSString *)CFStringCreateWithCStringNoCopy(kCFAllocatorDefault, buf, kCFStringEncodingASCII, kCFAllocatorMalloc);
    
    buf = OFShortASCIIDecimalStringFromDouble(d, OF_FLT_DIGITS_E, YES, YES);
    t2 = (NSString *)CFStringCreateWithCStringNoCopy(kCFAllocatorDefault, buf, kCFStringEncodingASCII, kCFAllocatorMalloc);
    
    shouldBeEqual(t0, decimalized);
    shouldBeEqual(t1, decimalized);
    if (exponential) {
        shouldBeEqual(t2, exponential);
    } else {
        shouldBeEqual(t2, decimalized);
    }
    
    [t0 release];
    [t1 release];
    [t2 release];
    
    if ([decimalized hasPrefix:@"0."]) {
        buf = OFShortASCIIDecimalStringFromDouble(d, OF_FLT_DIGITS_E, NO, NO);
        t1 = (NSString *)CFStringCreateWithCStringNoCopy(kCFAllocatorDefault, buf, kCFStringEncodingASCII, kCFAllocatorMalloc);
        shouldBeEqual(t1, [decimalized substringFromIndex:1]);
        [t1 release];
    }
}

- (void)testDecimalFormatting
{
    /* There are a crazy number of different cases in formatting a decimal number. This covers them all, I think. */
    
    [self testDecimal:0 expecting:@"0" :nil];
    [self testDecimal:1 expecting:@"1" :nil];
    [self testDecimal:-1 expecting:@"-1" :nil];
    [self testDecimal:10 expecting:@"10" :nil];
    [self testDecimal:-10 expecting:@"-10" :nil];
    [self testDecimal:.1 expecting:@"0.1" :nil];
    [self testDecimal:-.1 expecting:@"-0.1" :nil];
    [self testDecimal:-.01 expecting:@"-0.01" :nil];
    
    [self testDecimal:1e30 expecting:@"1000000000000000000000000000000" :@"1e30"];
    [self testDecimal:1e40 expecting:@"10000000000000000000000000000000000000000" :@"1e40"];
    [self testDecimal:1e50 expecting:@"100000000000000000000000000000000000000000000000000" :@"1e50"];
    [self testDecimal:1e60 expecting:@"1000000000000000000000000000000000000000000000000000000000000" :@"1e60"];
    [self testDecimal:-1e30 expecting:@"-1000000000000000000000000000000" :@"-1e30"];
    [self testDecimal:-1e40 expecting:@"-10000000000000000000000000000000000000000" :@"-1e40"];
    [self testDecimal:-1e50 expecting:@"-100000000000000000000000000000000000000000000000000" :@"-1e50"];
    [self testDecimal:-1e60 expecting:@"-1000000000000000000000000000000000000000000000000000000000000" :@"-1e60"];
    
    [self testDecimal:7e-3 expecting:@"0.007" :@"7e-3"];
    [self testDecimal:-7e-3 expecting:@"-0.007" :@"-7e-3"];
    [self testDecimal:17e-3 expecting:@"0.017" :@"0.017"];
    [self testDecimal:-17e-3 expecting:@"-0.017" :@"-0.017"];
    [self testDecimal:1e-10 expecting:@"0.0000000001" :@"1e-10"];
    [self testDecimal:-1e-10 expecting:@"-0.0000000001" :@"-1e-10"];
    [self testDecimal:1e-20 expecting:@"0.00000000000000000001" :@"1e-20"];
    [self testDecimal:1e-30 expecting:@"0.000000000000000000000000000001" :@"1e-30"];
    [self testDecimal:1e-40 expecting:@"0.0000000000000000000000000000000000000001" :@"1e-40"];
    [self testDecimal:1e-50 expecting:@"0.00000000000000000000000000000000000000000000000001" :@"1e-50"];
    [self testDecimal:1e-60 expecting:@"0.000000000000000000000000000000000000000000000000000000000001" :@"1e-60"];
    [self testDecimal:-1e-60 expecting:@"-0.000000000000000000000000000000000000000000000000000000000001" :@"-1e-60"];
    
    [self testDecimal:1.000001 expecting:@"1.000001" :nil];
    [self testDecimal:-2.000002 expecting:@"-2.000002" :nil];
    
    [self testDecimal:1.000001e20 expecting:@"100000100000000000000" :@"1000001e14"];
    [self testDecimal:-2.000002e20 expecting:@"-200000200000000000000" :@"-2000002e14"];
    [self testDecimal:1.000001e-20 expecting:@"0.00000000000000000001000001" :@"1000001e-26"];
    [self testDecimal:-2.000002e-20 expecting:@"-0.00000000000000000002000002" :@"-2000002e-26"];
    
#define TESTIT(num, expok, force, expect) { char *buf = OFShortASCIIDecimalStringFromDouble(num, OF_FLT_DIGITS_E, expok, force); should1(strcmp(buf, expect) == 0, ([NSString stringWithFormat:@"formatted %g (expok=%d forcelz=%d) got \"%s\" expected \"%s\"", num, expok, force, buf, expect])); free(buf); }
        
    TESTIT(0.017,   1, 0, ".017");
    TESTIT(0.017,   1, 1, "0.017");
    TESTIT(0.0017,  1, 1, "17e-4");
    TESTIT(0.0017,  1, 0, ".0017");
    TESTIT(0.0017,  0, 1, "0.0017");
    TESTIT(0.00017, 1, 0, "17e-5");
    TESTIT(0.00017, 0, 0, ".00017");
    TESTIT(0.00017, 0, 1, "0.00017");
    
#undef TEST
}

- (void)testComponentsSeparatedByCharactersFromSet
{
    NSCharacterSet *delimiterSet = [NSCharacterSet punctuationCharacterSet];
    NSCharacterSet *emptySet = [NSCharacterSet characterSetWithCharactersInString:@""];
    
    shouldBeEqual([@"Hi.there" componentsSeparatedByCharactersFromSet:delimiterSet], ([NSArray arrayWithObjects:@"Hi", @"there", nil]));
    shouldBeEqual([@"Hi.there" componentsSeparatedByCharactersFromSet:emptySet], ([NSArray arrayWithObject:@"Hi.there"]));
    shouldBeEqual([@".Hi.there!" componentsSeparatedByCharactersFromSet:delimiterSet], ([NSArray arrayWithObjects:@"", @"Hi", @"there", @"", nil]));
}

NSString *simpleXMLEscape(NSString *str, NSRange *where, void *dummy)
{
    OBASSERT(where->length == 1);
    unichar ch = [str characterAtIndex:where->location];
    
    switch(ch) {
        case '&':
            return @"&amp;";
        case '<':
            return @"&lt;";
        case '>':
            return @"&gt;";
        case '"':
            return @"&quot;";
        default:
            return [NSString stringWithFormat:@"&#%u;", (unsigned int)ch];
    }
}

NSString *unpair(NSString *str, NSRange *where, void *dummy)
{
    NSRange another;
    
    another.location = NSMaxRange(*where);
    another.length = where->length;
    
    if (NSMaxRange(another) <= [str length]) {
        NSString *p1 = [str substringWithRange:*where];
        NSString *p2 = [str substringWithRange:another];
        if ([p1 isEqualToString:p2]) {
            where->length = NSMaxRange(another) - where->location;
            return p1;
        }
    }
    
    return nil;
}

- (void)testGenericReplace
{
    NSString *t;
    NSCharacterSet *s = [NSCharacterSet characterSetWithCharactersInString:@"<&>"];
    
    t = @"This is a silly ole test.";
    should(t == [t stringByPerformingReplacement:simpleXMLEscape onCharacters:s]);
    
    shouldBeEqual([@"This & that" stringByPerformingReplacement:simpleXMLEscape onCharacters:s], @"This &amp; that");
    shouldBeEqual([@"&" stringByPerformingReplacement:simpleXMLEscape onCharacters:s], @"&amp;");
    shouldBeEqual([@"foo &&" stringByPerformingReplacement:simpleXMLEscape onCharacters:s], @"foo &amp;&amp;");
    shouldBeEqual([@"<&>" stringByPerformingReplacement:simpleXMLEscape onCharacters:s], @"&lt;&amp;&gt;");
    shouldBeEqual([@"<&> beelzebub" stringByPerformingReplacement:simpleXMLEscape onCharacters:[NSCharacterSet characterSetWithCharactersInString:@"< "]], @"&lt;&>&#32;beelzebub");
    
    t = @"This is a silly ole test.";
    should(t == [t stringByPerformingReplacement:unpair onCharacters:s]);
    shouldBeEqual([t stringByPerformingReplacement:unpair onCharacters:[s invertedSet]], @"This is a sily ole test.");
    shouldBeEqual([@"mississippi" stringByPerformingReplacement:unpair onCharacters:[s invertedSet]], @"misisipi");
    shouldBeEqual([@"mmississippi" stringByPerformingReplacement:unpair onCharacters:[NSCharacterSet characterSetWithCharactersInString:@"ms"]], @"misisippi");
    shouldBeEqual([@"mmississippii" stringByPerformingReplacement:unpair onCharacters:[NSCharacterSet characterSetWithCharactersInString:@"ip"]], @"mmississipi");
}

- (void)testGenericReplaceRange
{
    NSCharacterSet *s = [NSCharacterSet characterSetWithCharactersInString:@"<&>"];
    NSString *t = @"We&are<the Lo'lli\"p&>o&''<>p Guild\"";
    
    unsigned int l, r;
    for(r = 0; r < [t length]; r++) {
        NSString *tail = [t substringFromIndex:r];
        for(l = 0; l < r; l++) {
            NSString *head = [t substringToIndex:l];
            NSRange midRange;
            midRange.location = l;
            midRange.length = r - l;
            shouldBeEqual(([NSString stringWithStrings:head, [[t substringWithRange:midRange] stringByPerformingReplacement:simpleXMLEscape onCharacters:s], tail, nil]),
                          [t stringByPerformingReplacement:simpleXMLEscape onCharacters:s context:NULL options:0 range:midRange]);
        }
    }
}

@end

