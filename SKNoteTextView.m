//
//  SKNoteTextView.m
//  Skim
//
//  Created by Christiaan Hofman on 9/14/10.
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

#import "SKNoteTextView.h"
#import "NSUserDefaultsController_SKExtensions.h"

static char SKNoteTextViewDefaultsObservationContext;

#define SKNoteTextFontSizeKey @"SKNoteTextFontSize"

@implementation SKNoteTextView

@synthesize usesDefaultFontSize;

- (void)dealloc {
    if (usesDefaultFontSize)
        [[NSUserDefaultsController sharedUserDefaultsController] removeObserver:self forKey:SKNoteTextFontSizeKey];
    [super dealloc];
}

- (void)setUsesDefaultFontSize:(BOOL)flag {
    if (usesDefaultFontSize != flag) {
        usesDefaultFontSize = flag;
        if (usesDefaultFontSize) {
            CGFloat fontSize = [[NSUserDefaults standardUserDefaults] floatForKey:SKNoteTextFontSizeKey];
            [self setFont:[NSFont userFontOfSize:fontSize]];
            [[NSUserDefaultsController sharedUserDefaultsController] addObserver:self forKey:SKNoteTextFontSizeKey context:&SKNoteTextViewDefaultsObservationContext];
        } else {
            [[NSUserDefaultsController sharedUserDefaultsController] removeObserver:self forKey:SKNoteTextFontSizeKey];
        }
    }
}

- (void)changeFont:(id)sender {
    if (usesDefaultFontSize) {
        NSFont *font = [sender convertFont:[self font]];
        [[NSUserDefaults standardUserDefaults] setFloat:[font pointSize] forKey:SKNoteTextFontSizeKey];
    } else {
        [super changeFont:sender];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (context == &SKNoteTextViewDefaultsObservationContext) {
        NSString *key = [keyPath substringFromIndex:7];
        if ([key isEqualToString:SKNoteTextFontSizeKey] && usesDefaultFontSize) {
            CGFloat fontSize = [[NSUserDefaults standardUserDefaults] floatForKey:SKNoteTextFontSizeKey];
            [self setFont:[NSFont userFontOfSize:fontSize]];
        }
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

@end
