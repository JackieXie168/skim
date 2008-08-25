//
//  SKProgressCell.m
//  Skim
//
//  Created by Christiaan Hofman on 8/11/07.
/*
 This software is Copyright (c) 2007-2008
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

#define MARGIN_X 8.0
#define MARGIN_Y 2.0

@implementation SKProgressCell

- (id)objectValueForKey:(NSString *)key {
    id value = nil;
    NSDictionary *info = [self objectValue];
    if ([info respondsToSelector:@selector(objectForKey:)])
        value = [info objectForKey:key];
    return value;
}

- (NSProgressIndicator *)progressIndicator {
    return [self objectValueForKey:SKDownloadProgressIndicatorKey];
}

- (NSString *)fileName {
    return [self objectValueForKey:SKDownloadFileNameKey];
}

- (int)status {
    return [[self objectValueForKey:SKDownloadStatusKey] intValue];
}

- (NSString *)statusDescription {
    switch ([self status]) {
        case SKDownloadStatusStarting:
            return [NSLocalizedString(@"Starting", @"Download status message") stringByAppendingEllipsis];
        case SKDownloadStatusDownloading:
            return [NSLocalizedString(@"Downloading", @"Download status message") stringByAppendingEllipsis];
        case SKDownloadStatusFinished:
            return NSLocalizedString(@"Finished", @"Download status message");
        case SKDownloadStatusFailed:
            return NSLocalizedString(@"Failed", @"Download status message");
        case SKDownloadStatusCanceled:
            return NSLocalizedString(@"Canceled", @"Download status message");
        default:
            return nil;
    }
}

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
    id value = [[[self objectValue] retain] autorelease];
    NSProgressIndicator *progressIndicator = [self progressIndicator];
    NSRect rect, ignored, insetRect;
    
    NSDivideRect(NSInsetRect(cellFrame, MARGIN_X, 0.0), &ignored, &insetRect, MARGIN_Y, [controlView isFlipped] ? NSMaxYEdge : NSMinYEdge);
    
    [self setObjectValue:[self fileName]];
    NSDivideRect(insetRect, &rect, &ignored, [self cellSize].height, [controlView isFlipped] ? NSMinYEdge : NSMaxYEdge);
    [super drawWithFrame:rect inView:controlView];
    [self setObjectValue:value];
    
    if (progressIndicator) {
        NSDivideRect(insetRect, &rect, &ignored, NSHeight([progressIndicator frame]), [controlView isFlipped] ? NSMaxYEdge : NSMinYEdge);
        [progressIndicator setFrame:rect];
        
        if ([progressIndicator isDescendantOf:controlView] == NO)
            [controlView addSubview:progressIndicator];
    } else { 
        NSFont *font = [[[self font] retain] autorelease];
        [self setFont:[[NSFontManager sharedFontManager] convertFont:font toSize:10.0]];
        [self setObjectValue:[self statusDescription]];
        NSDivideRect(insetRect, &rect, &ignored, [self cellSize].height, [controlView isFlipped] ? NSMaxYEdge : NSMinYEdge);
        [super drawWithFrame:rect inView:controlView];
        [self setObjectValue:value];
        [self setFont:font];
    }
}

- (id)accessibilityAttributeValue:(NSString *)attribute {
    if ([attribute isEqualToString:NSAccessibilityValueAttribute]) {
        NSString *statusDescription = [self statusDescription];
        if (statusDescription)
            return [[super accessibilityAttributeValue:attribute] stringByAppendingFormat:@"\n%@", statusDescription];
    }
    return [super accessibilityAttributeValue:attribute];
}

@end
