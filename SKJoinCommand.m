//
//  SKJoinCommand.m
//  Skim
//
//  Created by Christiaan Hofman on 6/4/08.
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

#import "SKJoinCommand.h"
#import <Quartz/Quartz.h>
#import "PDFSelection_SKExtensions.h"


@implementation SKJoinCommand

- (id)performDefaultImplementation {
    id dP = [self directParameter];
	NSDictionary *args = [self evaluatedArguments];
    id other = [args objectForKey:@"To"];
    BOOL continuous = [[args objectForKey:@"Continuous"] boolValue];
    PDFSelection *selection = [PDFSelection selectionWithSpecifier:dP];
    PDFSelection *otherSelection = other ? [PDFSelection selectionWithSpecifier:other] : nil;
    
    if (selection == nil)
        selection = otherSelection;
    else if (otherSelection)
        [selection addSelection:otherSelection];
    
    if (continuous) {
        PDFPage *firstPage = [selection safeFirstPage];
        PDFPage *lastPage = [selection safeLastPage];
        if (firstPage && lastPage) {
            NSUInteger firstIndex = [selection safeIndexOfFirstCharacterOnPage:firstPage];
            NSUInteger lastIndex = [selection safeIndexOfLastCharacterOnPage:lastPage];
            if (firstIndex != NSNotFound && lastIndex != NSNotFound)
                selection = [[firstPage document] selectionFromPage:firstPage atCharacterIndex:firstIndex toPage:lastPage atCharacterIndex:lastIndex - 1];
        }
    }
    return selection ? [selection objectSpecifier] : [NSArray array];
}

@end
