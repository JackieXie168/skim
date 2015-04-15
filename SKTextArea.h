//
//  SKTextArea.h
//  SkimMobile
//
//  Created by Sylvain Bouchard on 13-06-15.
//  Copyright (c) 2013 Sylvain Bouchard. All rights reserved.
//

#import <Foundation/Foundation.h>

#define UNKNOWN     "unknown"
#define PAGE        "page"
#define COLUMN      "column"
#define REGION      "region"
#define PARAGRAPH   "paragraph"
#define LINE        "line"
#define WORD        "word"
#define CHARACTER   "character"

typedef NS_ENUM(NSInteger, TextAreaType)
{
    TextAreaUnknown,
    TextAreaPage,
    TextAreaColumn,
    TextAreaRegion,
    TextAreaParagraph,
    TextAreaLine,
    TextAreaWord,
    TextAreaCharacter
};

@interface SKTextArea : NSObject

@property (assign, nonatomic) TextAreaType type;
@property (assign, nonatomic) CGRect boundingRect;
@property (strong, nonatomic) NSString* textContent;

- (void)apply2DScalingOf:(CGSize)scale;
+ (NSString*)toStringFromType:(TextAreaType)areaType;
+ (TextAreaType)toAreaTypeFromCString:(const char*)typeUTFString;
+ (TextAreaType)toAreaTypeFromNSString:(NSString*)typeString;

@end