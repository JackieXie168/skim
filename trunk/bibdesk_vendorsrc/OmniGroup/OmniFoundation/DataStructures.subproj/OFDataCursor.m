// Copyright 1997-2005 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import <OmniFoundation/OFDataCursor.h>

#import <Foundation/Foundation.h>
#import <OmniBase/OmniBase.h>

#import <OmniFoundation/NSString-OFExtensions.h>
#import <OmniFoundation/OFByteSet.h>

#import "OFDataBuffer.h"

RCS_ID("$Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/OmniSourceRelease_2006-09-07/OmniGroup/Frameworks/OmniFoundation/DataStructures.subproj/OFDataCursor.m 68913 2005-10-03 19:36:19Z kc $")

@implementation OFDataCursor

static OFByteSet *endOfLineByteSet;

+ (void)initialize;
{
    OBINITIALIZE;

    endOfLineByteSet = [[OFByteSet alloc] init];
    [endOfLineByteSet addBytesFromString:@"\r\n" encoding:NSASCIIStringEncoding];
}

- initWithData:(NSData *)someData;
{
    if (![super init])
	return nil;

    if (!someData) {
	[self release];
	return nil;
    }

    data = [someData retain];
    byteOrder = NS_UnknownByteOrder;
    stringEncoding = NSISOLatin1StringEncoding;

    dataLength = [data length];
    startPosition = (const OFByte *)[data bytes];
    endPosition = startPosition + dataLength;
    currentPosition = startPosition;

    return self;
}

- (void)dealloc;
{
    [data release];
    [super dealloc];
}

- (BOOL)hasMoreData;
{
    return currentPosition < endPosition;
}

- (unsigned int)seekToOffset:(int)offset fromPosition:(OFDataCursorSeekPosition)position;
{
    const OFByte *newPosition;

    switch (position) {
        default:
        case OFDataCursorSeekFromCurrent:
            newPosition = currentPosition + offset;
            break;
        case OFDataCursorSeekFromEnd:
            newPosition = endPosition + offset;
            break;
        case OFDataCursorSeekFromStart:
            newPosition = startPosition + offset;
            break;
    }
    if (newPosition < startPosition)
	[NSException raise:NSRangeException format:@"Attempted seek past start of data"];
    else if (newPosition > endPosition)
	[NSException raise:NSRangeException format:@"Attempted seek past end of data"];
    currentPosition = newPosition;

    return currentPosition - startPosition;
}

- (unsigned int)currentOffset;
{
    return currentPosition - startPosition;
}

- (void)rewind;
{
    currentPosition = startPosition;
}

- (void)setByteOrder:(OFByteOrder)newByteOrder;
{
    byteOrder = newByteOrder;
}

- (OFByteOrder)byteOrder;
{
    return byteOrder;
}

#define ENSURE_ENOUGH_DATA(count)					\
    if (currentPosition + count > endPosition)			        \
	[NSException raise:NSRangeException format:@"Attempted read past end of data.  Current position is %d, count is %d, end position is %d.", currentPosition, count, endPosition];

#define START_READ_DATA(readValue)					\
    ENSURE_ENOUGH_DATA(sizeof(readValue));				\
    memcpy(&readValue, currentPosition, sizeof(readValue));
    
#define SWAP_BYTES(inputValue, returnValue, readType, swapType)		\
{									\
    switch (byteOrder) {						\
        case NS_UnknownByteOrder:	     				\
            memcpy(&returnValue, &inputValue, sizeof(returnValue));	\
            break;	   						\
        case NS_LittleEndian:						\
            returnValue = NSSwapLittle ## swapType ## ToHost(inputValue); \
            break;     							\
        case NS_BigEndian:     						\
            returnValue = NSSwapBig ## swapType ## ToHost(inputValue);	\
            break;	   						\
    }									\
}

#define INCREMENT_OFFSETS(readType)					\
    currentPosition += sizeof(readType);

#define READ_DATA_OF_TYPE(readType, methodType, swapType)		\
- (readType)read ## methodType;						\
{									\
    OFSwapped ## swapType inputValue;					\
    readType returnValue;						\
									\
    START_READ_DATA(inputValue);	   	    			\
    SWAP_BYTES(inputValue, returnValue, readType, swapType);		\
    INCREMENT_OFFSETS(readType);					\
    return returnValue;							\
}

#define PEEK_DATA_OF_TYPE(readType, methodType, swapType)		\
- (readType)peek ## methodType;						\
{									\
    OFSwapped ## swapType inputValue;					\
    readType returnValue;						\
									\
    START_READ_DATA(inputValue);	   	    			\
    SWAP_BYTES(inputValue, returnValue, readType, swapType);		\
    return returnValue;							\
}

#define SKIP_DATA_OF_TYPE(readType, methodType)				\
- (void)skip ## methodType;						\
{									\
    ENSURE_ENOUGH_DATA(sizeof(readType));				\
    INCREMENT_OFFSETS(readType);					\
}

- (void)readBytes:(unsigned int)byteCount intoBuffer:(void *)buffer;
{
    ENSURE_ENOUGH_DATA(byteCount);
    memcpy(buffer, currentPosition, byteCount);
    currentPosition += byteCount;
}

- (void)peekBytes:(unsigned int)byteCount intoBuffer:(void *)buffer;
{
    ENSURE_ENOUGH_DATA(byteCount);
    memcpy(buffer, currentPosition, byteCount);
}

- (void)skipBytes:(unsigned int)byteCount;
{
    ENSURE_ENOUGH_DATA(byteCount);
    currentPosition += byteCount;
}

- (unsigned int)readMaximumBytes:(unsigned int)byteCount
    intoBuffer:(void *)buffer;
{
    if (currentPosition + byteCount > endPosition)
	byteCount = endPosition - currentPosition;
    memcpy(buffer, currentPosition, byteCount);
    currentPosition += byteCount;
    return byteCount;
}

- (unsigned int)peekMaximumBytes:(unsigned int)byteCount
    intoBuffer:(void *)buffer;
{
    if (currentPosition + byteCount > endPosition)
	byteCount = endPosition - currentPosition;
    memcpy(buffer, currentPosition, byteCount);
    return byteCount;
}

- (unsigned int)skipMaximumBytes:(unsigned int)byteCount;
{
    if (currentPosition + byteCount > endPosition)
	byteCount = endPosition - currentPosition;
    currentPosition += byteCount;
    return byteCount;
}

static inline unsigned int offsetToByte(OFDataCursor *self, OFByte aByte)
{
    const OFByte *offset;

    for (offset = self->currentPosition; offset < self->endPosition; offset++)
        if (*(OFByte *)offset == aByte)
	    break;
    return offset - self->currentPosition;
}

static inline unsigned int
offsetToByteInSet(OFDataCursor *self, OFByteSet *byteSet)
{
    const OFByte *offset;
    OFByte aByte;

    for (offset = self->currentPosition; offset < self->endPosition; offset++) {
        aByte = *(OFByte *)offset;
	if (isByteInByteSet(aByte, byteSet))
	    break;
    }
    return offset - self->currentPosition;
}

- (unsigned int)offsetToByte:(OFByte)aByte;
{
    return offsetToByte(self, aByte);
}

- (unsigned int)offsetToByteInSet:(OFByteSet *)aByteSet;
{
    return offsetToByteInSet(self, aByteSet);
}

typedef long OFSwappedLong;
typedef short OFSwappedShort;
typedef long long OFSwappedLongLong;
typedef NSSwappedFloat OFSwappedFloat;
typedef NSSwappedDouble OFSwappedDouble;

READ_DATA_OF_TYPE(long int, LongInt, Long);
PEEK_DATA_OF_TYPE(long int, LongInt, Long);
SKIP_DATA_OF_TYPE(long int, LongInt);
READ_DATA_OF_TYPE(short int, ShortInt, Short);
PEEK_DATA_OF_TYPE(short int, ShortInt, Short);
SKIP_DATA_OF_TYPE(short int, ShortInt);
READ_DATA_OF_TYPE(long long int, LongLongInt, LongLong);
PEEK_DATA_OF_TYPE(long long int, LongLongInt, LongLong);
SKIP_DATA_OF_TYPE(long long int, LongLongInt);
READ_DATA_OF_TYPE(float, Float, Float);
PEEK_DATA_OF_TYPE(float, Float, Float);
SKIP_DATA_OF_TYPE(float, Float);
READ_DATA_OF_TYPE(double, Double, Double);
PEEK_DATA_OF_TYPE(double, Double, Double);
SKIP_DATA_OF_TYPE(double, Double);

- (OFByte)readByte;
{
    ENSURE_ENOUGH_DATA(sizeof(OFByte));
    return *(OFByte *)currentPosition++;
}

- (OFByte)peekByte;
{
    ENSURE_ENOUGH_DATA(sizeof(OFByte));
    return *(OFByte *)currentPosition;
}

SKIP_DATA_OF_TYPE(OFByte, Byte);

//

- (long int)readCompressedLongInt;
{
    unsigned int shiftAmount = 0;
    long int accumulator = 0;
    OFByte sevenBitsPlusContinueFlag;

    do {
        sevenBitsPlusContinueFlag = *(currentPosition++);
        accumulator |= (sevenBitsPlusContinueFlag & OF_COMPRESSED_INT_DATA_MASK) << shiftAmount;
        shiftAmount += OF_COMPRESSED_INT_BITS_OF_DATA;
    } while ((sevenBitsPlusContinueFlag & OF_COMPRESSED_INT_CONTINUE_MASK) != 0);

    return accumulator;
}

- (long int)peekCompressedLongInt;
{
    const OFByte *readPosition = currentPosition;
    unsigned int shiftAmount = 0;
    long int accumulator = 0;
    OFByte sevenBitsPlusContinueFlag;

    do {
        sevenBitsPlusContinueFlag = *(readPosition++);
        accumulator |= (sevenBitsPlusContinueFlag & OF_COMPRESSED_INT_DATA_MASK) << shiftAmount;
        shiftAmount += OF_COMPRESSED_INT_BITS_OF_DATA;
    } while ((sevenBitsPlusContinueFlag & OF_COMPRESSED_INT_CONTINUE_MASK) != 0);

    return accumulator;
}

- (void)skipCompressedLongInt;
{
    while ((*currentPosition & OF_COMPRESSED_INT_CONTINUE_MASK) != 0)
        currentPosition++; // skip all bytes marked with continue flag
    currentPosition++; // then skip final byte
}

- (long long int)readCompressedLongLongInt;
{
    int shiftAmount = 0;
    long long int accumulator = 0;
    long long int sevenBits;
    OFByte sevenBitsPlusContinueFlag;

    do {
        sevenBitsPlusContinueFlag = *(currentPosition++);
        // We we don't cast this to a long long before shifting, the compiler will treat it as a long, not a long long.
        sevenBits = sevenBitsPlusContinueFlag & OF_COMPRESSED_INT_DATA_MASK;
        accumulator |= sevenBits << shiftAmount;
        shiftAmount += OF_COMPRESSED_INT_BITS_OF_DATA;
    } while ((sevenBitsPlusContinueFlag & OF_COMPRESSED_INT_CONTINUE_MASK) != 0);

    return accumulator;
}

- (long long int)peekCompressedLongLongInt;
{
    const OFByte *readPosition = currentPosition;
    int shiftAmount = 0;
    long long int accumulator = 0;
    long long int sevenBits;
    OFByte sevenBitsPlusContinueFlag;

    do {
        sevenBitsPlusContinueFlag = *(readPosition++);
        // We we don't cast this to a long long before shifting, the compiler will treat it as a long, not a long long.
        sevenBits = sevenBitsPlusContinueFlag & OF_COMPRESSED_INT_DATA_MASK;
        accumulator |= sevenBits << shiftAmount;
        shiftAmount += OF_COMPRESSED_INT_BITS_OF_DATA;
    } while ((sevenBitsPlusContinueFlag & OF_COMPRESSED_INT_CONTINUE_MASK) != 0);

    return accumulator;
}

- (void)skipCompressedLongLongInt;
{
    while ((*currentPosition & OF_COMPRESSED_INT_CONTINUE_MASK) != 0)
        currentPosition++; // skip all bytes marked with continue flag
    currentPosition++; // then skip final byte
}

//

- (NSData *)readDataOfLength:(unsigned int)aLength;
{
    NSData *returnData;

    ENSURE_ENOUGH_DATA(aLength);
    returnData = [NSData dataWithBytes:currentPosition length:aLength];
    currentPosition += aLength;
    return returnData;
}

- (NSData *)peekDataOfLength:(unsigned int)aLength;
{
    NSData *returnData;

    ENSURE_ENOUGH_DATA(aLength);
    returnData = [NSData dataWithBytes:currentPosition length:aLength];
    return returnData;
}

- (NSData *)readDataUpToByte:(OFByte)aByte;
{
    int aLength;
    
    aLength = offsetToByte(self, aByte);
    if (aLength == 0)
	return nil;
    return [self readDataOfLength:aLength];
}

- (NSData *)peekDataUpToByte:(OFByte)aByte;
{
    int aLength;
    
    aLength = offsetToByte(self, aByte);
    if (aLength == 0)
	return nil;
    return [self peekDataOfLength:aLength];
}

- (NSData *)readDataUpToByteInSet:(OFByteSet *)aByteSet;
{
    unsigned int aLength;
    
    aLength = offsetToByteInSet(self, aByteSet);
    if (aLength == 0)
	return nil;
    return [self readDataOfLength:aLength];
}

- (NSData *)peekDataUpToByteInSet:(OFByteSet *)aByteSet;
{
    unsigned int aLength;
    
    aLength = offsetToByteInSet(self, aByteSet);
    if (aLength == 0)
	return nil;
    return [self peekDataOfLength:aLength];
}

- (NSString *)readStringOfLength:(unsigned int)aLength;
{
    NSData *someData;
    NSString *aString;

    ENSURE_ENOUGH_DATA(aLength);
    someData = [[NSData alloc] initWithBytes:currentPosition length:aLength];
    aString = [NSString stringWithData:someData encoding:stringEncoding];
    [someData release];
    currentPosition += aLength;
    return aString;
}

- (NSString *)peekStringOfLength:(unsigned int)aLength;
{
    NSData *someData;
    NSString *aString;

    ENSURE_ENOUGH_DATA(aLength);
    someData = [[NSData alloc] initWithBytes:currentPosition length:aLength];
    aString = [NSString stringWithData:someData encoding:stringEncoding];
    [someData release];
    return aString;
}

- (NSString *)readStringUpToByte:(OFByte)aByte;
{
    unsigned int aLength;
    
    aLength = offsetToByte(self, aByte);
    if (aLength == 0)
	return nil;
    return [self readStringOfLength:aLength];
}

- (NSString *)peekStringUpToByte:(OFByte)aByte;
{
    unsigned int aLength;
    
    aLength = offsetToByte(self, aByte);
    if (aLength == 0)
	return nil;
    return [self peekStringOfLength:aLength];
}

- (NSString *)readStringUpToByteInSet:(OFByteSet *)aByteSet;
{
    unsigned int aLength;
    
    aLength = offsetToByteInSet(self, aByteSet);
    if (aLength == 0)
	return nil;
    return [self readStringOfLength:aLength];
}

- (NSString *)peekStringUpToByteInSet:(OFByteSet *)aByteSet;
{
    unsigned int aLength;
    
    aLength = offsetToByteInSet(self, aByteSet);
    if (aLength == 0)
	return nil;
    return [self peekStringOfLength:aLength];
}

- (NSData *)readAllData;
{
    return [self readDataOfLength:endPosition - currentPosition];
}

- (NSString *)readLine;
{
    unsigned int lineLength;
    NSString *line;

    lineLength = offsetToByteInSet(self, endOfLineByteSet);
    if (lineLength == 0)
        line = @"";
    else
        line = [self readStringOfLength:lineLength];

    if (currentPosition + 1 <= endPosition) {
        switch (*(OFByte *)currentPosition) {
            case '\r':
                currentPosition++;
                if (currentPosition + 1 <= endPosition && *(OFByte *)currentPosition == '\n')
                    currentPosition++;
                    break;
            case '\n':
                currentPosition++;
                break;
            default:
                break;
        }
    }
    return line;
}

- (NSString *)peekLine;
{
    unsigned int lineLength;

    lineLength = offsetToByteInSet(self, endOfLineByteSet);
    if (lineLength == 0)
        return @"";
    else
        return [self peekStringOfLength:lineLength];
}

- (void)skipLine;
{
    unsigned int lineLength;

    lineLength = offsetToByteInSet(self, endOfLineByteSet);
    currentPosition += lineLength;

    if (currentPosition + 1 <= endPosition) {
        switch (*(OFByte *)currentPosition) {
            case '\r':
                currentPosition++;
                if (currentPosition + 1 <= endPosition &&
                    *(OFByte *)currentPosition == '\n')
                    currentPosition++;
                    break;
            case '\n':
                currentPosition++;
                break;
            default:
                break;
        }
    }
}

- (NSMutableDictionary *)debugDictionary;
{
    NSMutableDictionary *debugDictionary;

    debugDictionary = [super debugDictionary];

    if (data)
	[debugDictionary setObject:data forKey:@"data"];

    return debugDictionary;
}

@end
