// Copyright 2006 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/OmniSourceRelease_2006-09-07/OmniGroup/Frameworks/OmniAppKit/OpenStepExtensions.subproj/NSData-CGDataConsumer.h 79090 2006-09-07 23:55:58Z kc $

#import <Foundation/NSData.h>

@interface NSMutableData (CGDataProvider)

- (void *)coreGraphicsDataConsumer;
    // Returns CGDataConsumerRef. The caller must release the ref (it's not autoreleased).

@end

