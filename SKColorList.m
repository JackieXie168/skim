//
//  SKColorList.m
//  Skim
//
//  Created by Christiaan Hofman on 30/09/2020.
/*
This software is Copyright (c) 2020
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

#import "SKColorList.h"
#import "SKStringConstants.h"
#import "NSUserDefaultsController_SKExtensions.h"
#import "NSColor_SKExtensions.h"

static char SKDefaultsObservationContext;

@implementation SKColorList

@synthesize editable;

+ (NSColorList *)favoriteColorList {
    static SKColorList *colorList = nil;
    if (colorList == nil) {
        NSString *appName = [[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString *)kCFBundleNameKey];
        colorList = [[SKColorList alloc] initWithName:appName];
        [(SKColorList *)colorList setEditable:YES];
        NSInteger i = 0;
        for (NSColor *color in [NSColor favoriteColors]) {
            NSString *key = [NSLocalizedString(@"Favorite Color", @"Color name") stringByAppendingFormat:@" %ld", ++i];
            [colorList setColor:color forKey:key];
        }
        [(SKColorList *)colorList setEditable:NO];
        [[NSUserDefaultsController sharedUserDefaultsController] addObserver:colorList forKey:SKSwatchColorsKey context:&SKDefaultsObservationContext];
    }
    return colorList;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (context == &SKDefaultsObservationContext) {
        [self setEditable:YES];
        for (NSString *key in [[[self allKeys] copy] autorelease])
            [self removeColorWithKey:key];
        NSInteger i = 0;
        for (NSColor *color in [NSColor favoriteColors]) {
            NSString *key = [NSLocalizedString(@"Favorite Color", @"Color name") stringByAppendingFormat:@" %ld", ++i];
            [self setColor:color forKey:key];
        }
        [self setEditable:NO];
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

@end
