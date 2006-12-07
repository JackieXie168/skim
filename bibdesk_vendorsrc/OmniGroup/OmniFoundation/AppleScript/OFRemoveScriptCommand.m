// Copyright 2000-2005 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import <OmniFoundation/OFRemoveScriptCommand.h>

#import <OmniFoundation/NSObject-OFExtensions.h>

#import <Foundation/NSArray.h>
#import <Foundation/NSBundle.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSException.h>
#import <Foundation/NSScriptObjectSpecifiers.h>
#import <Foundation/NSString.h>

#import <OmniBase/rcsid.h>

RCS_ID("$Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/OmniSourceRelease_2006-09-07/OmniGroup/Frameworks/OmniFoundation/AppleScript/OFRemoveScriptCommand.m 66170 2005-07-28 17:40:10Z kc $");

@implementation OFRemoveScriptCommand

/*
 This needs to be defined as -executeCommand instead of -performDefaultImplementation since often the receiver will be unset (if an array is the receiver) and -performDefaultImplementation will just bail in that caase.
 */
- (id)executeCommand;
{
    // If we do 'add every row of MyDoc to selected rows of MyDoc', then the receivers will be an array.  We'll pass this command to the container.
    NSPropertySpecifier *containerSpec = [[self arguments] objectForKey:@"FromContainer"];
    if (!containerSpec) {
        NSLog(@"Command has no 'FromContainer' -- %@", self);
        [NSException raise:NSInvalidArgumentException format:NSLocalizedStringFromTableInBundle(@"Remove command missing the required 'from' specifier.", @"OmniFoundation", [OFRemoveScriptCommand bundle], @"script exception format")];
    }
    if (![containerSpec isKindOfClass:[NSPropertySpecifier class]]) {
        NSLog(@"Command's 'FromContainer' is not a NSPropertySpecifier -- %@", containerSpec);
        [NSException raise:NSInvalidArgumentException format:NSLocalizedStringFromTableInBundle(@"Remove command has invalid 'from' specifier.", @"OmniFoundation", [OFRemoveScriptCommand bundle], @"script exception format")];
    }

    // Use -directParameter since -evaluatedReceivers is NULL if we get an array ("add {x,y,z} to foo").
    id parameter = [self directParameter];
    if (!parameter) {
#ifdef DEBUG
        NSLog(@"Unable to evaluate receivers.  They problably don't respond to this command: %@", self);
#endif
        return nil;
    }

    NSArray *parameters;
    if ([parameter isKindOfClass:[NSArray class]]) // If we are adding a single object, it'll be that object
        parameters = (NSArray *)parameter;
    else
        parameters = [NSArray arrayWithObject:parameter];


    NSMutableArray *evaluatedParameters = [NSMutableArray array];
    unsigned int parameterIndex, parameterCount = [parameters count];
    for (parameterIndex = 0; parameterIndex < parameterCount; parameterIndex++) {
        NSScriptObjectSpecifier *parameter = [parameters objectAtIndex:parameterIndex];
        id object = [parameter objectsByEvaluatingSpecifier];
        if (!object) {
#ifdef DEBUG
            NSLog(@"%s: Unable to evaluate parameter: %@", __PRETTY_FUNCTION__, parameter);
#endif
            return nil;
        }

        // Result will be an array for things like 'every foo of...'
        if ([object isKindOfClass:[NSArray class]])
            [evaluatedParameters addObjectsFromArray:object];
        else
            [evaluatedParameters addObject:object];
    }

    NSString *key = [containerSpec key];
    id container = [[containerSpec containerSpecifier] objectsByEvaluatingSpecifier];
    if (![container respondsToSelector:@selector(removeObjects:fromPropertyWithKey:)]) {
        NSLog(@"Container doesn't respond to -removeObjects:toPropertyWithKey: -- container = %@", self, container);
        [NSException raise:NSInvalidArgumentException format:NSLocalizedStringFromTableInBundle(@"Specified container doesn't handle the remove command.", @"OmniFoundation", [OFRemoveScriptCommand bundle], @"script exception format")];
    }

    [container removeObjects:evaluatedParameters fromPropertyWithKey:key];
    return nil;
}

@end
