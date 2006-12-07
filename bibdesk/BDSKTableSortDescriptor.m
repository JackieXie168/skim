//
//  BDSKTableSortDescriptor.m
//  Bibdesk
//
//  Created by Christiaan Hofman on 12/11/05.
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

#import "BDSKTableSortDescriptor.h"
#import <OmniBase/assertions.h>
#import <OmniBase/OBUtilities.h>
#import <OmniFoundation/NSString-OFExtensions.h>

static Class NSStringClass = Nil;

@implementation BDSKTableSortDescriptor

+ (void)initialize{
    OBINITIALIZE;
    NSStringClass = [NSString class];
}

- (NSComparisonResult)compareObject:(id)object1 toObject:(id)object2 {
	id value1 = [object1 valueForKeyPath:[self key]];
	id value2 = [object2 valueForKeyPath:[self key]];
    
    // check to see if one of the values is nil
    if(value1 == nil){
        if(value2 == nil)
            return NSOrderedSame;
        else
            return ([self ascending] ? NSOrderedDescending : NSOrderedAscending);
    } else if(value2 == nil){
        return ([self ascending] ? NSOrderedAscending : NSOrderedDescending);
    // this check only applies to NSString objects
    } else if([value1 isKindOfClass:NSStringClass] && [value2 isKindOfClass:NSStringClass]){
        if ([value1 isEqualToString:@""]) {
                if ([value2 isEqualToString:@""]) {
                    return NSOrderedSame;
                } else {
                    return ([self ascending] ? NSOrderedDescending : NSOrderedAscending);
                }
        } else if ([value2 isEqualToString:@""]) {
            return ([self ascending] ? NSOrderedAscending : NSOrderedDescending);
        }
    } 	
	return [super compareObject:object1 toObject:object2];
}

@end
