// Copyright 1997-2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniAppKit/Widgets.subproj/OAProgressView.h,v 1.12 2003/01/15 22:51:44 kc Exp $

#import <AppKit/NSView.h>

@class NSString;
@class NSColor, NSFont;

@interface OAProgressView : NSView
{
    unsigned int progress;
    unsigned int total;
    struct {
        unsigned int validTotal:1;
        unsigned int validProgress:1;
        unsigned int turnedOff:1;
    } flags;
    NSImage *gaugeImage, *barberImage, *noProgressImage;
}

- (void)turnOff;
    // Turn off the progress view

- (void)processedBytes:(unsigned int)amount;
    // Use NSNotFound for undefined amount
- (void)processedBytes:(unsigned int)amount ofBytes:(unsigned int)total;

@end
