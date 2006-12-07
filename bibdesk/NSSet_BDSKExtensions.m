//
//  NSSet_BDSKExtensions.m
//  Bibdesk
//
//  Created by Adam Maxwell on 12/04/05.
/*
 This software is Copyright (c) 2005
 Adam Maxwell. All rights reserved.
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:
 
 - Redistributions of source code must retain the above copyright
 notice, this list of conditions and the following disclaimer.
 
 - Redistributions in binary form must reproduce the above copyright
 notice, this list of conditions and the following disclaimer in
 the documentation and/or other materials provided with the
 distribution.
 
 - Neither the name of Adam Maxwell nor the names of any
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

#import "NSSet_BDSKExtensions.h"
#import <OmniBase/OmniBase.h>
#import <OmniFoundation/CFSet-OFExtensions.h>

@interface BDSKSet : NSSet {} @end

@implementation BDSKSet

+ (void)performPosing;
{
    if(floor(NSAppKitVersionNumber) <= NSAppKitVersionNumber10_3)
        class_poseAs(self, NSClassFromString(@"NSSet"));
}

/* We replace this method so we can use @count with NSSet, which doesn't implement that key on 10.3.x (which really sucks).
*/
- (id)valueForUndefinedKey:(NSString *)key
{
    if([key isEqualToString:@"@count"])
        return [NSNumber numberWithInt:[self count]];
    return [super valueForUndefinedKey:key];
}

@end

@implementation NSMutableSet (BDSKExtensions)

- (id)initCaseInsensitive
{
	self = [self initCaseInsensitiveWithCapacity:0];
	return self;
}

- (id)initCaseInsensitiveWithCapacity:(unsigned)numItems
{
	// I think this works correctly
	if ([self class] != [NSClassFromString(@"NSPlaceholderMutableSet") class])
		[self release];
	// ignore capacity, as it will fix the number of items we can use
	self = (NSMutableSet *)CFSetCreateMutable(kCFAllocatorDefault, 0, &OFCaseInsensitiveStringSetCallbacks);
	return self;
}

@end
