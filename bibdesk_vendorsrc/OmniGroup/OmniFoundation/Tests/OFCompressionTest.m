// Copyright 2004-2006 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#define STEnableDeprecatedAssertionMacros
#import <SenTestingKit/SenTestingKit.h>

#import <OmniBase/rcsid.h>
#import <OmniFoundation/NSData-OFExtensions.h>
#import <OmniFoundation/OFRandom.h>
#import <OmniBase/OmniBase.h>
#import <unistd.h>
#import <fcntl.h>

RCS_ID("$Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/OmniSourceRelease_2006-09-07/OmniGroup/Frameworks/OmniFoundation/Tests/OFCompressionTest.m 79087 2006-09-07 23:37:02Z kc $");

@interface OFCompressionTest : SenTestCase

- (void)doTestWithData:(NSData *)d;

@end

@interface OFBzip2CompressionTest : OFCompressionTest
@end

@interface OFGzipCompressionTest : OFCompressionTest
@end


static NSData *utf8(NSString *str)
{
    return [str dataUsingEncoding:NSUTF8StringEncoding];
}

@implementation OFCompressionTest

+ (id) defaultTestSuite
{
    // This abstract class doesn't have a test suite.
    if (self == [OFCompressionTest class])
        return nil;
    else
        return [super defaultTestSuite];
}

- (void)doTestWithData:(NSData *)d;
{
    OBRequestConcreteImplementation(self, _cmd);
}

#define TEST_DATA(data) [self doTestWithData:(data)]
#define TEST_STRING(str) TEST_DATA(utf8(str))

- (void)testCompressionFixedStrings;
{
    TEST_STRING(@"abcdefghijklmnopqrstuvwxyz abcdefghijklmnopqrstuvwxyz abcdefghijklmnopqrstuvwxyz abcdefghijklmnopqrstuvwxyz abcdefghijklmnopqrstuvwxyz abcdefghijklmnopqrstuvwxyz abcdefghijklmnopqrstuvwxyz abcdefghijklmnopqrstuvwxyz\n");

    TEST_DATA([NSData data]); // Empty; handled by loop below

    // Some random inputs that failed before...
    TEST_DATA([NSData dataWithBase64String:@"G6B5+eO/FuPsuhBxgZZL/zcnv/i+IBUaDwNbmznaATz5tLa7rTRIpo4HWecJaxXUlol4WxYsUl9QgB2S1pUHaeBSpvW/ao17o9e96kbYZdOK3X2ydg7nKJvtcJz4Lsa4OiQGFoTTs3iZG9GFXHSX1Eruk90DYHY7RrbWmWFRvcXxmYonLBaZw1gir7sdKXr2PfnTqczcn3jfsMI4N24LgmZPG4WIM37KSdf21xQfgyiVRlP516PV2sD2DmG/pJBy2PB7UU4X6MYEBAQL18o3d/KCigNPbTQbfX6sdY365JmeSFa5tVC7LzUdk2aHsnJzMbUX9mLcvrAcMNytIZjz3LPPPVizRuEKivQBG6TZMCZKD7gd4N7YB+CN5lbnkOEAA7gFWcZp69uDKxYl8MeH9BkebipV8aS5OeTfK+4NTLBIv5KvI6Ffg1ffqslsMsJBnvMdAp0gcW4gRxCbBO5awCJytL5wGJ9iWEfsv2tXmoEm+djuxEy03KUZVp7Sd2ypRsHBtIFb2xAot/UnxBs3sSOA78ebffcjCEv9SZTbHicmGQSh1IMrP/VQ8DqzY7YiDkgpc3wzCSIU6VkoR6BAjz+DP4PeMUNJqamR4W5MJoHmVDQJDonzcmhQW2aOEuB+MgpkA7fVFxwRYGLEnxSsIpQHKazCFlU4hPay5mCC1NJdHv38J/Cdt7pp/QIAr7g3DTp2P1hqHwLRfYuq7Z7gJWmUNZwc0TeMKkMybMoRnSmnOz2FALArlnFbym6MOfqcRxeCm/Dqvj1qmOn9kqMeSXA364go0hSG0JPfP2RbW6ktYQ5FGm3XvQKSSvgjq1E+/TebSM+2kcTqertzzi95DwpDJTiYTFJAUDqnaJaIitl2EGYK3s9J4Q/SN636puVa3PgJdUjNhGGAWTNQon/h6VeK6/5td8szd/sj2NQ7q4gFhLdTxTUrV/iJrJdKc/XDyrLtFcnnIrwFOcSJ2RTy124KRWH+flmEY+Ch3O8aAH5l1JWA9e07tA=="]);
}

- (void)testCompressionLongRuns
{
    unsigned int incrementAmount = 5;
    if (getenv("RunSlowUnitTests") == NULL) {
        NSLog(@"*** ABBREVIATING slow test [%@ %s]", [self class], _cmd);
        incrementAmount *= 100;
    }
    
    // Test strings of 'a' of length 0..N
    NSMutableString *stringOfA = [NSMutableString stringWithString:@"a"];
    unsigned int length;
    for (length = 0; length < 16*1024; length += incrementAmount) {
        if ((length % 100) == 0)
            fprintf(stderr, "%d...\n", length);
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        TEST_STRING(stringOfA);
        [stringOfA appendString:@"a"];
        [pool release];
    }
}

- (void)testCompressionRandomVectors
{
    unsigned int maxLength = 128*1024;
    if (getenv("RunSlowUnitTests") == NULL) {
        NSLog(@"*** ABBREVIATING slow test [%@ %s]", [self class], _cmd);
	maxLength /= 10;
    }

    // Test some random vectors
    unsigned int repetitions = 50;
    while (repetitions--) {
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        NSData *data = [NSData randomDataOfLength:OFRandomNext() % maxLength];
        NS_DURING {
            TEST_DATA(data);
        } NS_HANDLER {
            [data writeToFile:@"/tmp/fail.dat" atomically:YES];
            NSLog(@"Failed on random vector (base-64): <%@>", [data base64String]);
            [localException raise];
        } NS_ENDHANDLER;
        [pool release];
    }
}

@end

@implementation OFBzip2CompressionTest

- (void)doTestWithData:(NSData *)data;
{
    NSData *bz2Data = [data compressedData];
    shouldBeEqual(data, [bz2Data decompressedData]);
    should([bz2Data mightBeCompressed]);
}

@end

@implementation OFGzipCompressionTest

- (void)doTestWithData:(NSData *)data;
{
    NSData *gzData, *decompressed;
    int levels[4] = { -1, 0, 1, 9 };
    int levelIndex;
    NSString *filename1, *filename2;
    NSTask *gunzip;
    int fd;
    NSFileHandle *wfh;
    NSAutoreleasePool *pool;

    pool = [[NSAutoreleasePool alloc] init];
    
    filename1 = [NSString stringWithFormat:@"/tmp/OFUnitTests-%d.gz", getpid()];
    filename2 = [filename1 stringByAppendingString:@".out"];

    for(levelIndex = 0; levelIndex < 4; levelIndex ++) {
        gzData = [data compressedDataWithGzipHeader:YES compressionLevel:levels[levelIndex]];
        should(gzData != nil);
        [gzData writeToFile:filename1 atomically:NO];
        gunzip = [[NSTask alloc] init];
        [gunzip setLaunchPath:@"/usr/bin/gzip"];
        [gunzip setArguments:[NSArray arrayWithObjects:@"--decompress", @"--to-stdout", filename1, nil]];
        fd = open([filename2 cString], O_WRONLY|O_CREAT, 0666);
        wfh = [[NSFileHandle alloc] initWithFileDescriptor:fd closeOnDealloc:YES];
        [gunzip setStandardOutput:wfh];
        [wfh release];
        [gunzip launch];
        [gunzip waitUntilExit];
        should([gunzip terminationStatus] == 0);
        [gunzip release];
        decompressed = [NSData dataWithContentsOfFile:filename2];

        shouldBeEqual(data, decompressed);

        decompressed = [gzData decompressedData];
        shouldBeEqual(data, decompressed);
        
        [[NSFileManager defaultManager] removeFileAtPath:filename1 handler:nil];
        [[NSFileManager defaultManager] removeFileAtPath:filename2 handler:nil];
    }

    [pool release];
}

@end


