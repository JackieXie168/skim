// Copyright 2000-2002 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.
//
// $Header$

#import <Foundation/NSData.h>

@interface NSData (CGDataProvider)

- (void *)coreGraphicsDataProvider;
    // Returns CGDataProviderRef. The caller must release the ref (it's not autoreleased).
- (void *)coreGraphicsDataProviderWithOffset:(int)offset;
    // Returns CGDataProviderRef. The caller must release the ref (it's not autoreleased).

@end
