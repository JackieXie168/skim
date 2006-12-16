//
//  BDSKTemplateParser.m
//  Bibdesk
//
//  Created by Christiaan Hofman on 5/17/06.
/*
 This software is Copyright (c)2006
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
 DATA, OR PROFITS; OR BUSINESS INTERRUPTION)HOWEVER CAUSED AND ON ANY
 THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 (INCLUDING NEGLIGENCE OR OTHERWISE)ARISING IN ANY WAY OUT OF THE USE
 OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "BDSKTemplateParser.h"
#import "NSString_BDSKExtensions.h"
#import "NSAttributedString_BDSKExtensions.h"
#import "BibAuthor.h"

#define STARTTAG_OPEN_DELIM @"<$"
#define ENDTAG_OPEN_DELIM @"</$"
#define SEPTAG_OPEN_DELIM @"<?$"
#define SINGLETAG_CLOSE_DELIM @"/>"
#define MULTITAG_CLOSE_DELIM @">"
#define CONDITIONTAG_CLOSE_DELIM @"?>"
#define CONDITIONTAG_EQUAL @"="
#define CONDITIONTAG_CONTAIN @"~"

/*
       single tag: <$key/>
        multi tag: <$key> </$key> 
               or: <$key> <?$key> </$key>
    condition tag: <$key?> </$key?> 
               or: <$key?> <?$key?> </$key?>
               or: <$key=value?> </$key?>
               or: <$key=value?> <?$key?> </$key?>
               or: <$key~value?> </$key?>
               or: <$key~value?> <?$key?> </$key?>
*/

@implementation BDSKTemplateParser


static NSCharacterSet *keyCharacterSet = nil;
static NSCharacterSet *invertedKeyCharacterSet = nil;

+ (void)initialize {
    
    OBINITIALIZE;
    
    NSMutableCharacterSet *tmpSet = [[NSCharacterSet alphanumericCharacterSet] mutableCopy];
    [tmpSet addCharactersInString:@".-:;@"];
    keyCharacterSet = [tmpSet copy];
    [tmpSet release];
    
    invertedKeyCharacterSet = [[keyCharacterSet invertedSet] copy];
}

static NSMutableDictionary *endMultiDict = nil;
static inline NSString *endMultiTagWithTag(NSString *tag){
    if(nil == endMultiDict)
        endMultiDict = [[NSMutableDictionary alloc] init];
    
    NSString *endTag = [endMultiDict objectForKey:tag];
    if(nil == endTag){
        endTag = [NSString stringWithFormat:@"%@%@%@", ENDTAG_OPEN_DELIM, tag, MULTITAG_CLOSE_DELIM];
        [endMultiDict setObject:endTag forKey:tag];
    }
    return endTag;
}

static NSMutableDictionary *sepMultiDict = nil;
static inline NSString *sepMultiTagWithTag(NSString *tag){
    if(nil == sepMultiDict)
        sepMultiDict = [[NSMutableDictionary alloc] init];
    
    NSString *altTag = [sepMultiDict objectForKey:tag];
    if(nil == altTag){
        altTag = [NSString stringWithFormat:@"%@%@%@", SEPTAG_OPEN_DELIM, tag, MULTITAG_CLOSE_DELIM];
        [sepMultiDict setObject:altTag forKey:tag];
    }
    return altTag;
}

static NSMutableDictionary *endConditionDict = nil;
static inline NSString *endConditionTagWithTag(NSString *tag){
    if(nil == endConditionDict)
        endConditionDict = [[NSMutableDictionary alloc] init];
    
    NSString *endTag = [endConditionDict objectForKey:tag];
    if(nil == endTag){
        endTag = [NSString stringWithFormat:@"%@%@%@", ENDTAG_OPEN_DELIM, tag, CONDITIONTAG_CLOSE_DELIM];
        [endConditionDict setObject:endTag forKey:tag];
    }
    return endTag;
}

static NSMutableDictionary *altConditionDict = nil;
static inline NSString *altConditionTagWithTag(NSString *tag){
    if(nil == altConditionDict)
        altConditionDict = [[NSMutableDictionary alloc] init];
    
    NSString *altTag = [altConditionDict objectForKey:tag];
    if(nil == altTag){
        altTag = [NSString stringWithFormat:@"%@%@%@", SEPTAG_OPEN_DELIM, tag, CONDITIONTAG_CLOSE_DELIM];
        [altConditionDict setObject:altTag forKey:tag];
    }
    return altTag;
}

static NSMutableDictionary *equalConditionDict = nil;
static inline NSString *equalConditionTagWithTag(NSString *tag){
    if(nil == equalConditionDict)
        equalConditionDict = [[NSMutableDictionary alloc] init];
    
    NSString *equalTag = [equalConditionDict objectForKey:tag];
    if(nil == equalTag){
        equalTag = [NSString stringWithFormat:@"%@%@%@", SEPTAG_OPEN_DELIM, tag, CONDITIONTAG_EQUAL];
        [equalConditionDict setObject:equalTag forKey:tag];
    }
    return equalTag;
}

static NSMutableDictionary *containConditionDict = nil;
static inline NSString *containConditionTagWithTag(NSString *tag){
    if(nil == containConditionDict)
        containConditionDict = [[NSMutableDictionary alloc] init];
    
    NSString *containTag = [containConditionDict objectForKey:tag];
    if(nil == containTag){
        containTag = [NSString stringWithFormat:@"%@%@%@", SEPTAG_OPEN_DELIM, tag, CONDITIONTAG_CONTAIN];
        [containConditionDict setObject:containTag forKey:tag];
    }
    return containTag;
}

static inline NSRange altTemplateTagRange(NSString *template, NSString *altTag, NSString *endDelim, NSString **argString){
    NSRange altTagRange = [template rangeOfString:altTag];
    if (altTagRange.location != NSNotFound) {
        // ignore whitespaces before the tag
        NSRange wsRange = [template rangeOfTrailingEmptyLineInRange:NSMakeRange(0, altTagRange.location)];
        if (wsRange.location != NSNotFound) 
            altTagRange = NSMakeRange(wsRange.location, NSMaxRange(altTagRange) - wsRange.location);
        if (nil != endDelim) {
            // find the end tag and the argument (match string)
            NSRange endRange = [template rangeOfString:endDelim options:0 range:NSMakeRange(NSMaxRange(altTagRange), [template length] - NSMaxRange(altTagRange))];
            if (endRange.location != NSNotFound) {
                *argString = [template substringWithRange:NSMakeRange(NSMaxRange(altTagRange), endRange.location - NSMaxRange(altTagRange))];
                altTagRange.length = NSMaxRange(endRange) - altTagRange.location;
            } else {
                *argString = @"";
            }
        }
        // ignore whitespaces after the tag, including a trailing newline 
        wsRange = [template rangeOfLeadingEmptyLineInRange:NSMakeRange(NSMaxRange(altTagRange), [template length] - NSMaxRange(altTagRange))];
        if (wsRange.location != NSNotFound)
            altTagRange.length = NSMaxRange(wsRange) - altTagRange.location;
    }
    return altTagRange;
}

+ (NSString *)stringByParsingTemplate:(NSString *)template usingObject:(id)object {
    return [self stringByParsingTemplate:template usingObject:object delegate:nil];
}

+ (NSString *)stringByParsingTemplate:(NSString *)template usingObject:(id)object delegate:(id <BDSKTemplateParserDelegate>)delegate {
    NSScanner *scanner = [[NSScanner alloc] initWithString:template];
    NSMutableString *result = [[NSMutableString alloc] init];

    [scanner setCharactersToBeSkipped:nil];
    
    while (![scanner isAtEnd]) {
        NSString *beforeText = nil;
        NSString *tag = nil;
        id keyValue = nil;
        int start;
                
        if ([scanner scanUpToString:STARTTAG_OPEN_DELIM intoString:&beforeText])
            [result appendString:beforeText];
        
        if ([scanner scanString:STARTTAG_OPEN_DELIM intoString:nil]) {
            
            start = [scanner scanLocation];
            
            // scan the key, must be letters and dots. We don't allow extra spaces
            // scanUpToCharactersFromSet is used for efficiency instead of scanCharactersFromSet
            [scanner scanUpToCharactersFromSet:invertedKeyCharacterSet intoString:&tag];
            
            if ([scanner scanString:SINGLETAG_CLOSE_DELIM intoString:nil]) {
                
                // simple template tag
                @try{ keyValue = [object valueForKeyPath:tag]; }
                @catch (id exception) { keyValue = nil; }
                if (keyValue != nil) 
                    [result appendString:[keyValue stringDescription]];
                
            } else if ([scanner scanString:MULTITAG_CLOSE_DELIM intoString:nil]) {
                
                NSString *itemTemplate = nil, *lastItemTemplate = nil;
                NSMutableString *tmpString;
                NSString *endTag;
                NSRange sepTagRange, wsRange;
                
                // collection template tag
                // ignore whitespace before the tag. Should we also remove a newline?
                wsRange = [result rangeOfTrailingEmptyLine];
                if (wsRange.location != NSNotFound)
                    [result deleteCharactersInRange:wsRange];
                
                endTag = endMultiTagWithTag(tag);
                // ignore the rest of an empty line after the tag
                [scanner scanEmptyLine];
                if ([scanner scanString:endTag intoString:nil])
                    continue;
                if ([scanner scanUpToString:endTag intoString:&itemTemplate] && [scanner scanString:endTag intoString:nil]) {
                    // ignore whitespace before the tag. Should we also remove a newline?
                    wsRange = [itemTemplate rangeOfTrailingEmptyLine];
                    if (wsRange.location != NSNotFound)
                        itemTemplate = [itemTemplate substringToIndex:wsRange.location];
                    
                    sepTagRange = altTemplateTagRange(itemTemplate, sepMultiTagWithTag(tag), nil, NULL);
                    if (sepTagRange.location != NSNotFound) {
                        lastItemTemplate = [itemTemplate substringToIndex:sepTagRange.location];
                        tmpString = [itemTemplate mutableCopy];
                        [tmpString deleteCharactersInRange:sepTagRange];
                        itemTemplate = [tmpString autorelease];
                    } else {
                        lastItemTemplate = nil;
                    }
                    
                    @try{ keyValue = [object valueForKeyPath:tag]; }
                    @catch (id exception) { keyValue = nil; }
                    if ([keyValue respondsToSelector:@selector(objectEnumerator)]) {
                        NSEnumerator *itemE = [keyValue objectEnumerator];
                        id nextItem, item = [itemE nextObject];
                        while (item) {
                            nextItem = [itemE nextObject];
                            if (lastItemTemplate != nil && nextItem == nil)
                                itemTemplate = lastItemTemplate;
                            [delegate templateParserWillParseTemplate:itemTemplate usingObject:item isAttributed:NO];
                            keyValue = [self stringByParsingTemplate:itemTemplate usingObject:item delegate:delegate];
                            [delegate templateParserDidParseTemplate:itemTemplate usingObject:item isAttributed:NO];
                            if (keyValue != nil)
                                [result appendString:keyValue];
                            item = nextItem;
                        }
                    }
                    // ignore the the rest of an empty line after the tag
                    [scanner scanEmptyLine];
                    
                }
                
            } else {
                
                NSString *matchString = nil;
                BOOL matchEqual = NO;
                BOOL matchContain = NO;
                
                if ([scanner scanString:CONDITIONTAG_EQUAL intoString:nil]) {
                    if([scanner scanUpToString:CONDITIONTAG_CLOSE_DELIM intoString:&matchString] == NO)
                        matchString = @"";
                    matchEqual = YES;
                } else if ([scanner scanString:CONDITIONTAG_CONTAIN intoString:nil]) {
                    if([scanner scanUpToString:CONDITIONTAG_CLOSE_DELIM intoString:&matchString] == NO)
                        matchString = @"";
                    matchContain = YES;
                }
                
                if ([scanner scanString:CONDITIONTAG_CLOSE_DELIM intoString:nil]) {
                    
                    NSMutableArray *subTemplates, *matchStrings;
                    NSString *subTemplate = nil;
                    NSString *endTag, *altTag;
                    NSRange altTagRange, wsRange;
                    BOOL isMatch;
                    unsigned i, count;
                    
                    // condition template tag
                    // ignore whitespace before the tag. Should we also remove a newline?
                    wsRange = [result rangeOfTrailingEmptyLine];
                    if (wsRange.location != NSNotFound)
                        [result deleteCharactersInRange:wsRange];
                    
                    endTag = endConditionTagWithTag(tag);
                    // ignore the rest of an empty line after the tag
                    [scanner scanEmptyLine];
                    if ([scanner scanString:endTag intoString:nil])
                        continue;
                    if ([scanner scanUpToString:endTag intoString:&subTemplate] && [scanner scanString:endTag intoString:nil]) {
                        // ignore whitespace before the tag. Should we also remove a newline?
                        wsRange = [subTemplate rangeOfTrailingEmptyLine];
                        if (wsRange.location != NSNotFound)
                            subTemplate = [subTemplate substringToIndex:wsRange.location];
                        
                        subTemplates = [[NSMutableArray alloc] init];
                        matchStrings = [[NSMutableArray alloc] initWithObjects:matchString ? matchString : @"", nil];
                        
                        if (matchEqual || matchContain) {
                            altTag = matchEqual ? equalConditionTagWithTag(tag) : containConditionTagWithTag(tag);
                            altTagRange = altTemplateTagRange(subTemplate, altTag, CONDITIONTAG_CLOSE_DELIM, &matchString);
                            while (altTagRange.location != NSNotFound) {
                                [subTemplates addObject:[subTemplate substringToIndex:altTagRange.location]];
                                [matchStrings addObject:matchString];
                                subTemplate = [subTemplate substringFromIndex:NSMaxRange(altTagRange)];
                                altTagRange = altTemplateTagRange(subTemplate, altTag, CONDITIONTAG_CLOSE_DELIM, &matchString);
                            }
                        }
                        
                        altTagRange = altTemplateTagRange(subTemplate, altConditionTagWithTag(tag), nil, NULL);
                        if (altTagRange.location != NSNotFound) {
                            [subTemplates addObject:[subTemplate substringToIndex:altTagRange.location]];
                            subTemplate = [subTemplate substringFromIndex:NSMaxRange(altTagRange)];
                        }
                        [subTemplates addObject:subTemplate];
                        
                        @try{ keyValue = [object valueForKeyPath:tag]; }
                        @catch (id exception) { keyValue = nil; }
                        count = [matchStrings count];
                        subTemplate = nil;
                        for (i = 0; i < count; i++) {
                            isMatch = [keyValue isNotEmpty];
                            matchString = [matchStrings objectAtIndex:i];
                            if (matchEqual) {
                                isMatch = [matchString isEqualToString:@""] ? NO == isMatch : [[keyValue stringDescription] caseInsensitiveCompare:matchString] == NSOrderedSame;
                            } else if (matchContain) {
                                isMatch = [matchString isEqualToString:@""] ? NO == isMatch : [[keyValue stringDescription] rangeOfString:matchString options:NSCaseInsensitiveSearch].location != NSNotFound;
                            }
                            if (isMatch) {
                                subTemplate = [subTemplates objectAtIndex:i];
                                break;
                            }
                        }
                        if (subTemplate == nil && [subTemplates count] > count) {
                            subTemplate = [subTemplates objectAtIndex:count];
                        }
                        if (subTemplate != nil) {
                            keyValue = [self stringByParsingTemplate:subTemplate usingObject:object delegate:delegate];
                            [result appendString:keyValue];
                        }
                        [subTemplates release];
                        [matchStrings release];
                        // ignore the the rest of an empty line after the tag
                        [scanner scanEmptyLine];
                        
                    }
                    
                } else {
                    
                    // an open delimiter without a close delimiter, so no template tag. Rewind
                    [result appendString:STARTTAG_OPEN_DELIM];
                    [scanner setScanLocation:start];
                    
                }
            }
        } // scan STARTTAG_OPEN_DELIM
    } // while
    [scanner release];
    return [result autorelease];    
}

+ (NSAttributedString *)attributedStringByParsingTemplate:(NSAttributedString *)template usingObject:(id)object {
    return [self attributedStringByParsingTemplate:template usingObject:object delegate:nil];
}

+ (NSAttributedString *)attributedStringByParsingTemplate:(NSAttributedString *)template usingObject:(id)object delegate:(id <BDSKTemplateParserDelegate>)delegate {
    NSString *templateString = [template string];
    NSScanner *scanner = [[NSScanner alloc] initWithString:templateString];
    NSMutableAttributedString *result = [[NSMutableAttributedString alloc] init];

    [scanner setCharactersToBeSkipped:nil];
    
    while (![scanner isAtEnd]) {
        NSString *beforeText = nil;
        NSString *tag = nil;
        id keyValue = nil;
        int start;
        NSDictionary *attr = nil;
        NSAttributedString *tmpAttrStr = nil;
        
        start = [scanner scanLocation];
                
        if ([scanner scanUpToString:STARTTAG_OPEN_DELIM intoString:&beforeText])
            [result appendAttributedString:[template attributedSubstringFromRange:NSMakeRange(start, [beforeText length])]];
        
        if ([scanner scanString:STARTTAG_OPEN_DELIM intoString:nil]) {
            
            attr = [template attributesAtIndex:[scanner scanLocation] - 1 effectiveRange:NULL];
            start = [scanner scanLocation];
            
            // scan the key, must be letters and dots. We don't allow extra spaces
            // scanUpToCharactersFromSet is used for efficiency instead of scanCharactersFromSet
            [scanner scanUpToCharactersFromSet:invertedKeyCharacterSet intoString:&tag];

            if ([scanner scanString:SINGLETAG_CLOSE_DELIM intoString:nil]) {
                
                // simple template tag
                @try{ keyValue = [object valueForKeyPath:tag]; }
                @catch (id exception) { keyValue = nil; }
                if (keyValue != nil) {
                    if ([keyValue isKindOfClass:[NSAttributedString class]]) {
                        tmpAttrStr = [[NSAttributedString alloc] initWithAttributedString:keyValue attributes:attr];
                    } else {
                        tmpAttrStr = [[NSAttributedString alloc] initWithString:[keyValue stringDescription] attributes:attr];
                    }
                    [result appendAttributedString:tmpAttrStr];
                    [tmpAttrStr release];
                }
                
            } else if ([scanner scanString:MULTITAG_CLOSE_DELIM intoString:nil]) {
                
                NSString *itemTemplateString = nil;
                NSAttributedString *itemTemplate = nil, *lastItemTemplate = nil;
                NSString *endTag;
                NSRange sepTagRange, wsRange;
                
                // collection template tag
                // ignore whitespace before the tag. Should we also remove a newline?
                wsRange = [[result string] rangeOfTrailingEmptyLine];
                if (wsRange.location != NSNotFound)
                    [result deleteCharactersInRange:wsRange];
                
                endTag = endMultiTagWithTag(tag);
                // ignore the rest of an empty line after the tag
                [scanner scanEmptyLine];
                if ([scanner scanString:endTag intoString:nil])
                    continue;
                start = [scanner scanLocation];
                if ([scanner scanUpToString:endTag intoString:&itemTemplateString] && [scanner scanString:endTag intoString:nil]) {
                    // ignore whitespace before the tag. Should we also remove a newline?
                    wsRange = [itemTemplateString rangeOfTrailingEmptyLine];
                    itemTemplate = [template attributedSubstringFromRange:NSMakeRange(start, [itemTemplateString length] - wsRange.length)];
                    
                    sepTagRange = altTemplateTagRange([itemTemplate string], sepMultiTagWithTag(tag), nil, NULL);
                    if (sepTagRange.location != NSNotFound) {
                        lastItemTemplate = [itemTemplate attributedSubstringFromRange:NSMakeRange(0, sepTagRange.location)];
                        tmpAttrStr = [itemTemplate mutableCopy];
                        [(NSMutableAttributedString *)tmpAttrStr deleteCharactersInRange:sepTagRange];
                        itemTemplate = [tmpAttrStr autorelease];
                    } else {
                        lastItemTemplate = nil;
                    }
                    
                    @try{ keyValue = [object valueForKeyPath:tag]; }
                    @catch (id exception) { keyValue = nil; }
                    if ([keyValue respondsToSelector:@selector(objectEnumerator)]) {
                        NSEnumerator *itemE = [keyValue objectEnumerator];
                        id nextItem, item = [itemE nextObject];
                        while (item) {
                            nextItem = [itemE nextObject];
                            if (lastItemTemplate != nil && nextItem == nil)
                                itemTemplate = lastItemTemplate;
                            [delegate templateParserWillParseTemplate:itemTemplate usingObject:item isAttributed:YES];
                            tmpAttrStr = [self attributedStringByParsingTemplate:itemTemplate usingObject:item delegate:delegate];
                            [delegate templateParserDidParseTemplate:itemTemplate usingObject:item isAttributed:YES];
                            if (tmpAttrStr != nil)
                                [result appendAttributedString:tmpAttrStr];
                            item = nextItem;
                        }
                    }
                    // ignore the the rest of an empty line after the tag
                    [scanner scanEmptyLine];
                    
                }
                
            } else {
                
                NSString *matchString = nil;
                BOOL matchEqual = NO;
                BOOL matchContain = NO;
                
                if ([scanner scanString:CONDITIONTAG_EQUAL intoString:nil]) {
                    if([scanner scanUpToString:CONDITIONTAG_CLOSE_DELIM intoString:&matchString] == NO)
                        matchString = @"";
                    matchEqual = YES;
                } else if ([scanner scanString:CONDITIONTAG_CONTAIN intoString:nil]) {
                    if([scanner scanUpToString:CONDITIONTAG_CLOSE_DELIM intoString:&matchString] == NO)
                        matchString = @"";
                    matchContain = YES;
                }
                
                if ([scanner scanString:CONDITIONTAG_CLOSE_DELIM intoString:nil]) {
                    
                    NSMutableArray *subTemplates, *matchStrings;
                    NSString *subTemplateString = nil;
                    NSAttributedString *subTemplate = nil;
                    NSString *endTag, *altTag;
                    NSRange altTagRange, wsRange;
                    BOOL isMatch;
                    unsigned i, count;
                    
                    // condition template tag
                    // ignore whitespace before the tag. Should we also remove a newline?
                    wsRange = [[result string] rangeOfTrailingEmptyLine];
                    if (wsRange.location != NSNotFound)
                        [result deleteCharactersInRange:wsRange];
                    
                    endTag = endConditionTagWithTag(tag);
                    altTag = altConditionTagWithTag(tag);
                    // ignore the rest of an empty line after the tag
                    [scanner scanEmptyLine];
                    if ([scanner scanString:endTag intoString:nil])
                        continue;
                    start = [scanner scanLocation];
                    if ([scanner scanUpToString:endTag intoString:&subTemplateString] && [scanner scanString:endTag intoString:nil]) {
                        // ignore whitespace before the tag. Should we also remove a newline?
                        wsRange = [subTemplateString rangeOfTrailingEmptyLine];
                        subTemplate = [template attributedSubstringFromRange:NSMakeRange(start, [subTemplateString length] - wsRange.length)];
                        
                        subTemplates = [[NSMutableArray alloc] init];
                        matchStrings = [[NSMutableArray alloc] initWithObjects:matchString ? matchString : @"", nil];
                        
                        if (matchEqual || matchContain) {
                            altTag = matchEqual ? equalConditionTagWithTag(tag) : containConditionTagWithTag(tag);
                            altTagRange = altTemplateTagRange([subTemplate string], altTag, CONDITIONTAG_CLOSE_DELIM, &matchString);
                            while (altTagRange.location != NSNotFound) {
                                [subTemplates addObject:[subTemplate attributedSubstringFromRange:NSMakeRange(0, altTagRange.location)]];
                                [matchStrings addObject:matchString];
                                subTemplate = [subTemplate attributedSubstringFromRange:NSMakeRange(NSMaxRange(altTagRange), [subTemplate length] - NSMaxRange(altTagRange))];
                                altTagRange = altTemplateTagRange([subTemplate string], altTag, CONDITIONTAG_CLOSE_DELIM, &matchString);
                            }
                        }
                        
                        altTagRange = altTemplateTagRange([subTemplate string], altConditionTagWithTag(tag), nil, NULL);
                        if (altTagRange.location != NSNotFound) {
                            [subTemplates addObject:[subTemplate attributedSubstringFromRange:NSMakeRange(0, altTagRange.location)]];
                            subTemplate = [subTemplate attributedSubstringFromRange:NSMakeRange(NSMaxRange(altTagRange), [subTemplate length] - NSMaxRange(altTagRange))];
                        }
                        [subTemplates addObject:subTemplate];
                        
                        
                        @try{ keyValue = [object valueForKeyPath:tag]; }
                        @catch (id exception) { keyValue = nil; }
                        count = [matchStrings count];
                        subTemplate = nil;
                        for (i = 0; i < count; i++) {
                            isMatch = [keyValue isNotEmpty];
                            matchString = [matchStrings objectAtIndex:i];
                            if (matchEqual) {
                                isMatch = [matchString isEqualToString:@""] ? NO == isMatch : [[keyValue stringDescription] caseInsensitiveCompare:matchString] == NSOrderedSame;
                            } else if (matchContain) {
                                isMatch = [matchString isEqualToString:@""] ? NO == isMatch : [[keyValue stringDescription] rangeOfString:matchString options:NSCaseInsensitiveSearch].location != NSNotFound;
                            }
                            if (isMatch) {
                                subTemplate = [subTemplates objectAtIndex:i];
                                break;
                            }
                        }
                        if (subTemplate == nil && [subTemplates count] > count) {
                            subTemplate = [subTemplates objectAtIndex:count];
                        }
                        if (subTemplate != nil) {
                            tmpAttrStr = [self attributedStringByParsingTemplate:subTemplate usingObject:object delegate:delegate];
                            [result appendAttributedString:tmpAttrStr];
                        }
                        [subTemplates release];
                        [matchStrings release];
                        // ignore the the rest of an empty line after the tag
                        [scanner scanEmptyLine];
                        
                    }
                    
                } else {
                    
                    // a STARTTAG_OPEN_DELIM without MULTITAG_CLOSE_DELIM, so no template tag. Rewind
                    [result appendAttributedString:[template attributedSubstringFromRange:NSMakeRange(start - [STARTTAG_OPEN_DELIM length], [STARTTAG_OPEN_DELIM length])]];
                    [scanner setScanLocation:start];
                    
                }
            }
        } // scan STARTTAG_OPEN_DELIM
    } // while
    
    [result fixAttributesInRange:NSMakeRange(0, [result length])];
    [scanner release];
    
    return [result autorelease];    
}

@end


@implementation NSObject (BDSKTemplateParser)

- (NSString *)stringDescription {
    NSString *description = nil;
    if ([self respondsToSelector:@selector(stringValue)])
        description = [self performSelector:@selector(stringValue)];
    return description ? description : [self description];
}

- (BOOL)isNotEmpty {
    return YES;
}

@end


@implementation NSScanner (BDSKTemplateParser)

- (BOOL)scanEmptyLine {
    BOOL foundNewline = NO;
    BOOL foundWhitespace = NO;
    int startLoc = [self scanLocation];
    
    // [self scanCharactersFromSet:[NSCharacterSet whitespaceCharacterSet] intoString:nil] is much more sensible, but NSScanner creates an autoreleased inverted character set every time you use it, so it's pretty inefficient
    foundWhitespace = [self scanUpToCharactersFromSet:[NSCharacterSet nonWhitespaceCharacterSet] intoString:nil];

    if ([self isAtEnd] == NO) {
        foundNewline = [self scanString:@"\r\n" intoString:nil];
        if (foundNewline == NO) {
            unichar nextChar = [[self string] characterAtIndex:[self scanLocation]];
            if (foundNewline = [[NSCharacterSet newlineCharacterSet] characterIsMember:nextChar])
                [self setScanLocation:[self scanLocation] + 1];
        }
    }
    if (foundNewline == NO && foundWhitespace == YES)
        [self setScanLocation:startLoc];
    return foundNewline;
}

@end


@implementation NSString (BDSKTemplateParser)

- (NSString *)stringDescription
{
    return self;
}

- (NSString *)stringBySurroundingWithSpacesIfNotEmpty 
{ 
    return [self isEqualToString:@""] ? self : [NSString stringWithFormat:@" %@ ", self];
}

- (NSString *)stringByAppendingSpaceIfNotEmpty
{
    return [self isEqualToString:@""] ? self : [self stringByAppendingString:@" "];
}

- (NSString *)stringByAppendingDoubleSpaceIfNotEmpty
{
    return [self isEqualToString:@""] ? self : [self stringByAppendingString:@"  "];
}

- (NSString *)stringByPrependingSpaceIfNotEmpty
{
    return [self isEqualToString:@""] ? self : [NSString stringWithFormat:@" %@", self];
}

- (NSString *)stringByAppendingCommaIfNotEmpty
{
    return [self isEqualToString:@""] ? self : [self stringByAppendingString:@","];
}

- (NSString *)stringByAppendingFullStopIfNotEmpty
{
    return [self isEqualToString:@""] ? self : [self stringByAppendingString:@"."];
}

- (NSString *)stringByAppendingCommaAndSpaceIfNotEmpty
{
    return [self isEqualToString:@""] ? self : [self stringByAppendingString:@", "];
}

- (NSString *)stringByAppendingFullStopAndSpaceIfNotEmpty
{
    return [self isEqualToString:@""] ? self : [self stringByAppendingString:@". "];
}

- (NSString *)stringByPrependingCommaAndSpaceIfNotEmpty
{
    return [self isEqualToString:@""] ? self : [NSString stringWithFormat:@", %@", self];
}

- (NSString *)stringByPrependingFullStopAndSpaceIfNotEmpty
{
    return [self isEqualToString:@""] ? self : [NSString stringWithFormat:@". %@", self];
}

- (NSString *)parenthesizedStringIfNotEmpty
{
    return [self isEqualToString:@""] ? self : [NSString stringWithFormat:@"(%@)", self];
}

- (BOOL)isNotEmpty
{
    return [self isEqualToString:@""] == NO;
}

@end


@implementation NSAttributedString (BDSKTemplateParser)

- (NSString *)stringDescription {
    return [self string];
}

- (BOOL)isNotEmpty
{
    return [self length] > 0;
}

@end

@implementation NSNumber (BDSKTemplateParser)

- (BOOL)isNotEmpty
{
    return [self isEqualToNumber:[NSNumber numberWithBool:NO]] == NO;
}

@end


@implementation NSArray (BDSKTemplateParser)

- (NSString *)componentsJoinedByAnd
{
    return [self componentsJoinedByString:@" and "];
}

- (BOOL)isNotEmpty
{
    return [self count] > 0;
}

@end


@implementation NSDictionary (BDSKTemplateParser)

- (BOOL)isNotEmpty
{
    return [self count] > 0;
}

@end


@implementation NSSet (BDSKTemplateParser)

- (BOOL)isNotEmpty
{
    return [self count] > 0;
}

@end


@implementation BibAuthor (BDSKTemplateParser)

- (BOOL)isNotEmpty
{
    return [BibAuthor emptyAuthor] != self;
}

@end
