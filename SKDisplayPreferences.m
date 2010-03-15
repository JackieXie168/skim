//
//  SKDisplayPreferences.m
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

#import "SKDisplayPreferences.h"
#import "SKPreferenceController.h"
#import "SKStringConstants.h"
#import "NSGeometry_SKExtensions.h"

static CGFloat SKDefaultFontSizes[] = {8.0, 9.0, 10.0, 11.0, 12.0, 13.0, 14.0, 16.0, 18.0, 20.0, 24.0, 28.0, 32.0, 48.0, 64.0};

@implementation SKDisplayPreferences

- (NSString *)nibName {
    return @"DisplayPreferences";
}

- (void)loadView {
    [super loadView];
    
    NSRect frame;
    CGFloat dw;
    
    SKAutoSizeLabelFields([NSArray arrayWithObjects:thumbnailSizeLabelField, snapshotSizeLabelField, nil], [NSArray arrayWithObjects:thumbnailSizeSlider, snapshotSizeSlider, discreteSizesCheckButton, nil], NO);
    [discreteSizesCheckButton sizeToFit];
    SKAutoSizeLabelFields([NSArray arrayWithObjects:tableFontLabelField, nil], [NSArray arrayWithObjects:tableFontComboBox, nil], NO);
    SKAutoSizeLabelFields([NSArray arrayWithObjects:greekingLabelField, nil], [NSArray arrayWithObjects:greekingTextField, nil], NO);
    [antiAliasCheckButton sizeToFit];
    SKAutoSizeLabelFields([NSArray arrayWithObjects:backgroundColorLabelField, readingBarColorLabelField, nil], [NSArray arrayWithObjects:backgroundColorWell, fullScreenBackgroundColorLabelField, fullScreenBackgroundColorWell, readingBarColorWell, readingBarInvertCheckButton, nil], NO);
    SKAutoSizeLabelFields([NSArray arrayWithObjects:fullScreenBackgroundColorLabelField, nil], [NSArray arrayWithObjects:fullScreenBackgroundColorWell, nil], NO);
    frame = [searchHighlightCheckButton frame];
    [searchHighlightCheckButton sizeToFit];
    dw = NSWidth([searchHighlightCheckButton frame]) - NSWidth(frame);
    if (fabs(dw) > 0.0)
        SKShiftAndResizeViews([NSArray arrayWithObjects:searchHighlightColorWell, nil], dw, 0.0);
    [readingBarInvertCheckButton sizeToFit];
}

#pragma mark Accessors

- (NSUInteger)countOfSizes {
    return sizeof(SKDefaultFontSizes) / sizeof(CGFloat);
}

- (NSNumber *)objectInSizesAtIndex:(NSUInteger)anIndex {
    return [NSNumber numberWithDouble:SKDefaultFontSizes[anIndex]];
}

#pragma mark Actions

- (IBAction)changeDiscreteThumbnailSizes:(id)sender {
    if ([sender state] == NSOnState) {
        [thumbnailSizeSlider setNumberOfTickMarks:8];
        [snapshotSizeSlider setNumberOfTickMarks:8];
        [thumbnailSizeSlider setAllowsTickMarkValuesOnly:YES];
        [snapshotSizeSlider setAllowsTickMarkValuesOnly:YES];
    } else {
        [[thumbnailSizeSlider superview] setNeedsDisplayInRect:[thumbnailSizeSlider frame]];
        [[snapshotSizeSlider superview] setNeedsDisplayInRect:[snapshotSizeSlider frame]];
        [thumbnailSizeSlider setNumberOfTickMarks:0];
        [snapshotSizeSlider setNumberOfTickMarks:0];
        [thumbnailSizeSlider setAllowsTickMarkValuesOnly:NO];
        [snapshotSizeSlider setAllowsTickMarkValuesOnly:NO];
    }
    [thumbnailSizeSlider sizeToFit];
    [snapshotSizeSlider sizeToFit];
}

@end
