//
//  BDSKScriptHook+Scripting.m
//  Bibdesk
//
//  Created by Christiaan Hofman on 17/10/05.
/*
 This software is Copyright (c) 2005
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

#import "BDSKScriptHook+Scripting.h"


@implementation BDSKScriptHook (Scripting)

- (NSScriptObjectSpecifier *)objectSpecifier {
    if (uniqueID) {
        // this is necessary as our container is the application 
		NSScriptClassDescription *containerClassDescription = (NSScriptClassDescription *)[NSClassDescription classDescriptionForClass:[OAApplication class]];
        return [[[NSUniqueIDSpecifier allocWithZone: [self zone]] 
			  initWithContainerClassDescription: containerClassDescription 
							 containerSpecifier: nil // the application is the null container
											key: @"scriptHooks" 
									   uniqueID: uniqueID] autorelease];
    } else {
        return nil;
    }
}

// Use separate accessors for AppleScript, to ensure the read-only properties. 
// Also make sure we don't return nil and break a script.

- (NSString *)asName {
    return name;
}

- (NSNumber *)asUniqueID {
    return uniqueID;
}

- (NSString *)asField {
    return field ? field : @"";
}

- (NSArray *)asOldValues {
    return oldValues ? oldValues : [NSArray array];
}

- (NSArray *)asNewValues {
    return newValues ? newValues : [NSArray array];
}

@end
