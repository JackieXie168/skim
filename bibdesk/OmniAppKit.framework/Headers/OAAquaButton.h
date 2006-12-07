// Copyright 2000-2002 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.
//
// $Header$

#import <AppKit/NSButton.h>

@interface OAAquaButton : NSButton
{
    NSImage *aquaImage;
    NSImage *graphiteImage;
    NSImage *clearImage;
}

@end

@interface OAAquaButton (SubclassesOnly)
- (void)cacheImages;
@end

#import <OmniAppKit/FrameworkDefines.h>

typedef enum {
    OAUndefinedTint, OAAquaTint, OAGraphiteTint,
} OAControlTint;

OmniAppKit_EXTERN OAControlTint OACurrentControlTint();
OmniAppKit_EXTERN NSString *OAControlTintDidChangeNotification;
OmniAppKit_EXTERN NSString *OAAquaGraphiteSuffix;
