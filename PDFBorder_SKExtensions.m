//
//  PDFBorder_SKExtensions.m
//  Skim
//
//  Created by Christiaan Hofman on 4/1/08.
/*
 This software is Copyright (c) 2008-2011
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
    return copy;
}

#if __LP64__

static id (*original_dashPattern)(id, SEL) = NULL;

- (NSArray *)replacement_dashPattern {
    NSMutableArray *pattern = [NSMutableArray array];
    @try {
        id vars = [self valueForKey:@"pdfPriv"];
        NSUInteger i, count = [[vars valueForKey:@"dashCount"] unsignedIntegerValue];
        Ivar ivar = object_getInstanceVariable(vars, "dashPattern", NULL);
        if (ivar != NULL) {
            CGFloat *dashPattern = *(CGFloat **)((void *)vars + ivar_getOffset(ivar));
            for (i = 0; i < count; i++)
                [pattern addObject:[NSNumber numberWithDouble:dashPattern[i]]];
        }
    }
    @catch (id e) {}
    return pattern;
}

+ (void)load {
    // the implementation of -dashPattern is currently badly broken, probably due to the wrong type for _pdfPriv.dashCount
    Class cls = NSClassFromString(@"PDFBorderPrivateVars");
    if (cls) {
        Ivar ivar = class_getInstanceVariable(cls, "dashCount");
        if (ivar && 0 != strcmp(ivar_getTypeEncoding(ivar), @encode(NSUInteger)))
            original_dashPattern = (id (*)(id, SEL))SKReplaceInstanceMethodImplementationFromSelector(self, @selector(dashPattern), @selector(replacement_dashPattern));
    }
}

#endif

@end
