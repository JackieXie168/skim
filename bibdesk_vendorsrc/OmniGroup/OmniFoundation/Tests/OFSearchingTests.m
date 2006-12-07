// Copyright 2003-2005 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import <Foundation/Foundation.h>
#import <OmniBase/rcsid.h>
#import <OmniFoundation/NSData-OFExtensions.h>
#import <OmniFoundation/NSString-OFExtensions.h>
#import <SenTestingKit/SenTestingKit.h>

RCS_ID("$Header$");

@interface OFDataSearch : SenTestCase
{
}


@end

@implementation OFDataSearch

// Test cases

- (void)testContainsData
{
    NSData *txt1 = [[NSData alloc] initWithBytesNoCopy:"xymoofbarbaz" length:12 freeWhenDone:NO];
    NSData *txt2 = [[NSData alloc] initWithBytesNoCopy:"ommoonymooof" length:12 freeWhenDone:NO];
    NSData *txt3 = [[NSData alloc] initWithBytesNoCopy:"moomoomoof"   length:10 freeWhenDone:NO];
    NSData *txt4 = [[NSData alloc] initWithBytesNoCopy:"moolaflmo"    length:9 freeWhenDone:NO];

    NSData *pat1 = [[NSData alloc] initWithBytesNoCopy:"moof"   length:4 freeWhenDone:NO];
    NSData *pat2 = [[NSData alloc] initWithBytesNoCopy:"om"     length:2 freeWhenDone:NO];

#define shouldEqualRange(expr, loc, len) should1(NSEqualRanges(expr, (NSRange){loc,len}), ([NSString stringWithFormat:@"%s == %@", #expr, NSStringFromRange(expr)]))

    should([txt1 containsData:pat1]);
    shouldEqualRange([txt1 rangeOfData:pat1],  2, 4 );
    shouldnt([txt1 containsData:pat2]);
    shouldEqualRange([txt1 rangeOfData:pat2], NSNotFound, 0 );

    shouldnt([txt2 containsData:pat1]);
    shouldEqualRange([txt2 rangeOfData:pat1], NSNotFound, 0 );
    should([txt2 containsData:pat2]);
    shouldEqualRange([txt2 rangeOfData:pat2], 0, 2 );

    should([txt3 containsData:pat1]);
    shouldEqualRange([txt3 rangeOfData:pat1], 6, 4 );
    should([txt3 containsData:pat2]);
    shouldEqualRange([txt3 rangeOfData:pat2], 2, 2 );

    shouldnt([txt4 containsData:pat1]);
    shouldEqualRange([txt4 rangeOfData:pat1], NSNotFound, 0 );
    shouldnt([txt4 containsData:pat2]);
    shouldEqualRange([txt4 rangeOfData:pat2], NSNotFound, 0 );

    [txt1 release];
    [txt2 release];
    [txt3 release];
    [txt4 release];

    [pat1 release];
    [pat2 release];
}

@end

@interface OFStringSplitting : SenTestCase
{
}


@end

@implementation OFStringSplitting

// Test cases

- (void)testLimitedSplit
{
    NSArray *foobar = [NSArray arrayWithObject:@"foo bar"];
    NSArray *foo_bar = [NSArray arrayWithObjects:@"foo", @"bar", nil];
    
    NSArray *foobarx = [NSArray arrayWithObjects:@"foo bar ", nil];
    NSArray *foo_barx = [NSArray arrayWithObjects:@"foo", @"bar ", nil];
    NSArray *foo_bar_ = [NSArray arrayWithObjects:@"foo", @"bar", @"", nil];

    shouldBeEqual([@"foo bar" componentsSeparatedByString:@" " maximum:4], foo_bar);
    shouldBeEqual([@"foo bar" componentsSeparatedByString:@" " maximum:3], foo_bar);
    shouldBeEqual([@"foo bar" componentsSeparatedByString:@" " maximum:2], foo_bar);
    shouldBeEqual([@"foo bar" componentsSeparatedByString:@" " maximum:1], foobar);

    shouldBeEqual([@"foo bar " componentsSeparatedByString:@" " maximum:4], foo_bar_);
    shouldBeEqual([@"foo bar " componentsSeparatedByString:@" " maximum:3], foo_bar_);
    shouldBeEqual([@"foo bar " componentsSeparatedByString:@" " maximum:2], foo_barx);
    shouldBeEqual([@"foo bar " componentsSeparatedByString:@" " maximum:1], foobarx);

    shouldBeEqual([@"oofoo bar" componentsSeparatedByString:@"oo" maximum:3],
                  ([NSArray arrayWithObjects:@"", @"f", @" bar", nil]));
    shouldBeEqual([@"oofoo bar" componentsSeparatedByString:@"oo" maximum:2],
                  ([NSArray arrayWithObjects:@"", @"foo bar", nil]));

    shouldBeEqual([@"foo bar " componentsSeparatedByString:@"z" maximum:3], foobarx);
    shouldBeEqual([@"foo bar " componentsSeparatedByString:@"z" maximum:1], foobarx);

    shouldBeEqual([@"::::" componentsSeparatedByString:@":" maximum:6],
                  ([NSArray arrayWithObjects:@"", @"", @"", @"", @"", nil]));
    shouldBeEqual([@"::::" componentsSeparatedByString:@":" maximum:5],
                  ([NSArray arrayWithObjects:@"", @"", @"", @"", @"", nil]));
    shouldBeEqual([@"::::" componentsSeparatedByString:@":" maximum:4],
                  ([NSArray arrayWithObjects:@"", @"", @"", @":", nil]));
}

@end


