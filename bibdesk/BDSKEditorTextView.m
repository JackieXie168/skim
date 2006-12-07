//
//  BDSKEditorTextView.m
//  Bibdesk
//
//  Created by Adam Maxwell on 02/28/06.
/*
 This software is Copyright (c) 2005,2006
 Adam Maxwell. All rights reserved.
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:
 
 - Redistributions of source code must retain the above copyright
 notice, this list of conditions and the following disclaimer.
 
 - Redistributions in binary form must reproduce the above copyright
 notice, this list of conditions and the following disclaimer in
 the documentation and/or other materials provided with the
 distribution.
 
 - Neither the name of Adam Maxwell nor the names of any
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

#import "BDSKEditorTextView.h"
#import "NSURL_BDSKExtensions.h"
#import "BibPrefController.h"
#import <OmniFoundation/OFPreference.h>

@interface BDSKEditorTextView (Private)

- (void)handleFontChangedNotification:(NSNotification *)note;
- (NSString *)URLStringFromRange:(NSRange *)startRange inString:(NSString *)string;
- (void)fixAttributesForURLs;
- (void)updateFontFromPreferences;
- (void)doCommonSetup;

@end

@implementation BDSKEditorTextView

- (id)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    [self doCommonSetup];
    return self;
}

- (id)initWithFrame:(NSRect)frameRect textContainer:(NSTextContainer *)container;
{
    self = [super initWithFrame:frameRect textContainer:container];
    [self doCommonSetup];
    return self;    
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [OFPreference removeObserver:self forPreference:nil];
    [super dealloc];
}

- (void)changeFont:(id)sender
{
    // convert the current font to the new font from the font panel
    // returns current font in case of a conversion failure
    NSFont *font = [[NSFontManager sharedFontManager] convertFont:[self font]];
    
    // save it to prefs for next time
    [[OFPreferenceWrapper sharedPreferenceWrapper] setFloat:[font pointSize] forKey:BDSKEditorFontSizeKey];
    [[OFPreferenceWrapper sharedPreferenceWrapper] setObject:[font fontName] forKey:BDSKEditorFontNameKey];
}

- (void)textStorageDidProcessEditing:(NSNotification *)notification
{    
    NSTextStorage *textStorage = [notification object];    
    NSString *string = [textStorage string];
    
    NSRange editedRange = [textStorage editedRange];
    
    // if this is > 1, it's likely a paste or initial insertion, so fix the whole thing
    if(editedRange.length > 1){
        [self fixAttributesForURLs];
    } else if(editedRange.location != NSNotFound){
        NSString *editedWord = [self URLStringFromRange:&editedRange inString:string];
        if([editedWord rangeOfString:@"://"].length == 0)
            editedWord = nil;
        NSURL *url = editedWord ? [[NSURL alloc] initWithString:editedWord] : nil;
        if(url != nil)
            [textStorage addAttribute:NSLinkAttributeName value:url range:editedRange];
        else
            [textStorage removeAttribute:NSLinkAttributeName range:editedRange];
        [url release];
    } else {
        NSLog(@"I am confused: edited range is %@", NSStringFromRange(editedRange));
    }
}

// make sure the font and other attributes get fixed when pasting text
- (void)paste:(id)sender {  [self pasteAsPlainText:sender]; }

@end

@implementation BDSKEditorTextView (Private)

// We get this notification when some other textview changes the font prefs
- (void)handleFontChangedNotification:(NSNotification *)note;
{
    [self updateFontFromPreferences];
}

// Determine if a % character is followed by two digits (valid in a URL)
static inline BOOL hasValidPercentEscapeFromIndex(NSString *string, unsigned startIndex)
{
    static NSCharacterSet *hexadecimalCharacterSet = nil;
    if (hexadecimalCharacterSet == nil) {
        NSMutableCharacterSet *tmpSet = [[NSCharacterSet decimalDigitCharacterSet] mutableCopy];
        [tmpSet addCharactersInRange:NSMakeRange('a', 6)];
        [tmpSet addCharactersInRange:NSMakeRange('A', 6)];
        hexadecimalCharacterSet = [tmpSet copy];
        [tmpSet release];
    }
    
    NSCParameterAssert(startIndex == 0 || [string length] > startIndex);
    // require % and at least two additional chars
    if([string isEqualToString:@""] || [string characterAtIndex:startIndex] != '%' || [string length] <= (startIndex + 2))
        return NO;
    
    // both characters following the % should be digits 0-9
    unichar ch1 = [string characterAtIndex:(startIndex + 1)];
    unichar ch2 = [string characterAtIndex:(startIndex + 2)];
    return ([hexadecimalCharacterSet characterIsMember:ch1] && [hexadecimalCharacterSet characterIsMember:ch2]) ? YES : NO;
}

/* Starts in the middle of a "word" (some range of interest) and searches forward and backward to find boundaries marked by characters that would be illegal for a URL.  Note that this may not be a valid URL in itself; it is just bounded by URL-like markers.
*/
- (NSString *)URLStringFromRange:(NSRange *)startRange inString:(NSString *)string
{
    unsigned startIdx = NSNotFound, endIdx = NSNotFound;
    NSRange range = NSMakeRange(0, startRange->location);
    
    do {
        range = [string rangeOfCharacterFromSet:[NSURL illegalURLCharacterSet] options:NSBackwardsSearch range:range];
        
        if(range.location != NSNotFound){
            // advance past the illegal character
            startIdx = range.location + 1;
        } else {
            // this has a URL as the first word in the string
            startIdx = 0;
            break;
        }
        
        // move the search range interval towards the beginning of the string
        range = NSMakeRange(0, range.location);
           
    } while (startIdx != NSNotFound && hasValidPercentEscapeFromIndex(string, startIdx - 1));

    NSString *lastWord = nil;
    if(startIdx != NSNotFound){

        range = NSMakeRange(startRange->location, [string length] - startRange->location);
        
        do {
            range = [string rangeOfCharacterFromSet:[NSURL illegalURLCharacterSet] options:0 range:range];

            // if the entire string is valid...
            if(range.location == NSNotFound){
                endIdx = [string length];
                break;
            } else {
                endIdx = range.location;
            }
            
            // move the search range interval towards the end of the string
            range = NSMakeRange(range.location + 1, [string length] - range.location - 1);
            
        } while (endIdx != NSNotFound && hasValidPercentEscapeFromIndex(string, endIdx));
        
        if(endIdx != NSNotFound && startIdx != NSNotFound && endIdx > startIdx){
            range = NSMakeRange(startIdx, endIdx - startIdx);
            lastWord = [string substringWithRange:range]; 
            *startRange = range;
        }
    }
    return lastWord;
}

// fixes the attributes for the entire text storage; inefficient for large strings
- (void)fixAttributesForURLs;
{
    NSTextStorage *textStorage = [self textStorage];
    NSString *string = [textStorage string];
    
    int start, length = [string length];
    NSRange range = NSMakeRange(0, 0);
    NSString *urlString;
    NSURL *url;
    
    do {
        start = NSMaxRange(range);
        range = [string rangeOfString:@"://" options:0 range:NSMakeRange(start, length - start)];
        
        if(range.length){
            urlString = [self URLStringFromRange:&range inString:string];
            url = urlString ? [[NSURL alloc] initWithString:urlString] : nil;
            if([url scheme]) [textStorage addAttribute:NSLinkAttributeName value:url range:range];
            [url release];
        }
        
    } while (range.length);
}

// used only for reading the default font from prefs and then changing the font of the text storage
- (void)updateFontFromPreferences;
{
    NSString *fontName = [[OFPreferenceWrapper sharedPreferenceWrapper] objectForKey:BDSKEditorFontNameKey];
    float fontSize = [[OFPreferenceWrapper sharedPreferenceWrapper] floatForKey:BDSKEditorFontSizeKey];
    NSFont *font = nil;
    
    if(fontName != nil)
        font = [NSFont fontWithName:fontName size:fontSize];
    
    // NSFont itself could be nil
    if(font == nil)
        font = [NSFont systemFontOfSize:[NSFont systemFontSize]];
    
    // this changes the font of the entire text storage without undo
    [self setFont:font];
}

- (void)doCommonSetup;
{
    OBPRECONDITION([self textStorage]);

    [[self textStorage] setDelegate:self];
    [self updateFontFromPreferences];
    [OFPreference addObserver:self selector:@selector(handleFontChangedNotification:) forPreference:[OFPreference preferenceForKey:BDSKEditorFontNameKey]];
}    

@end
