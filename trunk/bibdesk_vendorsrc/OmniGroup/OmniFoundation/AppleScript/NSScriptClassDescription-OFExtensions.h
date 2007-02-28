// Copyright 2006 The Omni Group.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/OmniSourceRelease_2006-09-07/OmniGroup/Frameworks/OmniFoundation/AppleScript/NSScriptClassDescription-OFExtensions.h 77394 2006-07-12 18:20:02Z wiml $

#import <Foundation/NSScriptClassDescription.h>

@interface NSScriptClassDescription (OFExtensions)
+ (NSScriptClassDescription *)commonScriptClassDescriptionForObjects:(NSArray *)objects;
- (BOOL)isKindOfScriptClassDescription:(NSScriptClassDescription *)desc;
- (NSScriptClassDescription *)resolveSynonym;
@end
