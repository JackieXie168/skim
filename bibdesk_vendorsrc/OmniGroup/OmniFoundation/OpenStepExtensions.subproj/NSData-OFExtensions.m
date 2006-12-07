// Copyright 1998-2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.

#import <OmniFoundation/NSData-OFExtensions.h>

#import <Foundation/Foundation.h>
#import <CoreFoundation/CoreFoundation.h>
#import <OmniBase/OmniBase.h>

#import <OmniFoundation/NSFileManager-OFExtensions.h>
#import <OmniFoundation/NSString-OFExtensions.h>
#import <OmniFoundation/OFDataBuffer.h>
#import <OmniFoundation/OFRandom.h>

#import "sha1.h"
#import <OmniFoundation/md5.h>

RCS_ID("$Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniFoundation/OpenStepExtensions.subproj/NSData-OFExtensions.m,v 1.40 2003/01/15 22:51:59 kc Exp $")

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

#define BASE64_GETC (length > 0 ? (length--, bytes++, bytes[-1]) : (unsigned int)EOF)
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
    int c1, c2, c3, c4;
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
// Anything else is illegal.
//
// Output strings are four-character tuples separated by dashes.  The last
// tuple might have fewer than four characters.
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
    const char *bytesToProcess;
    unsigned int lengthToProcess, currentLengthToProcess;
    SHA1_CTX context;
    char signature[SHA1_SIGNATURE_LENGTH];

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

- (BOOL)containsData:(NSData *)data;
{
    unsigned const char *selfPtr, *selfEnd, *selfRestart, *ptr, *ptrRestart, *end;

    ptrRestart = [data bytes];
    end = ptrRestart + [data length];
    selfRestart = [self bytes];
    selfEnd = selfRestart + [self length] - [data length];
    
    while(selfRestart <= selfEnd) {
        selfPtr = selfRestart;
        ptr = ptrRestart;
        while(ptr < end) {
            if (*ptr++ != *selfPtr++) 
                break;
        }
        if (ptr == end)
            return YES;
        selfRestart++;
    }
    return NO;
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


#if defined(sun)

- (BOOL)writeToFile:(NSString *)path atomically:(BOOL)useAuxiliaryFile;
{
#warning Ryan: This method does not reimplement atomic writing of files but it works for most purposes that we need  

    FILE *fp;
    int length;

    fp = fopen([path cString], "w");
    if (fp == NULL)
        return NO;

    length = [self length];
    if (fwrite([self bytes], 1, length, fp) < length)
        return NO;

    fclose(fp);

    return YES;
}

#endif

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
    
@end

#if OBOperatingSystemMajorVersion == 5 && OBOperatingSystemMinorVersion == 2

#warning On Mac OS X Server 1.0, replacing -[NSData initWithContentsOfMappedFile:] with one which actually maps files

// On Mac OS X Server 1.0, -initWithContentsOfMappedFile: immediately reads the entire file via read(), which was Apple's quick fix to avoid a semantic difference between mapping HFS files and UFS files:  on HFS filesystems, an open file cannot be removed, renamed, etc.  (Most NSDocument applications would be bit by this, since some mapped data might still be in memory when they try to replace the file on disk.)

// We're overriding their version with one which checks whether we're on hfs, and if we're not we'll map the file using Mach and some private NSData API.  (Apple has apparently already implemented this behavior in later versions of Foundation.)

#import <OmniBase/system.h>

@interface NSData (PrivateAPI)
- (id)initWithBytes:(void *)bytes length:(unsigned int)length copy:(BOOL)copy freeWhenDone:(BOOL)free bytesAreVM:(BOOL)vm;
@end

@interface NSData (OFFixes)
- (id)initWithContentsOfMappedFile:(NSString *)path;
@end

@implementation NSData (OFFixes)

- (id)initWithContentsOfMappedFile:(NSString *)path;
{
    if ([[[NSFileManager defaultManager] fileSystemTypeForPath:path] isEqualToString:@"hfs"]) {
        // Mapping a file doesn't have the same semantics under HFS, so let's not try it.
    } else {
        char fileSystemRepresentationOfPath[MAXPATHLEN];
        int fd;

        [path getFileSystemRepresentation:fileSystemRepresentationOfPath maxLength:sizeof(fileSystemRepresentationOfPath)];
        if ((fd = open(fileSystemRepresentationOfPath, O_RDONLY, 0)) != -1) {
            struct stat statbuf;

            if (fstat(fd, &statbuf) != -1) {
                vm_offset_t addr;
                kern_return_t rc;

                // int map_fd(int fd, vm_offset_t offset, vm_offset_t *address, boolean_t Þnd_space, vm_size_t size)
                rc = map_fd(fd, 0, &addr, TRUE, statbuf.st_size);
                close(fd);

                if (rc == KERN_SUCCESS) {
                    // Everything worked, let's return an NSData initialized with the mapped bytes
                    return [self initWithBytes:(void *)addr length:statbuf.st_size copy:NO freeWhenDone:YES bytesAreVM:YES];
                }
            }
            close(fd);
        }
    }
    // Mapping the file failed, so let's read the file using the non-mapped implementation.  (If -initWithContentsOfFile: also has problems, it can raise its own exception.)
    return [self initWithContentsOfFile:path];
}

@end

#endif
