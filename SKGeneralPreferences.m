//
//  SKGeneralPreferences.m
//  Skim
//
//  Created by Christiaan Hofman on 3/14/10.
/*
 This software is Copyright (c) 2010-2014
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
#import "NSGraphics_SKExtensions.h"

#define UPDATEINTERVAL_KEY @"updateInterval"
#define AUTOMATICALLYCHECKSFORUPDATES_KEY @"automaticallyChecksForUpdates"
#define UPDATECHECKINTERVAL_KEY @"updateCheckInterval"

#define SUScheduledCheckIntervalKey @"SUScheduledCheckInterval"

static char SKGeneralPreferencesDefaultsObservationContext;
static char SKGeneralPreferencesUpdaterObservationContext;

@interface SKGeneralPreferences (Private)
- (void)synchronizeUpdateInterval;
- (void)updateRevertButtons;
@end

@implementation SKGeneralPreferences

@synthesize updateIntervalPopUpButton, revertPDFSettingsButtons, openFilesLabelField, openFilesMatrix, updateIntervalLabelField, savePasswordsMatrix, updateInterval;

- (void)dealloc {
    @try {
        [[NSUserDefaultsController sharedUserDefaultsController] removeObserver:self forKeys:[NSArray arrayWithObjects:SKDefaultPDFDisplaySettingsKey, SKDefaultFullScreenPDFDisplaySettingsKey, nil]];
        [[SUUpdater sharedUpdater] removeObserver:self forKeyPath:AUTOMATICALLYCHECKSFORUPDATES_KEY];
        [[SUUpdater sharedUpdater] removeObserver:self forKeyPath:UPDATECHECKINTERVAL_KEY];
    }
    @catch(id e) {}
    SKDESTROY(updateIntervalPopUpButton);
    SKDESTROY(revertPDFSettingsButtons);
    SKDESTROY(openFilesLabelField);
    SKDESTROY(openFilesMatrix);
    SKDESTROY(updateIntervalLabelField);
    SKDESTROY(savePasswordsMatrix);
    [super dealloc];
}

- (NSString *)nibName {
    return @"GeneralPreferences";
}

- (void)loadView {
    [super loadView];
    
    SKAutoSizeButtons(revertPDFSettingsButtons, NO);
    SKAutoSizeLabelField(openFilesLabelField, openFilesMatrix, NO);
    CGFloat dw = SKAutoSizeLabelField(updateIntervalLabelField, updateIntervalPopUpButton, NO);
    [openFilesMatrix sizeToFit];
    [savePasswordsMatrix sizeToFit];
    SKShiftAndResizeView([self view], 0.0, dw);
    
    [self synchronizeUpdateInterval];
    [self updateRevertButtons];
    
    [[NSUserDefaultsController sharedUserDefaultsController] addObserver:self forKeys:[NSArray arrayWithObjects:SKDefaultPDFDisplaySettingsKey, SKDefaultFullScreenPDFDisplaySettingsKey, nil] context:&SKGeneralPreferencesDefaultsObservationContext];
    [[SUUpdater sharedUpdater] addObserver:self forKeyPath:AUTOMATICALLYCHECKSFORUPDATES_KEY options:0 context:&SKGeneralPreferencesUpdaterObservationContext];
    [[SUUpdater sharedUpdater] addObserver:self forKeyPath:UPDATECHECKINTERVAL_KEY options:0 context:&SKGeneralPreferencesUpdaterObservationContext];
}

#pragma mark Accessors

- (NSString *)title { return NSLocalizedString(@"General", @"Preference pane label"); }

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
    if (context == &SKGeneralPreferencesDefaultsObservationContext)
        [self updateRevertButtons];
    else if (context == &SKGeneralPreferencesUpdaterObservationContext)
        [self synchronizeUpdateInterval];
    else
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

#pragma mark Private

- (void)synchronizeUpdateInterval {
    [self willChangeValueForKey:UPDATEINTERVAL_KEY];
    updateInterval = [[SUUpdater sharedUpdater] automaticallyChecksForUpdates] ? [[SUUpdater sharedUpdater] updateCheckInterval] : 0;
    [self didChangeValueForKey:UPDATEINTERVAL_KEY];
}

- (void)updateRevertButtons {
    NSDictionary *initialValues = [[NSUserDefaultsController sharedUserDefaultsController] initialValues];
    NSUserDefaults *sud = [NSUserDefaults standardUserDefaults];
    [[revertPDFSettingsButtons objectAtIndex:0] setEnabled:[[initialValues objectForKey:SKDefaultPDFDisplaySettingsKey] isEqual:[sud dictionaryForKey:SKDefaultPDFDisplaySettingsKey]] == NO];
    [[revertPDFSettingsButtons objectAtIndex:1] setEnabled:[[initialValues objectForKey:SKDefaultFullScreenPDFDisplaySettingsKey] isEqual:[sud dictionaryForKey:SKDefaultFullScreenPDFDisplaySettingsKey]] == NO];
}

#pragma mark Hooks

- (void)defaultsDidRevert {
    NSTimeInterval interval = [[[NSBundle mainBundle] objectForInfoDictionaryKey:SUScheduledCheckIntervalKey] doubleValue];
    [[SUUpdater sharedUpdater] setUpdateCheckInterval:interval];
    [[SUUpdater sharedUpdater] setAutomaticallyChecksForUpdates:interval > 0.0];
}

@end
