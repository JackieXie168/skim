//
//  BDSKFontManager.m
//  Bibdesk
//
//  Created by Adam Maxwell on 02/25/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "BDSKFontManager.h"

static BDSKFontManager *sharedFontManager = nil;

@implementation BDSKFontManager

+ (BDSKFontManager *)sharedFontManager{
    if(!sharedFontManager){
        sharedFontManager = [[BDSKFontManager alloc] init];
    }
    return sharedFontManager;
}

- (id)init{
    if(self = [super init]){
        cachedFontsForPreviewPane = nil;
        [self setupFonts];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(setupFonts) 
                                                     name:BDSKPreviewPaneFontChangedNotification
                                                   object:nil];
    }
   return self;
}

- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [cachedFontsForPreviewPane release];
    [super dealloc];
}

NSFont *titleFontForFamily(NSString *tryFamily)
{
    NSFont *font = [NSFont fontWithName:[tryFamily stringByAppendingString:@" Bold Italic"] size:14.0];
    if(!font){
        font = [NSFont fontWithName:[tryFamily stringByAppendingString:@" Bold Oblique"] size:14.0];
        if(!font){
            font = [NSFont fontWithName:[tryFamily stringByAppendingString:@" Bold"] size:14.0];
            if(!font){
                font = [NSFont fontWithName:[tryFamily stringByAppendingString:@" Black Italic"] size:14.0];
                if(!font){
                    font = [NSFont boldSystemFontOfSize:14.0];
                }
            }
        }
    }
    return font;
}

NSFont *typeFontForFamily(NSString *tryFamily)
{
    NSFont *font = [NSFont fontWithName:tryFamily size:10.0];
    if(!font){
        font = [NSFont systemFontOfSize:10.0];
    }
    return font;
}    

NSFont *keyFontForFamily(NSString *tryFamily)
{
    NSFont *font = [NSFont fontWithName:[tryFamily stringByAppendingString:@" Bold"] size:12.0];
    if(!font){
        [NSFont fontWithName:[tryFamily stringByAppendingString:@" Black"] size:12.0];
        if(!font){
            font = [NSFont boldSystemFontOfSize:12.0];
        }
    }
    return font;
}

NSFont *bodyFontForFamily(NSString *tryFamily)
{
    NSFont *font = [NSFont fontWithName:tryFamily size:12.0];
    if(!font){
        font = [NSFont systemFontOfSize:12.0];
    }
    return font;
}

- (void)setupFonts{
    NSString *fontFamily = [[OFPreferenceWrapper sharedPreferenceWrapper] objectForKey:BDSKPreviewPaneFontFamily];
    [cachedFontsForPreviewPane release];
    cachedFontsForPreviewPane = [[NSDictionary dictionaryWithObjectsAndKeys:
        titleFontForFamily(fontFamily), @"Title",
        typeFontForFamily(fontFamily), @"Type",
        keyFontForFamily(fontFamily), @"Key",
        bodyFontForFamily(fontFamily), @"Body",
        nil] retain];
}

- (NSDictionary *)cachedFontsForPreviewPane{
    return cachedFontsForPreviewPane;
}

@end
