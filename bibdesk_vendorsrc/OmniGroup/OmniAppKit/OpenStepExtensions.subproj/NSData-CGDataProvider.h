// Copyright 2000-2004 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniAppKit/OpenStepExtensions.subproj/NSData-CGDataProvider.h,v 1.12 2004/02/10 04:07:34 kc Exp $

#import <Foundation/NSData.h>

@interface NSData (CGDataProvider)

- (void *)coreGraphicsDataProvider;
    // Returns CGDataProviderRef. The caller must release the ref (it's not autoreleased).
- (void *)coreGraphicsDataProviderWithOffset:(int)offset;
    // Returns CGDataProviderRef. The caller must release the ref (it's not autoreleased).

@end
