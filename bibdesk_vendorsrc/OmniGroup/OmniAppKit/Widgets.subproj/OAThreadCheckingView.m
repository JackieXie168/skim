// Copyright 1997-2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.

#import <OmniAppKit/OAThreadCheckingView.h>

#import <Foundation/Foundation.h>
#import <OmniBase/OmniBase.h>
#import <OmniFoundation/OmniFoundation.h>

RCS_ID("$Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniAppKit/Widgets.subproj/OAThreadCheckingView.m,v 1.17 2003/01/15 22:51:46 kc Exp $")

#ifdef OMNI_ASSERTIONS_ON
#ifndef RHAPSODY

@implementation OAThreadCheckingView

+ (void)performPosing;
{
    // don't use -poseAs: method as it messes up OBPostLoader
    class_poseAs((Class)self, ((Class)self)->super_class);

#warning Thread checking enabled for NSView methods.  This should be disabled in production code.
//    NSLog(@"Thread checking enabled for NSView methods.  This should be disabled in production code.  Ignore this message if you're an end user.  Everything is fine.  We're all fine here.  How about you?");
}

- (void)lockFocus;
{
    ASSERT_MAIN_THREAD_OPS_OK(@"Cannot call -lockFocus from any but the main thread");
    [super lockFocus];
}

- (void)setNeedsDisplay:(BOOL)newDisplay;
{
    if ([self window] != nil)
        ASSERT_MAIN_THREAD_OPS_OK(@"Cannot call -setNeedsDisplay: from any but the main thread");
    [super setNeedsDisplay:newDisplay];
}

- (void)setNeedsDisplayInRect:(NSRect)newRect;
{
    if ([self window] != nil)
        ASSERT_MAIN_THREAD_OPS_OK(@"Cannot call setNeedsDisplayInRect: from any but the main thread");
    [super setNeedsDisplayInRect:newRect];
}

@end

#endif
#endif
