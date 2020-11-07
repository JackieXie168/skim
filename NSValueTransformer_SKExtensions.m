//
//  NSValueTransformer_SKExtensions.m
//  Skim
//
//  Created by Christiaan Hofman on 4/2/08.
/*
 This software is Copyright (c) 2008-2020
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

#import "NSValueTransformer_SKExtensions.h"
#import "NSImage_SKExtensions.h"
#import <SkimNotes/SkimNotes.h>

NSString *SKTypeImageTransformerName = @"SKTypeImage";
NSString *SKIsZeroTransformerName = @"SKIsZero";
NSString *SKIsOneTransformerName = @"SKIsOne";
NSString *SKIsTwoTransformerName = @"SKIsTwo";

@interface SKOneWayArrayTransformer : NSValueTransformer {
    NSValueTransformer *valueTransformer;
}
- (id)initWithValueTransformer:(NSValueTransformer *)aValueTransformer;
- (NSArray *)transformedArray:(NSArray *)array usingSelector:(SEL)selector;
@end

#pragma mark -

@interface SKTwoWayArrayTransformer : SKOneWayArrayTransformer
@end

#pragma mark -

@interface SKTypeImageTransformer : NSValueTransformer
@end

#pragma mark -

@interface SKRadioTransformer : NSValueTransformer {
    NSInteger targetValue;
}
- (id)initWithTargetValue:(NSInteger)value;
@end

#pragma mark -

@implementation NSValueTransformer (SKExtensions)

+ (void)registerCustomTransformers {
    [NSValueTransformer setValueTransformer:[[[SKTypeImageTransformer alloc] init] autorelease] forName:SKTypeImageTransformerName];
    [NSValueTransformer setValueTransformer:[[[SKRadioTransformer alloc] initWithTargetValue:0] autorelease] forName:SKIsZeroTransformerName];
    [NSValueTransformer setValueTransformer:[[[SKRadioTransformer alloc] initWithTargetValue:1] autorelease] forName:SKIsOneTransformerName];
    [NSValueTransformer setValueTransformer:[[[SKRadioTransformer alloc] initWithTargetValue:2] autorelease] forName:SKIsTwoTransformerName];
}

+ (NSValueTransformer *)arrayTransformerWithValueTransformer:(NSValueTransformer *)valueTransformer {
    if ([[valueTransformer class] allowsReverseTransformation])
        return [[[SKTwoWayArrayTransformer alloc] initWithValueTransformer:valueTransformer] autorelease];
    else if (valueTransformer)
        return [[[SKOneWayArrayTransformer alloc] initWithValueTransformer:valueTransformer] autorelease];
    else
        return nil;
}

+ (NSValueTransformer *)arrayTransformerWithValueTransformerForName:(NSString *)name {
    return [self arrayTransformerWithValueTransformer:[self valueTransformerForName:name]];
}

@end

#pragma mark -

@implementation SKOneWayArrayTransformer

+ (Class)transformedValueClass {
    return [NSArray class];
}

+ (BOOL)allowsReverseTransformation {
    return NO;
}

- (id)initWithValueTransformer:(NSValueTransformer *)aValueTransformer {
    self = [super init];
    if (self) {
        if (aValueTransformer) {
            valueTransformer = [aValueTransformer retain];
        } else {
            [self release];
            self = nil;
        }
    }
    return self;
}

- (id)init {
    return [self initWithValueTransformer:[[[NSValueTransformer alloc] init] autorelease]];
}

- (void)dealloc {
    SKDESTROY(valueTransformer);
    [super dealloc];
}

- (NSArray *)transformedArray:(NSArray *)array usingSelector:(SEL)selector {
    NSMutableArray *transformedArray = [NSMutableArray arrayWithCapacity:[array count]];
    for (id obj in array)
        [transformedArray addObject:[valueTransformer performSelector:selector withObject:obj] ?: [NSNull null]];
    return transformedArray;
}

- (id)transformedValue:(id)array {
    return [self transformedArray:array usingSelector:_cmd];
}

@end

#pragma mark -

@implementation SKTwoWayArrayTransformer

+ (BOOL)allowsReverseTransformation {
    return YES;
}

- (id)reverseTransformedValue:(id)array {
    return [self transformedArray:array usingSelector:_cmd];
}

@end

#pragma mark -

@implementation SKTypeImageTransformer

+ (Class)transformedValueClass {
    return [NSImage class];
}

+ (BOOL)allowsReverseTransformation {
    return NO;
}

- (id)transformedValue:(id)type {
    if ([type isKindOfClass:[NSString class]] == NO)
        return nil;
    else if ([type isEqualToString:SKNFreeTextString])
        return [NSImage imageNamed:SKImageNameTextNote];
    else if ([type isEqualToString:SKNNoteString] || [type isEqualToString:SKNTextString])
        return [NSImage imageNamed:SKImageNameAnchoredNote];
    else if ([type isEqualToString:SKNCircleString])
        return [NSImage imageNamed:SKImageNameCircleNote];
    else if ([type isEqualToString:SKNSquareString])
        return [NSImage imageNamed:SKImageNameSquareNote];
    else if ([type isEqualToString:SKNHighlightString] || [type isEqualToString:SKNMarkUpString])
        return [NSImage imageNamed:SKImageNameHighlightNote];
    else if ([type isEqualToString:SKNUnderlineString])
        return [NSImage imageNamed:SKImageNameUnderlineNote];
    else if ([type isEqualToString:SKNStrikeOutString])
        return [NSImage imageNamed:SKImageNameStrikeOutNote];
    else if ([type isEqualToString:SKNLineString])
        return [NSImage imageNamed:SKImageNameLineNote];
    else if ([type isEqualToString:SKNInkString])
        return [NSImage imageNamed:SKImageNameInkNote];
    else
        return nil;
}

@end

#pragma mark -

@implementation SKRadioTransformer

+ (Class)transformedValueClass {
    return [NSNumber class];
}

- (id)initWithTargetValue:(NSInteger)value {
    self = [super init];
    if (self) {
        targetValue = value;
    }
    return self;
}

+ (BOOL)allowsReverseTransformation {
    return YES;
}

- (id)transformedValue:(id)value {
    return [NSNumber numberWithInteger:[value integerValue] == targetValue ? NSOnState : NSOffState];
}

- (id)reverseTransformedValue:(id)value {
    return [NSNumber numberWithInteger:[value integerValue] == NSOnState ? targetValue : 0];
}

@end
