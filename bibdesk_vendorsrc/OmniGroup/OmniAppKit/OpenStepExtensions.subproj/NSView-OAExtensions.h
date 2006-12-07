// Copyright 1997-2005 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/SourceRelease_2005-10-03/OmniGroup/Frameworks/OmniAppKit/OpenStepExtensions.subproj/NSView-OAExtensions.h 68913 2005-10-03 19:36:19Z kc $

#import <AppKit/NSView.h>

#import <Foundation/NSDate.h>

@class NSBitmapImageRep, NSFont;

typedef enum _OAImageSlideDirection {
    OALeftSlideDirection,
    OARightSlideDirection,
    OAUpSlideDirection,
    OADownSlideDirection
} OAImageSlideDirection;

@interface NSView (OAExtensions)

// Drawing
+ (void)drawRoundedRect:(NSRect)rect cornerRadius:(float)radius color:(NSColor *)color isFilled:(BOOL)isFilled;
- (void)drawRoundedRect:(NSRect)rect cornerRadius:(float)radius color:(NSColor *)color;
- (void)drawHorizontalSelectionInRect:(NSRect)rect;
- (void)drawSelfAndSubviewsInRect:(NSRect)rect;

// Scrolling (deferred)
+ (void)performDeferredScrolling;
    // Scheduled automatically, can call to scroll immediately
- (void)scrollDownByAdjustedPixels:(float)pixels;
- (void)scrollRightByAdjustedPixels:(float)pixels;

// Scrolling (convenience)
- (void)scrollToTop;
- (void)scrollToEnd;

- (void)scrollDownByPages:(float)pagesToScroll;
- (void)scrollDownByLines:(float)linesToScroll;
- (void)scrollDownByPercentage:(float)percentage;

- (void)scrollRightByPages:(float)pagesToScroll;
- (void)scrollRightByLines:(float)linesToScroll;
- (void)scrollRightByPercentage:(float)percentage;

- (NSPoint)scrollPositionAsPercentage;
- (void)setScrollPositionAsPercentage:(NSPoint)scrollPosition;

- (float)fraction;
    // Deprecated:  Use -scrollPositionAsPercentage
- (void)setFraction:(float)fraction;
    // Deprecated:  Use -setScrollPositionAsPercentage:

// Dragging
- (BOOL)shouldStartDragFromMouseDownEvent:(NSEvent *)event dragSlop:(float)dragSlop finalEvent:(NSEvent **)finalEventPointer timeoutDate:(NSDate *)timeoutDate;
- (BOOL)shouldStartDragFromMouseDownEvent:(NSEvent *)event dragSlop:(float)dragSlop finalEvent:(NSEvent **)finalEventPointer timeoutInterval:(NSTimeInterval)timeoutInterval;
- (BOOL)shouldStartDragFromMouseDownEvent:(NSEvent *)event dragSlop:(float)dragSlop finalEvent:(NSEvent **)finalEventPointer;

// Resizing
- (void)morphToFrame:(NSRect)newFrame overTimeInterval:(NSTimeInterval)morphInterval;

// View fade in/out
- (void)fadeInSubview:(NSView *)subview overTimeInterval:(NSTimeInterval)fadeInterval;
- (void)fadeOutAndRemoveFromSuperviewOverTimeInterval:(NSTimeInterval)fadeInterval;

- (NSBitmapImageRep *)bitmapForRect:(NSRect)rect;
    // Note: This does not include subviews
- (NSImage *)imageForRect:(NSRect)rect;

// Debugging
- (void)logViewHierarchy;

@end
