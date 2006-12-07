// Copyright 2001-2004 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniFoundation/OpenStepExtensions.subproj/NSNumberFormatter-OFFixes.h,v 1.6 2004/02/10 04:07:46 kc Exp $

#if !(defined(MAC_OS_X_VERSION_MIN_REQUIRED) && defined(MAC_OS_X_VERSION_10_2) && (MAC_OS_X_VERSION_MIN_REQUIRED >= MAC_OS_X_VERSION_10_2))
#define FIX_NSFORMATTER_BUG_12753
#endif

#ifdef FIX_NSFORMATTER_BUG_12753

// Patch submitted by Kurt Revis

#import <Foundation/NSNumberFormatter.h>

@interface NSNumberFormatter (OFFixes)

- (BOOL)replacementGetObjectValue:(id *)obj forString:(NSString *)string errorDescription:(NSString **)error;

@end

#endif