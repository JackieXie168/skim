// Copyright 1997-2005 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import <OmniFoundation/NSNumber-OFExtensions.h>

#import <Foundation/Foundation.h>
#import <OmniBase/OmniBase.h>

RCS_ID("$Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/SourceRelease_2005-10-03/OmniGroup/Frameworks/OmniFoundation/OpenStepExtensions.subproj/NSNumber-OFExtensions.m 68913 2005-10-03 19:36:19Z kc $")

@implementation NSNumber (OFExtensions)

static NSCharacterSet *dotCharacterSet = nil;

- initWithString:(NSString *)aString;
{
    /*
     * Currently this is a little lame -- it only will figure out a few types
     * of numbers.
     */
    NSRange range;

    if (!dotCharacterSet)
	dotCharacterSet = [[NSCharacterSet characterSetWithCharactersInString:@"."] retain];

    range = [aString rangeOfCharacterFromSet:dotCharacterSet];
    if (!range.length) {
	[self release];
	return [[NSNumber alloc] initWithInt:[aString intValue]];
    } else {
	[self release];
	return [[NSNumber alloc] initWithFloat:[aString floatValue]];
    }
}

@end


static float sharedNaNValue;
@implementation OFNaN
+ (OFNaN *)sharedNaN;
{
    static OFNaN *sharedNaN = nil;
    if (!sharedNaN) {
        sharedNaNValue = sqrt(-1.0);
        sharedNaN = [[OFNaN alloc] init];
    }
    return sharedNaN;
}
- (const char *)objCType;
{
    return @encode(float);
}
- (float)floatValue;
{
    return sharedNaNValue;
}
- (id)retain;
{
    return self;
}
- (id)autorelease;
{
    return self;
}
- (void)release;
{
}
- (id)copyWithZone:(NSZone *)zone;
{
    return self;
}
- (NSString *)description;
{
    return @"NaN";
}
- (NSString *)stringValue
{
    return @"NaN";
}
@end


