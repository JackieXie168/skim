// Copyright 1997-2005 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import <OmniFoundation/NSException-OFExtensions.h>

#import <Foundation/Foundation.h>
#import <OmniBase/OmniBase.h>

RCS_ID("$Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/OmniSourceRelease_2006-09-07/OmniGroup/Frameworks/OmniFoundation/OpenStepExtensions.subproj/NSException-OFExtensions.m 68913 2005-10-03 19:36:19Z kc $")

@implementation NSException (OFExtensions)

static NSMutableDictionary *displayNames = nil;

// Informal OFBundleRegistryTarget protocol

+ (void)registerItemName:(NSString *)itemName bundle:(NSBundle *)bundle description:(NSDictionary *)description;
{
    if ([itemName isEqualToString:@"displayNames"]) {
        if (!displayNames)
            displayNames = [[NSMutableDictionary alloc] init];
	[displayNames addEntriesFromDictionary:description];
    }
}

// Declared methods

- (NSString *)displayName;
{
    NSString *exceptionName;
    NSString *displayName;

    exceptionName = [self name];
    displayName = [displayNames objectForKey:exceptionName];
    return displayName ? displayName : exceptionName;
}

@end
