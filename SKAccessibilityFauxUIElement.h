//
//  SKAccessibilityFauxUIElement.h
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

#import <Cocoa/Cocoa.h>


@interface SKAccessibilityFauxUIElement : NSObject {
    id parent;
}
- (id)initWithParent:(id)aParent;
@property (nonatomic, readonly) id parent;
@property (nonatomic, readonly) id representedObject;
@property (nonatomic, readonly) NSInteger index;
@end

#pragma mark -

@interface SKAccessibilityProxyFauxUIElement : SKAccessibilityFauxUIElement {
    id object;
}
+ (id)elementWithObject:(id)anObject parent:(id)aParent;
- (id)initWithObject:(id)anObject parent:(id)aParent;
@end

#pragma mark -

@interface SKAccessibilityIndexedFauxUIElement : SKAccessibilityFauxUIElement {
    NSInteger index;
}
+ (id)elementWithIndex:(NSInteger)anIndex parent:(id)aParent;
- (id)initWithIndex:(NSInteger)anIndex parent:(id)aParent;
@end

#pragma mark -

// parent should implement these methods
@interface NSObject (SKAccessibilityFauxUIElementParent)
- (NSRect)screenRectForFauxUIElement:(SKAccessibilityFauxUIElement *)element;
- (BOOL)isFauxUIElementFocused:(SKAccessibilityFauxUIElement *)element;
- (void)fauxUIElement:(SKAccessibilityFauxUIElement *)element setFocused:(BOOL)focused;
- (void)pressFauxUIElement:(SKAccessibilityFauxUIElement *)element;
@end
