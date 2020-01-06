//
//  SKPDFDocument.m
//  Skim
//
//  Created by Christiaan Hofman on 9/4/09.
/*
 This software is Copyright (c) 2009-2020
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

#import "SKPDFDocument.h"
#import "SKPDFPage.h"
#import "PDFDocument_SKExtensions.h"


#if SDK_BEFORE(10_13)

@interface PDFDocument (SKHighSierraDeclarations)
- (BOOL)allowsCommenting;
@end

#endif

@implementation SKPDFDocument

@synthesize containingDocument;

- (void)dealloc {
    containingDocument = nil;
    SKZONEDESTROY(languageDirections);
    [super dealloc];
}

- (Class)pageClass {
    return [SKPDFPage class];
}

- (SKLanguageDirections)languageDirections {
    if (languageDirections == NULL) {
        languageDirections = (SKLanguageDirections *)NSZoneMalloc(NULL, sizeof(SKLanguageDirections));
        *languageDirections = [super languageDirections];
    }
    return *languageDirections;
}

- (BOOL)unlockWithPassword:(NSString *)password {
    PDFDocumentPermissions permissionsStatus = [self permissionsStatus];
    if ([super unlockWithPassword:password]) {
        if ([[self delegate] respondsToSelector:@selector(document:didUnlockWithPassword:)] &&
            [self permissionsStatus] > permissionsStatus)
            [[self delegate] document:self didUnlockWithPassword:password];
        return YES;
    }
    return NO;
}

// don't send out delegate methods during a synchronous find

#if SDK_BEFORE(10_13)
#define NSStringCompareOptions NSUInteger
#endif

- (NSArray *)findString:(NSString *)string withOptions:(NSStringCompareOptions)options {
    id delegate = [self delegate];
    [self setDelegate:nil];
    NSArray *array = [super findString:string withOptions:options];
    [self setDelegate:delegate];
    return array;
}

- (PDFSelection *)findString:(NSString *)string fromSelection:(PDFSelection *)selection withOptions:(NSStringCompareOptions)options {
    id delegate = [self delegate];
    [self setDelegate:nil];
    selection = [super findString:string fromSelection:selection withOptions:options];
    [self setDelegate:delegate];
    return selection;
}

#if SDK_BEFORE(10_13)
#undef NSStringCompareOptions
#endif

// fool the document into thinking it always allows annotations
- (BOOL)allowsCommenting { return YES; }

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wpartial-availability"

- (BOOL)realAllowsCommenting { return [PDFDocument instancesRespondToSelector:@selector(allowsCommenting)] == NO || [super allowsCommenting]; }

#pragma clang diagnostic pop

- (id <SKPDFDocumentDelegate>)delegate {
    return (id <SKPDFDocumentDelegate>)[super delegate];
}

- (void)setDelegate:(id <SKPDFDocumentDelegate>)newDelegate {
    [super setDelegate:newDelegate];
}

@end
