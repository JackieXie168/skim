// Copyright 2000-2005 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/OmniSourceRelease_2006-09-07/OmniGroup/Frameworks/OmniFoundation/AppleScript/OFAddScriptCommand.h 66170 2005-07-28 17:40:10Z kc $

#import <Foundation/NSScriptCommand.h>

@class NSArray;

@interface OFAddScriptCommand : NSScriptCommand
@end

@interface NSObject (OFAddScriptCommand)
- (void)addObjects:(NSArray *)objects toPropertyWithKey:(NSString  *)key;
- (void)insertObjects:(NSArray *)objects inPropertyWithKey:(NSString  *)key atIndex:(int)insertionIndex;
@end
