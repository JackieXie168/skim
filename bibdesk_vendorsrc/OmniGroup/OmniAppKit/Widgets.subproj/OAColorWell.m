// Copyright 2003-2004 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import "OAColorWell.h"

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <OmniBase/rcsid.h>

RCS_ID("$Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniAppKit/Widgets.subproj/OAColorWell.m,v 1.4 2004/02/10 04:07:37 kc Exp $");

/*
 NSColorWell and NSColorPanel have some terrible interaction.  In particular, if you have an active color well on an inspector but your main window's first responder has a -changeColor: method, the first responder's method still gets called instead of the inspector's action being responsible!

 Note that this probably only happens in inspectors since NSColorPanel uses -sendAction:to:from: with a nil 'to' and inspectors aren't in key windows typically.

 This class provides a means to determine if there is an active color well.  Thus, in your -changeColor: methods you can just do nothing if there is an active color well or do your default color changing if there isn't.
 */

static NSMutableArray *activeColorWells;

@implementation OAColorWell

+ (void)initialize;
{
    OBINITIALIZE;

    // Don't want to retain them and prevent them from being deallocated (and thus deactivated)!
    activeColorWells = OFCreateNonOwnedPointerArray();
}

+ (BOOL)hasActiveColorWell;
{
    return [activeColorWells count] > 0;
}

+ (NSArray *)activeColorWells;
{
    return [NSArray arrayWithArray:activeColorWells];
}

+ (void)deactivateAllColorWells;
{
    while ([activeColorWells count])
        [[activeColorWells lastObject] deactivate];
}

- (void)dealloc;
{
    [self deactivate];
    [super dealloc];
}

- (void)deactivate;
{
    [super deactivate];
    [activeColorWells removeObjectIdenticalTo:self];
}

- (void)activate:(BOOL)exclusive;
{
    // Do this first since this the super implementation will poke the color panel into poking -changeColor: on the responder chain.  We want to know that a color well is activated by then.
    if ([activeColorWells indexOfObjectIdenticalTo:self] == NSNotFound)
        [activeColorWells addObject:self];

    [super activate:exclusive];
}

@end
