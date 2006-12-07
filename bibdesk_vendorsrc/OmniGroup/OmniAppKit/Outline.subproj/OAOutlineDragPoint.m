// Copyright 1997-2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.

#import "OAOutlineDragPoint.h"

#import <Foundation/Foundation.h>
#import <OmniBase/OmniBase.h>

#import <OmniAppKit/OAOutlineEntry.h>

RCS_ID("$Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniAppKit/Outline.subproj/OAOutlineDragPoint.m,v 1.9 2003/01/15 22:51:40 kc Exp $")

@implementation OAOutlineDragPoint

- init;
{
    if (![super init])
	return nil;
    
    index = NSNotFound;
    entry = nil;
    position = NSMakePoint(0.0, 0.0);
    
    return self;
}

- (void)dealloc;
{
    [entry release];
    [super dealloc];
}

- copyWithZone:(NSZone *)aZone;
{
    OAOutlineDragPoint *copy;

    copy = [[[self class] allocWithZone:aZone] init];

    [copy setIndex:index];
    [copy setEntry:entry];
    [copy setPosition:position];

    return copy;
}

- copy;
{
    return [self copyWithZone:[self zone]];
}

//

- (unsigned int)index;
{
    return index;
}

- (OAOutlineEntry *)entry;
{
    return entry;
}

- (float)x;
{
    return position.x;
}

- (float)y;
{
    return position.y;
}

//

- (void)setIndex:(unsigned int)anIndex;
{
    index = anIndex;
}

- (void)setEntry:(OAOutlineEntry *)anEntry;
{
    if (entry == anEntry)
	return;
    [entry release];
    entry = [anEntry retain];
}

- (void)setPosition:(NSPoint)aPosition;
{
    position = aPosition;
}

- (void)addDX:(float)dx;
{
    position.x += dx;
}

- (void)addDY:(float)dy;
{
    position.y += dy;
}

// Debugging

- (NSMutableDictionary *)debugDictionary;
{
    NSMutableDictionary *debugDictionary;

    debugDictionary = [super debugDictionary];

    [debugDictionary setObject:[NSNumber numberWithFloat:index] forKey:@"index"];
    [debugDictionary setObject:entry forKey:@"entry"];
    [debugDictionary setObject:NSStringFromPoint(position) forKey:@"position"];

    return debugDictionary;
}

@end
