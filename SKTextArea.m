//
//  SKTextArea.m
//  SkimMobile
//
//  Created by Sylvain Bouchard on 13-06-15.
//  Copyright (c) 2013 Sylvain Bouchard. All rights reserved.
//

#import "SKTextArea.h"

@implementation SKTextArea

@synthesize type = _type;
@synthesize boundingRect = _boundingRect;
@synthesize textContent = _textContent;

- (void)apply2DScalingOf:(CGSize)scale
{
    _boundingRect.origin.x *= scale.width;
    _boundingRect.origin.y *= scale.height;
    _boundingRect.size.width *= scale.width;
    _boundingRect.size.height *= scale.height;
}

- (NSString*)description
{
    NSString* descriptionString = [NSString stringWithFormat:@"Type: %@\nBounding rect: (%f,%f,%f,%f)\nText: %@",
                                   [SKTextArea toStringFromType:self.type],
                                   self.boundingRect.origin.x, self.boundingRect.origin.y,
                                   self.boundingRect.size.width, self.boundingRect.size.height,
                                   self.textContent];
    return descriptionString;
}

+ (NSString *)toStringFromType:(TextAreaType)areaType
{
    switch(areaType)
    {
        case TextAreaUnknown: return @UNKNOWN;
        case TextAreaPage: return @PAGE;
        case TextAreaColumn: return @COLUMN;
        case TextAreaRegion: return @REGION;
        case TextAreaParagraph: return @PARAGRAPH;
        case TextAreaLine: return @LINE;
        case TextAreaWord: return @WORD;
        case TextAreaCharacter: return @CHARACTER;
    }
    return @UNKNOWN;
}

+ (TextAreaType)toAreaTypeFromCString:(const char *)typeUTFString
{
    NSString* str = [NSString stringWithCString:typeUTFString encoding:NSUTF8StringEncoding];
    return [self toAreaTypeFromNSString:str];
}

+ (TextAreaType)toAreaTypeFromNSString:(NSString*)typeString
{
    if([typeString isEqualToString:@PAGE])
        return TextAreaPage;
    if([typeString isEqualToString:@COLUMN])
        return TextAreaColumn;
    if([typeString isEqualToString:@REGION])
        return TextAreaRegion;
    if([typeString isEqualToString:@PARAGRAPH])
        return TextAreaParagraph;
    if([typeString isEqualToString:@LINE])
        return TextAreaLine;
    if([typeString isEqualToString:@WORD])
        return TextAreaWord;
    if([typeString isEqualToString:@CHARACTER])
        return TextAreaCharacter;
    
    return TextAreaUnknown;
}

@end