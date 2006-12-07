// Copyright 2000-2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.

#import <OmniFoundation/OFStringDecoder.h>
#import <Foundation/Foundation.h>
#import <OmniBase/OmniBase.h>

RCS_ID("$Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniFoundation/OFStringDecoder.m,v 1.10 2003/01/15 22:51:50 kc Exp $")

/* From the Unicode standard:
 * U+FFFD REPLACEMENT CHARACTER 
 * used to replace an incoming character whose value is unknown or unrepresentable in Unicode
 */
#define UNKNOWN_CHAR OF_UNICODE_REPLACEMENT_CHARACTER

NSString *OFCharacterConversionExceptionName = @"OFCharacterConversionException";


/* This is a merge of the real CP1252 mapping with Netscape's use of the few unused code points in 1252. */
static const unichar cp1252UpperRegionMap[0x20] = 
{
    0x20AC,
    UNKNOWN_CHAR,
    0x201a,
    0x0192,
    0x201e,
    0x2026,
    0x2020,
    0x2021,
    0x02c6,
    0x2030,
    0x0160,
    0x2039,
    0x0152,
    UNKNOWN_CHAR,
    0x017d,
    UNKNOWN_CHAR,
    
    UNKNOWN_CHAR,
    0x2018,
    0x2019,
    0x201c,
    0x201d,
    0x2022,
    0x2013,
    0x2014,
    0x02dc,
    0x2122,
    0x0161,
    0x203a,
    0x0153,
    UNKNOWN_CHAR,
    0x017e,
    0x0178
};

// These are some CFStringEncodings which are "simple" in the sense of OFEncodingIsSimple() and which aren't handled elsewhere. Simple encodings not listed here will be treated as complex encodings, which will produce correct results but will prevent incremental display
#define SIMPLE_FOUNDATION_ENCODINGS \
        case kCFStringEncodingMacRoman: \
        case kCFStringEncodingNextStepLatin: \
        case kCFStringEncodingMacRomanLatin1: \
        case kCFStringEncodingKOI8_R:

static inline struct OFCharacterScanResult OFScanUTF8CharactersIntoBuffer(struct OFStringDecoderState state, unsigned char *in_bytes, unsigned int in_bytes_count, unichar *out_characters, unsigned int out_characters_max)
{
    unsigned char *in_bytes_orig = in_bytes;
    unsigned char *in_bytes_end = in_bytes + in_bytes_count;
    unichar *out_characters_orig = out_characters;
    unichar *out_characters_end = out_characters + out_characters_max;
    while (in_bytes < in_bytes_end && out_characters < out_characters_end) {

        /* Handle any partial or long characters ... */
        if (state.vars.utf8.utf8octetsremaining > 0) {
        while (state.vars.utf8.utf8octetsremaining > 0 && in_bytes < in_bytes_end) {
            state.vars.utf8.partialCharacter = (state.vars.utf8.partialCharacter << 6) | (unichar)(in_bytes[0] & 0x3F);
            state.vars.utf8.utf8octetsremaining --;
            in_bytes ++;
        }
        if (state.vars.utf8.utf8octetsremaining == 0) {
            if (state.vars.utf8.partialCharacter < 0x10000) {
                /* Character can be represented in 16-bit Unicode */
                *out_characters++ = (unichar)state.vars.utf8.partialCharacter;
            } else if (state.vars.utf8.partialCharacter < 0x110000) {
                /* Character requires two UTF-16 points (a surrogate pair) */
                if ((out_characters+2) > out_characters_end) {
                    /* Not enough room for both surrogate chars: handle this on the next call */
                    break; /* return to caller */
                }

                OFCharacterToSurrogatePair(state.vars.utf8.partialCharacter, out_characters);
                out_characters += 2;
            } else {
                /* Character cannot be represented in UTF-16: it is not in the BMP or the sixteen Supplementary Planes. It's probably bogus. */
                *out_characters++ = UNKNOWN_CHAR;
            }
        } else 
            break; /* we ran out of input bytes. don't fall through to the fast loop. */
        }
        
        /* This loop takes care of the common case: characters in the 0000-FFFF range, not crossing a buffer boundary */
        while (out_characters < out_characters_end && in_bytes < in_bytes_end) {
            unsigned char aByte = *in_bytes;
            unichar aCharacter;
            
            if ((aByte & 0x80) == 0x00) {
                aCharacter = (unichar)aByte;
                in_bytes ++;
            } else if ((aByte & 0xE0) == 0xC0) {
                if (in_bytes + 1 >= in_bytes_end) {
                    state.vars.utf8.partialCharacter = (aByte & 0x1F);
                    state.vars.utf8.utf8octetsremaining = 1;
                    in_bytes ++;
                    break;
                }
                
                if ((in_bytes[1] & 0xC0) != 0x80) {
                    aCharacter = UNKNOWN_CHAR;
                } else {
                    aCharacter = ((((unsigned int)aByte) & 0x1F) << 6) |
                        (((unsigned int)in_bytes[1]) & 0x3F);
                }
                in_bytes += 2;
            } else if ((aByte & 0xF0) == 0xE0) {
                unsigned int byte2, byte3;
                
                if (in_bytes + 2 >= in_bytes_end) {
                    state.vars.utf8.partialCharacter = (aByte & 0x0F);
                    state.vars.utf8.utf8octetsremaining = 2;
                    in_bytes ++;
                    break;
                }
                
                byte2 = in_bytes[1];
                byte3 = in_bytes[2];
                
                if ((byte2 & 0xC0) != 0x80 || (byte3 & 0xC0) != 0x80) {
                    aCharacter = UNKNOWN_CHAR;
                } else {
                    aCharacter = ((((unsigned int)aByte) & 0x0F) << 12) |
                        ((byte2 & 0x3F) << 6) |
                        (byte3 & 0x3F);
                }
                in_bytes += 3;
            } else if ((aByte & 0xF8) == 0xF0) {
                state.vars.utf8.partialCharacter = (aByte & 0x07);
                state.vars.utf8.utf8octetsremaining = 3;
                in_bytes ++;
                break;
            } else if ((aByte & 0xFC) == 0xF8) {
                state.vars.utf8.partialCharacter = (aByte & 0x03);
                state.vars.utf8.utf8octetsremaining = 4;
                in_bytes ++;
                break;
            } else if ((aByte & 0xFE) == 0xFC) {
                state.vars.utf8.partialCharacter = (aByte & 0x01);
                state.vars.utf8.utf8octetsremaining = 5;
                in_bytes ++;
                break;
            } else {
                /* An illegal byte sequence --- either 0xFE, 0xFF, or an out of place continuation character */
                in_bytes ++;
                aCharacter = UNKNOWN_CHAR;
            }
            
            *out_characters++ = aCharacter;
        } /* end of fast loop */

        /* exiting this loop, we have either run out of bytes, run out of space for characters, encountered a long multibyte sequence, or a combination of these conditions */
        /* the outer loop will take care of multibyte sequences */
    }
    
    return (struct OFCharacterScanResult){state, bytesConsumed: in_bytes - in_bytes_orig, charactersProduced: out_characters - out_characters_orig};
    
}

struct OFCharacterScanResult OFScanCharactersIntoBuffer(struct OFStringDecoderState state, unsigned char *in_bytes, unsigned int in_bytes_count, unichar *out_characters, unsigned int out_characters_max)
{

    /* Optimizations for NSASCIIStringEncoding, NSISOLatin1StringEncoding, and NSWindowsCP1252StringEncoding */

#define SINGLE_BYTE_MAPPING(transform) \
    {                                                                           \
        unsigned int toScan = MIN(in_bytes_count, out_characters_max);          \
        struct OFCharacterScanResult result;                                    \
        result.state = state;                                                   \
        result.bytesConsumed = result.charactersProduced = toScan;              \
        in_bytes += toScan;                                                     \
        out_characters += toScan;                                               \
        while (toScan > 0) {                                                    \
            unsigned char aCharacter = *--in_bytes;                             \
            toScan --;                                                          \
            *--out_characters = (transform);                                    \
        }                                                                       \
        return result;                                                          \
    }
    
    
    switch (state.encoding) {
        case kCFStringEncodingASCII:
            SINGLE_BYTE_MAPPING( ((aCharacter & 0x80) == 0x00) ? (unichar)aCharacter : UNKNOWN_CHAR );
        case kCFStringEncodingISOLatin1:
            SINGLE_BYTE_MAPPING( ((aCharacter & 0xE0) == 0x80) ? UNKNOWN_CHAR : (unichar)aCharacter );
        case kCFStringEncodingWindowsLatin1:
            SINGLE_BYTE_MAPPING( ((aCharacter & 0xE0) == 0x80) ? cp1252UpperRegionMap[aCharacter - 0x80] : (unichar)aCharacter );
        
        case kCFStringEncodingUTF8:
            return OFScanUTF8CharactersIntoBuffer(state, in_bytes, in_bytes_count, out_characters, out_characters_max);
    
        SIMPLE_FOUNDATION_ENCODINGS
            {   
                unsigned int toScan;
                // NSData *byteBuffer;
                NSString *stringBuffer;
                
                toScan = MIN(in_bytes_count, out_characters_max);  
                // byteBuffer = [[NSData alloc] initWithBytesNoCopy:in_bytes length:toScan];
                // stringBuffer = [[NSString alloc] initWithData:byteBuffer encoding:state.encoding];
                stringBuffer = (NSString *)CFStringCreateWithBytes(kCFAllocatorDefault, in_bytes, toScan, state.encoding, TRUE);
                // [byteBuffer release];
                OBASSERT([stringBuffer length] == toScan);
                [stringBuffer getCharacters:out_characters];
                [stringBuffer release];
                return (struct OFCharacterScanResult){state, bytesConsumed:toScan, charactersProduced:toScan};
            }
    }
    
    [NSException raise:NSInvalidArgumentException format:@"Unsupported character encoding in fast string decoder: %d (%@)", state.encoding, CFStringGetNameOfEncoding(state.encoding)];
    /* NOT REACHED */
    return (struct OFCharacterScanResult){ };
}
        
BOOL OFCanScanEncoding(CFStringEncoding anEncoding)
{
    switch (anEncoding) {
        case kCFStringEncodingASCII:
        case kCFStringEncodingISOLatin1:
        case kCFStringEncodingWindowsLatin1:
        case kCFStringEncodingUTF8:
            return YES;
        SIMPLE_FOUNDATION_ENCODINGS
            return YES;
        default:
            return NO;
    }
}

BOOL OFEncodingIsSimple(CFStringEncoding anEncoding)
{
    switch (anEncoding) {
        case kCFStringEncodingASCII:
        case kCFStringEncodingISOLatin1:
        case kCFStringEncodingWindowsLatin1:
            return YES;
        SIMPLE_FOUNDATION_ENCODINGS
            return YES;
        default:
            return NO;
    }
}

struct OFStringDecoderState OFInitialStateForEncoding(CFStringEncoding anEncoding)
{
    if (OFCanScanEncoding(anEncoding)) {
        struct OFStringDecoderState result;
        
        memset(&result, 0, sizeof(result));
        result.encoding = anEncoding;
        if (anEncoding == kCFStringEncodingUTF8) {
            result.vars.utf8.utf8octetsremaining = 0;
        }
        return result;
    }
    
    [NSException raise:NSInvalidArgumentException format:@"Unsupported character encoding in fast string decoder: %d (%@)", anEncoding, CFStringGetNameOfEncoding(anEncoding)];
    /* NOT REACHED */
    return (struct OFStringDecoderState){ };
}

BOOL OFDecoderContainsPartialCharacters(struct OFStringDecoderState state)
{
    switch (state.encoding) {
        case kCFStringEncodingUTF8:
            return state.vars.utf8.utf8octetsremaining != 0;
        default:
            /* All of our other encodings at the moment are simple, so we cannot contain a partial character */
            return NO;
    }
    
    /* NB: If we ever implement shift-JIS or other encodings with shift sequences, we'll have to return YES if we're in a shift state other than the initial state, or else the callers of this function may behave incorrectly. In that case perhaps we should rename this function as well, or have two functions. */
}
