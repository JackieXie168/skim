//
//  PDFAnnotationLink_SKExtensions.m
//  Skim
//
//  Created by Christiaan Hofman on 7/8/08.
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

#import "PDFAnnotationLink_SKExtensions.h"
#import "SKUtilities.h"


@interface PDFAnnotationLink (SKLeopardPrivate)
- (NSString *)toolTipNoLabel;
@end


@implementation PDFAnnotationLink (SKExtensions)

// override these Leopard methods to avoid showing the standard tool tips over our own

static IMP originalToolTip = NULL;
static IMP originalToolTipNoLabel = NULL;

- (NSString *)replacementToolTip {
    return ([self URL] || [self destination] || originalToolTip == NULL) ? nil : originalToolTip(self, _cmd);
}

- (NSString *)replacementToolTipNoLabel {
    return ([self URL] || [self destination] || originalToolTipNoLabel == NULL) ? nil : originalToolTipNoLabel(self, _cmd);
}

+ (void)load {
    if ([self instancesRespondToSelector:@selector(toolTip)])
        originalToolTip = [self replaceInstanceMethodForSelector:@selector(toolTip) withInstanceMethodFromSelector:@selector(replacementToolTip)];
    if ([self instancesRespondToSelector:@selector(toolTipNoLabel)])
        originalToolTipNoLabel = [self replaceInstanceMethodForSelector:@selector(toolTip) withInstanceMethodFromSelector:@selector(replacementToolTipNoLabel)];
}

- (BOOL)isLink { return YES; }

- (NSArray *)accessibilityAttributeNames {
    static NSArray *attributes = nil;
    if (attributes == nil) {
        attributes = [[[super accessibilityAttributeNames] arrayByAddingObject:NSAccessibilityURLAttribute] retain];
    }
    return attributes;
}

- (id)accessibilityRoleAttribute {
    return NSAccessibilityLinkRole;
}

- (id)accessibilityTitleAttribute {
    NSString *title = nil;
    if (originalToolTip != NULL)
        title = originalToolTip(self, _cmd);
    if (title == nil)
        title = [self contents];
    return title;
}

- (id)accessibilityURLAttribute {
    return [self URL];
}

- (id)accessibilityValueAttribute {
    return [[[self page] selectionForRect:NSInsetRect([self bounds], -3.0, -3.0)] string];
}

- (id)accessibilityEnabledAttribute {
    return [NSNumber numberWithBool:YES];
}

- (NSArray *)accessibilityActionNames {
    return [NSArray arrayWithObject:NSAccessibilityPressAction];
}

@end
