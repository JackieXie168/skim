//
//  SKAnnotationTypeImageCell.m
//  Skim
//
//  Created by Christiaan Hofman on 3/22/08.
/*
 This software is Copyright (c) 2008
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

- (void)dealloc {
    [type release];
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

static void SKAddNamedAndFilteredImageForKey(NSMutableDictionary *images, NSMutableDictionary *filteredImages, NSString *name, NSString *key, CIFilter *filter)
{
    NSImage *image = [NSImage imageNamed:name];
    NSImage *filteredImage = [[NSImage alloc] initWithSize:[image size]];
    CIImage *ciImage = [CIImage imageWithData:[image TIFFRepresentation]];
    
    [filter setValue:ciImage forKey:@"inputImage"];
    ciImage = [filter valueForKey:@"outputImage"];
    
    CGRect cgRect = [ciImage extent];
    NSRect nsRect = *(NSRect*)&cgRect;
    
    [filteredImage lockFocus];
    [ciImage drawAtPoint:NSZeroPoint fromRect:nsRect operation:NSCompositeCopy fraction:1.0];
    [filteredImage unlockFocus];
    
    [images setObject:image forKey:key];
    [filteredImages setObject:filteredImage forKey:key];
    [filteredImage release];
}

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
    static NSMutableDictionary *noteImages = nil;
    static NSMutableDictionary *invertedNoteImages = nil;
    
    if (noteImages == nil) {
        CIFilter *filter = [CIFilter filterWithName:@"CIColorInvert"];
        
        noteImages = [[NSMutableDictionary alloc] initWithCapacity:8];
        invertedNoteImages = [[NSMutableDictionary alloc] initWithCapacity:8];
        
        SKAddNamedAndFilteredImageForKey(noteImages, invertedNoteImages, SKImageNameTextNoteAdorn, SKNFreeTextString, filter);
        SKAddNamedAndFilteredImageForKey(noteImages, invertedNoteImages, SKImageNameAnchoredNoteAdorn, SKNNoteString, filter);
        SKAddNamedAndFilteredImageForKey(noteImages, invertedNoteImages, SKImageNameCircleNoteAdorn, SKNCircleString, filter);
        SKAddNamedAndFilteredImageForKey(noteImages, invertedNoteImages, SKImageNameSquareNoteAdorn, SKNSquareString, filter);
        SKAddNamedAndFilteredImageForKey(noteImages, invertedNoteImages, SKImageNameHighlightNoteAdorn, SKNHighlightString, filter);
        SKAddNamedAndFilteredImageForKey(noteImages, invertedNoteImages, SKImageNameUnderlineNoteAdorn, SKNUnderlineString, filter);
        SKAddNamedAndFilteredImageForKey(noteImages, invertedNoteImages, SKImageNameStrikeOutNoteAdorn, SKNStrikeOutString, filter);
        SKAddNamedAndFilteredImageForKey(noteImages, invertedNoteImages, SKImageNameLineNoteAdorn, SKNLineString, filter);
        //SKAddNamedAndFilteredImageForKey(noteImages, invertedNoteImages, SKImageNameInkNoteAdorn, SKNInkString, filter);
    }
    
    BOOL isSelected = [self isHighlighted] && [[controlView window] isKeyWindow] && [[[controlView window] firstResponder] isEqual:controlView];
    NSImage *image = type ? [(isSelected ? invertedNoteImages : noteImages) objectForKey:type] : nil;
    
    if (active) {
        [[NSGraphicsContext currentContext] saveGraphicsState];
        if (isSelected)
            [[NSColor colorWithCalibratedWhite:1.0 alpha:0.8] set];
        else
            [[NSColor colorWithCalibratedWhite:0.0 alpha:0.7] set];
        NSRect rect = cellFrame;
        rect.origin.y = floorf(NSMinY(rect) + 0.5 * (NSHeight(cellFrame) - NSWidth(cellFrame)));
        rect.size.height = NSWidth(rect);
        [NSBezierPath setDefaultLineWidth:1.0];
        [NSBezierPath strokeRect:NSInsetRect(rect, 0.5, 0.5)];
        [[NSGraphicsContext currentContext] restoreGraphicsState];
    }
    
    [super setObjectValue:image];
    [super drawWithFrame:cellFrame inView:controlView];
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
