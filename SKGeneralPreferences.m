//
//  SKGeneralPreferences.m
//  Skim
//
//  Created by Christiaan on 3/14/10.
/*
 This software is Copyright (c) 2010
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

#import "SKGeneralPreferences.h"
#import "SKPreferenceController.h"
#import "SKStringConstants.h"
#import "NSUserDefaultsController_SKExtensions.h"
#import <Sparkle/Sparkle.h>
#import "NSGeometry_SKExtensions.h"

#define UPDATEINTERVAL_KEY @"updateInterval"

static char SKGeneralPreferencesDefaultsObservationContext;
static char SKGeneralPreferencesUpdaterObservationContext;

@interface SKGeneralPreferences (Private)
- (void)synchronizeUpdateInterval;
- (void)updateRevertButtons;
@end

@implementation SKGeneralPreferences

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        [[NSUserDefaultsController sharedUserDefaultsController] addObserver:self forKeys:[NSArray arrayWithObjects:SKDefaultPDFDisplaySettingsKey, SKDefaultFullScreenPDFDisplaySettingsKey, nil] context:&SKGeneralPreferencesDefaultsObservationContext];
        [[SUUpdater sharedUpdater] addObserver:self forKeyPath:@"automaticallyChecksForUpdates" options:0 context:&SKGeneralPreferencesUpdaterObservationContext];
        [[SUUpdater sharedUpdater] addObserver:self forKeyPath:@"updateCheckInterval" options:0 context:&SKGeneralPreferencesUpdaterObservationContext];
    }
    return self;
}

- (void)dealloc {
    [[NSUserDefaultsController sharedUserDefaultsController] removeObserver:self forKeys:[NSArray arrayWithObjects:SKDefaultPDFDisplaySettingsKey, SKDefaultFullScreenPDFDisplaySettingsKey, nil]];
    [[SUUpdater sharedUpdater] removeObserver:self forKeyPath:@"automaticallyChecksForUpdates"];
    [[SUUpdater sharedUpdater] removeObserver:self forKeyPath:@"updateCheckInterval"];
    [super dealloc];
}

- (NSString *)nibName {
    return @"GeneralPreferences";
}

- (void)loadView {
    [super loadView];
    
    SKAutoSizeLeftButtons(revertPDFSettingsButton, revertFullScreenPDFSettingsButton);
    SKAutoSizeLabelFields([NSArray arrayWithObjects:openFilesLabelField, nil], [NSArray arrayWithObjects:openFilesMatrix, nil], NO);
    SKAutoSizeLabelFields([NSArray arrayWithObjects:updateIntervalLabelField, nil], [NSArray arrayWithObjects:updateIntervalPopUpButton, nil], NO);
    [openFilesMatrix sizeToFit];
    [savePasswordsMatrix sizeToFit];
    
    [self synchronizeUpdateInterval];
}

#pragma mark Accessors

- (NSInteger)updateInterval {
    return updateInterval;
}

- (void)setUpdateInterval:(NSInteger)interval {
    if (interval > 0)
        [[SUUpdater sharedUpdater] setUpdateCheckInterval:interval];
    [[SUUpdater sharedUpdater] setAutomaticallyChecksForUpdates:interval > 0];
}

#pragma mark Actions

- (IBAction)revertPDFViewSettings:(id)sender {
    [[NSUserDefaultsController sharedUserDefaultsController] revertToInitialValueForKey:SKDefaultPDFDisplaySettingsKey];
}

- (IBAction)revertFullScreenPDFViewSettings:(id)sender {
    [[NSUserDefaultsController sharedUserDefaultsController] revertToInitialValueForKey:SKDefaultFullScreenPDFDisplaySettingsKey];
}

#pragma mark KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (context == &SKGeneralPreferencesDefaultsObservationContext) {
        NSString *key = [keyPath substringFromIndex:7];
        if ([key isEqualToString:SKDefaultPDFDisplaySettingsKey] || [key isEqualToString:SKDefaultFullScreenPDFDisplaySettingsKey]) {
            [self updateRevertButtons];
        }
    } else if (context == &SKGeneralPreferencesUpdaterObservationContext) {
        [self synchronizeUpdateInterval];
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

#pragma mark Private

- (void)synchronizeUpdateInterval {
    [self willChangeValueForKey:UPDATEINTERVAL_KEY];
    updateInterval = [[SUUpdater sharedUpdater] updateCheckInterval];
    [self didChangeValueForKey:UPDATEINTERVAL_KEY];
}

- (void)updateRevertButtons {
    NSDictionary *initialValues = [[NSUserDefaultsController sharedUserDefaultsController] initialValues];
    NSUserDefaults *sud = [NSUserDefaults standardUserDefaults];
    [revertPDFSettingsButton setEnabled:[[initialValues objectForKey:SKDefaultPDFDisplaySettingsKey] isEqual:[sud dictionaryForKey:SKDefaultPDFDisplaySettingsKey]] == NO];
    [revertFullScreenPDFSettingsButton setEnabled:[[initialValues objectForKey:SKDefaultFullScreenPDFDisplaySettingsKey] isEqual:[sud dictionaryForKey:SKDefaultFullScreenPDFDisplaySettingsKey]] == NO];
}

#pragma mark Hooks

- (void)resetSparkleDefaults {
    NSTimeInterval interval = [[[NSBundle mainBundle] objectForInfoDictionaryKey:@"SUScheduledCheckInterval"] doubleValue];
    [[SUUpdater sharedUpdater] setUpdateCheckInterval:interval];
    [[SUUpdater sharedUpdater] setAutomaticallyChecksForUpdates:interval > 0.0];
}

@end
