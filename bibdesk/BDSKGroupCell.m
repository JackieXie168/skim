//
//  BDSKGroupCell.m
//  Bibdesk
//
//  Created by Christiaan Hofman on 26/10/05.
/*
 This software is Copyright (c) 2005,2006
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

#import "BDSKGroupCell.h"
#import "BDSKGroup.h"
#import <OmniBase/rcsid.h>
#import "NSBezierPath_BDSKExtensions.h"
#import <OmniBase/OBUtilities.h>
#import "NSImage+Toolbox.h"
#import "NSGeometry_BDSKExtensions.h"

static NSMutableParagraphStyle *BDSKGroupCellStringParagraphStyle = nil;
static NSMutableParagraphStyle *BDSKGroupCellCountParagraphStyle = nil;
static NSLayoutManager *layoutManager = nil;

// names of these globals were changed to support key-value coding on BDSKGroup
NSString *BDSKGroupCellStringKey = @"stringValue";
NSString *BDSKGroupCellImageKey = @"icon";
NSString *BDSKGroupCellCountKey = @"numberValue";

@interface BDSKGroupCell (Private)
- (void)recacheCountAttributes;
@end

@implementation BDSKGroupCell

+ (void)initialize;
{
    OBINITIALIZE;
    
    BDSKGroupCellStringParagraphStyle = [[NSMutableParagraphStyle alloc] init];
    [BDSKGroupCellStringParagraphStyle setLineBreakMode:NSLineBreakByTruncatingTail];
    BDSKGroupCellCountParagraphStyle = [[NSMutableParagraphStyle alloc] init];
    [BDSKGroupCellCountParagraphStyle setLineBreakMode:NSLineBreakByClipping];
    layoutManager = [[NSLayoutManager alloc] init];
}

- (id)init {
    if (self = [super initTextCell:@""]) {
        
        [self setImagePosition:NSImageLeft];
        [self setEditable:YES];
        [self setScrollable:YES];
        
		[self setDrawsHighlight:NO];
        
        label = [[NSMutableAttributedString alloc] initWithString:@""];
        countString = [[NSMutableAttributedString alloc] initWithString:@""];
        
        countAttributes = [[NSMutableDictionary alloc] initWithCapacity:5];
        [self recacheCountAttributes];

    }
    return self;
}

// NSCoding

- (id)initWithCoder:(NSCoder *)coder {
	if (self = [super initWithCoder:coder]) {
		// we need to do these two because OATextWithIconCell does in subclass NSCoding, so super uses the one from NSTextFieldCell
		_oaFlags.drawsHighlight = [coder decodeIntForKey:@"drawsHighlight"];
		[self setImagePosition:NSImageLeft];
        
        // recreates the dictionary
        countAttributes = [[NSMutableDictionary alloc] initWithCapacity:5];
        [self recacheCountAttributes];
        
        // could encode these, but presumably we want a fresh string
        label = [[NSMutableAttributedString alloc] initWithString:@""];
        countString = [[NSMutableAttributedString alloc] initWithString:@""];
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
	[super encodeWithCoder:encoder];
	[encoder encodeInt:_oaFlags.drawsHighlight forKey:@"drawsHighlight"];
}

// NSCopying

- (id)copyWithZone:(NSZone *)zone {
    BDSKGroupCell *copy = [super copyWithZone:zone];

    copy->groupValue = [groupValue retain];
    copy->_oaFlags.drawsHighlight = _oaFlags.drawsHighlight;
    
    // count attributes are shared between this cell and all copies, but not with new instances
    copy->countAttributes = [countAttributes retain];
    copy->label = [label mutableCopy];
    copy->countString = [countString mutableCopy];

    return copy;
}

- (void)dealloc {
    [groupValue release];
    [label release];
    [countString release];
    [countAttributes release];
	[super dealloc];
}

- (NSColor *)highlightColorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView;
{
    if (!_oaFlags.drawsHighlight)
        return nil;
    else
        return [super highlightColorWithFrame:cellFrame inView:controlView];
}

- (NSColor *)textColor;
{
    if (_oaFlags.settingUpFieldEditor)
        return [NSColor blackColor];
    else if (!_oaFlags.drawsHighlight && _cFlags.highlighted)
        return [NSColor textBackgroundColor];
    else
        return [super textColor];
}

- (void)setFont:(NSFont *)font {
    [super setFont:font];
    [self recacheCountAttributes];
}

// BDSKGroup and NSString respond to these messages (see global keys in this file)

- (void)setObjectValue:(id <NSObject, NSCopying>)obj {
    OBASSERT(obj == nil || [obj respondsToSelector:@selector(stringValue)]);
    OBASSERT(obj == nil || [obj respondsToSelector:@selector(count)]);
    
    if(obj != groupValue){
        [groupValue release];
        groupValue = [obj retain];
        
        NSString *stringValue = [groupValue stringValue];
        // super's object value needs to be an NSString
        [super setObjectValue:stringValue];
        [[label mutableString] setString:stringValue];

        // all the -[NSNumber stringValue] does is create a string with a localized format description, so we'll call the underlying functions directly, since this shows up in Shark as a bottleneck
        int count = [groupValue count];
        CFStringRef countStr = (count ? CFStringCreateWithFormat(CFAllocatorGetDefault(), NULL, CFSTR("%d"), count) : CFRetain(CFSTR("")) );
        [[countString mutableString] setString:(NSString *)countStr];
        CFRelease(countStr);
    }
}

#pragma mark Drawing

#define BORDER_BETWEEN_EDGE_AND_IMAGE (2.0)
#define BORDER_BETWEEN_IMAGE_AND_TEXT (3.0)
#define SIZE_OF_TEXT_FIELD_BORDER (1.0)
#define BORDER_BETWEEN_EDGE_AND_COUNT (2.0)
#define BORDER_BETWEEN_COUNT_AND_TEXT (1.0)

#define _calculateDrawingRectsAndSizes \
NSRect ignored, imageRect, textRect, countRect; \
\
NSSize imageSize = NSMakeSize(NSHeight(aRect) + 1, NSHeight(aRect) + 1); \
NSSize countSize = NSZeroSize; \
BOOL failedDownload = [groupValue failedDownload]; \
BOOL isRetrieving = [groupValue isRetrieving]; \
BOOL controlViewIsFlipped = [controlView isFlipped]; \
\
float countSep = 0.0; \
if(failedDownload) { \
    countSize = NSMakeSize(16, 16); \
    countSep = 1.0; \
} \
else if(isRetrieving) { \
    countSize = NSMakeSize(16, 16); \
    countSep = 1.0; \
} \
else if([groupValue count] > 0) { \
    countSize = [countString size]; \
    countSep = 0.5f * countSize.height - 0.5; \
} \
\
/* set up the border around the image */ \
NSDivideRect(aRect, &ignored, &aRect, BORDER_BETWEEN_EDGE_AND_IMAGE, NSMinXEdge); \
NSDivideRect(aRect, &imageRect, &textRect, imageSize.width, NSMinXEdge); \
NSDivideRect(textRect, &ignored, &textRect, BORDER_BETWEEN_IMAGE_AND_TEXT, NSMinXEdge); \
if (countSize.width > 0) { \
    /* set up the border around the count string */ \
    NSDivideRect(textRect, &ignored, &textRect, BORDER_BETWEEN_EDGE_AND_COUNT + countSep, NSMaxXEdge); \
    NSDivideRect(textRect, &countRect, &textRect, countSize.width, NSMaxXEdge); \
    NSDivideRect(textRect, &ignored, &textRect, BORDER_BETWEEN_COUNT_AND_TEXT + countSep, NSMaxXEdge); \
} \
\
/* this is the main difference from OATextWithIconCell, which ends up with a really weird text baseline for tall cells */\
float vOffset = 0.5f * (NSHeight(aRect) - [layoutManager defaultLineHeightForFont:[self font]]); \
\
if (controlViewIsFlipped == NO) \
textRect.origin.y -= floorf(vOffset); \
else \
textRect.origin.y += floorf(vOffset); \

- (void)drawInteriorWithFrame:(NSRect)aRect inView:(NSView *)controlView {
    /* Shark and sample indicate that we're spending a lot of time in NSAttributedString drawing, if you test by holding down an arrow key and scrolling through the main table */

    NSRange labelRange = NSMakeRange(0, [label length]);
    [label addAttribute:NSFontAttributeName value:[self font] range:labelRange];
    [label addAttribute:NSForegroundColorAttributeName value:[self textColor] range:labelRange];
        	
	NSColor *highlightColor = [self highlightColorWithFrame:aRect inView:controlView];
	BOOL highlighted = [self isHighlighted];
	NSColor *bgColor = [NSColor disabledControlTextColor];
    NSRange countRange = NSMakeRange(0, [countString length]);
    [countString addAttributes:countAttributes range:countRange];

	if (highlighted) {
		// add the alternate text color attribute.
		if ([highlightColor isEqual:[NSColor alternateSelectedControlColor]])
			[label addAttribute:NSForegroundColorAttributeName value:[NSColor alternateSelectedControlTextColor] range:labelRange];
		[countString addAttribute:NSForegroundColorAttributeName value:[NSColor disabledControlTextColor] range:countRange];
		bgColor = [[NSColor alternateSelectedControlTextColor] colorWithAlphaComponent:0.8];
	} else {
		[countString addAttribute:NSForegroundColorAttributeName value:[NSColor alternateSelectedControlTextColor] range:countRange];
		bgColor = [bgColor colorWithAlphaComponent:0.7];
	}

    // Draw the text
    [label addAttribute:NSParagraphStyleAttributeName value:BDSKGroupCellStringParagraphStyle range:labelRange];
    
    // calculate after adding all attributes
    _calculateDrawingRectsAndSizes;
    
	// I am not sure about these, copied from OATextWithIconCell
    NSDivideRect(textRect, &ignored, &textRect, SIZE_OF_TEXT_FIELD_BORDER, NSMinXEdge);
    textRect = NSInsetRect(textRect, 1.0f, 0.0);    
    
    [label drawInRect:textRect];
    
    if (failedDownload) {
        NSImage *cautionImage = [NSImage cautionIconImage];
        NSSize cautionImageSize = [cautionImage size];
        NSRect cautionIconRect = NSMakeRect(0, 0, cautionImageSize.width, cautionImageSize.height);
        if(controlViewIsFlipped)
            [[NSImage cautionIconImage] drawFlippedInRect:countRect fromRect:cautionIconRect operation:NSCompositeSourceOver fraction:1.0];
        else
            [[NSImage cautionIconImage] drawInRect:countRect fromRect:cautionIconRect operation:NSCompositeSourceOver fraction:1.0];
    } else if (countSize.width > 0 && isRetrieving == NO) {
        [NSGraphicsContext saveGraphicsState];
		[bgColor setFill];
		[NSBezierPath fillHorizontalOvalAroundRect:NSIntegralRect(countRect)];
        [NSGraphicsContext restoreGraphicsState];

		[countString drawInRect:countRect];
    }
    	
    // Draw the image
    imageRect = BDSKCenterRect(imageRect, imageSize, controlViewIsFlipped);
	if (controlViewIsFlipped)
		[[groupValue icon] drawFlippedInRect:imageRect operation:NSCompositeSourceOver];
	else
		[[groupValue icon] drawInRect:imageRect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
    
}

- (void)selectWithFrame:(NSRect)aRect inView:(NSView *)controlView editor:(NSText *)textObj delegate:(id)anObject start:(int)selStart length:(int)selLength;
{
    _calculateDrawingRectsAndSizes;
    
    _oaFlags.settingUpFieldEditor = YES;
    [super selectWithFrame:textRect inView:controlView editor:textObj delegate:anObject start:selStart length:selLength];
    _oaFlags.settingUpFieldEditor = NO;
}

- (NSCellImagePosition)imagePosition;
{
    return _oaFlags.imagePosition;
}

- (void)setImagePosition:(NSCellImagePosition)aPosition;
{
    _oaFlags.imagePosition = aPosition;
}

- (BOOL)drawsHighlight;
{
    return _oaFlags.drawsHighlight;
}

- (void)setDrawsHighlight:(BOOL)flag;
{
    _oaFlags.drawsHighlight = flag;
}

- (NSRect)textRectForFrame:(NSRect)aRect inView:(NSView *)controlView;
{
    _calculateDrawingRectsAndSizes;
    
    return textRect;
}

@end

@implementation BDSKGroupCell (Private)

- (void)recacheCountAttributes {
    NSFont *font = [[self font] copy];
	NSFont *countFont = [[NSFontManager sharedFontManager] convertFont:font toHaveTrait:NSBoldFontMask];
    countFont = [[NSFontManager sharedFontManager] convertFont:countFont toSize:([countFont pointSize] - 1)];
    
	OBPRECONDITION(countFont);     
    
	[countAttributes removeAllObjects];
    [countAttributes setObject:[NSColor alternateSelectedControlTextColor] forKey:NSForegroundColorAttributeName];
    [countAttributes setObject:countFont forKey:NSFontAttributeName];
    [countAttributes setObject:font forKey:@"NSOriginalFont"];
    [countAttributes setObject:[NSNumber numberWithFloat:-1.0] forKey:NSKernAttributeName];
    [countAttributes setObject:BDSKGroupCellCountParagraphStyle forKey:NSParagraphStyleAttributeName];

	[font release];
}


@end
