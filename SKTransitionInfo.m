//
//  SKTransitionInfo.m
//  Skim
//
//  Created by Christiaan on 8/10/09.
/*
 This software is Copyright (c) 2009
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

#import "SKTransitionInfo.h"
#import "SKThumbnail.h"

#define STYLENAME_KEY @"styleName"
#define DURATION_KEY @"duration"
#define SHOULDRESTRICT_KEY @"shouldRestrict"


@implementation SKTransitionInfo

- (id)init {
    if (self = [super init]) {
        transitionStyle = SKNoTransition;
        duration = 1.0;
        shouldRestrict = NO;
        thumbnail = nil;
        label = nil;
    }
    return self;
}

- (void)dealloc {
    SKDESTROY(thumbnail);
    SKDESTROY(label);
    [super dealloc];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@ %p> %@", [self class], self, [self properties]];
}

- (NSDictionary *)properties {
    return [NSDictionary dictionaryWithObjectsAndKeys:
                ([SKTransitionController nameForStyle:transitionStyle] ?: @""), STYLENAME_KEY,
                [NSNumber numberWithDouble:duration], DURATION_KEY,
                [NSNumber numberWithBool:shouldRestrict], SHOULDRESTRICT_KEY, nil];
}

- (void)setProperties:(NSDictionary *)dictionary {
    id value;
    if (value = [dictionary objectForKey:STYLENAME_KEY])
        [self setTransitionStyle:[SKTransitionController styleForName:value]];
    if (value = [dictionary objectForKey:DURATION_KEY])
        [self setDuration:[value doubleValue]];
    if (value = [dictionary objectForKey:SHOULDRESTRICT_KEY])
        [self setShouldRestrict:[value doubleValue]];
}

- (SKAnimationTransitionStyle)transitionStyle {
    return transitionStyle;
}

- (void)setTransitionStyle:(SKAnimationTransitionStyle)newTransitionStyle {
    transitionStyle = newTransitionStyle;
}

- (CGFloat)duration {
    return duration;
}

- (void)setDuration:(CGFloat)newDuration {
    duration = newDuration;
}

- (BOOL)shouldRestrict {
    return shouldRestrict;
}

- (void)setShouldRestrict:(BOOL)newShouldRestrict {
    shouldRestrict = newShouldRestrict;
}

- (SKThumbnail *)thumbnail {
    return thumbnail;
}

- (void)setThumbnail:(SKThumbnail *)newThumbnail {
    if (thumbnail != newThumbnail) {
        [thumbnail release];
        thumbnail = [newThumbnail retain];
    }
}

- (NSString *)label {
    return label;
}

- (void)setLabel:(NSString *)newLabel {
    if (label != newLabel) {
        [label release];
        label = [newLabel copy];
    }
}

@end
