// Copyright 2000-2005 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import <OmniFoundation/OFAddScriptCommand.h>

#import <OmniFoundation/NSObject-OFExtensions.h>

#import <Foundation/NSArray.h>
#import <Foundation/NSBundle.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSException.h>
#import <Foundation/NSScriptObjectSpecifiers.h>
#import <Foundation/NSString.h>

#import <OmniBase/OmniBase.h>

RCS_ID("$Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/OmniSourceRelease_2006-09-07/OmniGroup/Frameworks/OmniFoundation/AppleScript/OFAddScriptCommand.m 66170 2005-07-28 17:40:10Z kc $");


/*
 This (and OFRemoveScriptCommand) are convenience classes for implementing the 'add' and 'remove' script commands for managing many-to-many relationships.  See TN2106.  These aren't implemented by Cocoa (as of 10.2.8, anyway), but are very useful.
 */

@implementation OFAddScriptCommand

/*
 This needs to be defined as -executeCommand instead of -performDefaultImplementation since often the receiver will be unset (if an array is the receiver) and -performDefaultImplementation will just bail in that caase.
 */
- (id)executeCommand;
{
    // If we do 'add every row of MyDoc to selected rows of MyDoc', then the receivers will be an array.  We'll pass this command to the container.
    NSScriptObjectSpecifier *containerSpec = [[self arguments] objectForKey:@"ToContainer"];
    if (!containerSpec) {
        NSLog(@"Command has no 'ToContainer' -- %@", self);
        [NSException raise:NSInvalidArgumentException format:NSLocalizedStringFromTableInBundle(@"Add command missing the required 'to' specifier.", @"OmniFoundation", [OFAddScriptCommand bundle], @"script exception format")];
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
    
    if ([containerSpec isKindOfClass:[NSPropertySpecifier class]]) {
        //
        // If we just got a property specifier, then we don't care about the index.
        //
        NSPropertySpecifier *propertySpec = (NSPropertySpecifier *)containerSpec;
        NSString *key = [propertySpec key];
        id container = [[propertySpec containerSpecifier] objectsByEvaluatingSpecifier];
        if (![container respondsToSelector:@selector(addObjects:toPropertyWithKey:)]) {
            NSLog(@"Container doesn't respond to -addObjects:toPropertyWithKey: -- container = %@", self, container);
            [NSException raise:NSInvalidArgumentException format:NSLocalizedStringFromTableInBundle(@"Specified container doesn't handle the add command.", @"OmniFoundation", [OFAddScriptCommand bundle], @"script exception format")];
        }

        [container addObjects:evaluatedParameters toPropertyWithKey:key];
    } else if ([containerSpec isKindOfClass:[NSPositionalSpecifier class]]) {
        //
        // With a position specifier, the index is important, so we pass that along.
        //
        NSPositionalSpecifier *positionalSpec = (NSPositionalSpecifier *)containerSpec;

        id insertionContainer = [positionalSpec insertionContainer];
        if (!insertionContainer) {
            NSLog(@"Unable to resolve insertion container in specifier %@", positionalSpec);
            [NSException raise:NSInvalidArgumentException format:NSLocalizedStringFromTableInBundle(@"Unable to resolve insertion container in specifier %@", @"OmniFoundation", [OFAddScriptCommand bundle], @"script exception format"), positionalSpec];
        }
        
        NSString *insertionKey = [positionalSpec insertionKey];
        if (!insertionKey) {
            NSLog(@"Unable to resolve insertion key in specifier %@", positionalSpec);
            [NSException raise:NSInvalidArgumentException format:NSLocalizedStringFromTableInBundle(@"Unable to resolve insertion key in specifier %@", @"OmniFoundation", [OFAddScriptCommand bundle], @"script exception format"), positionalSpec];
        }
        
        int insertionIndex = [positionalSpec insertionIndex];
        if (insertionIndex < 0) {
            NSLog(@"Unable to resolve insertion index in specifier %@", positionalSpec);
            [NSException raise:NSInvalidArgumentException format:NSLocalizedStringFromTableInBundle(@"Unable to resolve insertion index in specifier %@", @"OmniFoundation", [OFAddScriptCommand bundle], @"script exception format"), positionalSpec];
        }
        
        if (![insertionContainer respondsToSelector:@selector(insertObjects:inPropertyWithKey:atIndex:)]) {
            NSLog(@"Container doesn't respond to -addObjects:toPropertyWithKey:atIndex: -- container = %@", self, OBShortObjectDescription(insertionContainer));
            [NSException raise:NSInvalidArgumentException format:NSLocalizedStringFromTableInBundle(@"Specified container doesn't handle the add command.", @"OmniFoundation", [OFAddScriptCommand bundle], @"script exception format")];
        }

        [insertionContainer insertObjects:evaluatedParameters inPropertyWithKey:insertionKey atIndex:insertionIndex];
    } else {
        NSLog(@"Command's 'ToContainer' is not a NSPropertySpecifier or NSPositionalSpecifier -- %@", containerSpec);
        [NSException raise:NSInvalidArgumentException format:NSLocalizedStringFromTableInBundle(@"Add command has invalid 'to' specifier.", @"OmniFoundation", [OFAddScriptCommand bundle], @"script exception format")];
    }

    return nil;
}

@end
