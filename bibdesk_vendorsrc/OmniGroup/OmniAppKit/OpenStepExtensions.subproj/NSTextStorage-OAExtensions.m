// Copyright 2002-2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.

#import "NSTextStorage-OAExtensions.h"

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <OmniBase/OmniBase.h>
#import <OmniFoundation/OmniFoundation.h>
#import "OAFindPattern.h"
#import "OARegExFindPattern.h"

RCS_ID("$Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniAppKit/OpenStepExtensions.subproj/NSTextStorage-OAExtensions.m,v 1.5 2003/04/15 05:46:01 toon Exp $")

@implementation NSTextStorage (OAExtensions)

+ (void)load;
{
    NSScriptCoercionHandler *handler;

    handler = [NSScriptCoercionHandler sharedCoercionHandler];
    [handler registerCoercer:self selector:@selector(coerceList:toClass:) toConvertFromClass:[NSArray class] toClass:self];
    [self registerConversionFromRecord];
}

//
// A hack to make sure we get the Extended Text Suite instead of the original Text Suite from AppKit.
//
- (NSClassDescription *)classDescription;
{
    NSScriptSuiteRegistry *registry;
    
    registry = [NSScriptSuiteRegistry sharedScriptSuiteRegistry];
    return [[registry classDescriptionsInSuite:@"ExtendedText"] objectForKey:@"NSTextStorage"];
}

- (BOOL)isUnderlined;
{
    id value;
    
    if (![self length])
        return NO;
    value = [self attribute:NSUnderlineStyleAttributeName atIndex:0 effectiveRange:NULL];
    return [value intValue] == NSSingleUnderlineStyle;
}

- (void)setIsUnderlined:(BOOL)value;
{
    NSNumber *number;
    
    number = [NSNumber numberWithInt:(value ? NSSingleUnderlineStyle : 0)];
    [self beginEditing];
    [self addAttribute:NSUnderlineStyleAttributeName value:number range:NSMakeRange(0, [self length])];
    [self endEditing];
}

- (NSNumber *)superscriptLevel;
{
    if (![self length])
        return [NSNumber numberWithInt:0];
    return [self attribute:NSSuperscriptAttributeName atIndex:0 effectiveRange:NULL];
}

- (void)setSuperscriptLevel:(NSNumber *)value;
{
    [self beginEditing];
    [self addAttribute:NSSuperscriptAttributeName value:value range:NSMakeRange(0, [self length])];
    [self endEditing];
}

- (NSNumber *)baselineOffset;
{
    if (![self length])
        return [NSNumber numberWithFloat:0.0];
    return [self attribute:NSBaselineOffsetAttributeName atIndex:0 effectiveRange:NULL];
}

- (void)setBaselineOffset:(NSNumber *)value;
{
    [self beginEditing];
    [self addAttribute:NSBaselineOffsetAttributeName value:value range:NSMakeRange(0, [self length])];
    [self endEditing];
}

- (int)textAlignment;
{
    NSParagraphStyle *paragraphStyle;
    
    if (![self length])
        return 'OTa0'; // left
    paragraphStyle = [self attribute:NSParagraphStyleAttributeName atIndex:0 effectiveRange:NULL];
    switch([paragraphStyle alignment]) {
        case NSLeftTextAlignment: return 'OTa0';
        case NSCenterTextAlignment: return 'OTa1';
        case NSRightTextAlignment: return 'OTa2';
        case NSJustifiedTextAlignment: return 'OTa3';
        case NSNaturalTextAlignment:
        default:
            return 'OTa0'; // assume natural is left aligned
    }
}

- (void)setTextAlignment:(int)value;
{
    int newAlignment;
    NSParagraphStyle *paragraphStyle;
    NSMutableParagraphStyle *mutable;
    
    if (![self length])
        return;
    
    switch(value - 'OTa0') {
        case 0: 
            newAlignment = NSLeftTextAlignment;
            break;
        case 1:
            newAlignment = NSCenterTextAlignment;
            break;
        case 2:
            newAlignment = NSRightTextAlignment;
            break;
        case 3:
            newAlignment = NSJustifiedTextAlignment;
            break;
        default:
            newAlignment = NSLeftTextAlignment;
            break;
    }
    paragraphStyle = [self attribute:NSParagraphStyleAttributeName atIndex:0 effectiveRange:NULL];
    if (!paragraphStyle) 
        paragraphStyle = [NSParagraphStyle defaultParagraphStyle];
    mutable = [paragraphStyle mutableCopy];
    [mutable setAlignment:newAlignment];
    
    [self beginEditing];
    [self addAttribute:NSParagraphStyleAttributeName value:mutable range:NSMakeRange(0, [self length])];
    [self endEditing];

    [mutable release];
}

- (NSString *)text;
{
    return [self string];
}

- (void)setText:(NSString *)someText;
{
    [self beginEditing];
    [self replaceCharactersInRange:NSMakeRange(0, [self length]) withString:someText];
    [self endEditing];
}

- (void)_convertToHaveTrait:(NSFontTraitMask)trait;
{
    NSFontManager *manager;
    NSFont *font;
    NSRange range;
    int position, length;
    
    position = 0;
    length = [self length];
    manager = [NSFontManager sharedFontManager];
    
    [self beginEditing];
    while (position < length) {
        font = [self attribute:NSFontAttributeName atIndex:position effectiveRange:&range];
        font = [manager convertFont:font toHaveTrait:trait];
        [self addAttribute:NSFontAttributeName value:font range:range];
        position = NSMaxRange(range);
    }
    [self endEditing];
}

- (void)handleBoldScriptCommand:(NSScriptCommand *)command;
{
    [self _convertToHaveTrait:NSBoldFontMask];
}

- (void)handleItalicizeScriptCommand:(NSScriptCommand *)command;
{
    [self _convertToHaveTrait:NSItalicFontMask];
}

- (void)handleUnboldScriptCommand:(NSScriptCommand *)command;
{
    [self _convertToHaveTrait:NSUnboldFontMask];
}

- (void)handleUnitalicizeScriptCommand:(NSScriptCommand *)command;
{
    [self _convertToHaveTrait:NSUnitalicFontMask];
}

- (void)handleUnderlineScriptCommand:(NSScriptCommand *)command;
{
    [self setIsUnderlined:YES];
}

- (void)handleUnunderlineScriptCommand:(NSScriptCommand *)command;
{
    [self setIsUnderlined:NO];
}

- (void)handleReplaceScriptCommand:(NSScriptCommand *)command;
{
    NSString *string, *replacement;
    NSRange searchRange;
    NSRange range;
    NSDictionary *args;
    NSObject <OAFindPattern>*pattern;
    
    args = [command evaluatedArguments];
    replacement = [args objectForKey:@"replacement"];
    if (!replacement)
        return;
        
    if ((string = [args objectForKey:@"string"])) {
        pattern = [[OAFindPattern alloc] initWithString:string ignoreCase:NO wholeWord:NO backwards:NO];
    } else if ((string = [args objectForKey:@"regexp"])) {
        pattern = [[OARegExFindPattern alloc] initWithString:string selectedSubexpression:SELECT_FULL_EXPRESSION backwards:NO];
    } else	
        return;
    [pattern setReplacementString:replacement];
    
    [self beginEditing];
    string = [self string];
    searchRange = NSMakeRange(0, [string length]);
    while (searchRange.length != 0) {
        if (![pattern findInRange:searchRange ofString:string foundRange:&range])
            break;

        replacement = [pattern replacementStringForLastFind];
        [self replaceCharactersInRange:range withString:replacement];
        searchRange.location = range.location + [replacement length];
        searchRange.length = [string length] - searchRange.location;
    }
    [self endEditing];
    [pattern release];
}

+ (id)coerceRecord:(NSDictionary *)dictionary toClass:(Class)aClass
{
    id result = [[NSTextStorage alloc] init];

    [result setText:@" "]; // so there will be something to apply traits to
    [result appleScriptTakeAttributesFromRecord:dictionary];
    return result;
}

+ (id)coerceList:(NSArray *)array toClass:(Class)aClass;
{
    NSTextStorage *result = [[NSTextStorage alloc] init];
    NSScriptCoercionHandler *coercer = [NSScriptCoercionHandler sharedCoercionHandler];
    int index, count;
    
    count = [array count];
    
    [result beginEditing];
    for (index = 0; index < count; index++)
        [result appendAttributedString:[coercer coerceValue:[array objectAtIndex:index] toClass:self]];
    [result endEditing];
    
    return result;
}

- (id)appleScriptBlankInit;
{
    [self init];
    [self setText:@" "]; // so there will be something to apply traits to
    return self;
}

- (NSString *)appleScriptMakeProperties;
{
    NSArray *parts;

    parts = [self attributeRuns];
    if ([parts count] == 1)
        return [super appleScriptMakeProperties];
    else {
        NSMutableString *result = [NSMutableString stringWithString:@"{"];
        BOOL useComma = NO;
        int index, count;
        
        count = [parts count];
        for (index = 0; index < count; index++) {
            if (useComma)
                [result appendString:@", "];
            else
                useComma = YES;
            [result appendString:[[parts objectAtIndex:index] appleScriptMakeProperties]];
        }
        [result appendString:@"}"];
        return result;
    }
}

@end
