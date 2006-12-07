// Copyright 2003-2005 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import "OAContextButton.h"

#import <AppKit/AppKit.h>
#import <OmniBase/OmniBase.h>
#import <OmniFoundation/OmniFoundation.h>

#import "NSImage-OAExtensions.h"
#import "OAContextControl.h"

RCS_ID("$Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/SourceRelease_2005-10-03/OmniGroup/Frameworks/OmniAppKit/Widgets.subproj/OAContextButton.m 68913 2005-10-03 19:36:19Z kc $");

@implementation OAContextButton

+ (NSImage *)actionImage;
{
    static NSImage *OAActionImage = nil;
    if (OAActionImage == nil) {
        OAActionImage = [[NSImage imageNamed:@"OAAction" inBundleForClass:[OAContextButton class]] retain];
        OBASSERT(OAActionImage != nil);
    }

    return OAActionImage;
}

+ (NSImage *)miniActionImage;
{
    static NSImage *OAMiniActionImage = nil;
    if (OAMiniActionImage == nil) {
        OAMiniActionImage = [[NSImage imageNamed:@"OAMiniAction" inBundleForClass:[OAContextButton class]] retain];
        OBASSERT(OAMiniActionImage != nil);
    }

    return OAMiniActionImage;
}

- (id)initWithFrame:(NSRect)frameRect;
{
    if ([super initWithFrame:frameRect] == nil)
        return nil;

    [self setImagePosition:NSImageOnly];
    [self setBordered:NO];
    [self setButtonType:NSMomentaryPushInButton];
    [self setImage:[OAContextButton actionImage]];
    [self setToolTip:OAContextControlToolTip()];
    
    return self;
}

- (void)awakeFromNib
{
    if ([self image] == nil) {
        if ([[self cell] controlSize] == NSSmallControlSize)
            [self setImage:[OAContextButton miniActionImage]];
        else
            [self setImage:[OAContextButton actionImage]];
    }
    if ([NSString isEmptyString:[self toolTip]])
        [self setToolTip:OAContextControlToolTip()];
}

//
// NSView subclass
//
- (void)mouseDown:(NSEvent *)event;
{
    if (![self isEnabled])
        return;

    NSView *targetView;
    NSMenu *menu;
    OAContextControlGetMenu(delegate, self, &menu, &targetView);

    if (targetView == nil)
        menu = OAContextControlNoActionsMenu();
    
    NSPoint eventLocation = [self frame].origin;
    eventLocation = [[self superview] convertPoint:eventLocation toView:nil];
    if ([[[self window] contentView] isFlipped])
        eventLocation.y += 3;
    else
        eventLocation.y -= 3;
        
    [[self cell] setHighlighted:YES];
        
    NSEvent *simulatedEvent = [NSEvent mouseEventWithType:NSLeftMouseDown location:eventLocation modifierFlags:[event modifierFlags] timestamp:[event timestamp] windowNumber:[event windowNumber] context:[event context] eventNumber:[event eventNumber] clickCount:[event clickCount] pressure:[event pressure]];
    [NSMenu popUpContextMenu:menu withEvent:simulatedEvent forView:targetView];

    [[self cell] setHighlighted:NO];
}

//
// API
//

/*" Returns the menu to be used, or nil if no menu can be found. "*/
- (NSMenu *)locateActionMenu;
{
    NSMenu *menu;
    OAContextControlGetMenu(delegate, self, &menu, NULL);
    return menu;
}

/*" Returns YES if the receiver can find a menu to pop up.  Useful if you have an instance in a toolbar and wish to validate whether it can pop up anything. "*/
- (BOOL)validate;
{
    return ([self locateActionMenu] != nil);
}

@end
