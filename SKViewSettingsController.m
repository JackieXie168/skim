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
#import "SKStringConstants.h"
#import "NSWindowController_SKExtensions.h"

#define kPDFDisplaySinglePageContinuous 1
#define kPDFDisplayHorizontalContinuous 4

@implementation SKViewSettingsController

@synthesize customButton, custom, autoScales, scaleFactor, displayMode, displayDirection, displaysAsBook, displaysRTL, displaysPageBreaks, displayBox;
@dynamic extendedDisplayMode, allowsHorizontalSettings;

+ (NSSet *)keyPathsForValuesAffectingValueForKey:(NSString *)key {
    NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];
    if ([key isEqualToString:@"extendedDisplayMode"])
        keyPaths = [keyPaths setByAddingObjectsFromSet:[NSSet setWithObjects:@"displayMode", @"displayDirection", nil]];
    return keyPaths;

}

- (NSArray *)persistentKeys {
    return [NSArray arrayWithObjects:@"autoScales", @"scaleFactor", @"displayMode", @"displayDirection", @"displaysAsBook", @"displaysRTL", @"displaysPageBreaks", @"displayBox", nil];
}

- (void)setValuesFromDictionary:(NSDictionary *)settings {
    for (NSString *key in [self persistentKeys]) {
        id value = [settings objectForKey:key];
        if (value)
            [self setValue:value forKey:key];
    }
}

- (id)initForFullScreen:(BOOL)isFullScreen {
    self = [super init];
    if (self) {
        fullScreen = isFullScreen;
        
        NSString *key = fullScreen ? SKDefaultFullScreenPDFDisplaySettingsKey : SKDefaultPDFDisplaySettingsKey;
        NSDictionary *settings = [[NSUserDefaults standardUserDefaults] dictionaryForKey:key];
        if (fullScreen == NO || [settings count]) {
            custom = YES;
        } else {
            custom = NO;
            settings = [[NSUserDefaults standardUserDefaults] dictionaryForKey:SKDefaultPDFDisplaySettingsKey];
        }
        [self setValuesFromDictionary:settings];
    }
    return self;
}

- (void)dealloc {
    SKDESTROY(customButton);
    [super dealloc];
}

- (NSString *)windowNibName {
    return @"ViewSettings";
}

- (void)windowDidLoad {
    [super windowDidLoad];
    if (fullScreen == NO)
        [customButton removeFromSuperview];
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
        if (custom == NO && fullScreen)
            [self setValuesFromDictionary:[[NSUserDefaults standardUserDefaults] dictionaryForKey:SKDefaultPDFDisplaySettingsKey]];
    }
}

- (BOOL)allowsHorizontalSettings {
    return RUNNING_AFTER(10_12);
}

- (IBAction)dismissSheet:(id)sender {
    if ([sender tag] == NSOKButton) {
        NSString *key = fullScreen ? SKDefaultFullScreenPDFDisplaySettingsKey : SKDefaultPDFDisplaySettingsKey;
        if (custom) {
            NSDictionary *settings = [self dictionaryWithValuesForKeys:[self persistentKeys]];
            [[NSUserDefaults standardUserDefaults] setObject:settings forKey:key];
        } else {
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:key];
        }
    }
    [super dismissSheet:sender];
}

@end
