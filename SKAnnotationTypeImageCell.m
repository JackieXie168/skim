//
//  SKAnnotationTypeImageCell.m
//  Skim
//
//  Created by Christiaan Hofman on 3/22/08.
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

#import "SKAnnotationTypeImageCell.h"


@implementation SKAnnotationTypeImageCell

@synthesize hasOutline;

static NSMutableDictionary *activeImages;

+ (void)initialize {
    SKINITIALIZE;
    activeImages = [[NSMutableDictionary alloc] init];
}

- (id)copyWithZone:(NSZone *)aZone {
    SKAnnotationTypeImageCell *copy = [super copyWithZone:aZone];
    copy->hasOutline = hasOutline;
    return copy;
}

- (id)initWithCoder:(NSCoder *)decoder {
    self = [super initWithCoder:decoder];
    if (self) {
        hasOutline = [decoder decodeBoolForKey:@"hasOutline"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [super encodeWithCoder:coder];
    [coder encodeBool:hasOutline forKey:@"hasOutline"];
}

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
    [super drawWithFrame:cellFrame inView:controlView];
    
    if ([self hasOutline]) {
        NSSize size = cellFrame.size;
        size.height = fmin(size.width, size.height);
        NSString *sizeKey = NSStringFromSize(size);
        NSImage *image = [activeImages objectForKey:sizeKey];
        if (image == nil) {
            image = [[[NSImage alloc] initWithSize:size] autorelease];
            [image lockFocus];
            [[NSColor blackColor] setFill];
            [NSBezierPath setDefaultLineWidth:1.0];
            [NSBezierPath strokeRect:NSMakeRect(0.5, 1.5, size.width - 1.0, size.height - 2.0)];
            [image unlockFocus];
            [image setTemplate:YES];
            [activeImages setObject:image forKey:sizeKey];
        }
        id object = [[self objectValue] retain];
        [self setObjectValue:image];
        [super drawWithFrame:cellFrame inView:controlView];
        [self setObjectValue:object];
        [object release];
    }
}

@end
