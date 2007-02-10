//
//  BDSKTreeNode.m
//  Bibdesk
//
//  Created by Adam Maxwell on 05/18/06.
/*
 This software is Copyright (c) 2006,2007
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

#import "BDSKTreeNode.h"


@implementation BDSKTreeNode

- (id)init;
{
    if(self = [super init]){
        [self setParent:nil];
        [self setChildren:[NSArray array]];
        [self setColumnValues:[NSDictionary dictionary]];
    }
    return self;
}

- (void)dealloc
{
    [self setParent:nil];
    [self setChildren:nil];
    [columnValues release];
    [super dealloc];
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"%@: %@ parent object;\n\tvalues: \"%@\"\n\tchildren: \"%@\"", [super description], parent?@"Has":@"No", columnValues, children];
}

- (id)initWithCoder:(NSCoder *)coder;
{
    if(self = [super init]){
        [self setChildren:[coder decodeObjectForKey:@"children"]];
        [self setColumnValues:[coder decodeObjectForKey:@"columnValues"]];
        [self setParent:[coder decodeObjectForKey:@"parent"]];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder;
{
    [coder encodeObject:children forKey:@"children"];
    [coder encodeObject:columnValues forKey:@"columnValues"];
    [coder encodeConditionalObject:parent forKey:@"parent"];
}

- (BOOL)isEqual:(id)other;
{
    // should we compare the children and/or parent as well?
    return [other isKindOfClass:[self class]] && 
           [((BDSKTreeNode *)other)->columnValues isEqualToDictionary:columnValues];
}

- (BDSKTreeNode *)parent { return parent; }

- (void)setParent:(BDSKTreeNode *)anObject;
{
    parent = anObject;
}

- (void)setColumnValues:(NSDictionary *)values;
{
    if(columnValues != values){
        [columnValues release];
        columnValues = [values mutableCopy];
    }
}

- (id)copyWithZone:(NSZone *)aZone;
{
    BDSKTreeNode *node = [[[self class] alloc] init];
    
    // deep copy the array of children, since the copy could modify the original
    NSMutableArray *newChildren = [[NSMutableArray alloc] initWithArray:[self children] copyItems:YES];
    [node setChildren:newChildren];
    [newChildren release];
    
    node->columnValues = [columnValues mutableCopy];
    return node;
}

- (id)valueForKey:(NSString *)aKey
{
#warning wth?
    // when using these as values to be displayed in BDSKTextWithIconCell, valueForUndefinedKey: isn't called
    id obj = [super valueForKey:aKey];
    return obj ? obj : [self valueForUndefinedKey:aKey];
}

- (id)valueForUndefinedKey:(NSString *)key { 
    return [columnValues valueForKey:key]; 
}

- (void)setValue:(id)value forUndefinedKey:(NSString *)key;
{
    NSParameterAssert(nil != value);
    NSParameterAssert(nil != key);
    [columnValues setValue:value forKey:key];
}

- (void)addChild:(BDSKTreeNode *)anObject;
{
    [children addObject:anObject];
    
    // make sure this child knows its parent
    [anObject setParent:self];
}

- (void)insertChild:(BDSKTreeNode *)anObject atIndex:(unsigned int)index;
{
    [children insertObject:anObject atIndex:index];
    
    // make sure this child knows its parent
    [anObject setParent:self];
}

- (void)removeChild:(BDSKTreeNode *)anObject;
{
    [anObject setParent:nil];
    
    // make sure to orphin this child
    [children removeObject:anObject];
}

- (void)setChildren:(NSArray *)theChildren;
{
    if(theChildren != children){
        [children release];
        children = [theChildren mutableCopy];
        
        // make sure these children know their parent
        [children makeObjectsPerformSelector:@selector(setParent:) withObject:self];
    }
}

- (NSArray *)children { return children; }

- (unsigned int)numberOfChildren { return [children count]; }

- (BOOL)isLeaf { return [self numberOfChildren] > 0 ? NO : YES; }

@end
