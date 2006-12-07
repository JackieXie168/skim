// Copyright 2000-2004 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import <OmniAppKit/OAWindowCascade.h>

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <OmniBase/OmniBase.h>
#import <OmniFoundation/OmniFoundation.h>

RCS_ID("$Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniAppKit/Widgets.subproj/OAWindowCascade.m,v 1.19 2004/02/10 04:07:39 kc Exp $")

// #define DEBUG_CASCADE
#define WINDOW_TILE_STEP (20.0)
#define AVOID_INSET (8.0)
#define MAXIMUM_TRIES (200.0)

@interface OAWindowCascade (Private)
+ (NSScreen *)_screenForPoint:(NSPoint)aPoint;
+ (NSRect)_adjustWindowRect:(NSRect)windowRect forScreenRect:(NSRect)screenRect;
@end

@implementation OAWindowCascade

- (NSRect)nextWindowFrameFromStartingFrame:(NSRect)startingFrame avoidingWindows:(NSArray *)windowsToAvoid;
{
    NSScreen *screen;
    NSRect screenRect;
    NSRect firstFrame, nextWindowFrame;
    NSRect avoidRect, availableRect;
    unsigned int windowIndex;
    NSWindow *window;
    BOOL restartedAlready = NO;
    unsigned int triesRemaining = MAXIMUM_TRIES; // Let's just be absolutely certain we can't loop forever

    // Is the starting frame the same as last time?  If so, tile
    if (!NSEqualRects(startingFrame, lastStartingFrame)) {
        lastStartingFrame = startingFrame;
        firstFrame = startingFrame;
    } else {
        firstFrame.size = lastStartingFrame.size;
        firstFrame.origin = lastWindowOrigin;
        firstFrame.origin.x += WINDOW_TILE_STEP;
        firstFrame.origin.y -= WINDOW_TILE_STEP;
    }

    screen = [OAWindowCascade _screenForPoint:startingFrame.origin];
    screenRect = [screen visibleFrame];
    // Adjust the starting frame to fit on the screen
    startingFrame = [isa _adjustWindowRect:startingFrame forScreenRect:screenRect];
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"OAWindowCascadeDisabled"])
        return startingFrame;

    // Trim the available rect down based on the windows to avoid
    availableRect = screenRect;
    windowIndex = [windowsToAvoid count];
#ifdef DEBUG_CASCADE
    NSLog(@"Avoiding %d windows", windowIndex);
#endif
    while (windowIndex--) {
        window = [windowsToAvoid objectAtIndex:windowIndex];
        if (![window isVisible] || [window screen] != screen)
            continue;
        avoidRect = [window frame];
        // Don't position ourselves exactly adjacent to windows we're avoiding
        NSInsetRect(availableRect, -AVOID_INSET, -AVOID_INSET);
        availableRect = OFLargestRectAvoidingRectAndFitSize(availableRect, avoidRect, startingFrame.size);
#ifdef DEBUG_CASCADE
        NSLog(@"Avoid rect = %@", NSStringFromRect(avoidRect));
        NSLog(@"Available rect = %@", NSStringFromRect(availableRect));
#endif
    }
    
    // If we can't avoid them all, let's not bother trying to avoid any
    if (NSHeight(availableRect) < NSHeight(startingFrame) || NSWidth(availableRect) < NSWidth(startingFrame)) {
#ifdef DEBUG_CASCADE
        NSLog(@"Rect too small -- don't avoid anything");
#endif
        availableRect = screenRect;
    }
    
    // Tile inside the available rect.  Two calls to this function across movement of the windows to avoid might produce discontinuous tilings.  That should be pretty rare, though.

#ifdef DEBUG_CASCADE
    NSLog(@"availableRect = %@", NSStringFromRect(availableRect));
#endif
    nextWindowFrame = firstFrame;
#ifdef DEBUG_CASCADE
    NSLog(@"Start rect = %@", NSStringFromRect(nextWindowFrame));
#endif
    while (!NSContainsRect(availableRect, nextWindowFrame)) {
        if (triesRemaining-- == 0) {
            // Reset and abort
            nextWindowFrame = firstFrame;
            break;
        }

        // If we're too far to the right, start at the left
        if (NSMaxX(nextWindowFrame) > NSMaxX(availableRect)) {
            // Too far to the right, start over
            if (restartedAlready) {
                // No good options, so let's just go back to the first frame
                nextWindowFrame = firstFrame;
#ifdef DEBUG_CASCADE
                NSLog(@"Restarted already, abort: %@", NSStringFromRect(nextWindowFrame));
#endif
                break;
            } else {
                // Try again from the start
                restartedAlready = YES;
                nextWindowFrame.origin.x = availableRect.origin.x;
                nextWindowFrame.origin.y = startingFrame.origin.y;
#ifdef DEBUG_CASCADE
                NSLog(@"Back to start: %@", NSStringFromRect(nextWindowFrame));
#endif
            }
        } else if (NSMinY(nextWindowFrame) < NSMinY(availableRect)) {
            // Too far down: start from the top
            nextWindowFrame.origin.y = startingFrame.origin.y;
#ifdef DEBUG_CASCADE
            NSLog(@"Back to top: %@", NSStringFromRect(nextWindowFrame));
#endif
        } else {
            // Move down and to the right, then try again
            nextWindowFrame.origin.x += WINDOW_TILE_STEP;
            nextWindowFrame.origin.y -= WINDOW_TILE_STEP;
#ifdef DEBUG_CASCADE
            NSLog(@"Step: %@", NSStringFromRect(nextWindowFrame));
#endif
        }
    }
    nextWindowFrame = [isa _adjustWindowRect:nextWindowFrame forScreenRect:screenRect];
#ifdef DEBUG_CASCADE
    NSLog(@"Result rect = %@", NSStringFromRect(nextWindowFrame));
#endif
    lastWindowOrigin = nextWindowFrame.origin;
    return nextWindowFrame;
}

- (void)reset;
{
    lastStartingFrame = NSZeroRect;
}

@end

@implementation OAWindowCascade (Private)

+ (NSScreen *)_screenForPoint:(NSPoint)aPoint;
{
    NSArray *screens;
    unsigned int screenIndex, screenCount;
    
    screens = [NSScreen screens];
    screenCount = [screens count];
    for (screenIndex = 0; screenIndex < screenCount; screenIndex++) {
        NSScreen *screen;

        screen = [screens objectAtIndex:screenIndex];
        if (NSPointInRect(aPoint, [screen frame]))
            return screen;
    }
    return [NSScreen mainScreen];
}

+ (NSRect)_adjustWindowRect:(NSRect)windowRect forScreenRect:(NSRect)screenRect;
{
    // Adjust the window rect to fit on the screen
    if (NSHeight(windowRect) > NSHeight(screenRect))
        windowRect.size.height = NSHeight(screenRect);
    if (NSMinY(windowRect) < NSMinY(screenRect))
        windowRect.origin.y = NSMinY(screenRect);
    if (NSMaxY(windowRect) > NSMaxY(screenRect))
        windowRect.origin.y = NSMaxY(screenRect) - NSHeight(windowRect);
    if (NSWidth(windowRect) > NSWidth(screenRect))
        windowRect.size.width = NSWidth(screenRect);
    if (NSMaxX(windowRect) > NSMaxX(screenRect))
        windowRect.origin.x = NSMaxX(screenRect) - NSWidth(windowRect);
    if (NSMinX(windowRect) < NSMinX(screenRect))
        windowRect.origin.x = NSMinX(screenRect);
    return windowRect;
}

@end
