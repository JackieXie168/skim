// Copyright 2003-2004 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import "OAContextButton.h"

#import <AppKit/AppKit.h>
#import <OmniBase/OmniBase.h>

#import "NSImage-OAExtensions.h"

RCS_ID("$Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniAppKit/Widgets.subproj/OAContextButton.m,v 1.14 2004/02/10 04:07:37 kc Exp $");

@interface OAContextButton (PrivateAPI)
- (void)_getMenu:(NSMenu **)outMenu targetView:(NSView **)outTargetView;
@end

@implementation OAContextButton

+ (NSImage *)actionImage;
{
    static NSImage *OAActionImage = nil;
    if (OAActionImage == nil) {
        OAActionImage = [[NSImage imageNamed:@"OAAction" inBundleForClass:self] retain];
        OBASSERT(OAActionImage != nil);
    }

    return OAActionImage;
}

+ (NSImage *)miniActionImage;
{
    static NSImage *OAMiniActionImage = nil;
    if (OAMiniActionImage == nil) {
        OAMiniActionImage = [[NSImage imageNamed:@"OAMiniAction" inBundleForClass:self] retain];
        OBASSERT(OAMiniActionImage != nil);
    }

    return OAMiniActionImage;
}

+ (NSMenu *)noActionsMenu;
{
    static NSMenu *noActionsMenu = nil;
    if (noActionsMenu == nil) {
        NSString *title = NSLocalizedStringFromTableInBundle(@"No Actions Available", @"OmniAppKit", [OAContextButton bundle], @"menu title");
        noActionsMenu = [[NSMenu alloc] initWithTitle:title];
        [noActionsMenu addItemWithTitle:title action:NULL keyEquivalent:@""];
    }
    return noActionsMenu;
}

- (id)initWithFrame:(NSRect)frameRect;
{
    if ([super initWithFrame:frameRect] == nil)
        return nil;
    
    [self setImage:[OAContextButton actionImage]];
    
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
    [self _getMenu:&menu targetView:&targetView];

    if (targetView == nil)
        menu = [OAContextButton noActionsMenu];
    
    NSPoint eventLocation = [self frame].origin;
    eventLocation = [[self superview] convertPoint:eventLocation toView:nil];
    if ([[[self window] contentView] isFlipped])
        eventLocation.y += 3;
    else
        eventLocation.y -= 3;
        
    NSEvent *simulatedEvent = [NSEvent mouseEventWithType:NSLeftMouseDown location:eventLocation modifierFlags:[event modifierFlags] timestamp:[event timestamp] windowNumber:[event windowNumber] context:[event context] eventNumber:[event eventNumber] clickCount:[event clickCount] pressure:[event pressure]];
    [NSMenu popUpContextMenu:menu withEvent:simulatedEvent forView:targetView];
}

//
// API
//

/*" Returns YES if the receiver can find a menu to pop up.  Useful if you have an instance in a toolbar and wish to validate whether it can pop up anything. "*/
- (BOOL)validate;
{
    NSMenu *menu;
    [self _getMenu:&menu targetView:NULL];
    return menu != nil;
}

@end

@implementation OAContextButton (PrivateAPI)

- (void)_getMenu:(NSMenu **)outMenu targetView:(NSView **)outTargetView;
{
    NSMenu *menu = nil;
    NSView *targetView = nil;

    if (delegate) {
        // The delegate must respond to both
        targetView = [delegate targetViewForContextButton:self];
        menu       = [delegate menuForContextButton:self];
    } else {
        // TODO: Check if any of the menu items in the resulting menu are valid?

        id target = [NSApp targetForAction:@selector(menuForContextButton:)];
        if (target) {
            if ([target isKindOfClass:[NSView class]]) {
                targetView = target;
                menu       = [targetView menuForContextButton:self];
            } else {
                // Not a view, must respond to both
                targetView = [target targetViewForContextButton:self];
                menu       = [target menuForContextButton:self];
            }
        } else if ((target = [NSApp targetForAction:@selector(menu)])) {
            if ([target isKindOfClass:[NSView class]]) {
                targetView = target;
                menu       = [targetView menu];
            } else {
                // This can happen when the responder we get to -menu is NSApp
            }
        }
    }

    if (outMenu)
        *outMenu = menu;
    if (outTargetView)
        *outTargetView = targetView;
}

@end

