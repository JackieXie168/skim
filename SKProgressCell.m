//
//  SKProgressCell.m
//  Skim
//
//  Created by Christiaan Hofman on 8/11/07.
/*
 This software is Copyright (c) 2007-2011
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

#import "SKProgressCell.h"
#import "SKDownload.h"
#import "NSString_SKExtensions.h"
#import "NSGeometry_SKExtensions.h"

#define MARGIN_X 8.0
#define MARGIN_Y 2.0

@interface SKProgressCellFormatter : NSFormatter
@end

#pragma mark

static inline id objectValueForKey(id object, NSString *key) {
    return [object respondsToSelector:@selector(objectForKey:)] ? [object objectForKey:key] : nil;
}

@implementation SKProgressCell

static SKProgressCellFormatter *progressCellFormatter = nil;

+ (void)initialize {
    SKINITIALIZE;
    progressCellFormatter = [[SKProgressCellFormatter alloc] init];
    
}

- (void)commonInit {
    statusCell = [[NSTextFieldCell alloc] initTextCell:@""];
    [statusCell setFont:[[NSFontManager sharedFontManager] convertFont:[self font] toSize:10.0]];
    [statusCell setWraps:NO];
    [statusCell setLineBreakMode:NSLineBreakByClipping];
    if ([self formatter] == nil)
        [self setFormatter:progressCellFormatter];
}

- (id)initTextCell:(NSString *)aString {
    self = [super initTextCell:aString];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        [self commonInit];
	}
	return self;
}

- (id)copyWithZone:(NSZone *)zone {
    SKProgressCell *copy = [super copyWithZone:zone];
    copy->statusCell = [statusCell copyWithZone:zone];
    return copy;
}

- (void)dealloc {
    SKDESTROY(statusCell);
	[super dealloc];
}

- (void)setFont:(NSFont *)font {
    [super setFont:font];
    [statusCell setFont:[[NSFontManager sharedFontManager] convertFont:font toSize:10.0]];
}

- (void)setBackgroundStyle:(NSBackgroundStyle)style {
    [super setBackgroundStyle:style];
    [statusCell setBackgroundStyle:style];
}

- (void)setObjectValue:(id <NSCopying>)obj {
    [super setObjectValue:obj];
    
    NSString *statusDescription = nil;
    switch ([objectValueForKey(obj, SKDownloadStatusKey) integerValue]) {
        case SKDownloadStatusStarting:
            statusDescription = [NSLocalizedString(@"Starting", @"Download status message") stringByAppendingEllipsis];
            break;
        case SKDownloadStatusDownloading:
            statusDescription = [NSLocalizedString(@"Downloading", @"Download status message") stringByAppendingEllipsis];
            break;
        case SKDownloadStatusFinished:
            statusDescription = NSLocalizedString(@"Finished", @"Download status message");
            break;
        case SKDownloadStatusFailed:
            statusDescription = NSLocalizedString(@"Failed", @"Download status message");
            break;
        case SKDownloadStatusCanceled:
            statusDescription = NSLocalizedString(@"Canceled", @"Download status message");
            break;
        default:
            break;
    }
    [statusCell setObjectValue:statusDescription];
}

- (NSSize)cellSizeForBounds:(NSRect)aRect {
    NSSize cellSize = [super cellSizeForBounds:aRect];
    if (nil == objectValueForKey([self objectValue], SKDownloadProgressIndicatorKey)) {
        NSSize statusSize = [statusCell cellSize];
        cellSize.width = fmax(cellSize.width, statusSize.width);
        cellSize.height += statusSize.height;
    }
    cellSize.width += 2.0 * MARGIN_X;
    cellSize.height += MARGIN_Y;
    return cellSize;
}

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
    NSProgressIndicator *progressIndicator = objectValueForKey([self objectValue], SKDownloadProgressIndicatorKey);
    NSRectEdge bottomEdge = [controlView isFlipped] ? NSMaxYEdge : NSMinYEdge;
    NSRectEdge topEdge = [controlView isFlipped] ? NSMinYEdge : NSMaxYEdge;
    NSRect insetRect = SKShrinkRect(NSInsetRect(cellFrame, MARGIN_X, 0.0), MARGIN_Y, bottomEdge);
    
    [self drawInteriorWithFrame:SKSliceRect(insetRect, [super cellSizeForBounds:cellFrame].height, topEdge) inView:controlView];
    
    if (progressIndicator) {
        [progressIndicator setFrame:SKSliceRect(insetRect, NSHeight([progressIndicator frame]), bottomEdge)];
        
        if ([progressIndicator isDescendantOf:controlView] == NO)
            [controlView addSubview:progressIndicator];
    } else { 
        [statusCell drawInteriorWithFrame:SKSliceRect(insetRect, [statusCell cellSize].height, bottomEdge) inView:controlView];
    }
}

- (void)drawWithExpansionFrame:(NSRect)cellFrame inView:(NSView *)view {
    [self drawInteriorWithFrame:SKSliceRect(cellFrame, [super cellSizeForBounds:cellFrame].height, [view isFlipped] ? NSMinYEdge : NSMaxYEdge) inView:view];
    
    if (nil == objectValueForKey([self objectValue], SKDownloadProgressIndicatorKey))
        [statusCell drawInteriorWithFrame:SKSliceRect(cellFrame, [statusCell cellSize].height, [view isFlipped] ? NSMaxYEdge : NSMinYEdge) inView:view];
}

- (NSRect)expansionFrameWithFrame:(NSRect)cellFrame inView:(NSView *)view {
    NSRect rect = [super expansionFrameWithFrame:cellFrame inView:view];
    return SKShrinkRect(NSInsetRect(rect, MARGIN_X, 0.0), MARGIN_Y, [view isFlipped] ? NSMaxYEdge : NSMinYEdge);
}

#pragma mark Accessibility

- (id)accessibilityAttributeNames {
    return [[super accessibilityAttributeNames] arrayByAddingObject:NSAccessibilityDescriptionAttribute];
}

- (id)accessibilityAttributeValue:(NSString *)attribute {
    if ([attribute isEqualToString:NSAccessibilityDescriptionAttribute])
        return [statusCell stringValue];
    return [super accessibilityAttributeValue:attribute];
}

@end

#pragma mark -

@implementation SKProgressCellFormatter

- (NSString *)stringForObjectValue:(id)obj {
    return objectValueForKey(obj, SKDownloadFileNameKey);
}

- (BOOL)getObjectValue:(id *)obj forString:(NSString *)string errorDescription:(NSString **)error {
    *obj = [NSDictionary dictionaryWithObjectsAndKeys:[[string copy] autorelease], SKDownloadFileNameKey, nil];
    return YES;
}

@end
