// Copyright 2003-2004 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import "OFScriptPlaceholder.h"

#import <Foundation/Foundation.h>
#import <OmniBase/OmniBase.h>
#import <OmniBase/rcsid.h>

RCS_ID("$Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniFoundation/OFScriptPlaceholder.m,v 1.3 2004/02/10 04:07:41 kc Exp $");

@implementation OFScriptPlaceholder

- initWithTargetClassDescription:(NSScriptClassDescription *)targetClassDescription;
{
    OBPRECONDITION(targetClassDescription);
    OBPRECONDITION([targetClassDescription isKindOfClass:[NSScriptClassDescription class]]);
    _targetClassDescription = [targetClassDescription retain];
    return self;
}

- (void)dealloc;
{
    [_targetClassDescription release];
    [_target release];
    [_scriptingProperties release];
    [super dealloc];
}

- (NSScriptClassDescription *)targetClassDescription;
{
    return _targetClassDescription;
}

- (void)setTarget:(id)target;
{
    OBPRECONDITION(!_target);  // should really only set this once
    [_target release];
    _target = [target retain];
}

- (id)target;
{
    return _target;
}

- (NSScriptObjectSpecifier *)objectSpecifier;
{
    OBPRECONDITION(_target);
    return [_target objectSpecifier];
}

- (NSDictionary *)scriptingProperties;
{
    return _scriptingProperties;
}

- (void)setScriptingProperties:(NSDictionary *)properties;
{
    [_scriptingProperties release];
    _scriptingProperties = [[NSDictionary alloc] initWithDictionary:properties];
}

//
// Debugging
//
- (NSMutableDictionary *)debugDictionary;
{
    NSMutableDictionary *dict = [super debugDictionary];
    [dict takeValue:_targetClassDescription forKey:@"_targetClassDescription"];
    [dict takeValue:_target forKey:@"_target"];
    [dict takeValue:_scriptingProperties forKey:@"_scriptingProperties"];
    return dict;
}

@end
