//
//  SKNoteText.m
//  Skim
//
//  Created by Christiaan Hofman on 10/12/08.
/*
 This software is Copyright (c) 2007-2020
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

#import "SKNoteText.h"
#import "PDFAnnotation_SKExtensions.h"
#import "NSAttributedString_SKExtensions.h"


@implementation SKNoteText

@synthesize note;
@dynamic hasNoteText, noteText, type, page, pageIndex, string, text, objectValue;

+ (NSSet *)keyPathsForValuesAffectingValueForKey:(NSString *)key {
    NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];
    if ([key isEqualToString:@"objectValue"])
        keyPaths = [keyPaths setByAddingObjectsFromSet:[NSSet setWithObjects:@"note.text", nil]];
    return keyPaths;
}

- (id)initWithNote:(id)aNote {
    self = [super init];
    if (self) {
        note = aNote;
    }
    return self;
}

- (void)dealloc {
    note = nil;
    [super dealloc];
}

- (BOOL)hasNoteText { return NO; }

- (SKNoteText *)noteText { return nil; }

- (NSString *)type { return nil; }

- (PDFPage *)page { return nil; }

- (NSString *)string {
    return [note textString];
}

- (NSUInteger)pageIndex { return [note pageIndex]; }

- (NSAttributedString *)text {
    return [note isNote] ? [note text] :  nil;
}

- (id)objectValue {
    if ([note isNote] == NO)
        return [note textString];
    else if (RUNNING_AFTER(10_13))
        return [[note text] attributedStringByAddingControlTextColorAttribute];
    else
        return [note text];
}

@end
