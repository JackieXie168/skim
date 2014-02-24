//
//  SKDisplayPreferences.m
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

#import "SKDisplayPreferences.h"
#import "SKPreferenceController.h"
#import "SKStringConstants.h"
#import "NSGraphics_SKExtensions.h"

static CGFloat SKDefaultFontSizes[] = {8.0, 9.0, 10.0, 11.0, 12.0, 13.0, 14.0, 16.0, 18.0, 20.0, 24.0, 28.0, 32.0, 48.0, 64.0};

@implementation SKDisplayPreferences

@synthesize tableFontLabelField, tableFontComboBox, greekingLabelField, greekingTextField, antiAliasCheckButton, thumbnailSizeLabels, thumbnailSizeControls, colorLabels, colorControls;

- (void)dealloc {
    SKDESTROY(tableFontLabelField);
    SKDESTROY(tableFontComboBox);
    SKDESTROY(greekingLabelField);
    SKDESTROY(greekingTextField);
    SKDESTROY(antiAliasCheckButton);
    SKDESTROY(thumbnailSizeLabels);
    SKDESTROY(thumbnailSizeControls);
    SKDESTROY(colorLabels);
    SKDESTROY(colorControls);
    [super dealloc];
}

- (NSString *)nibName {
    return @"DisplayPreferences";
}

- (void)loadView {
    [super loadView];
    
    SKAutoSizeLabelFields(thumbnailSizeLabels, thumbnailSizeControls, NO);
    [[thumbnailSizeControls lastObject] sizeToFit];
    SKAutoSizeLabelField(tableFontLabelField, tableFontComboBox, NO);
    SKAutoSizeLabelField(greekingLabelField, greekingTextField, NO);
    [antiAliasCheckButton sizeToFit];
    SKAutoSizeLabelFields(colorLabels, colorControls, NO);
    SKAutoSizeLabelField([colorControls objectAtIndex:1], [colorControls objectAtIndex:2], NO);
    [[colorControls lastObject] sizeToFit];
    
    CGFloat w = 0.0;
    for (NSView *view in [[self view] subviews]) {
        if (([view autoresizingMask] & NSViewWidthSizable) == 0) {
            CGFloat x = NSMaxX([view frame]);
            if ([view isKindOfClass:[NSSlider class]] || [view isKindOfClass:[NSButton class]])
                x -= 2.0;
            else if ([view isKindOfClass:[NSComboBox class]])
                x -= 3.0;
            w = fmax(w, x);
        }
    }
    NSSize size = [[self view] frame].size;
    size.width = w + 20.0;
    [[self view] setFrameSize:size];
}

#pragma mark Accessors

- (NSString *)title { return NSLocalizedString(@"Display", @"Preference pane label"); }

- (NSUInteger)countOfSizes {
    return sizeof(SKDefaultFontSizes) / sizeof(CGFloat);
}

- (NSNumber *)objectInSizesAtIndex:(NSUInteger)anIndex {
    return [NSNumber numberWithDouble:SKDefaultFontSizes[anIndex]];
}

#pragma mark Actions

- (IBAction)changeDiscreteThumbnailSizes:(id)sender {
    NSSlider *slider1 = [thumbnailSizeControls objectAtIndex:0];
    NSSlider *slider2 = [thumbnailSizeControls objectAtIndex:1];
    if ([(NSButton *)sender state] == NSOnState) {
        [slider1 setNumberOfTickMarks:8];
        [slider2 setNumberOfTickMarks:8];
        [slider1 setAllowsTickMarkValuesOnly:YES];
        [slider2 setAllowsTickMarkValuesOnly:YES];
    } else {
        [[slider1 superview] setNeedsDisplayInRect:[slider1 frame]];
        [[slider2 superview] setNeedsDisplayInRect:[slider2 frame]];
        [slider1 setNumberOfTickMarks:0];
        [slider2 setNumberOfTickMarks:0];
        [slider1 setAllowsTickMarkValuesOnly:NO];
        [slider2 setAllowsTickMarkValuesOnly:NO];
    }
    [slider1 sizeToFit];
    [slider2 sizeToFit];
}

@end
