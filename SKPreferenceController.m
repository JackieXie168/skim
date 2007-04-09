//
//  SKPreferenceController.m
//  Skim
//
//  Created by Christiaan Hofman on 2/10/07.
/*
 This software is Copyright (c) 2007
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

#import "SKPreferenceController.h"
#import "SKStringConstants.h"
#import "NSUserDefaultsController_SKExtensions.h"


@implementation SKPreferenceController

+ (id)sharedPrefenceController {
    static SKPreferenceController *sharedPrefenceController = nil;
    if (sharedPrefenceController == nil)
        sharedPrefenceController = [[self alloc] init];
    return sharedPrefenceController;
}

- (id)init {
    if (self = [super init]) {
        NSMutableArray *fontNames = [[[[NSFontManager sharedFontManager] availableFontFamilies] mutableCopy] autorelease];
        NSEnumerator *fontEnum;
        NSString *fontName;
        
        [fontNames sortUsingSelector:@selector(caseInsensitiveCompare:)];
        fontEnum = [fontNames objectEnumerator];
        fonts = [[NSMutableArray alloc] init];
        while (fontName = [fontEnum nextObject]) {
            NSFont *font = [NSFont fontWithName:fontName size:0.0];
            [fonts addObject:[NSDictionary dictionaryWithObjectsAndKeys:[font fontName], @"fontName", [font displayName], @"displayName", nil]];
        }
        
        sizes = [[NSMutableArray alloc] initWithObjects:[NSNumber numberWithFloat:8.0], [NSNumber numberWithFloat:9.0], [NSNumber numberWithFloat:10.0], 
                                                        [NSNumber numberWithFloat:11.0], [NSNumber numberWithFloat:12.0], [NSNumber numberWithFloat:13.0], 
                                                        [NSNumber numberWithFloat:14.0], [NSNumber numberWithFloat:16.0], [NSNumber numberWithFloat:18.0], 
                                                        [NSNumber numberWithFloat:20.0], [NSNumber numberWithFloat:24.0], [NSNumber numberWithFloat:28.0], 
                                                        [NSNumber numberWithFloat:32.0], [NSNumber numberWithFloat:48.0], [NSNumber numberWithFloat:64.0], nil];
    }
    return self;
}

- (void)dealloc {
    [fonts release];
    [sizes release];
    [super dealloc];
}

- (NSString *)windowNibName {
    return @"PreferenceWindow";
}

- (NSArray *)fonts {
    return fonts;
}

- (NSArray *)sizes {
    return sizes;
}

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

- (IBAction)resetNoteColors:(id)sender {
    [[NSUserDefaultsController sharedUserDefaultsController] revertToInitialValuesForKeys:
        [NSArray arrayWithObjects:SKFreeTextNoteColorKey, SKAnchoredNoteColorKey, SKCircleNoteColorKey, SKSquareNoteColorKey, 
                                  SKHighlightNoteColorKey, SKUnderlineNoteColorKey, SKStrikeOutNoteColorKey, nil]];
}

- (IBAction)resetTextNoteFont:(id)sender {
    [[NSUserDefaultsController sharedUserDefaultsController] revertToInitialValuesForKeys:
        [NSArray arrayWithObjects:SKTextNoteFontNameKey, SKTextNoteFontSizeKey, nil]];
}

- (void)resetSheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo {
    if (returnCode == NSAlertDefaultReturn) {
        NSString *tabID = (NSString *)contextInfo;
        NSArray *keys = nil;
        if (tabID == nil) {
            [[NSUserDefaultsController sharedUserDefaultsController] revertToInitialValues:nil];
            return;
        } else if ([tabID isEqualToString:@"general"]) {
            keys = [NSArray arrayWithObjects:SKReopenLastOpenFilesKey, SKOpenFilesMaximizedKey, SKOpenContentsPaneOnlyForTOCKey, SKRememberLastPageViewedKey, SKSnapshotsOnTopKey, SKUpdateCheckIntervalKey, SKAutoCheckFileUpdateKey, nil];
        } else if ([tabID isEqualToString:@"display"]) {
            keys = [NSArray arrayWithObjects:SKThumbnailSizeKey, SKSnapshotThumbnailSizeKey, SKShouldAntiAliasKey, SKGreekingThresholdKey, nil];
        } else if ([tabID isEqualToString:@"colors"]) {
            keys = [NSArray arrayWithObjects:SKBackgroundColorKey, SKFullScreenBackgroundColorKey, SKShouldHighlightSearchResultsKey, SKSearchHighlightColorKey, SKReadingBarColorKey, SKReadingBarTransparencyKey, SKReadingBarInvertKey, nil];
        } else if ([tabID isEqualToString:@"notes"]) {
            keys = [NSArray arrayWithObjects:SKFreeTextNoteColorKey, SKAnchoredNoteColorKey, SKCircleNoteColorKey, SKSquareNoteColorKey, SKHighlightNoteColorKey, SKUnderlineNoteColorKey, SKStrikeOutNoteColorKey, SKTextNoteFontNameKey, SKTextNoteFontSizeKey, nil];
        }
        if (keys)
            [[NSUserDefaultsController sharedUserDefaultsController] revertToInitialValuesForKeys:keys];
    }
}

- (IBAction)resetAll:(id)sender {
    NSAlert *alert = [NSAlert alertWithMessageText:NSLocalizedString(@"Reset all preferences to their original values?", @"Message in alert dialog when pressing Reset All button") 
                                     defaultButton:NSLocalizedString(@"Reset", @"Button title")
                                   alternateButton:NSLocalizedString(@"Cancel", @"Button title")
                                       otherButton:nil
                         informativeTextWithFormat:NSLocalizedString(@"Choosing Reset will restore all settings to the state they were in when Skim was first installed.", @"Informative text in alert dialog when pressing Reset All button")];
    [alert beginSheetModalForWindow:[self window]
                      modalDelegate:nil
                     didEndSelector:NULL
                        contextInfo:NULL];
}

- (IBAction)resetCurrent:(id)sender {
    NSString *label = [[tabView selectedTabViewItem] label];
    NSAlert *alert = [NSAlert alertWithMessageText:[NSString stringWithFormat:NSLocalizedString(@"Reset %@ preferences to their original values?", @"Message in alert dialog when pressing Reset All button"), label]
                                     defaultButton:NSLocalizedString(@"Reset", @"Button title")
                                   alternateButton:NSLocalizedString(@"Cancel", @"Button title")
                                       otherButton:nil
                         informativeTextWithFormat:NSLocalizedString(@"Choosing Reset will restore all settings in this pane to the state they were in when Skim was first installed.", @"Informative text in alert dialog when pressing Reset All button"), label];
    [alert beginSheetModalForWindow:[self window]
                      modalDelegate:nil
                     didEndSelector:NULL
                        contextInfo:[[tabView selectedTabViewItem] identifier]];
}

@end
