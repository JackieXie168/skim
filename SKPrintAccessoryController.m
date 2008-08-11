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


@implementation SKPrintAccessoryController

+ (NSSet *)keyPathsForValuesAffectingLocalizedSummaryItems {
    return [NSSet setWithObjects:@"autoRotate", @"printScalingMode", nil];
}

+ (NSSet *)keyPathsForValuesAffectingAutoRotate {
    return [NSSet setWithObjects:@"representedObject", nil];
}

+ (NSSet *)keyPathsForValuesAffectingPrintScalingMode {
    return [NSSet setWithObjects:@"representedObject", nil];
}

- (NSString *)nibName {
    return @"PrintAccessoryView";
}

- (NSBundle *)nibBundle {
    return [NSBundle mainBundle];
}

- (BOOL)autoRotate {
    return [[self valueForKeyPath:@"representedObject.dictionary.PDFPrintAutoRotate"] boolValue];
}

- (void)setAutoRotate:(BOOL)autoRotate {
    [self setValue:[NSNumber numberWithBool:autoRotate] forKeyPath:@"representedObject.dictionary.PDFPrintAutoRotate"];
}

- (PDFPrintScalingMode)printScalingMode {
    return [[self valueForKeyPath:@"representedObject.dictionary.PDFPrintScalingMode"] intValue];
}

- (void)setPrintScalingMode:(PDFPrintScalingMode)printScalingMode {
    [self setValue:[NSNumber numberWithInteger:printScalingMode] forKeyPath:@"representedObject.dictionary.PDFPrintScalingMode"];
}

- (NSSet *)keyPathsForValuesAffectingPreview {
    return [NSSet setWithObjects:@"autoRotate", @"printScalingMode", nil];
}

- (NSArray *)localizedSummaryItems {
    NSString *autoRotation = [self autoRotate] ? NSLocalizedString(@"On", @"Print panel setting") : NSLocalizedString(@"Off", @"Print panel setting");
    NSString *autoScaling = nil;
    switch ([self printScalingMode]) {
        case kPDFPrintPageScaleNone: autoScaling = NSLocalizedString(@"None", @"Print panel setting"); break;
        case kPDFPrintPageScaleToFit: autoScaling = NSLocalizedString(@"Scale Each Page", @"Print panel setting"); break;
        case kPDFPrintPageScaleDownToFit: autoScaling = NSLocalizedString(@"Only Scale Down Large Pages", @"Print panel setting"); break;
    }
    return [NSArray arrayWithObjects:
            [NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Page Auto Rotation", @"Print panel setting description"), NSPrintPanelAccessorySummaryItemNameKey, autoRotation, NSPrintPanelAccessorySummaryItemDescriptionKey, nil], 
            [NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Page Auto Scaling", @"Print panel setting description"), NSPrintPanelAccessorySummaryItemNameKey, autoScaling, NSPrintPanelAccessorySummaryItemDescriptionKey, nil], nil];
}

@end
