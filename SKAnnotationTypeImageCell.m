//
//  SKAnnotationTypeImageCell.m
//  Skim
//
//  Created by Christiaan Hofman on 3/22/08.
/*
 This software is Copyright (c) 2008-2014
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
#import <Quartz/Quartz.h>
#import <SkimNotes/SkimNotes.h>
#import "NSImage_SKExtensions.h"
#import "NSString_SKExtensions.h"

NSString *SKAnnotationTypeImageCellTypeKey = @"type";
NSString *SKAnnotationTypeImageCellActiveKey = @"active";

@implementation SKAnnotationTypeImageCell

- (id)copyWithZone:(NSZone *)aZone {
    SKAnnotationTypeImageCell *copy = [super copyWithZone:aZone];
    copy->type = [type retain];
    copy->active = active;
    return copy;
}

- (id)initWithCoder:(NSCoder *)decoder {
    self = [super initWithCoder:decoder];
    if (self) {
        type = [[decoder decodeObjectForKey:@"type"] retain];
        active = [decoder decodeBoolForKey:@"active"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [super encodeWithCoder:coder];
    [coder encodeObject:type forKey:@"type"];
    [coder encodeBool:active forKey:@"active"];
}

- (void)dealloc {
    SKDESTROY(type);
    [super dealloc];
}

- (void)setObjectValue:(id)anObject {
    if ([anObject respondsToSelector:@selector(objectForKey:)]) {
        NSString *newType = [anObject objectForKey:SKAnnotationTypeImageCellTypeKey];
        if (type != newType) {
            [type release];
            type = [newType retain];
        }
        active = [[anObject objectForKey:SKAnnotationTypeImageCellActiveKey] boolValue];
    } else {
        [super setObjectValue:anObject];
    }
}

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
    NSImage *image = nil;
    
    if ([type isEqualToString:SKNFreeTextString])
        image = [NSImage imageNamed:SKImageNameTextNote];
    else if ([type isEqualToString:SKNNoteString])
        image = [NSImage imageNamed:SKImageNameAnchoredNote];
    else if ([type isEqualToString:SKNCircleString])
        image = [NSImage imageNamed:SKImageNameCircleNote];
    else if ([type isEqualToString:SKNSquareString])
        image = [NSImage imageNamed:SKImageNameSquareNote];
    else if ([type isEqualToString:SKNHighlightString])
        image = [NSImage imageNamed:SKImageNameHighlightNote];
    else if ([type isEqualToString:SKNUnderlineString])
        image = [NSImage imageNamed:SKImageNameUnderlineNote];
    else if ([type isEqualToString:SKNStrikeOutString])
        image = [NSImage imageNamed:SKImageNameStrikeOutNote];
    else if ([type isEqualToString:SKNLineString])
        image = [NSImage imageNamed:SKImageNameLineNote];
    else if ([type isEqualToString:SKNInkString])
        image = [NSImage imageNamed:SKImageNameInkNote];
    
    [super setObjectValue:image];
    [super drawWithFrame:cellFrame inView:controlView];
    
    if (active) {
        [[NSGraphicsContext currentContext] saveGraphicsState];
        if ([self isHighlighted] && [[controlView window] isKeyWindow] && [[[controlView window] firstResponder] isEqual:controlView])
            [[NSColor colorWithCalibratedWhite:1.0 alpha:0.8] set];
        else
            [[NSColor colorWithCalibratedWhite:0.0 alpha:0.7] set];
        NSRect rect = cellFrame;
        CGFloat height = fmin(NSWidth(cellFrame), NSHeight(cellFrame) - 1.0);
        CGFloat offset = 0.5 * (NSHeight(cellFrame) - height);
        rect.origin.y += [controlView isFlipped] ? ceil(offset) - 1.0 : floor(offset) + 1.0;
        rect.size.height = height;
        [NSBezierPath setDefaultLineWidth:1.0];
        [NSBezierPath strokeRect:NSInsetRect(rect, 0.5, 0.5)];
        [[NSGraphicsContext currentContext] restoreGraphicsState];
    }
}

- (NSArray *)accessibilityAttributeNames {
    return [[super accessibilityAttributeNames] arrayByAddingObject:NSAccessibilityTitleAttribute];
}

- (id)accessibilityAttributeValue:(NSString *)attribute {
   if ([attribute isEqualToString:NSAccessibilityTitleAttribute]) {
        return [type typeName];
    } else {
        return [super accessibilityAttributeValue:attribute];
    }
}

@end
