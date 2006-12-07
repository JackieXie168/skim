// Copyright 2000-2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniFoundation/OFStringDecoder.h,v 1.9 2003/01/15 22:51:50 kc Exp $

#import <Foundation/NSString.h>
#import <CoreFoundation/CFString.h>
#import <OmniFoundation/FrameworkDefines.h>

/* From the Unicode standard:
 * U+FFFD REPLACEMENT CHARACTER 
 * used to replace an incoming character whose value is unknown or unrepresentable in Unicode
 */
#define OF_UNICODE_REPLACEMENT_CHARACTER ((unichar)0xFFFD)


struct OFStringDecoderState {
    CFStringEncoding encoding;
    
    union {
       struct {
          unsigned int partialCharacter;  /* must be at least 31 bits */
          unsigned short utf8octetsremaining;
       } utf8;
       /* TODO: more state vars for other encodings */
    } vars;
};

struct OFCharacterScanResult {
    struct OFStringDecoderState state;
        
    unsigned int bytesConsumed;
    unsigned int charactersProduced;
};

/* Information about encodings */
OmniFoundation_EXTERN BOOL OFCanScanEncoding(CFStringEncoding anEncoding);
OmniFoundation_EXTERN BOOL OFEncodingIsSimple(CFStringEncoding anEncoding);

/* Functions for decoding a string */
OmniFoundation_EXTERN struct OFStringDecoderState OFInitialStateForEncoding(CFStringEncoding anEncoding);
OmniFoundation_EXTERN struct OFCharacterScanResult OFScanCharactersIntoBuffer(struct OFStringDecoderState state,  unsigned char *in_bytes, unsigned int in_bytes_count, unichar *out_characters, unsigned int out_characters_max);
OmniFoundation_EXTERN BOOL OFDecoderContainsPartialCharacters(struct OFStringDecoderState state);

/* An exception which can be raised by the above functions */
OmniFoundation_EXTERN NSString *OFCharacterConversionExceptionName;

/* General string utilities for dealing with surrogate pairs (UTF-16 encodings of UCS-4 characters) */
enum OFIsSurrogate {
    OFIsSurrogate_No = 0,
    OFIsSurrogate_HighSurrogate = 1,
    OFIsSurrogate_LowSurrogate = 2
};

/* Determines whether a given 16-bit unichar is part of a surrogate pair */
static inline enum OFIsSurrogate OFCharacterIsSurrogate(unichar ch)
{
    /* The surrogate ranges are conveniently lined up on power-of-two boundaries.
    ** Since the common case is that a character is not a surrogate at all, we
    ** test for that first.
    */
    if ((ch & 0xF800) == 0xD800) {
        if ((ch & 0x0400) == 0)
            return OFIsSurrogate_HighSurrogate;
        else
            return OFIsSurrogate_LowSurrogate;
    } else
        return OFIsSurrogate_No;
}

/* Combines a high and a low surrogate character into a 21-bit Unicode character value */
static inline UnicodeScalarValue OFCharacterFromSurrogatePair(unichar high, unichar low)
{
    return 0x10000 + (
                      ( (UnicodeScalarValue)(high & 0x3FF) << 10 ) |
                        (UnicodeScalarValue)(low & 0x3FF)
                     );
}

/* Splits a Supplementary Plane character into two UTF-16 surrogate characters */
/* Do not use this for characters in the Basic Multilinugal Plane */
static inline void OFCharacterToSurrogatePair(UnicodeScalarValue inCharacter, unichar *outUTF16)
{
    UnicodeScalarValue supplementaryPlanePoint = inCharacter - 0x10000;

    outUTF16[0] = 0xD800 | ( supplementaryPlanePoint & 0xFFC00 ) >> 10; /* high surrogate */
    outUTF16[1] = 0xDC00 | ( supplementaryPlanePoint & 0x003FF );       /* low surrogate */
}

