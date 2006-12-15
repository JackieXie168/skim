//
//  SKNote.m


//  This code is licensed under a BSD license. Please see the file LICENSE for details.
//
//  Created by Michael McCracken on 12/13/06.
//  Copyright 2006 __Michael O. McCrackenName__. All rights reserved.
//

#import "SKNote.h"


@implementation SKNote

- (id)initWithPageIndex:(int)newPageIndex locationInPageSpace:(NSPoint)newLocationInPageSpace{
    return [self initWithPageIndex:newPageIndex
                         pageLabel:[NSString stringWithFormat:@"%i", newPageIndex + 1]
               locationInPageSpace:newLocationInPageSpace
                         quotation:nil];
}
    
- (id)initWithPageIndex:(int)newPageIndex pageLabel:(NSString *)newPageLabel locationInPageSpace:(NSPoint)newLocationInPageSpace
              quotation:(NSString *)newQuotation{

    self = [super init];
    if (self != nil) {
        pageIndex = newPageIndex;
        pageLabel = [newPageLabel retain];
        locationInPageSpace = newLocationInPageSpace;
        quotation = [newQuotation retain];
        attributedString = nil;
    }
    return self;
}


- (id)initWithCoder:(NSCoder *)coder{
    self = [super init];
    if (self != nil) {
        quotation = [[coder decodeObjectForKey:@"SKNoteQuotation"] retain];
        attributedQuotation = [[coder decodeObjectForKey:@"SKNoteAttributedQuotation"] retain];
        image = [[coder decodeObjectForKey:@"SKNoteImage"] retain];
        attributedString = [[coder decodeObjectForKey:@"SKNoteAttributedString"] retain];
        pageIndex = [coder decodeIntForKey:@"SKNotePageIndex"];
        pageLabel = [[coder decodeObjectForKey:@"SKNotePageLabel"] retain];
        locationInPageSpace = [coder decodePointForKey:@"SKNoteLocationInPageSpace"];
    }
    return self;
}


- (void)encodeWithCoder:(NSCoder *)coder{
    if (quotation)
        [coder encodeObject:quotation forKey:@"SKNoteQuotation"];
    if (attributedQuotation)
        [coder encodeObject:attributedQuotation forKey:@"SKNoteAttributedQuotation"];
    if (image)
        [coder encodeObject:image forKey:@"SKNoteImage"];        
    
    [coder encodeObject:attributedString forKey:@"SKNoteAttributedString"];
    [coder encodeInt:pageIndex forKey:@"SKNotePageIndex"];
    [coder encodeObject:pageLabel forKey:@"SKNotePageLabel"];
    [coder encodePoint:locationInPageSpace forKey:@"SKNoteLocationInPageSpace"];
    return;
}


- (id)copyWithZone:(NSZone *)zone{

    SKNote *newNote = [[SKNote allocWithZone:zone] initWithPageIndex:pageIndex
                                                           pageLabel:pageLabel
                                                 locationInPageSpace:locationInPageSpace
                                                           quotation:quotation];
    
    newNote->attributedQuotation = [attributedQuotation copyWithZone:zone];
    newNote->image = [image copyWithZone:zone];
    newNote->attributedString = [attributedString copyWithZone:zone];
    return newNote;
}


- (void) dealloc {
    if (quotation) [quotation release];
    if (attributedQuotation) [attributedQuotation release];
    if (image) [image release];
    [attributedString release];
    [pageLabel release];
    [super dealloc];
}

- (NSString *)quotation {
    return quotation;
}

- (void)setQuotation:(NSString *)newQuotation {
    if (quotation != newQuotation) {
        [quotation release];
        quotation = [newQuotation copy];
    }
}

- (NSAttributedString *)attributedQuotation {
    if (attributedQuotation == nil) {
        attributedQuotation = [[NSAttributedString alloc] initWithString:quotation];
    }
    return attributedQuotation;
}

- (void)setAttributedQuotation:(NSAttributedString *)newAttributedQuotation {
    if (attributedQuotation != newAttributedQuotation) {
        [attributedQuotation release];
        attributedQuotation = [newAttributedQuotation copy];
        [self setQuotation:[attributedQuotation string]];
    }
}

- (NSAttributedString *)attributedString {
    if (attributedString == nil) {
        attributedString = [[NSAttributedString alloc] init];
    }
    return attributedString;
}

- (void)setAttributedString:(NSAttributedString *)newAttributedString {
    if (attributedString != newAttributedString) {
        [attributedString release];
        attributedString = [newAttributedString copy];
    }
}

- (unsigned int)pageIndex {
    return pageIndex;
}

- (NSString *)pageLabel {
    return pageLabel;
}

- (NSPoint)locationInPageSpace {
    return locationInPageSpace;
}

- (NSString *)description{
    return [NSString stringWithFormat:@"\"%@\" - %@", quotation, attributedString];
}

@end
