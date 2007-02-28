// Copyright 1997-2005 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import <OmniFoundation/OFByteSet.h>

#import <Foundation/Foundation.h>
#import <OmniBase/OmniBase.h>

#import <OmniFoundation/NSString-OFExtensions.h>

RCS_ID("$Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/OmniSourceRelease_2006-09-07/OmniGroup/Frameworks/OmniFoundation/DataStructures.subproj/OFByteSet.m 68913 2005-10-03 19:36:19Z kc $")

@implementation OFByteSet

- copy;
{
    OFByteSet *copy;
    unsigned int index;

    copy = [[isa alloc] init];
    for (index = 0; index < OFByteSetBitmapRepLength; index++)
	copy->bitmapRep[index] = bitmapRep[index];
    return copy;
}

- (BOOL)byteIsMember:(OFByte)aByte;
{
    return isByteInByteSet(aByte, self);
}

- (void)addByte:(OFByte)aByte;
{
    addByteToByteSet(aByte, self);
}

- (void)removeByte:(OFByte)aByte;
{
    removeByteFromByteSet(aByte, self);
}

- (void)addAllBytes;
{
    unsigned int index;

    for (index = 0; index < OFByteSetBitmapRepLength; index++)
	bitmapRep[index] = 0xff;
}

- (void)removeAllBytes;
{
    unsigned int index;

    for (index = 0; index < OFByteSetBitmapRepLength; index++)
	bitmapRep[index] = 0x00;
}

- (void)addBytesFromData:(NSData *)data;
{
    unsigned int index, length;
    const OFByte *bytes;

    bytes = (const OFByte *)[data bytes];
    length = [data length];
    for (index = 0; index < length; index++)
	addByteToByteSet(bytes[index], self);
}

- (void)addBytesFromString:(NSString *)string encoding:(NSStringEncoding)encoding;
{
    [self addBytesFromData:[string dataUsingEncoding:encoding]];
}

- (void)removeBytesFromData:(NSData *)data;
{
    unsigned int index, length;
    const OFByte *bytes;

    bytes = (const OFByte *)[data bytes];
    length = [data length];
    for (index = 0; index < length; index++)
	removeByteFromByteSet(bytes[index], self);
}

- (void)removeBytesFromString:(NSString *)string encoding:(NSStringEncoding)encoding;
{
    [self removeBytesFromData:[string dataUsingEncoding:encoding]];
}

- (NSData *)data;
{
    unsigned int index, length;
    NSMutableData *data;
    OFByte *bytePtr;

    length = 0;
    for (index = 0; index < 256; index++) {
	if (isByteInByteSet(index, self))
	    length++;
    }
    data = [NSMutableData dataWithLength:length];
    bytePtr = (OFByte *)[data mutableBytes];
    for (index = 0; index < 256; index++) {
	if (isByteInByteSet(index, self))
	    *bytePtr++ = index;
    }
    return data;
}

- (NSString *)stringUsingEncoding:(NSStringEncoding)encoding;
{
    return [NSString stringWithData:[self data] encoding:encoding];
}

- (NSMutableDictionary *)debugDictionary;
{
    NSMutableDictionary *debugDictionary;
    NSMutableArray *bytes;
    unsigned int index;

    debugDictionary = [super debugDictionary];

    bytes = [NSMutableArray arrayWithCapacity:256];
    for (index = 0; index < 256; index++) {
	if (isByteInByteSet(index, self))
	    [bytes addObject:[NSString stringWithFormat:@"%c", index]];
    }
    [debugDictionary setObject:bytes forKey:@"bytes"];

    return debugDictionary;
}

@end

@implementation OFByteSet (PredefinedSets)

static OFByteSet *whitespaceByteSet = nil;

+ (OFByteSet *)whitespaceByteSet;
{
    unsigned int index;

    if (whitespaceByteSet)
	return whitespaceByteSet;

    whitespaceByteSet = [[OFByteSet alloc] init];
    for (index = 0; index < 256; index++)
	if (isspace(index))
	    [whitespaceByteSet addByte:index];

    return whitespaceByteSet;
}

@end
