//
//  SKNote.m
//  Skim
//
//  Created by Christiaan Hofman on 12/10/08.
//  Copyright 2008 Christiaan Hofman. All rights reserved.
//

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

- (unsigned int)pageIndex {
    return [[properties valueForKey:SKNPDFAnnotationPageIndexKey] unsignedIntValue];
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

- (id)page {
    unsigned int pageIndex = [self pageIndex];
    return [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithUnsignedInt:pageIndex], @"pageIndex", [NSString stringWithFormat:@"%u", pageIndex + 1], @"label", nil];
}

- (NSArray *)texts {
    return texts;
}

- (id)valueForUndefinedKey:(NSString *)key {
    return [properties valueForKey:key];
}

@end
