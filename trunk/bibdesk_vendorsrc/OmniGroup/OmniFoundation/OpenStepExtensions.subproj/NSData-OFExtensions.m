// Copyright 1998-2005 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import <OmniFoundation/NSData-OFExtensions.h>

#import <Foundation/Foundation.h>
#import <CoreFoundation/CoreFoundation.h>
#import <OmniBase/OmniBase.h>

#import <OmniFoundation/NSFileManager-OFExtensions.h>
#import <OmniFoundation/NSMutableData-OFExtensions.h>
#import <OmniFoundation/NSObject-OFExtensions.h>
#import <OmniFoundation/NSString-OFExtensions.h>
#import <OmniFoundation/OFDataBuffer.h>
#import <OmniFoundation/OFRandom.h>

#import "sha1.h"
#import <OmniFoundation/md5.h>
#import <bzlib.h>
#import <zlib.h>

RCS_ID("$Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/OmniSourceRelease_2006-09-07/OmniGroup/Frameworks/OmniFoundation/OpenStepExtensions.subproj/NSData-OFExtensions.m 70933 2005-12-06 22:27:45Z wiml $")

@implementation NSData (OFExtensions)

+ (NSData *)randomDataOfLength:(unsigned int)length;
{
    OFByte *bytes;
    unsigned int byteIndex;

    bytes = (OFByte *)NSZoneMalloc(NULL, length);
    for (byteIndex = 0; byteIndex < length; byteIndex++)
        bytes[byteIndex] = OFRandomNext() & 0xff;

    // Send to self rather than NSData so that we'll get mutable instances when the caller sent the message to NSMutableData
    return [self dataWithBytesNoCopy:bytes length:length];
}

static inline unsigned char fromhex(unsigned char hexDigit)
{
     if (hexDigit >= '0' && hexDigit <= '9')
        return hexDigit - '0';
     if (hexDigit >= 'a' && hexDigit <= 'f')
        return hexDigit - 'a' + 10;
     if (hexDigit >= 'A' && hexDigit <= 'F')
        return hexDigit - 'A' + 10;
     [NSException raise:@"IllegalHexDigit" format:@"Attempt to interpret a string containing '%c' as a hexidecimal value", hexDigit];
     return 0; // Never reached
}

+ (id)dataWithHexString:(NSString *)hexString;
{
    return [[[self alloc] initWithHexString:hexString] autorelease];
}

- initWithHexString:(NSString *)hexString;
{
    unsigned int length;
    unsigned int destIndex;
    unichar *inputCharacters, *inputCharactersEnd;
    const unichar *inputPtr;
    OFByte *outputBytes;
    NSData *returnValue;

    length = [hexString length];
    inputCharacters = NSZoneMalloc(NULL, length * sizeof(unichar));

    [hexString getCharacters:inputCharacters];
    inputCharactersEnd = inputCharacters + length;

    inputPtr = inputCharacters;
    while (isspace(*inputPtr))
        inputPtr++;

    if (*inputPtr == '0' && (inputPtr[1] == 'x' || inputPtr[1] == 'X'))
        inputPtr += 2;

    outputBytes = NSZoneMalloc(NULL, (inputCharactersEnd - inputPtr) / 2 + 1);

    destIndex = 0;
    if ((inputCharactersEnd - inputPtr) & 0x01) {
        // 0xf08 must be interpreted as 0x0f08
        outputBytes[destIndex++] = fromhex(*inputPtr++);
    }

    while (inputPtr < inputCharactersEnd) {
        unsigned char outputByte;

        outputByte = fromhex(*inputPtr++) << 4;
        outputByte |= fromhex(*inputPtr++);
        outputBytes[destIndex++] = outputByte;
    }

    returnValue = [self initWithBytes:outputBytes length:destIndex];

    NSZoneFree(NULL, inputCharacters);
    NSZoneFree(NULL, outputBytes);

    return returnValue;
}

- (NSString *)_lowercaseHexStringWithPrefix:(const unichar *)prefix
                                     length:(unsigned int)prefixLength
{
    const OFByte *inputBytes, *inputBytesPtr;
    unsigned int inputBytesLength, outputBufferLength;
    unichar *outputBuffer, *outputBufferEnd;
    unichar *outputBufferPtr;
    const char _tohex[] = "0123456789abcdef";
    NSString *hexString;

    inputBytes = [self bytes];
    inputBytesLength = [self length];
    outputBufferLength = prefixLength + inputBytesLength * 2;
    outputBuffer = NSZoneMalloc(NULL, outputBufferLength * sizeof(unichar));
    outputBufferEnd = outputBuffer + outputBufferLength;

    inputBytesPtr = inputBytes;
    outputBufferPtr = outputBuffer;

    while(prefixLength--)
        *outputBufferPtr++ = *prefix++;
    while (outputBufferPtr < outputBufferEnd) {
        unsigned char inputByte;

        inputByte = *inputBytesPtr++;
        *outputBufferPtr++ = _tohex[(inputByte & 0xf0) >> 4];
        *outputBufferPtr++ = _tohex[inputByte & 0x0f];
    }

    hexString = [[NSString allocWithZone:[self zone]] initWithCharacters:outputBuffer length:outputBufferLength];

    NSZoneFree(NULL, outputBuffer);

    return [hexString autorelease];
}

- (NSString *)lowercaseHexString;
{
    /* For backwards compatibility, this method has a leading "0x" */
    static const unichar hexPrefix[2] = { '0', 'x' };

    return [self _lowercaseHexStringWithPrefix:hexPrefix length:2];
}

- (NSString *)unadornedLowercaseHexString;
{
    return [self _lowercaseHexStringWithPrefix:NULL length:0];
}

// This is based on decode85.c.  The only major difference is that this doesn't deal with newlines in the file and doesn't deal with the '<~' and '~>' beginning and end of stirng markers.

static inline void ascii85put(OFDataBuffer *buffer, unsigned long tuple, int bytes)
{
    switch (bytes) {
        case 4:
            OFDataBufferAppendByte(buffer, tuple >> 24);
            OFDataBufferAppendByte(buffer, tuple >> 16);
            OFDataBufferAppendByte(buffer, tuple >>  8);
            OFDataBufferAppendByte(buffer, tuple);
            break;
        case 3:
            OFDataBufferAppendByte(buffer, tuple >> 24);
            OFDataBufferAppendByte(buffer, tuple >> 16);
            OFDataBufferAppendByte(buffer, tuple >>  8);
            break;
        case 2:
            OFDataBufferAppendByte(buffer, tuple >> 24);
            OFDataBufferAppendByte(buffer, tuple >> 16);
            break;
        case 1:
            OFDataBufferAppendByte(buffer, tuple >> 24);
            break;
    }
}

- initWithASCII85String:(NSString *)ascii85String;
{
    static const unsigned long pow85[] = {
            85 * 85 * 85 * 85, 85 * 85 * 85, 85 * 85, 85, 1
    };
    OFDataBuffer buffer;
    const unsigned char *string;
    unsigned long tuple = 0, length;
    int c, count = 0;
    NSData *ascii85Data, *decodedData;
    NSData *returnValue;

    OBPRECONDITION([ascii85String canBeConvertedToEncoding:NSASCIIStringEncoding]);

    ascii85Data = [ascii85String dataUsingEncoding:NSASCIIStringEncoding];
    string = [ascii85Data bytes];
    length = [ascii85Data length];
    
    OFDataBufferInit(&buffer);
    while (length--) {
        c = (int)*string;
        string++;

        switch (c) {
            default:
                if (c < '!' || c > 'u')
                    [NSException raise:@"ASCII85Error" format:@"ASCII85: bad character in ascii85 string: %#o", c];

                tuple += (c - '!') * pow85[count++];
                if (count == 5) {
                    ascii85put(&buffer, tuple, 4);
                    count = 0;
                    tuple = 0;
                }
                break;
            case 'z':
                if (count != 0)
                    [NSException raise:@"ASCII85Error" format:@"ASCII85: z inside ascii85 5-tuple"];
                OFDataBufferAppendByte(&buffer, '\0');
                OFDataBufferAppendByte(&buffer, '\0');
                OFDataBufferAppendByte(&buffer, '\0');
                OFDataBufferAppendByte(&buffer, '\0');
                break;
        }
    }

    if (count > 0) {
        count--;
        tuple += pow85[count];
        ascii85put(&buffer, tuple, count);
    }

    decodedData = [OFDataBufferData(&buffer) retain];
    OFDataBufferRelease(&buffer);

    returnValue = [self initWithData:decodedData];
    [decodedData release];

    return returnValue;
}

static inline void encode85(OFDataBuffer *dataBuffer, unsigned long tuple, int count)
{
    int i;
    char buf[5], *s = buf;
    i = 5;
    do {
        *s++ = tuple % 85;
        tuple /= 85;
    } while (--i > 0);
    i = count;
    do {
        OFDataBufferAppendByte(dataBuffer, *--s + '!');
    } while (i-- > 0);
}

- (NSString *)ascii85String;
{
    OFDataBuffer dataBuffer;
    const unsigned char *byte;
    unsigned int length, count = 0, tuple = 0;
    NSData *data;
    NSString *string;
    
    OFDataBufferInit(&dataBuffer);
    
    byte = [self bytes];
    length = [self length];

    // This is based on encode85.c.  The only major difference is that this doesn't put newlines in the file to keep the output line(s) as some maximum width.  Also, this doesn't put the '<~' at the beginning and '

    while (length--) {
        unsigned int c;

        c = (unsigned int)*byte;
        byte++;

        switch (count++) {
            case 0:
                tuple |= (c << 24);
                break;
            case 1:
                tuple |= (c << 16);
                break;
            case 2:
                tuple |= (c <<  8);
                break;
            case 3:
                tuple |= c;
                if (tuple == 0)
                    OFDataBufferAppendByte(&dataBuffer, 'z');
                else
                    encode85(&dataBuffer, tuple, count);
                tuple = 0;
                count = 0;
                break;
        }
    }

    if (count > 0)
        encode85(&dataBuffer, tuple, count);
        
    data = OFDataBufferData(&dataBuffer);
    string = [NSString stringWithData:data encoding:NSASCIIStringEncoding];
    OFDataBufferRelease(&dataBuffer);

    return string;
}

//
// Base-64 (RFC-1521) support.  The following is based on mpack-1.5 (ftp://ftp.andrew.cmu.edu/pub/mpack/)
//

#define XX 127
static char index_64[256] = {
    XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX,
    XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX,
    XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,62, XX,XX,XX,63,
    52,53,54,55, 56,57,58,59, 60,61,XX,XX, XX,XX,XX,XX,
    XX, 0, 1, 2,  3, 4, 5, 6,  7, 8, 9,10, 11,12,13,14,
    15,16,17,18, 19,20,21,22, 23,24,25,XX, XX,XX,XX,XX,
    XX,26,27,28, 29,30,31,32, 33,34,35,36, 37,38,39,40,
    41,42,43,44, 45,46,47,48, 49,50,51,XX, XX,XX,XX,XX,
    XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX,
    XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX,
    XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX,
    XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX,
    XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX,
    XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX,
    XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX,
    XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX,
};
#define CHAR64(c) (index_64[(unsigned char)(c)])

#define BASE64_GETC (length > 0 ? (length--, bytes++, (unsigned int)(bytes[-1])) : (unsigned int)EOF)
#define BASE64_PUTC(c) OFDataBufferAppendByte(buffer, (c))

+ (id)dataWithBase64String:(NSString *)base64String;
{
    return [[[self alloc] initWithBase64String:base64String] autorelease];
}

- initWithBase64String:(NSString *)base64String;
{
    NSData *base64Data;
    const char *bytes;
    unsigned int length;
    OFDataBuffer dataBuffer, *buffer;
    NSData *decodedData;
    NSData *returnValue;
    BOOL suppressCR = NO;
    unsigned int c1, c2, c3, c4;
    int DataDone = 0;
    char buf[3];

    OBPRECONDITION([base64String canBeConvertedToEncoding:NSASCIIStringEncoding]);

    buffer = &dataBuffer;
    OFDataBufferInit(buffer);

    base64Data = [base64String dataUsingEncoding:NSASCIIStringEncoding];
    bytes = [base64Data bytes];
    length = [base64Data length];

    while ((c1 = BASE64_GETC) != (unsigned int)EOF) {
        if (c1 != '=' && CHAR64(c1) == XX)
            continue;
        if (DataDone)
            continue;
        
        do {
            c2 = BASE64_GETC;
        } while (c2 != (unsigned int)EOF && c2 != '=' && CHAR64(c2) == XX);
        do {
            c3 = BASE64_GETC;
        } while (c3 != (unsigned int)EOF && c3 != '=' && CHAR64(c3) == XX);
        do {
            c4 = BASE64_GETC;
        } while (c4 != (unsigned int)EOF && c4 != '=' && CHAR64(c4) == XX);
        if (c2 == (unsigned int)EOF || c3 == (unsigned int)EOF || c4 == (unsigned int)EOF) {
            [NSException raise:@"Base64Error" format:@"Premature end of Base64 string"];
            break;
        }
        if (c1 == '=' || c2 == '=') {
            DataDone=1;
            continue;
        }
        c1 = CHAR64(c1);
        c2 = CHAR64(c2);
        buf[0] = ((c1<<2) | ((c2&0x30)>>4));
        if (!suppressCR || buf[0] != '\r') BASE64_PUTC(buf[0]);
        if (c3 == '=') {
            DataDone = 1;
        } else {
            c3 = CHAR64(c3);
            buf[1] = (((c2&0x0F) << 4) | ((c3&0x3C) >> 2));
            if (!suppressCR || buf[1] != '\r') BASE64_PUTC(buf[1]);
            if (c4 == '=') {
                DataDone = 1;
            } else {
                c4 = CHAR64(c4);
                buf[2] = (((c3&0x03) << 6) | c4);
                if (!suppressCR || buf[2] != '\r') BASE64_PUTC(buf[2]);
            }
        }
    }

    decodedData = [OFDataBufferData(buffer) retain];
    OFDataBufferRelease(buffer);

    returnValue = [self initWithData:decodedData];
    [decodedData release];

    return returnValue;
}

static char basis_64[] =
   "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

static inline void output64chunk(int c1, int c2, int c3, int pads, OFDataBuffer *buffer)
{
    BASE64_PUTC(basis_64[c1>>2]);
    BASE64_PUTC(basis_64[((c1 & 0x3)<< 4) | ((c2 & 0xF0) >> 4)]);
    if (pads == 2) {
        BASE64_PUTC('=');
        BASE64_PUTC('=');
    } else if (pads) {
        BASE64_PUTC(basis_64[((c2 & 0xF) << 2) | ((c3 & 0xC0) >>6)]);
        BASE64_PUTC('=');
    } else {
        BASE64_PUTC(basis_64[((c2 & 0xF) << 2) | ((c3 & 0xC0) >>6)]);
        BASE64_PUTC(basis_64[c3 & 0x3F]);
    }
}

- (NSString *)base64String;
{
    NSString *string;
    NSData *data;
    const OFByte *bytes;
    unsigned int length;
    OFDataBuffer dataBuffer, *buffer;
    unsigned int c1, c2, c3;

    buffer = &dataBuffer;
    OFDataBufferInit(buffer);

    bytes = [self bytes];
    length = [self length];

    while ((c1 = BASE64_GETC) != (unsigned int)EOF) {
        c2 = BASE64_GETC;
        if (c2 == (unsigned int)EOF) {
            output64chunk(c1, 0, 0, 2, buffer);
        } else {
            c3 = BASE64_GETC;
            if (c3 == (unsigned int)EOF) {
                output64chunk(c1, c2, 0, 1, buffer);
            } else {
                output64chunk(c1, c2, c3, 0, buffer);
            }
        }
    }

    data = OFDataBufferData(&dataBuffer);
    string = [NSString stringWithData:data encoding:NSASCIIStringEncoding];
    OFDataBufferRelease(&dataBuffer);

    return string;
}

//
// Omni's custom base-26 support.  This is based on the ascii85 implementation above.
//
// Input strings are characters (either upper or lowercase).  Dashes are ignored.
// Anything else, including whitespace, is illegal.
//
// Output strings are four-character tuples separated by dashes.  The last
// tuple might have fewer than four characters.
//
// Unlike most encodings in this file, a partially-filled 4-octet group has the data
// packed into the less-significant bytes, instead of the more-significant bytes.
//

#define POW4_26_COUNT (7)   // Four base 256 digits take 7 base 26 digits
#define POW3_26_COUNT (6)   // Three base 256 digits take 6 base 26 digits
#define POW2_26_COUNT (4)   // Two base 256 digits take 4 base 26 digits
#define POW1_26_COUNT (2)   // One base 256 digit taks 2 base 26 digits

static unsigned int log256_26[] = {
    POW1_26_COUNT,
    POW2_26_COUNT,
    POW3_26_COUNT,
    POW4_26_COUNT
};

static unsigned int log26_256[] = {
    0, // invalid
    1, // two base 26 digits gives one base 256 digit
    0, // invalid
    2, // four base 26 digits gives two base 256 digits
    0, // invalid
    3, // six base 26 digits gives three base 256 digits
    4, // seven base 26 digits gives three base 256 digits
};

static inline void ascii26put(OFDataBuffer *buffer, unsigned long tuple, int count26)
{
    switch (log26_256[count26-1]) {
        case 4:
            OFDataBufferAppendByte(buffer, (tuple >> 24) & 0xff);
            OFDataBufferAppendByte(buffer, (tuple >> 16) & 0xff);
            OFDataBufferAppendByte(buffer, (tuple >>  8) & 0xff);
            OFDataBufferAppendByte(buffer, (tuple >>  0) & 0xff);
            break;
        case 3:
            OFDataBufferAppendByte(buffer, (tuple >> 16) & 0xff);
            OFDataBufferAppendByte(buffer, (tuple >>  8) & 0xff);
            OFDataBufferAppendByte(buffer, (tuple >>  0) & 0xff);
            break;
        case 2:
            OFDataBufferAppendByte(buffer, (tuple >>  8) & 0xff);
            OFDataBufferAppendByte(buffer, (tuple >>  0) & 0xff);
            break;
        case 1:
            OFDataBufferAppendByte(buffer, (tuple >>  0) & 0xff);
            break;
        default: // ie, zero
            [NSException raise:@"IllegalBase26String" format:@"Malformed base26 string -- last block is %d long", count26];
            break;
    }
}

- initWithASCII26String:(NSString *)ascii26String;
{
    OFDataBuffer buffer;
    const unsigned char *string;
    unsigned long tuple = 0, length;
    unsigned char c, count = 0;
    NSData *ascii26Data, *decodedData;
    NSData *returnValue;

    OBPRECONDITION([ascii26String canBeConvertedToEncoding:NSASCIIStringEncoding]);

    ascii26Data = [ascii26String dataUsingEncoding:NSASCIIStringEncoding];
    string = [ascii26Data bytes];
    length = [ascii26Data length];

    OFDataBufferInit(&buffer);
    while (length--) {
        c = *string;
        string++;

        if (c == '-') {
            // Dashes are ignored
            continue;
        }

        count++;
        
        // 'shift' up
        tuple *= 26;

        // 'or' in the new digit
        if (c >= 'a' && c <= 'z') {
            tuple += (c - 'a');
        } else if (c >= 'A' && c <= 'Z') {
            tuple += (c - 'A');
        } else {
            // Illegal character
            [NSException raise:@"ASCII26Error"
                        format:@"ASCII26: bad character in ascii26 string: %#o", c];
        }

        if (count == POW4_26_COUNT) {
            // If we've filled up a full tuple, output it
            ascii26put(&buffer, tuple, count);
            count = 0;
            tuple = 0;
        }
    }

    if (count)
        // flush remaining digits
        ascii26put(&buffer, tuple, count);

    decodedData = [OFDataBufferData(&buffer) retain];
    OFDataBufferRelease(&buffer);

    returnValue = [self initWithData:decodedData];
    [decodedData release];

    return returnValue;
}

static inline void encode26(OFDataBuffer *dataBuffer, unsigned long tuple, int count256)
{
    int  i, count26;
    char buf[POW4_26_COUNT], *s = buf;

    // Compute the number of base 26 digits necessary to represent
    // the number of base 256 digits we've been given.
    count26 = log256_26[count256-1];

    i = count26;
    while (i--) {
        *s = tuple % 26;
        tuple /= 26;
        s++;
    }
    i = count26;
    while (i--) {
        s--;
        OFDataBufferAppendByte(dataBuffer, *s + 'A');
    }
}

- (NSString *) ascii26String;
{
    OFDataBuffer dataBuffer;
    const unsigned char *byte;
    unsigned int length, count = 0, tuple = 0;
    NSData *data;
    NSString *string;

    OFDataBufferInit(&dataBuffer);

    byte   = [self bytes];
    length = [self length];

    while (length--) {
        unsigned int c;

        c = (unsigned int)*byte;
        tuple <<= 8;
        tuple += c;
        byte++;
        count++;
        
        if (count == 4) {
            encode26(&dataBuffer, tuple, count);
            tuple = 0;
            count = 0;
        }
    }

    if (count)
        encode26(&dataBuffer, tuple, count);

    data = OFDataBufferData(&dataBuffer);
    string = [NSString stringWithData:data encoding:NSASCIIStringEncoding];
    OFDataBufferRelease(&dataBuffer);

    return string;
}

+ dataWithDecodedURLString:(NSString *)urlString
{
    if (urlString == nil)
        return [NSData data];
    else
        return [urlString dataUsingCFEncoding:[NSString urlEncoding] allowLossyConversion:NO hexEscapes:@"%"];
}

static inline unichar hex(int i)
{
    static const char hexDigits[16] = {
        '0', '1', '2', '3', '4', '5', '6', '7',
        '8', '9', 'A', 'B', 'C', 'D', 'E', 'F'
    };

    return (unichar)hexDigits[i];
}

- (unsigned)lengthOfQuotedPrintableStringWithMapping:(const OFQuotedPrintableMapping *)qpMap
{
    unsigned const char *sourceBuffer;
    unsigned sourceLength, sourceIndex, quotedPairs;

    sourceLength = [self length];
    if (sourceLength == 0)
        return 0;
    sourceBuffer = [self bytes];

    quotedPairs = 0;

    for (sourceIndex = 0; sourceIndex < sourceLength; sourceIndex++) {
        unsigned char ch = sourceBuffer[sourceIndex];
        if (qpMap->map[ch] == 1)
            quotedPairs ++;
    }

    return sourceLength + ( 2 * quotedPairs );
}

- (NSString *)quotedPrintableStringWithMapping:(const OFQuotedPrintableMapping *)qpMap lengthHint:(unsigned)outputLengthHint
{
    unsigned const char *sourceBuffer;
    int sourceLength;
    int sourceIndex;
    unichar *destinationBuffer;
    int destinationBufferSize;
    int destinationIndex;
    NSString *escapedString;

    sourceLength = [self length];
    if (sourceLength == 0)
        return [NSString string];
    sourceBuffer = [self bytes];

    if (outputLengthHint > 0)
        destinationBufferSize = outputLengthHint;
    else
        destinationBufferSize = sourceLength + (sourceLength >> 2) + 12;
    destinationBuffer = malloc((destinationBufferSize) * sizeof(*destinationBuffer));
    destinationIndex = 0;

    for (sourceIndex = 0; sourceIndex < sourceLength; sourceIndex++) {
        unsigned char ch;
        unsigned char chtype;

        ch = sourceBuffer[sourceIndex];

        if (destinationIndex >= destinationBufferSize - 3) {
            destinationBufferSize += destinationBufferSize >> 2;
            destinationBuffer = realloc(destinationBuffer, (destinationBufferSize) * sizeof(*destinationBuffer));
        }

        chtype = qpMap->map[ ch ];
        if (!chtype) {
            destinationBuffer[destinationIndex++] = ch;
        } else {
            destinationBuffer[destinationIndex++] = qpMap->translations[chtype-1];
            if (chtype == 1) {
                // "1" indicates a quoted-printable rather than a translation
                destinationBuffer[destinationIndex++] = hex((ch & 0xF0) >> 4);
                destinationBuffer[destinationIndex++] = hex(ch & 0x0F);
            }
        }
    }

    escapedString = [[[NSString alloc] initWithCharactersNoCopy:destinationBuffer length:destinationIndex freeWhenDone:YES] autorelease];

    return escapedString;
}

//
// Misc extensions
//

- (unsigned long)indexOfFirstNonZeroByte;
{
    const OFByte *bytes, *bytePtr;
    unsigned long int byteIndex, byteCount;

    byteCount = [self length];
    bytes = (const unsigned char *)[self bytes];

    for (byteIndex = 0, bytePtr = bytes; byteIndex < byteCount; byteIndex++, bytePtr++) {
	if (*bytePtr != 0)
	    return byteIndex;
    }

    return NSNotFound;
}

- (unsigned long)firstByteSet;
{
    return [self indexOfFirstNonZeroByte];
}

- (NSData *)sha1Signature;
{
    const unsigned char *bytesToProcess;
    unsigned int lengthToProcess, currentLengthToProcess;
    SHA1_CTX context;
    unsigned char signature[SHA1_SIGNATURE_LENGTH];

    bytesToProcess = [self bytes];
    lengthToProcess = [self length];

    SHA1Init(&context);

    while (lengthToProcess) {
        currentLengthToProcess = MIN(lengthToProcess, 16384u);
        SHA1Update(&context, bytesToProcess, currentLengthToProcess);
        lengthToProcess -= currentLengthToProcess;
        bytesToProcess += currentLengthToProcess;
    }

    SHA1Final(signature, &context);

    return [NSData dataWithBytes:signature length:SHA1_SIGNATURE_LENGTH];
}

/* An MD5 hash is 16 bytes long. There isn't a define for this in md5.h; but it can't ever change, anyway (unless we go to a non-8-bit byte) */
#define MD5_SIGNATURE_LENGTH 16

- (NSData *)md5Signature;
{
    MD5_CTX md5context;
    unsigned char signature[MD5_SIGNATURE_LENGTH];

    MD5Init(&md5context);
    MD5Update(&md5context, [self bytes], [self length]);
    MD5Final(signature, &md5context);

    return [NSData dataWithBytes:signature length:MD5_SIGNATURE_LENGTH];
}

- (BOOL)hasPrefix:(NSData *)data;
{
    unsigned const char *selfPtr, *ptr, *end;

    if ([self length] < [data length])
        return NO;

    ptr = [data bytes];
    end = ptr + [data length];
    selfPtr = [self bytes];
    
    while(ptr < end) {
        if (*ptr++ != *selfPtr++)
            return NO;
    }
    return YES;
}

- (BOOL)containsData:(NSData *)data
{
    unsigned dataLocation = [self indexOfBytes:[data bytes] length:[data length]];
    return (dataLocation != NSNotFound);
}

- (NSRange)rangeOfData:(NSData *)data;
{
    unsigned patternLength, patternLocation;

    patternLength = [data length];
    patternLocation = [self indexOfBytes:[data bytes] length:patternLength];
    if (patternLocation == NSNotFound)
        return (NSRange){location: NSNotFound, length: 0};
    else
        return (NSRange){location: patternLocation, length: patternLength};
}

- (unsigned)indexOfBytes:(const void *)patternBytes length:(unsigned int)patternLength;
{
    return [self indexOfBytes:patternBytes length:patternLength range:(NSRange){0, [self length]}];
}

- (unsigned)indexOfBytes:(const void *)patternBytes length:(unsigned int)patternLength range:(NSRange)searchRange
{
    unsigned const char *selfBufferStart, *selfPtr, *selfPtrEnd;
    unsigned int selfLength;
    
    selfLength = [self length];
    if (searchRange.location > selfLength ||
        (searchRange.location + searchRange.length) > selfLength) {
        OBRejectInvalidCall(self, _cmd, @"Range {%u,%u} exceeds length %u", searchRange.location, searchRange.length, selfLength);
    }

    if (patternLength == 0)
        return searchRange.location;
    if (patternLength > searchRange.length) {
        // This test is a nice shortcut, but it's also necessary to avoid crashing: zero-length CFDatas will sometimes(?) return NULL for their bytes pointer, and the resulting pointer arithmetic can underflow.
        return NSNotFound;
    }
    
    
    selfBufferStart = [self bytes];
    selfPtr    = selfBufferStart + searchRange.location;
    selfPtrEnd = selfBufferStart + searchRange.location + searchRange.length + 1 - patternLength;
    
    for (;;) {
        if (memcmp(selfPtr, patternBytes, patternLength) == 0)
            return (selfPtr - selfBufferStart);
        
        selfPtr++;
        if (selfPtr == selfPtrEnd)
            break;
        selfPtr = memchr(selfPtr, *(const char *)patternBytes, (selfPtrEnd - selfPtr));
        if (!selfPtr)
            break;
    }
    return NSNotFound;
}

- propertyList
{
    CFPropertyListRef propList;
    CFStringRef errorString;
    NSException *exception;
    
    propList = CFPropertyListCreateFromXMLData(kCFAllocatorDefault, (CFDataRef)self, kCFPropertyListImmutable, &errorString);
    
    if (propList != NULL)
        return [(id <NSObject>)propList autorelease];
    
    exception = [[NSException alloc] initWithName:NSParseErrorException reason:(NSString *)errorString userInfo:nil];
    
    [(NSString *)errorString release];
    
    [exception autorelease];
    [exception raise];
    /* NOT REACHED */
    return nil;
}


- (BOOL)writeToFile:(NSString *)path atomically:(BOOL)useAuxiliaryFile createDirectories:(BOOL)shouldCreateDirectories;
    // Will raise an exception if it can't create the required directories.
{
    if (shouldCreateDirectories) {
        // TODO: We ought to make the attributes configurable
        [[NSFileManager defaultManager] createPathToFile:path attributes:nil];
    }

    return [self writeToFile:path atomically:useAuxiliaryFile];
}

- (NSData *)dataByAppendingData:(NSData *)anotherData;
{
    unsigned int myLength, otherLength;
    NSMutableData *buffer;
    NSData *result;
    
    if (!anotherData)
        return [[self copy] autorelease];

    myLength = [self length];
    otherLength = [anotherData length];

    if (!otherLength) return [[self copy] autorelease];
    if (!myLength) return [[anotherData copy] autorelease];

    buffer = [[NSMutableData alloc] initWithCapacity:myLength + otherLength];
    [buffer appendData:self];
    [buffer appendData:anotherData];
    result = [buffer copy];
    [buffer release];

    return [result autorelease];
}

/*" Creates a stdio FILE pointer for reading from the receiver via the funopen() BSD facility.  The receiver is automatically retained until the returned FILE is closed. "*/

// Same context used for read and write.
typedef struct _NSDataFileContext {
    NSData *data;
    void   *bytes;
    size_t  length;
    size_t  position;
} NSDataFileContext;

static int _NSData_readfn(void *_ctx, char *buf, int nbytes)
{
    //fprintf(stderr, " read(ctx:%p buf:%p nbytes:%d)\n", _ctx, buf, nbytes);
    NSDataFileContext *ctx = (NSDataFileContext *)_ctx;

    nbytes = MIN((unsigned)nbytes, ctx->length - ctx->position);
    memcpy(buf, ctx->bytes + ctx->position, nbytes);
    ctx->position += nbytes;
    return nbytes;
}

static int _NSData_writefn(void *_ctx, const char *buf, int nbytes)
{
    //fprintf(stderr, "write(ctx:%p buf:%p nbytes:%d)\n", _ctx, buf, nbytes);
    NSDataFileContext *ctx = (NSDataFileContext *)_ctx;

    // Might be in the middle of a the file if a seek has been done so we can't just append naively!
    if (ctx->position + nbytes > ctx->length) {
        ctx->length = ctx->position + nbytes;
        [(NSMutableData *)ctx->data setLength:ctx->length];
        ctx->bytes = [(NSMutableData *)ctx->data mutableBytes]; // Might have moved after size change
    }

    memcpy(ctx->bytes + ctx->position, buf, nbytes);
    ctx->position += nbytes;
    return nbytes;
}

static fpos_t _NSData_seekfn(void *_ctx, off_t offset, int whence)
{
    //fprintf(stderr, " seek(ctx:%p off:%qd whence:%d)\n", _ctx, offset, whence);
    NSDataFileContext *ctx = (NSDataFileContext *)_ctx;

    size_t reference;
    if (whence == SEEK_SET)
        reference = 0;
    else if (whence == SEEK_CUR)
        reference = ctx->position;
    else if (whence == SEEK_END)
        reference = ctx->length;
    else
        return -1;

    if (reference + offset >= 0 && reference + offset <= ctx->length) {
        ctx->position = reference + offset;
        return ctx->position;
    }
    return -1;
}

static int _NSData_closefn(void *_ctx)
{
    //fprintf(stderr, "close(ctx:%p)\n", _ctx);
    NSDataFileContext *ctx = (NSDataFileContext *)_ctx;
    [ctx->data release];
    free(ctx);
    
    return 0;
}


- (FILE *)openReadOnlyStandardIOFile;
{
    NSDataFileContext *ctx = calloc(1, sizeof(NSDataFileContext));
    ctx->data = [self retain];
    ctx->bytes = (void *)[self bytes];
    ctx->length = [self length];
    //fprintf(stderr, "open read -> ctx:%p\n", ctx);

    FILE *f = funopen(ctx, _NSData_readfn, NULL/*writefn*/, _NSData_seekfn, _NSData_closefn);
    if (f == NULL)
        [self release]; // Don't leak ourselves if funopen fails
    return f;
}

/*" Compression/decompression.
    We use bz2 library here instead of zlib since the later has no way of dealing with full 'gzip' formatted blobs of bytes in memory.  The gzopen function only read/writes to paths, not memory.  The bz2 library (besides actually compressing better) has 'FILE' variants which we can then hook to memory using the funopen() BSD call.
"*/

static inline BOOL _OFMightBeBzipCompressedData(const unsigned char *bytes, unsigned int length)
{
    return (length >= 2 && bytes[0] == 'B' && bytes[1] == 'Z');
}

static inline BOOL _OFMightBeGzipCompressedData(const unsigned char *bytes, unsigned int length)
{
    return (length >= 10 && bytes[0] == 0x1F && bytes[1] == 0x8B);
}

/*" Returns YES if the receiver looks like it might be compressed data that -decompressedData can handle.  Note that if this returns YES, it merely looks like the receiver is compressed, not that it is.  This is a simply intended to be a quick check to filter out obviously uncompressed data. "*/
- (BOOL)mightBeCompressed;
{
    const unsigned char *bytes = [self bytes];
    unsigned int length = [self length];
    return _OFMightBeGzipCompressedData(bytes, length) || _OFMightBeBzipCompressedData(bytes, length);
}

- (NSData *)compressedData;
{
    return [self compressedDataWithGzipHeader:YES compressionLevel:9];
}

- (NSData *)decompressedData;
{
    const unsigned char *initial;
    unsigned dataLength;

    initial = [self bytes];
    dataLength = [self length];
    if (_OFMightBeBzipCompressedData(initial, dataLength))
        return [self decompressedBzip2Data];

    if (_OFMightBeGzipCompressedData(initial, dataLength))
        return [self decompressedGzipData];

    [NSException raise:NSInvalidArgumentException format:NSLocalizedStringFromTableInBundle(@"Unable to decompress data: unrecognized compression format", @"OmniFoundation", [OFObject bundle], @"decompression exception format")];
    return nil; /* NOTREACHED */
}


/*" Compresses the receiver using the bz2 library algorithm and returns the compressed data.   The compressed data is a full bz2 file, not just a headerless compressed blob.  This is very useful if you are including this compressed data in a larger file wrapper and want users to be able to read it with standard tools. "*/
- (NSData *)compressedBzip2Data;
{
#if defined(MAC_OS_X_VERSION_10_4) && MAC_OS_X_VERSION_MIN_REQUIRED >= MAC_OS_X_VERSION_10_4
    NSMutableData *output = [NSMutableData data];
    FILE *dataFile = [output openReadWriteStandardIOFile];
    
    int err;
    BZFILE *bzFile = NULL;
    if (dataFile)
        bzFile = BZ2_bzWriteOpen(&err, dataFile,
                                 6,  // blockSize100k from 1-9, 9 best compression, slowest speed
                                 0,  // verbosity
                                 0); // workFactor, 0-250, 0==default of 30
    if (!bzFile) {
        fclose(dataFile);
        [NSException raise:NSInvalidArgumentException format:NSLocalizedStringFromTableInBundle(@"Unable to initialize compression", @"OmniFoundation", [OFObject bundle], @"compression exception format")];
    }

    // BZ2_bzWrite fails with BZ_PARAM_ERROR when passed length==0; allow compressing empty data by just not doing a write.
    unsigned int length = [self length];
    if (length) {
        BZ2_bzWrite(&err, bzFile, (void  *)[self bytes], [self length]);
        if (err != BZ_OK) {
            // Create exception before closing file since we read from the file
            NSString *reason = [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"Unable to compress data (rc:%d '%s')", @"OmniFoundation", [OFObject bundle], @"compression exception format"), err, BZ2_bzerror(bzFile, &err)];
            NSException *exc = [NSException exceptionWithName:NSInvalidArgumentException reason:reason userInfo:nil];
            fclose(dataFile);
            BZ2_bzWriteClose(&err, bzFile, 0, NULL, NULL);
            [exc raise];
        }
    }

    BZ2_bzWriteClose(&err, bzFile, 0, NULL, NULL);
    if (err != BZ_OK) {
        fclose(dataFile);
        [NSException raise:NSInvalidArgumentException format:NSLocalizedStringFromTableInBundle(@"Unable to finish compressing data", @"OmniFoundation", [OFObject bundle], @"compression exception format")];
    }

    fclose(dataFile);
    return output;
#else
    return [self filterDataThroughCommandAtPath:@"/usr/bin/bzip2" withArguments:[NSArray arrayWithObjects:@"--compress", nil]];
#endif
}

/*" Decompresses the receiver using the bz2 library algorithm and returns the decompressed data.   The receiver must represent a full bz2 file, not just a headerless compressed blob.  This is very useful if you are including this compressed data in a larger file wrapper and want users to be able to read it with standard tools.  Throws an exception if the receiver does not contain valid compressed data. "*/
- (NSData *)decompressedBzip2Data;
{
#if defined(MAC_OS_X_VERSION_10_4) && MAC_OS_X_VERSION_MIN_REQUIRED >= MAC_OS_X_VERSION_10_4
    FILE *dataFile = [self openReadOnlyStandardIOFile];
    
    int err;
    BZFILE *bzFile = NULL;
    if (dataFile)
        bzFile = BZ2_bzReadOpen(&err, dataFile,
                                [self length] < 4*1024,  // small; set to 1 for things that are 'small' to use less memory
                                0,  // verbosity
                                NULL, 0); // unused
    if (!bzFile) {
        fclose(dataFile);
        [NSException raise:NSInvalidArgumentException format:NSLocalizedStringFromTableInBundle(@"Unable to initialize decompression", @"OmniFoundation", [OFObject bundle], @"decompression exception format")];
    }

    size_t pageSize  = NSPageSize();
    unsigned int totalBytesRead = 0;
    NSMutableData *output = [NSMutableData dataWithLength:4*pageSize];
    do {
        unsigned int avail = [output length] - totalBytesRead;
        if (avail < pageSize) {
            [output setLength:[output length] + 4*pageSize];
            avail = [output length] - totalBytesRead;
        }
        void *ptr = [output mutableBytes] + totalBytesRead;
        
        
        int bytesRead = BZ2_bzRead(&err, bzFile, ptr, avail);
        if (err != BZ_OK && err != BZ_STREAM_END) {
            // Create exception before closing file since we read from the file
            NSString *reason = [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"Unable to decompress data (rc:%d '%s')", @"OmniFoundation", [OFObject bundle], @"decompression exception format"), err, BZ2_bzerror(bzFile, &err)];
            NSException *exc = [NSException exceptionWithName:NSInvalidArgumentException reason:reason userInfo:nil];
            fclose(dataFile);
            BZ2_bzReadClose(&err, bzFile);
            [exc raise];
        }

        totalBytesRead += bytesRead;
    } while (err != BZ_STREAM_END);

    [output setLength:totalBytesRead];
    
    BZ2_bzReadClose(&err, bzFile);
    fclose(dataFile);
    
    return output;
#else
    return [self filterDataThroughCommandAtPath:@"/usr/bin/bzip2" withArguments:[NSArray arrayWithObjects:@"--decompress", nil]];
#endif
}

/* Support for RFC 1952 gzip formatting. This is a simple wrapper around the data produced by zlib. */

#define OF_ZLIB_BUFFER_SIZE (2 * 64 * 1024)
#define OFZlibExceptionName (@"OFZlibException")

static NSMutableData *makeRFC1952MemberHeader(time_t modtime,
                                              NSString *orig_filename,
                                              NSString *file_comment,
                                              BOOL withCRC16,
                                              BOOL isText,
                                              u_int8_t xfl)
{
    u_int8_t *header;
    uLong headerCRC;
    NSData *filename_bytes, *comment_bytes;
    NSMutableData *result;

    if (orig_filename)
        filename_bytes = [orig_filename dataUsingEncoding:NSISOLatin1StringEncoding allowLossyConversion:YES];
    else
        filename_bytes = nil;
    if (file_comment)
        comment_bytes = [file_comment dataUsingEncoding:NSISOLatin1StringEncoding allowLossyConversion:YES];
    else
        comment_bytes = nil;
        
    /* Allocate the result buffer */
    result = [NSMutableData dataWithLength: 10 +
        (filename_bytes? [filename_bytes length] + 1 : 0) +
        (comment_bytes? [comment_bytes length] + 1 : 0) +
        (withCRC16 ? 2 : 0)];

    header = [result mutableBytes];
    
    /* GZIP file magic */
    header[0] = 0x1F;
    header[1] = 0x8B;

    /* Indicates use of the GZIP compression method */
    header[2] = Z_DEFLATED;

    /* Flag field #1 */
    header[3] = (isText? 1 : 0) | (withCRC16? 2 : 0) | (filename_bytes? 8 : 0) | (comment_bytes? 16 : 0);

    /* Modification time stamp */
    header[4] = ( modtime & 0x000000FF );
    header[5] = ( modtime & 0x0000FF00 ) >> 8;
    header[6] = ( modtime & 0x00FF0000 ) >> 16;
    header[7] = ( modtime & 0xFF000000 ) >> 24;

    /* Indicates file was written on a Unixlike system; we're being more Unixy than traditional-Mac-like */
    header[8] = 3;

    /* Flag field #2 */
    /* The XFLAG field is documented to have some bits set according to the compression level used by the compressor, but nobody actually reads it; it's not necessary to decompress the data, and RFC1952 doesn't really specify when each bit should be set anyway. So we don't worry about it overmuch. */    
    header[9] = xfl;
    
    /* Initialize the header CRC */
    headerCRC = crc32(0L, Z_NULL, 0);
    
    /* Update the CRC as we go */
    headerCRC = crc32(headerCRC, header, 10);
    header += 10;
    
    /* Filename, if we have one, with terminating NUL */
    if (filename_bytes) {
        int length = [filename_bytes length];
        [filename_bytes getBytes:header];
        header[length] = (char)0;
        headerCRC = crc32(headerCRC, header, length+1);
        header += length+1;
    }
    
    /* File comment, if we have one, with terminating NUL */
    if (comment_bytes) {
        int length = [comment_bytes length];
        [comment_bytes getBytes:header];
        header[length] = (char)0;
        headerCRC = crc32(headerCRC, header, length+1);
        header += length+1;
    }
    
    /* Header CRC */
    if (withCRC16) {
        header[0] = ( headerCRC & 0x00FF );
        header[1] = ( headerCRC & 0xFF00 ) >> 8;
        header += 2;
    }

    OBPOSTCONDITION( (unsigned)((char *)header - (char *)[result bytes]) == [result length] );

    return result;
}

static BOOL readNullTerminatedString(FILE *fp,
                                     NSStringEncoding encoding,
                                     NSString **into,
                                     uLong *runningCRC)
{
    CFMutableDataRef buffer;
    int ch;

    buffer = CFDataCreateMutable(kCFAllocatorDefault, 0);

    do {
        UInt8 chBuf[1];

        ch = getc(fp);
        if (ch == EOF) {
            CFRelease(buffer);
            return NO;
        }

        chBuf[0] = ch;
        CFDataAppendBytes(buffer, chBuf, 1);
    } while (ch != 0);

    *runningCRC = crc32(*runningCRC, CFDataGetBytePtr(buffer), CFDataGetLength(buffer));

    if (into) {
        *into = [[[NSString alloc] initWithData:(NSData *)buffer encoding:encoding] autorelease];
    }

    CFRelease(buffer);
    return YES;
}


static BOOL checkRFC1952MemberHeader(FILE *fp,
                                     NSString **orig_filename,
                                     NSString **file_comment,
                                     BOOL *isText)
{
    u_int8_t header[10];
    size_t count;
    uLong runningCRC;

    count = fread(header, 1, 10, fp);
    if (count != 10)
        return NO;

    /* File magic */
    if (header[0] != 0x1F || header[1] != 0x8B)
        return NO;

    /* Compression algorithm: only Z_DEFLATED is valid */
    if (header[2] != Z_DEFLATED)
        return NO;

    /* Flags field */
    if (isText)
        *isText = ( header[3] & 1 ) ? YES : NO;

    /* Ignore modification time, XFL, and OS fields for now */

    runningCRC = crc32( crc32(0L, NULL, 0), header, 10 );

    /* We don't handle the FEXTRA field, which means we're not actually RFC1952-conformant. It's pretty rare, but we really should at least skip it. TODO. */
    if (header[3] & 0x04)
        return NO;
    
    /* Skip/read the filename. */
    if (header[3] & 0x08) {
        if (!readNullTerminatedString(fp, NSISOLatin1StringEncoding, orig_filename, &runningCRC))
            return NO;
    }

    /* Skip/read the file comment. */
    if (header[3] & 0x10) {
        if (!readNullTerminatedString(fp, NSISOLatin1StringEncoding, file_comment, &runningCRC))
            return NO;
    }
    
    /* Verify the CRC, if present. */
    if (header[3] & 0x02) {
        u_int8_t crc_buffer[2];
        unsigned storedCRC;

        if (fread(crc_buffer, 1, 2, fp) != 2)
            return NO;
        storedCRC = ( (unsigned)crc_buffer[0] ) | ( 256 * (unsigned)crc_buffer[1] );
        if (storedCRC != ( runningCRC & 0xFFFF ))
            return NO;
    }
    
    /* We've successfuly run the gauntlet. */
    return YES;
}


static NSException *OFZlibException(int errorCode, z_stream *state)
{
    if (state && state->msg) {
        return [NSException exceptionWithName:OFZlibExceptionName reason:[NSString stringWithCString:state->msg] userInfo:nil];
    } else {
        return [NSException exceptionWithName:OFZlibExceptionName reason:[NSString stringWithFormat:@"zlib: error code %d", errorCode] userInfo:nil];
    }
}

static void writeLE32(u_int32_t le32, FILE *fp)
{
    putc( (le32 & 0x000000FF)      , fp );
    putc( (le32 & 0x0000FF00) >>  8, fp );
    putc( (le32 & 0x00FF0000) >> 16, fp );
    putc( (le32 & 0xFF000000) >> 24, fp );
}

static u_int32_t unpackLE32(const u_int8_t *from)
{
    return ( (u_int32_t)from[0] ) |
    ( (u_int32_t)from[1] << 8 ) |
    ( (u_int32_t)from[2] << 16 ) |
    ( (u_int32_t)from[3] << 24 );
}

static NSException *handleRFC1952MemberBody(FILE *fp,
                                            NSData *data,
                                            NSRange sourceRange,
                                            int compressionLevel,
                                            BOOL withTrailer,
                                            BOOL compressing)
{
    uLong dataCRC;
    z_stream compressionState;
    Bytef *outputBuffer;
    unsigned outputBufferSize;
    int ok;

    dataCRC = crc32(0L, Z_NULL, 0);
    
    if (compressionLevel < 0)
        compressionLevel = Z_DEFAULT_COMPRESSION;
    bzero(&compressionState, sizeof(compressionState));
    if (compressing) {
        /* Annoyingly underdocumented parameter: must pass windowBits = -MAX_WBITS to suppress the zlib header. */
        ok = deflateInit2(&compressionState, compressionLevel,
                          Z_DEFLATED, -MAX_WBITS, 9, Z_DEFAULT_STRATEGY);
        /* compressionState.data_type = dataType; */
    } else {
        ok = inflateInit2(&compressionState, -MAX_WBITS);
    }
    if (ok != Z_OK)
        return OFZlibException(ok, &compressionState);

    outputBuffer = malloc(outputBufferSize = OF_ZLIB_BUFFER_SIZE);

    compressionState.next_in = (Bytef *)[data bytes] + sourceRange.location;
    compressionState.avail_in = sourceRange.length;
    if (withTrailer && !compressing) {
        /* Subtract 8 bytes for the CRC and length which are stored after the compressed data. */
        if (sourceRange.length < 8) {
            return [NSException exceptionWithName:OFZlibExceptionName reason:@"zlib stream is too short" userInfo:nil];
        }
    }

    for(;;) {
        compressionState.next_out = outputBuffer;
        compressionState.avail_out = outputBufferSize;
        // printf("before: in = %u @ %p, out = %u @ %p\n", compressionState.avail_in, compressionState.next_in, compressionState.avail_out, compressionState.next_out);
        if (compressing) {
            const Bytef *last_in = compressionState.next_in;
            ok = deflate(&compressionState, Z_FINISH);
            if (compressionState.next_in > last_in)
                dataCRC = crc32(dataCRC, last_in, compressionState.next_in - last_in);
        } else {
            ok = inflate(&compressionState, Z_SYNC_FLUSH);
            if (compressionState.next_out > outputBuffer)
                dataCRC = crc32(dataCRC, outputBuffer, compressionState.next_out - outputBuffer);
        }
        // printf("after : in = %u @ %p, out = %u @ %p, ok = %d\n", compressionState.avail_in, compressionState.next_in, compressionState.avail_out, compressionState.next_out, ok);
        if (compressionState.next_out > outputBuffer)
            fwrite(outputBuffer, compressionState.next_out - outputBuffer, 1, fp);
        if (ok == Z_STREAM_END)
            break;
        else if (ok != Z_OK) {
            NSException *error = OFZlibException(ok, &compressionState);
            deflateEnd(&compressionState);
            free(outputBuffer);
            return error;
        }
    }

    if (compressing)
        ok = deflateEnd(&compressionState);
    else
        ok = inflateEnd(&compressionState);
    OBASSERT(ok == Z_OK);
    if (compressing || !withTrailer) {
        OBASSERT(compressionState.avail_in == 0);
    } else {
        /* Assert that there's space for the CRC and length at the end of the buffer */
        OBASSERT(compressionState.avail_in == 8);
    }

    free(outputBuffer);

    if (withTrailer && compressing) {
        writeLE32(dataCRC, fp);
        writeLE32((0xFFFFFFFFUL & sourceRange.length), fp);
    }
    if (withTrailer && !compressing) {
        u_int32_t storedCRC, storedLength;
        const u_int8_t *trailerStart;

        trailerStart = [data bytes] + sourceRange.location + sourceRange.length - 8;
        storedCRC = unpackLE32(trailerStart);
        storedLength = unpackLE32(trailerStart + 4);
        
        if (dataCRC != storedCRC)
            return [NSException exceptionWithName:OFZlibExceptionName reason:[NSString stringWithFormat:@"CRC error: stored CRC (%08X) does not match computed CRC (%08X)", storedCRC, dataCRC] userInfo:nil];
        if (storedLength != (0xFFFFFFFFUL & compressionState.total_out))
            return [NSException exceptionWithName:OFZlibExceptionName reason:[NSString stringWithFormat:@"Gzip error: stored length (%lu) does not match decompressed length (%lu)", (unsigned long)storedLength, (unsigned long)(0xFFFFFFFFUL & compressionState.total_out)] userInfo:nil];
    }
    

    return nil;
}

- (NSData *)compressedDataWithGzipHeader:(BOOL)includeHeader compressionLevel:(int)level
{
    NSException *error;
    NSMutableData *result;
    FILE *writeStream;
    
    if (includeHeader)
        result = makeRFC1952MemberHeader((time_t)0, nil, nil, NO, NO, 0);
    else
        result = [NSMutableData data];

    writeStream = [result openReadWriteStandardIOFile];
    fseek(writeStream, 0, SEEK_END);
    error = handleRFC1952MemberBody(writeStream, self, (NSRange){0, [self length]}, level, includeHeader, YES);
    fclose(writeStream);

    if (error)
        [error raise];

    return result;
}

- (NSData *)decompressedGzipData;
{
    FILE *readMe, *writeMe;
    BOOL ok;
    long headerLength;
    NSException *error;
    NSMutableData *result;

    readMe = [self openReadOnlyStandardIOFile];
    ok = checkRFC1952MemberHeader(readMe, NULL, NULL, NULL);
    headerLength = ftell(readMe);
    fclose(readMe);
    if (!ok) {
        [[NSException exceptionWithName:OFZlibExceptionName reason:NSLocalizedStringFromTableInBundle(@"Unable to decompress gzip data: invalid header", @"OmniFoundation", [OFObject bundle], @"decompression exception format") userInfo:nil] raise];
    }

    result = [NSMutableData data];
    writeMe = [result openReadWriteStandardIOFile];
    error = handleRFC1952MemberBody(writeMe, self,
                                    (NSRange){ headerLength, [self length] - headerLength },
                                    Z_DEFAULT_COMPRESSION, YES, NO);
    fclose(writeMe);

    if (error)
        [error raise];

    return result;
}

// UNIX filters

- (NSData *)filterDataThroughCommandAtPath:(NSString *)commandPath withArguments:(NSArray *)arguments;
{
    int childInputReadDescriptor, childInputWriteDescriptor;
    int childOutputReadDescriptor, childOutputWriteDescriptor;
    {
        int pipeFD[2];

        if (pipe(pipeFD) != 0) {
            [NSException raise:NSGenericException posixErrorNumber:OMNI_ERRNO() format:NSLocalizedStringFromTableInBundle(@"Error filtering data through UNIX command %@: %s", @"OmniFoundation", [NSBundle bundleForClass:[OFObject class]], @"Error encountered when trying to pass data through a UNIX command, details in parameters"), commandPath, strerror(OMNI_ERRNO())];
        }
        childInputReadDescriptor = pipeFD[0];
        childInputWriteDescriptor = pipeFD[1];

        if (pipe(pipeFD) != 0) {
            close(childInputReadDescriptor);
            close(childInputWriteDescriptor);
            [NSException raise:NSGenericException posixErrorNumber:OMNI_ERRNO() format:NSLocalizedStringFromTableInBundle(@"Error filtering data through UNIX command %@: %s", @"OmniFoundation", [NSBundle bundleForClass:[OFObject class]], @"Error encountered when trying to pass data through a UNIX command, details in parameters"), commandPath, strerror(OMNI_ERRNO())];
        }
        childOutputReadDescriptor = pipeFD[0];
        childOutputWriteDescriptor = pipeFD[1];
    }

    const char *toolPath = [[NSFileManager defaultManager] fileSystemRepresentationWithPath:commandPath];
    unsigned int argumentIndex, argumentCount = [arguments count];
    char *toolParameters[argumentCount + 2];
    toolParameters[0] = strdup(toolPath);
    for (argumentIndex = 0; argumentIndex < argumentCount; argumentIndex++) {
        toolParameters[argumentIndex + 1] = strdup([[arguments objectAtIndex:argumentIndex] UTF8String]);
    }
    toolParameters[argumentCount + 1] = NULL;

    pid_t child = vfork();
    switch (child) {
        case -1: // Error
            close(childInputReadDescriptor);
            close(childInputWriteDescriptor);
            close(childOutputReadDescriptor);
            close(childOutputWriteDescriptor);
            [NSException raise:NSGenericException posixErrorNumber:OMNI_ERRNO() format:NSLocalizedStringFromTableInBundle(@"Error filtering data through UNIX command %@: %s", @"OmniFoundation", [NSBundle bundleForClass:[OFObject class]], @"Error encountered when trying to pass data through a UNIX command, details in parameters"), commandPath, strerror(OMNI_ERRNO())];
            OBASSERT_NOT_REACHED("Raising an exception should not return");

        case 0: // Child
            // Close the parent's halves of the input and output pipes
            close(childInputWriteDescriptor);
            close(childOutputReadDescriptor);

            if (dup2(childInputReadDescriptor, STDIN_FILENO) != STDIN_FILENO)
                _exit(1); // Use _exit() not exit(): don't flush the parent's file buffers
            if (dup2(childOutputWriteDescriptor, STDOUT_FILENO) != STDOUT_FILENO)
                _exit(1); // Use _exit() not exit(): don't flush the parent's file buffers

            close(childInputReadDescriptor); // We've copied this to STDIN_FILENO, we can close the other descriptor now
            close(childOutputWriteDescriptor); // We've copied this to STDOUT_FILENO, we can close the other descriptor now
            close(STDERR_FILENO); // The child doesn't need stderr

            execv(toolPath, toolParameters);
            _exit(1); // Use _exit() not exit(): don't flush the parent's file buffers
            OBASSERT_NOT_REACHED("_exit() should not return");

        default: // Parent
            break;
    }

    int childStatus;

    // Close the child's halves of the input and output pipes
    close(childInputReadDescriptor);
    close(childOutputWriteDescriptor);
    
    // Don't block when writing to our child's input stream
    fcntl(childInputWriteDescriptor, F_SETFL, O_NONBLOCK);

    unsigned int writeDataOffset = 0, writeDataLength = [self length];
    const void *writeBytes = [self bytes];

    unsigned int filteredDataOffset = 0, filteredDataCapacity = 8192;
    NSMutableData *filteredData = [NSMutableData dataWithLength:filteredDataCapacity];
    void *filteredDataBytes = [filteredData mutableBytes];
    while (YES) {
        // Write some data to the child's input stream
        if (writeDataOffset < writeDataLength) {
            int bytesWritten = write(childInputWriteDescriptor, writeBytes + writeDataOffset, writeDataLength - writeDataOffset);
            if (bytesWritten == -1) {
                if (OMNI_ERRNO() == EINTR || OMNI_ERRNO() == EAGAIN)
                    continue;

                close(childInputWriteDescriptor);
                close(childOutputReadDescriptor);
                waitpid(child, &childStatus, 0);
                [NSException raise:NSGenericException posixErrorNumber:OMNI_ERRNO() format:NSLocalizedStringFromTableInBundle(@"Error filtering data through UNIX command %@: %s", @"OmniFoundation", [NSBundle bundleForClass:[OFObject class]], @"Error encountered when trying to pass data through a UNIX command, details in parameters"), commandPath, strerror(OMNI_ERRNO())];
            }
            writeDataOffset += bytesWritten;
            if (writeDataOffset == writeDataLength) {
                // We're done, close the child's input stream
                close(childInputWriteDescriptor);
            }
        }

        // Read filtered data from the child's output stream
        int bytesRead = read(childOutputReadDescriptor, filteredDataBytes + filteredDataOffset, filteredDataCapacity - filteredDataOffset);

        if (bytesRead == 0)
            break;

        if (bytesRead == -1) {
            if (OMNI_ERRNO() == EINTR)
                continue;

            close(childInputWriteDescriptor);
            close(childOutputReadDescriptor);
            waitpid(child, &childStatus, 0);
            [NSException raise:NSGenericException posixErrorNumber:OMNI_ERRNO() format:NSLocalizedStringFromTableInBundle(@"Error filtering data through UNIX command %@: %s", @"OmniFoundation", [NSBundle bundleForClass:[OFObject class]], @"Error encountered when trying to pass data through a UNIX command, details in parameters"), commandPath, strerror(OMNI_ERRNO())];
        }

        filteredDataOffset += bytesRead;
        if (filteredDataOffset == filteredDataCapacity) {
            filteredDataCapacity += filteredDataCapacity; // Double the capacity
            [filteredData setLength:filteredDataCapacity];
            filteredDataBytes = [filteredData mutableBytes];
        }
    }

    if (writeDataOffset < writeDataLength) {
        // The child closed its output stream without reading all its input.  (This can happen, for example, when the child is "head".)
        close(childInputWriteDescriptor);
    }
    close(childOutputReadDescriptor);
    [filteredData setLength:filteredDataOffset];
    do {
        waitpid(child, &childStatus, 0);
    } while (!WIFEXITED(childStatus));
    unsigned int terminationStatus = WEXITSTATUS(childStatus);
    if (terminationStatus != 0)
        [NSException raise:NSGenericException posixErrorNumber:OMNI_ERRNO() format:NSLocalizedStringFromTableInBundle(@"Error filtering data through UNIX command %@: command returned %d", @"OmniFoundation", [NSBundle bundleForClass:[OFObject class]], @"Error encountered when trying to pass data through a UNIX command, details in parameters"), commandPath, terminationStatus];

    return [NSData dataWithData:filteredData];
}

@end


@implementation NSMutableData (OFIOExtensions)

- (FILE *)openReadWriteStandardIOFile;
{
    NSDataFileContext *ctx = calloc(1, sizeof(NSDataFileContext));
    ctx->data   = [self retain];
    ctx->bytes  = [self mutableBytes];
    ctx->length = [self length];
    //fprintf(stderr, "open write -> ctx:%p\n", ctx);
    
    FILE *f = funopen(ctx, _NSData_readfn, _NSData_writefn, _NSData_seekfn, _NSData_closefn);
    if (f == NULL)
        [self release]; // Don't leak ourselves if funopen fails
    return f;
}

@end
