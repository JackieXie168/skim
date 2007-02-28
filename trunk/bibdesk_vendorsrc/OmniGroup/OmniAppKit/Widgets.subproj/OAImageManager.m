// Copyright 2003-2006 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import "OAImageManager.h"

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <OmniBase/OmniBase.h>

RCS_ID("$Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/OmniSourceRelease_2006-09-07/OmniGroup/Frameworks/OmniAppKit/Widgets.subproj/OAImageManager.m 79079 2006-09-07 22:35:32Z kc $");

@implementation OAImageManager

// API

static OAImageManager *SharedImageManager = nil;

+ (OAImageManager *)sharedImageManager;
{
    if (SharedImageManager == nil)
        SharedImageManager = [[self alloc] init];

    return SharedImageManager;
}

+ (void)setSharedImageManager:(OAImageManager *)newInstance;
{
    if (SharedImageManager != nil)
        [SharedImageManager release];

    SharedImageManager = [newInstance retain];
}

- (NSImage *)imageNamed:(NSString *)imageName;
{
    OBPRECONDITION(imageName); // Crashes under 10.3 otherwise
    if (!imageName)
	return nil;
    return [NSImage imageNamed:imageName];
}

- (NSImage *)imageNamed:(NSString *)imageName inBundle:(NSBundle *)aBundle;
{
    NSImage *image;
    NSString *path;

    image = [self imageNamed:imageName];
    if (image && [image isValid])
        return image;

    path = [aBundle pathForImageResource:imageName];
    if (!path)
        return nil;

    image = [[NSImage alloc] initByReferencingFile:path];
    [image setName:imageName];

    return image;
}    

@end

