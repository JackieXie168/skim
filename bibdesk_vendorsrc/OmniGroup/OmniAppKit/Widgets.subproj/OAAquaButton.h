// Copyright 2000-2005 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/OmniSourceRelease_2006-09-07/OmniGroup/Frameworks/OmniAppKit/Widgets.subproj/OAAquaButton.h 68913 2005-10-03 19:36:19Z kc $

#import <AppKit/NSButton.h>
#import <OmniAppKit/FrameworkDefines.h>

@class NSBundle; // Foundation

@interface OAAquaButton : NSButton
{
    NSImage *clearImage;
    NSImage *aquaImage;
    NSImage *graphiteImage;
}

- (void)setImageName:(NSString *)anImageName inBundle:(NSBundle *)aBundle;
    // The image named anImageName will be used for the normal state of the button.  The alternate image of the button will be the image named anImageName with either "Aqua" or "Graphite" appended to it.
    
@end

OmniAppKit_EXTERN NSString *OAAquaButtonAquaImageSuffix;	// "Aqua"
OmniAppKit_EXTERN NSString *OAAquaButtonGraphiteImageSuffix;	// "Graphite"

//
// Control tint utilities
//

typedef enum {
    OAUndefinedTint, OAAquaTint, OAGraphiteTint,
} OAControlTint;

OmniAppKit_EXTERN OAControlTint OACurrentControlTint();
OmniAppKit_EXTERN NSString *OAControlTintDidChangeNotification;
