//
//  SKThumbnailItem.m
//  Skim
//
//  Created by Christiaan Hofman on 17/02/2020.
/*
This software is Copyright (c) 2020
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

#import "SKThumbnailItem.h"
#import "SKThumbnailView.h"
#import "SKThumbnail.h"

@implementation SKThumbnailItem

@synthesize backgroundStyle, highlightLevel, marked;

- (id)copyWithZone:(NSZone *)zone {
    SKThumbnailItem *copy = [super copyWithZone:zone];
    [copy setBackgroundStyle:[self backgroundStyle]];
    [copy setHighlightLevel:[self highlightLevel]];
    [copy setMarked:[self isMarked]];
    return copy;
}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];
    if (viewLoaded)
        [(SKThumbnailView *)[self view] setThumbnail:[representedObject isKindOfClass:[SKThumbnail class]] ? representedObject : nil];
}

- (void)setSelected:(BOOL)selected {
    [super setSelected:selected];
    if (viewLoaded)
        [(SKThumbnailView *)[self view] setSelected:selected];
}

- (void)setBackgroundStyle:(NSBackgroundStyle)newBackgroundStyle {
    if (backgroundStyle != newBackgroundStyle) {
        backgroundStyle = newBackgroundStyle;
        if (viewLoaded)
            [(SKThumbnailView *)[self view] setBackgroundStyle:newBackgroundStyle];
    }
}

- (void)setHighlightLevel:(NSInteger)newHighlightLevel {
    if (highlightLevel != newHighlightLevel) {
        highlightLevel = newHighlightLevel;
        if (viewLoaded)
            [(SKThumbnailView *)[self view] setHighlightLevel:newHighlightLevel];
    }
}

- (void)setMarked:(BOOL)newMarked {
    if (marked != newMarked) {
        marked = newMarked;
        if (viewLoaded)
            [(SKThumbnailView *)[self view] setMarked:newMarked];
    }
}

- (void)loadView {
    if (viewLoaded == NO) {
        SKThumbnailView *view = [[SKThumbnailView alloc] init];
        if ([[self representedObject] isKindOfClass:[SKThumbnail class]])
            [view setThumbnail:[self representedObject]];
        [view setSelected:[self isSelected]];
        [view setBackgroundStyle:[self backgroundStyle]];
        [view setHighlightLevel:[self highlightLevel]];
        [view setMarked:[self isMarked]];
        [self setView:view];
        [view release];
    }
    viewLoaded = YES;
}

@end
