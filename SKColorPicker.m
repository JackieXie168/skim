//
//  SKColorPicker.m
//  Skim
//
//  Created by Christiaan Hofman on 17/05/2019.
/*
 This software is Copyright (c) 2019
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

#import "SKColorPicker.h"
#import "SKColorCell.h"
#import "SKStringConstants.h"
#import "NSValueTransformer_SKExtensions.h"
#import "NSUserDefaultsController_SKExtensions.h"

#define COLOR_IDENTIFIER @"color"

static char SKColorPickerDefaultsObservationContext;

@implementation SKColorPicker

@synthesize delegate;
@dynamic colors;

- (id)init {
    self = [super init];
    if (self) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wpartial-availability"
        scrubber = [[NSClassFromString(@"NSScrubber") alloc] initWithFrame:NSMakeRect(0.0, 0.0, 180, 22.0)];
        [scrubber setDelegate:self];
        [scrubber setDataSource:self];
        [scrubber setScrubberLayout:[[[NSScrubberProportionalLayout alloc] initWithNumberOfVisibleItems:[[self colors] count]] autorelease]];
        [scrubber registerClass:[NSClassFromString(@"NSScrubberItemView") class] forItemIdentifier:COLOR_IDENTIFIER];
        [scrubber setSelectionOverlayStyle:[NSClassFromString(@"NSScrubberSelectionStyle") outlineOverlayStyle]];
        [scrubber reloadData];
#pragma clang diagnostic pop
        
        NSView *view = [[[NSView alloc] initWithFrame:NSMakeRect(0.0, 0.0, 180, 30.0)] autorelease];
        NSMutableArray *constraints = [NSMutableArray array];
        [scrubber setTranslatesAutoresizingMaskIntoConstraints:NO];
        [view addSubview:scrubber];
        [constraints addObject:[NSLayoutConstraint constraintWithItem:scrubber attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:view attribute:NSLayoutAttributeLeading multiplier:1.0 constant:0.0]];
        [constraints addObject:[NSLayoutConstraint constraintWithItem:scrubber attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:view attribute:NSLayoutAttributeTrailing multiplier:1.0 constant:0.0]];
        [constraints addObject:[NSLayoutConstraint constraintWithItem:scrubber attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:view attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0.0]];
        [constraints addObject:[NSLayoutConstraint constraintWithItem:scrubber attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:22.0]];
        [NSLayoutConstraint activateConstraints:constraints];
        
        [self setView:view];
        
        [[NSUserDefaultsController sharedUserDefaultsController] addObserver:self forKey:SKSwatchColorsKey context:&SKColorPickerDefaultsObservationContext];
    }
    return self;
}

- (void)dealloc {
    @try { [[NSUserDefaultsController sharedUserDefaultsController] removeObserver:self forKey:SKSwatchColorsKey]; }
    @catch (id e) {}
    SKDESTROY(colors);
    SKDESTROY(scrubber);
    [super dealloc];
}

- (NSArray *)colors {
    if (colors == nil) {
        NSValueTransformer *transformer = [NSValueTransformer valueTransformerForName:SKUnarchiveFromDataArrayTransformerName];
        colors = [[transformer transformedValue:[[NSUserDefaults standardUserDefaults] objectForKey:SKSwatchColorsKey]] retain];
    }
    return colors;
}

#pragma mark NSScrubberDataSource, NSScrubberDelegate

- (NSInteger)numberOfItemsForScrubber:(NSScrubber *)scrubber {
    return [[self colors] count];
}

- (NSScrubberItemView *)scrubber:(NSScrubber *)aScrubber viewForItemAtIndex:(NSInteger)idx {
    NSScrubberItemView *itemView = [aScrubber makeItemWithIdentifier:COLOR_IDENTIFIER owner:nil];
    NSImageView *imageView = [[itemView subviews] firstObject];
    if (imageView  == nil || [imageView isKindOfClass:[NSImageView class]] == NO || [[imageView cell] isKindOfClass:[SKColorCell class]] == NO) {
        imageView = [[[NSImageView alloc] initWithFrame:[itemView bounds]] autorelease];
        SKColorCell *colorCell = [[SKColorCell alloc] init];
        [colorCell setShouldFill:YES];
        [imageView setCell:colorCell];
        [colorCell release];
        [imageView setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
        [itemView addSubview:imageView];
    }
    [imageView setObjectValue:[[self colors] objectAtIndex:idx]];
    return itemView;
}

- (void)scrubber:(NSScrubber *)scrubber didSelectItemAtIndex:(NSInteger)selectedIndex {
    if (selectedIndex >= 0 && selectedIndex < (NSInteger)[[self colors] count]) {
        NSColor *color = [[self colors] objectAtIndex:selectedIndex];
        [[self delegate] colorPicker:self didSelectColor:color];
    }
    [scrubber setSelectedIndex:-1];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (context == &SKColorPickerDefaultsObservationContext) {
        SKDESTROY(colors);
        [[scrubber scrubberLayout] setNumberOfVisibleItems:[[self colors] count]];
        [scrubber reloadData];
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

@end
