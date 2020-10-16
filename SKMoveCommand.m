//
//  SKMoveCommand.m
//  Skim
//
//  Created by Christiaan Hofman on 16/10/2020.
/*
This software is Copyright (c) 2020
Christiaan Hofman. All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions
are met:

- Redistributions of source code must retain the above copyright
  notice, this list of conditions and the following disclaimer.

- Redistributions in binary form must reproduce the above copyright
   notice, this list of conditions and the following disclaimer in
   the documentation and/or other materials provided with the
   distribution.

- Neither the name of Christiaan Hofman nor the names of any
   contributors may be used to endorse or promote products derived
   from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
"AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#import "SKMoveCommand.h"

@implementation SKMoveCommand

- (id)performDefaultImplementation {
    id objects = [self directParameter];
    if ([objects respondsToSelector:@selector(objectsByEvaluatingSpecifier)])
         objects = [objects objectsByEvaluatingSpecifier];
    if (objects && [objects isKindOfClass:[NSArray class]] == NO)
        objects = [NSArray arrayWithObject:objects];
    
    NSScriptClassDescription *classDescription = nil;
    for (id object in objects) {
        NSScriptClassDescription *aClassDescription = [NSScriptClassDescription classDescriptionForClass:[object class]];
        if (classDescription == nil && aClassDescription) {
            classDescription = aClassDescription;
        } else if ([classDescription isEqual:aClassDescription] == NO) {
            classDescription = nil;
            break;
        }
    }
    if (classDescription == nil) {
        [self setScriptErrorNumber:NSArgumentsWrongScriptError];
        [self setScriptErrorString:@"Invalid or missing objects to move"];
        return nil;
    }
    
    id locationSpecifier = [[self arguments] objectForKey:@"ToLocation"];
    
    id insertionContainer = nil;
    NSString *insertionKey = nil;
    NSInteger insertionIndex = -1;
    NSScriptClassDescription *containerClassDescription = nil;
    FourCharCode insertionType = [classDescription appleEventCode];
    
    if ([locationSpecifier isKindOfClass:[NSPositionalSpecifier class]]) {
        [locationSpecifier setInsertionClassDescription:classDescription];
        insertionContainer = [locationSpecifier insertionContainer];
        containerClassDescription = [NSScriptClassDescription classDescriptionForClass:[ insertionContainer class]];
        insertionKey = [locationSpecifier insertionKey];
        insertionIndex = [locationSpecifier insertionIndex];
    } else if ([locationSpecifier isKindOfClass:[NSPropertySpecifier class]] &&
               [[[(NSPropertySpecifier *)self containerClassDescription] toManyRelationshipKeys] containsObject:[(NSPropertySpecifier *)locationSpecifier key]]) {
        insertionContainer = [[locationSpecifier containerSpecifier] objectsByEvaluatingSpecifier];
        insertionKey = [locationSpecifier key];
        containerClassDescription = [NSScriptClassDescription classDescriptionForClass:[insertionContainer class]];
    } else if (locationSpecifier) {
        insertionContainer = [locationSpecifier objectsByEvaluatingSpecifier];
        // make sure this is a valid object, so not something like a range specifier
        if ([insertionContainer isKindOfClass:[NSArray class]] == NO) {
            containerClassDescription = [NSScriptClassDescription classDescriptionForClass:[insertionContainer class]];
            insertionKey = [containerClassDescription keyWithAppleEventCode:insertionType];
        }
    }
    
    // check if the insertion location is valid
    if (insertionContainer == nil || insertionKey == nil ||
        [[containerClassDescription toManyRelationshipKeys] containsObject:insertionKey] == NO) {
        [self setScriptErrorNumber:NSArgumentsWrongScriptError];
        [self setScriptErrorString:@"Could not find container to move to"];
        objects = nil;
    } else if ((insertionIndex == -1 && [containerClassDescription isLocationRequiredToCreateForKey:insertionKey]) ||
               [containerClassDescription hasWritablePropertyForKey:insertionKey] == NO ||
               insertionType != [containerClassDescription appleEventCodeForKey:insertionKey]) {
        [self setScriptErrorNumber:NSArgumentsWrongScriptError];
        [self setScriptErrorString:@"Invalid container to add to"];
    } else {
        // remove using scripting KVC
        for (id obj in objects) {
            NSScriptObjectSpecifier *specifier = [obj objectSpecifier];
            id container = [[specifier containerSpecifier] objectsByEvaluatingSpecifier];
            if ([container isKindOfClass:[NSArray class]])
                container = [container firstObject];
            [[container mutableArrayValueForKey:[specifier key]] removeObject:obj];
        }
        // insert using scripting KVC
        if (insertionIndex >= 0) {
            for (id obj in [objects reverseObjectEnumerator])
                [insertionContainer insertValue:obj atIndex:insertionIndex inPropertyWithKey:insertionKey];
        } else {
            for (id obj in objects)
                [insertionContainer insertValue:obj inPropertyWithKey:insertionKey];
        }
    }
    
    return nil;
}

@end
