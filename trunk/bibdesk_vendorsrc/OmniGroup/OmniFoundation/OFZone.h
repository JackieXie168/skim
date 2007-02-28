// Copyright 1998-2005 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/OmniSourceRelease_2006-09-07/OmniGroup/Frameworks/OmniFoundation/OFZone.h 68913 2005-10-03 19:36:19Z kc $

#import <OmniFoundation/OFObject.h>

/*" OFZone is a simple Objective-C wrapper around an NSZone pointer to allow reference counting (in particular, autoreleasing). When the OFZone is deallocated, it calls NSRecycleZone(). "*/

@interface OFZone : OFObject
{
    BOOL ownsZone;
@public
    NSZone *zone;  /*" The allocation zone represented by this OFZone. "*/
}

+ (OFZone *)zoneForNSZone:(NSZone *)aZone;
+ (OFZone *)zoneForObject:(id <NSObject>)anObject;
+ (OFZone *)defaultZone;
+ (OFZone *)newZone;

- (NSZone *)nsZone;  /* NB: -[OFZone zone] returns the zone the OFZone is allocated *in*, not the zone it *represents* ! */

- (void)setName:(NSString *)newName;
- (NSString *)name;

@end
