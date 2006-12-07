//
//  BDSKFontManager.m
//  BibDesk
//
//  Created by Adam Maxwell on 02/25/05.
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

#import "BDSKFontManager.h"
#import <OmniFoundation/OFPreference.h>

@implementation NSFontManager (BDSKExtensions)

static NSDictionary *cachedFontsForPreviewPane = nil;

+ (void)didLoad
{
    @try{
    OMNI_POOL_START {
        [OFPreference addObserver:self selector:@selector(setupFonts) forPreference:[OFPreference preferenceForKey:BDSKPreviewPaneFontFamilyKey]];
        [self setupFonts];
    } OMNI_POOL_END;
    }
    @catch(id exception){
        NSLog(@"caught exception %@", exception);
    }
}

+ (float)previewFontBaseSize;
{
    float defaultSize = [[OFPreferenceWrapper sharedPreferenceWrapper] floatForKey:BDSKPreviewBaseFontSizeKey];
    return (defaultSize <= 0.1 ? [NSFont systemFontSize] : defaultSize);
}

+ (NSFont *)titleFontForFamily:(NSString *)tryFamily;
{
    float size = [self previewFontBaseSize];
    size += 2;
    
    NSFont *font = [NSFont fontWithName:[tryFamily stringByAppendingString:@" Bold Italic"] size:size];
    if(!font){
        font = [NSFont fontWithName:[tryFamily stringByAppendingString:@" Bold Oblique"] size:size];
        if(!font){
            font = [NSFont fontWithName:[tryFamily stringByAppendingString:@" Bold"] size:size];
            if(!font){
                font = [NSFont fontWithName:[tryFamily stringByAppendingString:@" Black Italic"] size:size];
                if(!font){
                    font = [[NSFontManager sharedFontManager] convertFont:[NSFont fontWithName:tryFamily size:size] toHaveTrait:(NSBoldFontMask | NSItalicFontMask)];
                    if(!font){
                        font = [NSFont boldSystemFontOfSize:size];
                    }
                }
            }
        }
    }
    return font;
}

+ (NSFont *)typeFontForFamily:(NSString *)tryFamily;
{
    float size = [self previewFontBaseSize];
    size -= 2;
    
    NSFont *font = [NSFont fontWithName:tryFamily size:size];
    if(!font){
        font = [NSFont systemFontOfSize:size];
    }
    return font;
}    

+ (NSFont *)keyFontForFamily:(NSString *)tryFamily;
{
    float size = [self previewFontBaseSize];
    
    NSFont *font = [NSFont fontWithName:[tryFamily stringByAppendingString:@" Bold"] size:size];
    if(!font){
        font = [NSFont fontWithName:[tryFamily stringByAppendingString:@" Black"] size:size];
        if(!font){
            font = [[NSFontManager sharedFontManager] convertFont:[NSFont fontWithName:tryFamily size:size] toHaveTrait:NSBoldFontMask];
            if(!font){
                font = [NSFont boldSystemFontOfSize:size];
            }
        }
    }
    return font;
}

+ (NSFont *)bodyFontForFamily:(NSString *)tryFamily;
{
    float size = [self previewFontBaseSize];

    NSFont *font = [NSFont fontWithName:tryFamily size:size];
    if(!font){
        font = [NSFont systemFontOfSize:size];
    }
    return font;
}

+ (void)setupFonts{
    NSString *fontFamily = [[OFPreferenceWrapper sharedPreferenceWrapper] objectForKey:BDSKPreviewPaneFontFamilyKey];
    [cachedFontsForPreviewPane release];
    cachedFontsForPreviewPane = [[NSDictionary alloc] initWithObjectsAndKeys:
        [self titleFontForFamily:fontFamily], @"Title",
        [self typeFontForFamily:fontFamily], @"Type",
        [self keyFontForFamily:fontFamily], @"Key",
        [self bodyFontForFamily:fontFamily], @"Body",nil];
}

- (NSDictionary *)cachedFontsForPreviewPane{
    return cachedFontsForPreviewPane;
}

- (NSFontTraitMask)fontTraitMaskForTeXStyle:(NSString *)style{
    if([style isEqualToString:@"\\textit"])
        return NSItalicFontMask;
    else if([style isEqualToString:@"\\textbf"])
        return NSBoldFontMask;
    else if([style isEqualToString:@"\\textsc"])
        return NSSmallCapsFontMask;
    else if([style isEqualToString:@"\\emph"])
        return NSItalicFontMask;
    else if([style isEqualToString:@"\\textup"])
        return NSUnitalicFontMask;
    else return 0;
}
@end
