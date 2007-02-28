// Copyright 1997-2005 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/OmniSourceRelease_2006-09-07/OmniGroup/Frameworks/OmniFoundation/OFCharacterScanner.h 68913 2005-10-03 19:36:19Z kc $

#import <OmniFoundation/OFObject.h>

#import <Foundation/NSString.h> // For unichar
#import <OmniFoundation/CFString-OFExtensions.h>
#import <OmniFoundation/OFCharacterSet.h>

@class OFTrie, OFTrieBucket;

#define OFMaximumRewindMarks (8)

@interface OFCharacterScanner : OFObject
{
    unsigned int rewindMarkOffsets[OFMaximumRewindMarks]; // rewindMarkOffsets[0] is always the earliest mark, by definition
    unsigned short rewindMarkCount;
    unsigned int firstNonASCIIOffset;

@public
    unichar *inputBuffer;	// A buffer of unichars, in which we are scanning
    unichar *scanLocation;	// Pointer to next unichar
    unichar *scanEnd;		// Pointer to position after end of valid characters
    unsigned int inputStringPosition;	// This is the position (in a possibly notional string buffer) of the first character in inputBuffer
    BOOL freeInputBuffer;	// Whether we should deallocate inputBuffer when we're done with it
    OFCaseConversionBuffer caseBuffer;
}

- init;
    // Designated initializer

// - (NSString *)string;

/* TODO: Add an interface for guessing encodings, using TECSniffTextEncoding() */

/* Implemented by subclasses */
- (BOOL)fetchMoreData;
- (void)_rewindCharacterSource;

/* -fetchMoreData should make scanLocation point to a valid character, but should leave the value of (scanLocation -inputBuffer+inputStringPosition) unchanged. If the scan location is past EOF, it should return NO. OFCharacterScanner's implementation returns NO. */

/* -_rewindCharacterSource is called to indicate that the subsequent -fetchMoreData call will be requesting a buffer other than the one immediately following the previous call. It doesn't actually have to do anything. OFCharacterScanner's implementation raises an exception. */

/* Used by subclasses to implement the above */
- (BOOL)fetchMoreDataFromString:(NSString *)inputString;
- (BOOL)fetchMoreDataFromCharacters:(unichar *)characters length:(unsigned int)length offset:(unsigned int)offset freeWhenDone:(BOOL)doFreeWhenDone;
// #warning the following method is obsolete; remove all references and delete it
// - (BOOL)fetchMoreDataFromCharacters:(unichar *)characters length:(unsigned int)length freeWhenDone:(BOOL)doFreeWhenDone;

- (unichar)peekCharacter;
- (void)skipPeekedCharacter;
- (unichar)readCharacter;

- (void)setRewindMark;
    // We only have so much room for marks.  In particular, don't try to call this method recursively, it's just not designed for that.
    // ALWAYS call one of the following to match up with calling the previous, or you'll corrupt the mark array
- (void)rewindToMark;
- (void)discardRewindMark;

- (unsigned int)scanLocation;
- (void)setScanLocation:(unsigned int)aLocation;
- (void)skipCharacters:(int)anOffset;

- (BOOL)hasScannedNonASCII;  // returns YES if scanner has passed any non-ASCII characters

- (BOOL)scanUpToCharacter:(unichar)aCharacter;
- (BOOL)scanUpToCharacterInSet:(NSCharacterSet *)delimiterCharacterSet;
- (BOOL)scanUpToString:(NSString *)delimiterString;
- (BOOL)scanUpToStringCaseInsensitive:(NSString *)delimiterString;

// NB: Most delimited-token-reading functions will return nil if there is a zero-length token.
- (NSString *)readTokenFragmentWithDelimiterCharacter:(unichar)character;
- (NSString *)readTokenFragmentWithDelimiterOFCharacterSet:(OFCharacterSet *)delimiterOFCharacterSet;
- (NSString *)readTokenFragmentWithDelimiters:(NSCharacterSet *)delimiterSet;
- (NSString *)readFullTokenWithDelimiterOFCharacterSet:(OFCharacterSet *)delimiterOFCharacterSet forceLowercase:(BOOL)forceLowercase;
- (NSString *)readFullTokenWithDelimiterOFCharacterSet:(OFCharacterSet *)delimiterOFCharacterSet;
- (NSString *)readFullTokenWithDelimiterCharacter:(unichar)delimiterCharacter forceLowercase:(BOOL)forceLowercase;
- (NSString *)readFullTokenWithDelimiterCharacter:(unichar)delimiterCharacter;
- (NSString *)readFullTokenWithDelimiters:(NSCharacterSet *)delimiterCharacterSet forceLowercase:(BOOL)forceLowercase;
- (NSString *)readFullTokenOfSet:(NSCharacterSet *)tokenSet;
- (NSString *)readFullTokenUpToString:(NSString *)delimiterString;
    // Relatively slow!  Inverts tokenSet and calls -readFullTokenWithDelimiters:
- (NSString *)readLine;
- (NSString *)readCharacterCount:(unsigned int)count;
- (unsigned int)scanHexadecimalNumberMaximumDigits:(unsigned int)maximumDigits;
- (unsigned int)scanUnsignedIntegerMaximumDigits:(unsigned int)maximumDigits;
- (int)scanIntegerMaximumDigits:(unsigned int)maximumDigits;
- (BOOL)scanDouble:(double *)outValue maximumLength:(unsigned int)maximumLength exponentLength:(unsigned int)maximumExponentLength;
- (BOOL)scanString:(NSString *)string peek:(BOOL)doPeek;
- (BOOL)scanStringCaseInsensitive:(NSString *)string peek:(BOOL)doPeek;

- (OFTrieBucket *)readLongestTrieElement:(OFTrie *)trie;
- (OFTrieBucket *)readLongestTrieElement:(OFTrie *)trie delimiterOFCharacterSet:(OFCharacterSet *)delimiterOFCharacterSet;
- (OFTrieBucket *)readShortestTrieElement:(OFTrie *)trie;

@end

#import <OmniBase/assertions.h> // For OBPRECONDITION
#import "FrameworkDefines.h" // For OmniFoundation_EXTERN

// Here's a list of the inline functions:
//
//	BOOL scannerHasData(OFCharacterScanner *scanner);
//	unsigned int scannerScanLocation(OFCharacterScanner *scanner);
//	unichar scannerPeekCharacter(OFCharacterScanner *scanner);
//	void scannerSkipPeekedCharacter(OFCharacterScanner *scanner);
//	unichar scannerReadCharacter(OFCharacterScanner *scanner);
//	BOOL scannerScanUpToCharacter(OFCharacterScanner *scanner, unichar scanCharacter);
//	BOOL scannerScanUpToCharacterInOFCharacterSet(OFCharacterScanner *scanner, OFCharacterSet *delimiterBitmapRep);
//      BOOL scannerScanUpToCharacterNotInOFCharacterSet(OFCharacterScanner *scanner, OFCharacterSet *memberBitmapRep)
//	BOOL scannerScanUpToCharacterInSet(OFCharacterScanner *scanner, NSCharacterSet *delimiterCharacterSet);
//

OmniFoundation_EXTERN const unichar OFCharacterScannerEndOfDataCharacter;
    // This character is returned when a scanner is asked for a character past the end of its input.  (For backwards compatibility with earlier versions of OFCharacterScanner, this is currently '\0'--but you shouldn't rely on that behavior.)

static inline BOOL
scannerHasData(OFCharacterScanner *scanner)
{
    return scanner->scanLocation < scanner->scanEnd || [scanner fetchMoreData];
}

static inline unsigned int
scannerScanLocation(OFCharacterScanner *scanner)
{
    if (!scannerHasData(scanner)) {
        // Don't return an offset which is longer than our input.
        scanner->scanLocation = scanner->scanEnd;
    }
    return scanner->inputStringPosition + (scanner->scanLocation - scanner->inputBuffer);
}

static inline unichar
scannerPeekCharacter(OFCharacterScanner *scanner)
{
    if (!scannerHasData(scanner))
	return OFCharacterScannerEndOfDataCharacter;
    return *scanner->scanLocation;
}

static inline void
scannerSkipPeekedCharacter(OFCharacterScanner *scanner)
{
    // NOTE: It's OK for scanLocation to go past scanEnd
    scanner->scanLocation++;
}

static inline unichar
scannerReadCharacter(OFCharacterScanner *scanner)
{
    unichar character;

    if (!scannerHasData(scanner))
	return OFCharacterScannerEndOfDataCharacter;
    character = *scanner->scanLocation;
    scannerSkipPeekedCharacter(scanner);
    return character;
}

static inline BOOL
scannerScanUpToCharacter(OFCharacterScanner *scanner, unichar scanCharacter)
{
    while (scannerHasData(scanner)) {
        while (scanner->scanLocation < scanner->scanEnd) {
            if (*scanner->scanLocation == scanCharacter)
                return YES;
            scanner->scanLocation++;
        }
    }
    return NO;
}

static inline BOOL
scannerScanUntilNotCharacter(OFCharacterScanner *scanner, unichar scanCharacter)
{
    while (scannerHasData(scanner)) {
        while (scanner->scanLocation < scanner->scanEnd) {
            if (*scanner->scanLocation != scanCharacter)
                return YES;
            scanner->scanLocation++;
        }
    }
    return NO;
}

static inline BOOL
scannerScanUpToCharacterInOFCharacterSet(OFCharacterScanner *scanner, OFCharacterSet *delimiterBitmapRep)
{
    while (scannerHasData(scanner)) {
        while (scanner->scanLocation < scanner->scanEnd) {
            if (OFCharacterSetHasMember(delimiterBitmapRep, *scanner->scanLocation))
                return YES;
            scanner->scanLocation++;
        }
    } 
    return NO;
}

static inline BOOL
scannerScanUpToCharacterNotInOFCharacterSet(OFCharacterScanner *scanner, OFCharacterSet *memberBitmapRep)
{
    while (scannerHasData(scanner)) {
        while (scanner->scanLocation < scanner->scanEnd) {
            if (!OFCharacterSetHasMember(memberBitmapRep, *scanner->scanLocation))
                return YES;
            scanner->scanLocation++;
        }
    }
    return NO;
}

static inline BOOL
scannerScanUpToCharacterInSet(OFCharacterScanner *scanner, NSCharacterSet *delimiterCharacterSet)
{
    OFCharacterSet *delimiterOFCharacterSet;

    if (!scannerHasData(scanner))
        return NO;
    delimiterOFCharacterSet = [[[OFCharacterSet alloc] initWithCharacterSet:delimiterCharacterSet] autorelease];
    return scannerScanUpToCharacterInOFCharacterSet(scanner, delimiterOFCharacterSet);
}

static inline BOOL scannerPeekString(OFCharacterScanner *scanner, NSString *string)
{
    return [scanner scanString:string peek:YES];
}

static inline BOOL scannerReadString(OFCharacterScanner *scanner, NSString *string)
{
    return [scanner scanString:string peek:NO];
}

