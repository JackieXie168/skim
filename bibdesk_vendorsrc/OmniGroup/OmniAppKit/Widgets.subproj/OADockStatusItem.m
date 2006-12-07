// Copyright 2001-2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.

#import "OADockStatusItem.h"

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <OmniBase/OmniBase.h>
#import <OmniAppKit/NSImage-OAExtensions.h>

RCS_ID("$Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniAppKit/Widgets.subproj/OADockStatusItem.m,v 1.11 2003/01/15 22:51:43 kc Exp $")

@interface OADockStatusItem (private)
+ (void)registerItem:(OADockStatusItem *)item;
+ (void)unregisterItem:(OADockStatusItem *)item;
+ (void)redisplay;
- (void)drawDockStatusItemOnApplicationIcon:(NSImage *)applicationIcon;
@end

@implementation OADockStatusItem

static NSImage *leftBackgroundImage, *centerBackgroundImage, *rightBackgroundImage;

+ (void)initialize;
{
    OBINITIALIZE;

    leftBackgroundImage = [NSImage imageNamed:@"OADockStatusItemLeft" inBundleForClass:self];
    OBASSERT(leftBackgroundImage);
    centerBackgroundImage = [NSImage imageNamed:@"OADockStatusItemCenter" inBundleForClass:self];
    OBASSERT(centerBackgroundImage);
    rightBackgroundImage = [NSImage imageNamed:@"OADockStatusItemRight" inBundleForClass:self];
    OBASSERT(rightBackgroundImage);
}

- init;
{
    if ([super init] == nil)
        return nil;
    
    count = NSNotFound;
    isHidden = YES;
    
    [isa registerItem:self];
    return self;
}

- initWithIcon:(NSImage *)newIcon;
{
    if ([self init] == nil)
        return nil;

    icon = [newIcon retain];
    
    return self;
}


- (void)dealloc;
{
    [icon release];
    [isa unregisterItem:self];
    if (!isHidden)
        [isa redisplay];
}

// API

- (void)setCount:(unsigned int)aCount;
{
    if (count == aCount)
        return;
    count = aCount;
    if (!isHidden)
        [isa redisplay];
}

- (void)setNoCount;
{
    [self setCount:NSNotFound];
}

- (void)hide;
{
    if (isHidden)
        return;

    isHidden = YES;
    [isa redisplay];
}

- (void)show;
{
    if (!isHidden)
        return;

    isHidden = NO;
    [isa redisplay];
}

- (BOOL)isHidden;
{
    return isHidden;
}

@end

@implementation OADockStatusItem (private)

static NSMutableArray *dockStatusItems;

+ (void)registerItem:(OADockStatusItem *)item;
{
    if (!dockStatusItems)
        dockStatusItems = [[NSMutableArray alloc] init];

    [dockStatusItems addObject:[NSValue valueWithNonretainedObject:item]];
}

+ (void)unregisterItem:(OADockStatusItem *)item;
{
    unsigned int index;

    index = [dockStatusItems count];
    while (index--) {
        if ([[dockStatusItems objectAtIndex:index] nonretainedObjectValue] == item) {
            [dockStatusItems removeObjectAtIndex:index];
            break;
        }
    }
}


+ (void)redisplay;
{
    NSImage *applicationIcon, *bufferImage;
    unsigned int index;

    applicationIcon = [NSImage imageNamed:@"NSApplicationIcon"];

    bufferImage = [[NSImage alloc] initWithSize:[applicationIcon size]];
    [bufferImage setFlipped:YES];
    [bufferImage lockFocus]; {
        [applicationIcon compositeToPoint:NSMakePoint(0, [bufferImage size].height) operation:NSCompositeSourceOver];

        index = [dockStatusItems count];
        while(index--)
            [[[dockStatusItems objectAtIndex:index] nonretainedObjectValue] drawDockStatusItemOnApplicationIcon:applicationIcon];
    } [bufferImage unlockFocus];
    
    [NSApp setApplicationIconImage:bufferImage];
    [bufferImage autorelease];
}

- (void)drawDockStatusItemOnApplicationIcon:(NSImage *)applicationIcon;
{
    const float edgePadding = 12.0;
    NSString *string = nil;
    NSDictionary *stringAttributes = nil;
    NSSize applicationIconSize, textSize = NSZeroSize, iconSize = NSZeroSize;
    NSSize leftBackgroundSize, centerBackgroundSize, rightBackgroundSize, backgroundSize;
    float minimumWidth;
    NSPoint lowerLeftPoint;
    float currentBackgroundX, backgroundWidthToDraw;

    // TJW: It is not valid to send struct messages (or floats for that matter) to nil, so these must be non-nil (and I've actually been hit by them not being nil somehow).
    OBPRECONDITION(leftBackgroundImage);
    OBPRECONDITION(centerBackgroundImage);
    OBPRECONDITION(rightBackgroundImage);

    if (isHidden)
        return;

    // TJW: Also adding a runtime check for this since I haven't been able to track down why these images were nil
    if (!leftBackgroundImage || !centerBackgroundImage || !rightBackgroundImage) {
        NSLog(@"OADockStatusItem: Required background image is nil!");
        return;
    }
    
    leftBackgroundSize = [leftBackgroundImage size];
    centerBackgroundSize = [centerBackgroundImage size];
    rightBackgroundSize = [rightBackgroundImage size];

    if (count > 0 && count != NSNotFound) {
        NSFont *font;
        
        string = [NSString stringWithFormat:@"%d", count];
        font = [NSFont boldSystemFontOfSize:floor(centerBackgroundSize.height * 0.625)];
        stringAttributes = [NSDictionary dictionaryWithObjectsAndKeys:font, NSFontAttributeName, nil];
        textSize = [string sizeWithAttributes:stringAttributes];
    }

    if (icon != nil)
        iconSize = [icon size];

    applicationIconSize = [applicationIcon size];

    minimumWidth = textSize.width + iconSize.width + 2 * edgePadding;
    if (minimumWidth > applicationIconSize.width) {
        // Too darn wide? Drop the icon.
        iconSize = NSZeroSize;
        minimumWidth = textSize.width + 2 * edgePadding;
    }

    backgroundSize = NSMakeSize(MAX(leftBackgroundSize.width + rightBackgroundSize.width, minimumWidth), centerBackgroundSize.height);

    // Draw background (the translucent white oval)
    lowerLeftPoint = NSMakePoint(applicationIconSize.width - backgroundSize.width, applicationIconSize.height);
    [leftBackgroundImage compositeToPoint:lowerLeftPoint operation:NSCompositeSourceOver];

    currentBackgroundX = lowerLeftPoint.x + leftBackgroundSize.width;
    for (backgroundWidthToDraw = backgroundSize.width - (leftBackgroundSize.width + rightBackgroundSize.width); backgroundWidthToDraw > 0; backgroundWidthToDraw -= centerBackgroundSize.width) {
        [centerBackgroundImage compositeToPoint:NSMakePoint(currentBackgroundX, lowerLeftPoint.y) fromRect:NSMakeRect(0, 0, MIN(centerBackgroundSize.width, backgroundWidthToDraw), centerBackgroundSize.height) operation:NSCompositeSourceOver];
        currentBackgroundX += centerBackgroundSize.width;
    }

    [rightBackgroundImage compositeToPoint:NSMakePoint(applicationIconSize.width - [rightBackgroundImage size].width, lowerLeftPoint.y) operation:NSCompositeSourceOver];

    // Draw icon (eg, the OmniWeb green zap)
    lowerLeftPoint.x = lowerLeftPoint.x + ceil((backgroundSize.width - (textSize.width + iconSize.width)) / 2.0);
    if (iconSize.width > 0.0)
        [icon compositeToPoint:NSMakePoint(lowerLeftPoint.x, lowerLeftPoint.y - floor((backgroundSize.height - iconSize.height)/2.0)) operation:NSCompositeSourceOver];

    // Draw number to the right of icon (eg, "29")
    if (string != nil)
        [string drawAtPoint:NSMakePoint(lowerLeftPoint.x + iconSize.width, lowerLeftPoint.y - textSize.height - floor((backgroundSize.height - textSize.height)/2.0)) withAttributes:stringAttributes];
}

@end
