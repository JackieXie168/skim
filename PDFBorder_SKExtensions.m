//
//  PDFBorder_SKExtensions.m
//  Skim
//
//  Created by Christiaan Hofman on 4/1/08.
/*
 This software is Copyright (c) 2008-2009
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

#import "PDFBorder_SKExtensions.h"
#import "SKRuntime.h"
#import <objc/objc-runtime.h>

/*
@interface PDFBorderPrivateVars : NSObject
{
    NSUInteger style;
    CGFloat hCornerRadius;
    CGFloat vCornerRadius;
    CGFloat lineWidth;
    unsigned int dashCount;
    CGFloat *dashPattern;
}
@end
*/

@implementation PDFBorder (SKExtensions)

- (id)copyWithZone:(NSZone *)aZone {
    PDFBorder *copy = [[PDFBorder allocWithZone:aZone] init];
    [copy setLineWidth:[self lineWidth]];
    [copy setDashPattern:[[[self dashPattern] copyWithZone:aZone] autorelease]];
    [copy setStyle:[self style]];
    [copy setHorizontalCornerRadius:[self horizontalCornerRadius]];
    [copy setVerticalCornerRadius:[self verticalCornerRadius]];
    return copy;
}

#if __LP64__

static id (*original_dashPattern)(id, SEL) = NULL;

- (NSArray *)replacement_dashPattern {
    id vars = [self valueForKey:@"pdfPriv"];
    NSMutableArray *pattern = [NSMutableArray array];
    NSUInteger i, count;
    CGFloat *dashPattern;
    object_getInstanceVariable(vars, "dashCount", (void *)&count);
    object_getInstanceVariable(vars, "dashPattern", (void *)&dashPattern);
    for (i = 0; i < count; i++)
        [pattern addObject:[NSNumber numberWithDouble:dashPattern[i]]];
    return pattern;
}

+ (void)load {
    // on 10.6 the implementation of -dashPattern is badly broken, probably due to the wrong type for _pdfPriv.dashCount
    if (floor(NSAppKitVersionNumber) > 949)
        original_dashPattern = (id (*)(id, SEL))SKReplaceInstanceMethodImplementationFromSelector(self, @selector(dashPattern), @selector(replacement_dashPattern));
}

#endif

@end
