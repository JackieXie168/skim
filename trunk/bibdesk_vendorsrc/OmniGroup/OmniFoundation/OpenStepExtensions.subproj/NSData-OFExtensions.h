// Copyright 1997-2005 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/OmniSourceRelease_2006-09-07/OmniGroup/Frameworks/OmniFoundation/OpenStepExtensions.subproj/NSData-OFExtensions.h 70910 2005-12-06 02:54:01Z wiml $

#import <Foundation/NSData.h>
#import <stdio.h>

@class NSArray;

typedef struct OFQuotedPrintableMapping {
    char map[256];   // 256 entries, one for each octet value
    unsigned short translations[8];  // 8 is an arbitrary size; must be at least 2
} OFQuotedPrintableMapping;

@interface NSData (OFExtensions)

+ (NSData *)randomDataOfLength:(unsigned int)length;
// Returns a new autoreleased instance that contains the number of requested random bytes.

+ (id)dataWithHexString:(NSString *)hexString;
- initWithHexString:(NSString *)hexString;
- (NSString *)lowercaseHexString; /* has a leading 0x (sigh) */
- (NSString *)unadornedLowercaseHexString;  /* no 0x */

- initWithASCII85String:(NSString *)ascii85String;
- (NSString *)ascii85String;

+ (id)dataWithBase64String:(NSString *)base64String;
- initWithBase64String:(NSString *)base64String;
- (NSString *)base64String;

// This is our own coding method, not a standard.  This is good
// for NSData strings that users have to type in.
- initWithASCII26String:(NSString *)ascii26String;
- (NSString *)ascii26String;

+ dataWithDecodedURLString:(NSString *)urlString;

// This is a generic implementation of quoted-printable-style encodings, used by methods elsewhere in OmniFoundation
- (NSString *)quotedPrintableStringWithMapping:(const OFQuotedPrintableMapping *)qpMap lengthHint:(unsigned)zeroIfNoHint;
- (unsigned)lengthOfQuotedPrintableStringWithMapping:(const OFQuotedPrintableMapping *)qpMap;

- (unsigned long)indexOfFirstNonZeroByte;
    // Returns the index of the first non-zero byte in the receiver, or NSNotFound if if all the bytes in the data are zero.

- (NSData *)sha1Signature;
    // Uses the SHA-1 algorithm to compute a signature for the receiver.

- (NSData *)md5Signature;
    // Computes an MD5 digest of the receiver and returns it. (Derived from the RSA Data Security, Inc. MD5 Message-Digest Algorithm.)

- (BOOL)writeToFile:(NSString *)path atomically:(BOOL)useAuxiliaryFile createDirectories:(BOOL)shouldCreateDirectories;
    // Will raise an exception if it can't create the required directories.

- (NSData *)dataByAppendingData:(NSData *)anotherData;
    // Returns the catenation of this NSData and the argument
    
- (BOOL)hasPrefix:(NSData *)data;
- (BOOL)containsData:(NSData *)data;

- (NSRange)rangeOfData:(NSData *)data;
- (unsigned)indexOfBytes:(const void *)bytes length:(unsigned int)patternLength;
- (unsigned)indexOfBytes:(const void *)patternBytes length:(unsigned int)patternLength range:(NSRange)searchRange;

- propertyList;
    // a cover for the CoreFoundation function call

// stdio support
- (FILE *)openReadOnlyStandardIOFile;

// Compression
- (BOOL)mightBeCompressed;
- (NSData *)compressedData;
- (NSData *)decompressedData;

// Specific algorithms
- (NSData *)compressedBzip2Data;
- (NSData *)decompressedBzip2Data;

- (NSData *)compressedDataWithGzipHeader:(BOOL)includeHeader compressionLevel:(int)level;
- (NSData *)decompressedGzipData;

// UNIX filters
- (NSData *)filterDataThroughCommandAtPath:(NSString *)commandPath withArguments:(NSArray *)arguments;

@end
