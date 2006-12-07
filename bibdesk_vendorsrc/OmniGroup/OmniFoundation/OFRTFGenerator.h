// Copyright 1997-2005 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/OmniSourceRelease_2006-09-07/OmniGroup/Frameworks/OmniFoundation/OFRTFGenerator.h 68913 2005-10-03 19:36:19Z kc $

#import <OmniFoundation/OFObject.h>

typedef struct {
    unsigned int fontNumber;
    unsigned int fontSize;
    struct {
        unsigned int bold:1;
        unsigned int italic:2;
    } flags;
    int superscript;
} OFRTFState;

@class NSMutableArray;

#import <OmniFoundation/OFDataBuffer.h>

@interface OFRTFGenerator : OFObject
{
@public
    OFDataBuffer rtfBuffer;
    OFDataBuffer asciiBuffer;
    
    OFRTFState outputState;
    OFRTFState wantState;
    BOOL hasUnemittedState;
    
    NSMutableArray *fontNames;
    NSMutableDictionary *fontNameToNumberDictionary;
}

// Get results
- (NSData *)rtfData;
- (NSData *)asciiData;
- (NSString *)asciiString;

// Setting RTF state
- (void)setFontName:(NSString *)fontName;
- (void)setFontSize:(int)fontSize;
- (void)setBold:(BOOL)bold;
- (void)setItalic:(BOOL)italic;
- (void)setSuperscript:(int)superscript;

- (void)emitStateChange;

// Adding strings
- (void)appendString:(NSString *)string;
- (void)appendData:(NSData *)data;
- (void)appendBytes:(const unsigned char *)bytes length:(unsigned int)length;
- (void)appendCharacter:(unsigned char)ch;
    // N.B. Unlike the rest of our API, this "character" is a C char, not a Unicode character.

@end

static inline void
rtfAppendUnprocessedCharacter(OFRTFGenerator *self, unsigned char ch)
{
    switch (ch) {
        case 128: // non-breaking space
            OFDataBufferAppendByte(&self->rtfBuffer, '\\');
            OFDataBufferAppendByte(&self->rtfBuffer, ' ');
            OFDataBufferAppendByte(&self->asciiBuffer, ' ');
            break;
        case '\n':
        case '}':
        case '{':
        case '\\':
            OFDataBufferAppendByte(&self->rtfBuffer, '\\');
            // fall through
        default:
            OFDataBufferAppendByte(&self->rtfBuffer, ch);
            OFDataBufferAppendByte(&self->asciiBuffer, ch);
            break;
    }
}
