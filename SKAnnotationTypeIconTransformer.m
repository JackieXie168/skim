//
//  SKAnnotationTypeIconTransformer.m
//  Skim
//
//  Created by Christiaan Hofman on 2/16/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "SKAnnotationTypeIconTransformer.h"


@implementation SKAnnotationTypeIconTransformer

+ (Class)transformedValueClass {
    return [NSImage class];
}

+ (BOOL)allowsReverseTransformation {
    return NO;
}

- (NSImage *)transformedValue:(NSString *)type {
    if ([type isEqualToString:@"FreeText"])
        return [NSImage imageNamed:@"AnnotateToolAdorn"];
    if ([type isEqualToString:@"Note"])
        return [NSImage imageNamed:@"NoteToolAdorn"];
    if ([type isEqualToString:@"Circle"])
        return [NSImage imageNamed:@"CircleToolAdorn"];
    return nil;
}

@end
