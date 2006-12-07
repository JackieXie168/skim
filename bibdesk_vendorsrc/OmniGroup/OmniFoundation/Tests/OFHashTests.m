// Copyright 2003-2004 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import <OmniFoundation/NSData-OFExtensions.h>
#import <Foundation/Foundation.h>
#import <OmniBase/rcsid.h>
#import <SenTestingKit/SenTestingKit.h>

RCS_ID("$Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniFoundation/Tests/OFHashTests.m,v 1.3 2004/02/10 04:07:48 kc Exp $");

@interface OFHashTests : SenTestCase
{
}

@end

@implementation OFHashTests

- (void)testFIPS180_1
{
    NSMutableData *oneMillionAs;
    NSArray *expectedResults;

    expectedResults = [@"( <A9993E36 4706816A BA3E2571 7850C26C 9CD0D89D>, <84983E44 1C3BD26E BAAE4AA1 F95129E5 E54670F1>, <34AA973C D4C4DAA4 F61EEB2B DBAD2731 6534016F> )" propertyList];
    should([expectedResults count] == 3);

    shouldBeEqual([[@"abc" dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:NO] sha1Signature], [expectedResults objectAtIndex:0]);
    shouldBeEqual([[@"abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq" dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:NO] sha1Signature], [expectedResults objectAtIndex:1]);

    oneMillionAs = [[NSMutableData alloc] initWithLength:1000000];
    memset([oneMillionAs mutableBytes], 'a', [oneMillionAs length]);
    shouldBeEqual([oneMillionAs sha1Signature], [expectedResults objectAtIndex:2]);
    [oneMillionAs release];
}

#if 0
- (void)testGilloglyGrieu
{
    /* See: http://www.chiark.greenend.org.uk/pipermail/ukcrypto/1999-February/003538.html */
}
#endif

NSString *md5string(NSString *input)
{
    return [[[input dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:NO] md5Signature] unadornedLowercaseHexString];
}

- (void)testRFC1321
{
    shouldBeEqual([[[NSData data] md5Signature] unadornedLowercaseHexString],
                  @"d41d8cd98f00b204e9800998ecf8427e");

    shouldBeEqual(md5string(@"a"),
                  @"0cc175b9c0f1b6a831c399e269772661");

    shouldBeEqual(md5string(@"abc"),
                  @"900150983cd24fb0d6963f7d28e17f72");

    shouldBeEqual(md5string(@"message digest"),
                  @"f96b697d7cb7938d525a2f31aaf161d0");

    shouldBeEqual(md5string(@"abcdefghijklmnopqrstuvwxyz"),
                  @"c3fcd3d76192e4007dfb496cca67e13b");

    shouldBeEqual(md5string(@"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"),
                  @"d174ab98d277d9f5a5611c2c9f419d9f");

    shouldBeEqual(md5string(@"12345678901234567890123456789012345678901234567890123456789012345678901234567890"),
                  @"57edf4a22be3c955ac49da2e2107b67a");
}

@end

