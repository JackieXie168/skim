//
//  NSAttributedString_BDSKExtensions.m
//  Bibdesk
//
//  Created by Christiaan Hofman on 6/5/06.
/*
 This software is Copyright (c) 2006,2007
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

#import "NSAttributedString_BDSKExtensions.h"
#import "BDSKComplexString.h"
#import "NSString_BDSKExtensions.h"
#import "NSCharacterSet_BDSKExtensions.h"
#import "BDSKFontManager.h"

static NSString *__rangeKey = @"__BDSKRange";

static NSArray *copyAttributeDictionariesAndFixString(NSMutableString *mutableString, NSDictionary *attributes)
{
    OBASSERT(nil != mutableString);
    
    // we need something to copy and add to the array
    if (nil == attributes)
        attributes = [NSDictionary dictionary];
    
    NSFontManager *fontManager = [NSFontManager sharedFontManager];
    NSString *texStyle = nil;    
    NSMutableDictionary *attrs;
    NSFont *font = [attributes objectForKey:NSFontAttributeName];
    if (font == nil)
        font = [NSFont systemFontOfSize:0];
    
    NSRange searchRange = NSMakeRange(0, [mutableString length]); // starting value; changes as we change the string
    NSRange cmdRange;
    NSRange styleRange;
    unsigned startLoc; // starting character index to apply tex attributes
    unsigned endLoc;   // ending index to apply tex attributes
    
    NSMutableArray *attributeDictionaries = [[NSMutableArray alloc] init];
    CFAllocatorRef alloc = CFGetAllocator(mutableString);
    
    while( (cmdRange = [mutableString rangeOfTeXCommandInRange:searchRange]).location != NSNotFound){
        
        // copy the command
        texStyle = (NSString *)CFStringCreateWithSubstring(alloc, (CFStringRef)mutableString, CFRangeMake(cmdRange.location, cmdRange.length));
        
        // delete the command, now that we know what it was
        [mutableString deleteCharactersInRange:cmdRange];
        
        startLoc = cmdRange.location;
        
        // see if this is a font command
        NSFontTraitMask newTrait = [fontManager fontTraitMaskForTeXStyle:texStyle];
        [texStyle release];
        
        if (0 != newTrait) {
            
            // remember, we deleted our command, but not the brace
            if([mutableString characterAtIndex:startLoc] == '{' && (endLoc = [mutableString indexOfRightBraceMatchingLeftBraceAtIndex:startLoc]) != NSNotFound){
                
                // have to delete the braces as we go along, or else ranges will be hosed after deleting at the end
                [mutableString deleteCharactersInRange:NSMakeRange(startLoc, 1)];
                
                // deleting the left brace just shifted everything to the left
                [mutableString deleteCharactersInRange:NSMakeRange(endLoc - 1, 1)];
                
                attrs = [attributes mutableCopy];
                [attrs setObject:[fontManager convertFont:font toHaveTrait:newTrait]
                          forKey:NSFontAttributeName];
                
                // account for the braces, since we'll be removing them
                styleRange = NSMakeRange(startLoc, (endLoc - startLoc - 1));
                
                [attrs setObject:[NSValue valueWithRange:styleRange] forKey:__rangeKey];
                [attributeDictionaries addObject:attrs];
                [attrs release];
            }
        }
        // new range, since we've altered the string (we don't use endLoc because of possibly nested commands)
        searchRange = NSMakeRange(startLoc, [mutableString length] - startLoc);
    }
    
    return attributeDictionaries;
}

static void applyAttributesToString(const void *value, void *context)
{
    NSDictionary *dict = (void *)value;
    NSMutableAttributedString *mas = context;
    [mas addAttributes:dict range:[[dict objectForKey:__rangeKey] rangeValue]];    
}


@implementation NSAttributedString (BDSKExtensions)

- (id)initWithTeXString:(NSString *)string attributes:(NSDictionary *)attributes collapseWhitespace:(BOOL)collapse{

    NSMutableAttributedString *mas;
    
    // get rid of whitespace if we have to; we can't use this on the attributed string's content store, though
    if(collapse){
        if([string isComplex])
            string = [NSString stringWithString:string];
        string = [string fastStringByCollapsingWhitespaceAndRemovingSurroundingWhitespace];
    }
    
    NSMutableString *mutableString = [string mutableCopy];
    
    // Parse the TeX commands and remove them from the string, manipulating the NSMutableString as much as possible, since -[NSMutableAttributedString mutableString] returns a proxy object that's more expensive.
    NSArray *attributeDictionaries = copyAttributeDictionariesAndFixString(mutableString, attributes);
    
    unsigned numberOfDictionaries = [attributeDictionaries count];
    if (numberOfDictionaries > 0) {

        // discard the result of +alloc, since we're going to create a new object
        [[self init] release];

        // set the attributed string up with default attributes, after parsing and fixing the mutable string
        mas = [[NSMutableAttributedString alloc] initWithString:mutableString attributes:attributes]; 

        // now apply the previously determined attributes and ranges to the attributed string
        CFArrayApplyFunction((CFArrayRef)attributeDictionaries, CFRangeMake(0, numberOfDictionaries), applyAttributesToString, mas);
        
        // not all of the braces were deleted when parsing the commands
        [[mas mutableString] deleteCharactersInCharacterSet:[NSCharacterSet curlyBraceCharacterSet]];
        
        self = [mas copy];
        [mas release];
        
    } else {
        
        // no font commands, so operate directly on the NSMutableString and then use the result of +alloc
        [mutableString deleteCharactersInCharacterSet:[NSCharacterSet curlyBraceCharacterSet]];
        self = [self initWithString:mutableString attributes:attributes];
    }
    
    [mutableString release];
    [attributeDictionaries release];
    
    return self;
}

- (id)initWithAttributedString:(NSAttributedString *)attributedString attributes:(NSDictionary *)attributes {
    [[self init] release];
    NSMutableAttributedString *tmpStr = [attributedString mutableCopy];
    unsigned index = 0, length = [attributedString length];
    NSRange range = NSMakeRange(0, length);
    NSDictionary *attrs;
    [tmpStr addAttributes:attributes range:range];
    while (index < length) {
        attrs = [attributedString attributesAtIndex:index effectiveRange:&range];
        if (range.length > 0) {
            [tmpStr addAttributes:attrs range:range];
            index = NSMaxRange(range);
        } else index++;
    }
    [tmpStr fixAttributesInRange:NSMakeRange(0, length)];
    self = [tmpStr copy];
    [tmpStr release];
    return self;
}

- (NSRect)boundingRectForDrawingInViewWithSize:(NSSize)size{
    NSTextStorage *textStorage = [[NSTextStorage alloc] initWithAttributedString:self];
    NSTextContainer *textContainer = [[NSTextContainer alloc] initWithContainerSize:size];
    NSLayoutManager *layoutManager = [[NSLayoutManager alloc] init];
    
    [layoutManager addTextContainer:textContainer];
    [textStorage addLayoutManager:layoutManager];
    [textContainer release];
    [layoutManager release];
    
    // drawing in views uses a different typesetting behavior from the current one which leads to a mismatch in line height
    // see http://www.cocoabuilder.com/archive/message/cocoa/2006/1/3/153669
    [layoutManager setTypesetterBehavior:NSTypesetterBehavior_10_2_WithCompatibility];
    [layoutManager glyphRangeForTextContainer:textContainer];
    
    NSRect rect = [layoutManager usedRectForTextContainer:textContainer];
    [textStorage release];
    
    return rect;
}

@end

@implementation NSAttributedString (TeXComparison)
- (NSComparisonResult)localizedCaseInsensitiveNonTeXNonArticleCompare:(NSAttributedString *)other;
{
    return [[self string] localizedCaseInsensitiveNonTeXNonArticleCompare:[other string]];
}

@end

