// Copyright 1997-2004 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import <OmniAppKit/NSWindow-OAExtensions.h>

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <OmniBase/OmniBase.h>
#import <OmniFoundation/OmniFoundation.h>

RCS_ID("$Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniAppKit/OpenStepExtensions.subproj/NSWindow-OAExtensions.m,v 1.27 2004/02/10 04:07:35 kc Exp $")


static void (*oldMakeKeyAndOrderFront)(id self, SEL _cmd, id sender);
static void (*oldDealloc)(id self, SEL _cmd);
#ifdef OMNI_ASSERTIONS_ON
static void (*oldSetTitle)(id self, SEL _cmd, NSString *title);
#endif
static NSWindow *becomingKeyWindow = nil;

@interface NSWindow (CarbonControl)
- (WindowRef)_windowRef;
@end

@implementation NSWindow (OAExtensions)

+ (void)performPosing;
{
    oldMakeKeyAndOrderFront = (void *)OBReplaceMethodImplementationWithSelector(self, @selector(makeKeyAndOrderFront:), @selector(replacement_makeKeyAndOrderFront:));
//    oldDealloc = (void *)OBReplaceMethodImplementationWithSelector(self, @selector(dealloc), @selector(replacement_dealloc));
    
#ifdef OMNI_ASSERTIONS_ON
    oldSetTitle = (void *)OBReplaceMethodImplementationWithSelector(self, @selector(setTitle:), @selector(replacement_setTitle:));
#endif
}

static NSMutableArray *zOrder;

- (BOOL)_addToZOrderArray;
{
    [zOrder addObject:self];
    return NO;
}

+ (NSArray *)windowsInZOrder;
{
    if (!zOrder)
        zOrder = [[NSMutableArray alloc] init];
    else
        [zOrder removeAllObjects];
    [NSApp makeWindowsPerform:@selector(_addToZOrderArray) inOrder:YES];
    return zOrder;
}

- (void)replacement_dealloc;
{
    OBPRECONDITION([NSThread inMainThread]);

    // TJW: DP4 leaks the default button cell in NSWindow.  Check whether this is needed when we get Public Beta
    [_defaultButtonCell release];
    _defaultButtonCell = nil;
    oldDealloc(self, _cmd);
}

- (NSPoint)frameTopLeftPoint;
{
    NSRect windowFrame;

    windowFrame = [self frame];
    return NSMakePoint(NSMinX(windowFrame), NSMaxY(windowFrame));
}

#define MIN_MORPH_DIST (5.0)

- (void)morphToFrame:(NSRect)newFrame overTimeInterval:(NSTimeInterval)morphInterval;
{
    NSRect currentFrame, deltaFrame;
    NSTimeInterval start, current, elapsed;
    
    currentFrame = [self frame];
    deltaFrame.origin.x = newFrame.origin.x - currentFrame.origin.x;
    deltaFrame.origin.y = newFrame.origin.y - currentFrame.origin.y;
    deltaFrame.size.width = newFrame.size.width - currentFrame.size.width;
    deltaFrame.size.height = newFrame.size.height - currentFrame.size.height;
    
    // If nothing interesting is going on, just jump to the end state
    if (deltaFrame.origin.x < MIN_MORPH_DIST &&
        deltaFrame.origin.y < MIN_MORPH_DIST &&
        deltaFrame.size.width < MIN_MORPH_DIST &&
        deltaFrame.size.height < MIN_MORPH_DIST) {
        [self setFrame:newFrame display:YES];
        return;
    }

    start = [NSDate timeIntervalSinceReferenceDate];    
    while (YES) {
        float  ratio;
        NSRect stepFrame;
        
        current = [NSDate timeIntervalSinceReferenceDate];
        elapsed = current - start;
        if (elapsed >  morphInterval)
            break;

        ratio = elapsed / morphInterval;
        stepFrame.origin.x = currentFrame.origin.x + ratio * deltaFrame.origin.x;
        stepFrame.origin.y = currentFrame.origin.y + ratio * deltaFrame.origin.y;
        stepFrame.size.width = currentFrame.size.width + ratio * deltaFrame.size.width;
        stepFrame.size.height = currentFrame.size.height + ratio * deltaFrame.size.height;
        
        [self setFrame:stepFrame display:YES];
    }
    
    // Make sure we don't end up with round off errors
    [self setFrame:newFrame display:YES];
}

/*" We occasionally want to draw differently based on whether we are in the key window or not (for example, OAAquaButton).  This method allows us to draw correctly the first time we get drawn, when the window is coming on screen due to -makeKeyAndOrderFront:.  The window is not key at that point, but we would like to draw as if it is so that we don't have to redraw later, wasting time and introducing flicker. "*/

- (void)replacement_makeKeyAndOrderFront:(id)sender;
{
    becomingKeyWindow = self;
    oldMakeKeyAndOrderFront(self, _cmd, sender);
    becomingKeyWindow = nil;
}

#ifdef OMNI_ASSERTIONS_ON
// It is not thread safe to call this method from another thread since this will cause the Carbon menus representing the Windows menu to get updated, possibly causing mysterious crashes later.
- (void)replacement_setTitle:(NSString *)title;
{
    OBPRECONDITION([NSThread inMainThread]);
    oldSetTitle(self, _cmd, title);
}
#endif

- (BOOL)isBecomingKey;
{
    return self == becomingKeyWindow;
}

- (BOOL)shouldDrawAsKey;
{
    return [self isKeyWindow] || [self isBecomingKey];
}

- (void *)carbonWindowRef;
{
    WindowRef windowRef;
    extern void _SetWindowCGOrderingEnabled(WindowRef, Boolean);

    if (![self respondsToSelector:@selector(_windowRef)]) {
        NSLog(@"-[NSWindow(OAExtensions) carbonWindowRef]: _windowRef private API no longer exists, returning NULL");
        return NULL;
    }

    windowRef = [self _windowRef];
    _SetWindowCGOrderingEnabled(windowRef, false);
    return windowRef;
}

// NSCopying protocol

- (id)copyWithZone:(NSZone *)zone;
{
    return [self retain];
}

@end
