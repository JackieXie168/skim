// Copyright 2003-2004 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniFoundation/OFScriptPlaceholder.h,v 1.3 2004/02/10 04:07:41 kc Exp $

#import <Foundation/NSObject.h>

@class NSDictionary, NSScriptClassDescription, NSScriptObjectSpecifier;

@interface OFScriptPlaceholder : NSObject
{
    NSScriptClassDescription *_targetClassDescription;
    id _target;
    NSDictionary *_scriptingProperties;
}

- initWithTargetClassDescription:(NSScriptClassDescription *)targetClassDescription;

- (NSScriptClassDescription *)targetClassDescription;

- (void)setTarget:(id)target;
- (id)target;

- (NSScriptObjectSpecifier *)objectSpecifier;

- (NSDictionary *)scriptingProperties;
- (void)setScriptingProperties:(NSDictionary *)properties;

@end
