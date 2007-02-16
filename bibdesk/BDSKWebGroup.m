//
//  BDSKWebGroup.m
//  Bibdesk
//
//  Created by Michael McCracken on 1/25/07.
/*
 This software is Copyright (c) 2007
 Michael O. McCracken. All rights reserved.

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:

 - Redistributions of source code must retain the above copyright
   notice, this list of conditions and the following disclaimer.

 - Redistributions in binary form must reproduce the above copyright
    notice, this list of conditions and the following disclaimer in
    the documentation and/or other materials provided with the
    distribution.

 - Neither the name of Michael O. McCracken nor the names of any
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

#import "BDSKWebGroup.h"
#import "BibPrefController.h"
#import "BDSKPublicationsArray.h"
#import "BDSKMacroResolver.h"
#import "NSImage+Toolbox.h"

@implementation BDSKWebGroup
- (id)initWithName:(NSString *)aName{
    
    NSAssert(aName != nil, @"BDSKWebGroup requires a name");

    if (self = [super initWithName:aName count:0]) {
        publications = nil;
        macroResolver = [[BDSKMacroResolver alloc] initWithOwner:self];
        isRetrieving = NO;
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aCoder{
    [NSException raise:BDSKUnimplementedException format:@"Instances of %@ do not conform to NSCoding", [self class]];
    return nil;
}

- (void)encodeWithCoder:(NSCoder *)aCoder{
    [NSException raise:BDSKUnimplementedException format:@"Instances of %@ do not conform to NSCoding", [self class]];
}

- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [publications makeObjectsPerformSelector:@selector(setOwner:) withObject:nil];
    [publications release];
    [super dealloc];
}

- (BOOL)isEqual:(id)other { return self == other; }

- (unsigned int)hash {
    return( ((unsigned int) self >> 4) | (unsigned int) self << (32 - 4));
}

#pragma mark BDSKGroup overrides

// note that pointer equality is used for these groups, so names can overlap

- (NSImage *)icon { return [NSImage imageNamed:@"webFolderIcon"]; }

- (BOOL)isSearch { return NO; }

- (BOOL)isExternal { return YES; }

- (BOOL)isEditable { return NO; } 

- (BOOL)hasEditableName { return NO; }

- (BOOL)isRetrieving { return isRetrieving; }

- (void)setRetrieving:(BOOL)flag { isRetrieving = flag; }

- (BOOL)failedDownload { return NO;}

- (BOOL)containsItem:(BibItem *)item {
    return [publications containsObject:item];
}

#pragma mark BDSKOwner protocol

- (BDSKPublicationsArray *)publications{
    
    if([self isRetrieving] == NO && publications == nil){
        // get initial batch of publications
     //   [server retrievePublications];
        
        // use this to notify the tableview to start the progress indicators
   //     NSDictionary *userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO] forKey:@"succeeded"];
     //   [[NSNotificationCenter defaultCenter] postNotificationName:BDSKSearchGroupUpdatedNotification object:self userInfo:userInfo];
    }
    // this posts a notification that the publications of the group changed, forcing a redisplay of the table cell
    return publications;
}

- (void)setPublications:(NSArray *)newPublications{
    
    if(newPublications != publications){
        [publications makeObjectsPerformSelector:@selector(setOwner:) withObject:nil];
        [publications release];
        publications = newPublications == nil ? nil : [[BDSKPublicationsArray alloc] initWithArray:newPublications];
        [publications makeObjectsPerformSelector:@selector(setOwner:) withObject:self];
        
        if (publications == nil)
            [macroResolver removeAllMacros];
    }
    
    [self setCount:[publications count]];
    
    NSDictionary *userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:(publications != nil)] forKey:@"succeeded"];
    [[NSNotificationCenter defaultCenter] postNotificationName:BDSKWebGroupUpdatedNotification object:self userInfo:userInfo];
}

- (void)addPublications:(NSArray *)newPublications{    
    
    if(newPublications != publications && newPublications != nil){
        
        if (publications == nil)
            publications = [[BDSKPublicationsArray alloc] initWithArray:newPublications];
        else 
            [publications addObjectsFromArray:newPublications];
        [newPublications makeObjectsPerformSelector:@selector(setOwner:) withObject:self];
    }
    
    [self setCount:[publications count]];
    
    NSDictionary *userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:(newPublications != nil)] forKey:@"succeeded"];
    [[NSNotificationCenter defaultCenter] postNotificationName:BDSKWebGroupUpdatedNotification object:self userInfo:userInfo];
}

- (BDSKMacroResolver *)macroResolver{
    return macroResolver;
}

- (NSUndoManager *)undoManager { return nil; }

- (NSURL *)fileURL { return nil; }

- (NSString *)documentInfoForKey:(NSString *)key { return nil; }

- (BOOL)isDocument { return NO; }

@end
