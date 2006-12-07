// Copyright 2001-2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniFoundation/OpenStepExtensions.subproj/NSNumberFormatter-OFFixes.h,v 1.3 2003/01/15 22:52:00 kc Exp $

// Patch submitted by Kurt Revis

#import <Foundation/NSNumberFormatter.h>

@interface NSNumberFormatter (OFFixes)

- (BOOL)replacementGetObjectValue:(id *)obj forString:(NSString *)string errorDescription:(NSString **)error;

@end
