// Copyright 2000-2006 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import <OmniAppKit/OAAquaButton.h>

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <OmniBase/OmniBase.h>
#import <OmniFoundation/OmniFoundation.h>
#import <OmniAppKit/NSImage-OAExtensions.h>

RCS_ID("$Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/OmniSourceRelease_2006-09-07/OmniGroup/Frameworks/OmniAppKit/Widgets.subproj/OAAquaButton.m 79079 2006-09-07 22:35:32Z kc $")

@interface OAAquaButton (PrivateAPI)
- (void)_setButtonImages;
- (NSImage *)_imageForCurrentControlTint;
@end

NSString *OAControlTintDidChangeNotification = @"OAControlTintDidChangeNotification";
NSString *OAAquaButtonAquaImageSuffix = @"Aqua";
NSString *OAAquaButtonGraphiteImageSuffix = @"Graphite";

@implementation OAAquaButton

+ (void)didLoad;
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_controlTintChanged:) name:NSControlTintDidChangeNotification object:nil];
}

- (id)initWithFrame:(NSRect)frameRect;
{
    if (![super initWithFrame:frameRect])
        return nil;

    [self setButtonType:NSMomentaryLightButton];
    [self setImagePosition:NSImageOnly];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_controlTintChanged:) name:OAControlTintDidChangeNotification object:nil];
    
    return self;
}

- (void)dealloc;
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [clearImage release];
    [aquaImage release];
    [graphiteImage release];
    
    [super dealloc];
}

//
// NSButton subclass
//

- (void)setState:(int)value;
{
    [super setState:value];
    [self _setButtonImages];
}

- (void)setImageName:(NSString *)anImageName inBundle:(NSBundle *)aBundle;
{
    [clearImage release];
    [aquaImage release];
    [graphiteImage release];
    clearImage = [[NSImage imageNamed:anImageName inBundle:aBundle] retain];
    aquaImage = [[NSImage imageNamed:[anImageName stringByAppendingString:OAAquaButtonAquaImageSuffix] inBundle:aBundle] retain];
    graphiteImage = [[NSImage imageNamed:[anImageName stringByAppendingString:OAAquaButtonGraphiteImageSuffix] inBundle:aBundle] retain];
    
    [self _setButtonImages];
}

@end

@implementation OAAquaButton (PrivateAPI)

static volatile int cachedTint = OAUndefinedTint;

+ (void)_controlTintChanged:(NSNotification *)notification;
{
    cachedTint = OAUndefinedTint;
    [[NSNotificationCenter defaultCenter] postNotificationName:OAControlTintDidChangeNotification object:nil];
}

- (void)_controlTintChanged:(NSNotification *)notification;
{
    [self _setButtonImages];
}

// Sets the image and alternate image as appropriate (if state != 0, image is set to the "On" image)
- (void)_setButtonImages;
{
    if ([self state] == 0) {
        [self setImage:clearImage];
        [self setAlternateImage:[self _imageForCurrentControlTint]];
    } else {
        [self setImage:[self _imageForCurrentControlTint]];
        [self setAlternateImage:clearImage];
    }
}

// Returns the "On" image for the current control tint
- (NSImage *)_imageForCurrentControlTint;
{
    return (OACurrentControlTint() == OAGraphiteTint ? graphiteImage : aquaImage);
}

OAControlTint OACurrentControlTint()
{
    int currentTint;
    
    currentTint = cachedTint;
    if (currentTint == OAUndefinedTint) {
        NSColor *controlTintRGBColor;
        float hue = 0.0, saturation = 0.0, brightness = 0.0, alpha = 0.0;
    
        controlTintRGBColor = [[NSColor colorForControlTint:NSDefaultControlTint] colorUsingColorSpaceName:NSDeviceRGBColorSpace];
        [controlTintRGBColor getHue:&hue saturation:&saturation brightness:&brightness alpha:&alpha];
        if (alpha == 0.0) // Color values bogus, use default
            currentTint = OAAquaTint;
        else if (saturation < 0.1)
            currentTint = OAGraphiteTint; // Graphite: hue=0.595238, saturation=0.087500, brightness=0.800000
        else
            currentTint = OAAquaTint; // Aqua: hue=0.583333, saturation=0.329670, brightness=0.910000
        cachedTint = currentTint;
    }
    return currentTint;
}

@end
