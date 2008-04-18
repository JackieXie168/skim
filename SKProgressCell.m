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

- (void)dealloc {
    [progressIndicator release];
    [super dealloc];
}

- (id)copyWithZone:(NSZone *)aZone {
    SKProgressCell *copy = [super copyWithZone:aZone];
    copy->progressIndicator = [progressIndicator retain];
    copy->status = status;
    return copy;
}

- (NSProgressIndicator *)progressIndicator {
    return progressIndicator;
}

- (void)setProgressIndicator:(NSProgressIndicator *)newProgressIndicator {
    if (progressIndicator != newProgressIndicator) {
        [progressIndicator release];
        progressIndicator = [newProgressIndicator retain];
    }
}

- (int)status {
    return status;
}

- (void)setStatus:(int)newStatus {
    if (status != newStatus) {
        status = newStatus;
    }
}

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
    NSRect textRect = NSInsetRect(cellFrame, MARGIN_X, 0.0);
    
    textRect.size.height = [self cellSize].height;
    if ([controlView isFlipped])
        textRect.origin.y = NSMaxY(cellFrame) - NSHeight(textRect);
    [super drawWithFrame:textRect inView:controlView];
    
    if (progressIndicator) {
        NSRect barRect = NSInsetRect(cellFrame, MARGIN_X, 0.0);
        barRect.size.height = NSHeight([progressIndicator frame]);
        if ([controlView isFlipped])
            barRect.origin.y += MARGIN_Y;
        else
            barRect.origin.y = NSMaxY(cellFrame) - NSHeight(barRect) - MARGIN_Y;
        [progressIndicator setFrame:barRect];
        
        if ([progressIndicator isDescendantOf:controlView] == NO)
            [controlView addSubview:progressIndicator];
    } else { 
        if ([controlView isFlipped])
            textRect.origin.y = NSMinY(cellFrame);
        else
            textRect.origin.y = NSMaxY(cellFrame) - NSHeight(textRect);
        id value = [[[self objectValue] retain] autorelease];
        NSString *string = nil;
        switch (status) {
            case SKDownloadStatusStarting:
                string = [NSLocalizedString(@"Starting", @"Download status message") stringByAppendingEllipsis];
                break;
            case SKDownloadStatusFinished:
                string = NSLocalizedString(@"Finished", @"Download status message");
                break;
            case SKDownloadStatusFailed:
                string = NSLocalizedString(@"Failed", @"Download status message");
                break;
            case SKDownloadStatusCanceled:
                string = NSLocalizedString(@"Canceled", @"Download status message");
                break;
        }
        [self setObjectValue:string];
        [super drawWithFrame:textRect inView:controlView];
        [self setObjectValue:value];
    }
}

- (id)accessibilityAttributeValue:(NSString *)attribute {
    if ([attribute isEqualToString:NSAccessibilityValueAttribute] && progressIndicator == nil) {
        NSString *string = nil;
        switch (status) {
            case SKDownloadStatusStarting:
                string = [NSLocalizedString(@"Starting", @"Download status message") stringByAppendingEllipsis];
                break;
            case SKDownloadStatusFinished:
                string = NSLocalizedString(@"Finished", @"Download status message");
                break;
            case SKDownloadStatusFailed:
                string = NSLocalizedString(@"Failed", @"Download status message");
                break;
            case SKDownloadStatusCanceled:
                string = NSLocalizedString(@"Canceled", @"Download status message");
                break;
        }
        return [[super accessibilityAttributeValue:attribute] stringByAppendingFormat:@"\n%@", string];
    } else {
        return [super accessibilityAttributeValue:attribute];
    }
}

@end
