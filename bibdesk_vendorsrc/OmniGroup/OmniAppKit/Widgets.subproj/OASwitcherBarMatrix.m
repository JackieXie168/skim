// Copyright 2002-2004 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import "OASwitcherBarMatrix.h"
#import "OASwitcherBarButtonCell.h"

#import <OmniBase/rcsid.h>

RCS_ID("$Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniAppKit/Widgets.subproj/OASwitcherBarMatrix.m,v 1.5 2004/02/10 22:06:20 wiml Exp $");

@interface OASwitcherBarMatrix (Private)
- (void)_maintainFocusRing:(BOOL)subscribe deregister:(BOOL)unsubscribe;
@end

@implementation OASwitcherBarMatrix

- (void)dealloc
{
    if (switcherBarFlags.registeredForKeyNotifications) {
        NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
        [center removeObserver:self];
        switcherBarFlags.registeredForKeyNotifications = 0;
    }
    [super dealloc];
}

- (Class)cellClass;
{
    return [OASwitcherBarButtonCell class];
}

- (void)drawRect:(NSRect)rect;
{
    int row, column, rowCount, columnCount;

    if ([[self window] firstResponder] == self) {
        [NSGraphicsContext saveGraphicsState];
        NSSetFocusRingStyle(NSFocusRingOnly);
        NSRectFill([self bounds]); // Crude, but workable. How the heck do I get it to draw only around where the widget is opaque?
        [NSGraphicsContext restoreGraphicsState];
    }

    rowCount = [self numberOfRows];
    columnCount = [self numberOfColumns];
    for(row = 0; row < rowCount; row++) {
        for(column = 0; column < columnCount; column++) {
            NSRect cellFrame;
            OASwitcherBarButtonCell *cell;
            
            cellFrame = [self cellFrameAtRow:row column:column];
            cell = [self cellAtRow:row column:column];
            if (column == 0)
                [cell setCellLocation:OASwitcherBarLeft];
            else if (column == columnCount - 1)
                [cell setCellLocation:OASwitcherBarRight];
            else
                [cell setCellLocation:OASwitcherBarMiddle];

            [cell drawWithFrame:cellFrame inView:self];
        }
    }
}

//  Focus ring maintenance

- (BOOL)becomeFirstResponder;
{
    BOOL okToChange = [super becomeFirstResponder];
    [self _maintainFocusRing:okToChange deregister:NO];
    return okToChange;
}

- (BOOL)resignFirstResponder;
{
    BOOL okToChange = [super resignFirstResponder];
    [self _maintainFocusRing:NO deregister:okToChange];
    return okToChange;
}

- (void)windowKeyStateDidChange:(NSNotification *)notification;
{
    [self _maintainFocusRing:NO deregister:NO];
}

- (void)viewWillMoveToWindow:(NSWindow *)newWindow;
{
    [self _maintainFocusRing:NO deregister:YES];
    [super viewWillMoveToWindow:newWindow];
}

- (void)viewDidMoveToWindow;
{
    [super viewDidMoveToWindow];

    OBASSERT(!switcherBarFlags.registeredForKeyNotifications);
    
    if ([[self window] firstResponder] == self)
        [self _maintainFocusRing:YES deregister:NO];
}

- (BOOL)acceptsFirstResponder;
{
    return YES;		// Use me with the keyboard....
}

- (BOOL)needsPanelToBecomeKey;
{
    return NO;		// Clicking doesn't make us key, but tabbing to us will...
}

@end

@implementation OASwitcherBarMatrix (Private)

- (void)_maintainFocusRing:(BOOL)subscribe deregister:(BOOL)unsubscribe
{
    NSNotificationCenter *center;
    NSWindow *myWindow = [self window];

    if (myWindow != nil)
        [self setKeyboardFocusRingNeedsDisplayInRect: [self bounds]];

    center = [NSNotificationCenter defaultCenter];

    if (unsubscribe) {
        [center removeObserver:self name:NSWindowDidBecomeKeyNotification object:nil];
        [center removeObserver:self name:NSWindowDidResignKeyNotification object:nil];
        switcherBarFlags.registeredForKeyNotifications = 0;
    }

    if (subscribe && !switcherBarFlags.registeredForKeyNotifications) {
        if (myWindow != nil) {
            [center addObserver:self selector:@selector(windowKeyStateDidChange:) name:NSWindowDidBecomeKeyNotification object:myWindow];
            [center addObserver:self selector:@selector(windowKeyStateDidChange:) name:NSWindowDidResignKeyNotification object:myWindow];
            switcherBarFlags.registeredForKeyNotifications = 1;
        }
    }
}

@end

