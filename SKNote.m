//
//  SKNote.m
//  Skim
//
//  Created by Christiaan Hofman on 12/10/08.
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

#import "SKNote.h"
#import <SkimNotes/SkimNotes.h>
#import "SKNoteText.h"

@implementation SKNote


- (id)initWithSkimNoteProperties:(NSDictionary *)aProperties {
    if (self = [super init]) {
        properties = [aProperties copy];
        type = [properties valueForKey:SKNPDFAnnotationTypeKey];
        if ([type isEqualToString:SKNTextString])
            type = SKNNoteString;
        [type retain];
        if ([type isEqualToString:SKNNoteString])
            texts = [[NSArray alloc] initWithObjects:[[[SKNoteText alloc] initWithNote:self] autorelease], nil];
        NSMutableString *mutableContents = [[NSMutableString alloc] init];
        if ([[aProperties valueForKey:SKNPDFAnnotationContentsKey] length])
            [mutableContents appendString:[aProperties valueForKey:SKNPDFAnnotationContentsKey]];
        if ([[aProperties valueForKey:SKNPDFAnnotationTextKey] length]) {
            [mutableContents appendString:@"  "];
            [mutableContents appendString:[[aProperties valueForKey:SKNPDFAnnotationTextKey] string]];
        }
        contents = [mutableContents copy];
        [mutableContents release];
    }
    return self;
}

- (void)dealloc {
    [properties release];
    [type release];
    [contents release];
    [texts release];
    [super dealloc];
}

- (NSDictionary *)SkimNoteProperties {
    return properties;
}

- (NSString *)type {
    return type;
}

- (NSRect)bounds {
    return NSRectFromString([properties valueForKey:SKNPDFAnnotationBoundsKey]);
}

- (NSUInteger)pageIndex {
    return [[properties valueForKey:SKNPDFAnnotationPageIndexKey] unsignedIntegerValue];
}

- (NSString *)contents {
    return contents;
}

- (NSString *)string {
    return [properties valueForKey:SKNPDFAnnotationContentsKey];
}

- (NSAttributedString *)text {
    return [properties valueForKey:SKNPDFAnnotationTextKey];
}

- (NSColor *)color {
    return [properties valueForKey:SKNPDFAnnotationColorKey];
}

- (id)page {
    NSUInteger pageIndex = [self pageIndex];
    return [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithUnsignedInteger:pageIndex], @"pageIndex", [NSString stringWithFormat:@"%lu", (unsigned long)(pageIndex + 1)], @"label", nil];
}

- (NSArray *)texts {
    return texts;
}

- (id)valueForUndefinedKey:(NSString *)key {
    return [properties valueForKey:key];
}

@end
