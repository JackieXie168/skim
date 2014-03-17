//
//  SKAccessibilityFauxUIElement.m
//  Skim
//
//  Created by Christiaan Hofman on 4/22/08.
/*
 This software is Copyright (c) 2008-2014
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

#import "SKAccessibilityFauxUIElement.h"

static NSString *SKAttributeWithoutAXPrefix(NSString *attribute) {
	return [attribute hasPrefix:@"AX"] ? [attribute substringFromIndex:2] : attribute;
}

static SEL SKAttributeGetter(NSString *attribute) {
	return NSSelectorFromString([NSString stringWithFormat:@"accessibility%@Attribute", SKAttributeWithoutAXPrefix(attribute)]);
}

@implementation SKAccessibilityFauxUIElement

@synthesize parent;
@dynamic representedObject, index;

- (id)initWithParent:(id)aParent {
    self = [super init];
    if (self) {
        parent = aParent;
    }
    return self;
}

- (BOOL)isEqual:(id)other {
    if ([other isKindOfClass:[SKAccessibilityFauxUIElement class]]) {
        SKAccessibilityFauxUIElement *otherElement = (SKAccessibilityFauxUIElement *)other;
        return parent == [otherElement parent];
    } else {
        return NO;
    }
}

- (NSUInteger)hash {
    return [parent hash];
}

- (id)representedObject {
    return nil;
}

- (NSInteger)index {
    return -1;
}

- (NSArray *)accessibilityAttributeNames {
    return [[self representedObject] respondsToSelector:_cmd] ? [[self representedObject] performSelector:_cmd] : [NSArray array];
}

- (id)accessibilityAttributeValue:(NSString *)attribute {
    if ([attribute isEqualToString:NSAccessibilityParentAttribute]) {
        return NSAccessibilityUnignoredAncestor(parent);
    } else if ([attribute isEqualToString:NSAccessibilityWindowAttribute]) {
        // We're in the same window as our parent.
        return [NSAccessibilityUnignoredAncestor(parent) accessibilityAttributeValue:NSAccessibilityWindowAttribute];
    } else if ([attribute isEqualToString:NSAccessibilityTopLevelUIElementAttribute]) {
        // We're in the same top level element as our parent.
        return [NSAccessibilityUnignoredAncestor(parent) accessibilityAttributeValue:NSAccessibilityTopLevelUIElementAttribute];
    } else if ([attribute isEqualToString:NSAccessibilityFocusedAttribute]) {
        return [NSNumber numberWithBool:[parent isFauxUIElementFocused:self]];
    } else if ([attribute isEqualToString:NSAccessibilityPositionAttribute]) {
        return [NSValue valueWithPoint:[parent screenRectForFauxUIElement:self].origin];
    } else if ([attribute isEqualToString:NSAccessibilitySizeAttribute]) {
        return [NSValue valueWithSize:[parent screenRectForFauxUIElement:self].size];
    } else if ([[self accessibilityAttributeNames] containsObject:attribute]) {
		SEL getter = SKAttributeGetter(attribute);
        if ([self respondsToSelector:getter])
            return [self performSelector:getter];
        else if ([[self representedObject] respondsToSelector:getter])
            return [[self representedObject] performSelector:getter];
        else
            return nil;
    } else {
        return nil;
    }
}

- (BOOL)accessibilityIsAttributeSettable:(NSString *)attribute {
    return [attribute isEqualToString:NSAccessibilityFocusedAttribute]; 
}

- (void)accessibilitySetValue:(id)value forAttribute:(NSString *)attribute {
    if ([attribute isEqualToString:NSAccessibilityFocusedAttribute])
        [parent fauxUIElement:self setFocused:[value boolValue]];
}

- (BOOL)accessibilityIsIgnored {
    return [[self representedObject] respondsToSelector:_cmd] ? [[self representedObject] accessibilityIsIgnored] : NO;
}

- (id)accessibilityHitTest:(NSPoint)point {
    return NSAccessibilityUnignoredAncestor(self);
}

- (id)accessibilityFocusedUIElement {
    return NSAccessibilityUnignoredAncestor(self);
}

- (NSArray *)accessibilityActionNames {
    return [[self representedObject] respondsToSelector:_cmd] ? [[self representedObject] performSelector:_cmd] : [NSArray array];
}

- (NSString *)accessibilityActionDescription:(NSString *)anAction {
    return NSAccessibilityActionDescription(anAction);
}

- (void)accessibilityPerformAction:(NSString *)anAction {
    if ([anAction isEqualToString:NSAccessibilityPressAction])
        [parent pressFauxUIElement:self];
}

@end

#pragma mark -

@implementation SKAccessibilityProxyFauxUIElement

+ (id)elementWithObject:(id)anObject parent:(id)aParent {
    return [[[self alloc] initWithObject:anObject parent:aParent] autorelease];
}

- (id)initWithObject:(id)anObject parent:(id)aParent {
    self = [super initWithParent:aParent];
    if (self) {
        object = [anObject retain];
    }
    return self;
}

- (id)initWithParent:(id)aParent {
    return [self initWithObject:nil parent:aParent];
}

- (void)dealloc {
    SKDESTROY(object);
    [super dealloc];
}

- (BOOL)isEqual:(id)other {
    if ([other isKindOfClass:[SKAccessibilityProxyFauxUIElement class]]) {
        SKAccessibilityProxyFauxUIElement *otherElement = (SKAccessibilityProxyFauxUIElement *)other;
        return [super isEqual:other] && object == [otherElement representedObject];
    } else {
        return NO;
    }
}

- (NSUInteger)hash {
    return [super hash] + (((NSUInteger)object >> 4) | ((NSUInteger)object << (32 - 4)));
}

- (id)representedObject {
    return object;
}

@end

#pragma mark -

@implementation SKAccessibilityIndexedFauxUIElement

+ (id)elementWithIndex:(NSInteger)anIndex parent:(id)aParent {
    return [[[self alloc] initWithIndex:anIndex parent:aParent] autorelease];
}

- (id)initWithIndex:(NSInteger)anIndex parent:(id)aParent {
    self = [super initWithParent:aParent];
    if (self) {
        index = anIndex;
    }
    return self;
}

- (id)initWithParent:(id)aParent {
    return [self initWithIndex:-1 parent:aParent];
}

- (BOOL)isEqual:(id)other {
    if ([other isKindOfClass:[SKAccessibilityIndexedFauxUIElement class]]) {
        SKAccessibilityIndexedFauxUIElement *otherElement = (SKAccessibilityIndexedFauxUIElement *)other;
        return [super isEqual:other] && index == [otherElement index];
    } else {
        return NO;
    }
}

- (NSUInteger)hash {
    return [super hash] + (index + 1) >> 4;
}

- (NSInteger)index {
    return index;
}

@end
