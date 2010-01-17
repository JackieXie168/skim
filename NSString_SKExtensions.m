//
//  NSString_SKExtensions.m
//  Skim
//
//  Created by Christiaan Hofman on 2/12/07.
/*
 This software is Copyright (c) 2007-2010
 Christiaan Hofman. All rights reserved.

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:

 - Redistributions of source code must retain the above copyright
   notice, this list of conditions and the following disclaimer.

 - Redistributions in binary form must reproduce the above copyright
    notice, this list of conditions and the following disclaimer in
    the documentation and/or other materials provided with the
    distribution.

 - Neither the name of Christiaan Hofman nor the names of any
    contributors may be used to endorse or promote products derived
    from this software without specific prior written permission.

 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "NSString_SKExtensions.h"
#import "NSScanner_SKExtensions.h"
#import "NSCharacterSet_SKExtensions.h"
#import "NSURL_SKExtensions.h"
#import "NSImage_SKExtensions.h"
#import <SkimNotes/SkimNotes.h>
#import <CoreFoundation/CoreFoundation.h>

#define ELLIPSIS_CHARACTER 0x2026

#pragma mark CFString extensions

#define STACK_BUFFER_SIZE 256

static inline
CFStringRef __SKStringCreateByCollapsingAndTrimmingWhitespaceAndNewlines(CFAllocatorRef allocator, CFStringRef aString)
{
    
    CFIndex length = CFStringGetLength(aString);
    
    if(length == 0)
        return CFRetain(CFSTR(""));
    
    // set up the buffer to fetch the characters
    CFIndex cnt = 0;
    CFStringInlineBuffer inlineBuffer;
    CFStringInitInlineBuffer(aString, &inlineBuffer, CFRangeMake(0, length));
    UniChar ch;
    UniChar *buffer, stackBuffer[STACK_BUFFER_SIZE];
    CFStringRef retStr;

    allocator = (allocator == NULL) ? CFGetAllocator(aString) : allocator;

    if(length >= STACK_BUFFER_SIZE) {
        buffer = (UniChar *)CFAllocatorAllocate(allocator, length * sizeof(UniChar), 0);
    } else {
        buffer = stackBuffer;
    }
    
    NSCAssert1(buffer != NULL, @"failed to allocate memory for string of length %ld", (long)length);
    
    BOOL isFirst = NO, wasHyphen = NO;
    CFIndex bufCnt = 0;
    for(cnt = 0; cnt < length; cnt++){
        ch = CFStringGetCharacterFromInlineBuffer(&inlineBuffer, cnt);
        if(NO == CFCharacterSetIsCharacterMember(CFCharacterSetGetPredefined(kCFCharacterSetWhitespaceAndNewline), ch)){
            wasHyphen = (ch == '-');
            isFirst = YES;
            buffer[bufCnt++] = ch; // not whitespace, so we want to keep it
        } else {
            if(isFirst){
                if(wasHyphen && CFCharacterSetIsCharacterMember((CFCharacterSetRef)[NSCharacterSet newlineCharacterSet], ch))
                    bufCnt--; // ignore the last hyphen and current newline
                else
                    buffer[bufCnt++] = ' '; // if it's the first whitespace, we add a single space
                wasHyphen = NO;
                isFirst = NO;
            }
        }
    }
    
    if(buffer[(bufCnt-1)] == ' ') // we've collapsed any trailing whitespace, so disregard it
        bufCnt--;
    
    retStr = CFStringCreateWithCharacters(allocator, buffer, bufCnt);
    if(buffer != stackBuffer) CFAllocatorDeallocate(allocator, buffer);
    return retStr;
}

CFStringRef SKStringCreateByCollapsingAndTrimmingWhitespaceAndNewlines(CFAllocatorRef allocator, CFStringRef string){ return __SKStringCreateByCollapsingAndTrimmingWhitespaceAndNewlines(allocator, string); }

#pragma mark NSString category

@implementation NSString (SKExtensions)

- (NSNumber *)noteTypeOrder {
    NSInteger order = 9;
    if ([self isEqualToString:SKNFreeTextString])
        order = 0;
    else if ([self isEqualToString:SKNNoteString] || [self isEqualToString:SKNTextString])
        order = 1;
    else if ([self isEqualToString:SKNCircleString])
        order = 2;
    else if ([self isEqualToString:SKNSquareString])
        order = 3;
    else if ([self isEqualToString:SKNHighlightString] || [self isEqualToString:SKNMarkUpString])
        order = 4;
    else if ([self isEqualToString:SKNUnderlineString])
        order = 5;
    else if ([self isEqualToString:SKNStrikeOutString])
        order = 6;
    else if ([self isEqualToString:SKNLineString])
        order = 7;
    else if ([self isEqualToString:SKNInkString])
        order = 8;
    return [NSNumber numberWithInteger:order];
}

- (NSComparisonResult)noteTypeCompare:(id)other {
    return [[self noteTypeOrder] compare:[other noteTypeOrder]];
}

- (NSComparisonResult)boundsCompare:(NSString *)aString {
    NSRect rect1 = NSRectFromString(self);
    NSRect rect2 = NSRectFromString(aString);
    CGFloat top1 = NSMaxY(rect1);
    CGFloat top2 = NSMaxY(rect2);
    
    if (top1 > top2)
        return NSOrderedAscending;
    else if (top1 < top2)
        return NSOrderedDescending;
    
    CGFloat left1 = NSMinX(rect1);
    CGFloat left2 = NSMinX(rect2);
    
    if (left1 < left2)
        return NSOrderedAscending;
    else if (left1 > left2)
        return NSOrderedDescending;
    else
        return NSOrderedSame;
}

- (NSString *)stringByCollapsingWhitespaceAndNewlinesAndRemovingSurroundingWhitespaceAndNewlines;
{
    return [(id)SKStringCreateByCollapsingAndTrimmingWhitespaceAndNewlines(CFAllocatorGetDefault(), (CFStringRef)self) autorelease];
}

// NS and CF character sets won't find these, due to the way CFString handles surrogate pairs.  The surrogate pair inlines were borrowed from CFCharacterSetPriv.h in CF-lite-476.13.
static inline bool __SKIsSurrogateHighCharacter(const UniChar character) {
    return ((character >= 0xD800UL) && (character <= 0xDBFFUL) ? true : false);
}

static inline bool __SKIsSurrogateLowCharacter(const UniChar character) {
    return ((character >= 0xDC00UL) && (character <= 0xDFFFUL) ? true : false);
}

static inline bool __SKIsSurrogateCharacter(const UniChar character) {
    return ((character >= 0xD800UL) && (character <= 0xDFFFUL) ? true : false);
}

static inline UTF32Char __SKGetLongCharacterForSurrogatePair(const UniChar surrogateHigh, const UniChar surrogateLow) {
    return ((surrogateHigh - 0xD800UL) << 10) + (surrogateLow - 0xDC00UL) + 0x0010000UL;
}

static inline bool __SKIsPrivateUseCharacter(const UTF32Char ch)
{
    return ((ch >= 0xE000UL && ch <= 0xF8FFUL) ||    /* private use area */
            (ch >= 0xF0000UL && ch <= 0xFFFFFUL) ||  /* supplementary private use A */
            (ch >= 0x100000UL && ch <= 0x10FFFFUL)); /* supplementary private use B */
}

// Remove anything in the private use planes, and/or malformed surrogate pair sequences rdar://problem/6273932
- (NSString *)stringByRemovingAliens {

    // make a mutable copy only if needed
    CFMutableStringRef theString = (void *)self;
    
    CFStringInlineBuffer inlineBuffer;
    CFIndex length = CFStringGetLength(theString);
    
    // use the current mutable string with the inline buffer, but make a new mutable copy if needed
    CFStringInitInlineBuffer(theString, &inlineBuffer, CFRangeMake(0, length));
    UniChar ch;
    
#define DELETE_CHARACTERS(n) do{if((void*)self==theString){theString=(void*)[[self mutableCopyWithZone:[self zone]] autorelease];};CFStringDelete(theString, CFRangeMake(delIdx, n));} while(0)
        
    // idx is current index into the inline buffer, and delIdx is current index in the mutable string
    CFIndex idx = 0, delIdx = 0;
    while(idx < length){
        ch = CFStringGetCharacterFromInlineBuffer(&inlineBuffer, idx);
        if (__SKIsPrivateUseCharacter(ch)) {
            DELETE_CHARACTERS(1);
        } else if (__SKIsSurrogateCharacter(ch)) {
            
            if ((idx + 1) < length) {
                
                UniChar highChar = ch;
                UniChar lowChar = CFStringGetCharacterFromInlineBuffer(&inlineBuffer, idx + 1);
                UTF32Char longChar = __SKGetLongCharacterForSurrogatePair(highChar, lowChar);
                // if we only have half of a surrogate pair, delete the offending character
                if (__SKIsSurrogateLowCharacter(lowChar) == false || __SKIsSurrogateHighCharacter(highChar) == false) {
                    DELETE_CHARACTERS(1);
                    // only deleted a single char, so don't need to adjust idx
                } else if (__SKIsPrivateUseCharacter(longChar)) {
                    // remove the pair; can't display private use characters
                    DELETE_CHARACTERS(2);
                    // adjust since we removed two characters...
                    idx++;
                } else {
                    // valid surrogate pair, so we'll leave it alone
                    delIdx += 2;
                    idx++;
                }
                
            } else {
                // insufficient length for this to be a valid sequence, so it's only half of a surrogate pair
                DELETE_CHARACTERS(1);
            }
            
        } else {
            // keep track of our index in the copy and the original
            delIdx++;
        }
        idx++;
    }

    return (id)theString;
}

- (NSString *)stringByAppendingEllipsis;
{
    return [self stringByAppendingFormat:@"%C", ELLIPSIS_CHARACTER];
}

- (NSString *)stringByReplacingPathExtension:(NSString *)ext;
{
    return [[self stringByDeletingPathExtension] stringByAppendingPathExtension:ext];
}

// Escape those characters that are special, to the shell, inside a "quoted" string
- (NSString *)stringByEscapingShellChars {
    static NSCharacterSet *shellSpecialChars = nil;
    if (shellSpecialChars == nil)
        shellSpecialChars = [[NSCharacterSet characterSetWithCharactersInString:@"$\"`\\"] retain];

    NSMutableString *result = [self mutableCopy];
    NSUInteger i = 0;
    while (i < [result length]) {
        i = [result rangeOfCharacterFromSet:shellSpecialChars options:0 range:NSMakeRange(i, [result length] - i)].location;
        if (i != NSNotFound) {
            [result insertString:@"\\" atIndex: i];
            i += 2;
        }
    }

    return [result autorelease];
}

// parses a space separated list of shell script argments
// allows quoting parts of an argument and escaped characters outside quotes, according to shell rules
- (NSArray *)shellScriptArgumentsArray;
{
    static NSCharacterSet *specialChars = nil;
    static NSCharacterSet *quoteChars = nil;
    
    if (specialChars == nil) {
        NSMutableCharacterSet *tmpSet = [[NSCharacterSet whitespaceAndNewlineCharacterSet] mutableCopy];
        [tmpSet addCharactersInString:@"\\\"'`"];
        specialChars = [tmpSet copy];
        [tmpSet release];
        quoteChars = [[NSCharacterSet characterSetWithCharactersInString:@"\"'`"] retain];
    }
    
    NSScanner *scanner = [NSScanner scannerWithString:self];
    NSString *s = nil;
    unichar ch = 0;
    NSMutableString *currArg = [scanner isAtEnd] ? nil : [NSMutableString string];
    NSMutableArray *arguments = [NSMutableArray array];
    
    [scanner setCharactersToBeSkipped:nil];
    [scanner scanCharactersFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet] intoString:NULL];
    
    while ([scanner isAtEnd] == NO) {
        if ([scanner scanUpToCharactersFromSet:specialChars intoString:&s])
            [currArg appendString:s];
        if ([scanner scanCharacter:&ch] == NO)
            break;
        if ([[NSCharacterSet whitespaceAndNewlineCharacterSet] characterIsMember:ch]) {
            // argument separator, add the last one we found and ignore more whitespaces
            [scanner scanCharactersFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet] intoString:NULL];
            [arguments addObject:currArg];
            currArg = [scanner isAtEnd] ? nil : [NSMutableString string];
        } else if (ch == '\\') {
            // escaped character
            if ([scanner scanCharacter:&ch] == NO)
                [NSException raise:NSInternalInconsistencyException format:@"Missing character"];
            if ([currArg length] == 0 && [[NSCharacterSet newlineCharacterSet] characterIsMember:ch])
                // ignore escaped newlines between arguments, as they should be considered whitespace
                [scanner scanCharactersFromSet:[NSCharacterSet newlineCharacterSet] intoString:NULL];
            else // real escaped character, just add the character, so we can ignore it if it is a special character
                [currArg appendFormat:@"%C", ch];
        } else if ([quoteChars characterIsMember:ch]) {
            // quoted part of an argument, scan up to the matching quote
            if ([scanner scanUpToCharactersFromSet:[NSCharacterSet characterSetWithRange:NSMakeRange(ch, 1)] intoString:&s])
                [currArg appendString:s];
            if ([scanner scanCharacter:NULL] == NO)
                [NSException raise:NSInternalInconsistencyException format:@"Unmatched %C", ch];
        }
    }
    if (currArg)
        [arguments addObject:currArg];
    return arguments;
}

- (NSComparisonResult)localizedCaseInsensitiveNumericCompare:(NSString *)aStr{
    return [self compare:aStr
                 options:NSCaseInsensitiveSearch | NSNumericSearch
                   range:NSMakeRange(0, [self length])
                  locale:[[NSUserDefaults standardUserDefaults] dictionaryRepresentation]];
}

- (NSString *)lossyASCIIString {
    return [[[NSString alloc] initWithData:[self dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES] encoding:NSASCIIStringEncoding] autorelease];
}

- (NSString *)lossyISOLatin1String {
    return [[[NSString alloc] initWithData:[self dataUsingEncoding:NSISOLatin1StringEncoding allowLossyConversion:YES] encoding:NSASCIIStringEncoding] autorelease];
}

- (NSString *)stringByEscapingParenthesis {
    static NSCharacterSet *parenAndBackslashCharSet = nil;
    
    if (parenAndBackslashCharSet == nil)
        parenAndBackslashCharSet = [[NSCharacterSet characterSetWithCharactersInString:@"()\\"] retain];
    
    NSUInteger location = [self rangeOfCharacterFromSet:parenAndBackslashCharSet].location;
    if (location == NSNotFound)
        return self;
    
    NSRange range;
    NSMutableString *string = [self mutableCopy];
    
    while (location != NSNotFound) {
        [string insertString:@"\\" atIndex:location];
        range = NSMakeRange(location + 2, [string length] - location - 2);
        location = [string rangeOfCharacterFromSet:parenAndBackslashCharSet options:0 range:range].location;
    }
    return [string autorelease];
}

#pragma mark Templating support

- (NSString *)typeName {
    if ([self isEqualToString:SKNFreeTextString])
        return NSLocalizedString(@"Text Note", @"Description for export");
    else if ([self isEqualToString:SKNNoteString] || [self isEqualToString:SKNTextString])
        return NSLocalizedString(@"Anchored Note", @"Description for export");
    else if ([self isEqualToString:SKNCircleString])
        return NSLocalizedString(@"Circle", @"Description for export");
    else if ([self isEqualToString:SKNSquareString])
        return NSLocalizedString(@"Box", @"Description for export");
    else if ([self isEqualToString:SKNMarkUpString] || [self isEqualToString:SKNHighlightString])
        return NSLocalizedString(@"Highlight", @"Description for export");
    else if ([self isEqualToString:SKNUnderlineString])
        return NSLocalizedString(@"Underline", @"Description for export");
    else if ([self isEqualToString:SKNStrikeOutString])
        return NSLocalizedString(@"Strike Out", @"Description for export");
    else if ([self isEqualToString:SKNLineString])
        return NSLocalizedString(@"Line", @"Description for export");
    else if ([self isEqualToString:SKNInkString])
        return NSLocalizedString(@"Freehand", @"Description for export");
    else
        return self;
}

- (NSString *)rectString {
    return NSStringFromRect(NSRectFromString(self));
}

- (NSString *)pointString {
    return NSStringFromPoint(NSPointFromString(self));
}

- (NSString *)originString {
    return NSStringFromPoint(NSRectFromString(self).origin);
}

- (NSString *)sizeString {
    return NSStringFromSize(NSRectFromString(self).size);
}

- (NSString *)midPointString {
    NSRect rect = NSRectFromString(self);
    return NSStringFromPoint(NSMakePoint(NSMidX(rect), NSMidY(rect)));
}

- (CGFloat)rectX {
    return NSRectFromString(self).origin.x;
}

- (CGFloat)rectY {
    return NSRectFromString(self).origin.y;
}

- (CGFloat)rectWidth {
    return NSRectFromString(self).size.width;
}

- (CGFloat)rectHeight {
    return NSRectFromString(self).size.height;
}

- (CGFloat)pointX {
    return NSPointFromString(self).x;
}

- (CGFloat)pointY {
    return NSPointFromString(self).y;
}

- (NSString *)stringBySurroundingWithSpacesIfNotEmpty { 
    return [self isEqualToString:@""] ? self : [NSString stringWithFormat:@" %@ ", self];
}

- (NSString *)stringByAppendingSpaceIfNotEmpty {
    return [self isEqualToString:@""] ? self : [self stringByAppendingString:@" "];
}

- (NSString *)stringByAppendingDoubleSpaceIfNotEmpty {
    return [self isEqualToString:@""] ? self : [self stringByAppendingString:@"  "];
}

- (NSString *)stringByPrependingSpaceIfNotEmpty {
    return [self isEqualToString:@""] ? self : [NSString stringWithFormat:@" %@", self];
}

- (NSString *)stringByAppendingCommaIfNotEmpty {
    return [self isEqualToString:@""] ? self : [self stringByAppendingString:@","];
}

- (NSString *)stringByAppendingFullStopIfNotEmpty {
    return [self isEqualToString:@""] ? self : [self stringByAppendingString:@"."];
}

- (NSString *)stringByAppendingCommaAndSpaceIfNotEmpty {
    return [self isEqualToString:@""] ? self : [self stringByAppendingString:@", "];
}

- (NSString *)stringByAppendingFullStopAndSpaceIfNotEmpty {
    return [self isEqualToString:@""] ? self : [self stringByAppendingString:@". "];
}

- (NSString *)stringByPrependingCommaAndSpaceIfNotEmpty {
    return [self isEqualToString:@""] ? self : [NSString stringWithFormat:@", %@", self];
}

- (NSString *)stringByPrependingFullStopAndSpaceIfNotEmpty {
    return [self isEqualToString:@""] ? self : [NSString stringWithFormat:@". %@", self];
}

- (NSString *)parenthesizedStringIfNotEmpty {
    return [self isEqualToString:@""] ? self : [NSString stringWithFormat:@"(%@)", self];
}

- (NSURL *)url {
    NSURL *url = nil;
    if ([self rangeOfString:@"://"].location != NSNotFound)
        url = [NSURL URLWithString:self];
    else
        url = [NSURL fileURLWithPath:[self stringByExpandingTildeInPath]];
    return url;
}

- (NSAttributedString *)icon {
    return [[self url] icon];
}

- (NSAttributedString *)smallIcon {
    return [[self url] smallIcon];
}

- (NSAttributedString *)typeIcon {
    NSAttributedString *attrString = nil;
    
    NSString *imageName = nil;
    if ([self isEqualToString:SKNFreeTextString])
        imageName = SKImageNameTextNote;
    else if ([self isEqualToString:SKNNoteString] || [self isEqualToString:SKNTextString])
        imageName = SKImageNameAnchoredNote;
    else if ([self isEqualToString:SKNCircleString])
        imageName = SKImageNameCircleNote;
    else if ([self isEqualToString:SKNSquareString])
        imageName = SKImageNameSquareNote;
    else if ([self isEqualToString:SKNHighlightString] || [self isEqualToString:SKNMarkUpString])
        imageName = SKImageNameHighlightNote;
    else if ([self isEqualToString:SKNUnderlineString])
        imageName = SKImageNameUnderlineNote;
    else if ([self isEqualToString:SKNStrikeOutString])
        imageName = SKImageNameStrikeOutNote;
    else if ([self isEqualToString:SKNLineString])
        imageName = SKImageNameLineNote;
    else if ([self isEqualToString:SKNInkString])
        imageName = SKImageNameInkNote;
    
    if (imageName) {
        NSImage *image = [NSImage imageNamed:imageName];
        NSString *name = [self stringByAppendingPathExtension:@"tiff"];
        
        NSFileWrapper *wrapper = [[NSFileWrapper alloc] initRegularFileWithContents:[image TIFFRepresentation]];
        [wrapper setFilename:name];
        [wrapper setPreferredFilename:name];

        NSTextAttachment *attachment = [[NSTextAttachment alloc] initWithFileWrapper:wrapper];
        [wrapper release];
        attrString = [NSAttributedString attributedStringWithAttachment:attachment];
        [attachment release];
    }
    
    return attrString;
}

- (NSString *)xmlString {
    NSData *data = [NSPropertyListSerialization dataFromPropertyList:self format:NSPropertyListXMLFormat_v1_0 errorDescription:NULL];
    NSMutableString *string = [[[NSMutableString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
    NSInteger loc = NSMaxRange([string rangeOfString:@"<string>"]);
    if (loc == NSNotFound)
        return self;
    [string deleteCharactersInRange:NSMakeRange(0, loc)];
    loc = [string rangeOfString:@"</string>" options:NSBackwardsSearch].location;
    if (loc == NSNotFound)
        return self;
    [string deleteCharactersInRange:NSMakeRange(loc, [string length] - loc)];
    return string;
}

@end
