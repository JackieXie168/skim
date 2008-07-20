//
//  SKAccessibilityProxyElement.m
//  Skim
//
//  Created by Christiaan Hofman on 4/22/08.
/*
 This software is Copyright (c) 2008
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

#import "SKAccessibilityProxyElement.h"

static NSString *SKAttributeWithoutAXPrefix(NSString *attribute) {
	return [attribute hasPrefix:@"AX"] ? [attribute substringFromIndex:2] : attribute;
}

static SEL SKAttributeGetter(NSString *attribute) {
	return NSSelectorFromString([NSString stringWithFormat:@"accessibility%@Attribute", SKAttributeWithoutAXPrefix(attribute)]);
}

@implementation SKAccessibilityProxyElement

+ (id)elementWithObject:(id)anObject parent:(id)aParent {
    return [[[self alloc] initWithObject:anObject parent:aParent] autorelease];
}

- (id)initWithObject:(id)anObject parent:(id)aParent {
    if (self = [super init]) {
        object = [anObject retain];
        parent = aParent;
    }
    return self;
}

- (void)dealloc {
    [object release];
    [super dealloc];
}

- (BOOL)isEqual:(id)other {
    if ([other isKindOfClass:[SKAccessibilityProxyElement class]]) {
        SKAccessibilityProxyElement *otherElement = (SKAccessibilityProxyElement *)other;
        return object == otherElement->object && parent == otherElement->parent;
    } else {
        return NO;
    }
}

- (unsigned int)hash {
    return [object hash] + [parent hash];
}

- (NSArray *)accessibilityAttributeNames {
    return [object respondsToSelector:_cmd] ? [object performSelector:_cmd] : [NSArray array];
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
        return [NSNumber numberWithBool:[parent element:self isRepresentedObjectFocused:object]];
    } else if ([attribute isEqualToString:NSAccessibilityPositionAttribute]) {
        return [NSValue valueWithPoint:[parent element:self screenRectForRepresentedObject:object].origin];
    } else if ([attribute isEqualToString:NSAccessibilitySizeAttribute]) {
        return [NSValue valueWithSize:[parent element:self screenRectForRepresentedObject:object].size];
    } else if ([[self accessibilityAttributeNames] containsObject:attribute]) {
		SEL getter = SKAttributeGetter(attribute);
        return [object respondsToSelector:getter] ? [object performSelector:getter] : nil;
    } else {
        return nil;
    }
}

- (BOOL)accessibilityIsAttributeSettable:(NSString *)attribute {
    return [attribute isEqualToString:NSAccessibilityFocusedAttribute]; 
}

- (void)accessibilitySetValue:(id)value forAttribute:(NSString *)attribute {
    if ([attribute isEqualToString:NSAccessibilityFocusedAttribute])
        [parent element:self setFocused:[value boolValue] forRepresentedObject:object];
}

- (BOOL)accessibilityIsIgnored {
    return [object respondsToSelector:_cmd] ? [object accessibilityIsIgnored] : NO;
}

- (id)accessibilityHitTest:(NSPoint)point {
    return NSAccessibilityUnignoredAncestor(self);
}

- (id)accessibilityFocusedUIElement {
    return NSAccessibilityUnignoredAncestor(self);
}

- (NSArray *)accessibilityActionNames {
    return [object respondsToSelector:_cmd] ? [object performSelector:_cmd] : [NSArray array];
}

- (NSString *)accessibilityActionDescription:(NSString *)anAction {
    return NSAccessibilityActionDescription(anAction);
}

- (void)accessibilityPerformAction:(NSString *)anAction {
    if ([anAction isEqualToString:NSAccessibilityPressAction])
        [parent element:self pressRepresentedObject:object];
}

@end
