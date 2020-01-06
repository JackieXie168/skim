//
//  SKTemplateParser.m
//  Skim
//
//  Created by Christiaan Hofman on 5/26/07.
/*
 This software is Copyright (c) 2007-2020
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

#import "SKTemplateParser.h"
#import "SKTemplateTag.h"
#import "NSString_SKExtensions.h"
#import "PDFSelection_SKExtensions.h"

#define START_TAG_OPEN_DELIM            @"<$"
#define END_TAG_OPEN_DELIM              @"</$"
#define ALT_TAG_OPEN_DELIM              @"<?$"
#define VALUE_TAG_CLOSE_DELIM           @"/>"
#define COLLECTION_TAG_CLOSE_DELIM      @">"
#define CONDITION_TAG_CLOSE_DELIM       @"?>"
#define CONDITION_TAG_EQUAL             @"="
#define CONDITION_TAG_CONTAIN           @"~"
#define CONDITION_TAG_SMALLER           @"<"
#define CONDITION_TAG_SMALLER_OR_EQUAL  @"<="
#define CONDITION_TAG_LARGER            @"!<="
#define CONDITION_TAG_LARGER_OR_EQUAL   @"!<"
#define CONDITION_TAG_NOT_EQUAL         @"!="
#define CONDITION_TAG_NOT_CONTAIN       @"!~"

/*
        value tag: <$key/>
   collection tag: <$key> </$key> 
               or: <$key> <?$key> </$key>
    condition tag: <$key?> </$key?> 
               or: <$key?> <?$key?> </$key?>
               or: <$key=value?> </$key?>
               or: <$key=value?> <?$key?> </$key?>
               or: <$key~value?> </$key?>
               or: <$key~value?> <?$key?> </$key?>
               or: <$key<value?> </$key?>
               or: <$key<value?> <?$key?> </$key?>
               or: <$key<=value?> </$key?>
               or: <$key<=value?> <?$key?> </$key?>
               or: <$key!<=value?> </$key?>
               or: <$key!<=value?> <?$key?> </$key?>
               or: <$key!<value?> </$key?>
               or: <$key!<value?> <?$key?> </$key?>
               or: <$key!=value?> </$key?>
               or: <$key!=value?> <?$key?> </$key?>
               or: <$key!~value?> </$key?>
               or: <$key!~value?> <?$key?> </$key?>
*/

@implementation SKTemplateParser


static NSCharacterSet *keyCharacterSet = nil;
static NSCharacterSet *invertedKeyCharacterSet = nil;
static NSCharacterSet *nonWhitespaceCharacterSet = nil;

+ (void)initialize {
    NSMutableCharacterSet *tmpSet = [NSMutableCharacterSet characterSetWithRange:NSMakeRange('a', 26)];
    [tmpSet addCharactersInRange:NSMakeRange('A', 26)];
    [tmpSet addCharactersInRange:NSMakeRange('0', 10)];
    [tmpSet addCharactersInString:@".-_@#"];
    keyCharacterSet = [tmpSet copy];
    
    invertedKeyCharacterSet = [[keyCharacterSet invertedSet] copy];
    
    nonWhitespaceCharacterSet = [[[NSCharacterSet whitespaceCharacterSet] invertedSet] copy];
}

static inline NSString *templateTagWithKeyPathAndDelims(NSMutableDictionary **dict, NSString *keyPath, NSString *openDelim, NSString *closeDelim) {
    NSString *endTag = [*dict objectForKey:keyPath];
    if (nil == endTag) {
        if (*dict == nil)
            *dict = [[NSMutableDictionary alloc] init];
        endTag = [[NSString alloc] initWithFormat:@"%@%@%@", openDelim, keyPath, closeDelim];
        [*dict setObject:endTag forKey:keyPath];
        [endTag release];
    }
    return endTag;
}

static inline NSString *endCollectionTagWithKeyPath(NSString *keyPath) {
    static NSMutableDictionary *endCollectionDict = nil;
    return templateTagWithKeyPathAndDelims(&endCollectionDict, keyPath, END_TAG_OPEN_DELIM, COLLECTION_TAG_CLOSE_DELIM);
}

static inline NSString *sepCollectionTagWithKeyPath(NSString *keyPath) {
    static NSMutableDictionary *sepCollectionDict = nil;
    return templateTagWithKeyPathAndDelims(&sepCollectionDict, keyPath, ALT_TAG_OPEN_DELIM, COLLECTION_TAG_CLOSE_DELIM);
}

static inline NSString *endConditionTagWithKeyPath(NSString *keyPath) {
    static NSMutableDictionary *endConditionDict = nil;
    return templateTagWithKeyPathAndDelims(&endConditionDict, keyPath, END_TAG_OPEN_DELIM, CONDITION_TAG_CLOSE_DELIM);
}

static inline NSString *altConditionTagWithKeyPath(NSString *keyPath) {
    static NSMutableDictionary *altConditionDict = nil;
    return templateTagWithKeyPathAndDelims(&altConditionDict, keyPath, ALT_TAG_OPEN_DELIM, CONDITION_TAG_CLOSE_DELIM);
}

static inline NSString *compareConditionTagWithKeyPath(NSString *keyPath, SKTemplateTagMatchType matchType) {
    static NSMutableDictionary *equalConditionDict = nil;
    static NSMutableDictionary *containConditionDict = nil;
    static NSMutableDictionary *smallerConditionDict = nil;
    static NSMutableDictionary *smallerOrEqualConditionDict = nil;
    static NSMutableDictionary *largerConditionDict = nil;
    static NSMutableDictionary *largerOrEqualConditionDict = nil;
    static NSMutableDictionary *notEqualConditionDict = nil;
    static NSMutableDictionary *notContainConditionDict = nil;
    switch (matchType) {
        case SKTemplateTagMatchEqual:
            return templateTagWithKeyPathAndDelims(&equalConditionDict, keyPath, ALT_TAG_OPEN_DELIM, CONDITION_TAG_EQUAL);
        case SKTemplateTagMatchContain:
            return templateTagWithKeyPathAndDelims(&containConditionDict, keyPath, ALT_TAG_OPEN_DELIM, CONDITION_TAG_CONTAIN);
        case SKTemplateTagMatchSmaller:
            return templateTagWithKeyPathAndDelims(&smallerConditionDict, keyPath, ALT_TAG_OPEN_DELIM, CONDITION_TAG_SMALLER);
        case SKTemplateTagMatchSmallerOrEqual:
            return templateTagWithKeyPathAndDelims(&smallerOrEqualConditionDict, keyPath, ALT_TAG_OPEN_DELIM, CONDITION_TAG_SMALLER_OR_EQUAL);
        case SKTemplateTagMatchLarger:
            return templateTagWithKeyPathAndDelims(&largerConditionDict, keyPath, ALT_TAG_OPEN_DELIM, CONDITION_TAG_LARGER);
        case SKTemplateTagMatchLargerOrEqual:
            return templateTagWithKeyPathAndDelims(&largerOrEqualConditionDict, keyPath, ALT_TAG_OPEN_DELIM, CONDITION_TAG_LARGER_OR_EQUAL);
        case SKTemplateTagMatchNotEqual:
            return templateTagWithKeyPathAndDelims(&notEqualConditionDict, keyPath, ALT_TAG_OPEN_DELIM, CONDITION_TAG_NOT_EQUAL);
        case SKTemplateTagMatchNotContain:
            return templateTagWithKeyPathAndDelims(&notContainConditionDict, keyPath, ALT_TAG_OPEN_DELIM, CONDITION_TAG_NOT_CONTAIN);
        default:
            return nil;
    }
}

static inline BOOL scanConditionTagMatchTypeAndString(NSScanner *scanner, SKTemplateTagMatchType *matchType, NSString **argString) {
    if ([scanner scanString:CONDITION_TAG_EQUAL intoString:NULL])
        *matchType = SKTemplateTagMatchEqual;
    else if ([scanner scanString:CONDITION_TAG_CONTAIN intoString:NULL])
        *matchType = SKTemplateTagMatchContain;
    else if ([scanner scanString:CONDITION_TAG_SMALLER_OR_EQUAL intoString:NULL])
        *matchType = SKTemplateTagMatchSmallerOrEqual;
    else if ([scanner scanString:CONDITION_TAG_SMALLER intoString:NULL])
        *matchType = SKTemplateTagMatchSmaller;
    else if ([scanner scanString:CONDITION_TAG_LARGER intoString:NULL])
        *matchType = SKTemplateTagMatchLarger;
    else if ([scanner scanString:CONDITION_TAG_LARGER_OR_EQUAL intoString:NULL])
        *matchType = SKTemplateTagMatchLargerOrEqual;
    else if ([scanner scanString:CONDITION_TAG_NOT_EQUAL intoString:NULL])
        *matchType = SKTemplateTagMatchNotEqual;
    else if ([scanner scanString:CONDITION_TAG_NOT_CONTAIN intoString:NULL])
        *matchType = SKTemplateTagMatchNotContain;
    else
        *matchType = SKTemplateTagMatchOther;
    
    if (*matchType == SKTemplateTagMatchOther || [scanner scanUpToString:CONDITION_TAG_CLOSE_DELIM intoString:argString] == NO)
        *argString = @"";
    
    return [scanner scanString:CONDITION_TAG_CLOSE_DELIM intoString:NULL];
}

static inline BOOL findAltConditionTag(NSString *template, NSString *altTag, NSString **argString, NSRange *range) {
    NSRange altTagRange = [template rangeOfString:altTag];
    if (altTagRange.location != NSNotFound) {
        // find the end tag and the argument (match string)
        NSRange endRange = [template rangeOfString:CONDITION_TAG_CLOSE_DELIM options:0 range:NSMakeRange(NSMaxRange(altTagRange), [template length] - NSMaxRange(altTagRange))];
        if (endRange.location != NSNotFound) {
            *argString = [template substringWithRange:NSMakeRange(NSMaxRange(altTagRange), endRange.location - NSMaxRange(altTagRange))];
            altTagRange.length = NSMaxRange(endRange) - altTagRange.location;
        } else {
            altTagRange = NSMakeRange(NSNotFound, 0);
        }
    }
    *range = altTagRange;
    return altTagRange.location != NSNotFound;
}

static id templateValueForKeyPath(id object, NSString *keyPath, NSInteger anIndex) {
    if ([keyPath hasPrefix:@"#"]) {
        if (anIndex <= 0)
            return nil;
        object = [NSNumber numberWithInteger:anIndex];
        if ([keyPath length] == 1)
            return object;
        if ([keyPath hasPrefix:@"#."] == NO || [keyPath length] < 3)
            return nil;
        keyPath = [keyPath substringFromIndex:2];
    } else if ([keyPath hasPrefix:@"."]) {
        if ([keyPath length] == 1)
            return nil;
        object = NSApp;
        keyPath = [keyPath substringFromIndex:1];
    }
    if (object == nil)
        return nil;
    id value = nil;
    NSString *trailingKeyPath = nil;
    NSUInteger atIndex = [keyPath rangeOfString:@"@"].location;
    if (atIndex != NSNotFound) {
        NSUInteger dotIndex = [keyPath rangeOfString:@"." options:0 range:NSMakeRange(atIndex + 1, [keyPath length] - atIndex - 1)].location;
        if (dotIndex != NSNotFound) {
            static NSSet *arrayOperators = nil;
            if (arrayOperators == nil)
                arrayOperators = [[NSSet alloc] initWithObjects:@"@avg", @"@max", @"@min", @"@sum", @"@distinctUnionOfArrays", @"@distinctUnionOfObjects", @"@distinctUnionOfSets", @"@unionOfArrays", @"@unionOfObjects", @"@unionOfSets", nil];
            if ([arrayOperators containsObject:[keyPath substringWithRange:NSMakeRange(atIndex, dotIndex - atIndex)]] == NO) {
                trailingKeyPath = [keyPath substringFromIndex:dotIndex + 1];
                keyPath = [keyPath substringToIndex:dotIndex];
            }
        }
    }
    @try{ value = [object valueForKeyPath:keyPath]; }
    @catch(id exception) { value = nil; }
    if (trailingKeyPath)
        value = templateValueForKeyPath(value, trailingKeyPath, 0);
    return value;
}

static inline BOOL matchesCondition(NSString *keyValue, NSString *matchString, SKTemplateTagMatchType matchType) {
    if ([matchString isEqualToString:@""]) {
        switch (matchType) {
            case SKTemplateTagMatchEqual:
            case SKTemplateTagMatchContain:
            case SKTemplateTagMatchSmallerOrEqual:
                return NO == [keyValue isNotEmpty];
            case SKTemplateTagMatchSmaller:
                return NO;
            case SKTemplateTagMatchLargerOrEqual:
                return YES;
            default:
                return [keyValue isNotEmpty];
        }
    } else {
        NSString *stringValue = [keyValue templateStringValue] ?: @"";
        switch (matchType) {
            case SKTemplateTagMatchEqual:
                return [stringValue isCaseInsensitiveEqual:matchString];
            case SKTemplateTagMatchContain:
                return [stringValue rangeOfString:matchString options:NSCaseInsensitiveSearch].location != NSNotFound;
            case SKTemplateTagMatchSmaller:
                return [stringValue compare:matchString options:NSCaseInsensitiveSearch | NSNumericSearch] == NSOrderedAscending;
            case SKTemplateTagMatchSmallerOrEqual:
                return [stringValue compare:matchString options:NSCaseInsensitiveSearch | NSNumericSearch] != NSOrderedDescending;
            case SKTemplateTagMatchLarger:
                return [stringValue compare:matchString options:NSCaseInsensitiveSearch | NSNumericSearch] == NSOrderedDescending;
            case SKTemplateTagMatchLargerOrEqual:
                return [stringValue compare:matchString options:NSCaseInsensitiveSearch | NSNumericSearch] != NSOrderedAscending;
            case SKTemplateTagMatchNotEqual:
                return [stringValue isCaseInsensitiveEqual:matchString] == NO;
            case SKTemplateTagMatchNotContain:
                return [stringValue rangeOfString:matchString options:NSCaseInsensitiveSearch].location == NSNotFound;
            default:
                return NO;
        }
    }
}

#define SKNoTemplateTagType (SKTemplateTagType)-1

static inline NSRange rangeAfterRemovingEmptyLines(NSString *string, SKTemplateTagType typeBefore, SKTemplateTagType typeAfter, BOOL isSubtemplate) {
    NSRange range = NSMakeRange(0, [string length]);
    
    if (typeAfter == SKTemplateTagCollection || typeAfter == SKTemplateTagCondition || (isSubtemplate && typeAfter == SKNoTemplateTagType)) {
        // remove whitespace at the end, just before the collection or condition tag
        NSRange lastCharRange = [string rangeOfCharacterFromSet:nonWhitespaceCharacterSet options:NSBackwardsSearch range:range];
        if (lastCharRange.location != NSNotFound) {
            unichar lastChar = [string characterAtIndex:lastCharRange.location];
            NSUInteger rangeEnd = NSMaxRange(lastCharRange);
            if ([[NSCharacterSet newlineCharacterSet] characterIsMember:lastChar])
                range.length = rangeEnd;
        } else if (isSubtemplate == NO && typeBefore == SKNoTemplateTagType) {
            range.length = 0;
        }
    }
    if (typeBefore == SKTemplateTagCollection || typeBefore == SKTemplateTagCondition || (isSubtemplate && typeBefore == SKNoTemplateTagType)) {
        // remove whitespace and a newline at the start, just after the collection or condition tag
        NSRange firstCharRange = [string rangeOfCharacterFromSet:nonWhitespaceCharacterSet options:0 range:range];
        if (firstCharRange.location != NSNotFound) {
            unichar firstChar = [string characterAtIndex:firstCharRange.location];
            NSUInteger rangeEnd = NSMaxRange(firstCharRange);
            if([[NSCharacterSet newlineCharacterSet] characterIsMember:firstChar]) {
                if (firstChar == NSCarriageReturnCharacter && rangeEnd < NSMaxRange(range) && [string characterAtIndex:rangeEnd] == NSNewlineCharacter)
                    range = NSMakeRange(rangeEnd + 1, NSMaxRange(range) - rangeEnd - 1);
                else 
                    range = NSMakeRange(rangeEnd, NSMaxRange(range) - rangeEnd);
            }
        } else if (isSubtemplate == NO && typeAfter == SKNoTemplateTagType) {
            range.length = 0;
        }
    }
    
    return range;
}

#pragma mark Parsing string templates

+ (NSString *)stringByParsingTemplateString:(NSString *)template usingObject:(id)object {
    return [self stringFromTemplateArray:[self arrayByParsingTemplateString:template] usingObject:object atIndex:0];
}

+ (NSArray *)arrayByParsingTemplateString:(NSString *)template {
    return [self arrayByParsingTemplateString:template isSubtemplate:NO];
}

+ (NSArray *)arrayByParsingTemplateString:(NSString *)template isSubtemplate:(BOOL)isSubtemplate {
    NSScanner *scanner = [[NSScanner alloc] initWithString:template];
    NSMutableArray *result = [[NSMutableArray alloc] init];
    id currentTag = nil;

    [scanner setCharactersToBeSkipped:nil];
    
    while (![scanner isAtEnd]) {
        NSString *beforeText = nil;
        NSString *keyPath = @"";
        NSInteger start;
                
        if ([scanner scanUpToString:START_TAG_OPEN_DELIM intoString:&beforeText]) {
            if (currentTag && [(SKTemplateTag *)currentTag type] == SKTemplateTagText) {
                [(SKTextTemplateTag *)currentTag appendText:beforeText];
            } else {
                currentTag = [[SKTextTemplateTag alloc] initWithText:beforeText];
                [result addObject:currentTag];
                [currentTag release];
            }
        }
        
        if ([scanner scanString:START_TAG_OPEN_DELIM intoString:NULL]) {
            
            start = [scanner scanLocation];
            
            // scan the key, must be letters and dots. We don't allow extra spaces
            // scanUpToCharactersFromSet is used for efficiency instead of scanCharactersFromSet
            [scanner scanUpToCharactersFromSet:invertedKeyCharacterSet intoString:&keyPath];
            
            if ([scanner scanString:VALUE_TAG_CLOSE_DELIM intoString:NULL]) {
                
                // simple template currentTag
                currentTag = [[SKValueTemplateTag alloc] initWithKeyPath:keyPath];
                [result addObject:currentTag];
                [currentTag release];
                
            } else if ([scanner scanString:COLLECTION_TAG_CLOSE_DELIM intoString:NULL]) {
                
                NSString *itemTemplate = @"", *separatorTemplate = nil;
                NSString *endTag;
                NSRange sepTagRange;
                
                // collection template tag
                endTag = endCollectionTagWithKeyPath(keyPath);
                [scanner scanUpToString:endTag intoString:&itemTemplate];
                if ([scanner scanString:endTag intoString:NULL]) {
                    sepTagRange = [itemTemplate rangeOfString:sepCollectionTagWithKeyPath(keyPath)];
                    if (sepTagRange.location != NSNotFound) {
                        separatorTemplate = [itemTemplate substringFromIndex:NSMaxRange(sepTagRange)];
                        itemTemplate = [itemTemplate substringToIndex:sepTagRange.location];
                    }
                    
                    currentTag = [(SKCollectionTemplateTag *)[SKCollectionTemplateTag alloc] initWithKeyPath:keyPath itemTemplateString:itemTemplate separatorTemplateString:separatorTemplate];
                    [result addObject:currentTag];
                    [currentTag release];
                }
                
            } else {
                
                NSString *matchString = @"";
                SKTemplateTagMatchType matchType = SKTemplateTagMatchOther;
                
                if (scanConditionTagMatchTypeAndString(scanner, &matchType, &matchString)) {
                    
                    NSMutableArray *subTemplates, *matchStrings;
                    NSString *subTemplate = @"";
                    NSString *endTag, *altTag;
                    NSRange altTagRange;
                    
                    // condition template tag
                    endTag = endConditionTagWithKeyPath(keyPath);
                    [scanner scanUpToString:endTag intoString:&subTemplate];
                    if ([scanner scanString:endTag intoString:NULL]) {
                        
                        subTemplates = [[NSMutableArray alloc] init];
                        matchStrings = [[NSMutableArray alloc] initWithObjects:matchString, nil];
                        
                        if (matchType != SKTemplateTagMatchOther) {
                            altTag = compareConditionTagWithKeyPath(keyPath, matchType);
                            while (findAltConditionTag(subTemplate, altTag, &matchString, &altTagRange)) {
                                [subTemplates addObject:[subTemplate substringToIndex:altTagRange.location]];
                                [matchStrings addObject:matchString];
                                subTemplate = [subTemplate substringFromIndex:NSMaxRange(altTagRange)];
                            }
                        }
                        
                        altTagRange = [subTemplate rangeOfString:altConditionTagWithKeyPath(keyPath)];
                        if (altTagRange.location != NSNotFound) {
                            [subTemplates addObject:[subTemplate substringToIndex:altTagRange.location]];
                            subTemplate = [subTemplate substringFromIndex:NSMaxRange(altTagRange)];
                        }
                        [subTemplates addObject:subTemplate];
                        
                        currentTag = [[SKConditionTemplateTag alloc] initWithKeyPath:keyPath matchType:matchType matchStrings:matchStrings subtemplates:subTemplates];
                        [result addObject:currentTag];
                        [currentTag release];
                        
                        [subTemplates release];
                        [matchStrings release];
                        
                    }
                    
                } else {
                    
                    // an open delimiter without a close delimiter, so no template tag. Rewind
                    if (currentTag && [(SKTemplateTag *)currentTag type] == SKTemplateTagText) {
                        [(SKTextTemplateTag *)currentTag appendText:START_TAG_OPEN_DELIM];
                    } else {
                        currentTag = [[SKTextTemplateTag alloc] initWithText:START_TAG_OPEN_DELIM];
                        [result addObject:currentTag];
                        [currentTag release];
                    }
                    [scanner setScanLocation:start];
                    
                }
            }
        } // scan START_TAG_OPEN_DELIM
    } // while
    [scanner release];
    
    // remove whitespace before and after collection and condition tags up till newlines
    NSInteger i, count = [result count];
    
    for (i = count - 1; i >= 0; i--) {
        SKTemplateTag *tag = [result objectAtIndex:i];
        
        if ([tag type] != SKTemplateTagText) continue;
        
        NSString *string = [(SKTextTemplateTag *)tag text];
        NSRange range = rangeAfterRemovingEmptyLines(string, i > 0 ? [(SKTemplateTag *)[result objectAtIndex:i - 1] type] : SKNoTemplateTagType, i < count - 1 ? [(SKTemplateTag *)[result objectAtIndex:i + 1] type] : SKNoTemplateTagType, isSubtemplate);
        
        if (range.length == 0)
            [result removeObjectAtIndex:i];
        else if (range.length != [string length])
            [(SKTextTemplateTag *)tag setText:[string substringWithRange:range]];
    }
    
    return [result autorelease];    
}

+ (NSString *)stringFromTemplateArray:(NSArray *)template usingObject:(id)object atIndex:(NSInteger)anIndex {
    NSMutableString *result = [[NSMutableString alloc] init];
    
    for (id tag in template) {
        SKTemplateTagType type = [(SKTemplateTag *)tag type];
        
        if (type == SKTemplateTagText) {
            
            [result appendString:[(SKTextTemplateTag *)tag text]];
            
        } else {
            
            NSString *keyPath = [tag keyPath];
            id keyValue = templateValueForKeyPath(object, keyPath, anIndex);
            
            if (type == SKTemplateTagValue) {
                
                if (keyValue)
                    [result appendString:[keyValue templateStringValue]];
                
            } else if (type == SKTemplateTagCollection) {
                
                NSArray *itemTemplate = nil;
                NSInteger idx = 1;
                id prevItem = nil;
                
                if ([keyValue conformsToProtocol:@protocol(NSFastEnumeration)]) {
                    for (id item in keyValue) {
                        if (prevItem) {
                            if (itemTemplate == nil)
                                itemTemplate = [[tag itemTemplate] arrayByAddingObjectsFromArray:[tag separatorTemplate]];
                            keyValue = [self stringFromTemplateArray:itemTemplate usingObject:prevItem atIndex:idx++];
                            if (keyValue != nil)
                                [result appendString:keyValue];
                        }
                        prevItem = item;
                    }
                } else if ([keyValue isNotEmpty]) {
                    prevItem = keyValue;
                    idx = anIndex;
                }
                if (prevItem) {
                    itemTemplate = [tag itemTemplate];
                    keyValue = [self stringFromTemplateArray:itemTemplate usingObject:prevItem atIndex:idx];
                    if (keyValue != nil)
                        [result appendString:keyValue];
                }
                
            } else {
                
                NSString *matchString = nil;
                NSArray *matchStrings = [tag matchStrings];
                NSUInteger i, count = [matchStrings count];
                NSArray *subtemplate = nil;
                
                for (i = 0; i < count; i++) {
                    matchString = [matchStrings objectAtIndex:i];
                    if ([matchString hasPrefix:@"$"])
                        matchString = [templateValueForKeyPath(object, [matchString substringFromIndex:1], anIndex) templateStringValue] ?: @"";
                    if (matchesCondition(keyValue, matchString, [tag matchType])) {
                        subtemplate = [tag objectInSubtemplatesAtIndex:i];
                        break;
                    }
                }
                if (subtemplate == nil && [tag countOfSubtemplates] > count)
                    subtemplate = [tag objectInSubtemplatesAtIndex:count];
                if (subtemplate != nil) {
                    if ((keyValue = [self stringFromTemplateArray:subtemplate usingObject:object atIndex:anIndex]))
                        [result appendString:keyValue];
                }
                
            }
            
        }
    } // while
    
    return [result autorelease];    
}

#pragma mark Parsing attributed string templates

+ (NSAttributedString *)attributedStringByParsingTemplateAttributedString:(NSAttributedString *)template usingObject:(id)object {
    return [self attributedStringFromTemplateArray:[self arrayByParsingTemplateAttributedString:template] usingObject:object atIndex:0];
}

+ (NSArray *)arrayByParsingTemplateAttributedString:(NSAttributedString *)template {
    return [self arrayByParsingTemplateAttributedString:template isSubtemplate:NO];
}

+ (NSArray *)arrayByParsingTemplateAttributedString:(NSAttributedString *)template isSubtemplate:(BOOL)isSubtemplate {
    NSString *templateString = [template string];
    NSScanner *scanner = [[NSScanner alloc] initWithString:templateString];
    NSMutableArray *result = [[NSMutableArray alloc] init];
    id currentTag = nil;

    [scanner setCharactersToBeSkipped:nil];
    
    while (![scanner isAtEnd]) {
        NSString *beforeText = nil;
        NSString *keyPath = @"";
        NSInteger start;
        NSDictionary *attr = nil;
        
        start = [scanner scanLocation];
                
        if ([scanner scanUpToString:START_TAG_OPEN_DELIM intoString:&beforeText]) {
            if (currentTag && [(SKTemplateTag *)currentTag type] == SKTemplateTagText) {
                [(SKRichTextTemplateTag *)currentTag appendAttributedText:[template attributedSubstringFromRange:NSMakeRange(start, [beforeText length])]];
            } else {
                currentTag = [[SKRichTextTemplateTag alloc] initWithAttributedText:[template attributedSubstringFromRange:NSMakeRange(start, [beforeText length])]];
                [result addObject:currentTag];
                [currentTag release];
            }
        }
        
        if ([scanner scanString:START_TAG_OPEN_DELIM intoString:NULL]) {
            
            attr = [template attributesAtIndex:[scanner scanLocation] - [START_TAG_OPEN_DELIM length] effectiveRange:NULL];
            start = [scanner scanLocation];
            
            // scan the key, must be letters and dots. We don't allow extra spaces
            // scanUpToCharactersFromSet is used for efficiency instead of scanCharactersFromSet
            [scanner scanUpToCharactersFromSet:invertedKeyCharacterSet intoString:&keyPath];

            if ([scanner scanString:VALUE_TAG_CLOSE_DELIM intoString:NULL]) {
                
                // simple template tag
                currentTag = [[SKRichValueTemplateTag alloc] initWithKeyPath:keyPath attributes:attr];
                [result addObject:currentTag];
                [currentTag release];
                
            } else if ([scanner scanString:COLLECTION_TAG_CLOSE_DELIM intoString:NULL]) {
                
                NSString *itemTemplateString = @"";
                NSAttributedString *itemTemplate = nil, *separatorTemplate = nil;
                NSString *endTag;
                NSRange sepTagRange;
                
                // collection template tag
                endTag = endCollectionTagWithKeyPath(keyPath);
                if ([scanner scanString:endTag intoString:NULL])
                    continue;
                start = [scanner scanLocation];
                [scanner scanUpToString:endTag intoString:&itemTemplateString];
                if ([scanner scanString:endTag intoString:NULL]) {
                    itemTemplate = [template attributedSubstringFromRange:NSMakeRange(start, [itemTemplateString length])];
                    
                    sepTagRange = [[itemTemplate string] rangeOfString:sepCollectionTagWithKeyPath(keyPath)];
                    if (sepTagRange.location != NSNotFound) {
                        separatorTemplate = [itemTemplate attributedSubstringFromRange:NSMakeRange(NSMaxRange(sepTagRange), [itemTemplate length] - NSMaxRange(sepTagRange))];
                        itemTemplate = [itemTemplate attributedSubstringFromRange:NSMakeRange(0, sepTagRange.location)];
                    }
                    
                    currentTag = [(SKRichCollectionTemplateTag *)[SKRichCollectionTemplateTag alloc] initWithKeyPath:keyPath itemTemplateAttributedString:itemTemplate separatorTemplateAttributedString:separatorTemplate];
                    [result addObject:currentTag];
                    [currentTag release];
                    
                }
                
            } else {
                
                NSString *matchString = @"";
                SKTemplateTagMatchType matchType = SKTemplateTagMatchOther;
                
                if (scanConditionTagMatchTypeAndString(scanner, &matchType, &matchString)) {
                    
                    NSMutableArray *subTemplates, *matchStrings;
                    NSString *subTemplateString = nil;
                    NSAttributedString *subTemplate = nil;
                    NSString *endTag, *altTag;
                    NSRange altTagRange;
                    
                    // condition template tag
                    endTag = endConditionTagWithKeyPath(keyPath);
                    start = [scanner scanLocation];
                    [scanner scanUpToString:endTag intoString:&subTemplateString];
                    if ([scanner scanString:endTag intoString:NULL]) {
                        subTemplate = [template attributedSubstringFromRange:NSMakeRange(start, [subTemplateString length])];
                        
                        subTemplates = [[NSMutableArray alloc] init];
                        matchStrings = [[NSMutableArray alloc] initWithObjects:matchString, nil];
                        
                        if (matchType != SKTemplateTagMatchOther) {
                            altTag = compareConditionTagWithKeyPath(keyPath, matchType);
                            while (findAltConditionTag([subTemplate string], altTag, &matchString, &altTagRange)) {
                                [subTemplates addObject:[subTemplate attributedSubstringFromRange:NSMakeRange(0, altTagRange.location)]];
                                [matchStrings addObject:matchString];
                                subTemplate = [subTemplate attributedSubstringFromRange:NSMakeRange(NSMaxRange(altTagRange), [subTemplate length] - NSMaxRange(altTagRange))];
                            }
                        }
                        
                        altTagRange = [[subTemplate string] rangeOfString:altConditionTagWithKeyPath(keyPath)];
                        if (altTagRange.location != NSNotFound) {
                            [subTemplates addObject:[subTemplate attributedSubstringFromRange:NSMakeRange(0, altTagRange.location)]];
                            subTemplate = [subTemplate attributedSubstringFromRange:NSMakeRange(NSMaxRange(altTagRange), [subTemplate length] - NSMaxRange(altTagRange))];
                        }
                        [subTemplates addObject:subTemplate];
                        
                        currentTag = [[SKRichConditionTemplateTag alloc] initWithKeyPath:keyPath matchType:matchType matchStrings:matchStrings subtemplates:subTemplates];
                        [result addObject:currentTag];
                        [currentTag release];
                        
                        [subTemplates release];
                        [matchStrings release];
                        
                    }
                    
                } else {
                    
                    // a START_TAG_OPEN_DELIM without COLLECTION_TAG_CLOSE_DELIM, so no template tag. Rewind
                    if (currentTag && [(SKTemplateTag *)currentTag type] == SKTemplateTagText) {
                        [(SKRichTextTemplateTag *)currentTag appendAttributedText:[template attributedSubstringFromRange:NSMakeRange(start - [START_TAG_OPEN_DELIM length], [START_TAG_OPEN_DELIM length])]];
                    } else {
                        currentTag = [[SKRichTextTemplateTag alloc] initWithAttributedText:[template attributedSubstringFromRange:NSMakeRange(start - [START_TAG_OPEN_DELIM length], [START_TAG_OPEN_DELIM length])]];
                        [result addObject:currentTag];
                        [currentTag release];
                    }
                    [scanner setScanLocation:start];
                    
                }
            }
        } // scan START_TAG_OPEN_DELIM
    } // while
    
    [scanner release];
    
    // remove whitespace before and after collection and condition tags up till newlines
    NSInteger i, count = [result count];
    
    for (i = count - 1; i >= 0; i--) {
        SKTemplateTag *tag = [result objectAtIndex:i];
        
        if ([tag type] != SKTemplateTagText) continue;
        
        NSAttributedString *attrString = [(SKRichTextTemplateTag *)tag attributedText];
        NSString *string = [attrString string];
        NSRange range = rangeAfterRemovingEmptyLines(string, i > 0 ? [(SKTemplateTag *)[result objectAtIndex:i - 1] type] : SKNoTemplateTagType, i < count - 1 ? [(SKTemplateTag *)[result objectAtIndex:i + 1] type] : SKNoTemplateTagType, isSubtemplate);
        
        if (range.length == 0)
            [result removeObjectAtIndex:i];
        else if (range.length != [string length])
            [(SKRichTextTemplateTag *)tag setAttributedText:[attrString attributedSubstringFromRange:range]];
    }
    
    return [result autorelease];    
}

+ (id)attributeFromTemplate:(SKAttributeTemplate *)attributeTemplate usingObject:(id)object atIndex:(NSInteger)anIndex {
    id anAttribute = [self stringFromTemplateArray:[attributeTemplate template] usingObject:object atIndex:anIndex];
    if (anAttribute && [[attributeTemplate attributeClass] isSubclassOfClass:[NSURL class]]) {
        anAttribute = [(id)CFURLCreateStringByAddingPercentEscapes(NULL, (CFStringRef)anAttribute, CFSTR("#%"), NULL, kCFStringEncodingUTF8) autorelease];
        anAttribute = [NSURL URLWithString:anAttribute];
    }
    return anAttribute;
}

+ (NSAttributedString *)attributedStringFromTemplateArray:(NSArray *)template usingObject:(id)object atIndex:(NSInteger)anIndex {
    NSMutableAttributedString *result = [[NSMutableAttributedString alloc] init];
    
    for (id tag in template) {
        SKTemplateTagType type = [(SKTemplateTag *)tag type];
        
        if (type == SKTemplateTagText) {
            
            NSAttributedString *tmpAttrStr = [(SKRichTextTemplateTag *)tag attributedText];
            NSArray *linkTemplates = [(SKRichTextTemplateTag *)tag linkTemplates];
            
            if ([linkTemplates count]) {
                NSMutableAttributedString *tmpMutAttrStr = [tmpAttrStr mutableCopy];
                for (SKAttributeTemplate *linkTemplate in linkTemplates) {
                    NSRange range = [linkTemplate range];
                    id aLink = [self attributeFromTemplate:linkTemplate usingObject:object atIndex:anIndex];
                    if (aLink)
                        [tmpMutAttrStr addAttribute:NSLinkAttributeName value:aLink range:range];
                    else
                        [tmpMutAttrStr removeAttribute:NSLinkAttributeName range:range];
                }
                [result appendAttributedString:tmpMutAttrStr];
                [tmpMutAttrStr release];
            } else {
                [result appendAttributedString:tmpAttrStr];
            }
            
        } else {
            
            NSString *keyPath = [tag keyPath];
            id keyValue = templateValueForKeyPath(object, keyPath, anIndex);
            
            if (type == SKTemplateTagValue) {
                
                if (keyValue) {
                    NSAttributedString *tmpAttrStr;
                    NSDictionary *attrs = [(SKRichValueTemplateTag *)tag attributes];
                    SKAttributeTemplate *linkTemplate = [(SKRichValueTemplateTag *)tag linkTemplate];
                    if (linkTemplate) {
                        NSMutableDictionary *tmpAttrs = [attrs mutableCopy];
                        id aLink = [self attributeFromTemplate:linkTemplate usingObject:object atIndex:anIndex];
                        [tmpAttrs setValue:aLink forKey:NSLinkAttributeName];
                        tmpAttrStr = [keyValue templateAttributedStringValueWithAttributes:tmpAttrs];
                        [tmpAttrs release];
                    } else {
                        tmpAttrStr = [keyValue templateAttributedStringValueWithAttributes:attrs];
                    }
                    if (tmpAttrStr != nil)
                        [result appendAttributedString:tmpAttrStr];
                }
                
            } else if (type == SKTemplateTagCollection) {
                
                NSAttributedString *tmpAttrStr = nil;
                NSArray *itemTemplate = nil;
                NSInteger idx = 1;
                id prevItem = nil;
                
                if ([keyValue conformsToProtocol:@protocol(NSFastEnumeration)]) {
                    for (id item in keyValue) {
                        if (prevItem) {
                            if (itemTemplate == nil)
                                itemTemplate = [[tag itemTemplate] arrayByAddingObjectsFromArray:[tag separatorTemplate]];
                            tmpAttrStr = [self attributedStringFromTemplateArray:itemTemplate usingObject:prevItem atIndex:idx++];
                            if (tmpAttrStr != nil)
                                [result appendAttributedString:tmpAttrStr];
                        }
                        prevItem = item;
                    }
                } else if ([keyValue isNotEmpty]) {
                    prevItem = keyValue;
                    idx = anIndex;
                }
                if (prevItem) {
                    itemTemplate = [tag itemTemplate];
                    tmpAttrStr = [self attributedStringFromTemplateArray:itemTemplate usingObject:prevItem atIndex:idx];
                    if (tmpAttrStr != nil)
                        [result appendAttributedString:tmpAttrStr];
                }
                
            } else {
                
                NSString *matchString = nil;
                NSArray *matchStrings = [tag matchStrings];
                NSUInteger i, count = [matchStrings count];
                NSArray *subtemplate = nil;
                
                subtemplate = nil;
                for (i = 0; i < count; i++) {
                    matchString = [matchStrings objectAtIndex:i];
                    if ([matchString hasPrefix:@"$"])
                        matchString = [templateValueForKeyPath(object, [matchString substringFromIndex:1], anIndex) templateStringValue] ?: @"";
                    if (matchesCondition(keyValue, matchString, [tag matchType])) {
                        subtemplate = [tag objectInSubtemplatesAtIndex:i];
                        break;
                    }
                }
                if (subtemplate == nil && [tag countOfSubtemplates] > count)
                    subtemplate = [tag objectInSubtemplatesAtIndex:count];
                if (subtemplate != nil) {
                    NSAttributedString *tmpAttrStr = [self attributedStringFromTemplateArray:subtemplate usingObject:object atIndex:anIndex];
                    if (tmpAttrStr != nil)
                        [result appendAttributedString:tmpAttrStr];
                }
                
            }
            
        }
    } // while
    
    [result fixAttributesInRange:NSMakeRange(0, [result length])];
    
    return [result autorelease];    
}

@end

#pragma mark -

@implementation NSObject (SKTemplateParser)

+ (BOOL)isNotEmpty {
    return YES;
}

+ (NSString *)templateStringValue {
    return NSStringFromClass(self);
}

+ (NSAttributedString *)templateAttributedStringValueWithAttributes:(NSDictionary *)attributes {
    return [[[NSAttributedString alloc] initWithString:[self templateStringValue] attributes:attributes] autorelease];
}

- (BOOL)isNotEmpty {
    if ([self respondsToSelector:@selector(count)])
        return [(id)self count] > 0;
    if ([self respondsToSelector:@selector(length)])
        return [(id)self length] > 0;
    return YES;
}

- (NSString *)templateStringValue {
    if ([self respondsToSelector:@selector(stringValue)])
        return [(id)self stringValue] ?: @"";
    if ([self respondsToSelector:@selector(string)])
        return [(id)self string] ?: @"";
    return [self description];
}

- (NSAttributedString *)templateAttributedStringValueWithAttributes:(NSDictionary *)attributes {
    return [[[NSAttributedString alloc] initWithString:[self templateStringValue] attributes:attributes] autorelease];
}

@end

#pragma mark -

@implementation NSAttributedString (SKTemplateParser)

- (NSAttributedString *)templateAttributedStringValueWithAttributes:(NSDictionary *)attributes {
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:[self string] attributes:attributes];
    NSRange range = NSMakeRange(0, [self length]);
    [self enumerateAttributesInRange:range options:0 usingBlock:^(NSDictionary *attrs, NSRange r, BOOL *stop){
        [attributedString addAttributes:attrs range:r];
    }];
    [attributedString fixAttributesInRange:range];
    return [attributedString autorelease];
}

@end

#pragma mark -

@implementation NSString (SKTemplateParser)
- (NSString *)templateStringValue{ return self; }
@end

#pragma mark -

@implementation NSNumber (SKTemplateParser)
- (BOOL)isNotEmpty { return [self isEqualToNumber:[NSNumber numberWithBool:NO]] == NO && [self isEqualToNumber:[NSNumber numberWithInteger:0]] == NO; }
@end

#pragma mark -

@implementation NSNull (SKTemplateParser)
+ (NSString *)templateStringValue{ return @""; }
+ (BOOL)isNotEmpty { return NO; }
- (NSString *)templateStringValue{ return @""; }
- (BOOL)isNotEmpty { return NO; }
@end

#pragma mark -

@implementation PDFSelection (SKTemplateParser)
- (NSAttributedString *)templateAttributedStringValueWithAttributes:(NSDictionary *)attributes {
    return [[self attributedString] templateAttributedStringValueWithAttributes:attributes];
}
- (BOOL)isNotEmpty { return [self hasCharacters]; }
@end
