//
//  SKViewSettingsController.m
//  Skim
//
//  Created by Christiaan Hofman on 13/11/2020.
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

#import "SKViewSettingsController.h"

#define kPDFDisplaySinglePageContinuous 1
#define kPDFDisplayHorizontalContinuous 4

@implementation SKViewSettingsController

@synthesize customButton, custom, autoScales, scaleFactor, displayMode, displayDirection, displaysAsBook, displaysRTL, displaysPageBreaks, displayBox;
@dynamic extendedDisplayMode, allowsHorizontalSettings, settings;

+ (NSSet *)keyPathsForValuesAffectingValueForKey:(NSString *)key {
    NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];
    if ([key isEqualToString:@"extendedDisplayMode"])
        keyPaths = [keyPaths setByAddingObjectsFromSet:[NSSet setWithObjects:@"displayMode", @"displayDirection", nil]];
    return keyPaths;
}

- (NSArray *)persistentKeys {
    return [NSArray arrayWithObjects:@"autoScales", @"scaleFactor", @"displayMode", @"displayDirection", @"displaysAsBook", @"displaysRTL", @"displaysPageBreaks", @"displayBox", nil];
}

- (id)initWithSettings:(NSDictionary *)settings defaultSettings:(NSDictionary *)aDefaultSettings {
    self = [super init];
    if (self) {
        defaultSettings = [aDefaultSettings copy];
        if (defaultSettings == nil || [settings count]) {
            custom = YES;
        } else {
            custom = NO;
            settings = defaultSettings;
        }
        [self setSettings:settings];
    }
    return self;
}

- (void)dealloc {
    SKDESTROY(defaultSettings);
    SKDESTROY(customButton);
    [super dealloc];
}

- (NSString *)windowNibName {
    return @"ViewSettings";
}

- (void)windowDidLoad {
    [super windowDidLoad];
    if (defaultSettings == nil) {
        [customButton removeFromSuperview];
        [customButton unbind:NSValueBinding];
        SKDESTROY(customButton);
    }
}

- (NSInteger)extendedDisplayMode {
    NSInteger mode = [self displayMode];
    if (mode == kPDFDisplaySinglePageContinuous && [self displayDirection] == 1)
        return kPDFDisplayHorizontalContinuous;
    return mode;
}

- (void)setExtendedDisplayMode:(NSInteger)mode {
    if (mode != [self extendedDisplayMode]) {
        if (mode == kPDFDisplayHorizontalContinuous) {
            [self setDisplayMode:kPDFDisplaySinglePageContinuous];
            [self setDisplayDirection:1];
        } else {
            [self setDisplayMode:mode];
            [self setDisplayDirection:0];
        }
    }
}

- (void)setCustom:(BOOL)flag {
    if (custom != flag) {
        custom = flag;
        if (custom == NO && defaultSettings)
            [self setSettings:defaultSettings];
    }
}

- (void)setAutoScales:(BOOL)flag {
    if (autoScales != flag) {
        autoScales = flag;
        if (autoScales)
            [self setScaleFactor:1.0];
    }
}

- (BOOL)allowsHorizontalSettings {
    return RUNNING_AFTER(10_12);
}

- (NSDictionary *)settings {
    if (custom == NO)
        return [NSDictionary dictionary];
    return [self dictionaryWithValuesForKeys:[self persistentKeys]];
}

- (void)setSettings:(NSDictionary *)settings {
    for (NSString *key in [self persistentKeys]) {
        id value = [settings objectForKey:key];
        if (value)
            [self setValue:value forKey:key];
    }
}

@end
