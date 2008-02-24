//
//  SKPrintAccessoryController.m
//  Skim
//
//  Created by Christiaan Hofman on 2/24/08.
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

#import "SKPrintAccessoryController.h"


@interface PDFDocument (SKLeopardPrivateDeclarations)
- (void)setAutoRotate:(BOOL)autoRotate forPrintOperation:(NSPrintOperation *)printOperation;
- (void)setPrintScalingMode:(int)printScalingMode forPrintOperation:(NSPrintOperation *)printOperation;
@end


@implementation SKPrintAccessoryController

- (id)initWithPrintOperation:(NSPrintOperation *)aPrintOperation document:(PDFDocument *)aDocument {
    if (aDocument == nil || aPrintOperation == nil || 
        (NO == [aDocument respondsToSelector:@selector(setAutoRotate:forPrintOperation:)] && 
         nil == [aPrintOperation valueForKeyPath:@"printInfo.dictionary.PDFPrintAutoRotate"])) {
        [self release];
        self = nil;
    } else if (self = [super initWithNibName:@"PrintAccessoryView" bundle:[NSBundle mainBundle]]) {
        printOperation = [aPrintOperation retain];
        document = [aDocument retain];
    }
    return self;
}

- (void)dealloc {
    [printOperation release];
    [document release];
    [super dealloc];
}

- (void)windowDidLoad {
    [autoRotateButton setState:[self autoRotate] ? NSOnState : NSOffState];
    [printScalingModeMatrix selectCellWithTag:[self printScalingMode]];
    [printScalingModeMatrix setEnabled:[document respondsToSelector:@selector(setPrintScalingMode:forPrintOperation:)]];
}

- (BOOL)autoRotate {
    return [[printOperation valueForKeyPath:@"printInfo.dictionary.PDFPrintAutoRotate"] boolValue];
}

- (void)setAutoRotate:(BOOL)autoRotate {
    [self willChangeValueForKey:@"localizedSummaryItems"];
    if ([document respondsToSelector:@selector(setAutoRotate:forPrintOperation:)])
        [document setAutoRotate:autoRotate forPrintOperation:printOperation];
    [self didChangeValueForKey:@"localizedSummaryItems"];
}

- (PDFPrintScalingMode)printScalingMode {
    return [[printOperation valueForKeyPath:@"printInfo.dictionary.PDFPrintScalingMode"] intValue];
}

- (void)setPrintScalingMode:(PDFPrintScalingMode)printScalingMode {
    [self willChangeValueForKey:@"localizedSummaryItems"];
    if ([document respondsToSelector:@selector(setAutoRotate:forPrintOperation:)])
        [document setPrintScalingMode:printScalingMode forPrintOperation:printOperation];
    [self didChangeValueForKey:@"localizedSummaryItems"];
}

- (NSSet *)keyPathsForValuesAffectingPreview {
    return [NSSet setWithObjects:@"printAutoRotate", @"printScalingMode", nil];
}

- (NSArray *)localizedSummaryItems {
    return [NSArray arrayWithObjects:
            [NSDictionary dictionaryWithObjectsAndKeys:@"autoRotate", NSPrintPanelAccessorySummaryItemNameKey, [[self valueForKey:@"printAutoRotate"] description], NSPrintPanelAccessorySummaryItemDescriptionKey, nil], 
            [NSDictionary dictionaryWithObjectsAndKeys:@"printScalingMode", NSPrintPanelAccessorySummaryItemNameKey, [[self valueForKey:@"printScalingMode"] description], NSPrintPanelAccessorySummaryItemDescriptionKey, nil], nil];
}

@end
