// Copyright 2003-2005 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import "OFScriptPlaceholder.h"

#import <Foundation/Foundation.h>
#import <OmniBase/OmniBase.h>
#import <OmniBase/rcsid.h>

RCS_ID("$Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/OmniSourceRelease_2006-09-07/OmniGroup/Frameworks/OmniFoundation/AppleScript/OFScriptPlaceholder.m 68913 2005-10-03 19:36:19Z kc $");

@implementation OFScriptPlaceholder

- initWithTargetClass:(Class)targetClass;
{
    OBPRECONDITION(targetClass);
    OBPRECONDITION([[NSClassDescription classDescriptionForClass:targetClass] isKindOfClass:[NSScriptClassDescription class]]);
    _targetClass = targetClass;
    return self;
}

- (void)dealloc;
{
    [_target release];
    [_scriptingProperties release];
    [super dealloc];
}

- (Class)targetClass;
{
    return _targetClass;
}

- (void)setTarget:(id)target;
{
    OBPRECONDITION(!_target);  // should really only set this once
    OBPRECONDITION([target isKindOfClass:_targetClass]);
    
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
    [dict takeValue:_targetClass forKey:@"_targetClass"];
    [dict takeValue:_target forKey:@"_target"];
    [dict takeValue:_scriptingProperties forKey:@"_scriptingProperties"];
    return dict;
}

@end
