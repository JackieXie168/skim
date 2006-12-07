// Copyright 1997-2005 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import <OmniFoundation/OFTrieBucket.h>

#import <Foundation/Foundation.h>
#import <OmniBase/OmniBase.h>

RCS_ID("$Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/OmniSourceRelease_2006-09-07/OmniGroup/Frameworks/OmniFoundation/DataStructures.subproj/OFTrieBucket.m 68913 2005-10-03 19:36:19Z kc $")

@implementation OFTrieBucket

- (void)setRemainingLower:(unichar *)lower upper:(unichar *)upper length:(int)aLength;
{
    unichar *old;
    NSZone *myZone;
    
    myZone = [self zone];
    old = lowerCharacters;
    if (lower && upper && aLength > 0) {
        if (lower != upper) {
            lowerCharacters = (unichar *)NSZoneMalloc(myZone, (aLength + aLength + 2) * sizeof(unichar));
        } else {
            lowerCharacters = (unichar *)NSZoneMalloc(myZone, (aLength + 1) * sizeof(unichar));
        }
        memmove(lowerCharacters, lower, aLength * sizeof(unichar));
        lowerCharacters[aLength] = '\0';
        if (lower != upper) {
            upperCharacters = lowerCharacters + aLength + 1;
            memmove(upperCharacters, upper, aLength * sizeof(unichar));
            upperCharacters[aLength] = '\0';
        } else {
            // Share storage
            upperCharacters = lowerCharacters;
        }
    } else {
        lowerCharacters = (unichar *)NSZoneMalloc(myZone, sizeof(unichar));
	*lowerCharacters = '\0';
	upperCharacters = lowerCharacters; // Share storage for efficiency
    }
    if (old)
        NSZoneFree(myZone, old);
}

- (void)dealloc;
{
    NSZoneFree([self zone], lowerCharacters);
    [super dealloc];
}

// OBObject subclass

- (NSMutableDictionary *)debugDictionary;
{
    NSMutableDictionary *debugDictionary;

    debugDictionary = [super debugDictionary];
    if (lowerCharacters) {
        unsigned int length;
        unichar *ptr;

        ptr = lowerCharacters;
        length = 0;
        while (*ptr++)
	    length++;

	[debugDictionary setObject:[NSString stringWithCharacters:lowerCharacters length:length] forKey:@"lowerCharacters"];
        if (upperCharacters != lowerCharacters)
            [debugDictionary setObject:[NSString stringWithCharacters:upperCharacters length:length] forKey:@"upperCharacters"];
    }
    return debugDictionary;
}

@end
