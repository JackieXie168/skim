// Copyright 1997-2004 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import <OmniAppKit/NSBundle-OAExtensions.h>

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <OmniBase/OmniBase.h>
#import <OmniFoundation/OmniFoundation.h>

RCS_ID("$Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniAppKit/OpenStepExtensions.subproj/NSBundle-OAExtensions.m,v 1.10 2004/02/10 04:07:33 kc Exp $")

@implementation NSBundle (OAExtensions)

- (void)loadNibNamed:(NSString *)nibName owner:(id <NSObject>)owner;
{
    NSMutableDictionary *ownerDictionary;
    BOOL successfulLoad;

    ownerDictionary = [[NSMutableDictionary alloc] init];
    [ownerDictionary setObject:owner forKey:@"NSOwner"];
    successfulLoad = [self loadNibFile:nibName externalNameTable:ownerDictionary withZone:[owner zone]];
    [ownerDictionary release];
    if (!successfulLoad)
        [NSException raise:NSInternalInconsistencyException format:@"Unable to load nib %@", nibName];
}

@end

